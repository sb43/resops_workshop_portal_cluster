#!/usr/bin/env bash
set -e
# Provisions an OpenLava cluster in OpenStack
# The script assumes that env vars for authentication with OpenStack are present.

## Customise this ##
export TF_VAR_name="$(awk -v var="$PORTAL_DEPLOYMENT_REFERENCE" 'BEGIN {print tolower(var)}')"
export TF_VAR_DEPLOYMENT_KEY_PATH="$PUBLIC_KEY"

# Launch provisioning of the infrastructure
cd ostack/terraform || exit
terraform apply -parallelism=10 -input=false -state=$PORTAL_DEPLOYMENTS_ROOT'/'$PORTAL_DEPLOYMENT_REFERENCE'/terraform.tfstate'
cd ../..

# Extract master ip from
master_ip=$(terraform output -state=$PORTAL_DEPLOYMENTS_ROOT'/'$PORTAL_DEPLOYMENT_REFERENCE'/terraform.tfstate' MASTER_IP)

# Extract volumes mapping from TF state file
./ostack/volume_parser.py $PORTAL_DEPLOYMENTS_ROOT'/'$PORTAL_DEPLOYMENT_REFERENCE'/terraform.tfstate' $PORTAL_DEPLOYMENTS_ROOT'/'$PORTAL_DEPLOYMENT_REFERENCE'/ostack_volumes_mapping.json'

# Check if ssh-agent is running
eval "$(ssh-agent -s)" &> /dev/null
ssh-add $PRIVATE_KEY &> /dev/null

# Launch Ansible
cd ostack/ansible || exit
TF_STATE=$PORTAL_DEPLOYMENTS_ROOT'/'$PORTAL_DEPLOYMENT_REFERENCE'/terraform.tfstate' ansible-playbook -i /usr/local/bin/terraform-inventory --extra-vars "master_ip=$master_ip" --tags=live -u centos -b deployment.yml

# Kill local ssh-agent
eval "$(ssh-agent -k)" &> /dev/null

echo "Your master IP is $master_ip"
