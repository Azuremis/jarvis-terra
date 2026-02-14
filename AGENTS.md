# AGENTS.md - Guide for AI Assistants Working in This Repository

This document provides essential information for AI assistants (and developers) working in this Terraform-based infrastructure repository for deploying OpenClaw on Hetzner Cloud.

---

## Project Overview

This repository contains **infrastructure-as-code** for deploying [OpenClaw](https://github.com/openclaw/openclaw) (an AI coding assistant) on Hetzner Cloud VPS. It includes:

- **Terraform modules** for VPS provisioning, firewall configuration
- **Shell scripts** for deployment, backup, and management
- **Cloud-init configuration** for automated server setup
- **CI/CD pipelines** for validation

**Project Type**: Infrastructure as Code (Terraform + Shell Scripts)

---

## Quick Start Commands

### Environment Setup
```bash
# Copy configuration template
cp config/inputs.example.sh config/inputs.sh

# Edit with your credentials (NEVER commit config/inputs.sh)
vim config/inputs.sh

# Source the configuration before running commands
source config/inputs.sh
```

### Terraform Operations
```bash
# Initialize Terraform
make init

# Preview changes
make plan

# Apply infrastructure changes
make apply

# Destroy infrastructure (dangerous!)
make destroy

# Format Terraform files
make fmt

# Validate Terraform and shell scripts
make validate
```

### Deployment Operations
```bash
# Initial OpenClaw setup on VPS (run once after apply)
make bootstrap

# Pull latest image and restart
make deploy

# Push environment variables to VPS
make push-env

# Push configuration files to VPS
make push-config

# Set up Claude subscription auth
make setup-auth
```

### Status and Maintenance
```bash
# Check container status
make status

# Stream container logs
make logs

# SSH to VPS as openclaw user
make ssh

# SSH to VPS as root
make ssh-root

# Create SSH tunnel to OpenClaw gateway (localhost:18789)
make tunnel

# Run backup immediately
make backup-now

# Restore from backup
make restore BACKUP=openclaw_backup_YYYYMMDD_HHMMSS.tar.gz
```

---

## Code Organization

```
.
├── infra/
│   ├── terraform/
│   │   ├── globals/              # Shared provider/version config
│   │   │   ├── backend.tf        # S3 backend documentation
│   │   │   └── versions.tf       # Terraform + Hetzner provider versions
│   │   ├── envs/
│   │   │   └── prod/             # Production environment
│   │   │       ├── main.tf       # Main prod configuration
│   │   │       └── variables.tf  # Environment variables
│   │   └── modules/
│   │       └── hetzner-vps/      # Reusable VPS module
│   │           ├── main.tf
│   │           ├── variables.tf
│   │           └── outputs.tf
│   └── cloud-init/
│       └── user-data.yml.tpl     # Server initialization script
├── deploy/                        # Deployment automation scripts
│   ├── bootstrap.sh              # Initial setup
│   ├── deploy.sh                 # Update container
│   ├── backup.sh                 # Create backup
│   ├── restore.sh                # Restore from backup
│   ├── logs.sh                   # View logs
│   └── status.sh                 # Check status
├── scripts/                       # Utility scripts
│   ├── push-env.sh               # Push .env to VPS
│   ├── push-config.sh            # Push config files
│   └── setup-auth.sh             # Configure Claude auth
├── config/
│   └── inputs.example.sh         # Configuration template
└── secrets/
    └── openclaw.env.example      # Application secrets template
```

---

## Terraform Architecture

### Provider
- **Hetzner Cloud** (`hetznercloud/hcloud`) version `~> 1.45`
- Terraform version `>= 1.5`

### Key Resources Created
1. **Server** (Ubuntu 24.04, default: CX23)
2. **SSH Key** (existing key by fingerprint)
3. **Firewall** (SSH-only inbound from configured CIDRs)
4. **Cloud-init** user data for automated setup

### Remote State
- **Backend**: S3-compatible (Hetzner Object Storage)
- **Configuration**: Commented out by default; uncomment in `infra/terraform/envs/prod/main.tf`
- **Credentials**: Set via `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`

---

## Shell Script Conventions

### All Scripts Follow These Patterns

1. **Strict mode**: `set -euo pipefail`
2. **VPS IP detection**: Reads from Terraform output or accepts as argument
3. **SSH options**: `-o StrictHostKeyChecking=accept-new`
4. **User**: `openclaw` (non-root application user)

### Script Arguments
- Scripts typically accept VPS IP as optional first argument
- If not provided, scripts try to read from `terraform output -raw server_ip`
- Always verify SSH connectivity before proceeding

### Common Patterns
- SSH with heredocs for remote execution
- SCP for file transfers
- Docker Compose for container management
- Color-coded output (GREEN/RED/YELLOW/BLUE)

---

## Configuration Requirements

### Required Variables (in `config/inputs.sh`)

| Variable | Purpose |
|----------|---------|
| `HCLOUD_TOKEN` | Hetzner Cloud API token |
| `TF_VAR_ssh_key_fingerprint` | Existing SSH key fingerprint |
| `TF_VAR_ssh_allowed_cidrs` | CIDR blocks allowed for SSH |
| `CONFIG_DIR` | Path to openclaw-config repository |
| `GHCR_USERNAME` | GitHub username for container registry |
| `GHCR_TOKEN` | GitHub PAT with `read:packages` scope |
| `AWS_ACCESS_KEY_ID` | Hetzner Object Storage access key (for remote state) |
| `AWS_SECRET_ACCESS_KEY` | Hetzner Object Storage secret key |

### Required Application Secrets (in `secrets/openclaw.env`)

| Variable | Purpose |
|----------|---------|
| `TELEGRAM_BOT_TOKEN` | Telegram bot token (required) |
| `OPENCLAW_GATEWAY_TOKEN` | Gateway authentication token (required) |
| `ANTHROPIC_API_KEY` | Claude API key (optional if using setup-token) |

---

## Important Gotchas

### 1. CONFIG_DIR Must Be Set
- Used by `bootstrap.sh`, `push-config.sh`, `push-env.sh`
- Must point to your local `openclaw-config` repository
- Contains `docker/docker-compose.yml` and `config/` directory

### 2. Cloud-init Takes Time
- Server is not immediately usable after `terraform apply`
- Wait 2-5 minutes for cloud-init to complete
- Check with: `make status` (will fail if cloud-init not done)

### 3. SSH Key Fingerprint Must Match
- Get fingerprint from Hetzner console or API
- Never recreate the key (use existing fingerprint)
- Formula: `ssh-keygen -lf ~/.ssh/id_rsa.pub | cut -d' ' -f2`

### 4. Secrets NEVER Committed
- `.gitignore` excludes:
  - `config/inputs.sh`
  - `secrets/openclaw.env`
  - All `*.pem`, `*.key` files
  - Terraform state files

### 5. OpenClaw Gateway is Localhost Only
- Binds to `127.0.0.1:18789` (not exposed to internet)
- Access via: `make tunnel` (creates SSH tunnel)
- Or use your own reverse proxy

### 6. Backup Frequency
- Daily at 3:00 AM UTC via systemd timer
- Retention: 7 days
- Location: `~/backups/`

### 7. Auth Options
- **API Key**: Set `ANTHROPIC_API_KEY` in `secrets/openclaw.env`
- **Subscription**: Run `make setup-auth` with `CLAUDE_SETUP_TOKEN`

---

## Testing and Validation

### CI/CD Pipeline (GitHub Actions)

**ShellCheck** (`.github/workflows/shellcheck.yml`):
- Runs on all PRs and pushes to `main`
- Lints `deploy/*.sh` and `scripts/*.sh`
- Severity: `warning`

**Terraform CI** (`.github/workflows/terraform.yml`):
- Format check: `terraform fmt -check -recursive infra/terraform/`
- Validate prod: `terraform init -backend=false && terraform validate`
- Validate module: Same for `hetzner-vps` module
- Terraform version: `1.7.0`

### Manual Validation
```bash
# Check all shell scripts for syntax errors
make validate

# Format Terraform files
make fmt

# Check for uncommitted changes
git status
```

---

## Common Workflows

### Initial Deployment
```bash
# 1. Configure
cp config/inputs.example.sh config/inputs.sh
vim config/inputs.sh

# 2. Initialize Terraform
source config/inputs.sh
make init

# 3. Plan and apply
make plan
make apply

# 4. Wait for cloud-init (2-5 minutes)

# 5. Bootstrap OpenClaw
make bootstrap

# 6. Deploy
make deploy

# 7. Verify
make status
```

### Updating Configuration
```bash
# 1. Edit config files in your openclaw-config repo
vim ~/path/to/openclaw-config/config/openclaw.json

# 2. Push to VPS
make push-config

# 3. Restart container
make deploy
```

### Fixing Issues
```bash
# Check container status
make status

# View recent logs
make logs

# SSH to debug
make ssh

# Re-push environment variables
make push-env

# Re-push configuration
make push-config

# Force restart
make deploy
```

### Disaster Recovery
```bash
# List available backups
make ssh
ls -lh ~/backups/

# Restore from backup
make restore BACKUP=openclaw_backup_20240115_030000.tar.gz
```

---

## Security Considerations

### SSH Access
- Default: SSH allowed from `0.0.0.0/0` (any IP)
- **Recommendation**: Restrict to your IP in `config/inputs.sh`
  ```bash
  export TF_VAR_ssh_allowed_cidrs='["YOUR_IP/32"]'
  ```

### Secrets Management
- Never commit `config/inputs.sh` or `secrets/openclaw.env`
- Rotate API tokens periodically
- Use SSH keys, not passwords

### Firewall
- Default: SSH only from configured CIDRs
- Hetzner Cloud Firewall + UFW on VPS
- Gateway binds to localhost only

### Docker Security
- Non-root `openclaw` user
- Docker group membership for container management
- Image cleanup after updates

---

## Troubleshooting

### Terraform Init Fails
**Cause**: S3 backend credentials not set  
**Solution**:
```bash
source config/inputs.sh
make init
```
Or comment out backend block in `infra/terraform/envs/prod/main.tf`

### Container Won't Start
**Check logs**: `make logs`  
**Common fixes**:
```bash
make push-env    # Re-push environment variables
make push-config # Re-push config
make deploy      # Restart
```

### Bootstrap Fails
**Verify prerequisites**:
```bash
echo $CONFIG_DIR
ls $CONFIG_DIR/docker/docker-compose.yml
```

### SSH Connection Refused
**Check firewall**:
```bash
grep TF_VAR_ssh_allowed_cidrs config/inputs.sh
```
**Check VPS status**:
```bash
make status
make ssh-root
ufw status
```

---

## Dependencies and External Links

| Tool | Purpose | Link |
|------|---------|------|
| Terraform | Infrastructure provisioning | https://www.terraform.io/ |
| Hetzner Cloud | VPS provider | https://console.hetzner.cloud/ |
| Docker | Container runtime | https://docs.docker.com/ |
| OpenClaw | AI coding assistant | https://docs.openclaw.ai/ |
| Cloud-init | Server initialization | https://cloud-init.io/ |

**Companion Repositories**:
- [openclaw-docker-config](https://github.com/andreesg/openclaw-docker-config) - Docker and OpenClaw configuration

---

## Project-Specific Notes

### Why Shell Scripts Over GitHub Actions?
- Direct VPS interaction (SSH, Docker commands)
- Interactive prompts for safety (restore, bootstrap)
- User-friendly deployment workflow
- Easier debugging (run locally with same commands)

### Why No State in This Repo?
- State files contain sensitive data (IPs, resource IDs)
- Remote state (Hetzner Object Storage) is recommended
- Local state works for initial setup

### Modular Terraform Design
- `globals/` - Shared version constraints
- `envs/prod/` - Environment-specific configuration
- `modules/hetzner-vps/` - Reusable VPS component
- Follows Terraform best practices

---

## Generating the `CLAUDE_SETUP_TOKEN`

To use Claude subscription instead of API keys:

```bash
# 1. Generate setup token (locally)
claude setup-token

# 2. Add to config/inputs.sh
export CLAUDE_SETUP_TOKEN="your-token-here"

# 3. Run setup-auth
source config/inputs.sh
make setup-auth
```

---

*This document was auto-generated on 2026-02-14*
