

#domain
function Get-ADSIDomain(){
<#
    .SYNOPSIS
    
    Gets the associated domain ADSI object.
    
    .DESCRIPTION
    
    Returns an ADSI Object resulting from an ADSI domain query or $NULL if the
    domain is unavailable.
    
    .PARAMETER <domain>
    
    [string]: The name of the domain to search for
    
    .INPUTS
    None. 
    
    .OUTPUTS
    [ADSI] or $NULL: Returns an ADSI domain Object if the group exists or $NULL otherwise.
    
    .EXAMPLE
    
    Get-ADSIDomain "myDomain"
    
    Returns the ADSI domain object corresponding to the domain "myDomain" or
    $NULL if it is unavailable. 
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$FALSE, position=1)]
            [string]$domain=$env:USERDOMAIN
    
    )
    if($domain -ne $env:COMPUTERNAME){
        return Invoke-ADSIQuery "WinNT://$domain,domain"
    }
    else{
        throw "Computer: $env:computername is not domain Joined"
    }


}


#computer
function Get-ADSIComputer(){
<#
    .SYNOPSIS
    
    Gets the associated computer ADSI object.
    
    .DESCRIPTION
    
    Returns an ADSI Object resulting from an ADSI computer query or $NULL if the
    computer is unavailable.
    
    .PARAMETER computername
    
    [string]: The name of the computer to search for.
    
    .INPUTS
    [String]: See parameter <computerName> 
    
    .OUTPUTS
    [ADSI] or $NULL: Returns an ADSI Computer Object if the group exists or $NULL otherwise.
    
    
    .EXAMPLE
    
    Get-ADSIComputer -computername "test"
    
    Returns the ADSI object corresponding to the machine with hostname "test" or
    $NULL if it is unavailable.

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$FALSE, ValueFromPipeline=$TRUE, Position=1)]
            [string]$computerName = $env:COMPUTERNAME
    )
    BEGIN{}
    PROCESS{
           return Invoke-ADSIQuery "WinNT://$computerName,computer"
    }
    END{}


}



#group
function Get-ADSIGroup(){
<#
    .SYNOPSIS
    
    Gets the associated group ADSI object.
    
    .DESCRIPTION
    
    Returns an ADSI Object resulting from an ADSI group query or $NULL if the
    group does not exist.
    
    .PARAMETER group
    
    [string]: The name  of the group to search for.
    
    .PARAMETER domain
    
    [string]: The domain or computer to search for the user on.
    
    
    .INPUTS
    [String]: See parameter <group> 
    
    .OUTPUTS
    [ADSI] or $NULL: Returns an ADSI group Object if the group exists or $NULL otherwise.
    
    .EXAMPLE
    
    Get-ADSIGroup -group g1 -domain "test"
    
    Returns the ADSI object corresponding to the group (local or domain depending
    on whether test is a domain name or a machine name) or $NULL.

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$TRUE, ValueFromPipeline=$TRUE, Position=1) ]
            [string]$group,

        [Parameter(Mandatory=$FALSE ) ]
            [string]$domain = ($env:userdomain)
    )
    BEGIN{}
    PROCESS{
        return Invoke-ADSIQuery "WinNT://$domain/$group,group"
    }
    END{}
}


#user
function Get-ADSIUser(){
<#
    .SYNOPSIS
    
    Gets the associated user ADSI object.
    
    .DESCRIPTION
    
    Returns an ADSI Object resulting from an ADSI user query or $NULL if the
    ADSI user does not exist.
    
    .PARAMETER name
    
    [string]: The name of the user to search for.
    
    .PARAMETER domain
    
    [string]: The domain or computer to search for the user on.
    
    .INPUTS
    [string]: -name -> See parameter <name> 
    
    .OUTPUTS
    [ADSI] or $NULL: Returns an ADSI user object if the user exists or $NULL otherwise.
    
    
    .EXAMPLE
    
    Get-ADSIUser -name Joe -domain "test"
    
    Returns the ADSI object corresponding to the user "Joe" on domain "test"  or $NULL 
    if no such user exists.

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$TRUE, ValueFromPipeline=$TRUE, position=1) ]
            [string]$name,

        [Parameter(Mandatory=$FALSE) ]
            [string]$domain = ($env:userdomain)
    )
    BEGIN{}
    PROCESS{
        return Invoke-ADSIQuery "WinNT://$domain/$name,user"
    }
    END{}
}


function Invoke-ADSIQuery(){
<#
    .SYNOPSIS
    
    Internal interface to directly run an ADSI Query.  *This should not be
    called directly from user code.*
    
    .DESCRIPTION
    
    Returns an ADSI Object resulting from an ADSI query or $NULL if the
    ADSI query failed.
    
    .PARAMETER query
    
    [string]: A query that will be converted into an associated ADSI object
    
    .INPUTS
    None.  Does not accept pipelined input.
    
    .OUTPUTS
    [ADSI] or $NULL: ADSI object if the query was successful and $NULL otherwise.
    
    .EXAMPLE
    
    Invoke-ADSIQuery "WinNT://computerName/name,user"
    
    Returns the ADSI object corresponding to the local user denoted by name or
    $NULL if the user does not exist

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$TRUE, position=1)]
            [string]$query
    )
    $result = [ADSI]$query
    if(-not (Test-ADSISuccess $result)){
        $result = $NULL
    }
    return $result
}


function Test-ADSISuccess(){
<#
    .SYNOPSIS
    Tests the success of an ADSI Query by checking to see if the <path>
    instance variable exists (a property that all ADSI objects have).
    
    .DESCRIPTION
    Returns $TRUE if the ADSI object is real and $FALSE otherwise.
    
    ADSI queries always return a reference to an object and thus always appear
    to be successful until properties are inspected.  This method tests the
    path property, which is a universal property amongst ADSI objects.  If this
    test succeeds, $TRUE is returned or $FALSE otherwise.
    
    .PARAMETER object
    [ADSI]: ADSI object to test for success. 
    
    .INPUTS
    None.
    
    .OUTPUTS
    [boolean]
    
    .EXAMPLE
    Test-ADSISuccess (Get-User -local "test")
    
    Returns the ADSI object corresponding to the local user denoted by name or
    $NULL if the user does not exist

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$TRUE, ValueFromPipeline=$TRUE,  position=1)]
        [AllowNull()]
            [ADSI]$object
    )
    
    return [bool](([ADSI]$object).path)
                                 
}