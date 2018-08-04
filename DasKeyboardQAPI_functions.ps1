<#
PowerShell wrapper for the Das Keyboard Q API.

#Das Keyboard Q API Docs
https://github.com/DasKeyboard/Daskeyboard.io/blob/master/q-api-doc.md

.NOTES 
	Author: John Milner / jfrmilner
	Blog  : http://jfrmilner.wordpress.com 
	Legal: This script is provided "AS IS" with no warranties or guarantees, and confers no rights. You may use, modify, reproduce, and distribute this script file in any way provided that you agree to give the original author credit.
#>

function Get-DasQClientCredentials {
<#
  .SYNOPSIS
  Support function that loads and creates API credentails
  .NOTES
  to be hidden on module version

#>
	param (
	)

	begin {
		if (!(Test-Path ~\dasq.cred)) {

		Write-Host -ForegroundColor Yellow "To use Cloud Signals you are required to populate the below Client ID and Client Secret from at https://q.daskeyboard.com/account"
		$username = Read-Host "Client ID"
		$password = Read-Host "Client Secret" -AsSecureString
		try {
			$oauth2Credentials = New-Object -TypeName System.Management.Automation.PSCredential($username, $password)
			#Export credentials to C:\Users\<username>\dasq.cred
			$oauth2Credentials | Export-Clixml ~\dasq.cred
			$script:clientId = $oauth2Credentials.UserName
			$script:clientSecret = $oauth2Credentials.GetNetworkCredential().password
			}
		catch {
			$Error[0].Exception
		}

		}
		else {
			Write-Host -ForegroundColor Green -Object "Importing Cached Credentials"
			try {
				$oauth2Credentials = Import-Clixml ~\dasq.cred   
				$oauth2Credentials = New-Object System.Management.Automation.PSCredential($oauth2Credentials.username, $oauth2Credentials.password)
				$script:clientId = $oauth2Credentials.UserName
				$script:clientSecret = $oauth2Credentials.GetNetworkCredential().password
			}
			catch {
				$Error[0].Exception
			}
		}
		#todo - on error exception of bad creds provide option to reenter 
		#Remove-Item "~\dasq.cred" -Confirm
		}#begin 
	process {
		}#process 
	end {
		}#end 
}


