# 🛠️ Setup Guide: AWS Account Access, Local Tooling, and Cost Guardrails

> ## 👤 About
> This document is the **setup guide** for the Terraform-based AWS WordPress platform project.  
> It covers the **local workstation preparation** and the **AWS account preparation** that had to be in place before the real infrastructure work could start.  
> It is intentionally focused on setup-only topics: tooling, IAM access, local CLI profiles, local variable files, budget guardrails, and optional plan-inspection helpers.  
> For the project build diary and the broader Terraform/AWS concepts, see: **[docs/IMPLEMENTATION.md](IMPLEMENTATION.md)**.  
> For the short operational rerun flow, see: **[docs/RUNBOOK.md](RUNBOOK.md)**.

---

## 📌 Index (top-level)

- [**Purpose / Goal**](#purpose--goal)
- [**Definition of done**](#definition-of-done)
- [**Preconditions**](#preconditions)
- [**Step 01 - Install Terraform and basic local helper tools**](#step-01---install-terraform-and-basic-local-helper-tools)
- [**Step 02 - Install AWS CLI v2**](#step-02---install-aws-cli-v2)
- [**Step 03 - Create an IAM admin user for Terraform work**](#step-03---create-an-iam-admin-user-for-terraform-work)
- [**Step 04 - Create CLI / Terraform access keys for the IAM user**](#step-04---create-cli--terraform-access-keys-for-the-iam-user)
- [**Step 05 - Create a reusable local AWS CLI profile**](#step-05---create-a-reusable-local-aws-cli-profile)
- [**Step 06 - Prepare the local Terraform variable file**](#step-06---prepare-the-local-terraform-variable-file)
- [**Step 07 - Create AWS Budget guardrails before the first real apply**](#step-07---create-aws-budget-guardrails-before-the-first-real-apply)
- [**Step 08 - Optional local plan-inspection helpers**](#step-08---optional-local-plan-inspection-helpers)
- [**Sources**](#sources)

---

## Purpose / Goal

- Prepare the workstation so Terraform and AWS CLI commands can run reliably.
- Prepare the AWS account so infrastructure can be created through an **IAM user** instead of the root account.
- Create a **reusable local AWS CLI profile** that Terraform can use across projects.
- Put a **budget/alert guardrail** in place before the first real AWS deployment.
- Keep secrets and machine-specific values **local-only** while still publishing a clean repository.

## Definition of done

The setup phase is considered done when the following conditions are met:

- Terraform is installed locally and returns a version string.
- AWS CLI v2 is installed locally and returns a version string.
- An IAM user exists for daily AWS work and has both:
  - **console access**
  - **CLI / Terraform access keys**
- A reusable local AWS CLI profile exists and works.
- The profile can successfully run:
  - `aws sts get-caller-identity`
  - `aws ec2 describe-availability-zones --region eu-west-3`
- A local `terraform.tfvars` file exists and is ignored by Git.
- An AWS Budget exists as a cost guardrail before the first real `apply`.

## Preconditions

- Ubuntu / Linux workstation
- own AWS account available
- AWS console access available
- internet connection
- terminal access

---

## Step 01 - Install Terraform and basic local helper tools

### Rationale

Before any `.tf` files can be validated or applied, the Terraform CLI has to exist locally.  
A few helper tools are also needed for installation and later inspection tasks.

### Commands

~~~bash
# Install helper tools used during setup.
sudo apt-get update
sudo apt-get install -y curl unzip gpg lsb-release

# Add the official HashiCorp APT repository and install Terraform.
curl -fsSL https://apt.releases.hashicorp.com/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update
sudo apt-get install -y terraform

terraform version
~~~

### Why these helper tools are installed

- `curl` downloads repository keys and installer archives.
- `gpg` converts the repository signing key into the APT keyring format.
- `lsb-release` helps determine the Ubuntu codename for the APT source line.
- `unzip` is needed later for the AWS CLI installer ZIP.

### Result

Terraform should print a version string.

---

## Step 02 - Install AWS CLI v2

### Rationale

The Terraform AWS provider needs valid AWS credentials, but account verification is easier if the AWS CLI works first.

### Commands

~~~bash
# Install AWS CLI v2 from the official Linux ZIP installer.
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install

aws --version
~~~

### Result

`aws --version` should print an AWS CLI version string.

---

## Step 03 - Create an IAM admin user for Terraform work

> [!NOTE]
> **Root vs IAM user**  
> The AWS **root user** owns the account and should not be used for normal daily infrastructure work.  
> The safer pattern is: use root once for bootstrap tasks, then create an **IAM user** for ongoing AWS CLI / Terraform usage.

### Rationale

This project needs:
- **console access** for AWS UI verification
- **CLI access** for `aws` and Terraform provider authentication

### Click path: create the admin group

1. Log in to the AWS Console as **root**.
2. Search for **IAM**.
3. Open **IAM**.
4. In the left menu, click **User groups**.
5. Click **Create group**.
6. Group name: `Admins`
7. Attach the policy **AdministratorAccess**.
8. Click **Create user group**.

### Click path: create the IAM user

1. In the left menu, click **Users**.
2. Click **Create user**.
3. User name: `terraform-exam-admin` or another clear admin user name.
4. Click **Next**.
5. Add the user to the **Admins** group.
6. Click **Next**.
7. Review the settings.
8. Click **Create user**.

### Click path: enable console access

1. Open the new user.
2. Click **Security credentials**.
3. Under **Console sign-in**, enable console access if needed.
4. Set or keep the console password.

### Important clarification

At this point, the user has **console access**, but **CLI / Terraform access is not ready yet**.

---

## Step 04 - Create CLI / Terraform access keys for the IAM user

> [!NOTE]
> **Console access vs CLI access**  
> These are different credential types.
>
> - Console access uses: **sign-in URL + IAM username + password**
> - CLI / Terraform access uses: **Access Key ID + Secret Access Key**

### Rationale

The local terminal and Terraform provider need **programmatic AWS credentials**.

### Click path

1. Open **IAM**.
2. Click **Users**.
3. Click the Terraform IAM user.
4. Open **Security credentials**.
5. Scroll to **Access keys**.
6. Click **Create access key**.
7. Choose **Command Line Interface (CLI)**.
8. Check the confirmation box.
9. Click **Next**.
10. Optional description tag: `terraform-local`
11. Click **Create access key**.
12. **Copy or download immediately**:
    - **Access key ID**
    - **Secret access key**

### Important note

The **secret access key** is shown only once. If it is lost, create a new access key.

---

## Step 05 - Create a reusable local AWS CLI profile

> [!NOTE]
> **IAM user vs AWS CLI profile**  
> The IAM user is the real AWS identity.  
> The AWS CLI profile is just a **local nickname** stored on the workstation.

### Rationale

A **generic reusable profile name** is better than a project-specific one if the same AWS account may be reused later.

### Recommended profile name

`aws-personal-admin`

### Commands

~~~bash
# Create a reusable local AWS CLI profile.
aws configure --profile aws-personal-admin
~~~

When prompted, enter:
- **AWS Access Key ID** — paste the key ID
- **AWS Secret Access Key** — paste the secret key
- **Default region name** — `eu-west-3`
- **Default output format** — `json`

### Verify the profile

~~~bash
# Verify the active identity behind the new profile.
aws sts get-caller-identity --profile aws-personal-admin

# Verify that the target region is reachable and list the available AZs.
aws ec2 describe-availability-zones \
  --region eu-west-3 \
  --profile aws-personal-admin \
  --query 'AvailabilityZones[].ZoneName' \
  --output table
~~~

### Result

A working profile should return:
- the account identity via STS
- AZs such as `eu-west-3a`, `eu-west-3b`, and `eu-west-3c`

---

## Step 06 - Prepare the local Terraform variable file

### Rationale

The repository publishes a **redacted template file** while keeping the real runtime values local-only.

### Recommended file pattern

- published: `terraform.tfvars.example`
- local-only: `terraform.tfvars`

### Why this pattern is used

- `terraform.tfvars.example` documents the required local inputs and can be published for demonstrating purposes.
- the real `terraform.tfvars` stays out of Git because it contains machine-specific and secret values.
- Terraform automatically loads `terraform.tfvars`, so later commands can stay simple.

### Example published template

~~~hcl
aws_profile     = "aws-personal-admin"
my_ip_cidr      = "YOUR.PUBLIC.EGRESS.IP/32"
public_key_path = "~/.ssh/id_ed25519.pub"

db_name     = "wordpress"
db_user     = "wpadmin"
db_password = "CHANGE_ME_NOW"
~~~

### Example real local file

~~~hcl
aws_profile     = "aws-personal-admin"
my_ip_cidr      = "YOUR.ACTUAL.CURRENT.IP/32"
public_key_path = "~/.ssh/id_ed25519.pub"

db_name     = "wordpress"
db_user     = "wpadmin"
db_password = "YOUR_REAL_DB_PASSWORD"
~~~

### VPN note for `my_ip_cidr`

If a VPN is active, AWS usually sees the **VPN exit IP**, not the home ISP IP.
That means the bastion SSH rule must use the **current public egress IP** actually seen from the internet.

### Useful commands

~~~bash
# Show the current public egress IP.
curl icanhazip.com
curl https://checkip.amazonaws.com
~~~

---

## Step 07 - Create AWS Budget guardrails before the first real apply

> [!NOTE]
> **Why this exists**  
> The stack includes real AWS resources that can generate costs, especially:
> - NAT gateways
> - ALB
> - RDS
>
> A budget is a useful **warning layer**, but it is **not** a hard real-time stop button.

### What this guardrail does and does not do

What it **does** do:
- sends alerts when actual or forecasted spend crosses thresholds
- provides quick visibility into current vs budgeted costs

What it **does not** do:
- guarantee an instant stop at the exact threshold
- guarantee that all resource creation halts automatically
- replace `terraform destroy` as the real cleanup action

### Recommended settings for this project

- **Budget type:** Monthly cost budget
- **Budget amount:** `10 USD`
- **Scope:** All AWS services
- **Cost type:** Unblended costs
- **Notifications:**
  - actual cost at **50%**
  - forecasted cost at **80%**
  - actual cost at **100%**
- **Actions:** optional; notifications-only is acceptable here

### Click path

1. Open **Billing and Cost Management**.
2. Search for **Budgets**.
3. Open **AWS Budgets**.
4. Click **Create budget**.
5. Under **Budget setup**, choose **Use a template (simplified)**.
6. Under **Templates**, choose **Monthly cost budget**.
7. Leave **Billing View** empty unless a specific view is needed.
8. Budget name: `terraform-wordpress-platform-monthly-cost-guardrail`
9. Budget amount: `10 USD`
10. Scope: choose **All AWS services**.
11. Cost type: keep **Unblended costs**.
12. Click **Next**.
13. Add notifications:
    - **Actual cost** -> **50%**
    - **Forecasted cost** -> **80%**
    - **Actual cost** -> **100%**
14. Enter the recipient email address.
15. Click **Next**.
16. Review.
17. Click **Create budget**.

### What to remember later during project execution

The **real "stop button"** for this Terraform project is still:

~~~bash
terraform plan -destroy
terraform destroy
~~~

or, in the repo workflow:

~~~bash
make destroy
~~~

---

## Step 08 - Optional local plan-inspection helpers

### Rationale

These helpers are not required to make the project work, but they help inspect what Terraform is about to create in a more readable way.

### Install `jq`

~~~bash
sudo apt-get update
sudo apt-get install -y jq
~~~

### Install Graphviz

~~~bash
sudo apt-get update
sudo apt-get install -y graphviz
~~~

### Optional tools used in this project context

- **Terraform built-in graph output** via `terraform graph`
- **Rover** for local interactive plan visualization
- **Inframap** for provider-focused infrastructure graphs

### Example commands documented for later use

~~~bash
# Export a saved plan as JSON.
terraform plan -out plan.out
terraform show -json plan.out > plan.json

# Start Rover locally via Docker.
docker run --rm -it -p 9000:9000 \
  -v $(pwd)/plan.json:/src/plan.json \
  im2nguyen/rover:latest \
  -planJSONPath=plan.json

# Render Terraform dependency graphs.
terraform graph -type=plan | dot -Tsvg > terraform-plan-graph.svg
terraform graph -type=plan | dot -Tpng > terraform-plan-graph.png

# Render an Inframap graph.
inframap generate . | dot -Tpng > inframap.png
~~~

### Docker cleanup note for Rover

When Rover is run like this:

~~~bash
docker run --rm -it ...
~~~

`Ctrl+C` is normally enough in the foreground terminal session. The `--rm` flag removes the container automatically when it exits.

---

## Sources

- Terraform install / CLI basics (HashiCorp docs)
- AWS CLI install and configuration (AWS docs)
- IAM users, root-user best practices, and access keys (AWS docs)
- AWS Budgets / budget templates / budget behavior (AWS docs)
- Git ignore and local-only file handling (general Git behavior already reflected in project workflow)
