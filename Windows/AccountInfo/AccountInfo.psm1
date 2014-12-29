#LOCAL STUFF

import-Module Windows\General -Force
import-module assert -force
import-module Windows\adsi -force

$script:ADMIN_GROUP_SID = "S-1-5-32-544"
$script:ADMIN_USER_NAME = "Administrator"
$script:GUEST_USER_NAME = "Guest"

$script:ALLOW_EMPTY_STRING_ATTR = "AllowEmptyStringAttribute"
$script:ALLOW_NULL__ATTR = "AllowNull"



#XXX 
#TODO
#Instead of casting an adsi object to test if it exists, write a method to do so.
#Instead of using Test-IsLocalUser -eq $FALSE for a domain user, write a Test-IsDomainUser function
#	that does the same thing for clarity.
#Remove the domainName parameter and try to combine it with computername
#Combine user and group account tests
#END TODO

function Get-LocalAdminGroupName(){
<#
    .SYNOPSIS
    Determine the name of the local administrators group.
    
    .DESCRIPTION
    Ask WMI to return the local administrators group name.
    
    .PARAMETER computerName
    [string]: Name of the computer to run the WMI query on.
    
    .INPUTS
    [string]: See parameter <computerName> 
    
    .OUTPUTS
    [string]: The name of the local administrators group on computer <computerName>
    
    .EXAMPLE
	Get-LocalAdminGroupName "computer"
	
	Gets the local administrator group's name on host "computer".  
	
#>
	param(
		[Parameter(Mandatory=$FALSE, Position=1, ValueFromPipeline = $TRUE)]
			[string]$computerName=$env:COMPUTERNAME
		
	)
	BEGIN{}
	PROCESS {
		return (Get-WMIObject -computerName $computerName -class Win32_group -filter "SID='$($script:ADMIN_GROUP_SID)'").name
	} 
	END{}
}

function Get-SomeLocalUser(){
<#
    .SYNOPSIS
    Determine the name of the local administrators group. This function assumes that the guest
	account or the administrator account exists on a box.  If this is not
	a valid assumption, it is trivial to add in some well-known account for your
	network.
    
    .DESCRIPTION
    Ask WMI to return the local administrators group name.
    
    .PARAMETER computerName
    [string]: Name of the computer to run the WMI query on.
    
    .INPUTS
    [string]: See parameter <computerName> 
    
    .OUTPUTS
    [string]: The name of the local administrators group on computer <computerName>
    
    .EXAMPLE
	Get-LocalAdminGroupName "computer"
	
	Gets the local administrator group's name on host "computer".  
	
#>
	param(
		[string]$computerName = $env:COMPUTERNAME
	)
	
	$user = (Get-User -local -computerName $computerName $script:GUEST_USER_NAME)
	if($user -eq $NULL){
		$user = (Get-User -local -computerName $computerName $script:ADMIN_USER_NAME)
	}
	
	return $user
								
								
}

function ConvertFrom-BinarySIDToString(){
<#
	#YYY
    .SYNOPSIS
    YYY - Synopsis
    
    .DESCRIPTION
    YYY - Description
    
    .PARAMETER <p1>
    YYY [type]: P1 description
    
    .INPUTS
    YYY [type]: Pipeline input description 
    
    .OUTPUTS
    YYY [type]: Output description

    .EXAMPLE
    YYY - Example description 
#>
	[CmdletBinding()]
	param(
		[byte[]]$byteArr
	)
	return New-Object System.Security.Principal.SecurityIdentifier($byteArr,0)						
									
}

function ConvertFrom-SIDtoUser(){
<#
	#YYY
    .SYNOPSIS
    YYY - Synopsis
    
    .DESCRIPTION
    
    YYY - Description
    
    .PARAMETER <p1>
    
    YYY [type]: P1 description
    
    .INPUTS
    YYY [type]: Pipeline input description 
    
    .OUTPUTS
    YYY [type]: Output description
    
    
    .EXAMPLE
    
    YYY - Example description 
#>								
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$TRUE)]
			[string]$sidAsString
	)
	$sid = New-Object System.Security.Principal.SecurityIdentifier($sidAsString)
	$user = $sid.Translate([System.SEcurity.Principal.NTAccount])
	return $user.value
					
}

function ConvertFrom-UserToSID(){
<#
	#YYY
    .SYNOPSIS
    
    YYY - Synopsis
    
    .DESCRIPTION
    
    YYY - Description
    
    .PARAMETER <p1>
    
    YYY [type]: P1 description
    
    .INPUTS
    YYY [type]: Pipeline input description 
    
    .OUTPUTS
    YYY [type]: Output description
    
    
    .EXAMPLE
    
    YYY - Example description 
#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$TRUE)]
			[string]$domain,
		[Parameter(Mandatory=$TRUE)]
			[string]$userName
	)
	$ntAccount = New-Object System.Security.Principal.NTAccount($domain, $userName)
	$sid = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier])
	return $sid.value
					
}


function ConvertFrom-SIDtoDirectoryEntry{
<#
	#YYY
    .SYNOPSIS
    
    YYY - Synopsis
    
    .DESCRIPTION
    
    YYY - Description
    
    .PARAMETER <p1>
    
    YYY [type]: P1 description
    
    .INPUTS
    YYY [type]: Pipeline input description 
    
    .OUTPUTS
    YYY [type]: Output description
    
    
    .EXAMPLE
    
    YYY - Example description 
#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$TRUE)]
			[string]$sid
	)
	return [adsi]"LDAP://<SID=$sid>"					
}



#######Test functions

#grouptypes
$GROUP_TYPE_LOCAL = 4
$GROUP_TYPE_DOMAIN = 2

#schemaclassnames
$SCN_GROUP = "group"
$SCN_USER = "user"

#domainroles
$DOMAIN_ROLE_PRIMARY_DOMAIN_CONTROLLER = 5


function Get-Sid(){
<#
    .SYNOPSIS
    Returns the SID for an ADSI user or group account.
    
    .DESCRIPTION
    Returns the SID for an ADSI user or group account. 
    
    .PARAMETER account
    [ADSI]: User or Group ADSI object to get the corresponding SID for.
    
    .INPUTS
    [ADSI]: See parameter <account>
    
    .OUTPUTS
    [System.Security.Principal.SecurityIdentifier] or $NULL: The .net SID object for
    the corresponding user or group or $NULL if the group or user does not exist.
    
    .EXAMPLE
    Get-Sid (Get-User -local "Administrator")
    
    Returns the sid for the local administrator account. 
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$TRUE, Position=1, ValueFromPipeline=$TRUE)]
            [ADSI]$account
    )
    BEGIN{}
    PROCESS{
		if(-not (Test-ADSISuccess $account)){
			return $NULL
		}
		$objectSID = $account.invokeget("ObjectSid")
		if($objectSID){
        	return New-Object System.Security.Principal.SecurityIdentifier($objectSID, 0)
       }
	   return $NULL
    }
    END{}

}

