# Bus Arrival Backend Infrastructure
Backend infrastructure (IaC) for bus arrival app. 
Built using Terraform and the following AWS services
- Route53
- Cloudfront (Caching, Routing of API/website)
- S3 (Terraform state management, static website host)
- API Gateway
- Lambda
- Systems Manager (Parameter Store)

## Getting started
- Create a new stage environment
- Deployment

### Create a new stage environment

1. Use Terraform workspaces to separate different environments

    Example - creating dev environment

    `terraform workspace new dev`

### Deployment

1. Select the workspace for deployment

    Example - deploy to dev environment
    
    `terraform workspace select dev`

2. Execute changes

    `terraform apply -var-file=vars/dev.tfvars`
