import json
import boto3
import cloudscraper
from bs4 import BeautifulSoup
from datetime import datetime, timezone
import os

def handler(event, context):
    endpoint_url = os.environ.get("AWS_ENDPOINT_URL")
    table_name = os.environ.get("TABLE_NAME", "WatchDogProducts")
    region = os.environ.get("AWS_REGION", "us-east-1")

    dynamodb = boto3.resource('dynamodb', endpoint_url=endpoint_url, region_name=region)
    table = dynamodb.Table(table_name)

    url = event.get('url', 'https://books.toscrape.com/catalogue/a-light-in-the-attic_1000/index.html')
    product_id = event.get('product_id', 'book-test')

    try:
        scraper = cloudscraper.create_scraper()
        res = scraper.get(url, timeout=15)
        res.raise_for_status()

        soup = BeautifulSoup(res.text, 'html.parser')
        price = None

        # Sélecteurs Amazon
        amazon_selectors = [
            ("span", {"class": "a-price-whole"}),
            ("span", {"id": "priceblock_ourprice"}),
            ("span", {"id": "priceblock_dealprice"}),
            ("span", {"class": "a-offscreen"}),
        ]
        # Sélecteur books.toscrape.com
        toscrape_selectors = [
            ("p", {"class": "price_color"}),
        ]

        for tag, attrs in amazon_selectors + toscrape_selectors:
            price_tag = soup.find(tag, attrs)
            if price_tag:
                price_raw = price_tag.text.replace(',', '.').replace('\xa0', '').replace('£', '').replace('€', '').strip()
                price = "".join(filter(lambda x: x.isdigit() or x == '.', price_raw))
                if price:
                    break

        table.put_item(Item={
            'product_id': product_id,
            'url': url,
            'current_price': str(price),
            'timestamp': datetime.now(timezone.utc).isoformat()
        })

        return {
            "statusCode": 200,
            "body": json.dumps({"status": "success", "product": product_id, "price": price})
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"status": "error", "message": str(e)})
        }
