# Región donde se desplegarán los recursos
variable "region" {
  description = "AWS region for deployment"
  type        = string
}

# Nombre del bucket S3 (debe ser único globalmente)
variable "bucket_name" {
  description = "Unique name for the S3 bucket"
  type        = string
}

# Nombre del propietario para los tags
variable "owner_name" {
  description = "Owner name for tagging resources"
  type        = string
}