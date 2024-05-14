#!/bin/bash
cd "$(dirname "$0")"

# Create a bucket for tfstate
if [ -z $(aws s3 ls --output text | awk '{print $3}' | grep tfstate-) ]; then
    aws s3 mb s3://tfstate-$(uuidgen | tr A-Z a-z)
fi

export AWS_REGION=us-east-1
export TFSTATE_KEY=application-signals/demo-applications
export TFSTATE_BUCKET=$(aws s3 ls --output text | awk '{print $3}' | grep tfstate-)
export TFSTATE_REGION=$AWS_REGION

#Remove old TF Backend if exist
echo "Removing existing tfstate"
cd ../terraform
if test -d .terraform; then
    rm -rf .terraform
fi

old_tfstate=$(ls | grep *.tfstate*)
if [[ ! -z $old_tfstate ]]; then
    for f in ${old_tfstate[@]}; do
        if [ -f $f ]; then
            rm $f
        fi
    done
fi

if [ -f '.terraform.lock.hcl' ]; then
    rm '.terraform.lock.hcl'
fi

# init new backend
echo "init new backend"
terraform init -backend-config="bucket=${TFSTATE_BUCKET}" -backend-config="key=${TFSTATE_KEY}" -backend-config="region=${TFSTATE_REGION}"
terraform apply --auto-approve