All of the attached code is meant to run from a system running at least Powershell 3.0 (CLR 4.0). Simply copy and paste all of the libraries into your Powershell module path ($env:PSModulePath) and import the modules. Much of the code provided is support libraries for doing various things on Windows-based domain and local systems.  A lot of the library functionality is based upon the Windows ActiveDirectory module.

There is also a multithreading library provided. It speeds up running the various scripts on large networks considerably.  One problem that occurs in a single-threaded environment stems from the bottleneck of Windows timeouts.  So, if you are running a task across every machine on the network and the current machine being processed is down, then the processing of the next machine will have to wait until the current task timeouts.  Powershell's built-in
concurrency model is process-based and starting up one process for each machine on the network is going to not scale well.  Doing this would require the user to write in some management code to limit the number of concurrent tasks. Enclosed is a multithreading library that uses a simple asynchronous concurrency model, which takes advantage of a lot of the embarrassingly parallel tasks that happen frequently when running much of the code across large networks.   Just use the multithreading package for your simple, embarassingly parallel tasks.  See the documentation in the multithreading package for more information.

Note, pay close attention to the Test-IsComputerAlive and Get-AllAliveComputers cmdlets in Windows\General they will help filter out boxes that are not currently up or are not reachable.  There are several parameters to these cmdlets that trade accuracy for speed.  If it is taking too long to run some of the scripts  (with respect to the size of the network because large networks will take a long time), investigate using these cmdlets to filter out unreachable boxes.

The main cmdlets are found in the PTHTools library and are discussed in the paper (Get-Help on the cmdlets to get more information):
Find-PotentialPtHEvents
Invoke-DenyNetworkAccess
Edit-AllLocalAccountPasswords
Get-LocalAccountSummaryOnDomain

The rest of the libraries provided are all supplementary things used to build up a lot of the functionality for the main ideas and for testing.  

If you have any feedback, ideas on improvement, or bug reports, then please let us know. 