# Flask Application on AWS EKS with CI/CD Pipeline

This project demonstrates the deployment of a simple Flask application on AWS EKS (Elastic Kubernetes Service) using Docker and Terraform for infrastructure setup. A CI/CD pipeline is configured using GitHub Actions to automate the deployment process.

## Project Structure

- **`app.py`**: A basic Flask application that provides a REST API with CRUD operations.
- **`Dockerfile`**: A Dockerfile to containerize the Flask application.
- **`main.tf`**: Terraform script for setting up AWS infrastructure, including VPC, subnets, and EKS cluster.
- **`.github/workflows/main.yaml`**: GitHub Actions CI/CD pipeline configuration for building, pushing the Docker image to ECR, and deploying the application to the EKS cluster.
- **`k8s/deployment.yaml`**: Kubernetes Deployment file to deploy the Flask application.
- **`k8s/service.yaml`**: Kubernetes Service file to expose the Flask application via a LoadBalancer.

## Step 1: Develop and Containerize the Flask Application

### Flask Application (`app.py`)

The Flask application provides the following routes:

- **`/`**: Welcome message.
- **`/health`**: Health check endpoint.
- **`/users`**: CRUD operations for managing users.

### Dockerfile

The Dockerfile is used to containerize the Flask application. It uses the official Python 3.9 slim image as the base and installs necessary dependencies.

   ```dockerfile
   FROM python:3.9-slim
   WORKDIR /app
   COPY . /app
   RUN pip install --no-cache-dir -r requirements.txt
   EXPOSE 80
   CMD ["python", "app.py"]
   ```

## Step 2: Infrastructure as Code with Terraform

In this step, Terraform is used to provision the necessary AWS infrastructure, including the VPC, subnets, and EKS cluster. The infrastructure is defined as code, allowing for reproducibility and version control.

### Terraform Configuration (`main.tf`)

The main Terraform configuration file, `main.tf`, sets up the following AWS resources:

- **VPC (Virtual Private Cloud)**: A custom VPC with public, private, and intra subnets.
- **EKS (Elastic Kubernetes Service) Cluster**: A managed Kubernetes cluster within the VPC.

### Deploying the Infrastructure

To deploy the infrastructure using Terraform:

1. **Initialize Terraform:**
   ```
   terraform init
   ```
2. **Validate the configuration::**
   ```
   terraform validate
   ```
3. **Plan the infrastructure deployment:**
   ```
   terraform plan -out=tfplan
   ```
4. **Apply the plan:**
   ```
   terraform apply tfplan
   ```
   This command will show a plan of the changes Terraform will make. Review the plan, and if everything looks correct, confirm the deployment. This process may take several minutes.

5. **To destroy all the resources managed by your current Terraform configuration, simply run:**
   ```
   terraform destroy
   ```

## Step 3: Set Up AWS EKS Cluster and ECR
After provisioning the infrastructure, the `kubeconfig` file is updated to interact with the EKS cluster. An ECR repository is also created to store Docker images.

1. **Configure kubectl**
   ```
   aws eks --region us-east-1 update-kubeconfig --name cluster-name
   ```
   Verify the cluster is accessible:
   ```
   kubectl get nodes
   ```
2. **Create an ECR Repository**
   Create an Amazon ECR repository to store your Docker images:
   ```
   aws ecr create-repository --repository-name repo-name --region us-east-1
   ```
   Note the repository URI; you'll need it later.

## Step 4: Configure CI/CD Pipeline with GitHub Actions
### GitHub Actions Workflow (`main.yaml`)
The CI/CD pipeline automates the following tasks:
1. Checkout Code: Fetches the latest code from the repository.
2. Configure AWS Credentials: Sets up AWS credentials for subsequent steps.
3. Build, Tag, and Push Docker Image: Builds the Docker image and pushes it to the ECR repository.
4. Update Kubernetes Deployment: Updates the image in the Kubernetes deployment and applies changes to the EKS cluster.

## Step 5: Deploy the Application to EKS
### Kubernetes Deployment (`deployment.yaml`)
Defines the deployment of the Flask application with two replicas. Includes readiness and liveness probes to monitor the health of the application.

### Kubernetes Service (`service.yaml`)
Exposes the Flask application through a LoadBalancer, allowing external access to the application.

## Conclusion
This project demonstrates how to build, containerize, and deploy a Flask application on AWS EKS using Docker and Terraform. The CI/CD pipeline automates the build and deployment process, ensuring efficient and consistent deployments.