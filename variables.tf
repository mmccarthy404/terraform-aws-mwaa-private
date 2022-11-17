variable "region" {
  description = "Region to deploy all infrastructure to"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_id" {
  description = "ID of VPC to deploy all infrastructure to"
  type        = string
}

variable "ca_domain_name" {
  description = "Name of CodeArtifact domain"
  type        = string
  default     = "mwaa"
}

variable "ca_repo_name" {
  description = "Name of CodeArtifact repo"
  type        = string
  default     = "mwaa_repo"
}

variable "airflow_version" {
  description = "Version of Airflow to deploy on MWAA"
  type        = string
  default     = "2.2.2"
}

variable "environment_name" {
  description = "Environment name of MWAA cluster"
  type        = string
}

variable "environment_class" {
  description = "Environment class of MWAA cluster"
  type        = string
  default     = "mw1.small"
}

variable "s3_name" {
  description = "Name of S3 bucket to store DAGs, plugins and requirements files"
  type        = string
}

variable "s3_dags_path" {
  description = "Relative path to DAGs folder on S3"
  type        = string
  default     = "dags/"
}

variable "s3_requirements_path" {
  description = "Relative path to requirements file on S3"
  type        = string
  default     = "requirements.txt"
}

variable "airflow_configuration_options" {
  description = "Optional airflow configuration options"
  type        = map(string)
  default = {
    "webserver.expose_config" = true
  }
}