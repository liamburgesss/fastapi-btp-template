# FastAPI BTP Template

A production-ready FastAPI application template for deploying to SAP Business Technology Platform (BTP) CloudFoundry environment using Terraform Infrastructure as Code.

## Overview

This template provides a complete setup for:
- **FastAPI Application**: A modern, high-performance Python web framework
- **Terraform Deployment**: Infrastructure as Code for automated CloudFoundry deployments
- **BTP Integration**: Native integration with SAP Business Technology Platform
- **Automated Packaging**: ZIP file generation for CloudFoundry deployment

## Prerequisites

### Required Tools

1. **Terraform** (v1.0+)
   - Download from: https://www.terraform.io/downloads.html
   - Add to PATH for command-line access
   - Required for infrastructure provisioning and deployment

2. **Python** (v3.8+)
   - For running the FastAPI application locally
   - Install dependencies using `pip` or `uv`

3. **CloudFoundry CLI** (optional, for manual deployments)
   - Download from: https://github.com/cloudfoundry/cli/releases

4. **Git** (recommended)
   - For version control and repository management

### BTP Configuration

You must have the following BTP resources pre-configured:

1. **SAP BTP Subaccount**
   - Access to a BTP subaccount with proper permissions
   - BTP credentials (username and password)
   - Note the subaccount name for Terraform variable configuration

2. **CloudFoundry Environment Instance**
   - A CloudFoundry environment instance must be created in your BTP subaccount
   - The instance will be queried automatically by the BTP Terraform module
   - Ensure API endpoint is accessible

3. **CloudFoundry Space**
   - At least one space created in the CloudFoundry org (typically "dev" or "staging")
   - Required for application deployment

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

### 1. Local Development

#### Clone or Extract the Template

```bash
# Extract template files to your desired location
cd fastapi-btp
```

#### Install Dependencies

Using `pip`:
```bash
pip install -r requirements.txt
```

Or using `uv` (recommended for faster installation):
```bash
uv pip install -r requirements.txt
```

#### Run Locally

```bash
# Start the FastAPI application with uvicorn
# Command is defined in Procfile for consistency
uvicorn main:app --host=0.0.0.0 --port=8080
```

The application will be available at: `http://localhost:8080`

API endpoints:
- `GET /` - Returns a welcome message
- `GET /hello/{name}` - Returns a personalized greeting

#### Test Endpoints

You can test the endpoints using:
```bash
# Using curl
curl http://localhost:8080/
curl http://localhost:8080/hello/World
```

Or use the provided HTTP test file: `test_main.http`

### 2. Prepare Application for Deployment

Before deploying to BTP, you must configure which files will be packaged and deployed.

#### Update zip_files.py

Edit `tools/zip_files.py` to include all necessary application files:

```python
if __name__ == "__main__":
    zip_files("deploy.zip", [
        "./../main.py",                  # Application entry point (required)
        "./../requirements.txt",         # Dependencies (required)
        "./../services",                 # Custom services (if applicable)
        "./../env_models",               # Environment models (if applicable)
        "./../manifest.yml",             # CloudFoundry manifest (required)
        "./../Procfile"                  # Process definition (required)
        # Add any additional directories or files needed
    ])
```

**Important Files to Include:**
- `main.py` - Your FastAPI application
- `requirements.txt` - Python dependencies
- `Procfile` - CloudFoundry process commands
- `manifest.yml` - Application configuration

**Common Additions:**
- `services/` - Service layer modules
- `models/` - Data models and schemas
- `env_models/` - Environment configuration models
- `.env` - Environment variables (if using dotenv)

#### Understand the Procfile

The `Procfile` defines how CloudFoundry runs your application:

```
web: uvicorn main:app --host=0.0.0.0 --port=${PORT:-8080}
```

- `web:` - Process type (required for web applications)
- `uvicorn main:app` - Runs the FastAPI app using ASGI server
- `--host=0.0.0.0` - Listens on all network interfaces
- `--port=${PORT:-8080}` - Uses PORT environment variable (default: 8080)

You can modify this command if needed, but keep the ASGI server pattern.

### 3. Prepare Terraform Variables

Create or update Terraform variable files for your environment.

#### BTP Variables File

Create `tools/terraform/BTP/terraform.tfvars`:

```hcl
btp_username     = "your-btp-username@example.com"
btp_password     = "your-btp-password"
subaccount_name  = "your-subaccount-name"
target-directory = "/optional/target/directory"
```

#### CloudFoundry Variables File

Create `tools/terraform/cloudfoundry/terraform.tfvars`:

```hcl
btp_username   = "your-btp-username@example.com"
btp_password   = "your-btp-password"
btp_state_url  = "https://your-gitlab-instance.com/api/v4/projects/12345/terraform/state/btp"
gitlab_username = "your-gitlab-username"
gitlab_token   = "your-gitlab-token"
```

**Important:**
- `btp_state_url` should reference where BTP Terraform state is stored (typically GitLab)
- Credentials should be kept secure (use environment variables or secret management)
- Never commit `terraform.tfvars` files with real credentials to version control

#### Update CloudFoundry Main Configuration

