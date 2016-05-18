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

Function PSZabbix-GetHost {

}

Function PSZabbix-DeleteHostGroup {

}