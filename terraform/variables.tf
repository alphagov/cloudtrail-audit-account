variable "self_cloudtrail_s3_key_prefix" {
  default = "self"
}

variable "cloudtrail_s3_bucket_name" {
  type = "string"
}

variable "account_id_list" {
  type = "list"
}
