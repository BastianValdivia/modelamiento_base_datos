--------------------------------------------------------------------------------
-- PRY2205 - EFT - ENTREGA
-- BASE DE DATOS: ORACLE XE
--
-- ESTRATEGIA DE SEGURIDAD (CASO 1) - RESUMEN:
--   Se implementan 3 usuarios con responsabilidades distintas:
--
--   (A) PRY2205_EFT       -> OWNER / ADMINISTRADOR DEL MODELO
--       - Crea tablas, vistas, secuencias e índices del modelo.
--       - Crea sinónimos (públicos/privados) para ocultar los nombres reales.
--       - Crea la vista del Caso 3.
--
--   (B) PRY2205_EFT_DES   -> DESARROLLO / CONSTRUCCIÓN DE INFORMES
--       - Construye el informe del Caso 2.
--       - Almacena el informe en la tabla CARTOLA_PROFESIONALES.
--       - No debe depender de nombres reales: usa sinónimos para consultar.
--
--   (C) PRY2205_EFT_CON   -> CONSULTA / LECTURA
--       - Solo consulta resultados (informes y vistas) según permisos otorgados.
--       - No crea objetos ni modifica datos.
--
--   Para ordenar permisos se utilizan ROLES:
--     - PRY2205_ROL_D: Permisos asociados a tareas de desarrollo (DES).
--     - PRY2205_ROL_C: Permisos asociados a tareas de consulta (CON).
--
-- ORDEN DE EJECUCIÓN RECOMENDADO (CASO 1):
--   1) Conectarse como SYSTEM (o SYS):
--      1.1 Crear roles
--      1.2 Crear usuarios (con USERS / TEMP / QUOTA 10M)
--      1.3 Otorgar privilegios base y asignar roles
--
--   2) Conectarse como PRY2205_EFT:
--      2.1 Ejecutar el script oficial del esquema (creación y poblamiento de tablas)
--      2.2 Crear sinónimos (principalmente públicos) para tablas requeridas
--      2.3 Otorgar permisos SELECT (y los mínimos necesarios) a DES y CON
--
-- NOTA SOBRE SINÓNIMOS:
--   - Sinónimo público: cuando varios usuarios deben acceder al mismo objeto sin
--     escribir el esquema (ej: EMPRESA en vez de PRY2205_EFT.EMPRESA).
--   - Sinónimo privado: cuando el acceso es específico para un usuario.
--
-- NOTA SOBRE TEMP Y QUOTA:
--   - TEMPORARY TABLESPACE TEMP: Oracle usa TEMP como espacio de trabajo para
--     operaciones temporales (ORDER BY, GROUP BY, JOIN grandes).
--   - QUOTA 10M ON USERS: limita el espacio que el usuario puede usar en USERS.
--
--------------------------------------------------------------------------------








--------------------------------------------------------------------------------
-- USUARIO: SYSTEM  (ORACLE XE)
-- CASO 1 - ESTRATEGIA DE SEGURIDAD
--
-- OBJETIVO:
--   Implementar una estrategia de control de acceso utilizando:
--     - 3 usuarios con responsabilidades distintas
--     - 2 roles para agrupar privilegios
--     - Principio de menor privilegio
--     - Configuración estándar Oracle XE (USERS / TEMP / QUOTA 10M)
--
-- USUARIOS:
--   1) PRY2205_EFT       -> OWNER del modelo (dueño de las tablas)
--   2) PRY2205_EFT_DES   -> DESARROLLO (construye el informe del Caso 2)
--   3) PRY2205_EFT_CON   -> CONSULTA (solo lectura)
--
-- ROLES:
--   - PRY2205_ROL_D: rol de desarrollo (lectura de tablas base)
--   - PRY2205_ROL_C: rol de consulta (lectura de resultados finales)
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1) CREACIÓN DE ROLES
--    Un ROL es un contenedor de privilegios.
--    Permite administrar permisos de forma ordenada y reutilizable.
--------------------------------------------------------------------------------
CREATE ROLE PRY2205_ROL_D;
CREATE ROLE PRY2205_ROL_C;

