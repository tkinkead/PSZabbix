#Login handling functions

Function PSZabbix-GetLoginToken {
	Param(
    [Parameter(Mandatory=$False,Position=1)][PSCredential]$Credential,
	[Parameter(Mandatory=$True,Position=2)][string]$Server,
	[Parameter(Mandatory=$False,Position=3)][string]$PathToZabbixURLJSONRPCFile = "/zabbix/api_jsonrpc.php"
    )
	
	#If credential is not defined, prompt user for a credential
	If (!$Credential) {
		$Credential = Get-Credential
	}
	
	#If credential was supplied, confirm that it is a PSCredential object
	If ($Credential.GetType().FullName -ne "System.Management.Automation.PSCredential") {
		Write-Host "You must pass a PSCredential object to the -Credential parameter."
		Write-Host "Invoke the script without the -Credential parameter to be propmpted for credentials."
		Return
	}
	
	$header = @{"Content-Type" = "application/jsonrequest"}
	$body = '{
		"jsonrpc": "2.0",
		"method": "user.login",
		"params": {
			"user": "'+$Credential.UserName+'",
			"password": "'+$Credential.GetNetworkCredential().Password+'"
		},
		"id": 100,
		"auth": null
	}'
		
	$requestURI = "http://"+$Server+$PathToZabbixURLJSONRPCFile
	Try {
		$request = Invoke-WebRequest $requestURI -method POST -headers $header -Body $body -TimeoutSec 5
	}
	Catch {
		Write-Error $_.Exception.Message"...Terminating."
		Return
	}
	
	#If auth successful, result will be present in JSON output containing auth code
	If ( ($request.Content | ConvertFrom-Json).result ) {
		$authtoken = ($request.Content | ConvertFrom-Json).result
		Write-Verbose "Authentication successful, returning authtoken."
		Return $authtoken
	}
	#Otherwise login attempt failed, this should print the error message if available and return nothing
	Else {
		Write-Verbose "Login Failed...Error Message: "($request.Content | ConvertFrom-Json).Error.Data
		Return
	}
}

Function PSZabbix-DeleteLoginToken {
	Param(
    [Parameter(Mandatory=$False,Position=1)][string]$ZabbixToken,
	[Parameter(Mandatory=$True,Position=2)][string]$Server,
	[Parameter(Mandatory=$False,Position=3)][string]$PathToZabbixURLJSONRPCFile = "/zabbix/api_jsonrpc.php"
    )
	
	$header = @{"Content-Type" = "application/jsonrequest"}
	$body = '{
		"jsonrpc": "2.0",
		"method": "user.logout",
		"params": [],
		"id": 1,
		"auth": "'+$ZabbixToken+'"
		}'
	
	$requestURI = "http://"+$Server+$PathToZabbixURLJSONRPCFile
	Try {
		$request = Invoke-WebRequest $requestURI -method POST -headers $header -Body $body -TimeoutSec 5
	}
	Catch {
		Write-Error $_.Exception.Message"...Terminating."
		Return
	}
	
	If ( ($request.Content | ConvertFrom-Json).Result ) {
		If ( ($request.Content | ConvertFrom-Json).Result = "True") {
			Return $True
		}
		Else {
			Return $False
		}
	}
	Else {
		Return $False
	}
	
}

#HostGroup functions

