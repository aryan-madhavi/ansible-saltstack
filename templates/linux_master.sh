#!/bin/bash
yum update -y

curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.repo | sudo tee /etc/yum.repos.d/salt.repo
dnf clean expire-cache
dnf install salt-master salt-api git curl -y

if grep -q '^user:\s*salt' /etc/salt/master; then
  sed -i 's/^user:\s*salt/# &/' /etc/salt/master
fi

useradd -m -s /bin/bash saltuser
echo "saltuser:passwd" | chpasswd

mkdir -p /etc/salt/master.d

cat <<EOF > /etc/salt/master.d/auth.conf
external_auth:
  pam:
    saltuser:
      - .*
      - '@wheel'
      - '@runner'
      - '@jobs'
EOF

cat <<EOF > /etc/salt/master.d/api.conf
rest_cherrypy:
  port: 8080
  host: 0.0.0.0
  debug: true
  disable_ssl: true
EOF

cat <<EOF > /etc/salt/master.d/clients.conf
netapi_enable_clients:
  - local
  - local_async
  - local_batch
  - local_subset
  - runner
  - runner_async
EOF

cat <<EOF > /etc/salt/master.d/logs.conf
log_level: info
EOF

systemctl enable salt-master && systemctl start salt-master
systemctl enable salt-api && systemctl start salt-api