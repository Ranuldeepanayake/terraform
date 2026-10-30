terraform {
  cloud {
    organization = "ranuldeepanayake"
    workspaces {
      name = "aws-api-gw-account"
    }
  }
}

provider "aws" {
  region  = "ap-southeast-1"
  profile = "super-user"
}
