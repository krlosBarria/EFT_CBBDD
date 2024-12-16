/********************************************************************
    Informe 1: Resumen de clientes por región
*********************************************************************/
-- Consulta para obtener el resumen de clientes por región
SELECT R.cod_region, R.nombre_region,
    COUNT(CASE WHEN MONTHS_BETWEEN(SYSDATE, C.fecha_inscripcion) >= 240 THEN 1 END) AS "Clientes > 20 años Antiguedad",
    COUNT(*) AS total_clientes
FROM cliente C
INNER JOIN region R 
ON C.cod_region = R.cod_region
GROUP BY R.cod_region, R.nombre_region
ORDER BY "Clientes > 20 años Antiguedad" ASC;

-- Almacenar la consulta como una vista en la base de datos
-- Crear la Vista
CREATE OR REPLACE VIEW v_resumen_clientes_region 
AS SELECT R.cod_region, R.nombre_region,
        COUNT(CASE WHEN MONTHS_BETWEEN(SYSDATE, C.fecha_inscripcion) >= 240 THEN 1 END) AS "Clientes > 20 años Antiguedad",
        COUNT(*) AS total_clientes
    FROM cliente C
    INNER JOIN region R 
        ON C.cod_region = R.cod_region
    GROUP BY R.cod_region, R.nombre_region
    ORDER BY "Clientes > 20 años Antiguedad" ASC;
    
-- DESCRIBE v_resumen_clientes_region
-- SELECT * FROM v_resumen_clientes_region;

-- Optimizar el acceso a los datos creando los índices
-- Índice en tabla cliente(idx_cli_region)
CREATE INDEX idx_cli_region
ON cliente(cod_region);

-- Índice en tabla region (idx_region)
CREATE INDEX idx_region 
ON region(cod_region);

--Verificación de Índices
SELECT index_name, index_type, table_name, uniqueness
FROM USER_INDEXES
WHERE table_name = 'CLIENTE';

SELECT index_name, index_type, table_name, uniqueness
FROM USER_INDEXES
WHERE table_name = 'REGION';

/* NOTA: La columna ya esta indexada
Error que empieza en la línea: 33 del comando :
CREATE INDEX idx_region 
ON region(cod_region)
*/

/********************************************************************
    Informe 2: Transacciones con vencimientos en el segundo semestre
*********************************************************************/
-- 01. Ordenar los resultados por el promedio de montos de transacciones de manera Ascendente.
-- ORDER BY MONTO_PROMEDIO ASC;
-- 02. Generar dos soluciones
--      1ra Solución: usando un operador SET
SELECT 
    TO_CHAR(SYSDATE, 'DD-MM-YYYY') AS Fecha
    , cod_tptran_tarjeta AS Codigo
    , UPPER(nombre_tptran_tarjeta) AS Descripcion
    , 0 AS "Monto Promedio Transaccion"
FROM tipo_transaccion_tarjeta
UNION ALL
SELECT
    TO_CHAR(fecha_transaccion, 'DD-MM-YYYY') AS Fecha
    , cod_tptran_tarjeta AS Codigo
    , '' AS Descripcion -- Esto queda vacío como en tu consulta
    , AVG(monto_total_transaccion) AS "Monto Promedio Transaccion"
FROM transaccion_tarjeta_cliente
WHERE EXTRACT(MONTH FROM fecha_transaccion) BETWEEN 6 AND 12
GROUP BY TO_CHAR(fecha_transaccion, 'DD-MM-YYYY'), cod_tptran_tarjeta

--      2da Solución: usando una subconsulta, cuyos resultados se almacenarán en la tabla SELECCIÓN_TIPO_TRANSACCIÓN.
SELECT * FROM seleccion_tipo_transaccion;   -- Consulto talabla seleccion_tipo_transaccion;

-- Insertar en la tabla SELECCIÓN_TIPO_TRANSACCION el resultado de la consulta
INSERT INTO seleccion_tipo_transaccion (fecha, cod_tipo_transac, nombre_tipo_transac, monto_promedio) 
SELECT 
    TO_CHAR(SYSDATE, 'DD-MM-YYYY') AS Fecha
    ,TT.cod_tptran_tarjeta AS COD_TIPO_TRANSAC
    ,upper(TT.nombre_tptran_tarjeta) AS NOMBRE_TIPO_TRANSAC
    ,ROUND(AVG(TTC.monto_total_transaccion),0) AS MONTO_PROMEDIO
FROM transaccion_tarjeta_cliente TTC
INNER JOIN tipo_transaccion_tarjeta TT 
    ON TTC.cod_tptran_tarjeta = TT.cod_tptran_tarjeta
    INNER JOIN cuota_transac_tarjeta_cliente CTC 
        ON TTC.nro_tarjeta = CTC.nro_tarjeta
WHERE EXTRACT(MONTH FROM CTC.fecha_venc_cuota) BETWEEN 6 AND 12
GROUP BY TT.cod_tptran_tarjeta, TT.nombre_tptran_tarjeta
ORDER BY MONTO_PROMEDIO ASC;

COMMIT; -- Confirmo la actualización

-- 03. actualizar la Tasa de interés en la tabla TIPO_TRANSACCION_TARJETA
-- SELECT * FROM seleccion_tipo_transaccion;   -- Consulto tabla seleccion_tipo_transaccion;
-- SELECT * FROM tipo_transaccion_tarjeta;     -- Consulto tabla tipo_transaccion_tarjeta

UPDATE tipo_transaccion_tarjeta TT
SET TT.tasaint_tptran_tarjeta = (TT.tasaint_tptran_tarjeta - 0.01)
WHERE TT.cod_tptran_tarjeta IN(
                                SELECT cod_tipo_transac
                                FROM seleccion_tipo_transaccion
                            );
COMMIT; -- Confirmo la actualización

/***************************************************************************************************************
El desarrollo del Informe 2 pide responder a las siguientes preguntas:
1.	¿Cuál es el problema que se debe resolver?
    El problema de calcular el promedio de los montos de transacciones, segun el vencimiento en el 2 semestre (Junio - Diciembre)
    Con el operador SET no pude dar con una solicion concreta.
    
2.	¿Cuál es la información significativa que necesita para resolver el problema?
    La interaciones de las Tablas donde obtener los datos (información), sacar la fecha de vencimiento de cuota y calcular el monto_total_transaccion
    
3.	¿Cuál es el propósito de la solución que se requiere?
    Poder modificar la las tasas de interes correspondientes al 2 semestre.

4.	Detalle los pasos, en lenguaje natural, necesarios para construir la alternativa que usa SUBCONSULTA.
    - Cumplir con el filtro de las transacciones entre junio y diciembre (no importando el año).
    - Sacar el promedio de montos Total de transacciones.
    - Mostra los resultados odenados
    - Poblar la tabla seleccion_tipo_transaccion
    - Actualizar los valores de la tasa de interes filtradas por la antes creada (seleccion_tipo_transaccion)
    
5.	Detalle los pasos, en lenguaje natural, necesarios para construir la alternativa que usa OPERADOR SET.
    Con estos operadores intente de varias formas pero no tuve la claridad para resolverlo, de igual manera deje la consulta
    hasta donde pude.

***************************************************************************************************************/