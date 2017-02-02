# CloudTrail Audit Account #

[Terraform](https://www.terraform.io/) for an AWS account which receives [CloudTrail logs from other accounts](http://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-receive-logs-from-multiple-accounts.html).

## Using this module ##

The following example creates an s3_bucket `example` and allows accounts `111111111111` and `222222222222` to write CloudTrail logs into that bucket.

    $ terraform apply --var 'account_id_list=["111111111111", "222222222222"]' --var 'cloudtrail_s3_bucket_name="example"'

