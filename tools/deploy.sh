cd ../

uv pip freeze >> requirements.txt

cd tools || exit

python zip_files.py

cd terraform/cloudfoundry || exit

terraform destroy --auto-approve
terraform apply --auto-approve