--------------------------------------------------------------------------------
-- 2) CREACIÓN DE USUARIOS
--
--    Configuración Oracle XE:
--      - DEFAULT TABLESPACE USERS  -> espacio permanente
--      - TEMPORARY TABLESPACE TEMP -> espacio temporal
--      - QUOTA 10M ON USERS        -> límite
--
--    Contraseñas:
--      - Cumplen reglas de complejidad
--      - No contienen el nombre del usuario
--------------------------------------------------------------------------------
CREATE USER PRY2205_EFT
  IDENTIFIED BY "EftXX2025aa99"
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  QUOTA 10M ON USERS;

CREATE USER PRY2205_EFT_DES
  IDENTIFIED BY "DesXX2025aa99"
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  QUOTA 10M ON USERS;

CREATE USER PRY2205_EFT_CON
  IDENTIFIED BY "ConXX2025aa99"
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  QUOTA 10M ON USERS;

--------------------------------------------------------------------------------
-- 3) PRIVILEGIO BASE PARA CONECTARSE
--
--    CREATE SESSION:
--    Sin este privilegio el usuario existe, pero NO puede iniciar sesión.
--------------------------------------------------------------------------------
GRANT CREATE SESSION TO PRY2205_EFT;
GRANT CREATE SESSION TO PRY2205_EFT_DES;
GRANT CREATE SESSION TO PRY2205_EFT_CON;

--------------------------------------------------------------------------------
-- 4) PRIVILEGIOS DEL OWNER (PRY2205_EFT)
--
--    Este usuario es el dueño del modelo de datos y puede:
--      - Crear tablas del esquema
--      - Crear vistas y secuencias
--      - Crear sinónimos privados y públicos
--------------------------------------------------------------------------------
GRANT CREATE TABLE          TO PRY2205_EFT;
GRANT CREATE VIEW           TO PRY2205_EFT;
GRANT CREATE SEQUENCE       TO PRY2205_EFT;
GRANT CREATE SYNONYM        TO PRY2205_EFT;
GRANT CREATE PUBLIC SYNONYM TO PRY2205_EFT;

--------------------------------------------------------------------------------
-- 5) PRIVILEGIOS DEL USUARIO DESARROLLO (PRY2205_EFT_DES)
--
--    Este usuario:
--      - Construye el informe del Caso 2
--      - Crea vistas
--      - Puede crear usuarios y perfiles (requisito explícito del caso)
--------------------------------------------------------------------------------
GRANT CREATE VIEW    TO PRY2205_EFT_DES;
GRANT CREATE USER    TO PRY2205_EFT_DES;
GRANT CREATE PROFILE TO PRY2205_EFT_DES;

--------------------------------------------------------------------------------
-- 6) ASIGNACIÓN DE ROLES A USUARIOS
--
--    En esta etapa:
--      - Los roles NO tienen todavía SELECT sobre tablas
--      - Los SELECT se asignarán más adelante, cuando las tablas existan
--------------------------------------------------------------------------------
GRANT PRY2205_ROL_D TO PRY2205_EFT_DES;
GRANT PRY2205_ROL_C TO PRY2205_EFT_CON;

--------------------------------------------------------------------------------
-- 7) VERIFICACIONES
--    Útiles para comprobar ejecución correcta y para el video de presentación
--------------------------------------------------------------------------------

-- 7.1) Verificar usuarios creados
SELECT username
FROM dba_users
WHERE username IN ('PRY2205_EFT', 'PRY2205_EFT_DES', 'PRY2205_EFT_CON')
ORDER BY username;

-- 7.2) Verificar roles creados
SELECT role
FROM dba_roles
WHERE role IN ('PRY2205_ROL_D', 'PRY2205_ROL_C')
ORDER BY role;

-- 7.3) Verificar asignación de roles
SELECT grantee, granted_role
FROM dba_role_privs
WHERE grantee IN ('PRY2205_EFT_DES', 'PRY2205_EFT_CON')
ORDER BY grantee, granted_role;