Edit `tools/terraform/cloudfoundry/main.tf` to set your CloudFoundry space name:

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
```

### 4. Deploy to BTP CloudFoundry

#### Step 1: Package the Application

```bash
cd tools
python zip_files.py
```

This creates `deploy.zip` containing all files specified in `zip_files.py`.

Verify the zip file was created successfully:
```bash
ls -lh deploy.zip
```

#### Step 2: Initialize Terraform (First Time Only)

```bash
# For BTP module
cd terraform/BTP
terraform init -backend-config="address=https://your-gitlab-instance.com/api/v4/projects/12345/terraform/state/btp" \
               -backend-config="username=your-gitlab-username" \
               -backend-config="password=your-gitlab-token"

# For CloudFoundry module
cd ../cloudfoundry
terraform init
```

#### Step 3: Apply Terraform Configuration

```bash
# Deploy to CloudFoundry
cd terraform/cloudfoundry
terraform apply -auto-approve
```

Or use the automated deployment script:

```bash
cd tools
./deploy.sh
```

**Note:** The `deploy.sh` script performs the following:
1. Generates/updates `requirements.txt` using `uv pip freeze`
2. Packages application files into `deploy.zip`
3. Destroys previous deployment
4. Applies new Terraform configuration

#### Step 4: Verify Deployment

After successful deployment, Terraform will output the application URL:

```bash
# Get the deployed application URL
terraform output url
```

Visit the URL in your browser or test with curl:
```bash
curl https://template.cfapps.<region>.hana.ondemand.com/
```

## Environment Variables

The CloudFoundry deployment supports the following environment variables:

```terraform
environment = {
  SERVER_HOST = "http://localhost"
  SERVER_PORT = 8080
}
```

You can add additional variables in `tools/terraform/cloudfoundry/main.tf`:

```terraform
environment = {
  SERVER_HOST   = "http://localhost"
  SERVER_PORT   = 8080
  DEBUG         = "false"
  LOG_LEVEL     = "info"
  # Add your application-specific variables
}
```

## Customizing the Application

### Adding New Endpoints

Edit `main.py` to add new FastAPI endpoints:

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello World"}

@app.get("/hello/{name}")
async def say_hello(name: str):
    return {"message": f"Hello {name}"}

# Add your custom endpoints
@app.get("/api/data")
async def get_data():
    return {"data": "your data here"}

@app.post("/api/process")
async def process_data(data: dict):
    # Process and return results
    return {"result": "processed"}
```

### Adding Dependencies

Update `requirements.txt` with new Python packages:

```bash
pip install package-name
pip freeze >> requirements.txt
```

Or with uv:
```bash
uv pip install package-name
uv pip freeze >> requirements.txt
```

### Adding Application Files

1. Create your modules (e.g., `services/`, `models/`, `config/`)
2. Update `tools/zip_files.py` to include the new directories:
   ```python
   zip_files("deploy.zip", [
       "./../main.py",
       "./../requirements.txt",
       "./../services",
       "./../models",
       "./../config",
       "./../manifest.yml",
       "./../Procfile"
   ])
   ```
3. Re-deploy using the deployment process

### Updating Manifest Configuration

Edit `manifest.yml` to customize CloudFoundry settings:

```yaml
applications:
  - name: fastapi-template       # Application name in CloudFoundry
    memory: 256M                  # Memory allocation
    instances: 1                  # Number of instances
    buildpacks:
      - python_buildpack          # CloudFoundry buildpack
    path: ./
```

Modify as needed for your application requirements.

## Troubleshooting

### Issue: "terraform not found"
**Solution:** Install Terraform and ensure it's in your system PATH
```bash
# Verify installation
terraform --version
```

### Issue: "Authentication failed"
**Solution:** Verify BTP credentials and ensure:
- Username and password are correct
- BTP account has sufficient permissions
- Credentials are properly set in `terraform.tfvars`

### Issue: "CloudFoundry space not found"
**Solution:** Update the space name in `tools/terraform/cloudfoundry/main.tf`:
```terraform
name = "your-actual-space-name"
```

### Issue: "deploy.zip not found during terraform apply"
**Solution:** Ensure you ran `python zip_files.py` before applying Terraform:
```bash
cd tools
python zip_files.py
```

### Issue: "Port already in use" during local development
**Solution:** Use a different port:
```bash
uvicorn main:app --host=0.0.0.0 --port=8081
```

### Checking Application Logs

View CloudFoundry application logs:
```bash
cf logs template-tf --recent
```

Or stream live logs:
```bash
cf logs template-tf
```

## Best Practices

1. **Never commit credentials** - Store sensitive data in environment variables or secret management systems
2. **Use .gitignore** - Exclude `terraform.tfvars`, `*.tfstate`, `deploy.zip`, and `__pycache__`
3. **Test locally first** - Always test the FastAPI application locally before deploying
4. **Version control** - Keep Terraform configurations in version control
5. **State management** - Use remote state backend (HTTP/GitLab) for team collaboration
6. **Environment separation** - Use separate BTP subaccounts for dev, staging, and production
7. **Dependency management** - Keep `requirements.txt` updated and pinned to specific versions

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

## References

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [SAP BTP Documentation](https://help.sap.com/docs/btp)
- [CloudFoundry CLI Documentation](https://docs.cloudfoundry.org/cf-cli/)
- [SAP BTP Terraform Provider](https://github.com/SAP/terraform-provider-btp)

## Support

For issues or questions:
1. Check the Troubleshooting section
2. Review application logs using `cf logs`
3. Verify Terraform state with `terraform show`
4. Check BTP documentation for account-specific issues

## License

This template is provided as-is for use with SAP Business Technology Platform.