function Test-IsAdministrator(){
<#
    .SYNOPSIS
    Tests whether or not an account is a local or domain administrator
    
    .DESCRIPTION
	Tests whether or not a local or domain user account is an administrator.
    
    .PARAMETER local
    [switch]: Test for user being a local administrator account
    
    .PARAMETER domain
    [switch]: Test for user being a domain administrator account
    
    .PARAMETER account
    [ADSI]: The ADSI object representing a user account to test.
    
    .PARAMETER computerName
    [string]: The name of the computer we should query to see if the user is a local administrator.
    
    .INPUTS
    [ADSI]: See parameter <account> 
    
    .OUTPUTS
    [bool]: Returns True if the account supplied is a an administrator of the
    specified domain (local or domain).
    
    
    .EXAMPLE
    
    Test-IsAdministrator -local (Get-User -local "Administrator") 
#>
	[CmdletBinding()]
    param(
		[Parameter(Mandatory=$TRUE, ParameterSetName="Local")]
            [switch]$local,

        [Parameter(Mandatory=$TRUE, ParameterSetName="Domain")]
            [switch]$domain,

        [Parameter(Mandatory=$TRUE, Position=1, ValueFromPipeline=$TRUE)]
            [ADSI]$account,
            
            
        [Parameter(Mandatory=$FALSE, ParameterSetName="Local")]
			[string]$computerName=$env:COMPUTERNAME
           
    )
    BEGIN{}
    PROCESS{
		$adminGroup = $NULL
		if($local){
			$adminGroup = Get-Group -local (Get-LocalAdminGroupName -computerName $computerName)
		}
		else{
			#XXX Only supporting domain admins...need recursive group resolution to get all domain admins on box!!!!!
			$adminGroup = Get-Group -domain -computerName $computerName "Domain Admins" 
		}

		return (Test-GroupMembership -user $account -group $adminGroup)
		
    }
    END{} 

}


function Test-IsLocalUser(){
<#
    .SYNOPSIS
    
    Checks to see if a user account is a local user or a domain user.
    
    .DESCRIPTION
    
    Finds a well-known user (currently, guest or administrator) and checks to 
    see if the specified user's SID has an equivalent domain SID to the well-known user.
    This uses the Windows SID API method IsEqualDomainSid to test equivalence.
    
    .PARAMETER ADSI
    
    [switch]: Use this switch to signify the input is an ADSI account object
    
    .PARAMETER $account
    
    [ADSI]: user account to test.
    
    .PARAMETER sid
    
    [switch]: Use this switch to signify the input is a SID
    
    .PARAMETER accountSID
    
    [System.Security.Principal.SecurityIdentifier]: User SID to test.
    
    .PARAMETER computerName
    
    [string]: The computer to be designated as the local computer for the comparison.
    
    
    .INPUTS
    [ADSI] or [System.Security.Principal.SecurityIdentifier]: See parameter <user> or <userSID> 
    
    .OUTPUTS
    [bool]: True if the user is local to <computerName> or false otherwise
    
    .EXAMPLE
    
	Test-IsLocalUser (Get-User -local "Administrator")
#>
    [CmdletBinding(DefaultParameterSetName="ADSI")]
    param(
        [Parameter(Mandatory=$FALSE, ParameterSetName="ADSI")]
            [switch]$ADSI,
        
        [Parameter(Mandatory=$TRUE, ParameterSetName="Sid")]
            [switch]$sid,
        
        [Parameter(Mandatory=$TRUE, ValueFromPipeline=$TRUE, ParameterSetName="ADSI", position=1)]
            [ADSI]$account,

        [Parameter(Mandatory=$TRUE, ValueFromPipeline=$TRUE, ParameterSetName="Sid", position=1)]
            [System.Security.Principal.SecurityIdentifier]$accountSID,

        [Parameter(Mandatory=$FALSE, ParameterSetName="ADSI")]
        [Parameter(Mandatory=$FALSE, ParameterSetName="Sid")]
            [string]$computerName = $env:COMPUTERNAME
    )
    BEGIN{}
    PROCESS{
		#get well-known local user for the computer
		$localSid = Get-SomeLocalUser -computerName $computerName  | Get-Sid  
        if($PSCmdlet.ParameterSetName -eq "ADSI"){
            $accountSID = Get-Sid  $account
        }
        return $localSid.IsEqualDomainSid($accountSID)
    }
    END{}
}

function Test-IsLocalGroup(){
<#
	#ZZZ THIS IS A CODE CLONE OF Test-IsLocalUser...fix at some point
    .SYNOPSIS
    
    Checks to see if a user group is a local group or a domain group.
    
    .DESCRIPTION
    
    Finds a well-known user (currently, guest or administrator) and checks to 
    see if the specified user's SID has an equivalent domain SID to the well-known group.
    This uses the Windows SID API method IsEqualDomainSid to test equivalence.
    
    .PARAMETER ADSI
    
    [switch]: Use this switch to signify the input is an ADSI group object
    
    .PARAMETER account
    
    [ADSI]: group account to test.
    
    .PARAMETER sid
    
    [switch]: Use this switch to signify the input is a SID
    
    .PARAMETER accountSID
    
    [System.Security.Principal.SecurityIdentifier]: group SID to test.
    
    .PARAMETER computerName
    
    [string]: The computer to be designated as the local computer for the comparison.
    
    
    .INPUTS
    [ADSI] or [System.Security.Principal.SecurityIdentifier]: See parameter <group> or <groupSID> 
    
    .OUTPUTS
    [bool]: True if the group is local to <computerName> or false otherwise
    
    .EXAMPLE
    
	Test-IsLocalGroup (Get-Group -local "Administrators")
#>
    [CmdletBinding(DefaultParameterSetName="ADSI")]
    param(
        [Parameter(Mandatory=$FALSE, ParameterSetName="ADSI")]
            [switch]$ADSI,
        
        [Parameter(Mandatory=$TRUE, ParameterSetName="Sid")]
            [switch]$sid,
        
        [Parameter(Mandatory=$TRUE, ValueFromPipeline=$TRUE, ParameterSetName="ADSI", position=1)]
            [ADSI]$account,

        [Parameter(Mandatory=$TRUE, ValueFromPipeline=$TRUE, ParameterSetName="Sid", position=1)]
            [System.Security.Principal.SecurityIdentifier]$accountSID,

        [Parameter(Mandatory=$FALSE, ParameterSetName="ADSI")]
        [Parameter(Mandatory=$FALSE, ParameterSetName="Sid")]
            [string]$computerName = $env:COMPUTERNAME
    )
    BEGIN{}
    PROCESS{
		#get well-known local user for the computer
		$localSid = Get-SomeLocalUser -computerName $computerName  | Get-Sid  
        if($PSCmdlet.ParameterSetName -eq "ADSI"){
            $accountSID = Get-Sid  $account
        }
		#for some reason, some accounts have a $NULL valued accountdomainsid field.
		#This seems to happen for domain accounts that are local to the box
		if($userSid.AccountDomainSid -eq $NULL){
			return $TRUE
		}
		else{
        	$localSid.IsEqualDomainSid($accountSID)
        }
    }
    END{}
}