function Get-DasQAuthToken {
<#
  .SYNOPSIS
  Supporting function for cloud authentication. Obtain Client ID and Secret from https://q.daskeyboard.com/account.
#>

param(
		[Parameter(Mandatory = $true)]
        [String] 
        $clientId
    ,
		[Parameter(Mandatory = $true)]
        [String]
		$clientSecret
	)

	$tokenEndpoint = "https://q.daskeyboard.com/oauth/1.4/token"

	$requestHashtable = @{
		"client_id" = $clientId
		"client_secret" = $clientSecret
		"grant_type"="client_credentials"
		}

	$requestJSON = $requestHashtable | ConvertTo-Json
 	$response = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $requestJSON -ContentType 'application/json'
	$script:accessToken = $response.access_token
	$script:refreshToken = $response.refresh_token
	$script:expiryDateTimeToken = $((Get-Date).AddSeconds($response.expires_in)) #expires_in default value is 24 hours (86400 seconds).
}

  
function Send-DasQSignal {
<#
  .SYNOPSIS
  Send Signal from DAS Keyboard Q Local\Cloud API
  .EXAMPLE
  Send-DasQSignal -Name "Local Test Name" -Key KEY_L -Colour Green -Effect BLINK -Message "Local Test Message" -Endpoint Local
  .EXAMPLE
  Send-DasQSignal -Name "Cloud Test Name" -Key KEY_C -Colour Blue -Effect BLINK -Message "Cloud Test Message" -Endpoint Cloud
  .EXAMPLE
  65..90 | % { Send-DasQSignal -Name "Local Test Name KEY_$([char]$_)" -Key "KEY_$([char]$_)" -Colour Red -Effect BLINK -Endpoint Local -shouldNotify $false }
  
  Set all letter keys (A-Z) to Flashing Red (Red Alert!)
  .NOTES
  Author: jfrmilner
#>
    param(

        [ValidateSet("KEY_ESCAPE","KEY_F1","KEY_F2","KEY_F3","KEY_F4","KEY_F5","KEY_F6","KEY_F7","KEY_F8","KEY_F9","KEY_F10","KEY_F11","KEY_F12","KEY_PRINT_SCREEN","KEY_SCROLL_LOCK","KEY_PAUSE_BREAK","KEY_MACRO_1","KEY_MACRO_2","KEY_MACRO_3","KEY_BACKTICK","KEY_1","KEY_2","KEY_3","KEY_4","KEY_5","KEY_6","KEY_7","KEY_8","KEY_9","KEY_0","KEY_SUBTRACT","KEY_EQUAL","KEY_BACKSPACE","KEY_INSERT","KEY_HOME","KEY_PAGE_UP","KEY_NUMLOCK","KEY_NUMPAD_DIVIDE","KEY_NUMPAD_MULTIPLY","KEY_NUMPAD_SUBTRACT","KEY_TAB","KEY_Q","KEY_W","KEY_E","KEY_R","KEY_T","KEY_Y","KEY_U","KEY_I","KEY_O","KEY_P","KEY_OPEN_SQUARE_BRACKET","KEY_CLOSE_SQUARE_BRACKET","KEY_BACKSLASH","KEY_DELETE","KEY_END","KEY_PAGE_DOWN","KEY_NUMPAD_7","KEY_NUMPAD_8","KEY_NUMPAD_9","KEY_NUMPAD_ADD","KEY_CAPS_LOCK","KEY_A","KEY_S","KEY_D","KEY_F","KEY_G","KEY_H","KEY_J","KEY_K","KEY_L","KEY_SEMICOLON","KEY_QUOTE","KEY_ENTER","KEY_NUMPAD_4","KEY_NUMPAD_5","KEY_NUMPAD_6","KEY_SHIFT_LEFT","KEY_Z","KEY_X","KEY_C","KEY_V","KEY_B","KEY_N","KEY_M","KEY_COMMA","KEY_DOT","KEY_SLASH","KEY_SHIFT_RIGHT","KEY_ARROW_UP","KEY_NUMPAD_1","KEY_NUMPAD_2","KEY_NUMPAD_3","KEY_CONTROL_LEFT","KEY_META_LEFT","KEY_ALT_LEFT","KEY_SPACE","KEY_ALT_RIGHT","KEY_FN_KEY","KEY_META_RIGHT","KEY_CONTROL_RIGHT","KEY_ARROW_LEFT","KEY_ARROW_DOWN","KEY_ARROW_RIGHT","KEY_NUMPAD_0","KEY_NUMPAD_DECIMAL","KEY_NUMPAD_ENTER","KEY_VOLUME_Q_BUTTON","KEY_LIGHT_PIPE_LEFT","KEY_LIGHT_PIPE_RIGHT")]
		$Key = "KEY_SPACE"
		# If no key is specified this perimeter will default to the Space Bar key
	,
		[ValidateSet("WHITE", "SILVER", "GRAY", "BLACK", "RED", "ORANGE", "YELLOW", "OLIVE", "LIME", "GREEN", "AQUA", "TEAL", "BLUE", "NAVY", "FUCHSIA", "PURPLE")]
		$Colour = ("RED", "GREEN", "BLUE" | Get-Random)
		# If no colour is specified this perimeter make a random colour selection (Red, Green, Blue)
    , 
        [ValidateSet("SET_COLOR","BLINK","BREATHE","COLOR_CYCLE","RIPPLE","INWARD_RIPPLE","BOUNCING_LIGHT","LASER","WAVE")]
        $Effect = "BLINK"
		#https://q.daskeyboard.com/api/1.0/DK5QPID/effects
    ,
		[String]
		[ValidateSet("Local", "Cloud")]
		$Endpoint = "Local"
		# Select API Endpoint
	,	
		[ValidateSet($true, $false)]
		$isRead = $false
	,
		[ValidateSet($true, $false)]
		$isArchived = $false
	,
		[ValidateSet($true, $false)]
		$isMuted = $false
	,
		[String]
		$Message = ""
		# Signal Message Text. If no message text is send this will not create an alert in the Das Keyboard Q Desktop Client
	,
        [String] 
        $Name = ""

		
    )
begin {
	$colours = @{
		"WHITE" = "#FFFFFF"
		"SILVER" = "#C0C0C0"
		"GRAY" = "#808080"
		"BLACK" = "#000000"
		"RED" = "#FF0000"
		"ORANGE" = "#FFA500"
		"YELLOW" = "#FFFF00"
		"OLIVE" = "#808000"
		"LIME" = "#00FF00"
		"GREEN" = "#008000"
		"AQUA" = "#00FFFF"
		"TEAL" = "#008080"
		"BLUE" = "#0000FF"
		"NAVY" = "#000080"
		"FUCHSIA" = "#FF00FF"
		"PURPLE" = "#800080"
	}
	
	$signalHashtable = @{
		name = $Name
		pid = "DK5QPID"
		zoneId = $Key
		color = $colours.$($Colour)
		effect = $Effect
		isRead = $isRead
		isArchived = $isArchived
		isMuted = $isMuted
		message = $Message
	}
	

	
	
	}#begin 
process {

	try {
		if ($Endpoint -eq "Cloud") {
			if (!$accessToken -or $script:expiryDateTimeToken -lt (Get-Date)) {
				Get-DasQClientCredentials
				Get-DasQAuthToken -clientId $clientId -clientSecret $clientSecret
			}
		$headers = @{"Authorization"="Bearer $($accessToken)"}
		$aPIEndpoint = 'https://q.daskeyboard.com/api/1.0/'
		}
		else {
			$headers = $null
			$aPIEndpoint = 'http://localhost:27301/api/1.0/'
			#https://qforum.daskeyboard.com/t/local-api-calls-not-working/2208/4
			if (!$signalHashtable.isMuted) {
				$signalHashtable.Add("shouldNotify",  $false)
			}
            $signalHashtable.Remove("isMuted")
            $signalHashtable.Remove("isArchived")
            $signalHashtable.Remove("isRead")
		}
		Invoke-RestMethod -Uri ($aPIEndpoint+'signals') -Headers $headers -Method Post -Body $signalHashtable
	 }
	catch {
		$Error[0].Exception
	 }
	finally {
	 }
	 
	}#process 
end {
	}#end 
}


