#!/bin/bash

touch /etc/consul.d/server.hcl
chmod 640 /etc/consul.d/server.hcl

cat >/etc/consul.d/server.hcl <<EOF
server = true
bootstrap_expect = 3
ui = true
connect {
  enabled = true
}
EOF

systemctl enable consul
systemctl restart consul
systemctl status consul

# consul agent -retry-join 'provider=azure config=val config2="some other val" ...'