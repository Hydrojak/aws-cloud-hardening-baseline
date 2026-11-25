# Command Reference – AWS Cloud Hardening Baseline

This document lists **all common and advanced commands** that can be used with this project.  
Commands are grouped by category to serve as a **complete help/reference guide**.

---

## 1. Project Setup & Environment

### Terraform version
```bash
terraform version
```
Initialize Terraform (downloads providers & modules)
```bash
terraform init
```
Reinitialize (force provider/module re-download)
```bash
terraform init -reconfigure
terraform init -upgrade
```
2. Formatting & Validation
Format Terraform files
```bash
terraform fmt
terraform fmt -recursive
terraform fmt -check
```
Validate configuration
```bash
terraform validate
```
3. Planning & Deployment
Create an execution plan
```bash

terraform plan
```
Save a plan to a file
```bash
terraform plan -out=tfplan
```
Apply changes
```bash
terraform apply
```
Apply a saved plan
```bash
terraform apply tfplan
```
Auto-approve (no prompt)
```bash
terraform apply -auto-approve
```
4. Destroy & Cleanup
Destroy all managed resources
```bash
terraform destroy
```
Auto-approve destroy
```bash
terraform destroy -auto-approve
```
Destroy specific resources
```bash
terraform destroy -target=aws_s3_bucket.cloudtrail_logs
```
5. Variables & Configuration
Use a variable file
```bash
terraform plan -var-file="terraform.tfvars"
```
Override variables via CLI
```bash
terraform apply -var="aws_region=eu-west-1"
```
List all variables
```bash
terraform providers schema -json
```
6. State Management
Show current state
```bash
terraform show
```
List all resources in state
```bash
terraform state list
```
Show a specific resource
```bash
terraform state show aws_cloudtrail.main
```
Remove a resource from state (does NOT destroy it)
```bash
terraform state rm aws_s3_bucket.example
```
Move a resource inside the state
```bash
terraform state mv aws_s3_bucket.old aws_s3_bucket.new
```
7. Import Existing Resources
Import an existing AWS resource
```bash
terraform import aws_s3_bucket.cloudtrail_logs my-bucket-name
```
Import IAM role
```bash
terraform import aws_iam_role.guardrail_role role-name
```
8. Workspaces (Multi-Environment)
List workspaces
```bash
terraform workspace list
```
Create a workspace
```bash
terraform workspace new dev
```
Select a workspace
```bash
terraform workspace select prod
```
Delete a workspace
```bash
terraform workspace delete dev
```
9. Providers & Dependencies
Show providers used
```bash
terraform providers
```
Lock provider versions
```bash
terraform providers lock
```
10. Debugging & Troubleshooting
Enable detailed logs
```bash
export TF_LOG=TRACE
terraform apply
```
Save logs to a file
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
```
Disable logs
```bash
unset TF_LOG
unset TF_LOG_PATH
```
11. Security & Best Practices
Show execution plan in JSON
```bash
terraform show -json tfplan
```
Check unused providers
```bash
terraform providers schema
```
Validate IAM policies (AWS CLI)
```bash
aws iam validate-policy --policy-document file://policy.json
```
12. AWS CLI – Authentication
Configure AWS credentials
```bash
aws configure
```
Use named profiles
```bash
aws configure --profile security
export AWS_PROFILE=security
```
Check current identity
```bash
aws sts get-caller-identity
```
13. AWS CLI – CloudTrail
List trails
```bash
aws cloudtrail describe-trails
```
Get trail status
```bash
aws cloudtrail get-trail-status --name TrailName
```
Lookup events
```bash
aws cloudtrail lookup-events
```
14. AWS CLI – S3 Security
List buckets
```bash
aws s3 ls
```
Check public access block
```bash
aws s3api get-public-access-block --bucket bucket-name
```
Get bucket policy
```bash
aws s3api get-bucket-policy --bucket bucket-name
```
15. AWS CLI – CloudWatch & EventBridge
List log groups
```bash
aws logs describe-log-groups
```
Read log streams
```bash
aws logs describe-log-streams --log-group-name log-group
```
Put test event (EventBridge)
```bash
aws events put-events --entries file://event.json
```
16. AWS CLI – SNS Alerts
List SNS topics
```bash
aws sns list-topics
```
Subscribe email
```bash
aws sns subscribe \
  --topic-arn arn:aws:sns:region:account:topic \
  --protocol email \
  --notification-endpoint you@example.com
```
17. Cleanup & Reset
Remove Terraform cache
```bash
rm -rf .terraform
rm terraform.tfstate*
```
Reinitialize from scratch
```bash
terraform init -reconfigure
```
18. Help & Documentation
Terraform built-in help
```bash
terraform help
terraform help apply
```
Provider documentation
```bash
terraform providers
```
Notes
- Always review terraform plan before applying changes.

- Avoid using -auto-approve in production.

- Store Terraform state securely (remote backend recommended for production).