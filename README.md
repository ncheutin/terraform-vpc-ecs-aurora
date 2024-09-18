# Terraform project to create AWS infra VPC + ECS + Aurora (Mysql) 

## Overview

Create a simple but secured infra to host app(s) in container(s), store data in a Mysql DB which can scale largely without much tuning required and is quite cost efficient.

## Architecture

Setup:
- VPC
- 2 subnets (private + public)
- ECS cluster in public subnet
- Aurora cluster (Mysql) in private cluster

