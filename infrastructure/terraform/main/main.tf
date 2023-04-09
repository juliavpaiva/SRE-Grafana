resource "aws_lambda_function" "sre-grafana-lambda" {
  function_name = "sre-grafana-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.8"
  timeout       = 10

  filename      = "sre_grafana_lambda/handler.py"

  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }
  publish = true
}

resource "aws_iam_role" "lambda_role" {
  name = "sre-grafana-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_sqs_queue" "dlq" {
  name = "sre-grafana-lambda-dlq"
}

resource "aws_cloudwatch_metric_alarm" "dlq_alarm" {
  alarm_name          = "sre-grafana-lambda-dlq-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    QueueName    = aws_sqs_queue.dlq.name
    QueueUrl     = aws_sqs_queue.dlq.id
  }

  alarm_description = "Alarm when the DLQ for the sre-grafana-lambda function reaches 1 message."

  alarm_actions = [
    aws_sns_topic.notification_topic.arn,
  ]
}

resource "aws_sns_topic" "notification_topic" {
  name = "sre-grafana-lambda-notifications"
}
