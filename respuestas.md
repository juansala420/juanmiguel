# Respuestas

## 1. ¿Por qué se pudo consultar el tercer día sin registrar una partición nueva?

Esto fue posible porque la tabla entregas_db.entregas utiliza partition projection, lo que significa que Athena no necesita que las particiones estén registradas en Glue para poder consultar los datos
Desde el primer despliegue, en el archivo infraestructura/principal.tf, se configuró la proyección de fechas con el tipo date, el formato yyyy-MM-dd, un intervalo de un día y un rango desde 2026-10-01 hasta 2026-10-03. También se definió la ruta de los archivos en S3 con el formato `entregas/fecha=${fecha}/`
Esto permite que Athena calcule automáticamente las fechas que debe consultar y construya las rutas correspondientes en S3
Por eso, aunque el 3 de octubre todavía no tuviera ningún archivo, Athena ya tenía configurada esa fecha dentro del rango de proyección. Cuando subimos el archivo entregas/fecha=2026-10-03/entregas.csv, Athena pudo encontrarlo y leer sus registros sin necesidad de crear una partición nueva
Las evidencias muestran que al consultar Glue con aws glue get-partitions aparecen 0 particiones, tanto antes como después de cargar el tercer día. En resultados/final/verificacion_tercer_dia.csv aparecen los seis registros correspondientes al 3 de octubre, desde ENV-013 hasta ENV-018. Además, en resultados/final/verificacion_total_registros.csv se confirma que hay 18 registros distribuidos en las tres fechas
En conclusión, pudimos consultar el tercer día porque ya estaba incluido en el rango de la proyección. Lo único que hacía falta era subir el archivo a la ruta correspondiente de S3. No fue necesario utilizar un crawler ni registrar particiones manualmente

## 2. Si se subiera un archivo para el 4 de octubre manteniendo la configuración actual, ¿qué resultado se esperaría y qué se debería modificar para incluirlo?

Si subiéramos un archivo correspondiente al 4 de octubre sin modificar la configuración actual, el archivo quedaría almacenado en S3, pero Athena no podría leerlo

Esto sucede porque el rango de la proyección termina el 3 de octubre. Por lo tanto, Athena solamente tiene en cuenta las fechas del 1, 2 y 3 de octubre y no genera la ruta correspondiente al día 4

En ese caso, si ejecutamos SELECT count(*) FROM entregas_db.entregas, seguiríamos obteniendo 18 registros. Si consultamos específicamente la fecha 2026-10-04, obtendríamos cero registros y las consultas agrupadas por fecha seguirían mostrando únicamente los tres días anteriores

Para solucionar esto, tendríamos que modificar el rango de fechas de la proyección en Terraform

En este caso, la fecha final se controla mediante la variable fecha_fin_proyeccion, que se encuentra en infraestructura/variables.tf. Lo único que tendríamos que hacer es cambiarla para que incluya el 4 de octubre y después ejecutar el siguiente comando

en bash
cd infraestructura
terraform apply -var fecha_fin_proyeccion=2026-10-04


Con esto, Terraform actualizaría la configuración de la tabla en Glue y Athena ya podría incluir el 4 de octubre dentro de las fechas que consulta

Una vez aplicado el cambio, solo tendríamos que subir el archivo a la ruta correspondiente entregas/fecha=2026-10-04/entregas.csv, manteniendo el mismo esquema de cinco columnas que los archivos anteriores

También existe la posibilidad de configurar un rango dinámico, por ejemplo 2026-10-01,NOW, para que la proyección incluya automáticamente las fechas hasta el día actual. Esto sería útil si se van a recibir archivos diariamente

Sin embargo, para este ejercicio se mantuvo un rango específico del 1 al 3 de octubre, tal como lo pedía el enunciado

En conclusión, para incluir nuevos días no necesitamos crear particiones manualmente. Simplemente debemos ampliar el rango de fechas de la proyección y asegurarnos de que los archivos estén guardados en la ruta correcta de S3
