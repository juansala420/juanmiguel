-- Duración promedio de las entregas exitosas del 2 de octubre de 2026.
-- Solo estado 'entregado': los intentos fallidos tienen duración 0 y no deben
-- bajar el promedio. Un único valor para todas las ciudades y transportadoras.
SELECT
    fecha,
    CAST(round(avg(duracion_minutos), 2) AS decimal(10, 2)) AS duracion_promedio_minutos
FROM entregas_db.entregas
WHERE fecha = '2026-10-02'
  AND estado = 'entregado'
GROUP BY fecha;
