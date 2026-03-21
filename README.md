# ServerlessPriceWatch 

**ServerlessPriceWatch** est un outil de suivi de prix automatisé. Il utilise une fonction **AWS Lambda** (Python) pour scraper des pages produits, extraire les prix et stocker l'historique dans une table **DynamoDB**.

Le projet est conçu pour être testé localement sans frais grâce à **LocalStack** et déployé via **Terraform**.

## Architecture
* **Logiciel de Scraping** : Python 3.9 (BeautifulSoup4 & Requests).
* **Base de données** : AWS DynamoDB (Table : `WatchDogProducts`).
* **Infrastructure** : Terraform pour la création des ressources.
* **Environnement Local** : LocalStack via Docker Compose.

---

## Comment l'activer

La méthode la plus simple consiste à utiliser le fichier `Makefile` fourni qui automatise toutes les étapes.

### 1. Prérequis
* Docker et Docker Compose.
* L'outil `make` installé sur votre système.

### 2. Lancement complet
Ouvrez un terminal à la racine du projet et exécutez la commande suivante :
```bash
make all
```
Cette commande unique va :
1.  Installer les dépendances Python nécessaires dans le dossier de la Lambda.
2.  Démarrer le conteneur **LocalStack** en arrière-plan.
3.  Initialiser et appliquer la configuration **Terraform** pour créer la base de données et la fonction Lambda.

### 3. Tester le scraper
Une fois le déploiement terminé, vous pouvez simuler le suivi d'un produit (par exemple, un iPhone 15) avec cette commande :
```bash
make invoke
```
Le résultat du scraping sera enregistré dans un fichier `output.json` et affiché dans votre terminal.

---

## Commandes utiles

* **Voir les logs** : `make logs` pour surveiller l'activité de LocalStack.
* **Arrêter le projet** : `make clean` pour supprimer les conteneurs et les fichiers temporaires de build.
* **Supprimer l'infrastructure** : `make destroy` pour supprimer uniquement les ressources AWS créées.

## Structure du projet
* `src/` : Contient le script de scraping (`scraper.py`).
* `terraform/` : Fichiers de configuration de l'infrastructure AWS.
* `docker-compose.yaml` : Définition des services pour l'environnement local (LocalStack, Terraform, CLI).
