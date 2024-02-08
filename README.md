# Microblog

Microblog is a web application that allows users to create, read, update, and delete posts. Also a healthcheck endpoint
is available. This Project uses the Spring Boot 3 Framework and is built with Maven. The GraalVM Native Image Support
is used to create a native image of the application. The deployment takes place on the AWS Cloud with Terraform. The web
application can be executed as a Lambda function (as a zip or container image) or as a container in Amazon Elastic
Container Service (with ec2 instances or fargate). For this purpose, the application is zipped after it has been built
or is converted into a docker image and pushed to a container registry. Furthermore the application data is stored in a
noSQL Amazon DynamoDB database.

## Prerequisites

- GraalVM for JDK 21
- Docker-API compatible container runtime such as Podman or Docker
- Terraform
- AWS credentials configured with necessary permissions
- DynamoDB table (*Posts*) with primary key "id"
- S3 Bucket (*microblog-service-infrastructure-state*) for storing the terraform state file
- ECR Repository (*microblog-service*) for storing the container image

### Build the application locally

```bash
cd app
./mvnw -Pnative native:compile
```

### Build the container image and push it to the ECR repository

```bash
# Authenticate to your default registry
aws ecr get-login-password --region region | docker login --username AWS --password-stdin aws_account_id.dkr.ecr.eu-central-1.amazonaws.com

# Create a Docker image
docker build --build-arg APP_FILE=microblog-service -t microblog-service:latest .

# Tag the image to push to your repository
docker tag microblog-service:latest aws_account_id.dkr.ecr.region.amazonaws.com/microblog-service:latest

# Push the image
docker push aws_account_id.dkr.ecr.region.amazonaws.com/microblog-service:latest
```

## Deploy the application to AWS

To deploy the application as zip file to AWS Lambda, save the path to the native image and pass it to the terraform
variable *source_file*

```bash
cd infrastructure/lambda/zip
terraform init
terraform apply -var="source_file=path_to_native_image"
```

To deploy the application as container image to AWS ECS or Lambda, save the path to the container image in ECR and
pass it to
the
terraform
variable *image_url*

```bash
cd infrastructure/ecs/fargate
terraform init
terraform apply -var="image_url=aws_account_id.dkr.ecr.region.amazonaws.com/microblog-service:latest" 
```

## Access the deployed application

Copy the URL from the terraform output

```bash
# Following endpoints are available
curl -X GET https://{url}/microblog-service/healthcheck
curl -X POST https://{url}/microblog-service/post-api/v1/posts -H "Content-Type: application/json" -d '{"title":"My first post","content":"Hello World", "status":"IN_PROGRESS"}'
curl -X GET https://{url}/microblog-service/post-api/v1/posts/{id}
curl -X PATCH https://{url}/microblog-service/post-api/v1/posts/{id} -H "Content-Type: application/json" -d '{"status":"PUBLISHED"}'
curl -X DELETE https://{url}/microblog-service/post-api/v1/posts/{id}
```
