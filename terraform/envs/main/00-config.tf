terraform {
  required_version = "~> 1.1.4"

  backend "s3" {
    region               = <region>
    bucket               = <state bucket>
    workspace_key_prefix = <workspace prefix>
    key                  = <state name>
    encrypt              = true
    acl                  = "bucket-owner-full-control"
    kms_key_id           = <key arn>
    dynamodb_table       = <dynamo table name>
  }
}
