# PowerShell - DasKeyboard Q
PowerShell wrapper for Das Keyboard Q API.

## youtube Video Demo
[![Alt text](https://img.youtube.com/vi/uPwfrKJk3NI/0.jpg)](https://www.youtube.com/watch?v=uPwfrKJk3NI)

## This repository currently contains one script
*	DasKeyboardQAPI_functions.ps1

## Plans
* Convert DasKeyboardQAPI_functions.ps1 script to a PowerShell Module. This change will take place once DAS Keyboard Q Windows Client is out of Beta.
* Date filtering on Get-DasQSignal

## Installation
1. Download DasKeyboardQAPI_functions.ps1 to your local computer
2. Dot-source call the script to load the functions into your current PowerShell session
 ```powershell
	. .\DasKeyboardQAPI_functions.ps1
```
3. The first time you use Cloud Signals you will be prompted for the Client ID and Client Secret which you will need to obtain from https://q.daskeyboard.com/account. This information will then be saved to file dasq.cred at the following path C:\Users\<Username>\.

## Examples
### Sending Signals
#### Local API Endpoint
 ```powershell
Send-DasQSignal -Name "Local Test Name" -Key KEY_L -Colour Green -Effect BLINK -Message "Local Test Message" -Endpoint Local
```
#### Cloud API Endpoint
 ```powershell
Send-DasQSignal -Name "Cloud Test Name" -Key KEY_C -Colour Blue -Effect BLINK -Message "Cloud Test Message" -Endpoint Cloud
```
### Getting Signals
 ```powershell
Get-DasQSignal -Endpoint Cloud
```
### Removing Signals
#### Removal by id
 ```powershell
Remove-DasQSignal -id '-123'
```
#### Removal by Pipeline
 ```powershell
Get-DasQSignal -Endpoint Cloud | Remove-DasQSignal
```
### Updating Signals
#### Update by id
 ```powershell
Update-DasQSignal -id '1234567' -isRead $true 
```
#### Update by Pipeline
 ```powershell
Get-DasQSignal | Update-DasQSignal -isRead $true -isArchived $true -isMuted $true
```

## Contributing
Contributions are welcome, please open issue on what functionality you would like to see added/contribute or simply send a pull request.
