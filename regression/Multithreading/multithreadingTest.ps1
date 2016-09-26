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