# Example Project 

ECS First run sample project 
https://console.aws.amazon.com/ecs/home#/firstRun 

Getting started ECS
https://www.youtube.com/watch?v=2oXVYxIPs88


## How to create ecr and ecs jobs
https://particule.io/en/blog/cicd-ecr-ecs/












# Initialize the project 
```
terraform init -backend-config=../init/init_dev.tfvars -input=false


terraform plan -var-file=../var/plan_dev.tfvars -input=false

terraform apply -var-file=../var/plan_dev.tfvars -input=false
```
OR 
```
terraform plan -var-file=../var/plan_dev.tfvars -input=false -out run.plan
terraform apply run.plan
```

# Setup Docker application
https://omindu.medium.com/getting-started-with-amazon-ecr-a9c00f72eee4 

https://docs.aws.amazon.com/AmazonECR/latest/userguide/getting-started-cli.html 

1. Configure Docker with AWS ECR credentials
```
aws ecr get-login-password — region <account-region> | docker login — username AWS — password-stdin xxxxxx.dkr.ecr.<region>.amazonaws.com/<repo-name>
ex:
aws ecr get-login-password — region us-east-1 | docker login — username AWS — password-stdin xxxxxx.dkr.ecr.us-east-1.amazonaws.com/my-website
```
If the authentication is successful, you’ll get the below message
```
Login Succeeded
```

2. Pushing a Docker image to ECR
```
ocker build -t <image-name>:<image-version> .
ex:
docker build -t my-website:v1.0.0 .
```

```
docker tag <image-name>:<image-version> xxxxxx.dkr.ecr.<region>.amazonaws.com/<repo-name>:<image-version>
ex:
docker tag my-website:v1.0.0 xxxxxx.dkr.ecr.us-east-1.amazonaws.com/my-website:v1.0.0
```
```
docker push xxxxxx.dkr.ecr.<region>.amazonaws.com/<repo-name>:<image-version>
ex:
docker push xxxxxx.dkr.ecr.us-east-1.amazonaws.com/my-website:v1.0.0
```

3. Pulling a Docker image from ECR
```
docker pull xxxxxx.dkr.ecr.<region>.amazonaws.com/<repo-name>:<image-version>
ex:
docker pull xxxxxx.dkr.ecr.us-east-1.amazonaws.com/my-website:v1.0.0
```

4. Referring an ECR image in a Dockerfile
```
FROM xxxxxx.dkr.ecr.<region>.amazonaws.com/<repo-name>:<image-version>
ex:
FROM xxxxxx.dkr.ecr.us-east-1.amazonaws.com/my-website:v1.0.0
```

5. Delete an image

aws ecr batch-delete-image \
      --repository-name my-website \
      --image-ids imageTag=v1.0.0


6. Delete a repository

aws ecr delete-repository \
      --repository-name my-website \
      --force


