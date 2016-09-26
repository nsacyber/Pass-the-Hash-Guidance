function Get-Volume(){
<#
    .SYNOPSIS
    
    Gets a WMI-Object associated with the specified volume.
    
    .DESCRIPTION
    
    Returns a WMI-Object (Win32_LogicalDisk) associated witha  given volume qualifier.
    
    .PARAMETER $volumeQualifier
    
    [string]: The volume qualifier to find (C:, D:, etc.)
    
    .INPUTS
    None
    
    .OUTPUTS
    [System.Management.ManagementBaseObject]: Returns the logical disk WMI representation.
    
    
    .EXAMPLE
    
    Get-Volume C:
#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$TRUE, position=1)]
			[string]$volumeQualifier,	#C:, D:, etc
        [Parameter(Mandatory=$FALSE)]
            [string]$computerName=$env:COMPUTERNAME
	)
	$diskDrives = Get-WmiObject Win32_diskdrive -computerName $computerName
	foreach($drive in $diskDrives){
	    #loop over each drive and see if it is attached via usb
        $partitions = $($drive.GetRelated('Win32_DiskPartition'))
        foreach($partition in $partitions){
            #loop over each partition on the disk
            if($partition){
	            $logicalDisks = $($partition.GetRelated('Win32_LogicalDisk'))
	            foreach($logicalDisk in $logicalDisks){
	                #each partition has a logical disk or volume associated with it
	                if($logicalDisk -and ($logicalDisk.DeviceID.startswith($volumeQualifier))){
	                	return $logicalDisk
	                }
	            }
	        }
        }
	}							
}

function Test-isPathOnUSBDrive(){
<#
    .SYNOPSIS
    
    Determines if a path exists on a currently plugged in USB drive.
    
    .DESCRIPTION
    
    Returns $TRUE if the path exists on a currently plugged in USB drive or $FALSE otherwise.
    
    .PARAMETER path
    
    [string]: The path to test whether or not it exists on a usb location


    .INPUTS
    None
    
    .OUTPUTS
    [bool]: Returns $TRUE if the path exists on a currently plugged in USB drive or $FALSE otherwise.
    
    
    .EXAMPLE
    
    Test-IsPathOnUSBDrive "C:\users\user\desktop"
#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$TRUE, position=1)]
			[string]$path
	)
    $usbDrives = @(Get-USBDrives)
    if($usbDrives.count -eq 0){
        #XXX return $FALSE instead of throwing exception...let the user decide how they want to handle failure.
        throw "No USB Devices are Connected"
    }

	#convert path to the parent directory of the absolute path
	$absPath = [IO.Path]::GetFullPath($path)
	if((Test-Path (Split-Path -parent $path)) -eq $FALSE){
		#make sure the path exists
		[console]::WriteLine("The path: '$path' does not exist")
		throw "No such path exists"
	}
	else{
		foreach($drive in $usbDrives){
			#check to see if the path of the file starts with one of these USB drive letters
			if($path.startswith($drive)){
				return $TRUE
			}
		}
	}
	return $FALSE
}

function Get-USBDrives(){
<#
    .SYNOPSIS
    
    Get a list of all of the usb drives currently connected to <computerName>
    
    .DESCRIPTION
    
    Returns to the pipeline each volume qualifier, which corresponds to a USB Device
    
    .PARAMETER computerName
    
    [string]: The computername to query for its usb drives
    
    .INPUTS
    None
    
    .OUTPUTS
    [Pipeline<String>]: Returns to the pipeline each volume qualifier, which corresponds to a USB Device
    
    
    .EXAMPLE
    
    Get-USBDrives
#>
	[CmdletBinding()]
	param(
        [Parameter(Mandatory=$FALSE)]
			[string]$computername=$env:COMPUTERNAME
    )
	$diskDrives = Get-WmiObject Win32_diskdrive -computerName $computerName
	foreach($drive in $diskDrives){
	    #loop over each drive and see if it is attached via usb
	    if($drive.InterfaceType -eq "USB"){
	        $partitions = $($drive.GetRelated('Win32_DiskPartition'))
	        foreach($partition in $partitions){
	            #loop over each partition on the disk
	            $logicalDisks = $($partition.GetRelated('Win32_LogicalDisk'))
	            foreach($logicalDisk in $logicalDisks){
	                #each partition has a logical disk or volume associated with it
	                Write-Output $logicalDisk.DeviceID
	            }
	        }
	    }
	}
}
