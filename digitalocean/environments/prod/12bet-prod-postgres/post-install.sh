export ETCDCTL_API=3

#Certificate generation for Patroni cluster communication.
mkdir -p /etc/patroni/certs
cd /etc/patroni/certs

#Only on the first node to generate CA and server certificates.
openssl req -x509 -newkey rsa:4096 -keyout ca.key -sha256 -days 3650 -out ca.crt -subj "/CN=postgres-ca"

#Create a common CSR.
openssl req -new -newkey rsa:2048 -nodes -keyout postgres-node.key -out postgres-node.csr -subj "/CN=*.postgres.mydomain.local" -addext "subjectAltName=DNS:postgres-node-1.postgres.mydomain.local,DNS:postgres-node-1,IP:10.0.1.2,DNS:postgres-node-2.postgres.mydomain.local,DNS:postgres-node-2,IP:10.0.1.3,IP:127.0.0.1"
chmod 600 postgres-node-1.key

#Sign the CSR with the CA.
openssl x509 -req -in postgres-node.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out postgres-node.crt -days 1825 -sha256 -copy_extensions copy
chown postgres:postgres *

#Verify the certificates.
openssl x509 -in ca.crt -text -noout
openssl verify -CAfile ca.crt postgres-node.crt

#Copy the signed certificate and key to all nodes.

#Self-signed cert without CA.
openssl req -x509 -newkey rsa:2048 -nodes -keyout server.key -out server.crt -days 3650 -subj "/CN=postgres-node-1"

#Install mailx for email notifications.

#Start patroni.
sudo systemctl daemon-reload && sudo systemctl enable patroni && sudo systemctl start patroni && sudo systemctl status patroni

#Run this once on the leader node.
pgbackrest --stanza=postgres-cluster --log-level-console=info stanza-create

#Enable ETCD authentication.
ETCDCTL_API=3 etcdctl --endpoints=http://10.0.1.2:2379,http://10.0.1.3:2379 user add root
ETCDCTL_API=3 etcdctl --endpoints=http://10.0.1.2:2379,http://10.0.1.3:2379 role add root
ETCDCTL_API=3 etcdctl --endpoints=http://10.0.1.2:2379,http://10.0.1.3:2379 role grant-permission root --prefix=true readwrite /
ETCDCTL_API=3 etcdctl --endpoints=http://10.0.1.2:2379,http://10.0.1.3:2379 user grant-role root root
ETCDCTL_API=3 etcdctl --endpoints=http://10.0.1.2:2379,http://10.0.1.3:2379 auth enable