--------------------------------------------------------------------------------
-- IMPORTANTE:
-- El siguiente paso DEBE ejecutarse conectado como el usuario PRY2205_EFT.
-- Se ejecuta el script oficial del esquema de datos.
-- Este script crea y puebla las tablas del modelo.
-- SOLO después de eso se pueden crear sinónimos y asignar SELECT.
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
-- USUARIO: PRY2205_EFT  (OWNER)
-- CASO 1 (continuación)
--
-- 8) CREACIÓN DE SINÓNIMOS PÚBLICOS
--
--    Los sinónimos permiten que los usuarios DES y CON
--    consulten las tablas sin referenciar el esquema real.
--
--------------------------------------------------------------------------------
CREATE PUBLIC SYNONYM PROFESIONAL           FOR PRY2205_EFT.PROFESIONAL;
CREATE PUBLIC SYNONYM PROFESION             FOR PRY2205_EFT.PROFESION;
CREATE PUBLIC SYNONYM ISAPRE                FOR PRY2205_EFT.ISAPRE;
CREATE PUBLIC SYNONYM TIPO_CONTRATO         FOR PRY2205_EFT.TIPO_CONTRATO;
CREATE PUBLIC SYNONYM RANGOS_SUELDOS        FOR PRY2205_EFT.RANGOS_SUELDOS;
CREATE PUBLIC SYNONYM CARTOLA_PROFESIONALES FOR PRY2205_EFT.CARTOLA_PROFESIONALES;
CREATE PUBLIC SYNONYM EMPRESA               FOR PRY2205_EFT.EMPRESA;
CREATE PUBLIC SYNONYM ASESORIA              FOR PRY2205_EFT.ASESORIA;

--------------------------------------------------------------------------------
-- 9) PERMISOS DE LECTURA (SELECT) USANDO ROLES
--
-- Buenas prácticas:
--   - NO otorgar SELECT directo a los usuarios (salvo casos puntuales)
--   - Los SELECT se entregan a ROLES
--   - Los usuarios heredan permisos vía su rol
--------------------------------------------------------------------------------

-- 9.1) Acceso de lectura a tablas base para DESARROLLO (PRY2205_ROL_D)
GRANT SELECT ON PRY2205_EFT.PROFESIONAL     TO PRY2205_ROL_D;
GRANT SELECT ON PRY2205_EFT.PROFESION       TO PRY2205_ROL_D;
GRANT SELECT ON PRY2205_EFT.ISAPRE          TO PRY2205_ROL_D;
GRANT SELECT ON PRY2205_EFT.TIPO_CONTRATO   TO PRY2205_ROL_D;
GRANT SELECT ON PRY2205_EFT.RANGOS_SUELDOS  TO PRY2205_ROL_D;

-- 9.2) Acceso de lectura para CONSULTA (PRY2205_ROL_C)
-- Informe final del Caso 2
GRANT SELECT ON PRY2205_EFT.CARTOLA_PROFESIONALES TO PRY2205_ROL_C;

-- Tablas base necesarias para evidencias con PRY2205_EFT_CON (BLOQUE EXTRA)
GRANT SELECT ON PRY2205_EFT.PROFESIONAL TO PRY2205_ROL_C;
GRANT SELECT ON PRY2205_EFT.EMPRESA     TO PRY2205_ROL_C;
GRANT SELECT ON PRY2205_EFT.ASESORIA    TO PRY2205_ROL_C;










--------------------------------------------------------------------------------
-- USUARIO: PRY2205_EFT  (OWNER)
-- CASO 2 - PARTE A: PERMISOS PARA QUE DES PUEDA CARGAR EL INFORME
--
-- ¿Por qué esta sección?
--   - El usuario DES es quien CONSTRUYE el informe del Caso 2.
--   - Necesita:
--       * DELETE  -> para limpiar la cartola antes de recargarla
--       * INSERT  -> para cargar el nuevo informe
--       * SELECT WITH GRANT OPTION 
--
-- Nota:
--   Estos permisos se otorgan sobre la tabla CARTOLA_PROFESIONALES,
--   que pertenece al OWNER (PRY2205_EFT).
--------------------------------------------------------------------------------

-- Permite a DES borrar e insertar registros del informe
GRANT INSERT, DELETE
ON CARTOLA_PROFESIONALES
TO PRY2205_EFT_DES;

-- Permite que DES otorgue SELECT a otro usuario (CON)
GRANT SELECT
ON CARTOLA_PROFESIONALES
TO PRY2205_EFT_DES
WITH GRANT OPTION;

COMMIT;










