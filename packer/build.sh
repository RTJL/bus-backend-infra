#!/bin/bash
env="$1"
if [ ! -n "$env" ]
then
    echo "$0 - Error \$env not set or NULL"
    exit 1
fi
# echo "Building AMI"
# ARTIFACT=`packer build -machine-readable public.json |awk -F, '$0 ~/artifact,0,id/ {print $6}'`
# AMI_ID=`echo $ARTIFACT | cut -d ':' -f2`
AMI_ID="ami-00ddb7565dd3952ad"
echo ${AMI_ID}
echo "Setting AMI value"
aws ssm put-parameter --name "/bus-backend-infra/${env}/ec2/public_ami" --value ${AMI_ID} --type "SecureString" --overwrite