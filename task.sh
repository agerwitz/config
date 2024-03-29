#!/bin/bash

set -eu

file_path=$(find ./pivnet-opsman-product/ -name "*.ova")

echo "$file_path"

export GOVC_TLS_CA_CERTS=/tmp/vcenter-ca.pem
echo "$GOVC_CA_CERT" > "$GOVC_TLS_CA_CERTS"

govc import.spec "$file_path" | python -m json.tool > om-import.json

cat > filters <<'EOF'
del(.Deployment) |
.Name = $vmName |
.DiskProvisioning = $diskType |
.NetworkMapping[].Network = $network |
(.PropertyMapping[] | select(.Key == "ip0")).Value = $ip0 |
(.PropertyMapping[] | select(.Key == "netmask0")).Value = $netmask0 |
(.PropertyMapping[] | select(.Key == "gateway")).Value = $gateway |
(.PropertyMapping[] | select(.Key == "DNS")).Value = $dns |
(.PropertyMapping[] | select(.Key == "ntp_servers")).Value = $ntpServers |
(.PropertyMapping[] | select(.Key == "admin_password")).Value = $adminPassword |
(.PropertyMapping[] | select(.Key == "custom_hostname")).Value = $customHostname
EOF

jq \
  --arg ip0 "$OM_IP" \
  --arg netmask0 "$OM_NETMASK" \
  --arg gateway "$OM_GATEWAY" \
  --arg dns "$OM_DNS_SERVERS" \
  --arg ntpServers "$OM_NTP_SERVERS" \
  --arg adminPassword "$OPS_MGR_SSH_PWD" \
  --arg customHostname "$OPSMAN_DOMAIN_OR_IP_ADDRESS" \
  --arg network "$OM_VM_NETWORK" \
  --arg vmName "$OM_VM_NAME" \
  --arg diskType "$OPSMAN_DISK_TYPE" \
  --from-file filters \
  om-import.json > options.json

cat options.json

govc import.ova -options=options.json pivnet-opsman-product/ops-manager-vsphere-2.5.8-build.212.ova
