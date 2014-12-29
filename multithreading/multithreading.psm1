$script:MAX_HANDLES = 63	# the most handles we can pass to waitHandle is 64.

function Initialize-ParallelTaskManager(){
<#
    .SYNOPSIS
    
    Constructor for multithreading manager object.
    
    .DESCRIPTION
    
    To enable the multithreading package, you need a multithreading manager.  The manager provides three
    interface methods: New_Task, Receive_Task, and Receive_AllTasks.

    These methods combined provide both asynchrony and synchrony.  See their respective script block implementations
    for further details
    
    .PARAMETER maxThreads
    
    [int]: The maximum number of threads to allow the manager to spawn.
    
    .INPUTS
    None
    
    .OUTPUTS
    [ParallelTaskManager]: This method is
    
    
    .EXAMPLE
    
    XXX - Example description 
#>	
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$TRUE)]
            [int]$maxThreads
    )
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Collections.ArrayList")
	$mgr = New-Object PSObject

    $runSpacePool = [RunspaceFactory]::CreateRunSpacePool(1, $maxThreads)
    $runspacePool.open()
    $mgr | add-member -membertype NoteProperty "RunspacePool" $runSpacePool

    $workers = [System.Collections.ArrayList]::Synchronized( (New-Object System.Collections.ArrayList) )
    $mgr | add-member -membertype NoteProperty "workers" $workers

    $New_TaskSB = {
        param(
			[Parameter(Mandatory=$TRUE)]
				[scriptblock]$sb, 
			[Parameter(Mandatory=$FALSE)]
				[array]$sbargs=@()
		)	#XXX see if powershell allows for Variable args, then get rid of this array nonsense.
        $res = New-Object PSObject 
        
        $job = [powershell]::Create().addscript($sb)
        foreach($sbarg in $sbargs){
            [void]$job.AddArgument($sbarg)
        }
        $res | add-member -membertype NoteProperty "job" $job
        
        $AsyncResult = $job.beginInvoke()
        $res | add-member -membertype NoteProperty "AsyncResult" $AsyncResult

        [void]$this.workers.add($res)
        return $res
        

    }
    $mgr | add-member -membertype ScriptMethod "New_Task" $New_taskSB

	$Receive_TaskSB = {
		param($asyncJob)		
		[void]$asyncJob.asyncResult.asyncWaitHandle.waitOne()
		$output = $asyncJob.job.endinvoke($asyncJob.asyncResult)
		Write-Output $output 
	}
	
	$mgr | add-member -membertype ScriptMethod "Receive_Task" $Receive_taskSB

    $Receive_AllTasksSB = {
        param()
        $result = $NULL
        $toRemove = @()
        do{
            $more = $FALSE
            $njobs = $this.workers.count
            if($njobs -gt $script:MAX_HANDLES){
                $njobs = $script:MAX_HANDLES
            }
            $handles = ($this.workers).getRange(0, $njobs) | foreach{$_.asyncResult.asyncWaitHandle} 

            [void][System.Threading.WaitHandle]::WaitAny($handles)
            foreach($result in $this.workers){
                if($result.AsyncResult.iscompleted -eq $TRUE){
                    Write-Output $result.job.endinvoke($result.asyncResult)
                    $result.job = $NULL
                    $result.asyncResult = $NULL
                    $toRemove += $result
                }
                elseif($result.job -ne $NULL){
                    $more = $TRUE
                }
            }
            foreach($result in $toRemove){
                [void]$this.workers.remove($result)

            }

        }while($more -eq $TRUE)
    }
    $mgr | add-member -membertype ScriptMethod "Receive_AllTasks" $Receive_alltasksSB

    return $mgr

}

function New-ParallelTaskManager(){
<#
    .SYNOPSIS
    
    XXX - Synopsis
    
    .DESCRIPTION
    
    XXX - Description
    
    .PARAMETER <p1>
    
    XXX [type]: P1 description
    
    .INPUTS
    XXX [type]: Pipeline input description 
    
    .OUTPUTS
    XXX [type]: Output description
    
    
    .EXAMPLE
    
    XXX - Example description 
#>	
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$FALSE)]    
            [int]$maxThreads=5
    )
    Initialize-ParallelTaskManager $maxThreads
}
# SIG # Begin signature block
# MIIOwwYJKoZIhvcNAQcCoIIOtDCCDrACAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCP2tVZFjsnRO8E
# rVdSQo63CdbszQL7H70CU4rApADwEqCCC+MwggU4MIIEIKADAgECAhAL+AYYcFbO
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
# AgEVMC8GCSqGSIb3DQEJBDEiBCAfijT6YSxfYg0t3OIEU3tiU4gsTyxzA7NixuAW
# iTwl9jANBgkqhkiG9w0BAQEFAASCAQAqpFvJonXh9Lh8K3roFEWCbJBR+ZzbMSfS
# Dj+yOUDmlvwmMMRHFP0G94p0drVnkChYLrp4IB4sPw/iYNBfYfa6RHlGrMm0PATB
# uMk8I9jLUTr28ux5C+yGHfqNDC5m+PDu4VkxE4ntkygKprhyuVeG31usGbzICO1Q
# REvQRYYETLFCN+DAv6TNXVH8yX47/UiOMeoahUccufp7+kwnKno7JBKcFXrmFdrC
# Br8oj1rZRtghZSfa1PkCoZRUWNOVgMSvU7PYxPH7I4Cpi9gTZ+I3VXj8x6iYzbwW
# 6WcZELbwmlhDmWbXqMBB3WPTwKBPRGnqV6MHRGBE9f4HwR19WqNl
# SIG # End signature block