--------------------------------------------------------------------------------
-- USUARIO: PRY2205_EFT_DES  (DESARROLLO)
-- CASO 2 - PARTE B: CONSTRUCCIÓN Y CARGA DEL INFORME
--
-- Reglas del encargo que se cumplen explícitamente:
--   - El informe se almacena en CARTOLA_PROFESIONALES
--   - Se utiliza INSERT ... SELECT (SIN cláusula WITH)
--   - Acceso a tablas mediante SINÓNIMOS públicos
--   - Uso de funciones: NVL, TRIM, INITCAP, ROUND, CASE
--   - El orden solicitado se aplica en la consulta final de presentación
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1) LIMPIEZA PREVIA DEL INFORME (Opcional)
--    Permite ejecutar el script más de una vez sin duplicar datos.
--------------------------------------------------------------------------------
DELETE FROM CARTOLA_PROFESIONALES;
COMMIT;

--------------------------------------------------------------------------------
-- 2) CARGA DEL INFORME (INSERT ... SELECT SIN WITH)
--------------------------------------------------------------------------------
INSERT INTO CARTOLA_PROFESIONALES
(
  RUT_PROFESIONAL,
  NOMBRE_PROFESIONAL,
  PROFESION,
  ISAPRE,
  SUELDO_BASE,
  PORC_COMISION_PROFESIONAL,
  VALOR_TOTAL_COMISION,
  PORCENTATE_HONORARIO,
  BONO_MOVILIZACION,
  TOTAL_PAGAR
)
SELECT
  -- RUT del profesional
  p.rutprof AS rut_profesional,

  -- Nombre completo (limpieza de texto + formato)
  TRIM(
    INITCAP(p.nompro) || ' ' ||
    INITCAP(p.apppro) || ' ' ||
    INITCAP(NVL(p.apmpro, ''))
  ) AS nombre_profesional,

  -- Profesión e isapre (tablas de catálogo)
  pr.nomprofesion AS profesion,
  i.nomisapre     AS isapre,

  -- Sueldo base
  p.sueldo AS sueldo_base,

  -- Porcentaje de comisión (si es NULL se reemplaza por 0)
  NVL(p.comision, 0) AS porc_comision_profesional,

  -- Valor total de la comisión (redondeado)
  ROUND(p.sueldo * NVL(p.comision, 0)) AS valor_total_comision,

  -- Honorarios calculados según rango salarial
  ROUND(p.sueldo * (r.honor_pct / 100)) AS porcentate_honorario,

  -- Bono de movilización según tipo de contrato
  CASE
    WHEN tc.nomtcontrato = 'Indefinido Jornada Completa' THEN 150000
    WHEN tc.nomtcontrato = 'Indefinido Jornada Parcial'  THEN 120000
    WHEN tc.nomtcontrato = 'Plazo fijo'                  THEN  60000
    WHEN tc.nomtcontrato = 'Honorarios'                  THEN  50000
    ELSE 0
  END AS bono_movilizacion,

  -- Total a pagar = sueldo + comisión + honorarios + bono
  (
    p.sueldo
    + ROUND(p.sueldo * NVL(p.comision, 0))
    + ROUND(p.sueldo * (r.honor_pct / 100))
    + CASE
        WHEN tc.nomtcontrato = 'Indefinido Jornada Completa' THEN 150000
        WHEN tc.nomtcontrato = 'Indefinido Jornada Parcial'  THEN 120000
        WHEN tc.nomtcontrato = 'Plazo fijo'                  THEN  60000
        WHEN tc.nomtcontrato = 'Honorarios'                  THEN  50000
        ELSE 0
      END
  ) AS total_pagar
FROM
  profesional p
  JOIN profesion pr
    ON pr.idprofesion = p.idprofesion
  JOIN isapre i
    ON i.idisapre = p.idisapre
  LEFT JOIN tipo_contrato tc
    ON tc.idtcontrato = p.idtcontrato
  JOIN rangos_sueldos r
    ON p.sueldo BETWEEN r.s_min AND r.s_max;

COMMIT;




--------------------------------------------------------------------------------
-- 3) OTORGAR ACCESO A CON
--------------------------------------------------------------------------------
GRANT SELECT
ON CARTOLA_PROFESIONALES
TO PRY2205_EFT_CON;

