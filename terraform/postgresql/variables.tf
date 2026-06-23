variable "database_name" {
  type = string
}

variable "schema_name" {
  type = string
}

variable "postgres_user" {
  type = string
}

variable "preferred_port" {
  type = number
}

variable "max_retries" {
  type = number
}

variable "retry_interval" {
  type = number
}