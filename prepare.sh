#!/usr/bin/bash
set -e
cat <<\EOF > env.sh
#!/usr/bin/bash
## Locate your APIKEY (Entitlement Key For Container Software) 
## here: https://myibm.ibm.com/products-services/containerlibrary
### --- Update this section --- ###
export IBM_ENTITLEMENT_KEY=
export UDS_CONTACT_EMAIL=
export UDS_CONTACT_FIRSTNAME=
export UDS_CONTACT_LASTNAME=
export SLS_LICENSE_ID=
### ----------------------- ###
export MAS_CONFIG_DIR=/scripts
export SLS_MONGODB_CFG_FILE=/scripts
export MAS_INSTANCE_ID=masdemo
export MAS_WORKSPACE_ID=masdev
export SLS_DOMAIN=svc.cluster.local
export SLS_LICENSE_FILE=/scripts/entitlement.lic
export MAS_APP_SETTINGS_DEMODATA=true
export MAS_APP_SETTINGS_PERSISTENT_VOLUMES_FLAG=true
export MAS_APP_SETTINGS_SERVER_BUNDLES_SIZE=jms
export MAS_APPWS_COMPONENTS="base=latest,health=latest"
EOF
cat <<\EOF > 1_core.sh
#!/usr/bin/bash
## To read env.sh file.
source $(dirname $(realpath ${0}))/env.sh
set -e
## Check.
if [ -z "$IBM_ENTITLEMENT_KEY" ]; then echo "IBM container software's entitlement key must be defined."; fi
## Check.
FILE=/scripts/entitlement.lic
if [ ! -f "$FILE" ]; then echo "Place AppPoint License file as entitlement.lic."; fi
set +e
export OCP_INGRESS=$(oc get ingress.config cluster -o jsonpath='{.spec.domain}')
ansible-playbook ibm.mas_devops.oneclick_core
EOF
cat <<\EOF > 2_manage.sh
#!/usr/bin/bash
## To read env.sh file
source $(dirname $(realpath ${0}))/env.sh
set -e
export OCP_INGRESS=$(oc get ingress.config cluster -o jsonpath='{.spec.domain}')
ansible-playbook ibm.mas_devops.oneclick_add_manage.yml
set +e
export DB2_INSTANCE_NAME=db2w-shared
### Add PVC and BIM - post-deploy config for Manage
ROLE_NAME=suite_manage_attachments_config ansible-playbook ibm.mas_devops.run_role
#ROLE_NAME=suite_manage_bim_config ansible-playbook ibm.mas_devops.run_role
EOF
cat <<\EOF > 3_iot.sh
#!/usr/bin/bash
## To read env.sh file.
source $(dirname $(realpath ${0}))/env.sh
#export MAS_APP_CHANNEL=8.5.x
ansible-playbook ibm.mas_devops.oneclick_add_iot
set -e
oc project mas-masdemo-iot
oc get pods --field-selector 'status.phase=Failed' -o name | xargs oc delete
EOF
cat <<\EOF > 4_monitor.sh
#!/usr/bin/bash
## To read env.sh file.
source $(dirname $(realpath ${0}))/env.sh
#export MAS_APP_CHANNEL=8.8.x
ansible-playbook ibm.mas_devops.oneclick_add_monitor
EOF
chmod +x *.sh
exit 0
