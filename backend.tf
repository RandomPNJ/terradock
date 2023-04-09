terraform {
  cloud {
    organization = "dev-wkspc"

    workspaces {
      name = "dev-wkspc"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}
