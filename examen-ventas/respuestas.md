# Respuestas

## 1. ¿Por qué usar `_loaded_at` y no `fecha_venta` para este control?

Porque `fecha_venta` indica cuándo ocurrió la venta, mientras que `_loaded_at` indica cuándo llegó el registro a la tabla `raw`

Lo que queremos comprobar es si los datos están llegando a tiempo, por eso debemos utilizar `_loaded_at` y no la fecha de la venta

Si utilizáramos `fecha_venta`, los datos aparecerían como antiguos porque las ventas son de enero de 2026, incluso en el escenario donde la carga acaba de realizarse

En la demostración, una carga pasó freshness con aproximadamente 2 horas de antigüedad, mientras que otra falló al superar las 24 horas, llegando a 30,01 horas

En conclusión, `_loaded_at` permite comprobar si los datos están llegando a tiempo

## 2. ¿Por qué las pruebas de integridad no garantizan actualidad?

Porque las pruebas de integridad comprueban que los datos sean válidos, pero no cuánto tiempo llevan sin actualizarse

Pruebas como `unique`, `not_null` y `valores_ventas` verifican que no existan duplicados, campos vacíos o valores incorrectos, pero los datos pueden cumplir todo esto y seguir desactualizados

Por eso se agregó `comprobar_freshness`, que ejecuta `dbt source freshness` antes de construir el resumen. Así, si los datos están desactualizados, el proceso se detiene y evita construir el resumen con información vieja

En conclusión, la integridad comprueba que los datos estén bien y freshness comprueba que estén actualizados