Function PSZabbix-GetHostGroupID {
    Param(	
	[Parameter(Mandatory=$True,Position=1)][string]$HostGroupName,
	[Parameter(Mandatory=$False,Position=2)][PSCredential]$Credential,
	[Parameter(Mandatory=$True,Position=3)][string]$Server,
	[Parameter(Mandatory=$False,Position=4)][string]$PathToZabbixURLJSONRPCFile = "/zabbix/api_jsonrpc.php"
	)
	
	#If credential is not defined, prompt user for a credential
	If (!$Credential) {
		$Credential = Get-Credential
	}
	
	#If credential was supplied, confirm that it is a PSCredential object
	If ($Credential.GetType().FullName -ne "System.Management.Automation.PSCredential") {
		Write-Host "You must pass a PSCredential object to the -Credential parameter."
		Write-Host "Invoke the script without the -Credential parameter to be propmpted for credentials."
		Return
	}
	
	$header = @{"Content-Type" = "application/jsonrequest"}
	$authtoken = PSZabbix-GetLoginToken -Server $Server -Credential $Credential
	
	$body = '{
		"jsonrpc": "2.0",
		"method": "hostgroup.get",
		"params": {
			"output": "extend",
			"filter": {
				"name": [
					"'+$HostGroupName+'"
				]
			}
		},
		"auth": "'+$authtoken+'",
		"id": 1
		}'

	$requestURI = "http://"+$Server+$PathToZabbixURLJSONRPCFile
	Try {
		$request = Invoke-WebRequest $requestURI -method POST -headers $header -Body $body -TimeoutSec 5
	}
	Catch {
		Write-Error $_.Exception.Message"...Terminating."
		Return
	}
		
	$groupid = ($request.Content | ConvertFrom-Json).result.groupid
	If ( !($groupid) ) {
		Write-Verbose ""
		Return $False
		}	
	Return $groupid
}

Function PSZabbix-CreateHostGroup {
	Param(	
	[Parameter(Mandatory=$True,Position=1)][string]$HostGroupName,
	[Parameter(Mandatory=$False,Position=2)][PSCredential]$Credential,
	[Parameter(Mandatory=$True,Position=3)][string]$Server,
	[Parameter(Mandatory=$False,Position=4)][string]$PathToZabbixURLJSONRPCFile = "/zabbix/api_jsonrpc.php"
	)
	
	#If credential is not defined, prompt user for a credential
	If (!$Credential) {
		$Credential = Get-Credential
	}
	
	#If credential was supplied, confirm that it is a PSCredential object
	If ($Credential.GetType().FullName -ne "System.Management.Automation.PSCredential") {
		Write-Host "You must pass a PSCredential object to the -Credential parameter."
		Write-Host "Invoke the script without the -Credential parameter to be propmpted for credentials."
		Return
	}
	
	$header = @{"Content-Type" = "application/jsonrequest"}
	$authtoken = PSZabbix-GetLoginToken -Server $Server -Credential $Credential
	
	$body = '{
		"jsonrpc": "2.0",
		"method": "hostgroup.create",
		"params": {
			"name": "'+$HostGroupName+'"
		},
		"auth": "'+$authtoken+'",
		"id": 1
	}'

	$requestURI = "http://"+$Server+$PathToZabbixURLJSONRPCFile
	Try {
		$request = Invoke-WebRequest $requestURI -method POST -headers $header -Body $body -TimeoutSec 5
	}
	Catch {
		Write-Error $_.Exception.Message"...Terminating."
		Return
	}
	
	#Return group ID.  If no group ID is found, nothing will be returned.
	$groupid = ($request.Content | ConvertFrom-Json).result.groupids
	Return $groupid
}

Function PSZabbix-DeleteHostGroup {
	Param(	
	[Parameter(Mandatory=$True,Position=1)][string]$HostGroupID,
	[Parameter(Mandatory=$False,Position=2)][PSCredential]$Credential,
	[Parameter(Mandatory=$True,Position=3)][string]$Server,
	[Parameter(Mandatory=$False,Position=4)][string]$PathToZabbixURLJSONRPCFile = "/zabbix/api_jsonrpc.php"
	)
	
	#If credential is not defined, prompt user for a credential
	If (!$Credential) {
		$Credential = Get-Credential
	}
	
	#If credential was supplied, confirm that it is a PSCredential object
	If ($Credential.GetType().FullName -ne "System.Management.Automation.PSCredential") {
		Write-Host "You must pass a PSCredential object to the -Credential parameter."
		Write-Host "Invoke the script without the -Credential parameter to be propmpted for credentials."
		Return
	}
	
	$header = @{"Content-Type" = "application/jsonrequest"}
	$authtoken = PSZabbix-GetLoginToken -Server $Server -Credential $Credential
	
	$body = '{
		"jsonrpc": "2.0",
		"method": "hostgroup.delete",
		"params": [
			"'+$HostGroupID+'"
		],
		"auth": "'+$authtoken+'",
		"id": 1
	}'

	$requestURI = "http://"+$Server+$PathToZabbixURLJSONRPCFile
	Try {
		$request = Invoke-WebRequest $requestURI -method POST -headers $header -Body $body -TimeoutSec 5
	}
	Catch {
		Write-Error $_.Exception.Message"...Terminating."
		Return
	}
		
    $request

	#Return true if group ID was deleted, return false otherwise
	$groupid = ($request.Content | ConvertFrom-Json).result.groupids
	If ( $groupid ) {
		Return $True
	}
	Else {
		Return $False
	}
}

