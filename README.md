# Microblog-Service

Der Microblog-Service ist eine Webanwendung, mit der Benutzer Beiträge erstellen, lesen, editieren und löschen können.
Ein Healthcheck Endpunkt ist ebenfalls vorhanden. In diesem Projekt wird das Spring Boot Framework 3 verwendet und die
Anwendung wird unter Verwendung von Maven gebaut. Der GraalVM Native Image Support wird genutzt, um ein native Image
der Anwendung zu erzeugen. Die Bereitstellung erfolgt in der AWS Cloud mittels Terraform. Die Webanwendung kann als
Lambda Funktion (als ZIP-Datei oder Container Image) oder als Container im Amazon Elastic Container Service (mit EC2
Instanzen oder Fargate) betrieben werden. Dazu wird die Anwendung nach der Erstellung gezippt oder als Container Image
erstellt und in ein Amazon ECR Repository übertragen. Darüber hinaus werden die Anwendungsdaten in einer noSQL Amazon
DynamoDB Datenbank gespeichert.

## Voraussetzungen

- GraalVM für JDK 21
- Docker-API kompatible Container Runtime wie Podman oder Docker
- Terraform
- AWS CLI
- Konfigurierte AWS Anmeldedaten mit den erforderlichen Berechtigungen

## Erstellung der Anwendung

```bash
cd app
./mvnw -Pnative native:compile
```

## Bereitstellung der Anwendung in der AWS Cloud

#### Erstellung eines S3 Buckets für die Terraform Statusdateien

```bash
cd infrastructure
./create-s3-bucket.sh
```

#### Erstellung einer ECR Repository und einer DynamoDB Tabelle

```bash
cd infrastructure/shared
terraform init
terraform apply
```

#### Erstellung des Container Images und Übertragung in das ECR Repository

```bash
cd app
# Rufen Sie ein Authentifizierungstoken ab und authentifizieren Sie Ihren Docker-Client für Ihr Registry
aws ecr get-login-password --region region | docker login --username AWS --password-stdin aws_account_id.dkr.ecr.eu-central-1.amazonaws.com
# Erstellen Sie Ihr Docker-Image mit dem folgenden Befehl
docker build --build-arg APP_FILE=microblog-service -t microblog-service:latest .
# Nachdem die Erstellung abgeschlossen ist, taggen Sie Ihr Image, damit Sie das Image in dieses Repository übertragen können
docker tag microblog-service:latest aws_account_id.dkr.ecr.region.amazonaws.com/microblog-service:latest
# Führen Sie den folgenden Befehl aus, um dieses Image in Ihr neu erstelltes AWS Repository zu übertragen
docker push aws_account_id.dkr.ecr.region.amazonaws.com/microblog-service:latest
```

Für die Bereitstellung der Anwendung als ZIP-Datei auf AWS Lambda speichern Sie den Pfad zum native image und übergeben
ihn an die Terraform Variable *source_file*

```bash
cd infrastructure/lambda/zip
terraform init
terraform apply -var="source_file=path_to_native_image"
```

Für die Bereitstellung der Anwendung als Container Image auf Amazon ECS oder Lambda speichern Sie den Pfad zum Container
Image in ECR und übergeben ihn an die Terraform Variable *image_url*

```bash
cd infrastructure/ecs/fargate
terraform init
terraform apply -var="image_url=aws_account_id.dkr.ecr.region.amazonaws.com/microblog-service:latest" 
```

## Zugriff auf die bereitgestellte Anwendung

Kopieren Sie die URL aus der Terraform Ausgabe

```bash
# Folgende Endpunkte sind verfügbar
curl -X GET {url}/microblog-service/healthcheck
curl -X POST {url}/microblog-service/post-api/v1/posts -H "Content-Type: application/json" -d '{"title":"My first post","content":"Hello World", "status":"IN_PROGRESS"}'
curl -X GET {url}/microblog-service/post-api/v1/posts/{id}
curl -X PATCH {url}/microblog-service/post-api/v1/posts/{id} -H "Content-Type: application/json" -d '{"status":"PUBLISHED"}'
curl -X DELETE {url}/microblog-service/post-api/v1/posts/{id}
```

## E2E

Zur Überprüfung der Funktionsfähigkeit der API Endpunkte kann die Datei *post-api.http* ausgeführt werden

```bash
cd e2e
# 1. Ersetzen der url Variable durch die URL aus der Terraform Ausgabe
# 2. Ausführen aller Anfragen in der Datei post-api.http über die IDE
```

Ausführen des Lasttests mit dem Grafana k6 Tool

```bash
cd e2e
K6_WEB_DASHBOARD=true k6 run -e URL={url} k6-post-api.js
```
