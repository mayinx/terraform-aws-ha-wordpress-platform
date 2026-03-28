# 🧱 Implementation Log: Highly Available WordPress Platform on AWS with Terraform

> ## 👤 About
> This document is the **implementation log and detailed build diary** for the Terraform-based AWS WordPress platform project.  
> It records the full implementation path, including the setup decisions that mattered, the module-by-module build sequence, the reasoning behind the architecture, the validation steps, and the captured evidence.  
> For the shorter operational command checklist, see: **[docs/RUNBOOK.md](RUNBOOK.md)**.  
> For the local setup path, IAM user creation, AWS CLI profile configuration, and AWS Budget guardrails, see: **[docs/SETUP.md](SETUP.md)**.

---
 
## 📌 Index (top-level)

- [**Purpose / Goal**](#purpose--goal)
- [**Definition of done**](#definition-of-done)
- [**Preconditions**](#preconditions)
- [**Step 01 - Translate the exercise goal into a concrete target architecture**](#step-01---translate-the-exercise-goal-into-a-concrete-target-architecture)
- [**Step 02 - Scaffold the Terraform project structure and implement the base configuration**](#step-02---scaffold-the-terraform-project-structure-and-implement-the-nase-configuration)
- [**Step 03 - Implement the network module**](#step-03---implement-the-network-module)
- [**Step 04 - Implement the database module**](#step-04---implement-the-database-module)
- [**Step 05 - Implement the web tier module**](#step-05---implement-the-web-tier-module)
- [**Step 06 - Implement the bastion module**](#step-06---implement-the-bastion-module)
- [**Step 07 - Add a repeatable Terraform workflow with Make targets and plan inspection**](#step-07---add-a-repeatable-terraform-workflow-with-make-targets-and-plan-inspection)
- [**Step 08 - Validate the full plan before the first real apply**](#step-08---validate-the-full-plan-before-the-first-real-apply)
- [**Step 09 - Apply the full stack and verify it in AWS + browser**](#step-09---apply-the-full-stack-and-verify-it-in-aws--browser)
- [**Step 10 - Destroy the stack and verify cleanup**](#step-10---destroy-the-stack-and-verify-cleanup)
- [**Key engineering decisions**](#key-engineering-decisions)
- [**Final project structure**](#final-project-structure)
- [**Sources**](#sources)

---

## Purpose / Goal

- Provision a **highly available WordPress platform on AWS** with Terraform.
- Implement the infrastructure in a **modular IaC structure** that is readable, reusable, and easy to rerun.
- Validate the deployment through a **plan -> apply -> browser proof -> destroy** lifecycle.
- Capture evidence that proves:
  - The complete infrastructure was **created** via Terraform 
  - The deployed platform **actually worked** in the browser (Wordpress reachable)
  - The commplete infrastructure was **destoyed** again via Terraform after validation  



> [!NOTE]
> **Terraform**  
> Terraform is an **Infrastructure as Code (IaC) tool** that allows the declarative description + creation of infrastructure via configuration files - instead of creating that infrastructure manually in a cloud console.  
> Terrafdorm uses **providers** to communicate with external Cloud Provider APIs such as AWS in order to create, update, or destroy infrastructure so that the real environment matches the declared configuration.  
> In this project, Terraform is the **control layer for the AWS infrastructure**: 
> - it provisions and manages the AWS resources such as the VPC, subnets, NAT gateways, security groups, ALB, EC2 instances, Auto Scaling Group, and RDS database
> - and it deploys the WordPress platform onto that infrastructure

> [!NOTE]
> **Terraform + Kubernetes**  
> Though this poroject doesn't utilize Kubernetes (the WordPress platform is deployed directly on the Terraform-managed AWS infrastructure), it's worth noting the role of Terraform when used in combination with Kubernetes: 
> In many projects, Terraform is used to create the infrastructure that Kubernetes later runs on. So Terraform and Kubernetes can play nicely together, but solve different problems:
> - **Terraform** provisions and configures infrastructure or platform resources 
> - **Kubernetes** runs and orchestrates containerized applications on a cluster. 

## Definition of done

The project is considered done when the following conditions are met:

- A modular Terraform repository exists with dedicated child modules for:
  - `network`
  - `database`
  - `web`
  - `bastion`
- The target architecture is implemented in `eu-west-3`.
- The Terraform plan shows the required infrastructure.
- A full `apply` succeeds.
- The AWS Console shows the created infrastructure.
- WordPress is reachable via the ALB DNS name in a browser.
- The stack is destroyed again successfully.
- The repository contains a README, setup guide, implementation log, runbook, and evidence inventory.

## Preconditions

Completed beforehand:
- Terraform installed locally
- AWS CLI installed locally
- IAM user created
- CLI access keys created
- reusable AWS CLI profile configured
- local `terraform.tfvars` prepared
- AWS Budget guardrail created

See **[docs/SETUP.md](SETUP.md)** for that preparation path.

---

## Step 01 - Translate the exercise goal into a concrete target architecture

### Rationale

Before writing Terraform code, the exercise requirements must be translated into a **buildable AWS target shape**.

**The final implementation target:**
- 1 custom VPC
- 2 public subnets
- 2 private subnets
- 2 NAT gateways
- public ALB
- private WordPress web tier on EC2
- Auto Scaling Group with min 1 / max 2
- private RDS MySQL layer
- bastion host for controlled SSH entry

> [!NOTE]
> **What makes this platform “highly available”:**  
> - A deployment across **2 Availability Zones**
> - **2 public + 2 private subnets**
> - **one NAT gateway per public subnet**
> - a **public ALB** as the HTTP entrypoint
> - an **Auto Scaling Group** for the web tier
> - a **Multi-AZ RDS** database layer

### Result

A clear target architecture exists as base for the further implementation, which prevents random resource creation.

---

## Step 02 - Scaffold the Terraform project structure and implement the base configuration

### Rationale

A clean scaffold makes the Terraform configuration easier to understand and extend incrementally. The project was therefore split into:
- **1.** a **root module** for wiring
- **2.** dedicated **child modules** for each major infrastructure concern:
    - `network` 
    - `bastion` 
    - `database` 
    - `web`
- **3.** a separate **`user_data/` directory** for EC2 bootstrap logic (Wordpress setup)

### Initial scaffold commands

~~~bash
# Create the module directories and the separate user_data directory.
mkdir -p modules/network modules/web modules/database modules/bastion user_data

# Create the root Terraform files used to wire the full project together.
touch main.tf providers.tf versions.tf variables.tf outputs.tf terraform.tfvars .gitignore

# Create the standard Terraform files for the network child module.
touch modules/network/{main.tf,variables.tf,outputs.tf}

# Create the standard Terraform files for the web child module.
touch modules/web/{main.tf,variables.tf,outputs.tf}

# Create the standard Terraform files for the database child module.
touch modules/database/{main.tf,variables.tf,outputs.tf}

# Create the standard Terraform files for the bastion child module.
touch modules/bastion/{main.tf,variables.tf,outputs.tf}
~~~

### Scaffolded project structure

The initial scaffold created the following project shape:

~~~bash
.
├── main.tf                 # root module wiring
├── providers.tf            # AWS provider configuration
├── versions.tf             # Terraform / provider version requirements
├── variables.tf            # root input variables
├── outputs.tf              # root outputs for verification and module hand-off
├── .gitignore              # local-only / generated file exclusions
├── terraform.tfvars        # local real values (ignored)
├── modules/
│   ├── network/            # VPC, subnets, routing, NAT
│   ├── database/           # DB subnet group, DB SG, RDS
│   ├── web/                # ALB, launch template, ASG, web SGs
│   └── bastion/            # bastion EC2, key pair, bastion SG
└── user_data/
    └── wordpress.sh.tftpl  # EC2 bootstrap template for WordPress setup
~~~

This scaffold did not yet provision anything by itself.  
It created the file and module structure that was then filled incrementally with the actual Terraform configuration.

### Terraform structure rationale

The created structure follows common Terraform project conventions:
- a **root module** for provider setup, shared inputs/outputs, and module wiring
- **child modules** for separate infrastructure concerns
- a separate **template file** for EC2 bootstrap logic that would otherwise clutter the HCL files

**How the created main Terraform files work together:**  

1. The **root files** define the overall project interface and wiring:
- **`main.tf`** wires the child modules together.
- **`providers.tf`** defines how Terraform talks to AWS and keeps provider config separate.
- **`versions.tf`** declares the Terraform / provider requirements
- **`variables.tf`** defines the configurable inputs of the project 
- **`outputs.tf`** publishes important values such as VPC ID, subnet IDs, ALB DNS name, bastion public IP, and DB endpoint for later verification

2. The **child modules** define the actual AWS resources for each infrastructure concern and separate infrastructure responsibilities:
- **`modules/network`** = networking foundation
- **`modules/database`** = RDS layer
- **`modules/web`** = ALB + launch template + Auto Scaling Group
- **`modules/bastion`** = administrative SSH entrypoint

3. **`user_data/wordpress.sh.tftpl`** defines the EC2 bootstrap logic and keeps this out of the main HCL files.

**Source direction:** 

This structure is based on standard Terraform module, provider, and variable patterns, supported by the referenced sources listed at the end of this document.

> [!NOTE]
> **Terraform AWS provider**  
> The **Terraform AWS provider** is the plugin Terraform uses to talk to AWS APIs.  
> It is what makes resource blocks such as `aws_vpc`, `aws_subnet`, `aws_db_instance`, and `aws_lb` meaningful to Terraform.
>
> In this project, that provider setup is split across two root files:
> - **`versions.tf`** declares the dependency on **`hashicorp/aws`** via `required_providers`
> - **`providers.tf`** configures how Terraform should use that provider, for example:
>   - which **AWS region** to target
>   - which **local AWS CLI profile** to use

> [!NOTE]
> **Terraform outputs**  
> Terraform outputs are named values that Terraform prints after `apply` and makes available at the root level.  
> In this project, outputs are used to expose the most important verification values, such as the **ALB DNS name**, **bastion public IP**, **DB endpoint**, **subnet IDs**, and **VPC ID**.

### Implement Terraform Base Configuration

Next step is to fill the still empty Terraform structure with the actual Terraform configuration needed for the target AWS platform.

**This includes:**
- The **root files** to define the overall project interface and wiring
- The **module files** to define the concrete AWS resources for each infrastructure concern
- The **template file** under `user_data/` to define the EC2 bootstrap logic for WordPress installation

**The implementation follows a combination of:**
- the exercise requirements
- standard Terraform module / provider / variable patterns
- standard AWS resource patterns
- and the EC2 user-data / WordPress installation approach documented in the referenced sources

**Important configured values (examples):**

- **`region = eu-west-3`** (in the root Terraform configuration `variables.tf`)  
  This fixes the deployment target to Paris and therefore influences AZ selection, console inspection, and the resulting public endpoints.

- **`project_name` and `environment`** (also in `variables.tf`)  
  These values shape names and tags across the stack and make AWS Console filtering and Tag Editor searches easier later on.

- **`aws_profile`** (in the root AWS provider configuration in `providers.tf` 
  This tells Terraform which local AWS CLI profile to reuse for AWS API access.

- **`my_ip_cidr`** and **`public_key_path`** (also in `variables.tf`)  
  These values control bastion SSH access and the SSH public key uploaded into AWS.

- **Custom CIDR ranges** in the network module  
  The project explicitly defines:
  - VPC CIDR: `10.0.0.0/16`
  - public subnet 1: `10.0.1.0/24`
  - public subnet 2: `10.0.2.0/24`
  - private subnet 1: `10.0.11.0/24`
  - private subnet 2: `10.0.12.0/24`  
  These ranges were chosen deliberately in Terraform rather than inherited from the AWS default VPC. This way the network layout stays explicit, reproducible, and easy to reason about during both implementation and review.

- **`db_name`, `db_user`, `db_password`** in the root variables / database wiring  
  These values define the database connection to be used by WordPress during bootstrap and runtime.

- **`web_instance_type` and `bastion_instance_type`** in `variables.tf`  
  These influence both resource sizing and cost.

- **Dynamic AMI and AZ lookup** in the module configuration  
  The project does not hardcode a specific Ubuntu image ID or a manually typed list of Availability Zones.  
  Instead, Terraform **data sources** are used to look up:
  - the currently available target **Availability Zones (AZs)** in `eu-west-3`
  - a current matching Ubuntu **AMI (Amazon Machine Image)** for the EC2 instances  
  This makes the configuration less brittle and more reusable, because it does not depend on one frozen AMI ID or one manually maintained AZ list.  

- **`user_data_template_path`** in the web module wiring  
  This links the launch template to the external EC2 bootstrap template file for WordPress setup.

For the **source references** behind these patterns, see the grouped **Sources** section at the end of this document.

> [!NOTE]
> **AMI and AZ**  
> An **AMI (Amazon Machine Image)** is the machine image used to launch an EC2 instance.  
> An **AZ (Availability Zone)** is one physically separate AWS datacenter location within a region such as `eu-west-3`.  
> In this project, both were discovered dynamically instead of being hardcoded.

### Result

A predictable Terraform layout exists as base for the definition of the real resources.

---

## Step 03 - Implement the network module

### Rationale

Serving as the base for everything else, Networking must be defined first. The ALB, bastion, web tier, and database all rely on a VPC and the correct subnet layout.

> [!NOTE]
> **VPC**  
> A **VPC (Virtual Private Cloud)** is the private AWS network boundary for this project: The VPC is the top-level network container that holds subnets, route tables, gateways, and private IP ranges.

> [!NOTE]
> **Multi-AZ networking**  
> “Multi-AZ networking” refers to the distribution of key infrastructure components across more than one Availability Zone.  
> In our case the network spans **eu-west-3a** and **eu-west-3b** so the design is not tied to a single AZ.

> [!NOTE]
> **NAT + NAT gateways**  
> **NAT** stands for **Network Address Translation**. A **NAT gateway** lets resources in a **private subnet** reach the internet **outbound** without becoming directly reachable **inbound** from the internet.  
> In this project, the private WordPress instances need outbound internet access for bootstrap actions such as package installation and downloading WordPress.

> [!NOTE]
> **Route table**  
> A **route table** defines where network traffic from a subnet should be sent.  
> In this project, the public route table sends internet-bound traffic to the **Internet Gateway**, while each private route table sends outbound internet traffic to its corresponding **NAT gateway**.

> [!NOTE]
> **Security group**  
> A **security group** is a stateful virtual firewall attached to AWS resources such as EC2 instances, ALBs, and RDS databases.  
> In this project, security groups define which traffic is allowed between the internet, the ALB, the bastion host, the WordPress EC2 instances, and the database.

> [!NOTE]
> **Elastic IP (EIP)**  
> An **Elastic IP** is a static public IPv4 address allocated in AWS.  
> In this project, an Elastic IP was attached to each NAT gateway so the private subnets could use stable outbound internet access through those NAT gateways.

### What the network module creates

- VPC
- Internet Gateway
- 2 public subnets
- 2 private subnets
- 2 Elastic IPs
- 2 NAT gateways
- route tables
- route table associations

### What we defined ourselves

In the Terraform config, the following network ranges were chosen explicitly:

- VPC CIDR: `10.0.0.0/16`
- Public subnet 1: `10.0.1.0/24`
- Public subnet 2: `10.0.2.0/24`
- Private subnet 1: `10.0.11.0/24`
- Private subnet 2: `10.0.12.0/24`

So:
- the **CIDR blocks / subnet masks were defined in Terraform**
- AWS did **not** invent those ranges for this custom VPC

### What AWS assigns automatically

Inside those subnet ranges, the actual resource IPs are assigned by AWS automatically unless a fixed IP is explicitly requested.

So the pattern is:
- **we define the subnet ranges**
- **AWS assigns concrete IPs inside those ranges**

### Custom CIDR range rationale

The project uses a **dedicated custom VPC** instead of the AWS default VPC, because the layout should be reproducible, explicit, and easy to reason about.  
Choosing the CIDR ranges explicitly makes it much easier to understand the network design.

### NAT gateways rationale

The project uses **one NAT gateway per public subnet**, **because the exercise explicitly required that design** and because it avoids turning private-subnet outbound access into a single-AZ dependency.

### Commands used during validation

~~~bash
# Format all Terraform files recursively so the configuration stays readable and consistent.
make fmt

# Initialize the working directory, providers, and module metadata.
make init

# Check whether the current Terraform configuration is structurally valid.
make validate

# Save the current plan to a reusable plan file instead of only printing it to the terminal.
make plan-save

# Print a compact readable summary of which resources Terraform wants to create/update/delete.
make plan-summary

# Print grouped counts of planned resource types to sanity-check the overall stack shape.
make plan-counts
~~~

### Result

The saved Terraform plan showed the expected network foundation, including:
- 1 VPC
- 4 subnets
- 2 NAT gateways
- 2 EIPs
- 3 route tables
- 4 route table associations

Representative pre-apply terminal proof included grouped plan counts such as:
- `2x aws_eip`
- `2x aws_nat_gateway`
- `4x aws_subnet`
- `1x aws_vpc`

---

## Step 04 - Implement the database module

### Rationale

WordPress needs a relational database backend.
The exercise explicitly required an `aws_db_instance` on `db.t3.micro`, so the database layer had to be implemented as a real AWS RDS resource.

> [!NOTE]
> **RDS**  
> **Amazon RDS** is AWS’s managed relational database service.  
> In this project, RDS provides the MySQL database backend for WordPress so that the database does not need to be installed and operated manually on an EC2 instance.

> [!NOTE]
> **Private Multi-AZ RDS layer**  
> In this project, the database is an **RDS MySQL instance** that is **not publicly accessible** and is placed behind a **DB subnet group** spanning the private subnets in two Availability Zones.  
> “Multi-AZ” means the managed database service is configured for higher availability across more than one Availability Zone.

### What the database module creates

- DB subnet group across the 2 private subnets
- database security group
- private Multi-AZ RDS MySQL instance

### Why the DB is private

The database should not be internet-facing.  
It only needs to be reachable from inside the VPC, specifically from the application tier.

### Result

The Terraform plan then expanded from a network-only plan into a network + database plan, adding:
- `aws_db_instance`
- `aws_db_subnet_group`
- a DB security group

---

## Step 05 - Implement the web tier module

### Rationale

The exercise requires a WordPress web tier on EC2, public HTTP access, and an Auto Scaling Group behind an ALB. That is the core application path of the whole platform.

The web module depends on the earlier **network** and **database** layers: it needs the VPC ID, public/private subnet IDs, and the database endpoint before the ALB, launch template, and Auto Scaling Group can be configured correctly.

> [!NOTE]
> **ALB**  
> An **ALB (Application Load Balancer)** is the public HTTP entrypoint of the platform.  
> It receives incoming HTTP requests and forwards them to healthy application targets behind it.

> [!NOTE]
> **Target group**  
> A **target group** is the set of application targets the ALB forwards traffic to.  
> In this project, the WordPress EC2 instances from the Auto Scaling Group are the targets.

> [!NOTE]
> **HTTP listener**  
> A **listener** is the ALB component that listens on a port / protocol combination and decides what to do with incoming traffic.  
> Here, the ALB has an **HTTP listener on port 80** that forwards traffic to the WordPress target group.

> [!NOTE]
> **Launch template**  
> A **launch template** is the reusable EC2 instance blueprint for the Auto Scaling Group.  
> It defines things such as the AMI, instance type, security groups, and bootstrap `user_data`.

> [!NOTE]
> **Auto Scaling Group**  
> An **Auto Scaling Group (ASG)** manages a fleet of EC2 instances and tries to keep the desired number running.  
> In this project, the ASG manages the WordPress web instances with **min 1 / max 2 / desired 2**.

> [!NOTE]
> **EC2 `user_data`**  
> `user_data` is a startup script that EC2 runs during instance initialization.  
> Here we use it to install Apache/PHP, download WordPress, generate `wp-config.php`, and prepare the application automatically (see `user_data/wordpress.sh.tftpl`).

### Resources created by the web module

The web module creates the following main resources:

- dynamic Ubuntu AMI lookup
- ALB security group
- Web security group
- ALB
- Target group
- HTTP listener
- launch template
- Auto Scaling Group
- WordPress bootstrap via `user_data/wordpress.sh.tftpl` 

### EC2 Wordpress Bootstrap approach (`user_data/wordpress.sh.tftpl`) 

The EC2 bootstrap logic in `user_data/wordpress.sh.tftpl` combines:

- the standard **AWS EC2 user-data pattern** for launch-time instance configuration
- the conventional **WordPress installation flow on Linux**
- the standard **`wp-config.php` database / auth-key configuration model**

Further details are available in the bootstrap script itself and in the grouped Sources section at the end of this document.

### Terraform data sources

Terraform **data sources** were used to select:
- the target **Availability Zones**
- the current Ubuntu **AMI**

This was done **so the configuration can discover environment details dynamically instead of hardcoding brittle values**.
The project therefore stays more reusable and less tied to one frozen AMI ID or one manually typed AZ list.

### Private web tier

The web instances run in **private subnets**, while the ALB remains public.  
This keeps the public attack surface smaller: the internet reaches the ALB, not the EC2 instances directly.

### Result

The full plan now showed the web layer on top of the network + DB layer, including:
- `aws_lb`
- `aws_lb_listener`
- `aws_lb_target_group`
- `aws_launch_template`
- `aws_autoscaling_group`
- web / ALB security groups

---

## Step 06 - Implement the bastion module

### Rationale

The web instances run in private subnets, so a controlled administrative entrypoint was needed.

The bastion module depends on the **network** layer because the bastion host must be placed into a public subnet inside the custom VPC and protected by its own security group.

> [!NOTE]
> **Bastion access**  
> A **bastion host** is a small public entrypoint used for controlled administrative SSH access into an otherwise private environment.  
> In this project, the operator can SSH to the bastion first and then reach private resources from inside the VPC.
> The bastion is not left open to the whole internet on SSH.  
> Instead, its security group only allows SSH from the specific `my_ip_cidr` value, i.e. the current trusted public egress IP.

> [!NOTE]
> **SSH key-pair provisioning**  
> The project creates an AWS **key pair resource** from the local public SSH key so the bastion instance can be accessed without passwords.

### What the bastion module creates

- AWS key pair from the local public key
- bastion security group
- bastion EC2 instance in a public subnet

### Why the bastion exists

The bastion makes the SSH path explicit and controlled:
- laptop -> bastion (public SSH)
- bastion -> private web instances (SSH allowed from bastion SG)

### Result

The full plan now showed the complete core stack, including:
- bastion instance
- bastion key pair
- bastion security group
- SSH ingress from bastion SG to the web SG

Representative plan-summary output at that point included:
- `create aws_instance.this`
- `create aws_key_pair.this`
- `create aws_security_group.bastion`
- plus the earlier network, DB, and web resources

---

## Step 07 - Add a repeatable Terraform workflow with Make targets and plan inspection

### Rationale

We add a Makefile, becasue Terraform lifecycle commands repeat constantly during implementation. A Makefile keeps the happy-path commands short, consistent, and easier to document.

This includes Make targets for plan summaries and graphs, to make the raw Terraform plan easier "to digest" - and easier to answer:
- **what will be created?**
- **how many resources of each type?**
- **what does the plan dependency graph look like?**

### Main targets used in this project

- `make fmt`
- `make init`
- `make validate`
- `make plan-save`
- `make plan-summary`
- `make plan-counts`
- `make plan-json`
- `make graph-plan-svg`
- `make graph-plan-png`
- `make inframap-png`
- `make apply`
- `make output`
- `make destroy`

### Result

The Makefile provides the main project command entrypoints, while the underlying Terraform commands remain documented here for traceability.

---

## Step 08 - Validate the full plan before the first real apply

### Rationale

Before the first real `apply`, the Terraform plan needs to be checkedverified carefully to ensure that the complete intended stack appears in the plan and to reduce avoidable (and potentially costly) mistakes:  

### Commands

~~~bash
make fmt
make init
make validate
make plan-save
make plan-summary
make plan-counts
~~~

### Result

The final pre-apply plan showed the complete resource set across:
- network
- database
- web tier
- bastion

**Representative grouped plan output (`make plan-counts`) before the first real apply:**

`make-plan-counts` delivers a **grouped view** that allows a quick inspection of what Terraform is about to create once we enter `make apply`; the result is much easier to inspect than the full raw plan:

```text
1x aws_autoscaling_group
1x aws_db_instance
1x aws_db_subnet_group
2x aws_eip
1x aws_instance
1x aws_internet_gateway
1x aws_key_pair
1x aws_launch_template
1x aws_lb
1x aws_lb_listener
1x aws_lb_target_group
2x aws_nat_gateway
3x aws_route_table
4x aws_route_table_association
4x aws_security_group
4x aws_subnet
1x aws_vpc
```

---

## Step 09 - Apply the full stack and verify it in AWS + browser

### Rationale

The project needed real AWS proof, not just a valid plan.
That meant performing one real `apply`, capturing proof, and then tearing the stack down again.

### Commands

~~~bash
# Create the AWS infrastructure from the saved Terraform plan.
make apply

# Print the resulting Terraform outputs, including the ALB DNS name and bastion public IP.
make output
~~~

### Representative apply observations

The collected terminal output showed the expected staged resource creation flow, for example:
- bastion key pair creation
- VPC creation
- subnet creation
- DB subnet group and DB security group creation
- ALB target group creation
- later the rest of the full stack

### Final apply result

**Representative apply result excerpt:**

~~~bash
Apply complete! Resources: 30 added, 0 changed, 0 destroyed.
...
Outputs:

alb_dns_name = "wordpress-platform-dev-alb-647113853.eu-west-3.elb.amazonaws.com"
asg_name = "wordpress-platform-dev-asg"
bastion_public_ip = "35.180.44.235"
db_endpoint = "wordpress-platform-dev-db.cf68e4g6e9fp.eu-west-3.rds.amazonaws.com"
vpc_id = "vpc-082ec1bee886c0c40"
...
~~~

The apply completed successfully and returned outputs such as:
- `alb_dns_name`
- `asg_name`
- `bastion_public_ip`
- `db_endpoint`
- `private_subnet_ids`
- `public_subnet_ids`
- `selected_azs`
- `vpc_id`

**Conclusion:** This output confirmed that the infrastructure was fully created and exposed the most important verification values for the next validation steps.

> [!NOTE]
> **Real infrastructure - real costs - quick validation**  
> This is the point where the stack became **cost-generating real infrastructure**, which is why the validation session was intentionally kept short: apply, verify, capture evidence, destroy.

### What was verified in AWS

The evidence set included screenshots for:
- AWS Budgets overview
- Tag Editor resource search
- VPC overview
- VPC details
- subnet overview
- NAT gateway overview
- RDS overview and details
- ALB overview and details
- Auto Scaling Group overview and details
- EC2 instances overview and details
- target group details and target health

The collected evidence inventory was:
- `docs/evidence/aws/01-aws-budgets-index-screen.png`
- `docs/evidence/aws/02-aws-tag-editor-search-resources-settings.png`
- `docs/evidence/aws/03-aws-te-resoucre-search-result-after-apply.png`
- `docs/evidence/aws/04-aws-vpcs-overview.png`
- `docs/evidence/aws/05-aws-vpc-wp-dev-overview.png`
- `docs/evidence/aws/06-aws-wp-subnets-overview.png`
- `docs/evidence/aws/07-aws-nat-gateways-overview.png`
- `docs/evidence/aws/08-aws-db-wp-db-overview.png`
- `docs/evidence/aws/09-aws-db-wp-db-details.png`
- `docs/evidence/aws/10-aws-ec2-lb-overview.png`
- `docs/evidence/aws/11-aws-ec2-lb-wp-alb-details.png`
- `docs/evidence/aws/12-aws-ec2-asg-overview.png`
- `docs/evidence/aws/13-aws-ec2-asg-wp-asg-details.png`
- `docs/evidence/aws/14-aws-ec2-instances-overview.png`
- `docs/evidence/aws/15-aws-ec2-instances-wp-dev-web-details.png`
- `docs/evidence/aws/16-aws-ec2-instances-wp-dev-bastion-details.png`
- `docs/evidence/aws/17-aws-ec2-target-group-details.png`
- `docs/evidence/aws/18-aws-ec2-target-group-targets.png`

### What was verified in the browser

The browser-based WordPress evidence included:
- initial site load
- installation wizard
- finished installation
- admin login screen
- rendered sample page

Evidence files:
- `docs/evidence/wp/01-wp-successfully-loaded-wp-site.png`
- `docs/evidence/wp/02-wp-successfully-loaded-wp-intallation-wizard.png`
- `docs/evidence/wp/03-wp-successfully-finished-installation.png`
- `docs/evidence/wp/04-wp-admin-login-screen.png`
- `docs/evidence/wp/05-wp-successfully-rendered-sample-page.png` 

### Runtime observation worth noting

The site and installation flow worked, but a later admin login flow did not behave reliably.  
A likely explanation is the current multi-instance design behind the ALB: requests may land on different WordPress nodes, while bootstrap-generated local state is not shared across instances.

That does **not** invalidate the infrastructure proof, but it is an honest engineering observation worth documenting.

---

## Step 10 - Destroy the stack and verify cleanup

### Rationale

The stack was intentionally treated as short-lived cloud infrastructure to keep costs under control.
The real cost-control mechanism here is **destroying the stack again once the proof is captured**.

### Commands

~~~bash
# Preview the destroy operation before actually removing the infrastructure.
$ terraform plan -destroy

# Destroy the Terraform-managed stack after evidence capture is complete.
$ make destroy
Destroy complete! Resources: 30 destroyed.
~~~

### Destroy result

The collected destroy evidence (terminal + AWS console) showed the expected cleanup path, including the final DB removal and VPC deletion, followed by:

`Destroy complete! Resources: 30 destroyed.`

### Post-destroy verification

Post-destroy evidence included:
- NAT gateways overview after destroy
- EC2 instances overview after destroy
- Tag Editor search result after destroy
- AWS Budgets overview after destroy

Evidence files:
- `docs/evidence/aws/19-aws-vpc-nat-overview-after-destroy.png`
- `docs/evidence/aws/20-aws-ec2-instances-overview-after-destroy.png`
- `docs/evidence/aws/21-aws-te-resoucre-search-result-after-destroy.png`
- `docs/evidence/aws/22-aws-budgets-index-screen-after-destroy.png`

### Why some resources can appear briefly after destroy

Some AWS resource views can lag briefly after Terraform destroy.
For this project, transient lingering entries in AWS views were checked and interpreted correctly:
- NAT gateways were already in a terminated/deleting cleanup state
- EC2 instances were already terminated

That is consistent with AWS-side inventory lag rather than a real undeleted live stack.

---

## Key engineering decisions

This project includes a few practical engineering choices worth calling out.

### 1) Custom VPC instead of the default VPC

The infrastructure is provisioned into a dedicated VPC with explicitly chosen CIDR ranges instead of reusing the AWS default VPC.  
That makes the network layout reproducible, easier to reason about, and easier to present as intentional infrastructure rather than “whatever the account already had”.

### 2) Dual NAT design

The project uses **one NAT gateway per public subnet**, matching the high-availability requirement instead of collapsing everything behind a single NAT gateway.  
This is not the cheapest option, but it aligns with the target architecture and avoids turning private-subnet outbound access into a single-AZ dependency.

### 3) Private application + database placement

The web tier and RDS layer run in private subnets, while the ALB and bastion remain public-facing.  
That keeps the public attack surface smaller and makes the traffic flow easy to explain and defend:
- internet -> ALB
- operator -> bastion
- app -> database

### 4) Ephemeral cost-aware validation

The stack is intentionally treated as short-lived cloud infrastructure to keep costs in check:
- apply
- validate
- capture evidence
- destroy

The AWS Budget is a useful warning layer, but the real stop button is still `terraform destroy` / `make destroy`.

---

## Final project structure

~~~bash
.
├── docs
│   ├── evidence
│   │   ├── aws
│   │   │   ├── 01-aws-budgets-index-screen.png
│   │   │   ├── 02-aws-tag-editor-search-resources-settings.png
│   │   │   ├── 03-aws-te-resoucre-search-result-after-apply.png
│   │   │   ├── 04-aws-vpcs-overview.png
│   │   │   ├── 05-aws-vpc-wp-dev-overview.png
│   │   │   ├── 06-aws-wp-subnets-overview.png
│   │   │   ├── 07-aws-nat-gateways-overview.png
│   │   │   ├── 08-aws-db-wp-db-overview.png
│   │   │   ├── 09-aws-db-wp-db-details.png
│   │   │   ├── 10-aws-ec2-lb-overview.png
│   │   │   ├── 11-aws-ec2-lb-wp-alb-details.png
│   │   │   ├── 12-aws-ec2-asg-overview.png
│   │   │   ├── 13-aws-ec2-asg-wp-asg-details.png
│   │   │   ├── 14-aws-ec2-instances-overview.png
│   │   │   ├── 15-aws-ec2-instances-wp-dev-web-details.png
│   │   │   ├── 16-aws-ec2-instances-wp-dev-bastion-details.png
│   │   │   ├── 17-aws-ec2-target-group-details.png
│   │   │   ├── 18-aws-ec2-target-group-targets.png
│   │   │   ├── 19-aws-vpc-nat-overview-after-destroy.png
│   │   │   ├── 20-aws-ec2-instances-overview-after-destroy.png
│   │   │   ├── 21-aws-te-resoucre-search-result-after-destroy.png
│   │   │   └── 22-aws-budgets-index-screen-after-destroy.png
│   │   └── wp
│   │       ├── 01-wp-successfully-loaded-wp-site.png
│   │       ├── 02-wp-successfully-loaded-wp-intallation-wizard.png
│   │       ├── 03-wp-successfully-finished-installation.png
│   │       ├── 04-wp-admin-login-screen.png
│   │       └── 05-wp-successfully-rendered-sample-page.png
│   ├── IMPLEMENTATION.md
│   ├── _private
│   │   └── notes.md
│   ├── RUNBOOK.md
│   └── SETUP.md
├── main.tf
├── Makefile
├── modules
│   ├── bastion
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── database
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── network
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── web
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── providers.tf
├── README.md
├── terraform.tfvars.example
├── user_data
│   └── wordpress.sh.tftpl
├── variables.tf
└── versions.tf
~~~

### What the main repo parts are for

- `main.tf` — root composition layer that wires the modules together
- `providers.tf` — AWS provider config and shared tags
- `versions.tf` — Terraform and provider version requirements
- `variables.tf` — root input variables
- `outputs.tf` — root outputs used for verification
- `Makefile` — short repeatable lifecycle commands
- `modules/network` — VPC, subnets, route tables, Internet Gateway, NAT gateways
- `modules/database` — DB subnet group, DB security group, private Multi-AZ RDS
- `modules/web` — ALB, target group, listener, launch template, Auto Scaling Group
- `modules/bastion` — bastion EC2, AWS key pair, bastion SG
- `user_data/wordpress.sh.tftpl` — EC2 bootstrap template for WordPress installation
- `docs/evidence/` — proof of creation, runtime behavior, and cleanup

---

## Sources

### Terraform structure, providers, and CLI

- [HashiCorp: Install Terraform](https://developer.hashicorp.com/terraform/install)  
  Official Terraform install page.

- [HashiCorp: Terraform CLI overview](https://developer.hashicorp.com/terraform/cli)  
  Official CLI overview for the Terraform workflow.

- [HashiCorp: `terraform plan` command reference](https://developer.hashicorp.com/terraform/cli/commands/plan)  
  Official reference for speculative plans and saved plan files.

- [HashiCorp: `terraform show` command reference](https://developer.hashicorp.com/terraform/cli/commands/show)  
  Official reference for human-readable and JSON rendering of plan/state data.

- [HashiCorp: `terraform destroy` command reference](https://developer.hashicorp.com/terraform/cli/commands/destroy)  
  Official reference for stack teardown.

- [HashiCorp: Providers overview](https://developer.hashicorp.com/terraform/language/providers)  
  Official explanation of what providers are and how Terraform uses them.

- [HashiCorp: Provider requirements](https://developer.hashicorp.com/terraform/language/providers/requirements)  
  Official reference for `required_providers`.

- [HashiCorp: Standard module structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure)  
  Official guidance for the `main.tf` / `variables.tf` / `outputs.tf` module layout.

- [HashiCorp: `templatefile` function](https://developer.hashicorp.com/terraform/language/functions/templatefile)  
  Official reference for external template rendering such as `wordpress.sh.tftpl`.

### Local AWS access and account preparation

- [AWS: Install or update the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)  
  Official AWS CLI installation guide for Linux.

- [AWS: AWS CLI configuration and credential files](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)  
  Official reference for named AWS CLI profiles and local credentials.

- [AWS IAM: Root user best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-best-practices.html)  
  Official AWS guidance on avoiding root-user usage for normal project work.

- [AWS IAM: Manage access keys for IAM users](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)  
  Official AWS guide for CLI / Terraform programmatic access via IAM users.

### Cost awareness and cleanup

- [AWS Budgets: Managing your costs with AWS Budgets](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html)  
  Official explanation of budget behavior, alerts, and limitations.

- [AWS Budgets: Using a budget template (simplified)](https://docs.aws.amazon.com/cost-management/latest/userguide/budget-templates.html)  
  Official documentation for the simplified budget-template flow.

- [AWS Budgets: Creating a cost budget](https://docs.aws.amazon.com/cost-management/latest/userguide/create-cost-budget.html)  
  Official reference for budget scope, cost type, and alerts.

- [AWS Tag Editor: Find resources to tag](https://docs.aws.amazon.com/tag-editor/latest/userguide/find-resources-to-tag.html)  
  Official AWS documentation for cross-resource tag-based search in the console.

### EC2 WordPress bootstrap approach

- [AWS EC2: User data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)  
  AWS mechanism used to run shell commands automatically when an EC2 instance launches.

- [WordPress: How to install WordPress](https://developer.wordpress.org/advanced-administration/before-install/howto-install/)  
  Conventional WordPress installation flow: place the files, prepare the database, and complete the installation.

- [WordPress: `wp-config.php`](https://developer.wordpress.org/apis/wp-config-php/)  
  Database settings, salts, and core configuration values written into `wp-config.php`.

### Runtime validation in AWS

- [AWS ELB: Check target health](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/check-target-health.html)  
  Official AWS documentation for ALB target registration and health-state inspection.

- [AWS RDS: Creating a DB instance](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_CreateDBInstance.html)  
  Official AWS documentation for RDS DB instance creation behavior.
