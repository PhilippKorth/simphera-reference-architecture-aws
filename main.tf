
terraform {
  required_version = ">= 1.1.7" #nullable input values available in Terraform v1.1.0 and later.
  experiments      = [module_variable_optional_attrs]
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.74.3"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.4.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.7.1"
    }

  }
}
provider "aws" {
  region              = var.region
  allowed_account_ids = local.allowed_account_ids
  default_tags {
    tags = var.tags
  }
}
data "aws_eks_cluster" "cluster" {
  name = module.eks.eks_cluster_id
}
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.eks_cluster_id
}

data "aws_region" "current" {}
provider "kubernetes" {
  experiments {
    manifest_resource = true
  }
  config_path = "./kubeconfig_${module.eks.eks_cluster_id}"
}

provider "helm" {
  kubernetes {
    config_path = "./kubeconfig_${module.eks.eks_cluster_id}"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