--------------------------------------------------------------------------------
-- 4) CONSULTA FINAL DE PRESENTACIÓN
--    Muestra el resultado con formato y orden.
--    NO modifica datos.
--------------------------------------------------------------------------------
SELECT
  rut_profesional                                               AS "RUT PROFESIONAL",
  nombre_profesional                                            AS "NOMBRE PROFESIONAL",
  profesion                                                     AS "PROFESION",
  isapre                                                        AS "ISAPRE",
  TO_CHAR(sueldo_base,         'FM$999G999G999')                AS "SUELDO BASE",
  TO_CHAR(porc_comision_profesional * 100, 'FM990D00') || '%'   AS "% COMISION",
  TO_CHAR(valor_total_comision,'FM$999G999G999')                AS "VALOR COMISION",
  TO_CHAR(porcentate_honorario,'FM$999G999G999')                AS "HONORARIOS",
  TO_CHAR(bono_movilizacion,  'FM$999G999G999')                 AS "BONO MOVILIZACION",
  TO_CHAR(total_pagar,        'FM$999G999G999')                 AS "TOTAL PAGAR"
FROM cartola_profesionales
ORDER BY
  profesion ASC,
  sueldo_base DESC,
  porc_comision_profesional ASC,
  rut_profesional ASC;











--------------------------------------------------------------------------------
-- USUARIO: PRY2205_EFT  (OWNER)
-- CASO 3: VISTA VW_EMPRESAS_ASESORADAS + OPTIMIZACIÓN
--
-- OBJETIVO:
--   - Crear una vista con información agregada de empresas asesoradas
--   - Considerar SOLO asesorías terminadas el año calendario anterior
--   - Clasificar clientes y definir promociones según reglas de negocio
--   - Optimizar el acceso mediante índice + evidencia con EXPLAIN PLAN
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 3.1) CREACIÓN / REEMPLAZO DE LA VISTA
--
-- Reglas importantes:
--   - La vista NO incluye ORDER BY (Oracle no garantiza orden en vistas)
--   - El ORDER BY se aplica solo en la consulta de presentación
--   - Se accede a tablas mediante SINÓNIMOS públicos (EMPRESA, ASESORIA)
--   - El rango de fechas es PARAMÉTRICO (no usa fechas fijas)
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_EMPRESAS_ASESORADAS AS
SELECT
  /* RUT empresa con formato 12345678-9 */
  TO_CHAR(e.rut_empresa) || '-' || e.dv_empresa                           AS rut_empresa,

  /* Nombre de la empresa */
  INITCAP(e.nomempresa)                                                   AS nombre_empresa,

  /* Años de antigüedad desde inicio de actividades */
  TRUNC(MONTHS_BETWEEN(SYSDATE, e.fecha_iniciacion_actividades) / 12)     AS anos_antiguedad,

  /* IVA declarado (valor numérico; formato se aplica en presentación) */
  e.iva_declarado                                                         AS iva_declarado,

  /* Total de asesorías terminadas el año anterior */
  COUNT(*)                                                                AS total_asesorias,

  /* Promedio anual de asesorías */
  ROUND(COUNT(*) / 12, 2)                                                 AS prom_asesorias_anual,

  /* Devolución estimada de IVA */
  ROUND(e.iva_declarado * ((COUNT(*) / 12) / 100), 0)                     AS devolucion_iva_estimada,

  /* Clasificación del tipo de cliente */
  CASE
    WHEN (COUNT(*) / 12) > 5 THEN 'CLIENTE PREMIUM'
    WHEN (COUNT(*) / 12) BETWEEN 3 AND 5 THEN 'CLIENTE'
    ELSE 'CLIENTE POCO CONCURRIDO'
  END                                                                     AS tipo_cliente,

  /* Promoción según reglas del negocio */
  CASE
    -- CLIENTE PREMIUM
    WHEN (COUNT(*) / 12) > 5 AND COUNT(*) >= 7 THEN '1 ASESORIA GRATIS'
    WHEN (COUNT(*) / 12) > 5 AND COUNT(*) <  7 THEN '1 ASESORIA 40% DE DESCUENTO'

    -- CLIENTE
    WHEN (COUNT(*) / 12) BETWEEN 3 AND 5 AND COUNT(*) = 5 THEN '1 ASESORIA 30% DE DESCUENTO'
    WHEN (COUNT(*) / 12) BETWEEN 3 AND 5 AND COUNT(*) < 5 THEN '1 ASESORIA 20% DE DESCUENTO'

    -- CLIENTE POCO CONCURRIDO
    ELSE 'CAPTAR CLIENTE'
  END                                                                     AS promocion
FROM
  empresa  e
  JOIN asesoria a
    ON a.idempresa = e.idempresa
