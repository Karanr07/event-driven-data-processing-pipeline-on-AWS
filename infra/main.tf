resource "aws_s3_bucket" "data_bucket" {
  bucket = "event-driven-data-bucket-${random_id.suffix.hex}"
  force_destroy = true
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = aws_s3_bucket.data_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.report_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "report_lambda" {
  function_name = "daily_report_lambda"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_role.arn
  filename      = "lambda.zip"
  timeout       = 30
  memory_size   = 128

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy
  ]
}
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.report_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data_bucket.arn
}
resource "aws_iam_role_policy_attachment" "lambda_s3_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
