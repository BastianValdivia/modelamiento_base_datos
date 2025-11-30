-- ==========================================================
-- Actividad Sumativa 2
-- Bastián Valdivia
-- DUOC UC Online
-- ==========================================================

PROMPT ==========================================================
PROMPT CASO 1 – REPORTERÍA DE ASESORÍAS
PROMPT ==========================================================

COLUMN "ID Profesional" FORMAT 999
COLUMN "Profesional" FORMAT A30
COLUMN "Nro Asesoría Banca" FORMAT 999
COLUMN "Monto Total Banca" FORMAT A20
COLUMN "Nro Asesoría Retail" FORMAT 999
COLUMN "Monto Total Retail" FORMAT A20
COLUMN "Total Asesorías" FORMAT 999
COLUMN "Total Honorarios" FORMAT A20

-- ===============================================================
-- CONSULTA PRINCIPAL:
-- Identifica profesionales que trabajaron en ambos sectores (3 y 4)
-- ===============================================================

SELECT 
    -- Identificador del profesional
    p.id_profesional AS "ID Profesional",
    
    -- Nombre completo 
    INITCAP(p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre) AS "Profesional",

    -- ===============================
    -- SECTOR BANCA (código 3)
    -- ===============================
    (SELECT COUNT(*) 
     FROM asesoria a_banca
     INNER JOIN empresa e_banca 
         ON a_banca.cod_empresa = e_banca.cod_empresa
     WHERE a_banca.id_profesional = p.id_profesional
       AND e_banca.cod_sector = 3) AS "Nro Asesoría Banca",

    TO_CHAR(
        (SELECT SUM(a_banca.honorario)
         FROM asesoria a_banca
         INNER JOIN empresa e_banca 
             ON a_banca.cod_empresa = e_banca.cod_empresa
         WHERE a_banca.id_profesional = p.id_profesional
           AND e_banca.cod_sector = 3),
        '$999G999G999') AS "Monto Total Banca",

    -- ===============================
    -- SECTOR RETAIL (código 4)
    -- ===============================
    (SELECT COUNT(*) 
     FROM asesoria a_retail
     INNER JOIN empresa e_retail 
         ON a_retail.cod_empresa = e_retail.cod_empresa
     WHERE a_retail.id_profesional = p.id_profesional
       AND e_retail.cod_sector = 4) AS "Nro Asesoría Retail",

    TO_CHAR(
        (SELECT SUM(a_retail.honorario)
         FROM asesoria a_retail
         INNER JOIN empresa e_retail 
             ON a_retail.cod_empresa = e_retail.cod_empresa
         WHERE a_retail.id_profesional = p.id_profesional
           AND e_retail.cod_sector = 4),
        '$999G999G999') AS "Monto Total Retail",

    -- ===============================
    -- TOTALES GENERALES POR PROFESIONAL
    -- ===============================
    (SELECT COUNT(*) 
     FROM asesoria a_total
     WHERE a_total.id_profesional = p.id_profesional) AS "Total Asesorías",

    TO_CHAR(
        (SELECT SUM(a_total.honorario)
         FROM asesoria a_total
         WHERE a_total.id_profesional = p.id_profesional),
        '$999G999G999') AS "Total Honorarios"

FROM profesional p

-- ===============================
-- FILTRO: Solo profesionales que trabajaron en AMBOS SECTORES
-- ===============================
WHERE 
    p.id_profesional IN (
        SELECT id_profesional
        FROM asesoria a
        INNER JOIN empresa e ON a.cod_empresa = e.cod_empresa
        WHERE e.cod_sector IN (3,4)
        GROUP BY id_profesional
        HAVING COUNT(DISTINCT e.cod_sector) = 2  -- Ambos sectores: Banca y Retail
    )

