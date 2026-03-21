import json
import boto3
import requests
from bs4 import BeautifulSoup
from datetime import datetime, timezone
import os

def handler(event, context):
    endpoint_url = os.environ.get("AWS_ENDPOINT_URL")
    table_name = os.environ.get("TABLE_NAME", "WatchDogProducts")
    region = os.environ.get("AWS_REGION", "us-east-1")
    
    print(f"Connexion à DynamoDB ({table_name}) via : {endpoint_url or 'AWS Managed'}")
    
    dynamodb = boto3.resource('dynamodb', endpoint_url=endpoint_url, region_name=region)
    table = dynamodb.Table(table_name)

    # Récupération des paramètres de l'événement
    url = event.get('url', 'https://www.amazon.fr/dp/B0CHX5T4S8')
    product_id = event.get('product_id', 'iphone-15')

    # User-Agent
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
        "Accept-Language": "fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7"
    }
    
    try:
        # Scraping
        res = requests.get(url, headers=headers, timeout=15)
        res.raise_for_status() 
        
        soup = BeautifulSoup(res.text, 'html.parser')
        
        # Extraction du prix 
        price = None
     
        selectors = [
            ("span", {"class": "a-price-whole"}),
            ("span", {"id": "priceblock_ourprice"}),
            ("span", {"id": "priceblock_dealprice"}),
            ("span", {"class": "a-offscreen"})
        ]
        
        for tag, attrs in selectors:
            price_tag = soup.find(tag, attrs)
            if price_tag:
                # Nettoyage : on garde les chiffres, on remplace la virgule par un point
                price_raw = price_tag.text.replace(',', '.').replace('\xa0', '').strip()
                # Extraction basique pour ne garder que le prix numérique
                price = "".join(filter(lambda x: x.isdigit() or x == '.', price_raw))
                if price: break

        if not price:
            print(f"Attention : Prix non trouvé pour {product_id}")

        table.put_item(Item={
            'product_id': product_id,
            'url': url,
            'current_price': str(price),
            'timestamp': datetime.now(timezone.utc).isoformat()
        })
        
        return {
            "statusCode": 200,
            "body": json.dumps({
                "status": "success",
                "product": product_id,
                "price": price,
                "endpoint_used": endpoint_url
            })
        }

    except Exception as e:
        print(f"ERREUR CRITIQUE : {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"status": "error", "message": str(e)})
        }