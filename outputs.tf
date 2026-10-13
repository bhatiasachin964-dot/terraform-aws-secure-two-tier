output "web_public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.web.public_ip
}

output "web_url" {
  description = "URL to test the web tier"
  value       = "http://${aws_instance.web.public_ip}"
}

output "app_private_ip" {
  description = "Private IP of the app server (not reachable from the internet)"
  value       = aws_instance.app.private_ip
}

output "bucket_name" {
  description = "Private S3 bucket"
  value       = aws_s3_bucket.data.id
}
