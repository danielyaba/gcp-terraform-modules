#!/bin/bash

# add failover scripts to failover files
cat << 'EOF' >> /config/failover/active
tmsh modify ltm virtual virt_EXT-INGRESS-CONTROLLER enabled
tmsh modify ltm virtual virt_INT-INGRESS-CONTROLLER enabled
EOF
cat << 'EOF' >> /config/failover/standby
tmsh modify ltm virtual virt_EXT-INGRESS-CONTROLLER disabled
tmsh modify ltm virtual virt_INT-INGRESS-CONTROLLER disabled
EOF

# create virtuals and irules
tmsh create ltm virtual-address '{{{ ILB_VIP }}}' traffic-group traffic-group-local-only
HOSTNAME=$(tmsh list sys global-setting hostname | sed -n '2p' | awk '{print $2}')
if [[ $HOSTNAME  == *"bigip-a"* ]]; then 
    tmsh create ltm rule irule_INGRESS-CONTROLLER when HTTP_REQUEST { HTTP::respond 200 content { OK } noserver Connection Close }
fi
tmsh create ltm virtual virt_INT-INGRESS-CONTROLLER destination '{{{ ILB_VIP }}}':443 profiles add { tcp http clientssl } rules { irule_INGRESS-CONTROLLER }
tmsh create ltm virtual virt_EXT-INGRESS-CONTROLLER destination '{{{ PRIVATE_VIP }}}':443 profiles add { tcp http clientssl } rules { irule_INGRESS-CONTROLLER }

# diable virtuals on standby unit
if [[ $HOSTNAME == *"bigip-b"* ]]; then 
    tmsh modify ltm virtual all disabled
fi