-- ===============================
-- SE AGREGA TOTAL GENERAL 
-- ===============================
UNION
SELECT 
    NULL AS "ID Profesional",
    'TOTAL GENERAL' AS "Profesional",
    NULL AS "Nro Asesoría Banca",
    TO_CHAR(SUM(CASE WHEN e.cod_sector = 3 THEN a.honorario ELSE 0 END), '$999G999G999') AS "Monto Total Banca",
    NULL AS "Nro Asesoría Retail",
    TO_CHAR(SUM(CASE WHEN e.cod_sector = 4 THEN a.honorario ELSE 0 END), '$999G999G999') AS "Monto Total Retail",
    COUNT(a.honorario) AS "Total Asesorías",
    TO_CHAR(SUM(a.honorario), '$999G999G999') AS "Total Honorarios"
FROM asesoria a
INNER JOIN empresa e ON a.cod_empresa = e.cod_empresa
WHERE e.cod_sector IN (3,4)

ORDER BY "ID Profesional" ASC;

PROMPT ==========================================================
PROMPT CASO 1 EJECUTADO CORRECTAMENTE SEGÚN PAUTA DUOC UC
PROMPT ==========================================================



PROMPT ==========================================================
PROMPT CASO 2 – REPORTE MENSUAL DE HONORARIOS POR PROFESIONAL
PROMPT ==========================================================


PROMPT ----------------------------------------------------------
PROMPT ELIMINANDO TABLA REPORTE_MES SI EXISTE
PROMPT ----------------------------------------------------------

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE REPORTE_MES';
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/
COMMIT;


PROMPT ----------------------------------------------------------
PROMPT TABLA REPORTE_MES 
PROMPT ----------------------------------------------------------

CREATE TABLE REPORTE_MES AS
SELECT 
    -- Identificador del profesional
    p.id_profesional AS "ID Profesional",

    -- Nombre completo 
    INITCAP(p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre) AS "Nombre Completo",

    -- Profesión y comuna 
    pr.nombre_profesion AS "Profesión",
    c.nom_comuna AS "Comuna",

    -- Número de asesorías realizadas en ABRIL del AÑO PASADO
    COUNT(a.honorario) AS "Nro Asesorías",

    -- Monto total acumulado en honorarios (redondeado)
    TO_CHAR(ROUND(SUM(NVL(a.honorario,0))), '$999G999G999') AS "Monto Total",

    -- Promedio de honorarios (redondeado)
    TO_CHAR(ROUND(AVG(NVL(a.honorario,0))), '$999G999G999') AS "Promedio Honorario",

    -- Honorario mínimo y máximo del mes (redondeados)
    TO_CHAR(MIN(NVL(a.honorario,0)), '$999G999G999') AS "Honorario Mínimo",
    TO_CHAR(MAX(NVL(a.honorario,0)), '$999G999G999') AS "Honorario Máximo"

FROM 
    profesional p
    INNER JOIN comuna c ON p.cod_comuna = c.cod_comuna
    INNER JOIN profesion pr ON p.cod_profesion = pr.cod_profesion
    INNER JOIN asesoria a ON p.id_profesional = a.id_profesional

WHERE 
    -- FILTRO EXACTO: Asesorías de ABRIL del año pasado (sin fechas fijas)
    EXTRACT(MONTH FROM a.fin_asesoria) = 4
    AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -12))

GROUP BY 
    p.id_profesional, p.appaterno, p.apmaterno, p.nombre, 
    pr.nombre_profesion, c.nom_comuna

ORDER BY 
    p.id_profesional ASC;

COMMIT;


PROMPT ----------------------------------------------------------
PROMPT TABLA REPORTE_MES CREADA Y POBLADA CORRECTAMENTE
PROMPT ----------------------------------------------------------


PROMPT ==========================================================
PROMPT MOSTRANDO RESULTADOS DEL REPORTE_MES
PROMPT ==========================================================

COLUMN "ID Profesional" FORMAT 999
COLUMN "Nombre Completo" FORMAT A35
COLUMN "Profesión" FORMAT A25
COLUMN "Comuna" FORMAT A20
COLUMN "Nro Asesorías" FORMAT 999
COLUMN "Monto Total" FORMAT A15
COLUMN "Promedio Honorario" FORMAT A15
COLUMN "Honorario Mínimo" FORMAT A15
COLUMN "Honorario Máximo" FORMAT A15

SELECT * FROM REPORTE_MES
ORDER BY "ID Profesional";


