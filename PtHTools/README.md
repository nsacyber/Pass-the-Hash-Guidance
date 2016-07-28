 # PtHTools
 
 The main PowerShell commands are found in the PtHTools module and are discussed in the paper:
* Find-PotentialPtHEvents
* Invoke-DenyNetworkAccess
* Edit-AllLocalAccountPasswords
* Get-LocalAccountSummaryOnDomain

 Use the Get-Help command on the main commands to get more information on how to use them.
 
 The PowerShell commands are meant to run from a system with at least PowerShell 3.0 installed. Copy and paste all the modules into your PowerShell module path ($env:PSModulePath) and import the modules. 
  
 Much of the provided code is support modules for performing various actions on Windows-based domain and standalone systems. The modules provide functionality used to build the main commands.  

There is a [multithreading module](./../multithreading/) provided. It *considerably* speeds up running the various scripts on large networks. One problem that occurs stems from the bottleneck of Windows network timeouts. If you are running a task across every system on the network and the current system being processed is turned off or unreachable, then the processing of the next system has to wait until the current task timeouts which introduces significant delay. PowerShell's built-in concurrency model is process-based and starting up one process for each machine on the network does not scale well. The multithreading module provides a solution to both these problems.

The multithreading module uses a simple asynchronous concurrency model that takes advantage of a lot of the parallel tasks that happen frequently when running much of the code across large networks. Use the multithreading module for simple, parallel tasks. See the documentation in the multithreading module for more information.

The Test-IsComputerAlive and Get-AllAliveComputers commands in the [Windows\General module](./../Windows/General/General.psm1) can help filter out systems that are not currently on or are unreachable. There are several parameters to these commands that trade accuracy for speed. If it is taking too long to run some of the scripts (with respect to the size of the network because large networks will take a long time), then investigate using these commands to filter out unreachable systems.

Feedback, improvements, or bug reports should be submitted to the issue tracker.