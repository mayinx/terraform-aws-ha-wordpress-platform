# 🏗️ Highly Available WordPress Platform on AWS with Terraform

### Terraform-based modular AWS infrastructure provisioning • Modular VPC • Multi-AZ networking • Dual NAT gateways • ALB + Auto Scaling web tier • Bastion access • Private RDS • Evidence-backed apply / destroy validation

DevOps / Infrastructure-as-Code project demonstrating how to provision a **highly available WordPress platform on AWS** with **Terraform**, using a **custom VPC**, **public/private multi-AZ subnet layout**, **dual NAT gateways**, an **Application Load Balancer**, an **Auto Scaling web tier**, a **bastion host**, and a **private Multi-AZ RDS database**.

> **Implementation note:** This project focuses on **declarative infrastructure provisioning, validation, and clean teardown**.  
> The stack was successfully created, validated through AWS console evidence and browser checks/screenshots, and then destroyed again to avoid unnecessary cloud costs.

---

## 🎯 What this project demonstrates

✅ **Modular Terraform structure** with separate `network`, `database`, `web`, and `bastion` modules  
✅ **Custom VPC** instead of the default VPC, **in order to isolate the platform**, control the addressing scheme explicitly, and keep the infrastructure reproducible  
✅ **Custom CIDR ranges** for the **VPC and all 4 subnets**, **so the network layout is intentional, explicit, and easy to reason about instead of relying on AWS defaults**  
✅ **Public/private subnet design across 2 Availability Zones** for separation of concerns and higher availability  
✅ **Public Application Load Balancer** as the single HTTP entrypoint for the platform  
✅ **Auto Scaling Group** for the WordPress EC2 web servers in the private subnets  
✅ **One NAT Gateway per public subnet**, **matching the high-availability requirement** instead of collapsing private-subnet outbound traffic behind a single NAT gateway  
✅ **Private RDS MySQL deployment** with a DB subnet group and VPC security controls, **so the database is not internet-facing**  
✅ **Restricted bastion host access** for controlled SSH entry into the environment, **instead of exposing the private web tier directly**  
✅ **Local AWS CLI profile + Terraform workflow** for `plan` / `apply` / `destroy`  
✅ **Cost-aware validation workflow** with AWS Budgets, evidence capture, and immediate teardown

---

## 🧱 Tech Stack

🧱 **Terraform** | ☁️ **AWS** | 🌍 **VPC** | 🐧 **Ubuntu EC2** | 🗄️ **RDS MySQL** | ⚖️ **ALB** | 📈 **Auto Scaling** | 🔐 **IAM** | 🛡️ **Security Groups** | 🧰 **AWS CLI** | 🛠️ **Makefile**

---

## 🏗️ Architecture (high level)

~~~text
Internet
   |
   | HTTP :80
   v
+------------------------------------------------------------------+
| Application Load Balancer                                        |
| public subnets (2 AZs) | public entrypoint | DNS: <alb_dns_name> |
+------------------------------------------------------------------+
                                  |
                                  | HTTP :80
                                  v
                     +------------------------------------------+
                     | Auto Scaling Group                       |
                     | 2 WordPress EC2 instances                |
                     | private subnets (2 AZs) | eu-west-3a/b   |
                     +------------------------------------------+
                                          |
                                          | MySQL :3306
                                          v
                     +------------------------------------------+
                     | RDS MySQL (Multi-AZ)                     |
                     | private DB subnet group                  |
                     +------------------------------------------+

Admin / operator
   |
   | SSH :22
   v
+------------------------------------------------------------------+
| Bastion host                                                     |
| public subnet | public IP | restricted by security group         |
+------------------------------------------------------------------+

