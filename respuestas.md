# Respuestas

## 1. ¿Por qué se pudo consultar el tercer día sin registrar una partición nueva?

Porque la tabla `entregas_db.entregas` no depende de particiones guardadas en el catálogo, sino
de **partition projection**. En Terraform (`infraestructura/principal.tf`) la tabla quedó con
estas reglas desde el primer despliegue:

- `projection.enabled = true` y `projection.fecha.type = date`.
- `projection.fecha.format = yyyy-MM-dd`, con `interval = 1` e `interval.unit = DAYS`.
- `projection.fecha.range = 2026-10-01,2026-10-03`.
- `storage.location.template = s3://de-final-entregas-gr01-user-6/entregas/fecha=${fecha}/`.

Con esas reglas, Athena no le pregunta a Glue qué particiones existen. En cada consulta calcula
las fechas posibles del rango (01, 02 y 03 de octubre) y, para cada una, arma el prefijo de S3
reemplazando `${fecha}` en la plantilla. Luego lee los objetos que encuentre en esos prefijos.

El 3 de octubre ya estaba dentro del rango desde el `terraform apply` inicial
(`evidencias/aplicacion_terraform.txt`, `evidencias/outputs.json`, salida `rango_proyeccion`).
Antes de subir su archivo, ese prefijo estaba vacío y por eso las consultas iniciales solo
devolvieron 12 registros: la proyección no crea datos ni garantiza que existan. Al subir
`entregas/fecha=2026-10-03/entregas.csv`, el mismo prefijo que Athena ya calculaba empezó a tener
un objeto, y la siguiente consulta lo leyó.

La evidencia lo confirma:

- `aws glue get-partitions` devuelve `0` particiones antes y después de cargar el día 3: nunca se
  registró ninguna, ni con crawler, ni con `MSCK REPAIR TABLE`, ni con `ALTER TABLE ADD PARTITION`.
- `resultados/final/verificacion_tercer_dia.csv` muestra los seis registros del 2026-10-03
  (`ENV-013` a `ENV-018`) y `resultados/final/verificacion_total_registros.csv` muestra 18
  registros en 3 fechas.
- `resultados/final/intentos_por_fecha_estado.csv` y
  `resultados/final/porcentaje_exito_por_fecha_ciudad.csv` incluyen el día 3 y coinciden con las
  referencias finales. Las consultas son las mismas de la etapa inicial, sin cambios. Los
  identificadores de cada ejecución están en `evidencias/ejecuciones_athena.csv`.

## 2. Si se subiera un archivo para el 4 de octubre manteniendo la configuración actual, ¿qué resultado se esperaría y qué se debería modificar para incluirlo?

**Resultado esperado:** el archivo quedaría guardado en S3, pero Athena no lo leería. El rango
proyectado termina en `2026-10-03`, así que Athena nunca genera la fecha `2026-10-04` ni el prefijo
`entregas/fecha=2026-10-04/`. Las consultas no darían error; simplemente ignorarían ese archivo:

- `SELECT count(*) FROM entregas_db.entregas` seguiría devolviendo 18.
- Una consulta con `WHERE fecha = '2026-10-04'` devolvería cero filas.
- Las consultas agregadas seguirían mostrando solo tres fechas, como en `resultados/final/`.

Es la otra cara de la pregunta 1: con partition projection, el catálogo no "descubre" archivos; lo
que se puede consultar lo deciden las reglas de la tabla.

**Qué modificar:** ampliar el rango de la proyección en Terraform, no registrar una partición. En
`infraestructura/variables.tf` el fin del rango es la variable `fecha_fin_proyeccion`; basta con
cambiarla a `2026-10-04` (o a una fecha posterior, para cubrir los próximos días) y aplicar:

```bash
cd infraestructura
terraform apply -var fecha_fin_proyeccion=2026-10-04
```

Terraform solo actualiza la propiedad `projection.fecha.range` de la tabla. Desde ese momento el 4
de octubre queda dentro de la proyección y su archivo se consulta igual que el día 3: subirlo y
consultar, sin crawlers ni particiones nuevas. El archivo debe respetar la misma ruta
(`entregas/fecha=2026-10-04/entregas.csv`) y el mismo esquema de cinco columnas.

Si se espera recibir un archivo cada día, también se podría usar un rango relativo, por ejemplo
`2026-10-01,NOW`, para que la proyección avance sola con la fecha actual. En este ejercicio no se
hizo así porque el enunciado pide proyectar exactamente del 1 al 3 de octubre.
