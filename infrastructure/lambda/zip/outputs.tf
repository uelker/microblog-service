output "microblog_service_url" {
  description = "The URL of the microblog-service"
  value       = aws_lambda_function_url.microblog_service.function_url
}
