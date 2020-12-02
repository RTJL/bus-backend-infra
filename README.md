terraform workspace new staging
terraform workspace select staging
terraform apply -var-file=vars/dev.tfvars