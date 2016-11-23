# opsview-add-host
Add Windows server host via PowerShell/Opsview REST-API

The script is based on the resources from http://damirkasper.blogspot.de/2011/04/opsview-and-adding-hosts-through-rest.html.

You need a Host Group and a user/role with enough rights on this Host Group to add hosts to it. For determining the JSON-configuration-data-string I used the opsview_rest command on the opsview master.
