# 🧭 Runbook (TL;DR): Highly Available WordPress Platform on AWS with Terraform

> ## 👤 About
> This runbook is the **short, command-first guide** for rerunning the project once the workstation and AWS account are already prepared.  
> It focuses on the **happy-path execution flow**: initialize, validate, plan, apply, verify, and destroy.  
> For the full implementation narrative, concepts, and evidence mapping, see: **[docs/IMPLEMENTATION.md](IMPLEMENTATION.md)**.  
> For setup, IAM, AWS CLI, and budget preparation, see: **[docs/SETUP.md](SETUP.md)**.

---

## 📌 Index (top-level)

- [**Preconditions**](#preconditions)
- [**Step 01 - Initialize Terraform**](#step-01---initialize-terraform)
- [**Step 02 - Format and validate the configuration**](#step-02---format-and-validate-the-configuration)
- [**Step 03 - Save and inspect the plan**](#step-03---save-and-inspect-the-plan)
- [**Step 04 - Apply the reviewed infrastructure**](#step-04---apply-the-reviewed-infrastructure)
- [**Step 05 - Verify the live stack quickly in AWS and browser**](#step-05---verify-the-live-stack-quickly-in-aws-and-browser)
- [**Step 06 - Optional DB inspection via bastion**](#step-06---optional-db-inspection-via-bastion)
- [**Step 07 - Destroy the stack**](#step-07---destroy-the-stack)
- [**Step 08 - Post-destroy proof**](#step-08---post-destroy-proof)

---

## Preconditions

The Runbook assumes that the following steps are already completed:

- Terraform installed
- AWS CLI installed
- IAM user created
- AWS CLI profile configured
- local `terraform.tfvars` present
- AWS Budget created
- repository files already in place

If any of that is missing, use **[docs/SETUP.md](SETUP.md)** first.

FYI: The various **Make targets** are used as the primary command. The underlying raw Terraform or AWS commands are shown directly underneath in the `runs:` line for transparency + learning support.

---

## Step 01 - Initialize Terraform

~~~bash
# Initialize the Terraform working directory, providers, and module metadata.
# runs: terraform init
make init
~~~ 

### Important note

If the module structure changed since the last run, rerun `make init` before `make validate`, `make plan-save`, or `make apply`.

---

## Step 02 - Format and validate the configuration

~~~bash
# Format all Terraform files in the root module and child modules.
# runs: 'terraform fmt -recursive'
make fmt

 
# Check whether the configuration is structurally valid.
# runs: 'terraform validate'
make validate
~~~

---

## Step 03 - Save and inspect the plan

~~~bash
# Save the current reviewed plan to a file so the exact same plan can later be applied.
# runs: 'terraform plan -out=tfplan'
make plan-save

 
# Show a readable summary of create/update/delete actions from the saved plan.
# runs: 'terraform show -json tfplan | jq -r '...' '
make plan-summary

 
# Show grouped counts of changed resource types from the saved plan.
# runs: 'terraform show -json tfplan | jq -r '...' '
make plan-counts
~~~

### Optional inspection helpers

~~~bash
# Export the saved plan as JSON for further analysis tools.
# runs: 'terraform show -json tfplan > plan.json'
make plan-json
 
# Render the Terraform dependency graph as SVG.
# runs: 'terraform graph -type=plan | dot -Tsvg > terraform-plan-graph.svg'
make graph-plan-svg
 
# Render the Terraform dependency graph as PNG.
# runs: 'terraform graph -type=plan | dot -Tpng > terraform-plan-graph.png'
make graph-plan-png
 
# Generate an infrastructure graph from the Terraform configuration.
# runs: 'inframap generate . | dot -Tpng > inframap.png'
make inframap-png
~~~

---

## Step 04 - Apply the reviewed infrastructure

~~~bash
# Apply the previously saved Terraform plan exactly as reviewed.
# runs: 'terraform apply tfplan'
make apply

# Print the Terraform outputs after apply.
# runs: 'terraform output'
make output
~~~ 

### Expected important outputs

- `alb_dns_name`
- `asg_name`
- `bastion_public_ip`
- `db_endpoint`
- `public_subnet_ids`
- `private_subnet_ids`
- `selected_azs`
- `vpc_id`

---

## Step 05 - Verify the live stack quickly in AWS and browser

### Verification order

1. **EC2 -> Target Groups -> Targets**  
   Wait until the web targets become healthy.
2. Open the **ALB DNS name** from Terraform outputs in a browser.
3. Capture **AWS Console + Wordpress screenshots**:

### AWS Console locations / resources to verify + capture

#### VPC console
- **VPCs**
- **Subnets**
- **NAT gateways**

#### RDS console
- **Databases**
- click the DB instance
- open **Connectivity & security**

#### EC2 console
- **Load Balancers**
- **Target Groups**
- **Auto Scaling Groups**
- **Instances**

### Browser verification

**Open the ALB DNS name** from `make output` in the browser and confirm that WordPress loads.

### Summary: Evidence to capture

- Terminal output of `make apply`
- Terminal output of `make output`
- WordPress browser screenshots
- AWS screenshots for:
  - VPC
  - subnets
  - NAT gateways
  - RDS
  - ALB
  - Auto Scaling Group
  - EC2 instances
  - target group / target health

**The project evidence inventory** is stored under:
- `docs/evidence/aws/`
- `docs/evidence/wp/`

---

## Step 06 - Optional DB inspection via bastion

~~~bash
# SSH into the bastion host using the local private key.
# runs: ssh -i ~/.ssh/id_ed25519 ubuntu@<bastion_public_ip>
ssh -i ~/.ssh/id_ed25519 ubuntu@<bastion_public_ip>
 
# Install the MySQL client on the bastion.
# runs: sudo apt-get update && sudo apt-get install -y mysql-client
sudo apt-get update && sudo apt-get install -y mysql-client
 
# Connect from the bastion to the private RDS endpoint.
# runs: mysql -h <db_endpoint> -P 3306 -u <db_user> -p
mysql -h <db_endpoint> -P 3306 -u <db_user> -p
~~~

### Useful SQL checks

~~~sql
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT ID, user_login, user_email FROM wp_users;
~~~

---

## Step 07 - Destroy the stack


~~~bash
# Preview the planned destruction before deleting the stack.
# runs: terraform plan -destroy
terraform plan -destroy

# Destroy all Terraform-managed resources.
# runs: terraform destroy
make destroy
~~~

### Cost reminder

The AWS Budget provides **cost visibility and alerting**, but it is **not** the real shutdown mechanism. The actual stack teardown command is:

~~~bash
make destroy
~~~
---

## Step 08 - Post-destroy proof

### Post-destroy checks

- **Terminal output of `make destroy`**
- **AWS Tag Editor search** showing no active matching project resources - use the following settings to filter the ressouces accordingly:
    - **Region:** `eu-west-3`
    - **Ressource types:** `All supported ressource types`
    - **Tags:**
        - `Project: wordpress-platform`
        - `Environment: dev` 

- **NAT gateway view** showing deleted / terminated / deleting state if it lingers briefly
- **EC2 instance view** showing terminated state if it still remains visible briefly
- **AWS Budget overview** after destroy

**Hint:** Some AWS console views can lag briefly after destroy (the AWS Tag Editor f.i.).  