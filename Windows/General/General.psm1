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