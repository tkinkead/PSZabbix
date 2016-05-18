Function PSZabbix-CreateHost {
	Param(
		[Parameter(Mandatory=$True,Position=1)][string]$Hostname,
		[Parameter(Mandatory=$True,Position=2)][string]$ZabbixGroup,
		[Parameter(Mandatory=$False,Position=3)][string]$IPAddress,
		[Parameter(Mandatory=$False,Position=4)][string]$DNSName,
		[Parameter(Mandatory=$False,Position=5)][string]$ZabbixServer,
		[Parameter(Mandatory=$False,Position=6)][PSCredential]$Credential
		)

	$authtoken = PSZabbix-GetLoginToken -Server $ZabbixServer 
		
	$body = '{
		"jsonrpc": "2.0",
		"method": "hostgroup.get",
		"params": {
			"output": "extend",
			"filter": {
				"name": [
					"'+$ZabbixGroup+'"
				]
			}
		},
		"auth": "'+$authtoken+'",
		"id": 1
	}'
	$request = Invoke-WebRequest http://10.64.104.171/zabbix/api_jsonrpc.php -method POST -headers $header -Body $body
	$groupid = ($request.Content | ConvertFrom-Json).result.groupid
	 
	If ($IPAddress) {$useip = '1'}
	Else {$useip = '0'; $IPAddress = "0.0.0.0"}
	 
	If (!$DNSName) {$DNSName = $Hostname}
	 
	$body = '{
		"jsonrpc": "2.0",
		"method": "host.create",
		"params": {
			"host": "'+$Hostname+'",
			"interfaces": [
				{
					"type": 1,
					"main": 1,
					"useip": '+$useip+',
					"ip": "'+$IPAddress+'",
					"dns": "'+$DNSName+'",
					"port": "10050"
				}
			],
			"groups": [
				{
					"groupid": "'+$groupid+'"
				}
			]
		},
		"auth": "'+$authtoken+'",
		"id": 1
	}'
	 
	$request = Invoke-WebRequest http://10.64.104.171/zabbix/api_jsonrpc.php -method POST -headers $header -Body $body
	$Hostname + "   " + $request.Content

}

Function PSZabbix-GetHost {

}

Function PSZabbix-DeleteHostGroup {

}