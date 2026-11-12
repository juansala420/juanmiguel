-- Verificación de la incorporación del 2026-10-03.
-- El día 3 se consultó solo subiendo su archivo: sin crawlers, MSCK REPAIR TABLE,
-- ALTER TABLE ADD PARTITION ni cambios en la tabla. Son tres consultas
-- independientes: en la consola de Athena se ejecuta cada una por separado.

-- 1. Los seis registros del 2026-10-03.
--    Resultado: resultados/final/verificacion_tercer_dia.csv
SELECT
    fecha,
    id_envio,
    ciudad,
    transportadora,
    estado,
    duracion_minutos
FROM entregas_db.entregas
WHERE fecha = '2026-10-03'
ORDER BY id_envio ASC;

-- 2. Conteos por estado del 2026-10-03.
--    Resultado: resultados/final/verificacion_tercer_dia_conteo_estados.csv
SELECT
    fecha,
    estado,
    count(*) AS total_intentos
FROM entregas_db.entregas
WHERE fecha = '2026-10-03'
GROUP BY fecha, estado
ORDER BY estado ASC;

-- 3. Total de registros de la tabla: 18, seis por cada una de las tres fechas.
--    Resultado: resultados/final/verificacion_total_registros.csv
SELECT
    count(*) AS total_registros,
    count(DISTINCT fecha) AS fechas_con_datos
FROM entregas_db.entregas;
