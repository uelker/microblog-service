variable "source_file" {
  description = "The path to the microblog-service app to be zipped"
  type        = string
}

variable "function_memory" {
  description = "The amount of memory to allocate to the function"
  type        = number
  default     = 256
}
