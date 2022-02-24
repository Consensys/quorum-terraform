output "public_ip" {
  description = "public_ip"
  value = "${aws_instance.monitoring.public_ip}"
}