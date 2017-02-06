data "aws_iam_policy_document" "view_cloudtrails_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "AWS"
      identifiers = ["${var.log_viewers}"]
    }

    condition = {
      test = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = ["true"]
    }
  }
}

data "aws_iam_policy_document" "view_cloudtrails_policy_document" {
  statement {
    sid = "ListCloudTrailsBucket"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "${aws_s3_bucket.cloudtrail_bucket.arn}",
    ]
  }
  statement {
    sid = "GetLogs"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.cloudtrail_bucket.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "view_logs_policy" {
  name = "view_logs_policy"
  role = "${aws_iam_role.view_logs_role.id}"

  policy = "${data.aws_iam_policy_document.view_cloudtrails_policy_document.json}"
}

resource "aws_iam_role" "view_logs_role" {
  name = "view_logs_role"

  assume_role_policy = "${data.aws_iam_policy_document.view_cloudtrails_assume_role.json}"
}

data "aws_iam_policy_document" "check_cloudtrail_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "check_cloudtrail_policy_document" {
  statement {
    sid = "ListCloudTrailsBucket"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "${aws_s3_bucket.cloudtrail_bucket.arn}",
    ]
  }

  statement {
    sid = "NotifySecurityTeam"

    actions = [
      "sns:Publish",
    ]

    resources = [
      "${aws_sns_topic.check_cloudtrail_topic.arn}",
    ]
  }
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid = "CloudTrailCheckACL"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl",
    ]
    resources = [
      "arn:aws:s3:::${var.cloudtrail_s3_bucket_name}",
    ]
  }
  statement {
    sid = "CloudTrailPutObjectsSelf"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::${var.cloudtrail_s3_bucket_name}/${var.self_cloudtrail_s3_key_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
    ]
    condition = {
      test = "StringEquals"
      variable = "s3:x-amz-acl"
      values = ["bucket-owner-full-control"]
    }
  }
  statement {
    sid = "CloudTrailPutObjectsOtherAccounts"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:PutObject",
    ]
    resources = ["${formatlist("arn:aws:s3:::%s/%s/AWSLogs/%s/*", var.cloudtrail_s3_bucket_name, var.account_id_list, var.account_id_list)}"]
    condition = {
      test = "StringEquals"
      variable = "s3:x-amz-acl"
      values = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_iam_role_policy" "check_cloudtrail_policy" {
  name = "check_cloudtrail_policy"
  role = "${aws_iam_role.check_cloudtrail_role.id}"

  policy = "${data.aws_iam_policy_document.check_cloudtrail_policy_document.json}"
}

resource "aws_iam_role_policy_attachment" "aws_basic_lambda_execution_role" {
  role       = "${aws_iam_role.check_cloudtrail_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "check_cloudtrail_role" {
  name = "check_cloudtrail_role"

  assume_role_policy = "${data.aws_iam_policy_document.check_cloudtrail_assume_role.json}"
}
