terraform {
  required_version = ">= 1.5" # Versión mínima requerida de Terraform

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Provider oficial de AWS
    }
  }
}

# Configura el provider AWS usando la región pasada por variable
provider "aws" {
  region = var.region
}

# Bucket S3 que alojará la página web estática
resource "aws_s3_bucket" "website_bucket" {
  bucket = var.bucket_name

  # Tags obligatorios solicitados en el examen
  tags = {
    Environment = "dev"
    Owner       = var.owner_name
    Project     = "Betek"
  }
}

# 🔴 RECURSO CLAVE EN S3 MODERNO (evita uso de ACLs)
# Controla la propiedad de los objetos para permitir políticas públicas
resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.website_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Habilita el hosting estático del bucket
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html" # Archivo principal que se mostrará al abrir la URL
  }
}

# Permite acceso público al bucket para que el navegador pueda visualizar la página
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Política que habilita lectura pública del contenido del bucket
resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "PublicReadGetObject",
      Effect    = "Allow",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.website_bucket.arn}/*"
    }]
  })
}

# Sube el archivo index.html al bucket SIN usar ACL
resource "aws_s3_object" "index_file" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"

  # Espera a que el bucket tenga ownership correcto antes de subir el objeto
  depends_on = [
    aws_s3_bucket_website_configuration.website_config,
    aws_s3_bucket_ownership_controls.ownership
  ]
}