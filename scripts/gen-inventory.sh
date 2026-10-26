#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/envs/dev"

BASTION=$(terraform output -raw bastion_public_ip)
KEY="$HOME/.ssh/jungle-fury-dev-key.pem"
OUT="$ROOT/ansible/inventory/dev.ini"

# Refresh the bastion alias in ~/.ssh/config (IP changes on every recreate)
mkdir -p "$HOME/.ssh"; touch "$HOME/.ssh/config"
sed -i '/^# BEGIN bastion-jf/,/^# END bastion-jf/d' "$HOME/.ssh/config"
cat >> "$HOME/.ssh/config" <<EOT
# BEGIN bastion-jf
Host bastion-jf
  HostName $BASTION
  User ec2-user
  IdentityFile $KEY
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new
# END bastion-jf
EOT
chmod 600 "$HOME/.ssh/config"

{
  echo "[fleet]"
  terraform output -json fleet_private_ips | jq -r '.[]'
  cat <<EOT

[fleet:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=$KEY
ansible_ssh_common_args='-o ProxyJump=bastion-jf -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes'
EOT
} > "$OUT"
echo "Wrote $OUT"
