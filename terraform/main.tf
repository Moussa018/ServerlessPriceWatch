# Table DynamoDB
resource "aws_dynamodb_table" "price_tracker_table" {
  name           = "WatchDogProducts"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "product_id"

  attribute {
    name = "product_id"
    type = "S"
  }

  tags = {
    Project = "PriceTracker"
  }
}

# BUG CORRIGÉ : archive lambda_zip était référencée mais jamais déclarée
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/scraper.py"
  output_path = "${path.module}/scraper.zip"
}

# La Layer est zippée depuis lambda_layers/ qui contient le dossier python/.
# AWS Lambda exige impérativement cette structure dans le zip :
#   python_libs.zip
#   └── python/
#       ├── requests/
#       ├── bs4/
#       └── ...
# Le service pip-installer (docker-compose) installe les libs dans
# lambda_layers/python/ avant que Terraform ne crée ce zip.
data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda_layers"
  output_path = "${path.module}/python_libs.zip"
}

resource "aws_lambda_layer_version" "python_libs" {
  filename            = data.archive_file.layer_zip.output_path
  layer_name          = "python_dependencies"
  compatible_runtimes = ["python3.9"]
  source_code_hash    = data.archive_file.layer_zip.output_base64sha256
}

# Rôle IAM pour la Lambda
resource "aws_iam_role" "lambda_role" {
  name = "price_tracker_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Politique pour que Lambda écrive dans DynamoDB
resource "aws_iam_role_policy" "dynamodb_lambda_policy" {
  name = "dynamodb_lambda_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:GetItem",
        "dynamodb:DescribeTable"
      ]
      Resource = "${aws_dynamodb_table.price_tracker_table.arn}"
    }]
  })
}

# Fonction Lambda
resource "aws_lambda_function" "price_scraper" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "PriceScraper"
  role             = aws_iam_role.lambda_role.arn
  handler          = "scraper.handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30

  layers = [aws_lambda_layer_version.python_libs.arn]

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.price_tracker_table.name
      # BUG CORRIGÉ : "localhost" est inaccessible depuis l'intérieur de Docker
      #               → remplacé par le nom du service docker-compose "localstack"
      AWS_ENDPOINT_URL = "http://localstack:4566"
    }
  }
}
