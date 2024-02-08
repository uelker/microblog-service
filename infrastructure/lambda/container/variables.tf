variable "image_url" {
  description = "The URL of the Docker image to use for the microblog service"
  type        = string
}

variable "function_memory" {
  description = "The amount of memory to allocate to the function"
  type        = number
  default     = 256
}
