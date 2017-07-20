#!/usr/bin/env bash

JSON="$(terraform output -json)";
DOMAIN=cje.$(sed -e 's/^"//' -e 's/"$//' <<<"`echo $JSON | jq '.["domain"]["value"]'`");
SSH_ID_FILE=$(sed -e 's/^"//' -e 's/"$//' <<<"`echo $JSON | jq '.["ssh_identity_file"]["value"]'`");
USER=$(sed -e 's/^"//' -e 's/"$//' <<<"`echo $JSON | jq '.["user"]["value"]'`");
CONT_COUNT=$(sed -e 's/^"//' -e 's/"$//' <<<"`echo $JSON | jq '.["controller_count"]["value"]'`");
CONT_IPS=$(sed -e 's/^"//' -e 's/"$//' <<<"`echo $JSON | jq '.["controllers_addresses"]["value"]'`");
MW_COUNT=$(sed -e 's/^"//' -e 's/"$//' <<<"`echo $JSON | jq '.["master_worker_count"]["value"]'`");
MW_IPS=$(sed -e 's/^"//' -e 's/"$//' <<<"`echo $JSON | jq '.["master_workers_addresses"]["value"]'`");
BW_COUNT=$(sed -e 's/^"//' -e 's/"$//' <<<"`echo $JSON | jq '.["build_worker_count"]["value"]'`");
BW_IPS=$(sed -e 's/^"//' -e 's/"$//' <<<"`echo $JSON | jq '.["build_workers_addresses"]["value"]'`");
ES_COUNT=$(sed -e 's/^"//' -e 's/"$//' <<<"`echo $JSON | jq '.["elasticsearch_worker_count"]["value"]'`");
ES_IPS=$(sed -e 's/^"//' -e 's/"$//' <<<"`echo $JSON | jq '.["elasticsearch_workers_addresses"]["value"]'`");
NFS_IP=$(sed -e 's/^"//' -e 's/"$//' <<<"`echo $JSON | jq '.["nfs_server"]["value"]'`");
NFS_DIR=$(sed -e 's/^"//' -e 's/"$//' <<<"`echo $JSON | jq '.["nfs_export_dir"]["value"]'`");

echo "filling in the following data to cluster-init.config"
echo "domain: $DOMAIN"
echo "ssh_identity_file: $SSH_ID_FILE"
echo "user: $USER"
echo "controller_count: $CONT_COUNT"
echo "controllers_addresses: $CONT_IPS"
echo "master_worker_count: $MW_COUNT"
echo "master_workers_addresses: $MW_IPS"
echo "build_worker_count: $BW_COUNT"
echo "build_workers_addresses: $BW_IPS"
echo "elasticsearch_worker_count: $ES_COUNT"
echo "elasticsearch_workers_addresses: $ES_IPS"
echo "nfs_server: $NFS_IP"
echo "nfs_export_dir: $NFS_DIR"

sed -i '' -e "/^# domain_separator/s|# domain_separator =.*|domain_separator = -|" ./cluster-init.config
sed -i '' -e "/^domain_name/s|domain_name =|domain_name = $DOMAIN|" ./cluster-init.config
sed -i '' -e "/^ssh_identity_file/s|ssh_identity_file =|ssh_identity_file = $SSH_ID_FILE|" ./cluster-init.config
sed -i '' -e "/^ssh_user/s|ssh_user =.*|ssh_user = $USER|" ./cluster-init.config
sed -i '' -e "/^controller_count/s|controller_count =.*|controller_count = $CONT_COUNT|" ./cluster-init.config
sed -i '' -e "/^controllers_addresses/s|controllers_addresses =|controllers_addresses = $CONT_IPS|" ./cluster-init.config
sed -i '' -e "/^master_worker_count/s|master_worker_count =.*|master_worker_count = $MW_COUNT|" ./cluster-init.config
sed -i '' -e "/^master_workers_addresses/s|master_workers_addresses =|master_workers_addresses = $MW_IPS|" ./cluster-init.config
sed -i '' -e "/^build_worker_count/s|build_worker_count =.*|build_worker_count = $BW_COUNT|" ./cluster-init.config
sed -i '' -e "/^build_workers_addresses/s|build_workers_addresses =|build_workers_addresses = $BW_IPS|" ./cluster-init.config
sed -i '' -e "/^elasticsearch_worker_count/s|elasticsearch_worker_count =.*|elasticsearch_worker_count = $ES_COUNT|" ./cluster-init.config
sed -i '' -e "/^#elasticsearch_workers_addresses/s|#elasticsearch_workers_addresses =|elasticsearch_workers_addresses = $ES_IPS|" ./cluster-init.config
sed -i '' -e "/^nfs_server/s|nfs_server =|nfs_server = $NFS_IP|" ./cluster-init.config
sed -i '' -e "/^nfs_export_dir/s|nfs_export_dir =|nfs_export_dir = $NFS_DIR|" ./cluster-init.config

SYMLINKED_CONFIG="$(pwd)/operations/$(ls operations | grep -- cluster-init)/config"
cp cluster-init.config $SYMLINKED_CONFIG
ln -fs $SYMLINKED_CONFIG $(pwd)/cluster-init.config
