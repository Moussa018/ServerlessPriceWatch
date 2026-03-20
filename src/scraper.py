import json
import boto3
import requests
from bs4 import BeautifulSoup
import os

def handler(event, context):
    lh = os.environ.get("LOCALSTACK_HOSTNAME", "localhost")
    endpoint_url = f"http://{lh}:4566"
    
    print(f"Connexion à DynamoDB via : {endpoint_url}")
    
    dynamodb = boto3.resource('dynamodb', endpoint_url=endpoint_url, region_name="us-east-1")
    table = dynamodb.Table('WatchDogProducts')

    url = event.get('url', 'https://www.amazon.fr/dp/B0CHX5T4S8')
    product_id = event.get('product_id', 'iphone-15')

    headers = {"User-Agent": "Mozilla/5.0"}
    
    try:
        #  Scraping
        res = requests.get(url, headers=headers, timeout=15)
        soup = BeautifulSoup(res.text, 'html.parser')
        
        # On cherche le prix 
        price_tag = soup.find("span", {"class": "a-price-whole"}) or soup.find("span", {"id": "priceblock_ourprice"})
        price = price_tag.text.replace(',', '').strip() if price_tag else "999" 

        # Sauvegarde
        table.put_item(Item={
            'product_id': product_id,
            'url': url,
            'current_price': str(price)
        })
        
        return {"status": "success", "product": product_id, "price": price}

    except Exception as e:
        print(f"ERREUR : {str(e)}")
        return {"status": "error", "message": str(e)}
