function Get-DomainRole(){
<#
    .SYNOPSIS
    
    Gets the domain role of <computerName>
    
    .DESCRIPTION
    
    Returns the following based on the role of <computerName>:

    0:Standalone Workstation
    1:Member Workstation
    2:Standalone Server
    3:Member Server
    4:Backup Domain Controller
    5:Primary Domain Controller
    
    .PARAMETER computerName
    
    [string]: The computername to query its domain role.
    
    .INPUTS
    None
    
    .OUTPUTS
    [int]: The value corresponding to the computer's domain role.
    
    
    .EXAMPLE
    
    Get-DomainRole
#>
	param(
		[Parameter(Mandatory=$TRUE, Position=0)]
			[string]$computerName
	)
	return [int]((Get-WMIObject -computerName $computerName Win32_ComputerSystem).domainRole)
						
}