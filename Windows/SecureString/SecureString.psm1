function Compare-SecureStrings(){
<#
    .SYNOPSIS
    
    Compares two secure strings for equivalence.
    
    .DESCRIPTION
    
    Converts two secure strings to their string representation and then compares them.  Returns $TRUE if they are
    equivalent and $FALSE otherwise.
    
    .PARAMETER lhs
    
    [System.Security.SecureString]: The left hand side of the equivalence operation.

    .PARAMETER rhs
    
    [System.Security.SecureString]: The right hand side of the equivalence operation.
    
    .INPUTS
    None
    
    .OUTPUTS
    [bool]: Converts two secure strings to their string representation and then compares them.  Returns $TRUE if they are
    equivalent and $FALSE otherwise.
    
#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$TRUE, position=1)]
			[System.Security.SecureString]$lhs,
		[Parameter(Mandatory=$TRUE, position=2)]
			[System.Security.SecureString]$rhs
	)
	return (ConvertFrom-SecureStringToString $lhs) -eq (ConvertFrom-SecureStringToString $rhs)
}

function ConvertFrom-SecureStringToBStr(){
<#
    .SYNOPSIS
    
    Converts a Secure String to a BStr.
    
    .DESCRIPTION
    
    Converts a Secure String to a BStr.
    
    .PARAMETER ss
    
    [System.Security.SecureString]: The secure string to be transformed into a bstr.
    
    .INPUTS
    None
    
    .OUTPUTS
    [System.String]: The string representing the secure string.
    
#>
    param(
        [System.Security.SecureString]$ss
    )
    return ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBStr($ss)))
                                          
}

function ConvertFrom-SecureStringToString(){
<#
    .SYNOPSIS
    
    Converts a Secure String to a string.
    
    .DESCRIPTION
    
    Converts a Secure String to a string.
    
    .PARAMETER ss
    
    [System.Security.SecureString]: The secure string to be transformed into a string.
    
    .INPUTS
    None
    
    .OUTPUTS
    [System.String]: The string representing the secure string.
    
#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$TRUE)]
			[System.Security.SecureString]$secureStr
	)
	#convert System.Security.SecureString to String
    #powershell auto-converts Bstr to String
    return ConvertFrom-SecureStringToBstr ($secureStr)
}


function New-SecureStringPrependedWithString(){
<#
    .SYNOPSIS
    
    Prepends a string to a secure string.
    
    .DESCRIPTION
    
    Prepends a string to a secure string.
    
    .PARAMETER str
    
    [System.String]: The string to prepend.

    .PARAMETER secureStr
    
    [System.Security.SecureString]: The secure string to be prepended to.
    
    .INPUTS
    None
    
    .OUTPUTS
    [System.Security.SecureString]: Returns a secure string with the string <str> prepended to the secure string <$secureStr>.
    
    
    .EXAMPLE
    
    $ss = New-Object System.Security.SecureString
    (65..75) | foreach{$ss.appendChar([char]$_)
    $newSS = New-SecureStringPrependedWithString "before" $ss
    
#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$TRUE, position=1)]
			[string]$str,
		[Parameter(Mandatory=$TRUE, position=2)]
			[System.Security.SecureString]$secureStr
	)
	$result = New-Object System.Security.SecureString
	$str.toCharArray() | foreach{$result.appendChar($_)}
	(ConvertFrom-SecureStringToString $secureStr).toCharArray() | foreach{$result.appendChar($_)}
	return , $result
	
									
}

function New-SecureStringAppendedWithString(){
<#
    .SYNOPSIS
    
    Appends a string to a secure string.
    
    .DESCRIPTION
    
    Appends a string to a secure string.
    
    .PARAMETER secureStr
    
    [System.Security.SecureString]: The secure string to be appended to.

    .PARAMETER str
    
    [System.String]: The string to append.
    
    .INPUTS
    None
    
    .OUTPUTS
    [System.Security.SecureString]: Returns a secure string with the string <str> appended to the secure string <$secureStr>.
    
    
    .EXAMPLE
    
    $ss = New-Object System.Security.SecureString
    (65..75) | foreach{$ss.appendChar(([char]$_))
    $newSS = New-SecureStringAppendedWithString $ss "before"
    
#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$TRUE, position=1)]
			[string]$str,
		[Parameter(Mandatory=$TRUE, position=2)]
			[System.Security.SecureString]$secureStr
	)
	$result = New-Object System.Security.SecureString
	(ConvertFrom-SecureStringToString $secureStr).toCharArray() | foreach{$result.appendChar($_)}
	$str.toCharArray() | foreach{$result.appendChar($_)}
	return , $result								
}