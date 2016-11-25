# opsview-add-host
Add Windows server host via PowerShell/Opsview REST-API

The script is based on the resources from http://damirkasper.blogspot.de/2011/04/opsview-and-adding-hosts-through-rest.html.
The issue with the script provided there was that the .NET client/PowerShell set the expect header and only send the request headers before a POST of data. This allows the server to respond with errors/redirects/security violations prior to the client sending the request body. The client does not wait until it gets a response and just pushes out the body of the request, which results in a 417 expectation error on my apache 2.2 and requesting the auth token failed. I resolved by disabling the expect header via "ServicePoint.Expect100Continue" property.

## Requirements
You need a Host Group and a user/role with enough rights on this Host Group to add hosts to it. For determining the JSON-configuration-data-string I used the opsview_rest command on the opsview master.

## Miscellaneous
- Bypass Powershell Execution Policy and execute script like - *powershell.exe -noprofile -executionpolicy bypass -file C:\Temp\opsview-add-host.ps1* 
