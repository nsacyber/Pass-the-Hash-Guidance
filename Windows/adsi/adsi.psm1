

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







# SIG # Begin signature block
# MIIOwwYJKoZIhvcNAQcCoIIOtDCCDrACAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCATk1j3aJRKoLbp
# PL+VGSmleQJfdulGYSJ0w36VVWOCmaCCC+MwggU4MIIEIKADAgECAhAL+AYYcFbO
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
# AgEVMC8GCSqGSIb3DQEJBDEiBCALFxjnwDflkI2NS0RI9A+cJ5r5yiSGTS+i2JLC
# dgXXqDANBgkqhkiG9w0BAQEFAASCAQAyOtkn2hAUep7/k/LPkhtXpVs2bQt/Iw0G
# c4snCCLGtciVJByApzhj6656gRIkkjcD1hmpetmz/0QmM3gwiYcJyzFrLo3WQKQz
# LYXaTm9emTpZFEayMkpE7kMTw20YqCHg9ro/P9EW8T01/8cHmBOA3FBiKhmv9CpL
# xRBX450NVUYloWXgprtaSiuyIQYCgByYCjy88L+D16ESMdG4gOiJgH/uZqMRQjEX
# La61SNajFkws+GsQRPKZfAMsGgRXC+DrolQ9FGJ+AaNyNiqk+0DixcgrHHKKm50D
# C2ONeept2eaivzi+PRIC9lvhCit8DBax5yfOHw1Mba2rnWarjuWh
# SIG # End signature block
