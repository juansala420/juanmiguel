-- Resumen diario de ventas: una fila por fecha_venta.
-- ingreso_total multiplica cantidad (INTEGER) por precio_unitario (DECIMAL(12,2)),
-- así que la suma sigue siendo DECIMAL y conserva los dos decimales.
select
    fecha_venta,
    count(*) as numero_ventas,
    sum(cantidad) as unidades_vendidas,
    sum(cantidad * precio_unitario) as ingreso_total
from {{ ref('stg_ventas') }}
group by fecha_venta