function Get-DomainRole(){
<#
    .SYNOPSIS
    
    Returns the domain role property from the Win32_ComputerSystem WMI query.
    	0="Standalone Workstation"; 
		1="Member Workstation";
		2="Standalone Server"
		3="Member Server";
		4="Backup Domain Controller";
		5="Primary Domain Controller"
    
    .PARAMETER computerName
    
    [string]: The name of the comptuer to run the WMI query on.
    
    .INPUTS
    None. 
    
    .OUTPUTS
    [int]: Returns an integer corresponding to the computer's domain role
    
    .EXAMPLE
    
    Get-DomainRole "testSystem"
#>
	param(
		[Parameter(Mandatory=$TRUE, Position=1)]
			[string]$computerName
	)
	return [int]((Get-WMIObject -computerName $computerName Win32_ComputerSystem).domainRole)
						
}


function Get-PrimaryDC(){
<#
    .SYNOPSIS
    
    Returns the host name of the primary domain controller
    
    .DESCRIPTION
    
    Returns the host name of the primary dc by enumerating all systems on
    the domain and looking for a host that satisfies the expression:
    (Get-DomainRole -eq 5). 
    
    .OUTPUTS
    [string]: The host name of the primary domain controller
    
    
    .EXAMPLE
    
    Get-PrimaryDC
#>
    return Get-DomainComputers | Where {(Get-DomainRole $_) -eq $DOMAIN_ROLE_PRIMARY_DOMAIN_CONTROLLER}
}


function Get-FunctionParameters(){
<#
    .SYNOPSIS
    
    ZZZ - Synopsis
    
    .DESCRIPTION
    
    ZZZ - Description
    
    .PARAMETER <p1>
    
    ZZZ [type]: P1 description
    
    .INPUTS
    ZZZ [type]: Pipeline input description 
    
    .OUTPUTS
    ZZZ [type]: Output description
    
    
    .EXAMPLE
    
    ZZZ - Example description 
#>
    param(
        [string]$_function
    )
    $result = New-Object "System.collections.Generic.Dictionary[System.String, System.Object]"
    
    $cmd = Get-command $_function 
    foreach($key in $cmd.Parameters.keys){
        $metadata = $cmd.parameters.item($key)
        try{
        	$value = (Get-Variable -ErrorAction Stop -errorvariable "fpErr" -scope 1 $key).value
	        if($value -or $metadata.attributes.typeid.name -eq $script:ALLOW_EMPTY_STRING_ATTR){
	            $result.add($key, $value)
	        }
		}
        catch [System.Management.Automation.ItemNotFoundException]{
		#	Write-Host "CANNOT FIND PARAMETER: $key for function $_function"
		}
    }
    return $result

}



#############
#User
#############
###XXX
####Consider aliasing domain and computer to be the same thing

function Get-User(){
<#
    .SYNOPSIS
    
    Gets an ADSI User object corresponding to domain\user or computer\user.
    
    .DESCRIPTION
    
    Uses the WinNT provider to get an ADSI user object corresponding to a specified user
    
    .PARAMETER local
    
    [switch]: Return a local user
    
    .PARAMETER domain
    
    [switch]: Return a domain user
    
    .PARAMETER domainName
    
    [string]: Name of the domain
    
    .PARAMETER name
    
    [string]: Name of the user to search for.
    
    .PARAMETER computerName
    
    [string]: In the context of a local user search, the hostname to search on.
    
    .INPUTS
    None 
    
    .OUTPUTS
    [ADSI]: The ADSI user object of the specified user or $NULL if the user does not exist
    
    
    .EXAMPLE
    
    Get-User -local "joe" 
#>
    [CmdletBinding(DefaultParameterSetName="Domain")]
    param(
        [Parameter(Mandatory=$TRUE, ParameterSetName="Local")]
            [switch]$local,

        [Parameter(Mandatory=$TRUE, ParameterSetName="Domain")]
            [switch]$domain,

        [Parameter(Mandatory=$FALSE, ParameterSetName="Domain")]
            [string]$domainName=$env:USERDOMAIN,

        [Parameter(Mandatory=$TRUE, ParameterSetName="Domain", position=1)]
        [Parameter(Mandatory=$TRUE, ParameterSetName="Local", position=1)]
            [string]$name,

        [Parameter(Mandatory=$FALSE, ParameterSetName="Local")]
            [string]$computerName=$env:COMPUTERNAME
    )
    if($local){
		return Get-ADSIUser -domain $computername -name $name
    }
    else{
		return Get-ADSIUser -domain $domainName -name $name
    }
}

##############
#Group
##############

function Test-GroupExists(){
<#
    .SYNOPSIS
    
    Returns true if the group exists or false if it does not.
    
    .DESCRIPTION
    
    Returns true if the group exists in the specified domain/local/or any context or false otherwise.
    
    .PARAMETER all
    
    [switch]: Search both domain and the local computer for the group
    
    .INPUTS
    None. 
    
    .OUTPUTS
    [bool]: True if the group exists or False otherwise.
    
    
    .EXAMPLE
    
    Test-GroupExists -local "Administrators"
    
    .NOTES
    
    Todo: 
    	XXX Search all local computers instead of just this host. 
     
#>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$TRUE, ParameterSetName="All")]
        	[switch]$all,

        [Parameter(Mandatory=$TRUE, ParameterSetName="Local", position=1)]
        [Parameter(Mandatory=$TRUE, ParameterSetName="Domain", position=1)]
        [Parameter(Mandatory=$TRUE, ParameterSetName="All", position=1)]
			[string]$name,

		[Parameter(Mandatory=$TRUE, ParameterSetName="Local")]
			[switch]$local,

		[Parameter(Mandatory=$TRUE, ParameterSetName="Domain") ]
        	[switch]$domain,
        
        [Parameter(Mandatory=$FALSE, ParameterSetName="All")]
        [Parameter(Mandatory=$FALSE,ParameterSetName="Domain") ]
            [string]$domainName = ($env:userdomain),

		[Parameter(Mandatory=$FALSE) ]
			[string]$computerName = ($env:ComputerName)
	)
	BEGIN{}
	PROCESS{
		$res = $NULL
		$fargs = Get-FunctionParameters "Get-Group"
		if($all){
			$res = Get-Group @fargs
		}
		elseif($local){
			[void]$fargs.remove("domainName")
			$res = Get-Group @fargs
		}
		else{
			#domain
			$res = Get-Group @fargs
		}
		return [bool]$res
	}
	END{}
}


function Test-GroupMembership(){
<#
    .SYNOPSIS
    
    Test whether or not a user is a direct member of a specific group.
    
    .DESCRIPTION
    
    Returns True if a user is a direct member of a group or False otherwise.
    
    .PARAMETER user
    
    [ADSI]: The user to test the membership of.
    
    .PARAMETER group
    
    [ADSI]: The group to test the user's membership in.
    
    .INPUTS
    None 
    
    .OUTPUTS
    [bool]: Returns True if the user <user> is a direct member of the group <group> and false otherwise.
    
    
    .EXAMPLE
    
    Test-GroupMembership -user (Get-User -local "Administrator") -group (Get-Group -local "Administrators")  
    
    .NOTES 
    
    Todo: 
    	XXX Add indirect membership
#>
	[CmdletBinding()]
	param(
		
		[Parameter(Mandatory=$TRUE)]
		[AllowNull()]
			[ADSI]$user,
		[Parameter(Mandatory=$TRUE)]
		[AllowNull()]
			[ADSI]$group

			
	)		
	if($user -eq $NULL -or $group -eq $NULL){
		return $FALSE
	}
	$members = $group | Get-GroupMembers
	$userSid = Get-Sid $user
	
	
	if($userSID -ne $NULL){
		foreach($member in $members){
			if ((Get-Sid $member).value -eq $userSid.value){
				return $TRUE
			}
		}
	}
	return $FALSE
							
							
}