WHERE
  /* Año calendario anterior completo:
     Desde 01-01 del año anterior
     Hasta 01-01 del año actual
  */
  a.fin >= ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -12)
  AND a.fin <  TRUNC(SYSDATE, 'YYYY')
GROUP BY
  e.rut_empresa,
  e.dv_empresa,
  e.nomempresa,
  e.fecha_iniciacion_actividades,
  e.iva_declarado;

--------------------------------------------------------------------------------
-- 3.1.1) SINÓNIMO PÚBLICO + PERMISOS DE LECTURA (CONSULTA)
--
-- ¿Por qué se agrega esto?
--   - El usuario PRY2205_EFT_CON (y su rol PRY2205_ROL_C) debe poder consultar
--     la vista usando el nombre "VW_EMPRESAS_ASESORADAS" sin anteponer el esquema.
--   - En tu diseño de seguridad, los permisos se administran por ROLES.
--------------------------------------------------------------------------------
CREATE PUBLIC SYNONYM VW_EMPRESAS_ASESORADAS
FOR PRY2205_EFT.VW_EMPRESAS_ASESORADAS;

GRANT SELECT ON PRY2205_EFT.VW_EMPRESAS_ASESORADAS TO PRY2205_ROL_C;

GRANT SELECT ON PRY2205_EFT.VW_EMPRESAS_ASESORADAS TO PRY2205_EFT_CON;

--------------------------------------------------------------------------------
-- 3.1.2) CONSULTA DE PRESENTACIÓN
--  Se utiliza ORDER BY y formato de salida.
--------------------------------------------------------------------------------
SELECT
  rut_empresa                                                            AS "RUT EMPRESA",
  nombre_empresa                                                         AS "NOMBRE EMPRESA",
  anos_antiguedad                                                        AS "AÑOS ANTIGÜEDAD",
  TO_CHAR(iva_declarado, 'FM$999G999G999')                               AS "IVA DECLARADO",
  total_asesorias                                                        AS "TOTAL ASESORÍAS",
  TO_CHAR(prom_asesorias_anual, 'FM990D00')                              AS "PROM. ASESORÍAS ANUAL",
  TO_CHAR(devolucion_iva_estimada, 'FM$999G999G999')                     AS "DEVOLUCIÓN IVA ESTIMADA",
  tipo_cliente                                                           AS "TIPO CLIENTE",
  promocion                                                              AS "PROMOCIÓN"
FROM VW_EMPRESAS_ASESORADAS
ORDER BY nombre_empresa ASC;

--------------------------------------------------------------------------------
-- 3.2) PLAN DE EJECUCIÓN - ANTES DEL ÍNDICE
-- Evidencia del comportamiento del optimizador sin optimización explícita.
--------------------------------------------------------------------------------
EXPLAIN PLAN FOR
SELECT
  rut_empresa,
  nombre_empresa,
  anos_antiguedad,
  iva_declarado,
  total_asesorias,
  prom_asesorias_anual,
  devolucion_iva_estimada,
  tipo_cliente,
  promocion
FROM VW_EMPRESAS_ASESORADAS
ORDER BY nombre_empresa ASC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

--------------------------------------------------------------------------------
-- 3.2) CREACIÓN DEL ÍNDICE
--
-- Justificación:
--   - La vista se construye a partir de ASESORIA
--   - El filtro principal es por rango de fechas (FIN)
--   - El JOIN se realiza por IDEMPRESA
--
-- AJUSTE:
--   - Se referencia la tabla REAL del OWNER para evitar depender de sinónimos.
--------------------------------------------------------------------------------
CREATE INDEX IDX_ASESORIA_FIN_IDEMPRESA
ON PRY2205_EFT.ASESORIA (FIN, IDEMPRESA);

--------------------------------------------------------------------------------
-- Actualización de estadísticas
-- Necesaria para que el optimizador considere el nuevo índice.
--------------------------------------------------------------------------------
BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname          => 'PRY2205_EFT',
    tabname          => 'ASESORIA',
    estimate_percent => 100
  );

  DBMS_STATS.GATHER_INDEX_STATS(
    ownname => 'PRY2205_EFT',
    indname => 'IDX_ASESORIA_FIN_IDEMPRESA'
  );
END;
/
COMMIT;

