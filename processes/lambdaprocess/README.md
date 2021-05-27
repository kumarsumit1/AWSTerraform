
# Initialize the project 

terraform init -backend-config=../init/init_dev.tfvars


terraform plan -var-file=../var/plan_dev.tfvars
   

terraform apply-var-file=var/plan_dev.tfvars