PROMPT ==========================================================
PROMPT CASO 2 EJECUTADO CORRECTAMENTE
PROMPT ==========================================================





PROMPT ==========================================================
PROMPT CASO 3 – MODIFICACIÓN DE HONORARIOS
PROMPT ==========================================================


PROMPT ==========================================================
PROMPT CREACIÓN TABLA RESUMEN_COMPRA_AVANCE_PUNTOS 
PROMPT ==========================================================

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE resumen_compra_avance_puntos';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE resumen_compra_avance_puntos (
    id_profesional NUMBER(10),
    puntos NUMBER(10)
);

INSERT INTO resumen_compra_avance_puntos (id_profesional, puntos)
SELECT id_profesional, 0 FROM profesional;

COMMIT;


PROMPT ==========================================================
PROMPT PROCESO DE CÁLCULO DE HONORARIOS ANTES DE LA MODIFICACIÓN
PROMPT ==========================================================

-- Esta salida debe lucir igual a la Figura 4
SELECT 
    a.honorario,
    p.id_profesional,
    p.numrun_prof,
    p.sueldo
FROM 
    profesional p
    INNER JOIN asesoria a ON p.id_profesional = a.id_profesional
WHERE 
    EXTRACT(MONTH FROM a.fin_asesoria) = 3
    AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -12))
ORDER BY 
    p.id_profesional;

PROMPT ==========================================================
PROMPT ACTUALIZANDO SUELDOS SEGÚN HONORARIOS DE MARZO AÑO PASADO
PROMPT ==========================================================

UPDATE profesional p
SET p.sueldo = p.sueldo * 
    (
        CASE
            WHEN (
                SELECT SUM(NVL(a.honorario,0))
                FROM asesoria a
                WHERE a.id_profesional = p.id_profesional
                AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
                AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -12))
            ) < 1000000 THEN 1.10
            WHEN (
                SELECT SUM(NVL(a.honorario,0))
                FROM asesoria a
                WHERE a.id_profesional = p.id_profesional
                AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
                AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -12))
            ) >= 1000000 THEN 1.15
            ELSE 1
        END
    )
WHERE 
    p.id_profesional IN (
        SELECT DISTINCT id_profesional
        FROM asesoria
        WHERE EXTRACT(MONTH FROM fin_asesoria) = 3
          AND EXTRACT(YEAR FROM fin_asesoria) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -12))
    );

COMMIT;

PROMPT ----------------------------------------------------------
PROMPT SUELDOS ACTUALIZADOS CORRECTAMENTE
PROMPT ----------------------------------------------------------


PROMPT ==========================================================
PROMPT ACTUALIZANDO TABLA RESUMEN_COMPRA_AVANCE_PUNTOS (PUNTOS)
PROMPT ==========================================================

UPDATE resumen_compra_avance_puntos r
SET r.puntos = (
    SELECT ROUND(AVG(p.sueldo) / 1000)
    FROM profesional p
    WHERE p.id_profesional = r.id_profesional
)
WHERE EXISTS (
    SELECT 1
    FROM profesional p
    WHERE p.id_profesional = r.id_profesional
);

COMMIT;

PROMPT ----------------------------------------------------------
PROMPT TABLA RESUMEN_COMPRA_AVANCE_PUNTOS ACTUALIZADA CORRECTAMENTE
PROMPT ----------------------------------------------------------


PROMPT ==========================================================
PROMPT PROCESO DE CÁLCULO DE HONORARIOS DESPUÉS DE LA MODIFICACIÓN
PROMPT ==========================================================

-- Esta salida debe lucir igual a la Figura 5
SELECT 
    a.honorario,
    p.id_profesional,
    p.numrun_prof,
    p.sueldo
FROM 
    profesional p
    INNER JOIN asesoria a ON p.id_profesional = a.id_profesional
WHERE 
    EXTRACT(MONTH FROM a.fin_asesoria) = 3
    AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -12))
ORDER BY 
    p.id_profesional;

PROMPT ==========================================================
PROMPT CASO 3 EJECUTADO CORRECTAMENTE
PROMPT ==========================================================