--------------------------------------------------------------------------------
-- 3.2) PLAN DE EJECUCIÓN - DESPUÉS DEL ÍNDICE
-- Evidencia de la mejora tras la optimización.
--------------------------------------------------------------------------------
EXPLAIN PLAN FOR
SELECT
  rut_empresa,
  nombre_empresa,
  anos_antiguedad,
  iva_declarado,
  total_asesorias,
  prom_asesorias_anual,
  devolucion_iva_estimada,
  tipo_cliente,
  promocion
FROM VW_EMPRESAS_ASESORADAS
ORDER BY nombre_empresa ASC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);





--------------------------------------------------------------------------------
-- BLOQUE EXTRA: EVIDENCIAS (SUBCONSULTA + SET + UPDATE)
--
-- OBJETIVO:
--   Este bloque NO es parte del Caso 1/2/3 del enunciado “funcional”.
--   Se agrega únicamente para cubrir criterios pauta:
--     1) Subconsultas
--     2) Operadores SET (UNION / MINUS / INTERSECT)
--     3) UPDATE (DML completo), sin alterar el estado final (ROLLBACK)
--
-- IMPORTANTE:
--   - Todas las consultas son de solo lectura EXCEPTO el UPDATE, que se revierte.
--   - Se recomienda ejecutarlo al final del script, una vez creados:
--       * Sinónimos públicos (profesional, empresa, asesoria, etc.)
--       * Datos cargados
--       * Vista VW_EMPRESAS_ASESORADAS creada
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- USUARIO: PRY2205_EFT_CON  (CONSULTA)
-- 1) EVIDENCIA: SUBCONSULTA ESCALAR
--
-- Qué demuestra:
--   - Uso de una subconsulta que retorna un único valor (AVG)
--   - Comparación con el valor retornado por la subconsulta
--   - Solo lectura
--------------------------------------------------------------------------------
SELECT
  p.rutprof   AS rut_profesional,
  INITCAP(TRIM(p.nompro)) AS nombre,
  p.sueldo    AS sueldo_base
FROM profesional p
WHERE p.sueldo > (
  SELECT AVG(p2.sueldo)
  FROM profesional p2
)
ORDER BY p.sueldo DESC;


--------------------------------------------------------------------------------
-- USUARIO: PRY2205_EFT_CON  (CONSULTA)
-- 2) EVIDENCIA: SUBCONSULTA CORRELACIONADA (EXISTS)
--
-- Qué demuestra:
--   - Subconsulta correlacionada con EXISTS
--   - Validación de existencia de registros relacionados
--   - Solo lectura
--------------------------------------------------------------------------------
SELECT
  e.idempresa,
  INITCAP(TRIM(e.nomempresa)) AS nombre_empresa
FROM empresa e
WHERE EXISTS (
  SELECT 1
  FROM asesoria a
  WHERE a.idempresa = e.idempresa
    AND a.fin >= ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -12)
    AND a.fin <  TRUNC(SYSDATE, 'YYYY')
)
ORDER BY nombre_empresa ASC;


--------------------------------------------------------------------------------
-- USUARIO: PRY2205_EFT_CON  (CONSULTA)
-- 3) EVIDENCIA: OPERADOR SET (UNION)
--
-- Qué demuestra:
--   - Uso de UNION (operador de conjuntos)
--   - Ambas consultas retornan mismas columnas y tipos
--   - Solo lectura
--------------------------------------------------------------------------------
SELECT
  nombre_empresa,
  tipo_cliente
FROM vw_empresas_asesoradas
WHERE tipo_cliente = 'CLIENTE PREMIUM'
UNION
SELECT
  nombre_empresa,
  tipo_cliente
FROM vw_empresas_asesoradas
WHERE tipo_cliente = 'CLIENTE POCO CONCURRIDO'
ORDER BY nombre_empresa;


--------------------------------------------------------------------------------
-- USUARIO: PRY2205_EFT_CON  (CONSULTA)
-- 4) EVIDENCIA: OPERADOR SET (MINUS)
--
-- Qué demuestra:
--   - Uso de MINUS para obtener "A excepto B"
--   - Caso típico: empresas existentes que no aparecen en la vista del año anterior
--   - Solo lectura
--------------------------------------------------------------------------------
SELECT
  INITCAP(TRIM(e.nomempresa)) AS nombre_empresa
FROM empresa e
MINUS
SELECT
  v.nombre_empresa
FROM vw_empresas_asesoradas v
ORDER BY nombre_empresa;
