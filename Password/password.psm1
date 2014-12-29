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
# SIG # Begin signature block
# MIIOwwYJKoZIhvcNAQcCoIIOtDCCDrACAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCJggIRWITJ9Jja
# Xr7yop4VVs7Kq1G365DF/XaFkoyTTKCCC+MwggU4MIIEIKADAgECAhAL+AYYcFbO
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
# AgEVMC8GCSqGSIb3DQEJBDEiBCD+3Atq5UavgQrHjarT18m7z0T+f8c596IxlOXK
# 2TUx6zANBgkqhkiG9w0BAQEFAASCAQC755OVYTEMeTrCqLRg2XjTu6n1HnzAVNp4
# EYQeqkGfSgDYFKzPXp+FLiOXFQG7gWblq5KWtqGcomtNHh5sy+T0uCNVAwkAZJZ+
# nJi6OidyBgpqgaTVDKPMhypJX5+wfwLKib3Gs7rrbe0A42ufiCdnpC7SZ6qoq3AQ
# hfnqTN0JKGSq+g6jR8ZCrEFfwdPB3Tnq7KIkrpXiqNpOmPqGRFpq8czGMF9JlqQw
# wzv7JSsNxJ5keeM6694BbM4PhCjBjkAo2ALA5G5bnluwkjkqc9N67l+/NFFGPoY0
# afi0c7+moaWqJ0Dl4YI8Mk0TaOALJlSlsJAxkvfhltAMPT7RsSS9
# SIG # End signature block
