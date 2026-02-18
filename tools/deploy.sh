cd ../

uv pip freeze >> requirements.txt

cd tools || exit

python zip_files.py

cd terraform/btp || exit

terraform destroy --auto-approve
terraform apply --auto-approve

cd ../cloudfoundry || exit

terraform destroy --auto-approve
terraform apply --auto-approve