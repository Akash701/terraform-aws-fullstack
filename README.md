# Terraform AWS Full-Stack Deployment

Welcome to my full-stack cloud deployment project! This project showcases a fully automated deployment of a Node.js backend and static frontend using **AWS** services — all provisioned through **Terraform**.

## 🌐 Live Site

**Frontend:** [https://ansarbro.com](https://ansarbro.com)

> ⚠️ *Live backend services (EC2 & RDS) may be paused to avoid AWS charges. All code and infrastructure setup remain available for reference.*

---

## 🚀 Project Overview

### What It Includes:

* **Frontend**:

  * Hosted on **Amazon S3**
  * Delivered via **CloudFront** CDN
  * Configured with **HTTPS** via **AWS ACM**

* **Backend**:

  * **Node.js** API running on **EC2 (Ubuntu)**
  * Managed with **PM2** process manager

* **Database**:

  * **Amazon RDS** MySQL
  * Subnet-isolated and protected with **custom security groups**

* **Networking**:

  * **Route 53** for DNS
  * **ACM** for SSL certs
  * **Custom security groups** for safe traffic routing

* **Infrastructure as Code**:

  * Entire architecture written in **Terraform**
  * Includes IAM, EC2, RDS, S3, Route53, CloudFront, ACM, and VPC settings

---

## 🛠 Tech Stack

| Layer      | Tech                     |
| ---------- | ------------------------ |
| IaC        | Terraform                |
| Backend    | Node.js (Express)        |
| Frontend   | HTML + CSS (static site) |
| Database   | Amazon RDS (MySQL)       |
| Hosting    | Amazon S3 + CloudFront   |
| Domain     | Route 53 + ACM (SSL)     |
| Deployment | AWS EC2 (Ubuntu)         |

---

## 📁 Repo Structure

```
.
├── terraform/                # All Terraform .tf files
├── ansarbro-backend/        # Node.js backend
│   ├── server.js
│   ├── db.js
│   └── .env (NOT included)
├── static-site/             # S3-deployed frontend
│   └── index.html
└── README.md
```

---

## 📦 Environment Variables

In `ansarbro-backend/.env` (not committed):

```env
PORT=3000
DB_HOST=<your-rds-endpoint>
DB_USER=<your-db-username>
DB_PASS=<your-db-password>
```

---

## 🧠 Key Learnings

* Real-world Terraform usage with complex multi-service provisioning
* IAM permission scoping and least privilege practice
* HTTPS setup using Route 53 + ACM
* Managing EC2 backend with PM2
* Connecting EC2 securely to RDS via subnet groups and security rules

---

## 🔗 Useful Commands

```bash
# Terraform
terraform init
terraform plan
terraform apply

# SSH into EC2
ssh -i <key>.pem ubuntu@<ec2-public-ip>

# Node.js (PM2)
pm install
pm run start
pm2 restart server
```

---

## 🧾 License

MIT

---

## 🙌 Connect With Me

Built with 💻☁️ by [Akash](https://github.com/Akash701)

If you liked the project, feel free to ⭐ the repo or drop me a message on LinkedIn!

---
