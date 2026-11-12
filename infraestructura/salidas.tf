output "bucket" {
  description = "Nombre del bucket S3 del ejercicio"
  value       = aws_s3_bucket.entregas.bucket
}

output "bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.entregas.arn
}

output "ubicacion_datos" {
  description = "Prefijo S3 donde se cargan los CSV de entregas"
  value       = local.ubicacion_datos
}

output "ubicacion_resultados_athena" {
  description = "Prefijo S3 donde Athena escribe los resultados"
  value       = local.ubicacion_resultados
}

output "base_datos" {
  description = "Base de datos de Glue Data Catalog"
  value       = aws_glue_catalog_database.entregas.name
}

output "tabla" {
  description = "Tabla externa con partition projection"
  value       = aws_glue_catalog_table.entregas.name
}

output "tabla_completa" {
  description = "Nombre calificado para usar en las consultas"
  value       = "${aws_glue_catalog_database.entregas.name}.${aws_glue_catalog_table.entregas.name}"
}

output "rango_proyeccion" {
  description = "Rango de fechas proyectado por la tabla"
  value       = aws_glue_catalog_table.entregas.parameters["projection.fecha.range"]
}

output "workgroup" {
  description = "Workgroup de Athena para ejecutar las consultas"
  value       = aws_athena_workgroup.entregas.name
}
