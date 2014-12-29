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
# SIG # Begin signature block
# MIIOwwYJKoZIhvcNAQcCoIIOtDCCDrACAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBb3q0pp9tL7fc3
# YcUytgeUwF+B9w3rUn0rc1wGL7OXMqCCC+MwggU4MIIEIKADAgECAhAL+AYYcFbO
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
# AgEVMC8GCSqGSIb3DQEJBDEiBCC+OaIWZVggXHojsTKXq1K5wm2fBvEWMvYolhgS
# eylKWzANBgkqhkiG9w0BAQEFAASCAQCW4F9y+GzTw8A/f3t3B4Wyj56+JUPiN82s
# d+205jOaGCmgmOsrIAFwLE6KzkOl+AK3an2OfPCMDPq6IwdohqROnpW9sg8vM4M6
# SY6hwtmBAY4qWEseuDusdLd2pHFQE417UPskLn6IWJ3ls6RKv7mx6dHld5+Bhq5b
# Dcoaup7Q9i+TtndMtjjvaJv9Noc0B9z7ulC9fxXpNx7+b0jsB3cHVhV0riN9d0k2
# s11x2EjBqpg4MKLBc5Wy5mfpB6Kcvt8FdNbMpKeJViBwuujeOahb5fW0WetIwUmb
# ZzZN5jfw/4nxrmwCJu9sn4GMp9YUbK/D11ynX1QXoRCxGhKukXWh
# SIG # End signature block