function Get-DasQSignal { 
<#
  .SYNOPSIS
  Get Signal from DAS Keyboard Q Local API
  .EXAMPLE
  Get-DasQSignal
  .EXAMPLE
  Get-DasQSignal -Endpoint Cloud
  .NOTES
  Local\Cloud API Only
  Author: jfrmilner

#>
    param(
		[String]
		[ValidateSet("Local", "Cloud")]
		$Endpoint = "Local"
		# Select API Endpoint
    )
	
begin {
	}#begin 
process {

		try {
			if ($Endpoint -eq "Cloud") {
				if (!$accessToken -or $script:expiryDateTimeToken -lt (Get-Date)) {
					Get-DasQClientCredentials
					Get-DasQAuthToken -clientId $clientId -clientSecret $clientSecret
				}
			$headers = @{"Authorization"="Bearer $($accessToken)"}
			$aPIEndpoint = 'https://q.daskeyboard.com/api/1.0/'
			$signals = Invoke-RestMethod -Uri ($aPIEndpoint+'signals') -Headers $headers -Method Get
			$signals = $signals.content
			}
			else {
				$headers = $null
				$aPIEndpoint = 'http://localhost:27301/api/1.0/'
				$signals = Invoke-RestMethod -Uri ($aPIEndpoint+'signals/shadows') -Headers $headers -Method Get
			}
			
		 }
		catch {
			$Error[0].Exception
		 }
		finally {
		 }

	}#process 
end {
	$script:unixEpochStart = New-Object DateTime 1970,1,1,0,0,0,([DateTimeKind]::Utc)
	$signals | Add-Member -Name updatedAtDateTime -MemberType ScriptProperty -Value {$unixEpochStart.AddMilliseconds($this.updatedAt)} -PassThru
	}#end
}


