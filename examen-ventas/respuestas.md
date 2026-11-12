# Respuestas

## 1. ¿Por qué usar `_loaded_at` y no `fecha_venta` para este control?

Porque las dos columnas responden preguntas distintas. `fecha_venta` dice **cuándo ocurrió la
venta** en el negocio; `_loaded_at` dice **cuándo llegó esa fila a `raw`**. El problema que
queremos detectar es que la carga se haya retrasado, así que lo que hay que medir es la llegada
de los datos, no la fecha de las ventas.

Con `fecha_venta` el control daría resultados equivocados:

- En este ejercicio las ventas son de enero de 2026 (`2026-01-10` a `2026-01-12`) en los tres
  escenarios. Medido con `fecha_venta`, la fuente tendría casi diez meses de antigüedad y
  freshness fallaría siempre, también en el escenario `actualizada`, que acaba de cargarse.
- Al revés, una venta antigua se puede cargar hoy, y un día sin ventas no significa que la
  carga haya fallado. La fecha del negocio no dice nada sobre si el proceso de carga está al día.

Con `_loaded_at` el control distingue los escenarios aunque los datos de negocio sean idénticos.
En la demostración, la ejecución `manual__2026-11-12T12:18:36.961068+00:00` (carga de hace unas
2 h) pasó freshness, y la ejecución `manual__2026-11-12T12:20:31.932608+00:00` falló con
`ERROR STALE` porque el máximo de `_loaded_at` tenía **30,01 h** frente al límite de 24 h
(`evidencias/desactualizada_sources.json` y `evidencias/desactualizada_log_freshness.txt`).

Este control mide la carga más reciente. Por sí solo no demuestra que hayan llegado todas las
ventas esperadas: solo que la última carga no es demasiado vieja.

## 2. ¿Por qué las pruebas de integridad no garantizan actualidad?

Porque revisan **la forma y la consistencia** de las filas que existen, no **cuándo** llegaron.
`unique`, `not_null` y la prueba `valores_ventas` comprueban que no haya identificadores
repetidos, campos vacíos, cantidades no positivas ni precios negativos. Un conjunto de datos
viejo puede cumplir todo eso perfectamente: en los tres escenarios las seis ventas son
exactamente las mismas, así que son igual de válidas con 2 h que con 30 h de antigüedad.

Además, `dbt build` no ejecuta freshness: corre modelos y pruebas, pero no compara
`_loaded_at` con la hora actual. Si el DAG solo tuviera `construir_resumen`, con la fuente de
30 h el build habría terminado en `success` (las 19 pruebas pasan con estos datos) y el
resumen se habría reconstruido con información desactualizada sin ninguna alarma.

Por eso la actualidad se comprueba aparte y **antes** de construir: `comprobar_freshness`
ejecuta `dbt source freshness` y, con la regla `all_success`, `construir_resumen` solo corre si
freshness termina bien o con advertencia. En la ejecución desactualizada, freshness quedó
`failed` y build `upstream_failed`, sin intento ni marca `INICIO dbt`
(`evidencias/estados_airflow.txt`, `evidencias/capturas/`). El resumen se conservó: es igual
antes y después del bloqueo (`evidencias/resumen_antes_bloqueo.txt` y
`evidencias/resumen_despues_bloqueo.txt`). Como los datos de negocio no cambian entre
escenarios, esa igualdad por sí sola no prueba que build no corrió; lo prueban los estados de
Airflow.
