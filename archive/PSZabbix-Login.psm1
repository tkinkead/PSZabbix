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