#!/bin/bash
# ============================================
# OpenClaw - Input Configuration Example
# ============================================
# Copy this file to inputs.sh and fill in your values:
#   cp config/inputs.example.sh config/inputs.sh
#
# Source before running Terraform:
#   source config/inputs.sh
#
# NEVER commit inputs.sh to version control

# ============================================
# REQUIRED: Hetzner Cloud API Token
# ============================================
# Generate at: https://console.hetzner.cloud/ -> Projects -> API Tokens
export HCLOUD_TOKEN="CHANGE_ME_your-hcloud-token-here"

# Terraform reads this as var.hcloud_token
export TF_VAR_hcloud_token="$HCLOUD_TOKEN"

# ============================================
# REQUIRED: Hetzner Object Storage (S3-compatible)
# ============================================
# For Terraform remote state storage
# Create bucket at: https://console.hetzner.cloud/ -> Object Storage
export S3_ENDPOINT="https://nbg1.your-objectstorage.com"
export S3_ACCESS_KEY="CHANGE_ME_your-s3-access-key"
export S3_SECRET_KEY="CHANGE_ME_your-s3-secret-key"
export S3_BUCKET="openclaw-tfstate"

# Terraform S3 backend uses AWS_ env vars
export AWS_ACCESS_KEY_ID="$S3_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$S3_SECRET_KEY"

# ============================================
# REQUIRED: SSH Configuration
# ============================================
# Allowed CIDRs for SSH access (use YOUR_IP/32 for single IPs)
# Find your IP: curl -s ifconfig.me
export TF_VAR_ssh_allowed_cidrs='["0.0.0.0/0"]'

# Fingerprint of your existing Hetzner SSH key (avoids recreating shared keys)
# Option 1: Get fingerprint programmatically by key name (recommended)
# Set your key name here:
export HETZNER_SSH_KEY_NAME="your-key-name"
# This will automatically get the fingerprint:
export TF_VAR_ssh_key_fingerprint=$(curl -s -H "Authorization: Bearer $HCLOUD_TOKEN" https://api.hetzner.cloud/v1/ssh_keys | jq -r --arg name "$HETZNER_SSH_KEY_NAME" '.ssh_keys[] | select(.name == $name) | .fingerprint')

# Option 2: List all keys manually
# curl -s -H "Authorization: Bearer $HCLOUD_TOKEN" https://api.hetzner.cloud/v1/ssh_keys | jq '.ssh_keys[] | {name, fingerprint}'

# Option 3: Set fingerprint directly (if you know it)
# export TF_VAR_ssh_key_fingerprint="CHANGE_ME_your-ssh-key-fingerprint"

# ============================================
# REQUIRED: Config Directory
# ============================================
# Local path to your openclaw-config repository (used by bootstrap, push-config)
export CONFIG_DIR="/path/to/your/openclaw-config"

# ============================================
# REQUIRED: GitHub Container Registry
# ============================================
# For pulling private Docker images during bootstrap and deploy
# Create a PAT at: https://github.com/settings/tokens with read:packages scope
export GHCR_USERNAME="your-github-username"
export GHCR_TOKEN="CHANGE_ME_your-github-pat-with-read-packages-scope"

# ============================================
# OPTIONAL: Claude Setup Token (for Claude Max/Pro subscription)
# ============================================
# Use your Claude subscription instead of paying for API credits.
# Generate with: claude setup-token
# Then run: make setup-auth
export CLAUDE_SETUP_TOKEN=""

# ============================================
# OPTIONAL: Additional Model Provider Tokens
# ============================================
# OpenRouter API key (30+ free models)
export OPENROUTER_API_KEY="your-key"

# Groq API key (fastest inference)
export GROQ_API_KEY="your-key"

# Cerebras API key (ultra-fast inference)
export CEREBRAS_API_KEY="your-key"

# Modal API key ($5/month + $30 with payment method)
export MODAL_API_KEY="your-key"

# Vercel AI Gateway API key ($5/month)
export VERCEL_API_KEY="your-key"

# Ollama endpoints
export OLLAMA_CLOUD_ENDPOINT="https://your-ollama-cloud.com"  # If using cloud Ollama
export OLLAMA_LOCAL_ENDPOINT="http://localhost:11434"         # Local Ollama

# OpenAI API key
export OPENAI_API_KEY="your-key"

# Anthropic API key (if not using Claude setup token)
export ANTHROPIC_API_KEY="your-key"

# Azure OpenAI endpoint and key
export AZURE_OPENAI_ENDPOINT="https://your-resource.openai.azure.com/"
export AZURE_OPENAI_KEY="your-key"
export AZURE_OPENAI_API_VERSION="2024-02-15-preview"

# Google AI Studio API key
export GOOGLE_AI_API_KEY="your-key"

# ============================================
# Server Configuration (Optional Overrides)
# ============================================
# export TF_VAR_server_type="cx23"
# export TF_VAR_server_location="nbg1"

# Resulting server name will be: <project_name>-<environment>
# Project naming (this will be used for server naming)
export TF_VAR_project_name="your-server-name"
 
# Environment (affects naming too)
export TF_VAR_environment="number"

# Application user (default: openclaw)
export TF_VAR_app_user="openclaw"