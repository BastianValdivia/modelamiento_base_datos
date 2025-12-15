
--------------------------------------------------------------------------------
-- ORDEN DE EJECUCIÓN
--
-- 1) Conectarse como SYSTEM / SYS / ADMIN 
--    - Ejecutar:
--        * Creación de roles
--        * Creación de usuarios
--        * Asignación de privilegios y roles
--
-- 2) Conectarse como PRY2205_USER1 (OWNER):
--
--    >>> Ejecutamos el script de la prueba con PRY2205_USER1 <<<
--
--    - Luego ejecutar en este mismo archivo:
--        * Creación de sinónimos públicos
--        * Otorgamiento de permisos SELECT al rol PRY2205_ROL_P
--
-- 3) Conectarse como PRY2205_USER2:
--    - Ejecutar:
--        * Creación de la secuencia SEQ_CONTROL_STOCK
--        * Creación y carga de la tabla CONTROL_STOCK_LIBROS (Caso 2)
--
-- 4) Conectarse nuevamente como PRY2205_USER1:
--    - Ejecutar:
--        * Creación de la vista VW_DETALLE_MULTAS (Caso 3.1)
--        * Creación de índices para optimización (Caso 3.2)
--        * Obtención de planes de ejecución (ANTES y DESPUÉS)
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- CASO 1: ESTRATEGIA DE SEGURIDAD (ROLES + USUARIOS + PRIVILEGIOS)
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1) CREAR ROLES
--------------------------------------------------------------------------------
CREATE ROLE PRY2205_ROL_D;
-- Rol del usuario dueño (PRY2205_USER1)

CREATE ROLE PRY2205_ROL_P;
-- Rol del usuario limitado (PRY2205_USER2)

--------------------------------------------------------------------------------
-- 2) PRIVILEGIOS POR ROL (menor privilegio)
--------------------------------------------------------------------------------

-- =================
-- Rol D (OWNER)
-- =================
GRANT CREATE SESSION TO PRY2205_ROL_D;          -- Conectarse
GRANT CREATE TABLE TO PRY2205_ROL_D;            -- Crear tablas 
GRANT CREATE VIEW TO PRY2205_ROL_D;             -- Crear vista (Caso 3)
GRANT CREATE SYNONYM TO PRY2205_ROL_D;          -- Sinónimos privados 
GRANT CREATE PUBLIC SYNONYM TO PRY2205_ROL_D;   -- Sinónimos públicos (Caso 1)

-- =================
-- Rol P (LIMITADO)
-- =================
GRANT CREATE SESSION TO PRY2205_ROL_P;          -- Conectarse
GRANT CREATE TABLE TO PRY2205_ROL_P;            -- Crear CONTROL_STOCK_LIBROS (Caso 2)
GRANT CREATE SEQUENCE TO PRY2205_ROL_P;         -- Crear SEQ_CONTROL_STOCK (Caso 2)
GRANT CREATE TRIGGER TO PRY2205_ROL_P;          -- Para TRG_CONTROL_STOCK_BI 

--------------------------------------------------------------------------------
-- 3) CREAR USUARIOS
--------------------------------------------------------------------------------
CREATE USER PRY2205_USER1 IDENTIFIED BY user1
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON USERS;

CREATE USER PRY2205_USER2 IDENTIFIED BY user2
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON USERS;

--------------------------------------------------------------------------------
-- 4) ASIGNAR ROLES A USUARIOS
--------------------------------------------------------------------------------
GRANT PRY2205_ROL_D TO PRY2205_USER1;
GRANT PRY2205_ROL_P TO PRY2205_USER2;



--------------------------------------------------------------------------------
-- USUARIO: PRY2205_USER1 (OWNER)
-- >>> AQUÍ ejecutar script de la prueba con PRY2205_USER1 <<<
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- USUARIO: PRY2205_USER1 (OWNER)
-- CASO 1: SINÓNIMOS + PERMISOS MÍNIMOS PARA USER2 (vía ROL)
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1) CREACIÓN DE SINÓNIMOS PÚBLICOS 
--------------------------------------------------------------------------------
CREATE PUBLIC SYNONYM SYN_LIBRO        FOR PRY2205_USER1.LIBRO;
CREATE PUBLIC SYNONYM SYN_EJEMPLAR     FOR PRY2205_USER1.EJEMPLAR;
CREATE PUBLIC SYNONYM SYN_PRESTAMO     FOR PRY2205_USER1.PRESTAMO;
CREATE PUBLIC SYNONYM SYN_EMPLEADO     FOR PRY2205_USER1.EMPLEADO;
CREATE PUBLIC SYNONYM SYN_ALUMNO       FOR PRY2205_USER1.ALUMNO;
CREATE PUBLIC SYNONYM SYN_CARRERA      FOR PRY2205_USER1.CARRERA;
CREATE PUBLIC SYNONYM SYN_REBAJA_MULTA FOR PRY2205_USER1.REBAJA_MULTA;

