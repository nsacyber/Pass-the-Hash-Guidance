Import-Module -force Assert
Import-Module -force multithreading
Import-Module -force Windows\FileSystem


$script:PING_SUCCESS = "Success" 
$script:nthreads = 50

$script:PORTS_TO_TEST_AWAKE = @(135,139, 445, 80, 5985)

$global:_asyncPingResults = @()

function Import-DotNetModule(){
<#
    .SYNOPSIS
    
    Load a .NET module into the namespace.

    (Deprecated)
    
    .DESCRIPTION
    
    Adds a .NET module to the namespace
    
    .PARAMETER packageName
    
    [string]: The fully qualified package name to be added.
    
    .INPUTS
    None
    
    .OUTPUTS
    None
    
    
    .EXAMPLE
    
    Import-DotNetModule "Microsoft.SqlServer.Management.SMO.Server"
#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$TRUE, position=1)]
			[string]$packageName
	)
	[void][System.Reflection.Assembly]::LoadWithPartialName($packageName)
}


function Test-ModuleExists(){
<#
    .SYNOPSIS
    
    Tests the existence of a module
    
    .DESCRIPTION
    
    Returns $TRUE if a module exists and $FALSE otherwise.
    
    .PARAMETER moduleName
    
    [string]: The name of the module to test for.
    
    .INPUTS
    None
    
    .OUTPUTS
    None
    
    
    .EXAMPLE
    
    Test-ModuleExists "General"

    Tests whether or not this module exists.
#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$TRUE, position=1)]
		[string]$moduleName
	)
    $res = $((Get-Module -listavailable).name -contains $moduleName)
	return $res
}


function Get-AllComputersAlive(){
<#
    .SYNOPSIS
    
    Tests if an array of hosts are currently available.
    
    .DESCRIPTION
    
    Provides a multithreaded and singlethreaded option for testing whether or not an array of hosts are currently
    available.  This method utilizes Test-IsComputerAlive -fast to make this determination.  The multithreaded version
    will spin up a new thread for each ping.  See the multithreading library for more information on the threading model.
    
    .PARAMETER computerNames
    
    [array]: An array of computer names to test.

    .PARAMETER multithreaded
    
    [switch]: Enable multithreaded mode (much faster, but requires the multithreading package associated with this release).
    
    .INPUTS
    None
    
    .OUTPUTS
    [pipeline]: Adds each hostname that is available to the pipeline.
    
    
    .EXAMPLE
    
    Get-AllComputersAlive -multithreaded @("machine1", "machine2")
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$TRUE, position=1, ValueFromPipeline=$TRUE)]
            [array]$computerNames,
        [Parameter(Mandatory=$FALSE)]
            [switch]$multithreaded,
        [Parameter(Mandatory=$FALSE)]
            [switch]$fast
    )
    BEGIN{}

    PROCESS{
        if($multithreaded){
            Test-Assert {(Test-ModuleExists "multithreading") -eq $TRUE} 
            $task = {
                param(
                    [string]$hostname
                )
                Import-Module Windows\General -force
                if(Test-IsComputerAlive -fast $hostname){
                    Write-Output $hostname
                }

            }
            $mgr = New-ParallelTaskManager
            try{
                $asyncJobs = @()
                foreach($computer in $computerNames){
                    $asyncJobs += $mgr.new_task($task, @($computer))
                }
       
                foreach($asyncJob in $asyncJobs){
                    $mgr.receive_task($asyncJob)
                }
            }
            finally{
                $mgr = $NULL
            }
        }
        else{
            foreach($computer in $computerNames){
                if($fast){
                    if(Test-IsComputerAlive -fast $computer){
                        Write-Output $computer
                    }
                }
                else{
                    if(Test-IsComputerAlive $computer){
                       Write-Output $computer
                    }

                }
            
            }

        }
    }
    END{}
}

function Test-IsComputerAlive(){
<#
    .SYNOPSIS
    
    Tests whether or not a host is up.
    
    .DESCRIPTION
    
    Returns $TRUE if any of the following tests pass for <computerName>:
    TCP connect to all ports in $script:PORTS_TO_TEST_AWAKE 
    Pings <computerName>.
    Test-Connect <computername>
    Get-WMIObject Win32_computersystem <computerName>

    Returns $FALSE otherwise.
    
    .PARAMETER computerName
    
    [string]: The computer's name to test.

    .PARAMETER fast
    
    [switch]: Enable fast mode, which doesn't do checks that take a long amount of time. It is less accurate, but faster.

    .PARAMETER timeout
    
    [int]: The maximum amount of time to wait for a tcp port check connection.
    
    .INPUTS
    [string]: See <computerName
    
    .OUTPUTS
    [bool]: $TRUE if <computerName> is up or $FALSE otherwise.
    
    
    .EXAMPLE
    
    Test-IsComputerAlive
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$TRUE, ValueFromPipeline=$TRUE, position=1)]
            [string]$computerName,
        [Parameter(Mandatory=$FALSE)]
            [switch]$fast,
        [Parameter(Mandatory=$FALSE)]
            [int]$timeout=500
    )
    $res = $NULL

    foreach($port in $script:PORTS_TO_TEST_AWAKE){
        #this is the fast case...
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpRes = $tcpClient.BeginConnect($computerName, $port, $NULL, $NULL)
        $res = $tcpRes.AsyncWaitHandle.WaitOne([System.TimeSpan]::FromMilliseconds($timeout))
        if([bool]$res){
            #Write-Host $port
            return $TRUE
        }

    }

    $res = $NULL
    try{
        $res =(Invoke-SynchronousPing $computerName)
    }
    catch [System.Net.NetworkInformation.PingException]{}
    if($fast){
        #do quick testing of whether or not a box is up
        return $res.Status -eq $script:PING_SUCCESS
    } 
    elseif($res.Status -eq $script:PING_SUCCESS){
        return $TRUE
    } 
    
    elseif((Test-Connection $computerName -quiet -count 1)){
        return $TRUE
    }
    elseif([bool](Get-WMIObject -class Win32_ComputerSystem -computername $computername -EA SilentlyContinue)){
        return $TRUE
    }
    #... add more tests as needed

    
    return $FALSE                             
                                  
}