function Get-Group(){
<#
    .SYNOPSIS
    
    Gets an ADSI group object corresponding to domain\group or computer\group
    
    .DESCRIPTION
    
    Uses the WinNT provider to get an ADSI group object corresponding to a specified group name.
    
    .PARAMETER all
    
    [switch]: Return local groups or domain groups
    
    .PARAMETER local
    
    [switch]: Return a local group
    
    .PARAMETER domain
    
    [switch]: Return a domain user
    
    .PARAMETER domainName
    
    [string]: Name of the domain
    
    .PARAMETER name
    
    [string]: Name of the group to search for.
    
    .PARAMETER computerName
    
    [string]: In the context of a local group search, the hostname to search on.
    
    .INPUTS
    None 
    
    .OUTPUTS
    [ADSI]: The ADSI group object of the specified group or $NULL if the group does not exist
    
    
    .EXAMPLE
    
    Get-Group -local "Administrators" 
#>

	[CmdletBinding(DefaultParameterSetName="All")]
	param(

        [Parameter(Mandatory=$FALSE, ParameterSetName="All")]
            [switch]$all,

		[Parameter(Mandatory=$FALSE, ParameterSetName="All", position=1)]
        [Parameter(Mandatory=$FALSE, ParameterSetName="Local", position=1)]
        [Parameter(Mandatory=$FALSE, ParameterSetName="Domain", position=1)]
			[string]$name,

		[Parameter(Mandatory=$TRUE, ParameterSetName="Local")]
			[switch]$local,

		[Parameter(Mandatory=$TRUE, ParameterSetName="Domain") ]
        	[switch]$domain,
        
        [Parameter(Mandatory=$FALSE, ParameterSetName="All")]
        [Parameter(Mandatory=$FALSE,ParameterSetName="Domain") ]
            [string]$domainName = ($env:userdomain),

		[string]$computerName = ($env:ComputerName)
	)
        $result = $NULL
        
        
        if($PSCmdlet.ParameterSetName -eq "All"){
            #get all groups
            $allArgs = Get-FunctionParameters "Get-LocalGroup"
            $result = @(Get-LocalGroup @allArgs)

            $domainArgs = Get-FunctionParameters "Get-DomainGroup"
            $result += @(Get-DomainGroup @domainArgs)
        }
        elseif($local -eq $TRUE){
            $localArgs = Get-FunctionParameters "Get-LocalGroup"
            $result = (Get-LocalGroup @localArgs)
		}
        elseif($domain -eq $TRUE){
            $domainArgs = Get-FunctionParameters "Get-DomainGroup"
            $result =  (Get-DomainGroup @domainArgs) 

        }
        else{
            #this should not happen
            throw "Both local and domain are TRUE, this should not happen"
        }
        if($name){
            $result = $result | Where {$_.name -eq $name}
        }
	    return $result 
					
}

#internal function
function Get-LocalGroup(){
<#
    .SYNOPSIS
    
    Gets an ADSI group object corresponding to computer\group
    
    .DESCRIPTION
    
    Uses the WinNT provider to get an ADSI group object corresponding to a specified group name.
    
    .PARAMETER name
    
    [string]: Name of the group to search for.
    
    .PARAMETER computerName
    
    [string]: The hostname to search on.
    
    .INPUTS
    None 
    
    .OUTPUTS
    [ADSI]: The ADSI group object of the specified local group or $NULL if the group does not exist
    
    .NOTES
    
    This is an internal function and is not meant to be called directly.  Use Get-Group -local to
    conform to our published API.
    
    .EXAMPLE
    
    Get-LocalGroup "Administrators" 
#>
    [CmdletBinding(DefaultParameterSetName="All")]
	param(
		[Parameter(Mandatory=$FALSE, position=1, ParameterSetName="Name") ]
			[string]$name,

        [Parameter(Mandatory=$FALSE) ]
			[string]$computerName = ($env:ComputerName)


	)
    $groups = $NULL
    if($name){
        $groups = Get-ADSIGroup -group $name -domain $computername
    }
    else{
        $groups = Get-ADSIComputer -computerName $computerName | Where {$?} | foreach{$_.psbase.children} | Where {$_.SchemaClassName -eq $SCN_GROUP -and $_.properties.grouptype -eq $GROUP_TYPE_LOCAL}

    }

    return $groups

}

#internal function
function Get-DomainGroup(){
<#
    .SYNOPSIS
    
    Gets an ADSI group object corresponding to computer\group
    
    .DESCRIPTION
    
    Uses the WinNT provider to get an ADSI group object corresponding to a specified group name.
    
    .PARAMETER name
    
    [string]: Name of the group to search for.
    
    .PARAMETER computerName
    
    [string]: The hostname to search on.
    
    .INPUTS
    None 
    
    .OUTPUTS
    [ADSI]: The ADSI group object of the specified local group or $NULL if the group does not exist
    
    .NOTES
    
    This is an internal function and is not meant to be called directly.  Use Get-Group -domain to
    conform to our published API.
    
    .EXAMPLE
    
    Get-DomainGroup "Domain Admins" 
#>
    [CmdletBinding(DefaultParameterSetName="All")]
	param(

		[Parameter(Mandatory=$TRUE, ParameterSetName="Name", position=1)]
			[string]$name,

        #[Parameter(Mandatory=$TRUE,ParameterSetName="All") ]
		#[Parameter(Mandatory=$TRUE,ParameterSetName="Name") ]
		#	[string]$computerName,
    

        [Parameter(Mandatory=$FALSE, ParameterSetName="All")]
        [Parameter(Mandatory=$FALSE, ParameterSetName="Name")]
			[string]$domainName=$env:USERDOMAIN
	)
    $groups = $NULL
    if($PSCmdlet.ParameterSetName -eq "All"){
        $groups = Get-ADSIDomain $domainName | foreach{$_.psbase.children} | Where {$_.SchemaClassName -eq $SCN_GROUP -and $_.properties.grouptype -eq $GROUP_TYPE_DOMAIN}
        
    }
    elseif($PSCmdlet.ParameterSetName -eq "Name"){

        $groups = Get-ADSIGroup -domain $domainName -group $name 
    }
    else{
		throw "Wrong parameterset...should not get here"
	}
    
    
    return $groups
}

