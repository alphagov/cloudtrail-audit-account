output "bucket_policy" {
  value = "${data.aws_iam_policy_document.s3_policy.json}"
}