--------------------------------------------------------------------------------
-- 2) PERMISOS MÍNIMOS
--------------------------------------------------------------------------------
GRANT SELECT ON PRY2205_USER1.LIBRO        TO PRY2205_ROL_P;
GRANT SELECT ON PRY2205_USER1.EJEMPLAR     TO PRY2205_ROL_P;
GRANT SELECT ON PRY2205_USER1.PRESTAMO     TO PRY2205_ROL_P;
GRANT SELECT ON PRY2205_USER1.EMPLEADO     TO PRY2205_ROL_P;
GRANT SELECT ON PRY2205_USER1.ALUMNO       TO PRY2205_ROL_P;
GRANT SELECT ON PRY2205_USER1.CARRERA      TO PRY2205_ROL_P;
GRANT SELECT ON PRY2205_USER1.REBAJA_MULTA TO PRY2205_ROL_P;


--------------------------------------------------------------------------------
-- USUARIO: PRY2205_USER2
-- CASO 2: CONTROL_STOCK_LIBROS (TABLA + SECUENCIA + CÁLCULOS)
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1) CREAR SECUENCIA
--------------------------------------------------------------------------------
CREATE SEQUENCE SEQ_CONTROL_STOCK
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

--------------------------------------------------------------------------------
-- 2) CREAR TABLA CON CTAS (SIN SEQ.NEXTVAL EN EL SELECT)
--    Reglas:
--      - Solo sinónimos SYN_*
--      - Sin WITH
--      - Fecha paramétrica: año actual - 2
--      - Empleados: 190, 180, 150
--      - % redondeado a ENTERO (sin decimales)
--------------------------------------------------------------------------------
CREATE TABLE CONTROL_STOCK_LIBROS AS
SELECT
    /* Fecha de proceso: MM/YYYY calculado a partir de "hace 24 meses" */
    TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -24), 'MM/YYYY')                   AS fecha_proceso,

    /* ID y nombre del libro */
    l.libroid                                                                   AS id_libro,
    INITCAP(l.nombre_libro)                                                     AS nombre_libro,

    /* Totales */
    e.total_ejemplares                                                          AS total_ejemplares,
    NVL(p.ejemplares_en_prestamo, 0)                                            AS ejemplares_en_prestamo,

    /* Disponibles */
    (e.total_ejemplares - NVL(p.ejemplares_en_prestamo, 0))                     AS ejemplares_disponibles,

    /* % préstamo respecto del total: REDONDEADO A ENTERO (sin decimales) */
    ROUND(
      (NVL(p.ejemplares_en_prestamo, 0) / NULLIF(e.total_ejemplares, 0)) * 100
    )                                                                           AS pct_prestamo,

    /* Indicador stock crítico:
       'S' si disponibles > 2, si no 'N' */
    CASE
      WHEN (e.total_ejemplares - NVL(p.ejemplares_en_prestamo, 0)) > 2 THEN 'S'
      ELSE 'N'
    END                                                                         AS ind_stock_critico

FROM
    /* Subconsulta: total de ejemplares por libro */
    (SELECT
         ej.libroid,
         COUNT(*) AS total_ejemplares
     FROM SYN_EJEMPLAR ej
     GROUP BY ej.libroid
    ) e

    JOIN SYN_LIBRO l
      ON l.libroid = e.libroid

    /* Subconsulta: ejemplares en préstamo por libro, filtrando por año y empleados */
    LEFT JOIN
    (SELECT
         pr.libroid,
         COUNT(DISTINCT pr.ejemplarid) AS ejemplares_en_prestamo
     FROM SYN_PRESTAMO pr
     WHERE
         EXTRACT(YEAR FROM pr.fecha_inicio) = (EXTRACT(YEAR FROM SYSDATE) - 2)
         AND pr.empleadoid IN (190, 180, 150)
     GROUP BY pr.libroid
    ) p
      ON p.libroid = e.libroid

ORDER BY l.libroid;

--------------------------------------------------------------------------------
-- 3) AGREGAR CORRELATIVO Y RELLENAR CON SECUENCIA
--------------------------------------------------------------------------------
ALTER TABLE CONTROL_STOCK_LIBROS ADD (correlativo NUMBER);

UPDATE CONTROL_STOCK_LIBROS
SET correlativo = SEQ_CONTROL_STOCK.NEXTVAL;

COMMIT;

--------------------------------------------------------------------------------
-- 4) TRIGGER PARA FUTUROS INSERTS
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_CONTROL_STOCK_BI
BEFORE INSERT ON CONTROL_STOCK_LIBROS
FOR EACH ROW
BEGIN
  IF :NEW.correlativo IS NULL THEN
    :NEW.correlativo := SEQ_CONTROL_STOCK.NEXTVAL;
  END IF;
