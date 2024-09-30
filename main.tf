# This section defines the AWS provider, which tells Terraform to interact with AWS services.
# The region is set using the local variable "region", defined in the locals block.
provider "aws" {
  region = local.region
}

# Local variables are defined here. These variables help to simplify and reuse values throughout the configuration.
locals {
  name   = "ramy-cluster" # Name of the EKS cluster and other AWS resources.
  region = "us-east-1"    # AWS region where resources will be deployed.

  vpc_cidr = "10.123.0.0/16"              # CIDR block for the Virtual Private Cloud (VPC).
  azs      = ["us-east-1a", "us-east-1b"] # List of availability zones for resource distribution.

  # Defining public, private, and intra-subnets in the VPC with specific CIDR blocks.
  public_subnets  = ["10.123.1.0/24", "10.123.2.0/24"] # Public subnets (internet-accessible).
  private_subnets = ["10.123.3.0/24", "10.123.4.0/24"] # Private subnets (internal network).
  intra_subnets   = ["10.123.5.0/24", "10.123.6.0/24"] # Intra-subnets for the EKS control plane.

  # Tags are metadata you can add to resources to help with organization.
  tags = {
    Example = local.name # Adding a tag to resources with the cluster name.
  }
}

# The VPC module defines the networking resources (VPC, subnets, gateways) for AWS.
module "vpc" {
  # Source specifies that we are using a pre-built VPC module from the Terraform AWS modules repository.
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0" # Version of the VPC module being used.

  # Setting the name, CIDR block, availability zones, and subnets from the local variables defined earlier.
  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs             # Availability zones where subnets will be distributed.
  private_subnets = local.private_subnets # Subnets for internal resources (private).
  public_subnets  = local.public_subnets  # Subnets for internet-facing resources (public).
  intra_subnets   = local.intra_subnets   # Subnets used for internal communication between EKS control plane.

  enable_nat_gateway = true # Enabling NAT gateway so instances in private subnets can access the internet.

  # Adding specific tags to public subnets so Kubernetes knows they can be used for load balancers (ELB).
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  # Adding tags to private subnets for Kubernetes internal load balancers.
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

# The EKS module defines the resources needed to deploy a Kubernetes cluster on AWS.
module "eks" {
  # Source specifies that we are using a pre-built EKS module from the Terraform AWS modules repository.
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.1" # Version of the EKS module being used.

  cluster_name                   = local.name # Name of the EKS cluster (from the locals block).
  cluster_endpoint_public_access = true       # Enables public access to the EKS cluster control plane (for management).

  # Enabling some essential Kubernetes add-ons such as CoreDNS, kube-proxy, and VPC CNI (networking).
  cluster_addons = {
    coredns = {
      most_recent = true # Use the most recent version of CoreDNS.
    }
    kube-proxy = {
      most_recent = true # Use the most recent version of kube-proxy.
    }
    vpc-cni = {
      most_recent = true # Use the most recent version of the VPC CNI plugin for networking.
    }
  }

  # The VPC ID and subnet IDs are passed from the VPC module created above.
  vpc_id                   = module.vpc.vpc_id          # The VPC ID where the EKS cluster will be deployed.
  subnet_ids               = module.vpc.private_subnets # Worker nodes will run in the private subnets.
  control_plane_subnet_ids = module.vpc.intra_subnets   # The control plane of the EKS cluster will run in the intra-subnets.

  # Defining some defaults for the EKS managed node groups (worker nodes).
  eks_managed_node_group_defaults = {
    ami_type                              = "AL2_x86_64" # The Amazon Machine Image (AMI) type used by worker nodes (Amazon Linux 2).
    instance_types                        = ["t3.small"] # Instance type used for worker nodes.
    attach_cluster_primary_security_group = true         # Automatically attach the primary security group for the cluster.
  }

  # Defining a managed node group for the EKS cluster.
  eks_managed_node_groups = {
    ramy-cluster-wg = { # Name of the node group.
      min_size     = 1  # Minimum number of instances (nodes) in the node group.
      max_size     = 2  # Maximum number of instances (nodes).
      desired_size = 1  # Desired number of instances to run.

      instance_types = ["t3.small"] # Type of EC2 instance for the nodes.
      capacity_type  = "SPOT"       # Using Spot instances (cheaper, but can be interrupted).

      # Additional tag for this specific node group.
      tags = {
        ExtraTag = "helloworld"
      }
    }
  }

  # Applying tags to the EKS cluster.
  tags = local.tags # Tags from the local variable block.

  # Adding security group tags so Kubernetes can manage the nodes and control plane securely.
  node_security_group_tags = {
    "kubernetes.io/cluster/${local.name}" = null # Security group tag to associate nodes with the EKS cluster.
  }
}
