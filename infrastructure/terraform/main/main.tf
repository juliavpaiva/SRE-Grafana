data "archive_file" "sre-grafana-lambda" {
  type = "zip"

  source_dir  = "${path.module}/sre-grafana-lambda"
  output_path = "${path.module}/sre-grafana-lambda.zip"
}

resource "aws_sns_topic" "sre-grafana-sns-topic" {
  name = "sre-grafana-sns-topic"
}

resource "aws_lambda_function" "sre-grafana-lambda" {
  function_name    = "sre-grafana-lambda"
  role             = aws_iam_role.sre-grafana-lambda-role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  filename         = "${path.module}/sre-grafana-lambda.zip"

  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }

  environment {
    variables = {
      SNS_TOPIC_ARN = sre-grafana-sns-topic.arn
    }
  }

  publish = true
}


resource "aws_iam_role" "sre-grafana-lambda-role" {
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

resource "aws_lambda_permission" "sns_invoke_lambda_permission" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sre-grafana-lambda.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.sre-grafana-sns-topic.arn
}

resource "aws_sns_topic_subscription" "sre-grafana-lambda-sns_topic_subscription" {
  topic_arn = aws_sns_topic.sre-grafana-sns-topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.sre-grafana-lambda.arn
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_send" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  role       = aws_iam_role.sre-grafana-lambda-role.name
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.sre-grafana-lambda-role.name
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