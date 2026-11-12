variable "region" {
  description = "Región de AWS donde se crean los recursos"
  type        = string
  default     = "us-east-1"
}

variable "nombre_bucket" {
  description = "Nombre del bucket S3 del ejercicio; debe ser único en todo AWS"
  type        = string
  default     = "de-final-entregas-gr01-user-6"
}

variable "prefijo_datos" {
  description = "Prefijo de los CSV de entregas dentro del bucket, terminado en /"
  type        = string
  default     = "entregas/"

  validation {
    condition     = endswith(var.prefijo_datos, "/")
    error_message = "El prefijo de datos debe terminar en /."
  }
}

variable "prefijo_resultados" {
  description = "Prefijo de los resultados de Athena dentro del bucket, terminado en /"
  type        = string
  default     = "resultados-athena/"

  validation {
    condition     = endswith(var.prefijo_resultados, "/")
    error_message = "El prefijo de resultados debe terminar en /."
  }
}

variable "nombre_base_datos" {
  description = "Nombre de la base de datos de Glue Data Catalog"
  type        = string
  default     = "entregas_db"
}

variable "nombre_tabla" {
  description = "Nombre de la tabla externa de entregas"
  type        = string
  default     = "entregas"
}

variable "nombre_workgroup" {
  description = "Nombre del workgroup de Athena"
  type        = string
  default     = "entregas-wg"
}

variable "fecha_inicio_proyeccion" {
  description = "Primera fecha proyectada (yyyy-MM-dd), incluida"
  type        = string
  default     = "2026-10-01"
}

variable "fecha_fin_proyeccion" {
  description = "Última fecha proyectada (yyyy-MM-dd), incluida"
  type        = string
  default     = "2026-10-03"
}
