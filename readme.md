# FastAPI BTP Template

A production-ready FastAPI application template for deploying to SAP Business Technology Platform (BTP) CloudFoundry environment using Terraform Infrastructure as Code.

## Overview

This template provides a complete setup for:
- **FastAPI Application**: A modern, high-performance Python web framework
- **Terraform Deployment**: Infrastructure as Code for automated CloudFoundry deployments
- **BTP Integration**: Native integration with SAP Business Technology Platform
- **Automated Packaging**: ZIP file generation for CloudFoundry deployment

## Table of Contents

- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Local Development](#local-development)
- [Deployment Guide](#deployment-guide)
- [Configuration](#configuration)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [References](#references)

## Quick Start

Get up and running in 5 minutes:

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Run locally
uvicorn main:app --host=0.0.0.0 --port=8080

# 3. Visit http://localhost:8080
```

Ready to deploy? Jump to [Deployment Guide](#deployment-guide).

## Prerequisites

### System Requirements

- **Operating System**: Linux, macOS, or Windows (with WSL2 recommended)
- **Memory**: Minimum 4GB RAM (8GB recommended)
- **Disk Space**: 2GB for dependencies and tools

### Required Tools

1. **Terraform** (v1.0 or higher) - Infrastructure as Code
   - Download from: https://www.terraform.io/downloads.html
   - Add to PATH for command-line access
   - Required for infrastructure provisioning and deployment
   - Verify installation: `terraform --version`

2. **Python** (v3.8+) - Application runtime
   - Download from: https://www.python.org/downloads/
   - For running the FastAPI application locally
   - Install dependencies using `pip` or `uv`
   - Verify installation: `python --version`

3. **CloudFoundry CLI** (optional, for manual deployments)
   - Download from: https://github.com/cloudfoundry/cli/releases
   - Useful for monitoring and managing deployments
   - Verify installation: `cf --version`

4. **Git** (recommended)
   - For version control and repository management
   - Download from: https://git-scm.com/

5. **Package Manager**
   - `pip` (default Python package manager)
   - `uv` (optional, faster alternative)

### BTP Configuration Requirements

You must have the following BTP resources pre-configured before deployment:

1. **SAP BTP Subaccount** - Your deployment target
   - Access to a BTP subaccount with proper permissions
   - BTP credentials (username and password)
   - Subaccount name for Terraform variable configuration
   - Link: https://help.sap.com/docs/btp

2. **CloudFoundry Environment Instance** - Container platform
   - A CloudFoundry environment instance created in your BTP subaccount
   - Instance will be queried automatically by the BTP Terraform module
   - Ensure API endpoint is accessible from your machine
   - Documentation: https://help.sap.com/docs/btp/sap-btp-cloud-foundry-environment

3. **CloudFoundry Space** - Deployment namespace
   - At least one space created in the CloudFoundry org (typically "dev", "staging", or "prod")
   - Required for application deployment
   - Admin permissions in the space recommended

### Recommended Setup

```bash
# Verify all tools are installed
terraform --version
python --version
cf --version
git --version
```

## Project Structure

```
fastapi-btp/
├── main.py                          # FastAPI application entry point
├── requirements.txt                 # Python dependencies
├── Procfile                         # CloudFoundry process definitions
├── manifest.yml                     # CloudFoundry application manifest
├── tools/
│   ├── deploy.sh                    # Deployment automation script
│   ├── zip_files.py                 # Packaging utility for CloudFoundry
│   └── terraform/
│       ├── BTP/                     # BTP Terraform module
│       │   ├── main.tf              # BTP resource queries
│       │   ├── variables.tf         # BTP input variables
│       │   ├── providers.tf         # BTP provider configuration
│       │   └── backend.tf           # BTP state backend configuration
│       └── cloudfoundry/            # CloudFoundry Terraform module
│           ├── main.tf              # CloudFoundry resources
│           ├── variables.tf         # CloudFoundry input variables
│           ├── providers.tf         # CloudFoundry provider configuration
│           └── backend.tf           # CloudFoundry state backend configuration
```

## Getting Started

### 1. Local Development and Testing

#### Clone or Extract the Template

```bash
# Extract template files to your desired location
cd fastapi-btp
```

#### Install Python Dependencies

Using `pip` (standard):
```bash
pip install -r requirements.txt
```

Or using `uv` (recommended for faster installation):
```bash
uv pip install -r requirements.txt
```

**Dependency Details:**
- `fastapi` - Web framework
- `uvicorn` - ASGI server
- `pydantic` - Data validation
- Additional dependencies listed in `requirements.txt`

#### Run the Application Locally

```bash
# Start the FastAPI application with uvicorn
# Command is defined in Procfile for consistency
uvicorn main:app --host=0.0.0.0 --port=8080

# Alternative: Reload on code changes (development)
uvicorn main:app --host=0.0.0.0 --port=8080 --reload
```

The application will be available at: `http://localhost:8080`

**Available API Endpoints:**
- `GET /` - Returns a welcome message
- `GET /hello/{name}` - Returns a personalized greeting with parameter

#### Test API Endpoints

Using curl:
```bash
# Test root endpoint
curl http://localhost:8080/

# Test parameterized endpoint
curl http://localhost:8080/hello/World
```

Using Python requests:
```python
import requests

response = requests.get("http://localhost:8080/")
print(response.json())
```

Or use the provided HTTP test file: `test_main.http` (requires REST Client IDE extension)

### 2. Prepare Application Files for Deployment

Before deploying to BTP CloudFoundry, you must configure which files will be packaged.

#### Configure zip_files.py - File Packaging Script

Edit `tools/zip_files.py` to include all necessary application files for deployment:

```python
if __name__ == "__main__":
    zip_files("deploy.zip", [
        "./../main.py",                  # Application entry point (REQUIRED)
        "./../requirements.txt",         # Python dependencies (REQUIRED)
        "./../services",                 # Custom services module (if applicable)
        "./../env_models",               # Environment models (if applicable)
        "./../manifest.yml",             # CloudFoundry manifest (REQUIRED)
        "./../Procfile"                  # Process definition (REQUIRED)
        # Add any additional directories or files needed by your application
    ])
```

**Required Files to Include:**
- `main.py` - Your FastAPI application entry point
- `requirements.txt` - Python package dependencies
- `Procfile` - CloudFoundry process definition
- `manifest.yml` - CloudFoundry application configuration

**Common Additional Files:**
- `services/` - Service layer and business logic modules
- `models/` - Pydantic data models and schemas
- `env_models/` - Environment configuration models
- `config/` - Application configuration files
- `.env` - Environment variables (be careful with secrets)

**Do NOT include:**
- `__pycache__/` - Python cache files
- `.env` - Real credentials (use environment variables instead)
- `.git/` - Git repository metadata
- Large test files or datasets

#### Understand the Procfile - CloudFoundry Process Definition

The `Procfile` is critical - it defines how CloudFoundry runs your application:

```
web: uvicorn main:app --host=0.0.0.0 --port=${PORT:-8080}
```

**Procfile Components:**
- `web:` - Process type (required for web applications)
- `uvicorn main:app` - ASGI server running your FastAPI app
- `--host=0.0.0.0` - Listens on all network interfaces
- `--port=${PORT:-8080}` - Uses PORT environment variable (default: 8080)

**Customizing Procfile:**
You can modify this command if needed:
```
# Example: Add workers for production
web: gunicorn main:app --workers=4 --worker-class uvicorn.workers.UvicornWorker

# Example: With logging
web: uvicorn main:app --host=0.0.0.0 --port=${PORT:-8080} --log-level info
```

### 3. Configure Terraform Variables and Credentials

Create or update Terraform variable files for your environment.

#### BTP Terraform Module Variables

Create `tools/terraform/BTP/terraform.tfvars`:

```hcl
btp_username     = "your-btp-username@example.com"
btp_password     = "your-btp-password"
subaccount_name  = "your-subaccount-name"
target-directory = "/optional/target/directory"
```

**Variable Descriptions:**
- `btp_username` - Your BTP username/email
- `btp_password` - Your BTP account password
- `subaccount_name` - Name of your BTP subaccount
- `target-directory` - Optional deployment directory

#### CloudFoundry Terraform Module Variables

Create `tools/terraform/cloudfoundry/terraform.tfvars`:

```hcl
btp_username   = "your-btp-username@example.com"
btp_password   = "your-btp-password"
btp_state_url  = "https://your-gitlab-instance.com/api/v4/projects/12345/terraform/state/btp"
gitlab_username = "your-gitlab-username"
gitlab_token   = "your-gitlab-token"
```

**Variable Descriptions:**
- `btp_username` - BTP credentials for CloudFoundry authentication
- `btp_password` - BTP password
- `btp_state_url` - Remote Terraform state URL (typically GitLab)
- `gitlab_username` - GitLab username for state backend access
- `gitlab_token` - GitLab personal access token

**Security Best Practices:**
- Never commit `terraform.tfvars` files with real credentials to version control
- Credentials should be kept secure (use environment variables or secret management)
- Use GitLab CI/CD secrets or similar mechanisms for sensitive data
- Rotate credentials regularly

#### Update CloudFoundry Main Configuration

Edit `tools/terraform/cloudfoundry/main.tf` to customize your deployment:

```terraform
data "cloudfoundry_space" "dev" {
    name = "dev"              # Change to your space name
    org  = data.terraform_remote_state.btp.outputs.org_id
}

resource "cloudfoundry_route" "route" {
  space  = data.cloudfoundry_space.dev.id
  domain = data.cloudfoundry_domain.cfapps.id
  host   = "template"         # Change to your app hostname
}

resource "cloudfoundry_app" "server" {
  # ...existing configuration...
}
```

**Key Customizations:**
- `space` name - Update to match your CloudFoundry space
- `host` name - Your application's hostname in the route
- `instances` - Number of running instances
- `memory` - Memory allocation per instance

### 4. Deploy to BTP CloudFoundry - Step-by-Step

### 4. Deploy to BTP CloudFoundry - Step-by-Step

#### Step 1: Package the Application into ZIP

Package your application files for CloudFoundry deployment:

```bash
cd tools
python zip_files.py
```

**What this does:**
- Creates `deploy.zip` containing all files specified in `zip_files.py`
- Compresses the application with dependencies
- Prepares artifact for CloudFoundry upload

**Verify the ZIP file:**
```bash
ls -lh deploy.zip
# Example output: -rw-r--r--  1 user  group  2.3M Feb 18 10:30 deploy.zip
```

**Troubleshooting ZIP creation:**
```bash
# If files are missing, verify zip_files.py includes them
# Check the output for "⚠️  Warning: '[path]' does not exist"
# Add missing directories to the source_paths list
```

#### Step 2: Initialize Terraform (First Time Only)

Initialize Terraform for both modules:

```bash
# Initialize BTP module
cd terraform/BTP
terraform init -backend-config="address=https://your-gitlab-instance.com/api/v4/projects/12345/terraform/state/btp" \
               -backend-config="username=your-gitlab-username" \
               -backend-config="password=your-gitlab-token"

# Initialize CloudFoundry module
cd ../cloudfoundry
terraform init
```

**What this does:**
- Downloads Terraform providers (BTP and CloudFoundry)
- Sets up local state management
- Prepares for infrastructure provisioning

**Verify initialization:**
```bash
terraform validate
# Should output: Success! The configuration is valid.
```

#### Step 3: Plan Terraform Configuration (Recommended)

Before applying, review what will be created:

```bash
cd terraform/cloudfoundry
terraform plan -out=tfplan
```

**Review output for:**
- Resource creation (cloudfoundry_app, cloudfoundry_route, etc.)
- Correct application name and space
- Environment variables
- Correct number of instances

#### Step 4: Apply Terraform Configuration

Deploy your application to CloudFoundry:

```bash
# Deploy to CloudFoundry
cd terraform/cloudfoundry
terraform apply tfplan  # Uses plan from Step 3
# OR
terraform apply -auto-approve  # Apply directly
```

**Or use the automated deployment script:**

```bash
cd tools
./deploy.sh
```

**What the deploy.sh script does:**
1. Freezes Python dependencies using `uv pip freeze`
2. Packages application files into `deploy.zip`
3. Destroys previous deployment (if existing)
4. Applies new Terraform configuration
5. Deploys to CloudFoundry

**Deployment progress:**
- Watch for `Resource cloudfoundry_app.server: Creating...`
- Wait for completion (~2-5 minutes)
- Success: `Apply complete! Resources: X added, X destroyed`

#### Step 5: Verify Deployment

Confirm your application is running:

```bash
# Get the deployed application URL
cd terraform/cloudfoundry
terraform output url
```

**Example output:**
```
url = "https://template.cfapps.eu12.hana.ondemand.com"
```

**Test the deployed application:**
```bash
# Test root endpoint
curl https://template.cfapps.eu12.hana.ondemand.com/

# Test with parameter
curl https://template.cfapps.eu12.hana.ondemand.com/hello/World
```

**Check application status:**
```bash
cf logs template-tf --recent
```

**View live logs:**
```bash
cf logs template-tf
```

## Deployment Guide

## Deployment Guide

[Section already expanded above]

## Configuration

### FastAPI Application Configuration

#### main.py - Application Entry Point

Your main application file defines all API endpoints and routes:

```python
from fastapi import FastAPI

app = FastAPI(
    title="My FastAPI App",
    description="API Description",
    version="1.0.0"
)

@app.get("/")
async def root():
    return {"message": "Hello World"}

@app.get("/api/status")
async def health_check():
    return {"status": "healthy"}
```

#### requirements.txt - Python Dependencies

Specify all Python packages your application needs:

```
fastapi==0.129.0
uvicorn==0.41.0
pydantic==2.12.5
# Add your dependencies below
```

**Managing Dependencies:**
```bash
# Add new package
pip install new-package
pip freeze > requirements.txt

# Using uv (faster)
uv pip install new-package
uv pip freeze > requirements.txt
```

### manifest.yml - CloudFoundry Application Manifest

Configuration file for CloudFoundry deployment:

```yaml
applications:
  - name: fastapi-template           # Application name in CloudFoundry
    memory: 256M                      # RAM per instance
    instances: 1                      # Number of running instances
    buildpacks:
      - python_buildpack              # CloudFoundry buildpack
    path: ./
```

**Customization Options:**
```yaml
applications:
  - name: my-fastapi-app
    memory: 512M                      # Increase for larger apps
    instances: 2                      # Scale for production
    buildpacks:
      - python_buildpack
    path: ./
    env:                              # Environment variables
      LOG_LEVEL: info
      DEBUG: false
    health-check-type: http           # Health check endpoint
    health-check-http-endpoint: /     # Endpoint to check
```

### Procfile - CloudFoundry Process Definition

Defines how to start your application:

```
web: uvicorn main:app --host=0.0.0.0 --port=${PORT:-8080}
```

**Process Type Explanation:**
- `web` - Web application process (receives HTTP traffic)
- `worker` - Background worker (for async jobs)

**Procfile Examples:**

Production with Gunicorn:
```
web: gunicorn main:app --workers=4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:${PORT:-8080}
```

With Logging:
```
web: uvicorn main:app --host=0.0.0.0 --port=${PORT:-8080} --log-level ${LOG_LEVEL:-info}
```

### Environment Variables

Set environment variables in Terraform configuration:

```terraform
environment = {
  SERVER_HOST   = "http://localhost"
  SERVER_PORT   = 8080
  DEBUG         = "false"
  LOG_LEVEL     = "info"
  DATABASE_URL  = "postgresql://..."
  API_KEY       = var.api_key      # From Terraform variables
}
```

**Accessing in FastAPI:**
```python
import os
from fastapi import FastAPI

app = FastAPI()

DEBUG = os.getenv("DEBUG", "false").lower() == "true"
LOG_LEVEL = os.getenv("LOG_LEVEL", "info")

@app.get("/config")
async def get_config():
    return {"debug": DEBUG, "log_level": LOG_LEVEL}
```

### Terraform Configuration

#### BTP Module (tools/terraform/BTP/)

Queries your BTP environment:

```terraform
# main.tf - Queries BTP resources
data "btp_subaccounts" "all" {}
data "btp_subaccount_environment_instances" "all" {}

# variables.tf - Input variables
variable "btp_username" {
  type = string
  sensitive = true
}

# providers.tf - Provider configuration
provider "btp" {
  globalaccount = "your-global-account"
  username = var.btp_username
  password = var.btp_password
}
```

#### CloudFoundry Module (tools/terraform/cloudfoundry/)

Manages CloudFoundry resources:

```terraform
# main.tf - Create route and deploy app
resource "cloudfoundry_route" "route" {
  space  = data.cloudfoundry_space.dev.id
  domain = data.cloudfoundry_domain.cfapps.id
  host   = "my-app"
}

resource "cloudfoundry_app" "server" {
  name = "my-fastapi-app"
  space_name = "dev"
  path = "../../deploy.zip"
  instances = 1
}
```

## Customization

### Adding New FastAPI Endpoints

Extend your application with custom endpoints:

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

class Item(BaseModel):
    name: str
    price: float

@app.post("/api/items")
async def create_item(item: Item):
    """Create a new item"""
    return {"id": 1, "item": item}

@app.get("/api/items/{item_id}")
async def get_item(item_id: int):
    """Retrieve a specific item"""
    if item_id < 1:
        raise HTTPException(status_code=400, detail="Invalid item ID")
    return {"id": item_id, "name": "Sample Item"}

@app.put("/api/items/{item_id}")
async def update_item(item_id: int, item: Item):
    """Update an existing item"""
    return {"id": item_id, "updated": item}

@app.delete("/api/items/{item_id}")
async def delete_item(item_id: int):
    """Delete an item"""
    return {"deleted": True, "id": item_id}
```

**Best Practices:**
- Use descriptive function names
- Add docstrings for documentation
- Use Pydantic models for validation
- Include HTTP status codes
- Implement error handling

### Adding Python Dependencies

Add required packages to your project:

```bash
# Add a single package
pip install sqlalchemy

# Update requirements.txt
pip freeze > requirements.txt

# Or using uv (faster)
uv pip install sqlalchemy
uv pip freeze > requirements.txt
```

**Common Dependencies:**
- `sqlalchemy` - Database ORM
- `requests` - HTTP client
- `python-dotenv` - Environment variables
- `pydantic-settings` - Settings management
- `pytest` - Testing framework
- `httpx` - Async HTTP client

### Creating Modular Application Structure

Organize your code into a professional structure:

```
fastapi-btp/
├── main.py                      # Entry point
├── services/
│   ├── __init__.py
│   ├── user_service.py         # User business logic
│   ├── product_service.py      # Product business logic
│   └── database_service.py     # Database operations
├── models/
│   ├── __init__.py
│   ├── user.py                 # User models
│   ├── product.py              # Product models
│   └── schemas.py              # Request/response schemas
├── routes/
│   ├── __init__.py
│   ├── users.py                # User endpoints
│   └── products.py             # Product endpoints
└── config/
    ├── __init__.py
    └── settings.py             # Configuration
```

**Example: services/user_service.py**
```python
class UserService:
    @staticmethod
    async def get_user(user_id: int):
        # Database query logic
        return {"id": user_id, "name": "John"}
    
    @staticmethod
    async def create_user(name: str, email: str):
        # Create user logic
        return {"id": 1, "name": name, "email": email}
```

**Example: routes/users.py**
```python
from fastapi import APIRouter
from services.user_service import UserService

router = APIRouter(prefix="/api/users", tags=["users"])

@router.get("/{user_id}")
async def get_user(user_id: int):
    return await UserService.get_user(user_id)

@router.post("/")
async def create_user(name: str, email: str):
    return await UserService.create_user(name, email)
```

**Update main.py:**
```python
from fastapi import FastAPI
from routes.users import router as user_router

app = FastAPI()
app.include_router(user_router)
```

**Update tools/zip_files.py:**
```python
zip_files("deploy.zip", [
    "./../main.py",
    "./../requirements.txt",
    "./../services",        # Add services directory
    "./../models",          # Add models directory
    "./../routes",          # Add routes directory
    "./../config",          # Add config directory
    "./../manifest.yml",
    "./../Procfile"
])
```

### Scaling Configuration

#### Increase Instances for High Traffic

Edit `tools/terraform/cloudfoundry/main.tf`:

```terraform
resource "cloudfoundry_app" "server" {
  # ...existing code...
  instances = 3          # Change from 1 to 3 instances
  # ...existing code...
}
```

#### Adjust Memory Allocation

Edit `manifest.yml`:

```yaml
applications:
  - name: fastapi-template
    memory: 512M           # Increase from 256M
    instances: 2
```

### Database Integration

#### Example: PostgreSQL with SQLAlchemy

1. Add dependencies:
```bash
pip install sqlalchemy psycopg2-binary
pip freeze > requirements.txt
```

2. Create database models in `models/database.py`:
```python
from sqlalchemy import Column, Integer, String, create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    name = Column(String)
    email = Column(String, unique=True)

DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
```

3. Set environment variable in Terraform:
```terraform
environment = {
  DATABASE_URL = "postgresql://user:password@host:5432/dbname"
}
```

### Updating Manifest Configuration

Customize CloudFoundry application settings:

```yaml
applications:
  - name: fastapi-app
    memory: 512M
    instances: 2
    buildpacks:
      - python_buildpack
    path: ./
    env:
      LOG_LEVEL: info
      DEBUG: false
    health-check-type: http
    health-check-http-endpoint: /health
    timeout: 180
```

## Troubleshooting

### Common Setup Issues

#### Issue: "terraform not found"
**Solution:** Install Terraform and ensure it's in your system PATH
```bash
# Verify installation
terraform --version

# On macOS with Homebrew
brew install terraform

# On Windows with Chocolatey
choco install terraform

# Or download from https://www.terraform.io/downloads.html
```

#### Issue: "python not found"
**Solution:** Install Python 3.8 or higher
```bash
python --version
# Should output: Python 3.8.x or higher

# If not installed, download from https://www.python.org/downloads/
```

#### Issue: "Module not found" when running locally
**Solution:** Install all dependencies
```bash
pip install -r requirements.txt
# Or with uv
uv pip install -r requirements.txt
```

### Authentication and Credentials Issues

#### Issue: "Authentication failed" during Terraform apply
**Solution:** Verify BTP credentials and check permissions
```bash
# Verify credentials in terraform.tfvars
# Check that username and password are correct
# Ensure BTP account has necessary permissions

# Test BTP credentials manually if possible
cf login -a <API_ENDPOINT>
```

**Common causes:**
- Incorrect username or password
- BTP account credentials expired
- Missing permissions in BTP subaccount
- Credentials contain special characters (need escaping)

#### Issue: "Invalid GitLab token"
**Solution:** Generate new GitLab token with proper permissions
1. Go to GitLab: Settings → Access Tokens
2. Create new token with `api` scope
3. Update `gitlab_token` in `terraform.tfvars`

### Deployment Issues

#### Issue: "CloudFoundry space not found"
**Solution:** Update the space name in `tools/terraform/cloudfoundry/main.tf`
```terraform
data "cloudfoundry_space" "dev" {
    name = "your-actual-space-name"  # Check your CF space name
    org  = data.terraform_remote_state.btp.outputs.org_id
}
```

**Find your space name:**
```bash
cf login
cf spaces
```

#### Issue: "deploy.zip not found during terraform apply"
**Solution:** Ensure you packaged the application before deployment
```bash
cd tools
python zip_files.py

# Verify ZIP file was created
ls -lh deploy.zip
```

#### Issue: "Application failed to start" on deployment
**Solution:** Check application logs
```bash
cf logs template-tf --recent

# Common causes:
# - Missing dependencies in requirements.txt
# - Wrong Procfile format
# - Port binding issues
# - Environment variable not set
```

### Local Development Issues

#### Issue: "Port 8080 already in use"
**Solution:** Use a different port
```bash
# Use port 8081 instead
uvicorn main:app --host=0.0.0.0 --port=8081

# Or kill the process using port 8080
# On Linux/macOS:
lsof -ti:8080 | xargs kill -9

# On Windows:
netstat -ano | findstr :8080
taskkill /PID <PID> /F
```

#### Issue: "Module import errors"
**Solution:** Check Python path and imports
```bash
# Verify current directory in Python path
python -c "import sys; print(sys.path)"

# Run from project root directory
cd /path/to/fastapi-btp
python -m uvicorn main:app
```

### File and Configuration Issues

#### Issue: "zip_files.py: path does not exist"
**Solution:** Verify paths in zip_files.py are correct
```python
# Check if directories exist before adding to zip
if __name__ == "__main__":
    zip_files("deploy.zip", [
        "./../main.py",          # Verify file exists
        "./../requirements.txt",  # Verify file exists
        "./../manifest.yml",
        "./../Procfile"
        # Remove non-existent directories
    ])
```

**Debug:**
```bash
# From tools directory, verify paths
ls -la ../main.py
ls -la ../requirements.txt
```

#### Issue: "Terraform state conflicts"
**Solution:** Reset local state and reinitialize
```bash
cd terraform/cloudfoundry

# Backup existing state
mv terraform.tfstate terraform.tfstate.bak

# Reinitialize
terraform init

# Reapply configuration
terraform plan
terraform apply
```

### Performance and Resource Issues

#### Issue: "Application timeout during deployment"
**Solution:** Increase CloudFoundry timeout
```yaml
# In manifest.yml
applications:
  - name: fastapi-template
    timeout: 300  # Increase from default 60 to 300 seconds
```

#### Issue: "Out of memory errors"
**Solution:** Increase memory allocation
```yaml
# In manifest.yml
applications:
  - name: fastapi-template
    memory: 512M  # Increase from 256M
```

### Checking Application Logs

#### View recent logs
```bash
cf logs template-tf --recent
```

#### Stream live logs
```bash
cf logs template-tf
```

#### Filter logs by source
```bash
cf logs template-tf --recent | grep ERR
cf logs template-tf --recent | grep WARNING
```

### Getting Help

1. **Check application logs:** `cf logs <app-name> --recent`
2. **Verify Terraform state:** `terraform show`
3. **Review BTP documentation:** https://help.sap.com/docs/btp
4. **Check CloudFoundry status:** `cf status`
5. **Validate Terraform:** `terraform validate`

## Best Practices

### Security

1. **Never commit credentials** - Store sensitive data in environment variables or secret management systems
   ```bash
   # Use environment variables
   export BTP_USERNAME="user@example.com"
   export BTP_PASSWORD="secure_password"
   
   # Or use .env file (add to .gitignore)
   # Then load with python-dotenv
   ```

2. **Use .gitignore** - Exclude sensitive files from version control
   ```
   terraform.tfvars
   *.tfstate
   *.tfstate.*
   deploy.zip
   __pycache__/
   .env
   .venv/
   venv/
   ```

3. **Rotate credentials regularly** - Update BTP and GitLab credentials periodically

4. **Use VPN or bastion hosts** - For sensitive deployments, use secure networks

### Development Workflow

1. **Test locally first** - Always test the FastAPI application locally before deploying
   ```bash
   uvicorn main:app --host=0.0.0.0 --port=8080 --reload
   ```

2. **Use version control** - Keep Terraform configurations in Git
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   ```

3. **Write tests** - Use pytest for unit and integration tests
   ```bash
   pip install pytest httpx
   pytest tests/
   ```

4. **Code review** - Have changes reviewed before deployment

### Infrastructure Management

1. **State management** - Use remote state backend (HTTP/GitLab) for team collaboration
   ```terraform
   backend "http" {
     address = "https://your-gitlab-instance.com/api/v4/projects/12345/terraform/state"
   }
   ```

2. **Environment separation** - Use separate BTP subaccounts for dev, staging, and production
   - Development: For testing and experimentation
   - Staging: Production-like environment
   - Production: Customer-facing environment

3. **Dependency management** - Keep `requirements.txt` updated and pinned to specific versions
   ```
   fastapi==0.129.0
   uvicorn==0.41.0
   pydantic==2.12.5
   ```

4. **Monitor applications** - Set up alerting and monitoring for production deployments

### API Design

1. **Use semantic versioning** - Version your APIs for backward compatibility
   ```python
   app = FastAPI(version="1.0.0")
   
   @app.get("/api/v1/items")
   async def get_items_v1():
       pass
   ```

2. **Document endpoints** - Use FastAPI's automatic documentation
   ```python
   @app.get("/items/{item_id}", 
            summary="Get an item",
            description="Retrieve item details by ID",
            responses={404: {"description": "Item not found"}})
   async def get_item(item_id: int):
       """Get item by ID"""
       pass
   ```

3. **Implement error handling** - Return consistent error responses
   ```python
   from fastapi import HTTPException
   
   @app.get("/items/{item_id}")
   async def get_item(item_id: int):
       if item_id < 1:
           raise HTTPException(
               status_code=400,
               detail="Item ID must be positive"
           )
   ```

4. **Use pagination** - For endpoints returning lists
   ```python
   @app.get("/items")
   async def list_items(skip: int = 0, limit: int = 10):
       return {"items": [], "skip": skip, "limit": limit}
   ```

### Performance Optimization

1. **Enable caching** - Cache frequently accessed data
   ```python
   from fastapi import Response
   
   @app.get("/items")
   async def get_items(response: Response):
       response.headers["Cache-Control"] = "max-age=3600"
       return {"items": []}
   ```

2. **Use async/await** - FastAPI is built for async operations
   ```python
   @app.get("/items")
   async def get_items():
       # Use async database operations
       items = await db.fetch_items()
       return items
   ```

3. **Optimize database queries** - Use indexes and lazy loading
   ```python
   # Bad: N+1 queries
   users = db.query(User).all()
   for user in users:
       print(user.posts)  # This queries again for each user
   
   # Good: Use joins or eager loading
   users = db.query(User).options(joinedload(User.posts)).all()
   ```

4. **Use CDN** - For static assets and media files

### Logging and Monitoring

1. **Structured logging** - Use consistent log format
   ```python
   import logging
   
   logger = logging.getLogger(__name__)
   logger.info("User login", extra={"user_id": 123})
   ```

2. **Set appropriate log levels** - DEBUG, INFO, WARNING, ERROR, CRITICAL

3. **Monitor application metrics** - Track CPU, memory, response times

4. **Set up alerts** - Alert on errors and performance issues

## Useful Commands

```bash
# Local development
uvicorn main:app --host=0.0.0.0 --port=8080

# Package application
python tools/zip_files.py

# Terraform operations
terraform init
terraform plan
terraform apply
terraform destroy

# CloudFoundry operations
cf login -a <API_ENDPOINT>
cf push
cf logs <APP_NAME>
cf restart <APP_NAME>
```

## Frequently Asked Questions (FAQ)

### General Questions

**Q: What is FastAPI and why should I use it?**
A: FastAPI is a modern, fast Python web framework for building APIs. It features automatic documentation, data validation with Pydantic, and supports async/await for high performance.

**Q: What is SAP BTP CloudFoundry?**
A: SAP Business Technology Platform CloudFoundry is a Platform-as-a-Service (PaaS) environment that allows you to deploy and manage cloud applications without managing infrastructure.

**Q: Can I use this template for production?**
A: Yes, this template provides a solid foundation for production deployments. Ensure you follow security best practices and perform thorough testing.

### Setup and Installation

**Q: Do I need to install all the tools separately?**
A: Yes, Terraform and Python need to be installed manually. CloudFoundry CLI is optional but recommended for easier management.

**Q: How do I verify my tools are installed correctly?**
A: Run verification commands:
```bash
terraform --version
python --version
cf --version
```

**Q: Can I use Python 3.7?**
A: The template requires Python 3.8 or higher. Update to a supported version.

### Customization

**Q: How do I add a new endpoint to my API?**
A: Edit `main.py` and add a new function with a route decorator:
```python
@app.get("/api/new-endpoint")
async def new_endpoint():
    return {"message": "Hello"}
```

**Q: Can I use a database with this template?**
A: Yes, you can integrate databases like PostgreSQL. Add the driver to `requirements.txt` and create models using SQLAlchemy.

**Q: How do I add environment-specific configuration?**
A: Use environment variables in Terraform and access them in your FastAPI app:
```python
import os
db_url = os.getenv("DATABASE_URL")
```

### Deployment

**Q: Why do I need to run zip_files.py before deploying?**
A: This script packages your application and dependencies into a ZIP file that CloudFoundry can understand and deploy.

**Q: How often should I update my deployment?**
A: As often as your development cycle requires. Just update files, run `zip_files.py`, and re-apply Terraform.

**Q: Can I have multiple instances of my application running?**
A: Yes, increase the `instances` parameter in `manifest.yml` or Terraform configuration for high availability.

**Q: How do I rollback a deployment?**
A: Terraform maintains state, so you can:
```bash
terraform destroy  # Remove current deployment
git checkout <previous-version>  # Revert code
terraform apply  # Redeploy previous version
```

### Troubleshooting

**Q: My application won't start. What should I check?**
A: 1. Check logs: `cf logs <app-name> --recent`
   2. Verify Procfile is correct
   3. Ensure all dependencies are in requirements.txt
   4. Check for port binding issues

**Q: How do I see what's in my deployed ZIP file?**
A: Extract and inspect:
```bash
unzip -l deploy.zip
```

**Q: Can I test my Terraform configuration before applying?**
A: Yes, use `terraform plan`:
```bash
terraform plan -out=tfplan
```

**Q: What if I lose my Terraform state?**
A: Use remote state backend to prevent loss. For recovery:
```bash
terraform import <resource-type>.<name> <resource-id>
```

### Performance and Scaling

**Q: How can I make my application faster?**
A: 1. Use async/await for I/O operations
   2. Enable caching with appropriate headers
   3. Optimize database queries
   4. Use a CDN for static assets

**Q: When should I increase memory or instances?**
A: Increase memory if you see out-of-memory errors. Add instances for high traffic or CPU-intensive workloads.

**Q: How do I monitor my application performance?**
A: Use CloudFoundry logs and integrate with monitoring tools like ELK Stack, Datadog, or New Relic.

### Security

**Q: Should I commit my terraform.tfvars file?**
A: No, never commit files with credentials. Add to `.gitignore` and use secure credential management.

**Q: How do I secure sensitive data?**
A: Use environment variables, secret management systems (Vault, AWS Secrets Manager), or GitLab CI/CD secrets.

**Q: Is it safe to use this template for personal projects?**
A: Yes, but always follow security best practices, especially regarding credential management.

## References

### Official Documentation

- [FastAPI Documentation](https://fastapi.tiangolo.com/) - Complete FastAPI guide and best practices
- [Terraform Documentation](https://www.terraform.io/docs) - Official Terraform reference
- [SAP BTP Documentation](https://help.sap.com/docs/btp) - SAP BTP official documentation
- [CloudFoundry CLI Documentation](https://docs.cloudfoundry.org/cf-cli/) - CloudFoundry command reference
- [SAP BTP Terraform Provider](https://github.com/SAP/terraform-provider-btp) - BTP Terraform provider source

### FastAPI Resources

- [FastAPI Tutorial](https://fastapi.tiangolo.com/tutorial/) - Step-by-step FastAPI tutorial
- [Pydantic Documentation](https://docs.pydantic.dev/) - Data validation library
- [Uvicorn Server](https://www.uvicorn.org/) - ASGI server documentation
- [Starlette Framework](https://www.starlette.io/) - Underlying FastAPI framework

### Terraform Resources

- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices) - Terraform best practices guide
- [Terraform State Management](https://www.terraform.io/docs/state/) - State file best practices
- [Terraform Modules](https://www.terraform.io/docs/modules/) - Modular infrastructure code
- [CloudFoundry Provider](https://registry.terraform.io/providers/cloudfoundry-community/cloudfoundry/latest/docs) - CloudFoundry Terraform provider

### SAP BTP Resources

- [SAP BTP Cloud Foundry Environment](https://help.sap.com/docs/btp/sap-btp-cloud-foundry-environment/sap-btp-cloud-foundry-environment) - CF environment guide
- [BTP Subaccounts](https://help.sap.com/docs/btp/sap-btp-getting-started/managing-subaccounts) - Subaccount management
- [BTP Global Account](https://help.sap.com/docs/btp/sap-btp-getting-started/managing-global-account) - Global account setup
- [BTP Services](https://help.sap.com/docs/btp/platform-services-catalog) - Available BTP services

### Python Development Resources

- [Python.org - Official](https://www.python.org/) - Official Python website
- [Python Virtual Environments](https://docs.python.org/3/tutorial/venv.html) - Managing Python environments
- [pip Package Manager](https://pip.pypa.io/) - Python package management
- [Poetry Package Manager](https://python-poetry.org/) - Alternative to pip

### Docker and Container Resources

- [Docker Documentation](https://docs.docker.com/) - Container platform
- [Docker for Python Applications](https://docs.docker.com/language/python/) - Python in Docker
- [CloudFoundry Buildpacks](https://docs.cloudfoundry.org/buildpacks/) - How applications are built

### Related Frameworks and Tools

- [Flask](https://flask.palletsprojects.com/) - Lightweight Python framework
- [Django](https://www.djangoproject.com/) - Full-featured Python framework
- [Gunicorn](https://gunicorn.org/) - Python WSGI server
- [uv Package Manager](https://github.com/astral-sh/uv) - Fast Python package manager

### Community and Support

- [FastAPI GitHub Issues](https://github.com/tiangolo/fastapi/issues) - FastAPI issue tracker
- [Stack Overflow - FastAPI](https://stackoverflow.com/questions/tagged/fastapi) - FastAPI questions
- [Stack Overflow - Terraform](https://stackoverflow.com/questions/tagged/terraform) - Terraform questions
- [SAP Community](https://community.sap.com/t5/SAP-Business-Technology-Platform/ct-p/sap-btp) - SAP BTP community

### Related Templates and Examples

- [FastAPI Full Stack Template](https://github.com/tiangolo/full-stack-fastapi-postgresql) - Full stack FastAPI example
- [Terraform CloudFoundry Examples](https://github.com/cloudfoundry-community/terraform-provider-cloudfoundry/examples) - CloudFoundry Terraform examples
- [SAP BTP Examples](https://github.com/SAP-samples) - Official SAP samples repository

## Support

For issues or questions:
1. Check the **Troubleshooting** section
2. Review application logs using `cf logs`
3. Verify Terraform state with `terraform show`
4. Check **FAQ** section for common questions
5. Review **References** for additional documentation

## Related Topics

- **Infrastructure as Code (IaC)** - Manage infrastructure using code
- **Continuous Deployment** - Automate application deployments
- **Microservices Architecture** - Design patterns for scalable applications
- **API Development** - Best practices for API design
- **Cloud-Native Applications** - Principles for cloud deployment
- **DevOps** - Development and operations integration

## License

This template is provided as-is for use with SAP Business Technology Platform.
