provider "aws" {
  region              = lookup(var.region, terraform.workspace)
  allowed_account_ids = ["${lookup(var.account_id, terraform.workspace)}"]

  profile = "default"

  assume_role {
    role_arn = "arn:aws:iam::${lookup(var.account_id, terraform.workspace)}:role/terraform"
  }

  default_tags {
    tags = {
      env       = lookup(var.env, terraform.workspace)
      owner     = lookup(var.owner, terraform.workspace)
      terraform = var.repository_url
    }
  }
}
