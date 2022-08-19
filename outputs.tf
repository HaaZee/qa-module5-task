output "ci_public_ip" {
  value = module.ci.vm_public_ip
}

output "deployment_public_ip" {
  value = module.deployment.vm_public_ip
}

output "vm_private_key" {
  value     = tls_private_key.demokey.private_key_pem
  sensitive = true
}