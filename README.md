# ServerlessPriceWatch__v1
> Un tracker de prix automatisé et Serverless.

Ce projet déploie une infrastructure Cloud complète sur **LocalStack** via **Terraform**.

##  Architecture
- **AWS Lambda** (Python + BeautifulSoup) : Le scraper qui extrait les prix.
- **Amazon DynamoDB** : Base NoSQL pour l'historique des prix.

##  Installation rapide
1. `docker-compose up -d`
2. `cd terraform && terraform init && terraform apply --auto-approve`

