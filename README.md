# CloudTrail Audit Account #

[Terraform](https://www.terraform.io/) for an AWS account which receives [CloudTrail logs from other accounts](http://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-receive-logs-from-multiple-accounts.html).

## Using this module ##

The following example creates an s3_bucket `example` and allows accounts `111111111111` and `222222222222` to write CloudTrail logs into that bucket.

    $ terraform apply --var 'account_id_list=["111111111111", "222222222222"]' --var 'cloudtrail_s3_bucket_name="example"'

## CloudTrail delivery alarm ##

If a trail is switched off so logs are no longer being delivered a notification is sent to an SNS topic. This is sent from the [lambda-check-cloudtrail](https://github.com/alphagov/lambda-check-cloudtrail) function.

This gives an opportunity to check with the relevant AWS account holder that they intended to switch off CloudTrail e.g. that account is being deleted.

## CloudWatch alarms ##

Separate alarms are created from certain activity in the account. This is provided by the [aws-security-alarms](https://github.com/alphagov/aws-security-alarms) terraform module.

 - Root user activity
 - Unexpected IP access (configurable)
 - Unauthorized activity / failed authentication attempts
