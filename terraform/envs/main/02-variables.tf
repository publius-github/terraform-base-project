variable "region" {
  description = "The AWS region where the provider will operate."

  default = {
    main = "us-east-1"
  }
}

variable "owner" {
  description = "Used in tags for specify owner. Email or name preferable."

  default = {
    main = "owner@example.com"
  }
}

variable "repository_url" {
  description = "Used in tags for specify Repositori URL."

  default = "https://github.com/..."
}

variable "account_id" {
  description = "The AWS account ID where the provider will operate."

  default = {
    main = "83937kljkl189"
  }
}

variable "env" {
  description = "Environment."

  default = {
    main = "main"
  }
}

variable "organization_name" {
  default = "org-name"
}