function New-Group(){
<#
    .SYNOPSIS
    
    Creates a new group (local or domain).
    
    .DESCRIPTION
    
    Uses ADSI to create a new local or domain group.
    
    .PARAMETER local
    
    [switch]: Create local group.
    
    .PARAMETER domain
    
    [switch]: Create domain group.
    
    .PARAMETER name
    
    [string]: Name of the new group.
    
    .PARAMETER computername
    
    [switch]: Name of the computer to create the local group on.
    
    .PARAMETER description
    
    [string]: Description of the group.
    
    .PARAMETER verify
    
    [switch]: Verify that the group was created successfully.
    
    .INPUTS
    None 
    
    .OUTPUTS
    [ADSI|$NULL]: An ADSI reference to the new group or $NULL if the group was not created.
    
    
    .EXAMPLE
    
    New-Group -local "test"
    
    Create a new local group named test on the current host.
#>
    [CmdletBinding(DefaultParameterSetName="Local")]
    param(
        [Parameter(Mandatory=$TRUE, ParameterSetName="Local")]
            [switch]$local,

        [Parameter(Mandatory=$TRUE, ParameterSetName="Domain")]
            [switch]$domain,

        [Parameter(Mandatory=$TRUE, ParameterSetName="Domain", position=1)]
        [Parameter(Mandatory=$TRUE, ParameterSetName="Local", position=1)]
            [string]$name,

        [Parameter(Mandatory=$FALSE, ParameterSetName="Local")]
            [string]$computerName=$env:COMPUTERNAME,
                
        [Parameter(Mandatory=$FALSE, ParameterSetName="Domain")]
        [Parameter(Mandatory=$FALSE, ParameterSetName="Local")]
            [string]$description,

        [Parameter(Mandatory=$FALSE)]
            [switch]$verify

    
    )

    $computer = $NULL

    if($local){
        $computer = Get-ADSIComputer -computerName $computerName

    }
    elseif($domain){
        $computer = Get-ADSIDomain 

    }
    else{
        throw "Unknown ParameterSet in New-Group"
    }
	if((Test-ADSISuccess $computer) -eq $TRUE){
	    $group = $computer.create($SCN_GROUP, $name)
	    [void]$group.setInfo()
	    $group.description = $description
	    [void]$group.setInfo()
	    if($verify){
            $group = $computer.GetObject($SCN_GROUP, $name)
			if(-not (Test-ADSISuccess $group)){
                throw "Error creating group $name"
            }
        }
        return $group
	}
	else{
		Write-Error "Unable to create group $name on computer $computername"
		return $NULL
		
	}

}

function Remove-Group(){
<#
    .SYNOPSIS
    
    Removes an existing group (local or domain).
    
    .DESCRIPTION
    
    Uses ADSI to remove a new local or domain group.
    
    .PARAMETER local
    
    [switch]: Remove local group.
    
    .PARAMETER domain
    
    [switch]: Remove domain group.
    
    .PARAMETER name
    
    [string]: Name of the group to be removed.
    
    .PARAMETER computername
    
    [switch]: Name of the computer to remove the local group from.
    
    .INPUTS
    None. 
    
    .OUTPUTS
    None.
    
    .NOTES 
    
    Todo:
    	XXX Add verify parameter
    
    .EXAMPLE
    
    New-Group -local "test"
    
    Create a new local group named test on the current host.
#>
    [CmdletBinding(DefaultParameterSetName="Domain")]
    param(
        [Parameter(Mandatory=$TRUE, ParameterSetName="Local")]
            [switch]$local,

        [Parameter(Mandatory=$FALSE, ParameterSetName="Domain")]
            [switch]$domain,

        [Parameter(Mandatory=$TRUE, ParameterSetName="Domain", position=1)]
        [Parameter(Mandatory=$TRUE, ParameterSetName="Local", position=1)]
            [string]$name,

        [Parameter(Mandatory=$FALSE, ParameterSetName="Local")]
            [string]$computerName=$env:COMPUTERNAME
    )

    $computer = $NULL

    if($PSCmdlet.ParameterSetName -eq "Local"){
        $computer = Get-ADSIComputer -computerName $computerName

    }
    elseif($PSCmdlet.ParameterSetName -eq "Domain"){
        $computer = Get-ADSIDomain 
    }
    else{
        throw "Unknown ParameterSet in New-Group"
    }
	if($computer){
    	[void]$computer.Delete($SCN_GROUP, $name)
    	
    }
	else{
		throw "could not delete group $name"
	}

}


function Get-GroupMembers(){
<#
    .SYNOPSIS
    
    Returns the members of a group
    
    .DESCRIPTION
    
    Uses ADSI to query the members of a group and returns it to the user.
    
    .PARAMETER local
    
    [switch]: Return local group members
    
    .PARAMETER domain
    
    [switch]: Return domain group members
    
    .PARAMETER ADSIGroup
    
    [ADSI]: The ADSI object referring to a specific group
    
	.PARAMETER userName
	
	[string]: The username to use as a filter.
	
	.PARAMETER computerName
	[string]: The name of the computer to get local groups from.
    
    .INPUTS
    [ADSI]: See parameter <ADSIGroup> 
    
    .OUTPUTS
    [array] or $NULL: An array containing the members of a group or $NULL if no members pass the filtering checks
    
    .NOTES
    
    todo:
    	XXX When filtering by username, we currently only support exact matches.
    	Could potentially just use a regular expression to do filter based on
    	pattern matching.
    
    .EXAMPLE
    
    Get-GroupMembers (Get-Group "Domain Admins")
#>
    [CmdletBinding(DefaultParameterSetName="All")]
    param(
        [Parameter(Mandatory=$FALSE, ValueFromPipeline=$TRUE, ParameterSetName="All", Position=1) ]
        [Parameter(Mandatory=$TRUE, ValueFromPipeline=$TRUE, ParameterSetName="Domain", Position=1) ]
        [Parameter(Mandatory=$TRUE, ValueFromPipeline=$TRUE, ParameterSetName="Local", Position=1) ]
        [AllowNull()]
            [ADSI]$ADSIgroup,

        [Parameter(Mandatory=$TRUE, ParameterSetName="Local") ]
            [switch]$local,

        [Parameter(Mandatory=$FALSE, ParameterSetName="All") ]
        [Parameter(Mandatory=$FALSE, ParameterSetName="Local") ]
            [string]$computerName = $env:COMPUTERNAME,

        [Parameter(Mandatory=$TRUE, ParameterSetName="Domain") ]
            [switch]$domain,

		[Parameter(Mandatory=$FALSE, Position=2)]
            [string]$username

    )
	#XXX
	#Get-Groupmembers should also be able to take a group name
	#
	#
    BEGIN{}
    PROCESS{
		if($ADSIGroup -eq $NULL){
			return $NULL
		}
        $members = $ADSIgroup.invoke("Members") | foreach{[ADSI]$_}
        if($username){
            $members = $members | Where {$_.name -eq $username}
        }
        switch($PSCmdlet.ParameterSetName){
            "Local" {
                return $members | Where {(Test-IsLocalUser -ADSI -account $_ -computerName $computerName) -eq $TRUE}

            }

            "Domain"{
                return $members | Where {(Test-IsLocalUser -ADSI -account $_) -eq $FALSE}

            }

        }
        
        return $members    
    }
    END{}

}

