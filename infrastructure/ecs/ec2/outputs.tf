output "microblog_service_ec2_alb_dns_name" {
  description = "The DNS name of the ALB to access the microblog-service"
  value       = aws_alb.ecs_alb.dns_name
}
