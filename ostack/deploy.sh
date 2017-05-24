#!/usr/bin/env bash
set -e
# Provisions an OpenLava cluster in OpenStack
# The script assumes that env vars for authentication with OpenStack are present.

## Customise this ##
export TF_VAR_name="$(awk -v var="$PORTAL_DEPLOYMENT_REFERENCE" 'BEGIN {print tolower(var)}')"
export TF_VAR_DEPLOYMENT_KEY_PATH="$PUBLIC_KEY"

# Launch provisioning of the infrastructure
cd terraform || exit
terraform apply
cd ..

# Extract master ip from
master_ip=$(terraform output -state='terraform/terraform.tfstate' MASTER_IP)

# Extract volumes mapping from TF state file
./volume_parser.py 'terraform/terraform.tfstate' 'ostack_volumes_mapping.json'

# Check if ssh-agent is running
eval "$(ssh-agent -s)" &> /dev/null
ssh-add $PRIVATE_KEY &> /dev/null

# Launch Ansible
cd ansible || exit
TF_STATE='../terraform/terraform.tfstate' ansible-playbook -i /usr/local/bin/terraform-inventory --extra-vars "master_ip=$master_ip" -u centos deployment.yml --tags live

# Kill local ssh-agent
eval "$(ssh-agent -k)"

echo "Your master IP is $master_ip"