function Add-GroupMember(){
<#
    .SYNOPSIS
    
    Adds a user to a group
    
    .DESCRIPTION
    
    Uses ADSI to add a new member of a group.
    
    .PARAMETER local
    
    [switch]: Add a new local group member.
    
    .PARAMETER domain
    
    [switch]: Add a new domain group member.
    
	.PARAMETER group
	
	[string]: The name of the group to receive the new member.
	
	.PARAMETER user
	
	[string]: The name of the user to be added to the group.
	
	.PARAMETER computerName
	[string]: The name of the computer that the local group resides on.
    
    .INPUTS
    None.
    
    .OUTPUTS
    None.
    
    .NOTES
    
    todo:
    	XXX When filtering by username, we currently only support exact matches.
    	Could potentially just use a regular expression to do filter based on
    	pattern matching.
    	
    	XXX Remove-GroupMember and Add-GroupMember should support taking an 
    	ADSI object in as a parameter. 
    	
    	XXX This should also support taking in a group...it may already do so, 
    	but i have not checked.
    
    .EXAMPLE
    
    Add-GroupMember -user "joe" -group "Administrators"
#>
    [CmdletBinding(DefaultParameterSetName="Local")]
    param(
        [Parameter(Mandatory=$TRUE, ParameterSetName="Local")]
            [switch]$local,

        [Parameter(Mandatory=$TRUE, ParameterSetName="Domain")]
            [switch]$domain,

        [Parameter(Mandatory=$TRUE, ParameterSetName="Domain")]
        [Parameter(Mandatory=$TRUE, ParameterSetName="Local")]
            [string]$group,

        [Parameter(Mandatory=$FALSE, ParameterSetName="Local")]
            [string]$computerName=$env:COMPUTERNAME,

        [Parameter(Mandatory=$TRUE, ParameterSetName="Domain")]
        [Parameter(Mandatory=$TRUE, ParameterSetName="Local")]
            [string]$user
    )
    $fargs = Get-FunctionParameters "Get-Group"
    $fargs["name"] = $group
    $adsiGroup = Get-Group @fargs
    Test-Assert {($adsiGroup | Test-ADSISuccess) -eq $TRUE}
    $adsiUser = $NULL
    if($local){
        $adsiUser = Get-User -local -name $user -computername $computername
        
    }
    else{
        $adsiUser = Get-User -domain -name $user
    }
	Test-Assert {($adsiUser | Test-ADSISuccess) -eq $TRUE}
    $adsiGroup.add($adsiUser.path)
}

function Remove-GroupMember(){
<#
    .SYNOPSIS
    
    Remove a user from a group
    
    .DESCRIPTION
    
    Uses ADSI to remove a member of a group.
    
    .PARAMETER local
    
    [switch]: Remove a local group member.
    
    .PARAMETER domain
    
    [switch]: Remove a domain group member.
    
	.PARAMETER group
	
	[string]: The name of the group the member will be removed from.
	
	.PARAMETER user
	
	[string]: The name of the user to be removed from the group.
	
	.PARAMETER computerName
	[string]: The name of the computer that the local group resides on.
	
    .INPUTS
    None.
    
    .OUTPUTS
    None.
    
    .NOTES
    
    todo:
    	XXX When filtering by username, we currently only support exact matches.
    	Could potentially just use a regular expression to do filter based on
    	pattern matching.
    	
    	XXX Remove-GroupMember and Add-GroupMember should support taking an 
    	ADSI object in as a parameter. 
    
    .EXAMPLE
    
    Remove-GroupMember -user "joe" -group "Administrators"
#>
    [CmdletBinding(DefaultParameterSetName="Local")]
    param(
        [Parameter(Mandatory=$TRUE, ParameterSetName="Local")]
            [switch]$local,

        [Parameter(Mandatory=$TRUE, ParameterSetName="Domain")]
            [switch]$domain,

        [Parameter(Mandatory=$TRUE, ParameterSetName="Domain")]
        [Parameter(Mandatory=$TRUE, ParameterSetName="Local")]
            [string]$group,

        [Parameter(Mandatory=$FALSE, ParameterSetName="Local")]
            [string]$computerName=$env:COMPUTERNAME,

        [Parameter(Mandatory=$TRUE, ParameterSetName="Domain")]
        [Parameter(Mandatory=$TRUE, ParameterSetName="Local")]
            [string]$user
    )
    $fargs = Get-FunctionParameters "Get-Group"
    $fargs["name"] = $group
    $adsiGroup = Get-Group @fargs
    if($adsiGroup -eq $NULL){
		Write-Error "Group $group does not exist"
		return
	}
    $adsiUser = $NULL
    if($local){
        $adsiUser = Get-User -local -name $user -computername $computername
        
    }
    else{
        $adsiUser = Get-User -domain -name $user
    }
	if($adsiUser -eq $NULL){
		Write-Error "User $user does not exist"
		return
	}
							
    $adsiGroup.Remove($adsiUser.path)


}


function Test-UserExists(){
<#
    .SYNOPSIS
    Tests the existence of a domain or local user.
    
    .DESCRIPTION
    Uses ADSI to find if a user exists.  Returns true if so and false otherwise.
    
    .PARAMETER local
    [switch]: Look for a local user.
    
    .PARAMETER domain
    [switch]: Look for a domain user.
    
	.PARAMETER name
	[string]: The name of the user to look for.

	.PARAMETER domainName
	[string]: The name of the domain to search.
	
	.PARAMETER computerName
	[string]: The name of the computer to search.
	
    .INPUTS
    None.
    
    .OUTPUTS
    [bool]: True if the user exists or false otherwise.
    
    .EXAMPLE
    Test-UserExists -local "test"
#>

	[CmdletBinding(DefaultParameterSetName="Domain")]
    param(
        [Parameter(Mandatory=$TRUE, ParameterSetName="Local")]
            [switch]$local,

        [Parameter(Mandatory=$FALSE, ParameterSetName="Domain")]
            [switch]$domain,

        [Parameter(Mandatory=$FALSE, ParameterSetName="Domain")]
            [string]$domainName=$env:USERDOMAIN,

        [Parameter(Mandatory=$TRUE, ParameterSetName="Domain", position=1)]
        [Parameter(Mandatory=$TRUE, ParameterSetName="Local", position=1)]
            [string]$name,

        [Parameter(Mandatory=$FALSE, ParameterSetName="Local")]
            [string]$computerName=$env:COMPUTERNAME
    )
	$fargs = Get-FunctionParameters "Get-User"
	if($local){
		[void]$fargs.remove("domainName")
	}
	else{
		[void]$fargs.remove("computerName")
	}
	$user = Get-User @fargs
	return ($user | Test-ADSISuccess)

}

