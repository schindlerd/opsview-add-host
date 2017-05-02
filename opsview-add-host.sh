#!/bin/bash
USERNAME_OPS="autoadduser"
PASSWORD_OPS="password"
OPSVIEW_URL="https://opsview.foo.bar"
HOSTGROUP="AutoAdd"
HOSTFILE="/tmp/opsview-add-host.tmp"
HOSTNAME=`hostname --fqdn | tr '[:lower:]' '[:upper:]'`
HOSTIP=`ip route get 1 | awk '{print $NF;exit}'`
TOKEN=`curl --silent  -d '{"username":"'$USERNAME_OPS'","password":"'$PASSWORD_OPS'"}' -H "Content-Type: application/json" -H "Accept: application/json" $OPSVIEW_URL/rest/login | cut -d: -f2 | cut -d} -f1  | cut -d'"' -f2`

cat > $HOSTFILE << EOF
{
         "name": "$HOSTNAME",
         "ip": "$HOSTIP",
         "hostgroup": {
           "name": "$HOSTGROUP",
         },
         "hosttemplates": [
          {
            "name": "OS - Unix Base"
          }
         ],
         "check_attempts" : "3",
         "check_command" : {
           "name" : "ping",
         },
         "check_interval" : "300",
         "retry_check_interval" : "10",
         "check_period" : {
            "name" : "24x7",
         },
         "notification_interval" : "3600",
         "notification_options" : "u,d,r",
         "notification_period" : {
            "name" : "24x7",
         },
         "flap_detection_enabled" : "1",
         "icon" : {
            "name" : "LOGO - Oracle Linux",
            "path" : "/images/logos/oracle-linux_small.png"
         },
}

EOF

curl --silent -H "Accept: application/json" -H "X-Opsview-Username: $USERNAME_OPS" -H "X-Opsview-Token: $TOKEN" -H "Content-Type: application/json" -X PUT -d "@$HOSTFILE" $OPSVIEW_URL/rest/config/host

