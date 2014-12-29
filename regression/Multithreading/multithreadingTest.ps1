Import-Module Multithreading -ErrorAction Stop -Force
Import-Module Windows\DomainInfo -Force -ErrorAction Stop

function Test-Barrier($sb){
    Write-Host "Testing Barrier"
    $mgr = New-ParallelTaskManager
    $servers = Get-DomainComputersSansDomainControllers 
    $servers = Get-AllComputersAlive -fast -multithreaded $servers
    if($servers.count -gt 0){

        Write-Host "Found $($servers.count) servers"
        for($i=0;$i -lt 10; $i++){
            Write-Host "Iteration $i"
            foreach($server in $servers){
                [void]$mgr.new_task($task, @($server))
            }
            $mgr.receive_alltasks()
        }
        
    }
    else{
        Write-Host "No servers found"
    }
}


function Test-Synchronous($sb){
    Write-Host "Testing Synchronous"
    $mgr = New-ParallelTaskManager
    $servers = Get-DomainComputersSansDomainControllers 
    $servers = Get-AllComputersAlive -fast -multithreaded $servers
    if($servers.count -gt 0){
        Write-Host "Found $($servers.count) servers"
        for($i=0;$i -lt 10; $i++){
            Write-Host "Iteration $i"
            foreach($server in $servers){
                
                $asyncJob = $mgr.new_task($task, @($server))
                $mgr.receive_task($asyncJob)
            }
        }
    }
    else{
        Write-Host "No servers found"
    }
}

function Test-ASynchronousBarrier($sb){
    Write-Host "Testing ASynchronousBarrier"
    $mgr = New-ParallelTaskManager
    $servers = Get-DomainComputersSansDomainControllers 
    $servers = Get-AllComputersAlive -fast -multithreaded $servers
    if($servers.count -gt 0){
        Write-Host "Found $($servers.count) servers"
        $asyncJobs = @()
        for($i=0;$i -lt 10; $i++){
            Write-Host "Iteration $i"
            foreach($server in $servers){
                $asyncJobs += $mgr.new_task($task, @($server))
            }
        
            foreach($asyncJob in $asyncJobs){
                $mgr.receive_task($asyncJob)
            }
        }
    }
    else{
        Write-Host "No servers found"
    }
}


function Main(){
    $task = {
        param($hostname)
        function Get-LocalAccountNames($machine="localhost"){
            return Get-WMIObject -computername $hostname Win32_UserAccount | where{ $_.localaccount -eq $TRUE} | foreach{$_.name}

        }
        
        function Get-LocalAdminAccountNames($machine){
            $group = Get-WMIObject -computername $hostname Win32_group -filter "name='Administrators'"
            return $group.GetRelated("Win32_UserAccount") | where{$_.localaccount -eq $TRUE} | foreach{$_.name}
            
        }
        try{
            Write-Output "`r`n$hostname"
            Write-Output "`t $(Get-LocalAccountNames $hostname)"
            Write-Output "`t $(Get-LocalAdminAccountNames $hostname)"
        }
        catch{
            Write-Output "Host is unavailable"

        }

    }

    Test-Synchronous $task
    Test-AsynchronousBarrier $task
    Test-Barrier $task

}

Main

# SIG # Begin signature block
# MIIOwwYJKoZIhvcNAQcCoIIOtDCCDrACAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCACcIrmpdUxDY/3
# Egk6FO4boLYdN1qL3VVl9qmw3y0nFaCCC+MwggU4MIIEIKADAgECAhAL+AYYcFbO
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
# AgEVMC8GCSqGSIb3DQEJBDEiBCBzuW5URd5OLIJTb2oyUXvYpePBNqXWdhseF9bh
# LnVdezANBgkqhkiG9w0BAQEFAASCAQApNv0Cbj/NaF7SL6Eow37dewedEotHxJbw
# A/DqxUkpup8PP6iAtt9AsGwNnerBlbD+1GNLRrlgNivufl09iL8WAqkdVjleZtbg
# 5LTw6xiJlGltguoygnDaZT/9i7Yv+SrMF/ZwR4Ae1b7/PBloNB8C4pivLrZ2a8WZ
# PagbW8q8smeuLhZusONjbzeWFvq6E2wtopdEHy3HbhWlez1CNx0rrnMvLO229Mnw
# fhKulkKDPBBWqHAbqVIKRy3Tuf3FckfeCg+j9POxPcF3ZG0Lvh1xl39PYUPgZnkS
# c4KC4C3FOAuqPoTGUuAvwv82gAtfNEwS+MalULWYXFNL6Djw/Ff9
# SIG # End signature block
