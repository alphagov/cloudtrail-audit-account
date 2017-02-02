data "aws_caller_identity" "current" {}

resource "aws_sns_topic" "check_cloudtrail_topic" {
  name = "check_cloudtrail_topic"
}

resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = "${var.cloudtrail_s3_bucket_name}"
  force_destroy = true
  policy        = "${data.aws_iam_policy_document.s3_policy.json}"

  versioning = {
    enabled = true
  }
}

module "aws-security-alarms" {
  source                      = "github.com/alphagov/aws-security-alarms//terraform"
  cloudtrail_s3_bucket_name   = "${aws_s3_bucket.cloudtrail_bucket.id}"
  cloudtrail_s3_bucket_prefix = "${var.self_cloudtrail_s3_key_prefix}"
}

module "unexpected-ip-access" {
  source               = "github.com/alphagov/aws-security-alarms//terraform/alarms/unexpected_ip_access"
  environment_name     = "audit-logging"
  cloudtrail_log_group = "${module.aws-security-alarms.cloudtrail_log_group}"
  alarm_actions        = ["${module.aws-security-alarms.security_alerts_topic}"]
}

module "unauthorized-activity" {
  source               = "github.com/alphagov/aws-security-alarms//terraform/alarms/unauthorized_activity"
  environment_name     = "audit-logging"
  cloudtrail_log_group = "${module.aws-security-alarms.cloudtrail_log_group}"
  alarm_actions        = ["${module.aws-security-alarms.security_alerts_topic}"]
}

module "root-activity" {
  source               = "github.com/alphagov/aws-security-alarms//terraform/alarms/root_activity"
  environment_name     = "audit-logging"
  cloudtrail_log_group = "${module.aws-security-alarms.cloudtrail_log_group}"
  alarm_actions        = ["${module.aws-security-alarms.security_alerts_topic}"]
}

resource "aws_lambda_function" "check_cloudtrail_lambda" {
  filename         = "../check_cloudtrail.zip"
  function_name    = "check_cloudtrail"
  role             = "${aws_iam_role.check_cloudtrail_role.arn}"
  handler          = "check_cloudtrail.lambda_handler"
  source_code_hash = "${base64sha256(file("../check_cloudtrail.zip"))}"
  runtime          = "python2.7"
  timeout          = 10

  environment {
    variables = {
      BUCKET_NAME = "${aws_s3_bucket.cloudtrail_bucket.id}"
      TOPIC_ARN   = "${aws_sns_topic.check_cloudtrail_topic.arn}"
    }
  }
}

resource "aws_cloudwatch_event_rule" "scheduled_cloudtrail_check" {
  name                = "scheduled_cloudtrail_check"
  description         = "Check CloudTrails are still enabled."
  schedule_expression = "rate(24 hours)"
}

resource "aws_lambda_alias" "check_cloudtrail_alias" {
  name             = "check_cloudtrail_alias"
  description      = "Latest version of check_cloudtrail"
  function_name    = "${aws_lambda_function.check_cloudtrail_lambda.arn}"
  function_version = "$LATEST"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.check_cloudtrail_lambda.arn}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.scheduled_cloudtrail_check.arn}"
  qualifier     = "${aws_lambda_alias.check_cloudtrail_alias.name}"
}

resource "aws_cloudwatch_event_target" "trigger_cloudtrail_check" {
  target_id = "check_cloudtrail_lambda"
  rule      = "${aws_cloudwatch_event_rule.scheduled_cloudtrail_check.name}"
  arn       = "${aws_lambda_alias.check_cloudtrail_alias.arn}"
}
