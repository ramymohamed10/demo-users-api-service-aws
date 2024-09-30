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
Build the Docker image:
   ```
   docker build -t flask-eks-app:latest .
   ```
Test the Docker image locally:
   ```
   docker run -p 80:80 flask-eks-app:latest
   ```
Visit http://localhost in your browser to verify it's working.


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

### Setup GitHub Secrets and Env Variables:
#### For AWS access
In your GitHub repository, go to Settings > Secrets and variables > Actions > New repository secret. Add the following secrets:
- AWS_ACCESS_KEY_ID: Your AWS access key ID.
- AWS_SECRET_ACCESS_KEY: Your AWS secret access key.

Add the following ENV Variables:
- AWS_REGION: AWS region (us-east-1)

#### For EKS access 
1. **Kubeconfig**
   Copy the output you've obtained and save it to a file named kubeconfig_minified.
   ```
   kubectl config view --flatten --minify > kubeconfig_minified
   ```
2. **Base64 Encode the Kubeconfig File**
   To securely store the kubeconfig as a GitHub secret, encode it in base64.
   ```
   cat kubeconfig_minified | base64 | tr -d '\n' > kubeconfig_base64
   ```
3. **Copy the Encoded Content**
   ```
   cat kubeconfig_base64
   ```
   Ensure you copy the entire output without any extra spaces or line breaks.

4. **Add KUBE_CONFIG_DATA as a GitHub Secret**
   
   Add the Secret:
   - Name: KUBE_CONFIG_DATA
   - Value: Paste the base64-encoded kubeconfig content you copied.


## Step 5: Deploy the Application to EKS
Create a k8s directory in your project root then create `deployment.yaml`and `service.yaml` inside it.
### Kubernetes Deployment (`deployment.yaml`)
Defines the deployment of the Flask application with two replicas. Includes readiness and liveness probes to monitor the health of the application.

### Kubernetes Service (`service.yaml`)
Exposes the Flask application through a LoadBalancer, allowing external access to the application.

## Step 6: Implement Monitoring and SRE Best Practices
For Step 6, we will integrate monitoring and apply SRE (Site Reliability Engineering) best practices to your Flask application running on AWS EKS. This will ensure you have the tools necessary to track the performance, health, and reliability of your application, while adhering to SRE principles to manage reliability at scale. Let’s break down this step into smaller sub-steps.

### Step 6.1: Monitoring Using Prometheus and Grafana
#### 6.1.1 Install Prometheus on AWS EKS
Prometheus is an open-source monitoring tool widely used to collect metrics from Kubernetes applications. First, you’ll install Prometheus to scrape metrics from your application and the cluster.

#### 6.1.2 Install Grafana for Visualization
Grafana is a powerful dashboard tool for visualizing metrics collected by Prometheus.


#### 6.1.3 Application Metrics with Flask
For custom application metrics (like response times, request counts, error rates), integrate Prometheus client libraries into your Flask app:

### Step 6.2: Set Up Logging with AWS CloudWatch
- Configure Fluentd to Push Logs to CloudWatch: Fluentd is often used to collect logs from Kubernetes pods and push them to AWS CloudWatch.

### Step 6.3: Implement SRE Best Practices
#### 6.3.1 Set SLIs (Service Level Indicators)
#### 6.3.2 Set SLOs (Service Level Objectives)
#### 6.3.3 Set Error Budgets

### Step 6.4: Set Up Alerting

Alertmanager for Prometheus: Install the Alertmanager component of Prometheus to send alerts based on thresholds:

## Conclusion
This project demonstrates how to build, containerize, and deploy a Flask application on AWS EKS using Docker and Terraform. The CI/CD pipeline automates the build and deployment process, ensuring efficient and consistent deployments.