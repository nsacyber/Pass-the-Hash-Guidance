function Test-Assert(){
<#
    .SYNOPSIS
    
    Ensures that a specified assertion is true.
    
    .DESCRIPTION
    
    Evaluates a scriptblock and if that scriptblock evaluates to $TRUE, then success, otherwise an error is thrown.
    
    .PARAMETER sb
    
    [scriptblock]: A block of code that we want to assert to be true.

    .PARAMETER message
    
    [string]: The message to print if the assertion fails.
    
    .INPUTS
    None
    
    .OUTPUTS
    [$NULL|error]: Returns $NULL if the assertion succeeds and throws an exception and prints a stack trace if not.
    
    
    .EXAMPLE
    
    Test-Assert {(2 -eq 2)}
#>	
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$TRUE,position=1)]
			[scriptblock]$sb,
		[Parameter(Mandatory=$FALSE)]
			[string]$message= ""
	)
	$result = & $sb 
	if($result -eq $NULL){
		Get-PSCallStack
		throw "ScriptBlock returned null value"			
	}
	elseif($result.GetTypeCode() -notcontains "Boolean"){
		Get-PSCallStack
		throw "ScriptBlock did not return a boolean value"
	}
	
	if($result -eq $FALSE){
		Get-PSCallStack
		if($result.length -gt 0){
			
			Write-Error $message -ErrorAction Stop
		}
		else{
			throw "Assertion Failed $sb"
		}
	}

    

}