END;
/




--------------------------------------------------------------------------------
-- USUARIO: PRY2205_USER1
-- CASO 3.1: VISTA VW_DETALLE_MULTAS
-- CASO 3.2: ÍNDICES + PLAN ANTES/DESPUÉS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1) CREAR VISTA (SIN ORDER BY)
--    Reglas:
--      - Acceso por sinónimos SYN_*
--      - Sin WITH
--      - Solo atrasados
--      - Solo préstamos terminados hace 2 años (año actual - 2)
--      - Rango de fechas sargable para favorecer uso de índices
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_DETALLE_MULTAS AS
SELECT
    p.prestamoid                                                                 AS id_prestamo,
    TRIM(a.nombre || ' ' || a.apaterno || ' ' || NVL(a.amaterno, ''))           AS nombre_alumno,
    c.descripcion                                                                AS nombre_carrera,
    l.libroid                                                                    AS id_libro,
    TO_CHAR(l.precio, 'FM$999G999G999')                                          AS valor_libro,
    TO_CHAR(p.fecha_termino, 'DD/MM/YYYY')                                       AS fecha_termino,
    TO_CHAR(p.fecha_entrega, 'DD/MM/YYYY')                                       AS fecha_entrega,
    (TRUNC(p.fecha_entrega) - TRUNC(p.fecha_termino))                            AS dias_atraso,
    TO_CHAR(
      ROUND( (l.precio * 0.03) * (TRUNC(p.fecha_entrega) - TRUNC(p.fecha_termino)) )
    , 'FM$999G999G999')                                                          AS valor_multa,
    TO_CHAR(NVL(rm.porc_rebaja_multa, 0) / 100, 'FM0D00')                        AS porcentaje_rebaja_multa,
    TO_CHAR(
      ROUND(
        ( (l.precio * 0.03) * (TRUNC(p.fecha_entrega) - TRUNC(p.fecha_termino)) )
        * (1 - (NVL(rm.porc_rebaja_multa, 0) / 100))
      )
    , 'FM$999G999G999')                                                          AS valor_rebajado
FROM
    SYN_PRESTAMO p
    JOIN SYN_ALUMNO  a ON a.alumnoid  = p.alumnoid
    JOIN SYN_CARRERA c ON c.carreraid = a.carreraid
    JOIN SYN_LIBRO   l ON l.libroid   = p.libroid
    LEFT JOIN SYN_REBAJA_MULTA rm ON rm.carreraid = c.carreraid
WHERE
    p.fecha_entrega IS NOT NULL
    AND p.fecha_termino < p.fecha_entrega
    AND p.fecha_termino >= ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -24)
    AND p.fecha_termino <  ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -12)
;

--------------------------------------------------------------------------------
-- 2) CONSULTA DE PRESENTACIÓN
--------------------------------------------------------------------------------
SELECT *
FROM VW_DETALLE_MULTAS
ORDER BY TO_DATE(fecha_entrega, 'DD/MM/YYYY') DESC;

--------------------------------------------------------------------------------
-- 3) PLAN ANTES (evidencia)
--------------------------------------------------------------------------------
EXPLAIN PLAN FOR
SELECT *
FROM VW_DETALLE_MULTAS
ORDER BY TO_DATE(fecha_entrega, 'DD/MM/YYYY') DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

--------------------------------------------------------------------------------
-- 4) ÍNDICES
--------------------------------------------------------------------------------
CREATE INDEX IDX_PRESTAMO_FECHAS ON PRESTAMO (fecha_termino, fecha_entrega);
CREATE INDEX IDX_PRESTAMO_ALU_LIB ON PRESTAMO (alumnoid, libroid);

--------------------------------------------------------------------------------
-- 5) ESTADÍSTICAS
--------------------------------------------------------------------------------
BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname          => 'PRY2205_USER1',
    tabname          => 'PRESTAMO',
    estimate_percent => 100
  );

  DBMS_STATS.GATHER_INDEX_STATS(
    ownname => 'PRY2205_USER1',
    indname => 'IDX_PRESTAMO_FECHAS'
  );

  DBMS_STATS.GATHER_INDEX_STATS(
    ownname => 'PRY2205_USER1',
    indname => 'IDX_PRESTAMO_ALU_LIB'
  );
END;
/

--------------------------------------------------------------------------------
-- 6) PLAN DESPUÉS (evidencia)
--------------------------------------------------------------------------------
EXPLAIN PLAN FOR
SELECT *
FROM VW_DETALLE_MULTAS
ORDER BY TO_DATE(fecha_entrega, 'DD/MM/YYYY') DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

--------------------------------------------------------------------------------
-- FIN
--------------------------------------------------------------------------------
