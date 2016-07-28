 # PtHTools
 
## Getting started

1. [Download](#downloading-the-repository) the repository as a zip file.
1. [Configure PowerShell](#configuring-the-powershell-environment) 
1. [Install the PtHTools modules](#installing-the-pthtools-modules)
1. [Run the PtHTools commands](#using-the-pthtools-module-commands)

## Downloading the repository

Download the [current code](https://github.com/iadgov/Pass-the-Hash-Guidance/archive/master.zip) to your **Downloads** folder. It should be saved as **Pass-the-Hash-Guidance-master.zip**.
 
## Configuring the PowerShell environment
The PowerShell commands are meant to run from a system with at least PowerShell 3.0 installed. PowerShell may need to be configured to run the commands.

### Changing the PowerShell execution policy

Users may need to change the default PowerShell execution policy. This can be achieved in a number of different ways:
* Open a command prompt and run **powershell.exe -ExecutionPolicy Bypass** or **powershell.exe -ExecutionPolicy Unrestricted** and run scripts from that PowerShell session.
* Open a PowerShell prompt and run **Set-ExecutionPolicy Unrestricted -Scope CurrentUser** and run scripts from any PowerShell session.
* Open an administrative PowerShell prompt and run **Set-ExecutionPolicy Unrestricted** and run scripts from any PowerShell session.

### Unblocking the PowerShell scripts
Users will need to unblock the downloaded zip file since it will be marked as having been downloaded from the Internet which PowerShell will block by default. Running the PowerShell scripts inside the zip file without unblocking the file will result in the following warning:

```
Security warning
Run only scripts that you trust. While scripts from the internet can be useful, this script can potentially harm your computer. If you trust this script, use the Unblock-File cmdlet to allow the script to run without this warning message. Do you want to run C:\users\user\Downloads\script.ps1?
[D] Do not run [R] Run once [S] Suspend [?] Help (default is "D"):
```

Open a PowerShell prompt and run the following commands to unblock the PowerShell code in the zip file:
1. **cd $env:USERPROFILE**
1. **cd Downloads**
1. **Unblock-File -Path '.\Pass-the-Hash-Guidance-master.zip'**

If the downloaded zip file is not unblocked before extracting it, then all the individual PowerShell files that were in the zip file will have to be unblocked. Open a PowerShell prompt and run **[System.IO.FileInfo[]]@(Get-ChildItem -Path '.\Pass-the-Hash-Guidance-master') -Recurse -Filter '\*.psm1' | Unblock-File**

See the [Unblock-File command's documentation](https://technet.microsoft.com/en-us/library/hh849924.aspx) for more information on how to use it.

## Installing the PtHTools modules
The PtHTools module, along with its supporting modules, need to be installed into your PowerShell module path before using the main commands.
1. Expand the **Pass-the-Hash-Guidance-master.zip** file inside your **Downloads** folder. Right clicking on the zip file, selecting Extract All, and clicking Next will create a **Pass-the-Hash-Guidance-master\Pass-the-Hash-Guidance-master** folder hierarchy.
1. Copy the **Assert**, **multithreading**, **Password**, **PtHTools**, **regression**, and **Windows** module folders to a path contained in the your PowerShell module path (see value of the the $env:PSModulePath environment variable). The %USERPROFILE%\Documents\WindowsPowerShell\Modules\ path is in the PowerShell module path by default.

The following PowerShell code will perform step #2 from above.

```
$downloadPath = ($env:USERPROFILE,'Downloads') -join '\'

cd $downloadPath

if (Test-Path -Path '.\Pass-the-Hash-Guidance-master' -PathType Container) {
    cd Pass-the-Hash-Guidance-master
}

if (Test-Path -Path '.\Pass-the-Hash-Guidance-master' -PathType Container) {
    cd Pass-the-Hash-Guidance-master
}

$userModulePath = $env:PSModulePath -split '\;' | Where-Object { $_.StartsWith($env:UserProfile) }

if (-not(Test-Path -Path $userModulePath -PathType Container)) {
   New-Item -Path $userModulePath -ItemType Directory | Out-Null
}

Get-ChildItem -Path '.\' | Where-Object { $_.PSIsContainer } | ForEach-Object { Copy-Item -Path $_ -Destination $userModulePath -Recurse -Force }
```

## Using the PtHTools module commands
The main PowerShell commands discussed in the paper and found in the PtHTools module are:
* Find-PotentialPtHEvents
* Invoke-DenyNetworkAccess
* Edit-AllLocalAccountPasswords
* Get-LocalAccountSummaryOnDomain
* Invoke-SmartcardHashRefresh

Use the Get-Help command (e.g. **Get-Help Invoke-SmartcardHashRefresh**) on the main commands to get more information on how to use them. 

To use one of the commands:
1. Open a PowerShell prompt
1. Import the PtHTools module (e.g. **Import-Module PtHTools**)
1. Run one of the main PtHTools commands (e.g. **Invoke-SmartcardHashRefresh**)

## About the other modules
The other modules (e.g. **mulithreading**, **Password**, and **Windows**) are support modules for performing various actions on Windows-based domain and standalone systems. These modules provide functionality used to build the main commands in the PtHTools modules. Some of the other modules (e.g. **Assert** and **regression**) are used for testing.

One problem that occurs stems from the bottleneck of Windows network timeouts. If you are running a task across every system on the network and the current system being processed is turned off or unreachable, then the processing of the next system has to wait until the current task times out which introduces significant delay. Another problem that occurs is that PowerShell's built-in concurrency model is process-based and starting a new process for each system on the network does not scale on large networks. The [multithreading module](./../multithreading/) provides a solution to both these problems.

The multithreading module uses a simple asynchronous concurrency model that takes advantage of a lot of the parallel tasks that happen frequently when running code across large networks. Use the multithreading module for simple, parallel tasks. See the documentation in the multithreading module for more information.

The Test-IsComputerAlive and Get-AllAliveComputers commands in the [Windows\General module](./../Windows/General/General.psm1) can help filter out systems that are not currently on or are unreachable. There are several parameters to these commands that trade accuracy for speed. If it is taking too long to run some of the scripts (with respect to the size of the network because large networks will take a long time), then investigate using these commands to filter out unreachable systems.