<# 
    .SYNOPSIS 
        A script to add newly installed Windows server hosts to Opsview via its REST-API. 
    .DESCRIPTION 
        This script will add a newly installed Windows server host to Opsview via its REST-API. Communication from the Windows host to Opsview via port 443 (HTTPS) has to be allowed.
        
        The basic server metrics will be monitored via WMI.
    .PARAMETER server 
        Set Opsview hostname to register at. 
         
        The default value is "opsview.domain.de". 
    .PARAMETER user
        Set Opsview username to use for registration.
        
        The default value is "autoadduser".
    .PARAMETER pass 
        Set Opsview username's password to use for registration. 
         
        The default value is "password".
    .PARAMETER hostname 
        Set name of host object in Opsview. 
         
        The default value is the auto-detected FQDN from DNS resolution via a .Net class in the format HOSTNAME.DOMAIN.TLD.
     .PARAMETER hostip 
        Set IP address of host object in Opsview. 
         
        The default value is auto-detected via ipconfig command.
     .PARAMETER hostgroup 
        Set Opsview hostgroup where host shall be registered to. 
         
        The default value is "AutoAdd".
    .EXAMPLE 
        .\opsview-add-host.ps1 -server opsview.domain.de -user autoadduser -pass password -hostname winserver.domain.de -hostip 10.70.100.12 -hostgroup AutoAdd 
         
        Description 
        ----------- 
        This example shows how to run the script with all parameters set.
    .EXAMPLE 
        powershell.exe -noprofile -executionpolicy bypass -file C:\Temp\opsview-add-host.ps1 
         
        Description 
        ----------- 
        This example shows how to bypass PowerShell execution policy and run script with default parameters. 
    .NOTES 
        ScriptName : opsview-add-host.ps1 
        Created By : Daniel Schindler 
        Date Coded : 2016-11-29 
  
        Features:
        - check OS-version (Windows Server 2008/2012) depending on Host-Template
        - detect FQDN via .Net Class and use as Opsview-Host-Object-Name if not set via argument
        - detect IP if not set via argument
    .LINK 
        http://damirkasper.blogspot.de/2011/04/opsview-and-adding-hosts-through-rest.html 
    .LINK 
        https://github.com/schindlerd/opsview-add-host 
#> 
#requires -version 2.0
	
# CHANGELOG:
# 1.3  2016-12-16 - added Windows Server 2016 support
# 1.2  2016-12-06 - added Get-Help header information
# 1.1  2016-12-03 - hostgroup parameter added
#                 - hostdata more generalized
# 1.0  2016-11-29 - initial version
#
#################################################################################
# Copyright (C) 2016 Daniel Schindler, daniel.schindler@steag.com
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
#################################################################################

### Set param default values to your environment if not set via arguments.
### Hostname e.g. is set to FQDN from DNS if not set because our Opsview hosts are named like their FQDN names.
param (
    [string]$server = "opsview.domain.de",
    [string]$user = "autoadduser",
    [string]$pass = "password",
    [string]$hostname = [System.Net.Dns]::GetHostEntry([string]$env:computername).HostName,
    [string]$hostip = ((ipconfig | findstr [0-9].\.)[0]).Split()[-1],
    [string]$hostgroup = "AutoAdd"
)

### URLs for authentication and config
$urlauth = "https://$server/rest/login"
$urlconfig = "https://$server/rest/config/host"

### JSON formated body string with credentials
$creds = '{"username":"' + $user + '","password":"' + $pass + '"}'

### Get auth token
$bytes1 = [System.Text.Encoding]::ASCII.GetBytes($creds)
$web1 = [System.Net.WebRequest]::Create($urlauth)
$web1.Method = "POST"
$web1.ContentLength = $bytes1.Length
$web1.ContentType = "application/json"
$web1.ServicePoint.Expect100Continue = $false
$stream1 = $web1.GetRequestStream()
$stream1.Write($bytes1,0,$bytes1.Length)
$stream1.Close()

