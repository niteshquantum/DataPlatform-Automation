variable "sql_instance" {
  description = "SQL Server Instance Name"
  type        = string
}

variable "sql_port" {
  description = "SQL Server TCP Port"
  type        = string
}

variable "sql_database" {
  description = "Database Name"
  type        = string
}

variable "sql_sa_password" {
  description = "SQL Server SA Password"
  type        = string
  sensitive   = true
}

variable "sql_installer" {
  description = "SQL Server Installer File"
  type        = string
}

variable "sql_download_url" {
  description = "SQL Server Download URL"
  type        = string
}