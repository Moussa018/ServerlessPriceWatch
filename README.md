# ServerlessPriceWatch

**ServerlessPriceWatch** est un outil de suivi des prix automatisé conçu avec une architecture Cloud-native. Il utilise le web scraping pour surveiller les prix des produits et stocke les données. 
Le projet est entièrement testable localement grâce à **LocalStack**.

## Architecture

Le projet repose sur les services AWS suivants :
* **AWS Lambda** : Logique de scraping en Python 3.9.
* **AWS DynamoDB** : Base de données NoSQL pour l'historique des prix.
* **Lambda Layers** : Gestion optimisée des dépendances (`requests`, `BeautifulSoup4`).
* **Terraform** : Infrastructure as Code (IaC) pour déployer les ressources.
* **LocalStack** : Émulateur AWS local pour le développement sans frais.



## Optimisation : Lambda Layers

Pour ce projet, nous utilisons les **Lambda Layers** pour séparer le code métier des bibliothèques volumineuses.

**Avantages :**
* **Déploiements rapides** : Seul le script `scraper.py` (quelques Ko) est mis à jour lors des modifications de code.
* **Propreté du code** : Le dossier `src/` reste léger et ne contient pas les dossiers de dépendances (comme `requests/` ou `bs4/`).
* **Standard professionnel** : Reproduit la gestion des dépendances utilisée en production.



##  Installation et Configuration

### 1. Préparer les dépendances de la Layer
Pour que la Layer fonctionne, les bibliothèques doivent être installées dans un dossier spécifique nommé `python/` :
```bash
mkdir -p lambda_layers/python
pip install -r src/requirements.txt -t lambda_layers/python/
```

### 2. Lancer l'environnement local
Démarrez LocalStack via Docker Compose :
```bash
docker-compose up -d
```

### 3. Déployer l'infrastructure
Utilisez Terraform pour créer la table DynamoDB, la Layer et la fonction Lambda :
```bash
cd terraform
terraform init
terraform apply --auto-approve
```

## Utilisation

Une fois déployé, vous pouvez invoquer la fonction manuellement en passant une URL Amazon et un ID de produit :

```bash
awslocal lambda invoke \
  --function-name PriceScraper \
  --payload '{"url": "https://www.amazon.fr/dp/B0CHX5T4S8", "product_id": "iphone-15"}' \
  output.json
```

## Structure du Projet

```text
.
├── src/
│   ├── scraper.py       # Code source de la Lambda
│   └── requirements.txt # Dépendances Python
├── terraform/
│   ├── main.tf          # Définition des ressources AWS
│   └── provider.tf      # Configuration LocalStack
├── lambda_layers/
│   └── python/          # Dépendances installées pour la Layer
├── docker-compose.yaml  # Configuration LocalStack
└── README.md
```
