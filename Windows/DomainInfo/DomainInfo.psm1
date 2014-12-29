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
# SIG # Begin signature block
# MIIOwwYJKoZIhvcNAQcCoIIOtDCCDrACAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBw8+SDIGvR7vRH
# GrvAPK4JX0S6ta70vlFQ4XN2BjghhqCCC+MwggU4MIIEIKADAgECAhAL+AYYcFbO
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
# AgEVMC8GCSqGSIb3DQEJBDEiBCDY38zyzeFgMZv2LskWhEprlSASjaq7AmVr4oNl
# IQ4HzjANBgkqhkiG9w0BAQEFAASCAQB14KpyowGAwTXvQhiPxA6MPn3Vfug0bVtS
# xoQV6BbzbJsOKcYWshuydFbzBqV+ynVWYMPr2S7TjVLsE/LgkatJPnk4/Zl1n26H
# ornuA1gScV1JIRkAF569sbl7TgALZ8mGVVbpi/ob1W1a28gl+6JvSbJrVlRj6UBi
# L5ykkOh0LPvPrwX0GWSHzxbM0DFwpCOwp4WgcVybrvq9z5vLmmEl+maPHqvFDxHG
# jdxH9bTSxgUDT6r+j4tGiMp1tYUL0DyCgUqwVV6k65tIUkzF4Uh3OHec+vhyvATB
# bx1RKxF+eKWh2CyoE36Loc0hD6ey9kKZHicwS5W8H3V8j7mGaFLb
# SIG # End signature block
