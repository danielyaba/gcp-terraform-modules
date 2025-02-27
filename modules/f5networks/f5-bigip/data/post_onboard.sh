#!/bin/bash

mkdir /var/tmp/scripts/

# add failover scripts to failover files
cat <<'EOF' >>/config/failover/active
tmsh modify ltm virtual virt_EXT-INGRESS-CONTROLLER enabled
tmsh modify ltm virtual virt_INT-INGRESS-CONTROLLER enabled
EOF

cat <<'EOF' >>/config/failover/standby
tmsh modify ltm virtual virt_EXT-INGRESS-CONTROLLER disabled
tmsh modify ltm virtual virt_INT-INGRESS-CONTROLLER disabled
EOF

# create virtuals and irules for Google-Load-Balancers
tmsh create ltm virtual-address '{{{ ILB_VIP }}}' traffic-group traffic-group-local-only
HOSTNAME=$(tmsh list sys global-setting hostname | sed -n '2p' | awk '{print $2}')
if [[ $HOSTNAME == *"bigip-a"* ]]; then
  tmsh create ltm rule irule_INGRESS-CONTROLLER when HTTP_REQUEST { HTTP::respond 200 content { OK } noserver Connection Close }
fi
tmsh create ltm virtual virt_INT-INGRESS-CONTROLLER destination '{{{ ILB_VIP }}}':443 profiles add { tcp http clientssl } rules { irule_INGRESS-CONTROLLER } vlans add { vlan_EXTERNAL } vlans-enabled
tmsh create ltm virtual virt_EXT-INGRESS-CONTROLLER destination '{{{ PRIVATE_VIP }}}':443 profiles add { tcp http clientssl } rules { irule_INGRESS-CONTROLLER } vlans add { vlan_EXTERNAL } vlans-enabled

# diable virtuals on standby unit
if [[ $HOSTNAME == *"bigip-b"* ]]; then
  tmsh modify ltm virtual all disabled
fi

if [[ $HOSTNAME == *"bigip-a"* ]]; then
  # system hardening
  tmsh modify sys db ui.system.preferences.advancedselection value advanced
  tmsh modify sys db ui.system.preferences.recordsperscreen value 100

  # TCP Profiles
  tmsh create ltm profile tcp prof_F5_TCP_WAN_DDoS defaults-from f5-tcp-wan deferred-accept enabled syn-cookie-enable enabled zero-window-timeout 10000 idle-timeout 180 reset-on-timeout disabled

  # SSL Profiles
  tmsh create /ltm profile client-ssl clientssl-hard secure-renegotiation require-strict
  tmsh modify /ltm profile client-ssl clientssl-hard max-renegotiations-per-minute 3
  tmsh modify /ltm profile client-ssl clientssl-hard ciphers 'NATIVE:!NULL:!LOW:!EXPORT:!RC4:!DES:!3DES:!ADH:!DHE:!EDH:!MD5:!SSLv2:!SSLv3:!DTLSv1:@STRENGTH'

  # HTTP Profiles
  tmsh modify /ltm profile http http server-agent-name aws
  tmsh create /ltm profile http http-hard insert-xforwarded-for enabled enforcement { known-methods replace-all-with { GET HEAD POST PUT DELETE } unknown-method reject } hsts { mode enabled preload enabled }

  # Persistence Profiles
  tmsh modify /ltm persistence cookie cookie cookie-name "$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 10)"

  # SSHD
  tmsh modify /sys sshd inactivity-timeout 600

  # Banners
  tmsh modify /sys sshd banner enabled banner-text '"
    ******************************************************************************************
    *                                                                                        *
    *                                        WARNING!                                        *
    *                                                                                        *
    *             This is a private system. If you are not authorized to access              *
    *   this system, exit immediately. Unauthorized access to this system is forbidden by    *
    *                organization policies, national and international laws.                 *
    *                                                                                        *
    *             Unauthorized users are subject to criminal and civil penalties             *
    *              as well as organization initiated disciplinary proceedings.               *
    *                                                                                        *
    ******************************************************************************************
    "'
  tmsh modify /sys global-settings gui-security-banner enabled gui-security-banner-text '"WARNING!

    This is a private system. If you are not authorized to access this system, exit immediately.

    Unauthorized access to this system is forbidden by organization policies, national and international laws.

    Unauthorized users are subject to criminal and civil penalties as well as organization initiated disciplinary proceedings.
    "'

  # Logging
  tmsh modify /sys log-rotate max-file-size 10240

fi

# Aliases
echo -e "\n\n\n" >>~/.bashrc
echo \#---------- hardF5 ---------- >>~/.bashrc
echo alias t=\'tailf /var/log/ltm\' >>~/.bashrc
echo alias t1=\'tailf /var/log/apm\' >>~/.bashrc
echo alias t2=\'tailf /var/log/gtm\' >>~/.bashrc
echo alias t3=\'tailf /var/log/asm\' >>~/.bashrc
echo \#---------- EoF ----------- >>~/.bashrc
echo -e "\n\n\n" >>~/.bashrc