function Test-IsSameUser(){
<#
    .SYNOPSIS
    Tests to see if two accounts are the same.
    
    .DESCRIPTION
    Checks the SID of two accounts to look for equivalence. Returns true if
    the accounts have the same SID and false otherwise.
    
    
    .PARAMETER lhs
    [ADSI]: The left hand side of an equality test
    
    .PARAMETER rgs
    [ADSI]: The right hand side of an equality test
    
    .INPUTS
    None.
    
    .OUTPUTS
    [bool]: Returns true if two accounts are the same and false otherwise.
    
    .NOTES
    todo:
    	XXX Should be able to combine this with other user related functions
    	to be mroe generic.  (Instead of working on users and groups separately, 
		we can work on accounts generically.)
    
    .EXAMPLE
    Test-IsSameUser (Get-User -local "Administrator") (Get-User -local "Administrator")
#>
	param(
		[Parameter(Mandatory=$TRUE, position=1)]
            [ADSI]$lhs,
        [Parameter(Mandatory=$TRUE, position=2)]
            [ADSI]$rhs
	)
	return (Get-Sid $lhs).value -eq (Get-Sid $rhs).value
						
}

function New-User(){
<#
    .SYNOPSIS
    Create a new user.
    
    .DESCRIPTION
    Uses ADSI to create a new user.
    
    .PARAMETER local
    [switch]: Create new local user.
    
    .PARAMETER domain
    [switch]: Create new domain user.
    
    .PARAMETER name
    [string]: The name of the new user.
    
    .PARAMETER password
    [string]: The password for the new user.
    
    .PARAMETER computername
    [string]: The computer name to create the new local user on.
    
    .PARAMETER verify
    [switch]: Verify that the new user was created.
    
    .INPUTS
    None. 
    
    .OUTPUTS
    None.
    
    .NOTES
    todo:
    	XXX Investigate if the password is sent in the clear, and if so, use
    		securestring instead.
    
    .EXAMPLE
    
    New-User -local "joe" 
#>
	param(
        [Parameter(Mandatory=$TRUE, ParameterSetName="Local")]
            [switch]$local,

        [Parameter(Mandatory=$FALSE, ParameterSetName="Domain")]
            [switch]$domain,

        [Parameter(Mandatory=$FALSE, ParameterSetName="Domain")]
            [string]$domainName=$env:USERDOMAIN,

        [Parameter(Mandatory=$TRUE, ParameterSetName="Domain", position=1)]
        [Parameter(Mandatory=$TRUE, ParameterSetName="Local", position=1)]
            [string]$name,
            
        [Parameter(Mandatory=$TRUE, ParameterSetName="Domain")]
        [Parameter(Mandatory=$TRUE, ParameterSetName="Local")]
            [string]$password,

        [Parameter(Mandatory=$FALSE, ParameterSetName="Local")]
            [string]$computerName=$env:COMPUTERNAME,

        [switch]$verify
    )
	$computer = $NULL
	if($local){
		$computer = Get-ADSIComputer -computername $computername
	}
	else{
		#domain
		$computer = Get-ADSIDomain
		
	}	
	$user = $computer.create($SCN_USER, $name)
	$user.setPassword($password)
	$user.setinfo()		
	
	if($verify){
		Test-Assert {(Test-ADSISuccess ($computer.GetObject($SCN_USER, $name))) -eq $TRUE}
	}
	
				
}

function Remove-User(){
<#
    .SYNOPSIS
    Removes a user from a computer/domain.
    
    .DESCRIPTION
    Uses ADSI to remove a user.
    
    .PARAMETER local
    [switch]: Remove a local user.
    
    .PARAMETER domain
    [switch]: Remove a domain user.
    
    .PARAMETER name
    [string]: The name of the user to be removed.
    
    .PARAMETER computername
    [string]: The computer name to remove the local user from.
    
    .PARAMETER verify
    [switch]: Verify that the user was removed.
    
    .INPUTS
    None. 
    
    .OUTPUTS
    None.

    .EXAMPLE
    Remove-User -local "joe" 
#>
	param(
        [Parameter(Mandatory=$TRUE, ParameterSetName="Local")]
            [switch]$local,

        [Parameter(Mandatory=$FALSE, ParameterSetName="Domain")]
            [switch]$domain,

        [Parameter(Mandatory=$FALSE, ParameterSetName="Domain")]
            [string]$domainName=$env:USERDOMAIN,

        [Parameter(Mandatory=$TRUE, ParameterSetName="Domain", position=1)]
        [Parameter(Mandatory=$TRUE, ParameterSetName="Local", position=1)]
            [string]$name,

        [Parameter(Mandatory=$FALSE, ParameterSetName="Local")]
            [string]$computerName=$env:COMPUTERNAME,
        
        [switch]$verify
    )
	$computer = $NULL
	if($local){
		$computer = Get-ADSIComputer -computername $computername
		[void]$computer.Delete($SCN_USER, $name)	
			
	}
	else{
		#domain
		$computer = Get-ADSIDomain
		[void]$computer.Delete($SCN_USER, $name)
	}		
	if($verify){
		$user = $NULL
		try{
			$user = $computer.GetObject($SCN_USER, $name)
		}
		catch{}
		Test-Assert {$user -eq $NULL}	
		
	}
}