#Host functions

Function PSZabbix-CreateHost {
	Param(
		[Parameter(Mandatory=$True,Position=1)][string]$HostName,
		[Parameter(Mandatory=$True,Position=2)][string]$HostGroup,
		[Parameter(Mandatory=$False,Position=3)][ipaddress]$IPAddress,
		[Parameter(Mandatory=$False,Position=4)][string]$DNSName,
		[Parameter(Mandatory=$False,Position=5)][string]$ZabbixServer,
		[Parameter(Mandatory=$False,Position=6)][PSCredential]$Credential
		[Parameter(Mandatory=$False,Position=7)][boolean]$UseIP = $True
		[Parameter(Mandatory=$False,Position=8)][string]$PathToZabbixURLJSONRPCFile = "/zabbix/api_jsonrpc.php"
		)

	#If credential is not defined, prompt user for a credential
	If (!$Credential) {
		$Credential = Get-Credential
	}
	
	#If credential was supplied, confirm that it is a PSCredential object
	If ($Credential.GetType().FullName -ne "System.Management.Automation.PSCredential") {
		Write-Host "You must pass a PSCredential object to the -Credential parameter."
		Write-Host "Invoke the script without the -Credential parameter to be propmpted for credentials."
		Return
	}
	
	#If neither IPAddress or DNSName are supplied, exit
	If ( !($IPAddress) -and !($DNSName) ) {
		Write-Error "Either an IP address or a DNSName must be supplied." 
		Return
	}
		
	#If DNSName is supplied and IP address is not, change $UseIP to $False, set IP address to default
	If ( $DNSName -and !($IPAddress) ) {
		$UseIP = $False
		$IPAddress = "0.0.0.0"
	}
	
	#If DNSName is not specified, use Hostname as DNSName
	If (!$DNSName) {$DNSName = $Hostname}
	
	#Convert $UseIP to 0 or 1
	If ($UseIP -eq $True) {
		$UseIP = "1"
	}
	If ($UseIP -eq $False) {
		$UseIP = "0"
	}	
	
	$header = @{"Content-Type" = "application/jsonrequest"}
	$authtoken = PSZabbix-GetLoginToken -Server $Server -Credential $Credential
	$groupid = PSZabbix-GetHostGroupID -Server $Server -Credential $Credential -HostGroupName $HostGroup
	 
	
	$body = '{
		"jsonrpc": "2.0",
		"method": "host.create",
		"params": {
			"host": "'+$Hostname+'",
			"interfaces": [
				{
					"type": 1,
					"main": 1,
					"useip": '+$UseIP+',
					"ip": "'+$IPAddress.ToString+'",
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
	 
	$requestURI = "http://"+$Server+$PathToZabbixURLJSONRPCFile
	Try {
		$request = Invoke-WebRequest $requestURI -method POST -headers $header -Body $body -TimeoutSec 5
	}
	Catch {
		Write-Error $_.Exception.Message"...Terminating."
		Return
	}
	
	If ( ($request.Content | ConvertFrom-Json).result.hostids ) {
		$hostid = ($request.Content | ConvertFrom-Json).result.hostids
		Write-Verbose "Host added, returning host ID."
		Return $hostid
	}
	#Otherwise login attempt failed, this should print the error message if available and return nothing
	Else {
		Write-Verbose "Login Failed...Error Message: "($request.Content | ConvertFrom-Json).Error.Data
		Return
	}

}

Function PSZabbix-GetHostID {

}

Function PSZabbix-GetHostInfo {

}

Function PSZabbix-GetHostGroupsForHost {

}

Function PSZabbix-DeleteHostByID {

}

Function PSZabbix-DeleteHostByName {

}