+------------------------------------------------------------------+
| Custom VPC                                                       |
| CIDR: 10.0.0.0/16                                                |
| - 2 public subnets:                                              |
|   - public-1  10.0.1.0/24  -> IGW                                |
|   - public-2  10.0.2.0/24  -> IGW                                |
| - 2 private subnets:                                             |
|   - private-1 10.0.11.0/24 -> NAT-1                              |
|   - private-2 10.0.12.0/24 -> NAT-2                              |
| - 1 Internet Gateway                                             |
| - 2 NAT Gateways                                                 |
+------------------------------------------------------------------+
~~~

Notes:
- The **ALB** is the **public HTTP entrypoint** for the application.
- he **WordPress web tier / EC2 instances** run in **private subnets** and are **not directly public**.
- The **RDS database** is also **private** and only reachable from inside the VPC.
- The **bastion host** is the **controlled SSH entrypoint** for administrative access.
- The **private subnets use NAT gateways for outbound internet access** without becoming directly public.
---


## 📦 Infrastructure Overview

This repository provisions an AWS-based WordPress platform as code.

The final deployed stack includes:

- **1 custom VPC** in `eu-west-3`
- **2 public subnets** and **2 private subnets** across `eu-west-3a` and `eu-west-3b`
- **1 Internet Gateway**
- **2 NAT Gateways**
- **1 bastion EC2 instance**
- **1 ALB** with HTTP listener and target group
- **1 Auto Scaling Group** for the WordPress web tier
- **1 Multi-AZ RDS MySQL instance**
- Terraform outputs for the ALB DNS name, DB endpoint, subnet IDs, security groups, and VPC ID

The deployment was validated through:
- successful Terraform `plan`, `apply`, and `destroy`
- AWS Console screenshots across VPC / EC2 / RDS / Budgets / Tag Editor (see `docs/evidence/aws/...`)
- browser-based WordPress proof via the ALB DNS name (see `docs/evidence/wp/...`)

---

## 🔄 Implementation Sequence (high level)

1. **AWS access and guardrails prepared**  
   IAM user access, local AWS CLI profile, and AWS Budget alerts were configured first.

2. **Terraform project scaffolded**  
   The repository structure, module layout, variable flow, and Make targets were prepared before real infrastructure work began.

3. **Core infrastructure modules implemented**  
   The network, database, web, and bastion layers were added step by step and validated incrementally with Terraform plans.

4. **Readable plan inspection added**  
   Saved plans, grouped resource summaries, and optional graph/visualization helpers were used to inspect what Terraform was about to create.

5. **Full stack deployed and validated**  
   The AWS stack was applied successfully, inspected in the console, and verified in the browser through the ALB-hosted WordPress flow.

6. **Evidence captured and stack destroyed**  
   AWS Console and browser proof were collected, then the full stack was destroyed again to end the cost-generating phase.

---

## ✅ DevOps / IaC Scope Implemented

- Created a **modular Terraform layout** with dedicated **child modules** for:
  - **`network`**
  - **`database`**
  - **`web`**
  - **`bastion`**
- Configured **AWS CLI access** for **local Terraform execution**
- Defined **custom CIDR ranges** for the **VPC and all 4 subnets**, **because the project uses a dedicated custom VPC instead of AWS defaults**
- Used Terraform **data sources** to select the target **Availability Zones** and **AMI**
- Provisioned the **AWS network foundation declaratively**
- Added a **private Multi-AZ RDS layer**
- Added a **public ALB** with **target group** and **HTTP listener**
- Added a **launch template** and **Auto Scaling Group** for the web tier
- **Bootstrapped WordPress automatically** through EC2 `user_data`
- Added a **restricted bastion host** and **SSH key-pair provisioning**
- Added a **Makefile** for the common **Terraform lifecycle + plan inspection commands**
- Captured **creation, runtime, and cleanup evidence**
- **Destroyed the entire stack** after validation

---

## 📁 Project Structure

