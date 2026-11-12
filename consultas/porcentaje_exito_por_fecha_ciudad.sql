-- Porcentaje de entregas exitosas por fecha y ciudad: 100 × exitosas / total de intentos.
-- El denominador incluye los tres estados. El CAST a double evita la división entera
-- y el CAST final a decimal(5,2) conserva siempre dos decimales.
SELECT
    fecha,
    ciudad,
    CAST(
        round(100 * CAST(count_if(estado = 'entregado') AS double) / count(*), 2)
        AS decimal(5, 2)
    ) AS porcentaje_exito
FROM entregas_db.entregas
GROUP BY fecha, ciudad
ORDER BY fecha ASC, ciudad ASC;