function Invoke-SynchronousPing(){
<#
    .SYNOPSIS
    
    Attempts to ping a box.
    
    .DESCRIPTION
    
    Uses the .NET 4.0 API to ping a box and return the results.
    
    .PARAMETER computerName
    
    [string]: The computerName of the box to ping.

    .PARAMETER timeout
    
    [int]: The amount of time to wait (in milliseconds).
    
    .INPUTS
    [string]: See <computername>
    
    .OUTPUTS
    [System.Net.NetworkInformation.Ping]: The result of the ping
    
    
    .EXAMPLE
    
    Invoke-SynchronousPing "host1"
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$TRUE, ValueFromPipeline=$TRUE, position=1)]
            [string]$computerName,
        [Parameter(Mandatory=$FALSE)]
            [int]$timeout=5000
    )
    BEGIN{
          #AsyncPing is a .net 4 API
          Test-Assert{$PSVersiontable.clrversion.major -ge 4}
    }
    
    PROCESS{
        $ping = New-Object System.Net.NetworkInformation.Ping
        return $ping.send($computerName, $timeout)
            
            
    }
    
    END{}
                            
                            
}

<#
#CLR 4.0 doesn't have a good interface for asyncping
function Invoke-AsyncPing(){
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$TRUE, ValueFromPipeline=$TRUE, position=1)]
            [string]$computerName,
        [Parameter(Mandatory=$FALSE)]
            [int]$timeout=50000
    )
    BEGIN{
          #AsyncPing is a .net 4 API
          Test-Assert{$PSVersiontable.clrversion.major -ge 4}
    }
    
    PROCESS{
        $global:_asyncPingResults.clear()
        $jobs = @()
        $ping = New-Object System.Net.NetworkInformation.Ping
        
        $jobs += Register-ObjectEvent -Action {
            $reply = $event.SourceArgs[1].Reply
            $global:_asyncPingResults += ($reply | Select-Object Address, Status, RoundTripTime)
            Unregister-Event -SourceIdentifier $EventSubscriber.SourceIdentifier
                                               
        } -EventName PingCompleted -InputObject $ping
        Write-Host $jobs
        $ping.SendAsync($computerName, $timeout)
        Write-Host $jobs
        Get-Job | Wait-Job | Receive-Job
        return $global:_asyncPingResults
            
            
    }
    
    END{}
                            
                            
}
#>

function Test-SufficientDiskSpace(){
<#
    .SYNOPSIS
    
    Checks to see if the disk has enough data.
    
    .DESCRIPTION
    
    Returns $TRUE if the disk associated with <outFilePath> contains at least <minFileSpace> bytes and $FALSE otherwise
    
    .PARAMETER outFilePath
    
    [string]: The user-specified save path

    .PARAMETER minFileSpace
    
    [int]: The required space (in bytes) for a successful save.
    
    .INPUTS
    None
    
    .OUTPUTS
    [bool]: Returns $TRUE if the disk associated with <outFilePath> contains at least <minFileSpace> bytes and $FALSE otherwise
    
    
    .EXAMPLE
    
    Test-SufficientDiskSpace "C:\users\user\Desktop\out.txt" 25mb
#>
    param(
        [Parameter(Mandatory=$TRUE, position=1)]
            [string]$outFilePath,
        [Parameter(Mandatory=$TRUE, position=2)]
            [int]$minFileSpace
    )
    $volumeQualifier = Split-Path -path $([IO.Path]::GetFullPath($outFilePath)) -qualifier
    $volume = Get-Volume $volumeQualifier
    return $volume.FreeSpace -gt $minFileSpace                                
}




# SIG # Begin signature block
# MIIOwwYJKoZIhvcNAQcCoIIOtDCCDrACAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBv/NVL+pn2imeN
# 1uYWr5u000QKtSZmZTVeFbkHQDVIM6CCC+MwggU4MIIEIKADAgECAhAL+AYYcFbO
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
# AgEVMC8GCSqGSIb3DQEJBDEiBCBuXp1CtzTrOR9jbyzWoTz2tNmzIwvssC2V7Aov
# H+juQjANBgkqhkiG9w0BAQEFAASCAQAG8IIPi02GADddTcPzUqoARNYujRXsUQRF
# SVX0XFQW50jQGNXPSd58ja891pT+YeVxBtYJL5hjYQIWmTW0FvMQwFSqYnVNiMVl
# OTzQFZEbmBCetUP/aObjls/JBDbO0rWrlspHuZzz3UFV+u0+yD30AmV/sCwqjpW/
# jrmLbVBpA45ktiWMoQi6T+lb+ZnEzKfVKFgPfYUPUEt9UHtNK6J6ddfdyaYznt+X
# 2sGoh7KueCYkfBnaa24ZcIb2XUsqE/IchAOk71wetKOcCdOww8xEvmZr0nVpFUM0
# jNuB4ce8dkqL4CF60VofQCwTHDqvU9Eg3SMatfQiR+JgOt4iOEQL
# SIG # End signature block
