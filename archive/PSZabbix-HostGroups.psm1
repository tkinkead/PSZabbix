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
