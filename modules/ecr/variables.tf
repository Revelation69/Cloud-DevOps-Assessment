variable "frontend_repository_name" {
  description = "Name of the frontend repository"
  type        = string
}

variable "frontend_repository_type" {
  description = "Type of the frontend repository"
  type        = string
  default     = "private"
}

variable "frontend_create_lifecycle_policy" {
  description = "Whether to create a lifecycle policy for the frontend repository"
  type        = bool
  default     = false
}

variable "backend_repository_name" {
  description = "Name of the backend repository"
  type        = string
}

variable "backend_repository_type" {
  description = "Type of the backend repository"
  type        = string
  default     = "private"
}

variable "backend_create_lifecycle_policy" {
  description = "Whether to create a lifecycle policy for the backend repository"
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(any)
  default = {}
}