#!/usr/bin/python

# PURPOSE:
# Small python script to add Oracle Linux host to Opsview.
#
# CHANGELOG:
# 1.0  2017-05-02 - initial release (Happy Birthday Adam!)
#
################################################################################
# Copyright (C) 2017 Daniel Schindler, daniel.schindler@steag.com
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, see <http://www.gnu.org/licenses>.
################################################################################

import os
import sys
import json
import socket
import urllib
import urllib2
import argparse
import commands

# Script options.
parser = argparse.ArgumentParser()
parser.add_argument("--url", help="Opsview server URL.", nargs="?", const="https://opsview.foo.bar/", default="https://opsview.foo.bar/")
parser.add_argument("--user", help="Opsview username.", nargs="?", const="autoadduser", default="autoadduser")
parser.add_argument("--password", help="Opsview password.", nargs="?", const="password", default="password")
parser.add_argument("--hostname", help="Opsview new host object hostname.")
parser.add_argument("--hostip", help="Opsview new host object IP address.")
parser.add_argument("--hostgroup", help="Opsview hostgroup.", nargs="?", const="AutoAdd", default="AutoAdd")
args = parser.parse_args()

# Set main variables.
opsview_url = args.url
opsview_user = args.user
opsview_password = args.password
opsview_hostgroup = args.hostgroup

# Check hostname/hostip args and set to autodetected values if empty.
if None in [args.hostname]:
    opsview_hostname = socket.gethostname()
else:
    opsview_hostname = args.hostname

if None in [args.hostip]:
    opsview_hostip = socket.gethostbyname(socket.getfqdn())
    if "127.0.0.1" in [opsview_hostip]:
        opsview_hostip = commands.getoutput("ip route get 1 | awk '{print $NF;exit}'")
else:
    opsview_hostip = args.hostip

# Connect to Opsview to retreive auth_token.
opsview_cookies = urllib2.HTTPCookieProcessor()
opsview_opener = urllib2.build_opener(opsview_cookies)

connect_opsview = opsview_opener.open(
  urllib2.Request(opsview_url + "rest/login",
    urllib.urlencode(dict({'username': opsview_user, 'password': opsview_password}))
  )
)

response_text = connect_opsview.read()
response = eval(response_text)

# Check Opsview response.
if not response:
    print("Cannot evaluate %s" % response_text)
    sys.exit()

if "token" in response:
    print("Opsview authentication succeeded")
    print("Token: %s" % response["token"])
    opsview_token = response["token"]
    print("Host Object Name : %s" % opsview_hostname)
    print("Host Object IP   : %s" % opsview_hostip)
    print("Host Object Group: %s" % opsview_hostgroup)
else:
    print("Opsview authentication FAILED")
    sys.exit(1)

# Fetch server info.
url = opsview_url + "rest/serverinfo"
headers = {
    "Content-Type": "application/json",
    "X-Opsview-Username": opsview_user,
    "X-Opsview-Token": opsview_token,
}
request = urllib2.Request(url, None, headers)
#print opsview_opener.open(request).read()

# New host object info in JSON format.
host = json.dumps({
    "name": opsview_hostname,
    "ip": opsview_hostip,
    "hostgroup": {"name": opsview_hostgroup},
    "hosttemplates": [{"name": "OS - Unix Base"}],
    "check_attempts" : "3",
    "check_interval" : "300",
    "check_period": {"name" : "24x7"},
    "check_command": {"name": "ping"},
    "retry_check_interval" : "10",
    "flap_detection_enabled" : "1",
    "notification_options" : "u,d,r",
    "notification_period" : {"name" : "24x7"},
    "icon": {
        "name": "LOGO - Oracle Linux",
        "path": "/images/logos/oracle-linux_small.png"
    }
})

# API link and headers.
url = opsview_url + "rest/config/host"
headers = {
    "Content-Type": "application/json",
    "X-Opsview-Username": opsview_user,
    "X-Opsview-Token": opsview_token,
}

# Add host to Opsview.
request = urllib2.Request(url, host, headers)
try:
    connect_opsview = opsview_opener.open(request)
except urllib2.URLError, e:
    print("Could not add host. %s: %s" % (e.code, e.read()))
    could_not_add_host = True

# Debugging.
#print connect_opsview.read()