~~~bash
.
├── docs/
│   ├── evidence/
│   │   ├── aws/                         # AWS Console screenshots for budgets, VPC, subnets, NAT, RDS, ALB, ASG, instances, target health, and post-destroy proof
│   │   └── wp/                          # Browser screenshots for WordPress load, install wizard, login screen, and rendered sample page
│   ├── IMPLEMENTATION.md                # Full build diary with rationale, commands, observations, and evidence links
│   ├── RUNBOOK.md                       # Short happy-path rerun guide using Make targets as primary entrypoints
│   ├── SETUP.md                         # Local setup guide for Terraform, AWS CLI, IAM user, profile, and AWS budget guardrails
│   └── _private/                        # Local-only notes excluded from the public documentation flow
├── Makefile                             # Human-friendly wrappers for init / validate / plan / apply / destroy / graph helpers
├── main.tf                              # Root module wiring for network, database, bastion, and web
├── providers.tf                         # AWS provider configuration and shared default tags
├── versions.tf                          # Terraform and provider version requirements
├── variables.tf                         # Root input variables for profile, region, DB settings, and instance sizes
├── outputs.tf                           # Root outputs for ALB, DB, VPC, subnets, and security groups
├── terraform.tfvars.example             # Redacted example for local-only runtime values
├── modules/
│   ├── network/                         # VPC, subnets, route tables, Internet Gateway, NAT Gateways
│   ├── database/                        # RDS subnet group, DB security group, Multi-AZ RDS instance
│   ├── web/                             # ALB, listener, target group, launch template, Auto Scaling Group
│   └── bastion/                         # Bastion EC2 instance, SSH key pair, restricted bastion security group
└── user_data/
    └── wordpress.sh.tftpl               # Bootstrap template for package install, WordPress download, config generation, and Apache startup
~~~

**The final solution centers around 6 main building blocks:**

- **(1) the root Terraform composition layer** (`main.tf`, `providers.tf`, `variables.tf`, `outputs.tf`)
- **(2) the network module** (`modules/network`)
- **(3) the database module** (`modules/database`)
- **(4) the web module** (`modules/web`)
- **(5) the bastion module** (`modules/bastion`)
- **(6) the documentation + evidence layer** (`docs/`)

---

## ✅ What works

- Terraform initializes and validates successfully
- The saved plan shows the intended AWS resource set before apply
- The stack deploys successfully into AWS with:
  - custom VPC
  - 4 subnets
  - dual NAT gateways
  - bastion host
  - ALB
  - Auto Scaling Group
  - Multi-AZ RDS
- Terraform outputs return the expected infrastructure identifiers after apply
- The WordPress site is reachable through the ALB DNS name
- The WordPress installation wizard loads successfully in the browser
- AWS Console evidence exists for both creation and destruction phases
- Terraform destroys the full stack successfully after validation

---

## 🔧 Key Engineering Decisions

This project includes a few practical engineering choices worth calling out:

- **Custom VPC instead of the default VPC**  
  The infrastructure is provisioned into a dedicated VPC with explicitly chosen CIDR ranges instead of reusing the AWS default VPC. This makes the network layout reproducible and easier to reason about.

- **Dual NAT design**  
  To provide high-availability, the project uses **one NAT Gateway per public subnet**, instead of collapsing everything behind a single NAT gateway.

- **Private application + database placement**  
  The web tier and RDS layer run in private subnets, while the ALB and bastion remain public-facing. This keeps the public attack surface smaller and helps structuring the traffic flow: internet -> ALB, operator -> bastion, app -> database

- **Ephemeral cost-aware validation**  
  The stack is intentionally treated as short-lived cloud infrastructure to keep costs in check: apply, validate, capture evidence, destroy.

---

## 🧾 Evidence Overview

### Overview

**Evidence captured in `docs/evidence/...` during validation includes:**

- AWS Budgets overview before and after the live validation cycle
- Tag Editor search results after apply and after destroy
- VPC / subnet / NAT gateway screenshots
- RDS database overview and details screenshots
- ALB, target group, Auto Scaling Group, and EC2 instance screenshots
- browser-based WordPress screenshots:
  - initial load
  - installation wizard
  - finished installation
  - login screen
  - rendered sample page

**Representative evidence files captured during validation:**

