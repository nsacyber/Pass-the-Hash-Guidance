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