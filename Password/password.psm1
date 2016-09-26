import-module Windows\SecureString

function Read-PasswordFromUser(){
<#
    .SYNOPSIS
    
    Reads a password in from the user.
    
    .DESCRIPTION
    
    Loops until a password is entered successfully (it does not do complexity checking).   
    
    .INPUTS
    None
    
    .OUTPUTS
    [System.Security.SecureString]: The password in a secure string form.
#>
    param()   
    while($TRUE){
        #read in password
        $password1 = Read-Host -asSecureString "Enter password   "
        $password2 = Read-Host -asSecureString "Re-Enter password"
        if((Compare-SecureStrings $password1 $password2) -eq $FALSE){
            Write-Host "Passwords mismatched"
        }
        else{
            break
        }
    } 
    return $password1                     
                                 
}

function New-RandomPassword(){
<#
    .SYNOPSIS
    
    Creates a new random password.
    
    .DESCRIPTION
    
    Creates a new random password of length <length>.  
    
    With the complexity requirements switch enabled, the function tests to make sure
    that the new password contains an upper, lower, digit, and special character.

    .PARAMETER length
    
    [int]: The desired length of the password

    .PARAMETER complexityRequirements
    
    [switch]: Enable complexity requirements checking to ensure that the new password contains an upper, lower, digit, and special character.

    .PARAMETER minValue
    
    [int]: The minimum ascii value that is considered a valid input

    .PARAMETER maxValue
    
    [int]: The maximum ascii value that is considered a valid input
    
    .INPUTS
    None
    
    .OUTPUTS
    [System.Security.SecureString]: A newly created random password
    
    
    .EXAMPLE
    
    New-RandomPassword 18 -complexityRequirements 
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$TRUE)]
            [int]$length,
        [Parameter(Mandatory=$FALSE)]
            [switch]$complexityRequirements,
        [Parameter(Mandatory=$FALSE)]
            [int]$minValue=33,
        [Parameter(Mandatory=$FALSE)]
            [int]$maxValue=126
    )
                        
    BEGIN{
        [byte[]]$byte = New-Object Byte[] 1 
        $password = New-Object System.Security.SecureString 
        $random = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
        $containsLower = $containsUpper = $containsDigit = $containsSpecial = $FALSE
    }
    
    PROCESS{
        try{
            while(($password.length -lt $length) -or 
                  ((($containsLower -and $containsUpper -and $containsSpecial -and $containsDigit) -eq $FALSE) -and 
                   $complexityRequirements)){
                #loop as long as the password length < the desired password length or
                #the password does not conform to the password policy, which states
                #a password contains lower, upper, digits, and special chars.  Add
                #1 byte to the SecureString on each iteration iff it is in the desired ascii range.
                if($password.length -ge $length){
                    #password failed password policy restrictions
                    $password.clear() 
                    $containsLower = $containsUpper = $containsDigit = $containsSpecial = $FALSE
                }
                else{
                    
                    $random.getBytes($byte)
                    if(($byte[0] -ge $minValue) -and ($byte[0] -le $maxValue)){
                        $password.appendChar([char]$byte[0])
                        if($complexityRequirements){
                            if([char]::IsLower($byte[0])){
                                $containsLower = $TRUE
                            }
                            elseif([char]::IsUpper($byte[0])){
                                $containsUpper = $TRUE
                            }
                            elseif([char]::IsDigit($byte[0])){
                                $containsDigit = $TRUE
                            }
                            elseif(([char]::IsSymbol($byte[0])) -or ([char]::IsPunctuation($byte[0]))){
                                $containsSpecial = $TRUE
                            }
                        }
                    }
                }
                                                                                                                                                           
            }
            [void]$password.makeReadOnly()
            return $password 
        }
        finally{
            $passwordByteArray = $NULL
            $random = $NULL
        }
            
    }
    
    END{
        
        
    }
                        
                        
}