- `docs/evidence/aws/03-aws-te-resoucre-search-result-after-apply.png`
- `docs/evidence/aws/18-aws-ec2-target-group-targets.png`
- `docs/evidence/aws/21-aws-te-resoucre-search-result-after-destroy.png`
- `docs/evidence/wp/01-wp-successfully-loaded-wp-site.png`
- `docs/evidence/wp/05-wp-successfully-rendered-sample-page.png`

**Additional terminal proof available for the documentation layer includes:**

- successful `make apply`
- successful Terraform outputs after apply
- successful `terraform plan -destroy`
- successful `make destroy`

## 📸 Evidence Highlights

### 1) Provisioned resoucres on AWS after `terraform apply` 

![AWS Tag Editor search result after destroy](docs/evidence/aws/03-aws-te-resoucre-search-result-after-apply.png)

*Post-apply proof showing that the aws stack was provisioend by terraform (obtained via a tag-editor search for ressoucres carrying the project tag `wordpress-platform`*

### 2) Public WordPress page rendered successfully

![Public WordPress sample page rendered through the ALB](docs/evidence/wp/05-wp-successfully-rendered-sample-page.png)

*Public proof that the stack was reachable through the load balancer and rendered application content successfully.*

### 3) Application Load Balancer created and exposed as the public entrypoint

![AWS EC2 Load Balancer details](docs/evidence/aws/11-aws-ec2-lb-wp-alb-details.png)

*ALB details showing the public entrypoint used to reach the WordPress platform.*

### 4) Auto Scaling Group created for the private web tier

![AWS Auto Scaling Group details](docs/evidence/aws/13-aws-ec2-asg-wp-asg-details.png)

*ASG details proving that the web tier was deployed as an Auto Scaling Group instead of a single standalone EC2 instance.*

### 5) Target group targets registered behind the ALB

![AWS target group targets](docs/evidence/aws/18-aws-ec2-target-group-targets.png)

*Target-group proof showing that the web instances were registered behind the ALB and participated in request handling.*

### 6) Resource cleanup verified after destroy

TODO: Provide current screenshot showing no hits - once AWS refreshed this  

![AWS Tag Editor search result after destroy](docs/evidence/aws/21-aws-te-resoucre-search-result-after-destroy.png)

*Post-destroy proof showing that the AWS stack was torn down again instead of being left running.*

---

## 🧠 Runbook + Setup + Implementation Log

**Setup guide**  
For the local setup path, IAM user creation, CLI profile configuration, AWS Budgets guardrail, and tooling prerequisites:
- [docs/SETUP.md](docs/SETUP.md)

**Runbook**  
For the short happy-path rerun guide based on Make targets:
- [docs/RUNBOOK.md](docs/RUNBOOK.md)

**Implementation log**  
For the detailed build diary, rationale, Terraform + AWS concepts, decisions, evidence mapping, and cleanup flow:
- [docs/IMPLEMENTATION.md](docs/IMPLEMENTATION.md)

---

## APPENDIX: Exercise Goal (summary)

**Scenario:**  
Provision a WordPress platform on AWS with Terraform using a modular IaC structure and validate that the deployment works.

**Core requirements covered by the project:**
- AWS region `eu-west-3`
- 1 VPC
- 4 subnets
- NAT gateway in each public subnet
- WordPress web tier on `t2.micro` instances
- Auto Scaling Group with min `1` / max `2`
- automatic infrastructure lookup where relevant (for example Availability Zones / AMI)
- `aws_db_instance` database layer on `db.t3.micro`
- ALB for public HTTP access
- bastion host
- modular Terraform code
- no hardcoded secrets in committed source

**Expected proof / deliverables covered here:**
- modular Terraform repository
- successful plan / apply / destroy flow
- AWS Console validation screenshots
- browser-based WordPress proof
- reproducible documentation in `README.md`, `docs/SETUP.md`, `docs/RUNBOOK.md`, and `docs/IMPLEMENTATION.md`
