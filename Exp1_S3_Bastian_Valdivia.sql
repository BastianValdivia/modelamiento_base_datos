-- ==========================================================
-- Evaluación Sumativa - Semana 3
-- Caso 1: Listado de Clientes con Rango de Renta
-- Autor: Bastian Valdivia
-- Usuario: PRY2205_S3
-- Fecha: (SYSDATE)
-- ==========================================================

ALTER SESSION SET NLS_DATE_FORMAT='DD/MM/YYYY';

-- ==========================================================
-- Consulta: Clientes con rango de renta y clasificación de tramos
-- ==========================================================

COLUMN RUT_CLIENTE FORMAT A15
COLUMN NOMBRE_COMPLETO FORMAT A30
COLUMN RENTA FORMAT $999G999G999
COLUMN TRAMO FORMAT A10

SELECT 
    -- Formatea el RUT con puntos y guion
    SUBSTR(N.NUMRUT_CLI, 1, LENGTH(N.NUMRUT_CLI)-1) || '-' || SUBSTR(N.NUMRUT_CLI, -1) AS RUT_CLIENTE,

    -- Une nombre y apellidos
    INITCAP(NOMBRE_CLI) || ' ' || INITCAP(APPATERNO_CLI) || ' ' || INITCAP(APMATERNO_CLI) AS NOMBRE_COMPLETO,

    -- Muestra la renta del cliente
    RENTA_CLI AS RENTA,

    -- Clasifica según el tramo de renta
    CASE
        WHEN RENTA_CLI > 500000 THEN 'TRAMO 1'
        WHEN RENTA_CLI BETWEEN 400000 AND 500000 THEN 'TRAMO 2'
        WHEN RENTA_CLI BETWEEN 200000 AND 399999 THEN 'TRAMO 3'
        ELSE 'TRAMO 4'
    END AS TRAMO

FROM CLIENTE N
WHERE 
    RENTA_CLI BETWEEN &RENTA_MINIMA AND &RENTA_MAXIMA
    AND CELULAR_CLI IS NOT NULL
ORDER BY 
    NOMBRE_COMPLETO ASC;
    
TTITLE OFF;    

-- ============================================================
-- CASO 2: Sueldo Promedio por Categoría de Empleado
-- Alumno: Bastian Valdivia
-- ============================================================



PROMPT ============================================
PROMPT INFORME DE SUELDO PROMEDIO POR CATEGORÍA
PROMPT Alumno: Bastian Valdivia
PROMPT ============================================

COLUMN NOMBRE_SUCURSAL FORMAT A20;
COLUMN CATEGORIA FORMAT A25;
COLUMN CANTIDAD_EMPLEADOS FORMAT 999;
COLUMN SUELDO_PROMEDIO FORMAT $999G999G999;

SELECT
    -- Código y nombre de sucursal
    E.ID_SUCURSAL AS COD_SUCURSAL,
    CASE 
        WHEN E.ID_SUCURSAL = 10 THEN 'Las Condes'
        WHEN E.ID_SUCURSAL = 20 THEN 'Santiago Centro'
        WHEN E.ID_SUCURSAL = 30 THEN 'Providencia'
        WHEN E.ID_SUCURSAL = 40 THEN 'Vitacura'
        ELSE 'Otra'
    END AS NOMBRE_SUCURSAL,

    -- Código y descripción de categoría
    E.ID_CATEGORIA_EMP AS COD_CATEGORIA,
    CASE
        WHEN E.ID_CATEGORIA_EMP = 1 THEN 'Gerente'
        WHEN E.ID_CATEGORIA_EMP = 2 THEN 'Supervisor'
        WHEN E.ID_CATEGORIA_EMP = 3 THEN 'Ejecutivo de Arriendo'
        WHEN E.ID_CATEGORIA_EMP = 4 THEN 'Auxiliar'
        ELSE 'Sin Categoría'
    END AS CATEGORIA,

    -- Cantidad y promedio
    COUNT(*) AS CANTIDAD_EMPLEADOS,
    ROUND(AVG(E.SUELDO_EMP)) AS SUELDO_PROMEDIO

FROM EMPLEADO E

GROUP BY
    E.ID_SUCURSAL,
    E.ID_CATEGORIA_EMP

HAVING
    AVG(E.SUELDO_EMP) > &SUELDO_PROMEDIO_MINIMO

ORDER BY
    SUELDO_PROMEDIO DESC;
    
 -- ============================================================
-- CASO 3: Arriendo Promedio por Tipo de Propiedad
-- Alumno: Bastian Valdivia
-- ============================================================



PROMPT ============================================
PROMPT INFORME DE PROMEDIO DE ARRIENDOS
PROMPT Alumno: Bastian Valdivia
PROMPT ============================================

COLUMN TIPO_PROPIEDAD FORMAT A25;
COLUMN COMUNA FORMAT A25;
COLUMN CANTIDAD_PROPIEDADES FORMAT 999;
COLUMN ARRIENDO_PROMEDIO FORMAT $999G999G999;

SELECT 
    TP.ID_TIPO_PROPIEDAD AS COD_TIPO,
    TP.DESC_TIPO_PROPIEDAD AS TIPO_PROPIEDAD,
    C.NOMBRE_COMUNA AS COMUNA,
    COUNT(*) AS CANTIDAD_PROPIEDADES,
    ROUND(AVG(P.VALOR_ARRIENDO)) AS ARRIENDO_PROMEDIO

FROM PROPIEDAD P
JOIN TIPO_PROPIEDAD TP ON P.ID_TIPO_PROPIEDAD = TP.ID_TIPO_PROPIEDAD
JOIN COMUNA C ON P.ID_COMUNA = C.ID_COMUNA

GROUP BY 
    TP.ID_TIPO_PROPIEDAD,
    TP.DESC_TIPO_PROPIEDAD,
    C.NOMBRE_COMUNA

HAVING 
    AVG(P.VALOR_ARRIENDO) > &PROMEDIO_MINIMO

ORDER BY 
    ARRIENDO_PROMEDIO DESC;

-- ============================================================
-- CASO RESUMEN: RESUMEN GLOBAL DE LA BASE DE DATOS
-- Alumno: Bastian Valdivia
-- ============================================================



PROMPT ============================================
PROMPT RESUMEN GLOBAL DE REGISTROS Y PROMEDIOS
PROMPT Alumno: Bastian Valdivia
PROMPT ============================================

COLUMN DESCRIPCION FORMAT A40;
COLUMN TOTAL FORMAT 999G999;
COLUMN PROMEDIO FORMAT $999G999G999;

SELECT 'Total de Clientes' AS DESCRIPCION,
       COUNT(*) AS TOTAL,
       ROUND(AVG(RENTA_CLI)) AS PROMEDIO
FROM CLIENTE
UNION ALL
SELECT 'Total de Empleados',
       COUNT(*),
       ROUND(AVG(SUELDO_EMP))
FROM EMPLEADO
UNION ALL
SELECT 'Total de Propiedades',
       COUNT(*),
       ROUND(AVG(VALOR_ARRIENDO))
FROM PROPIEDAD;    