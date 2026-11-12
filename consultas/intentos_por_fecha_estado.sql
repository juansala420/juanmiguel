-- Cantidad de intentos por fecha y estado.
-- Cuenta todos los intentos, de cualquier estado. Sin filtro de fechas: cubre
-- todas las fechas proyectadas que tengan archivo en S3.
SELECT
    fecha,
    estado,
    count(*) AS total_intentos
FROM entregas_db.entregas
GROUP BY fecha, estado
ORDER BY fecha ASC, estado ASC;
