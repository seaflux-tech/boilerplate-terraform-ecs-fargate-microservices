Deploying an ECS (Elastic Container Service) cluster and an ECR (Elastic Container Registry) repository using Terraform.

# Terraform ECS and ECR Deployment with farget

This Terraform script deploys an ECS cluster and an ECR repository on AWS. ECS is a fully managed container orchestration service, and ECR is a fully managed container registry.

## Prerequisites

Before you begin, ensure you have the following:

1. AWS account with appropriate permissions.
2. Terraform installed on your local machine.
3. AWS CLI configured with the necessary credentials.

## Usage

1. Clone the repository:

```
    git clone <repo-url>
    cd boilerplate-terraform-ecs-fargate-microservices
```

Initialize Terraform:

    terraform init
Customize the terraform.tfvars file with your desired configurations.

Review and apply the Terraform plan:

```
    terraform plan
    terraform apply
```
Respond with yes when prompted to confirm the deployment.

Once the deployment is complete, Terraform will output information about the ECS cluster and ECR repository.

Configuration
Update the terraform.tfvars file to configure the deployment according to your requirements. The file includes variables such as region, ecs_cluster_name, ecr_repository_name, etc.

Cleanup
To destroy the resources created by Terraform and clean up the deployment, run:

```
terraform destroy
```

Respond with yes when prompted to confirm the destruction.

## Important Notes

Ensure that your AWS CLI is configured with the necessary credentials and the region specified in terraform.tfvars.
Review the IAM roles and permissions to make sure they are appropriate for your use case.
The default configuration uses the latest Amazon Linux 2 ECS-optimized AMI for the ECS instances. Adjust the AMI as needed.