$reader1 = New-Object System.IO.Streamreader -ArgumentList $web1.GetResponse().GetResponseStream()
$token1 = $reader1.ReadToEnd()
$reader1.Close()

### Parse Token for follwoing sessions
$token1=$token1.Replace("{`"token`":`"", "")
$token1=$token1.Replace("`"}", "")

### OS version
$osversion = (Get-WmiObject Win32_OperatingSystem).Caption
Write-Host $osversion

### JSON format hostdata like hosttemplate, servicechecks etc.
### Check if it is Windows Server 2008/2012/2016
if ($osversion -like "*2008*") {
    $hostdata = '{"object":{"hosttemplates":[{"name":"OS - Windows Server 2008 WMI - Base"}],"flap_detection_enabled":"1","check_period":{"name":"24x7"},"check_attempts":"3","check_interval":"300","hostattributes":[{"value":"wincreds","name":"WINCREDENTIALS"}],"notification_period":{"name":"24x7"},"notification_options":"u,d,r","name":"' + $hostname + '","hostgroup":{"name":"' + $hostgroup + '"},"monitored_by":{"name":"Master Monitoring Server"},"icon":{"name":"LOGO - Windows","path":"/images/logos/windows_small.png"},"retry_check_interval":"10","ip":"' + $hostip + '","check_command":{"name":"ping"}}}'
}
elseif ($osversion -like "*2012*") {
    $hostdata = '{"object":{"hosttemplates":[{"name":"OS - Windows Server 2012 WMI - Base"}],"flap_detection_enabled":"1","check_period":{"name":"24x7"},"check_attempts":"3","check_interval":"300","hostattributes":[{"value":"wincreds","name":"WINCREDENTIALS"}],"notification_period":{"name":"24x7"},"notification_options":"u,d,r","name":"' + $hostname + '","hostgroup":{"name":"' + $hostgroup + '"},"monitored_by":{"name":"Master Monitoring Server"},"icon":{"name":"LOGO - Windows","path":"/images/logos/windows_small.png"},"retry_check_interval":"10","ip":"' + $hostip + '","check_command":{"name":"ping"}}}'
}
elseif ($osversion -like "*2016*") {
    $hostdata = '{"object":{"hosttemplates":[{"name":"OS - Windows Server 2016 WMI - Base"}],"flap_detection_enabled":"1","check_period":{"name":"24x7"},"check_attempts":"3","check_interval":"300","hostattributes":[{"value":"wincreds","name":"WINCREDENTIALS"}],"notification_period":{"name":"24x7"},"notification_options":"u,d,r","name":"' + $hostname + '","hostgroup":{"name":"' + $hostgroup + '"},"monitored_by":{"name":"Master Monitoring Server"},"icon":{"name":"LOGO - Windows","path":"/images/logos/windows_small.png"},"retry_check_interval":"10","ip":"' + $hostip + '","check_command":{"name":"ping"}}}'
}
else {
    Write-Host "Unsupported OS! - Now exiting..."
    break
}

### Use token and add host to Opsview
$bytes2 = [System.Text.Encoding]::ASCII.GetBytes($hostdata)
$web2 = [System.Net.WebRequest]::Create($urlconfig)
$web2.Method = "PUT"
$web2.ContentLength = $bytes2.Length
$web2.ContentType = "application/json"
$web2.ServicePoint.Expect100Continue = $false
$web2.Headers.Add("X-Opsview-Username","$user")
$web2.Headers.Add("X-Opsview-Token",$token1);
$stream2 = $web2.GetRequestStream()
$stream2.Write($bytes2,0,$bytes2.Length)
$stream2.Close()

$reader2 = New-Object System.IO.Streamreader -ArgumentList $web2.GetResponse().GetResponseStream()
$output2 = $reader2.ReadToEnd()
$reader2.Close()

Write-Host $output2
