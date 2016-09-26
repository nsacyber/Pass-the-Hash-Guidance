Import-Module Windows\General -force

#DOMAIN Stuff
$script:nthreads = 50
$domainRoleHash = @{
								0="Standalone Workstation"; 
								1="Member Workstation";
								2="Standalone Server"
								3="Member Server";
								4="Backup Domain Controller";
								5="Primary Domain Controller"
				}



function Get-DomainComputers(){
<#
    .SYNOPSIS
    
    Gets the computer names for each computer on the domain.
    
    .DESCRIPTION
    
    Writes each hostname on the domain to the pipeline
    
    .INPUTS
    None
    
    .OUTPUTS
    [Pipeline<string>]: Writes each hostname on the domain to the pipeline
    
    
    .EXAMPLE
    
    Get-DomainComputers
#>
	#Write every computer name in the domain to the pipeline
	[CmdletBinding()]
	param()
	BEGIN {}
	PROCESS{
		Write-Output (Invoke-DomainComputerLDAPQuery "(objectCategory=computer)") 
	}									
	END{}
}

function Get-DomainComputersSansDomainControllers(){
<#
    .SYNOPSIS
    
    Gets the computer names for each computer on the domain except for the domain controllers.
    
    .DESCRIPTION
    
    Writes each hostname on the domain (except for domain controllers) to the pipeline
    
    .INPUTS
    None
    
    .OUTPUTS
    [Pipeline<string>]: Writes each hostname on the domain (except for domain controllers) to the pipeline
    
    
    .EXAMPLE
    
    Get-DomainComputersSansDomainControllers
#>
	#Write every computer name in the domain minus the domain controllers
	#to the pipeline
	[CmdletBinding()]
	param()
	BEGIN {}
	PROCESS{
		Write-Output (Invoke-DomainComputerLDAPQuery "(&(objectCategory=computer)(!(primaryGroupID=516)))") 
	}
	END{}
}

function Invoke-DomainComputerLDAPQuery(){
<#
    .SYNOPSIS
    
    Invokes a user-specified ldap query to write all names of computers with a specified filter to the pipeline.

    (This is an internal function and should not be called directly.)
    
    .DESCRIPTION
    
    Invokes a user-specified ldap query to return all names of computers with a specified filter.
    
    .PARAMETER filter
    
    [string]: The ldap query to be executed.
    
    .INPUTS
    None
    
    .OUTPUTS
    [Pipeline<string>]: Writes the host names to the pipeline corresponding to <filter>.
    
    
    .EXAMPLE
    
    Invoke-DomainComputerLDAPQuery "(&(objectCategory=computer)(!(primaryGroupID=516)))"


#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$TRUE, position=1)]
			[string]$filter
	)
	
	BEGIN {
		#if multithreading package is available, use that version
		
        if($verbose){
		    Write-Host "Determining the machines on the network..." -NoNewLine
        }
	}
	PROCESS{
		$objDomain = New-Object System.DirectoryServices.DirectoryEntry
		$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
        $objsearcher.ServerTimeLimit = 1000
		try{
			$objSearcher.SearchRoot = $objDomain
			$objSearcher.Filter = $filter
			[void]$objSearcher.PropertiesToLoad.Add("name")
			$colResults = $objSearcher.FindAll()
			$colResults | foreach{Write-Output $_.Properties.name}
		}
		finally{
			$objDomain = $NULL
			$objSearcher = $NULL
		}
	}
	END{
        if($verbose){
		    Write-Host "...Done."
        }
	}
}




Export-ModuleMember -Variable domainRoleHash | Out-Null
Export-ModuleMember -function "*-*" | Out-Null