function Remove-DasQSignal {
<#
  .SYNOPSIS
  Remove Signal from DAS Keyboard Q Local\Cloud API
  .EXAMPLE
  Remove-DasQSignal -id '-123'
  .EXAMPLE
  #Remove all messages using the pipeline 
  Get-DasQSignal | Remove-DasQSignal
  
  Remove all messages using the pipeline
  .NOTES
  Author: jfrmilner

#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory,ValueFromPipelineByPropertyName)]
		$id
		# Signal id
	,
		[parameter(ValueFromPipelineByPropertyName)]
		$clientName
		# Signal clientname
	)

begin {
	}#begin 
process {
		
		try {
			if ($clientName -ne 'PublicApi') {
				if (!$accessToken -or $script:expiryDateTimeToken -lt (Get-Date)) {
					Get-DasQClientCredentials
					Get-DasQAuthToken -clientId $clientId -clientSecret $clientSecret
				}
			$headers = @{"Authorization"="Bearer $($accessToken)"}
			$aPIEndpoint = 'https://q.daskeyboard.com/api/1.0/'
			}
			else {
				$headers = $null
				$aPIEndpoint = 'http://localhost:27301/api/1.0/'
			}
			Invoke-RestMethod -Uri ($aPIEndpoint+'signals/'+$id) -Headers $headers -Method Delete
		 }
		catch {
			$Error[0].Exception
		 }
		finally {
		 }
	 
	}#process 
end {
	}#end 
}


function Update-DasQSignal {
<#
  .SYNOPSIS
  Update Signal from DAS Keyboard Q Cloud API
  .EXAMPLE
  Update-DasQSignal -id '1217350' -isRead $true   
  .EXAMPLE
  Get-DasQSignal | Update-DasQSignal -isRead $true -isArchived $true -isMuted $true
  .NOTES
  Author: jfrmilner

#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory,ValueFromPipelineByPropertyName)]
		$id
		# Signal id
	,
		[parameter(ValueFromPipelineByPropertyName)]
		$clientName
		# Signal clientname
	,
		[ValidateSet($true, $false)]
		$isRead
	,
		[ValidateSet($true, $false)]
		$isArchived
	,
		[ValidateSet($true, $false)]
		$isMuted
	)

begin 	{
		$signalHashtable = @{}
		if ($isRead) { $signalHashtable.Add("isRead" , $isRead) }
        if ($isArchived) { $signalHashtable.Add("isArchived" , $isArchived) }
        if ($isMuted) { $signalHashtable.Add("isMuted" , $isMuted) }
        $signalJSON = $signalHashtable | ConvertTo-Json
		}#begin 
process {
			try {
				if ($clientName -ne 'PublicApi') {
					if (!$accessToken -or $script:expiryDateTimeToken -lt (Get-Date)) {
						Get-DasQClientCredentials
						Get-DasQAuthToken -clientId $clientId -clientSecret $clientSecret
					}
				$headers = @{"Authorization"="Bearer $($accessToken)"}
				$aPIEndpoint = 'https://q.daskeyboard.com/api/1.0/'
				}
				else {
	                Write-Error -Exception "Updating a Signal status is Cloud only"
					$headers = $null
					$aPIEndpoint = 'http://localhost:27301/api/1.0/'
				}
				Invoke-RestMethod -Uri ($aPIEndpoint+'signals/'+$id+'/status') -Method Patch -Headers $headers -Body $signalJSON -ContentType 'application/json'
			}
			catch {
				$Error[0].Exception
			}
			finally {
			}
		}#process 
end 	{
		}#end 
}
