resource "aws_dynamodb_table" "price_tracker_table" {
  name           = "WatchDogProducts"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "product_id"
  attribute {
    name = "product_id"
    type = "S"
  }
  tags = { Project = "PriceTracker" }
}

# Zip scraper.py + toutes les dépendances ensemble dans un seul package
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda_package"
  output_path = "${path.module}/scraper.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "price_tracker_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "dynamodb_lambda_policy" {
  name = "dynamodb_lambda_policy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:PutItem","dynamodb:UpdateItem","dynamodb:GetItem","dynamodb:DescribeTable"]
      Resource = "${aws_dynamodb_table.price_tracker_table.arn}"
    }]
  })
}

resource "aws_lambda_function" "price_scraper" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "PriceScraper"
  role             = aws_iam_role.lambda_role.arn
  handler          = "scraper.handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30
  environment {
    variables = {
      TABLE_NAME       = aws_dynamodb_table.price_tracker_table.name
      AWS_ENDPOINT_URL = "http://localstack:4566"
    }
  }
}
