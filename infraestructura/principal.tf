terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Proyecto = "DE-Final-Entregas"
      Gestion  = "Terraform"
    }
  }
}

locals {
  # Prefijos dentro del bucket: son parte de las claves, no carpetas que haya que crear.
  ubicacion_datos      = "s3://${aws_s3_bucket.entregas.bucket}/${var.prefijo_datos}"
  ubicacion_resultados = "s3://${aws_s3_bucket.entregas.bucket}/${var.prefijo_resultados}"
}

# ---------------------------------------------------------------------------
# 1. Bucket S3 privado para los datos y los resultados de Athena
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "entregas" {
  bucket = var.nombre_bucket
}

# Bloquea cualquier acceso público al bucket y a sus objetos.
resource "aws_s3_bucket_public_access_block" "entregas" {
  bucket = aws_s3_bucket.entregas.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# El dueño del bucket es dueño de todos los objetos; las ACL quedan deshabilitadas.
resource "aws_s3_bucket_ownership_controls" "entregas" {
  bucket = aws_s3_bucket.entregas.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "entregas" {
  bucket = aws_s3_bucket.entregas.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ---------------------------------------------------------------------------
# 2. Base de datos de Glue Data Catalog
# ---------------------------------------------------------------------------
resource "aws_glue_catalog_database" "entregas" {
  name        = var.nombre_base_datos
  description = "Catálogo de los intentos de entrega diarios"
}

# ---------------------------------------------------------------------------
# 3. Tabla externa sobre los CSV, con partition projection por fecha
# ---------------------------------------------------------------------------
resource "aws_glue_catalog_table" "entregas" {
  database_name = aws_glue_catalog_database.entregas.name
  name          = var.nombre_tabla
  description   = "Intentos de entrega; una carpeta fecha=yyyy-MM-dd por día"
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL       = "TRUE"
    classification = "csv"

    # Cada archivo trae una línea de encabezado que no es un registro.
    "skip.header.line.count" = "1"

    # Partition projection: Athena calcula las particiones con estas reglas
    # durante la consulta, sin registrarlas en el catálogo.
    "projection.enabled"             = "true"
    "projection.fecha.type"          = "date"
    "projection.fecha.format"        = "yyyy-MM-dd"
    "projection.fecha.range"         = "${var.fecha_inicio_proyeccion},${var.fecha_fin_proyeccion}"
    "projection.fecha.interval"      = "1"
    "projection.fecha.interval.unit" = "DAYS"

    # Prefijo de cada partición, terminado en "/". "$${fecha}" deja el texto
    # literal ${fecha} para que Athena lo reemplace con cada fecha proyectada.
    "storage.location.template" = "${local.ubicacion_datos}fecha=$${fecha}/"
  }

  # La fecha sale de la ruta, no del archivo: es clave de partición, no columna.
  partition_keys {
    name    = "fecha"
    type    = "string"
    comment = "Fecha del archivo, tomada de la carpeta fecha=yyyy-MM-dd"
  }

  storage_descriptor {
    location      = local.ubicacion_datos
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "csv"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim"          = ","
        "serialization.format" = ","
      }
    }

    # Las cinco columnas del CSV, en el orden del encabezado.
    columns {
      name    = "id_envio"
      type    = "string"
      comment = "Identificador único del envío"
    }
    columns {
      name    = "ciudad"
      type    = "string"
      comment = "Ciudad del intento de entrega"
    }
    columns {
      name    = "transportadora"
      type    = "string"
      comment = "Transportadora responsable del intento"
    }
    columns {
      name    = "estado"
      type    = "string"
      comment = "entregado, destinatario_ausente o direccion_incorrecta"
    }
    columns {
      name    = "duracion_minutos"
      type    = "int"
      comment = "Minutos de la entrega; 0 en los intentos fallidos"
    }
  }
}

# ---------------------------------------------------------------------------
# 4. Workgroup de Athena que escribe los resultados en resultados-athena/
# ---------------------------------------------------------------------------
resource "aws_athena_workgroup" "entregas" {
  name        = var.nombre_workgroup
  description = "Consultas del ejercicio de entregas"

  # Permite eliminar el workgroup aunque tenga historial de consultas.
  force_destroy = true

  configuration {
    # Las consultas no pueden cambiar la ubicación de resultados del workgroup.
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false

    result_configuration {
      output_location = local.ubicacion_resultados

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}
