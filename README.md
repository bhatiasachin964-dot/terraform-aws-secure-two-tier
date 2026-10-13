# Secure Two-Tier AWS Infrastructure with Terraform

Infrastructure as code for a small, **security-first** two-tier setup on AWS: a public web server, a private app server, and a locked-down S3 bucket, all defined in Terraform.

> **Status:** work in progress. The Terraform code is written and its syntax checked. I am still applying it to a live AWS account to test it. Screenshots and real output will be added after that.

<!-- TODO: add a screenshot of `terraform plan` / `terraform apply` output here -->
<!-- TODO: add a screenshot of the live web page and the AWS console (VPC / security groups) here -->

## Architecture

```
                 Internet
                    |
             Internet Gateway
                    |
   +----------------+-------------------------+  VPC 10.0.0.0/16
   |  Public subnet 10.0.1.0/24               |
   |    Web server (nginx)                    |
   |    HTTP 80 from anywhere                 |
   |    SSH 22 from YOUR IP only              |
   +----------------+-------------------------+
                    | port 8080 / SSH, from the web security group only
   +----------------+-------------------------+
   |  Private subnet 10.0.2.0/24              |
   |    App server (no public IP,             |
   |    no route to the internet)             |
   +------------------------------------------+

   S3 bucket: private, versioned, encrypted, TLS-only
   Web server IAM role: read-only access to that one bucket
```

## What gets created

| Resource | Purpose |
|---|---|
| VPC, 2 subnets, internet gateway, route tables | Network layout. The private route table has no default route. |
| 2 security groups + rules | Web: 80 from anywhere, 22 from your IP. App: only from the web security group. |
| 2 EC2 instances (Amazon Linux 2023) | Web tier (nginx) and app tier |
| IAM role + instance profile | Web server can read one S3 bucket and nothing else |
| S3 bucket + policies | Private data store |

## Security decisions

| Decision | Why |
|---|---|
| `admin_cidr` has no default and rejects `0.0.0.0/0` | SSH can never be opened to the world by accident |
| App tier is in a private subnet with no public IP | It is not reachable from the internet at all |
| App security group references the web security group | Access is tied to the web tier, not to IP ranges |
| No egress rules on the app security group | A compromised app server cannot call out |
| Default security group stripped of all rules | Nothing can silently rely on it |
| IMDSv2 required on both instances | Blocks the SSRF route to instance credentials |
| Encrypted root volumes | Data at rest is encrypted |
| S3: all four public-access blocks on | The bucket cannot be made public |
| S3: versioning and server-side encryption | Recovery from deletion and encryption at rest |
| S3 policy denies non-TLS requests | Data is only transferred encrypted |
| IAM policy scoped to one bucket, read-only actions | Least privilege |
| State file and `.tfvars` are git-ignored | State can contain sensitive values |

## Prerequisites

- Terraform 1.5 or newer
- An AWS account and credentials configured (`aws configure`)
- An existing EC2 key pair (optional, only for SSH)
- Your public IP address

## Usage

```bash
git clone https://github.com/bhatiasachin964-dot/terraform-aws-secure-two-tier.git
cd terraform-aws-secure-two-tier

cp terraform.tfvars.example terraform.tfvars   # then edit admin_cidr and key_name

terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Test the web tier with the `web_url` output:
```bash
curl $(terraform output -raw web_url)
```

To reach the private app server, jump through the web server (this needs your key loaded into an SSH agent, for example `ssh-add <key>`):
```bash
ssh -A -J ec2-user@<web_public_ip> ec2-user@<app_private_ip>
```

## Clean up (avoid charges)

```bash
terraform destroy
```
The bucket must be empty first, or set `force_destroy_bucket = true`. Instances and public IPv4 addresses cost money while they run, so check current AWS pricing and destroy the stack when you are finished.

## Limitations

- The app server has **no internet access** by design, so it cannot install packages. A real app tier would need a NAT gateway or VPC endpoints, which add cost.
- The web server serves plain **HTTP**. For production, add a load balancer or certificate for HTTPS.
- Single availability zone. Not highly available.
- The state is local. For a team, use a remote backend (S3 with locking).

## Ideas for next steps

- [ ] Remote state in S3 with locking
- [ ] VPC flow logs and CloudTrail
- [ ] Application Load Balancer with HTTPS (ACM certificate)
- [ ] Add a pipeline that runs `fmt`, `validate` and a security scanner (tfsec or Checkov) on every pull request
- [ ] Split into modules (network, compute, storage)

## Author

**Sachin Bhatia** · [LinkedIn](https://linkedin.com/in/sachin-bhatia-725a7a1a0) · [GitHub](https://github.com/bhatiasachin964-dot)