# SIG # Begin signature block
# MIIOwwYJKoZIhvcNAQcCoIIOtDCCDrACAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDESVGyctkO7qiP
# Z1yt6/3BbZgJb6Qkr/E06HMSVuRpU6CCC+MwggU4MIIEIKADAgECAhAL+AYYcFbO
# B4Q1jrTl6zCxMA0GCSqGSIb3DQEBBQUAMG8xCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xLjAsBgNV
# BAMTJURpZ2lDZXJ0IEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBLTEwHhcNMTQx
# MDA5MDAwMDAwWhcNMTUwOTIzMTIwMDAwWjCBjTELMAkGA1UEBhMCVVMxETAPBgNV
# BAgTCE1hcnlsYW5kMRMwEQYDVQQHEwpGb3J0IE1lYWRlMSowKAYDVQQKEyFJbmZv
# cm1hdGlvbiBBc3N1cmFuY2UgRGlyZWN0b3JhdGUxKjAoBgNVBAMTIUluZm9ybWF0
# aW9uIEFzc3VyYW5jZSBEaXJlY3RvcmF0ZTCCASIwDQYJKoZIhvcNAQEBBQADggEP
# ADCCAQoCggEBANpVP+Teg9dGEnPsWCln0dy4iAcLzEBLIA+9qGwQNk1trvRq+uvY
# yHmZzKgELuY+yzIhvn94AnISiMCufC2MqHpf3fNTQIzNY0ABfTPjti/LRG1ErvuN
# 2YpD6oDkOwwSpsA3dno6FNHvg99qdp+ELjftYPdLGUqNDd3psfXK46t0cgWBtysJ
# DLCVpMoyAlVBMZy28GSGYYVjvHhMPqBy2ZlYXRS0lTTWtFo0+PanFqhWnvwK3Cg+
# ip8kw17iBqTC9FfH3mbyZA8brb1Ihhjr44EQdbGJdzXBaodV8me7H+XmthNgXTii
# ZkxMlX2wiGAQXQ0q5+Hyi0qoo9b4UbYi0sUCAwEAAaOCAa8wggGrMB8GA1UdIwQY
# MBaAFHtozimqwBe+SXrh5T/Wp/dFjzUyMB0GA1UdDgQWBBTACYQFasXjQ4Ibq+1U
# cOxmiajiPDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwbQYD
# VR0fBGYwZDAwoC6gLIYqaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL2Fzc3VyZWQt
# Y3MtZzEuY3JsMDCgLqAshipodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vYXNzdXJl
# ZC1jcy1nMS5jcmwwQgYDVR0gBDswOTA3BglghkgBhv1sAwEwKjAoBggrBgEFBQcC
# ARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzCBggYIKwYBBQUHAQEEdjB0
# MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wTAYIKwYBBQUH
# MAKGQGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJ
# RENvZGVTaWduaW5nQ0EtMS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQUF
# AAOCAQEADchXouHNJ8uOb2RxgMmqLPeBTUu42ubkGYVn7jDMiQWsCnP8cPOmwzP8
# wMu67msc9u5eMtx6iIqIkhBXzPiSewOItmh5PbYhqEgN3Ig3PC0m+CepvVIhkHXi
# x27G22yG1kgUZxeu5DrAvYcIIQGdntcNrjCcz57NES7wIgKWE5fQTvBC5bhWhT+C
# 4ItmQZB2MoFfh42TZUntifeY+6vFQ+hFWFQKyktaxpUC4MFQnSIEr+OkVoiOgjLd
# A+afOR7YiVC3+WA8HMeSa8OmKqowtMuI5m9pgvByehgGs0HU0blNlMaudmgg3nwo
# ohrkvZB6AMxm5fS7M/9a4PXUyk+ypzCCBqMwggWLoAMCAQICEA+oSQYV1wCgviF2
# /cXsbb0wDQYJKoZIhvcNAQEFBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERp
# Z2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMb
# RGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTExMDIxMTEyMDAwMFoXDTI2
# MDIxMDEyMDAwMFowbzELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IElu
# YzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEuMCwGA1UEAxMlRGlnaUNlcnQg
# QXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EtMTCCASIwDQYJKoZIhvcNAQEBBQAD
# ggEPADCCAQoCggEBAJx8+aCPCsqJS1OaPOwZIn8My/dIRNA/Im6aT/rO38bTJJH/
# qFKT53L48UaGlMWrF/R4f8t6vpAmHHxTL+WD57tqBSjMoBcRSxgg87e98tzLuIZA
# RR9P+TmY0zvrb2mkXAEusWbpprjcBt6ujWL+RCeCqQPD/uYmC5NJceU4bU7+gFxn
# d7XVb2ZklGu7iElo2NH0fiHB5sUeyeCWuAmV+UuerswxvWpaQqfEBUd9YCvZoV29
# +1aT7xv8cvnfPjL93SosMkbaXmO80LjLTBA1/FBfrENEfP6ERFC0jCo9dAz0eoty
# S+BWtRO2Y+k/Tkkj5wYW8CWrAfgoQebH1GQ7XasCAwEAAaOCA0MwggM/MA4GA1Ud
# DwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDAzCCAcMGA1UdIASCAbowggG2
# MIIBsgYIYIZIAYb9bAMwggGkMDoGCCsGAQUFBwIBFi5odHRwOi8vd3d3LmRpZ2lj
# ZXJ0LmNvbS9zc2wtY3BzLXJlcG9zaXRvcnkuaHRtMIIBZAYIKwYBBQUHAgIwggFW
# HoIBUgBBAG4AeQAgAHUAcwBlACAAbwBmACAAdABoAGkAcwAgAEMAZQByAHQAaQBm
# AGkAYwBhAHQAZQAgAGMAbwBuAHMAdABpAHQAdQB0AGUAcwAgAGEAYwBjAGUAcAB0
# AGEAbgBjAGUAIABvAGYAIAB0AGgAZQAgAEQAaQBnAGkAQwBlAHIAdAAgAEMAUAAv
# AEMAUABTACAAYQBuAGQAIAB0AGgAZQAgAFIAZQBsAHkAaQBuAGcAIABQAGEAcgB0
# AHkAIABBAGcAcgBlAGUAbQBlAG4AdAAgAHcAaABpAGMAaAAgAGwAaQBtAGkAdAAg
# AGwAaQBhAGIAaQBsAGkAdAB5ACAAYQBuAGQAIABhAHIAZQAgAGkAbgBjAG8AcgBw
# AG8AcgBhAHQAZQBkACAAaABlAHIAZQBpAG4AIABiAHkAIAByAGUAZgBlAHIAZQBu
# AGMAZQAuMBIGA1UdEwEB/wQIMAYBAf8CAQAweQYIKwYBBQUHAQEEbTBrMCQGCCsG
# AQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0
# dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RD
# QS5jcnQwgYEGA1UdHwR6MHgwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmw0
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwHQYDVR0O
# BBYEFHtozimqwBe+SXrh5T/Wp/dFjzUyMB8GA1UdIwQYMBaAFEXroq/0ksuCMS1R
# i6enIZ3zbcgPMA0GCSqGSIb3DQEBBQUAA4IBAQB7ch1k/4jIOsG36eepxIe725SS
# 15BZM/orh96oW4AlPxOPm4MbfEPE5ozfOT7DFeyw2jshJXskwXJduEeRgRNG+pw/
# alE43rQly/Cr38UoAVR5EEYk0TgPJqFhkE26vSjmP/HEqpv22jVTT8nyPdNs3CPt
# qqBNZwnzOoA9PPs2TJDndqTd8jq/VjUvokxl6ODU2tHHyJFqLSNPNzsZlBjU1ZwQ
# PNWxHBn/j8hrm574rpyZlnjRzZxRFVtCJnJajQpKI5JA6IbeIsKTOtSbaKbfKX8G
# uTwOvZ/EhpyCR0JxMoYJmXIJeUudcWn1Qf9/OXdk8YSNvosesn1oo6WQsQz/MYIC
# NjCCAjICAQEwgYMwbzELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IElu
# YzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEuMCwGA1UEAxMlRGlnaUNlcnQg
# QXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EtMQIQC/gGGHBWzgeENY605eswsTAN
# BglghkgBZQMEAgEFAKCBhDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqG
# SIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3
# AgEVMC8GCSqGSIb3DQEJBDEiBCABC0TX0zY1ppEpul4XsZMUeLesDiyYGA6XbwvF
# D+jX1jANBgkqhkiG9w0BAQEFAASCAQBjKYoC4O7ygcUXBZbCvek9bokMFd/tVzjd
# nDr2KDY8XmfIuYm71OqE6bWJOWJdSVrKncIvaOrWN0UavpJ/TiCkk0xuaVG5NxyQ
# SUjB7yLEQUKiouOKDu49R32mW3oyMaoJDzcEPzZk8YxztRXGbu3eYhXbvotvcjHJ
# 4wb6D9qbUdFeHaTbBjEy7QPRRoVuu4/thftcOWTXp6wGOeJ6+R0fNr9Ss8OqeAF0
# xWrOGmmJblnQRbL7Wgyi9uHHunJaczXxA2YvVPAHt6NqtVd7BfUXtP54yuLlWZkF
# oFKeCYphEdctIkDSxVFcRwB9AJQzMMuZH2AYlYaE7/ARqr9aXB7E
# SIG # End signature block
