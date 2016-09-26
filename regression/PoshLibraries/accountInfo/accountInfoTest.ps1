Import-Module Assert -force
Import-Module Windows\AccountInfo -force

$LOCALHOST = $env:COMPUTERNAME
$DOMAIN = $env:USERDOMAIN

$REMOTE_COMPUTER = "c2"
$USER_NAME = "$($LOCALHOST)_user1"
$REMOTE_USER_NAME = "$($REMOTE_COMPUTER)_user1"
$DOMAIN_USER_NAME = "$($DOMAIN)_user1"


$BAD_USER_NAME = "asdfasdfasdfasdf"
$ADMINISTRATOR_NAME = "Administrator"


$GROUP_NAME = "test_group"
$BAD_GROUP_NAME = "asdfasdfasdfasdfasdf"

$PASSWORD = "!@#QWERASDF1234qwerasdf" 

function Create-Groups(){
    #local
    if((Test-GroupExists -local $GROUP_NAME) -eq $TRUE){
        Remove-Group -local $GROUP_NAME
    }        
    New-Group -local $GROUP_NAME -verify
    
    
    #remote
    if((Test-GroupExists -local -computerName $REMOTE_COMPUTER $GROUP_NAME) -eq $TRUE){
        Remove-Group -local $GROUP_NAME -computername $REMOTE_COMPUTER
    }
    New-Group -local $GROUP_NAME -computername $REMOTE_COMPUTER -verify
    
    #domain
    if((Test-GroupExists -domain $GROUP_NAME) -eq $TRUE){
        Remove-Group -domain $GROUP_NAME
    }
    New-Group -domain $GROUP_NAME  -verify
    
}

function Initialize-Users(){
    
    if((Test-UserExists -local $USER_NAME) -eq $FALSE){
        New-User -local $USER_NAME -password $PASSWORD -verify
    }
                        
    if((Test-UserExists -local $REMOTE_USER_NAME -computername $REMOTE_COMPUTER) -eq $FALSE){
        New-User -local $REMOTE_USER_NAME -computername $REMOTE_COMPUTER  -password $PASSWORD -verify
    }
                        
    if((Test-UserExists -domain $DOMAIN_USER_NAME) -eq $FALSE){
        New-User -domain $DOMAIN_USER_NAME  -password $PASSWORD -verify
    }
                        
                        
}

function Uninitialize-Users(){
    if((Test-UserExists -local $USER_NAME) -eq $TRUE){
        Remove-User -local $USER_NAME -verify
    }
    if((Test-UserExists -local $REMOTE_USER_NAME -computername $REMOTE_COMPUTER) -eq $TRUE){                              
        Remove-User -local $REMOTE_USER_NAME -computername $REMOTE_COMPUTER -verify
    }
    if((Test-UserExists -domain $DOMAIN_USER_NAME) -eq $TRUE){
        REmove-User -domain $DOMAIN_USER_NAME -verify
    }
                        
}

function Initialize-GroupMembers(){
    if(((Test-UserExists -local $USER_NAME) -eq $FALSE) -or 
       ((Test-UserExists -local $REMOTE_USER_NAME -computername $REMOTE_COMPUTER) -eq $FALSE) -or
        ((Test-UserExists -domain $DOMAIN_USER_NAME) -eq $FALSE) ){
        
        Initialize-Users
    }
    Uninitialize-GroupMembers
    Add-GroupMember -group $GROUP_NAME -local -user $USER_NAME                   
    Add-GroupMember -group $GROUP_NAME -local -user $REMOTE_USER_NAME -computername $REMOTE_COMPUTER                 
    Add-GroupMember -group $GROUP_NAME -domain -user $DOMAIN_USER_NAME                      
}

function Uninitialize-GroupMembers(){
    $user = Get-User -local $USER_NAME
    $group = Get-Group -local $GROUP_NAME
    if(($user -ne $NULL) -and ($group -ne $NULL) -and ((Test-GroupMembership -user $user -group $group) -eq $TRUE)) {
        Remove-GroupMember -group $GROUP_NAME -local -user $USER_NAME
    }
    
    $user = Get-User -local $REMOTE_USER_NAME -computername $REMOTE_COMPUTER
    $group = Get-Group -local $GROUP_NAME -computername $REMOTE_COMPUTER
    if(($user -ne $NULL) -and ($group -ne $NULL) -and ((Test-GroupMembership -user $user -group $group) -eq $TRUE)){                              
        Remove-GroupMember -group $GROUP_NAME -local -user $REMOTE_USER_NAME -computername $REMOTE_COMPUTER
    }
                                     
    $user = Get-User -domain $DOMAIN_USER_NAME
    $group = Get-Group -domain $GROUP_NAME                             
    if(($user -ne $NULL) -and ($group -ne $NULL) -and (Test-GroupMembership -user $user -group $group) -eq $TRUE){
        Remove-GroupMember -group $GROUP_NAME -domain -user $DOMAIN_USER_NAME
    }                  
                     
    
                                     
}



function Initialize-Groups(){
    if(Test-GroupExists -local -name $GROUP_NAME){
        Remove-Group -local -name $GROUP_NAME
    }                       
    New-Group -local -name $GROUP_NAME  
    
   
    if((Test-GroupExists -local -computername $REMOTE_COMPUTER -name $GROUP_NAME) -eq $TRUE){
        Remove-Group -local -computername $REMOTE_COMPUTER -name $GROUP_NAME
    }
    New-Group -local -name $GROUP_NAME -computername $REMOTE_COMPUTER
    
    if(Test-GroupExists -domain $GROUP_NAME){
        Remove-Group -domain -name $GROUP_NAME
    }                       
    New-Group -domain -name $GROUP_NAME
}

function Uninitialize-Groups(){
     if(Test-GroupExists -local -name $GROUP_NAME){
        Remove-Group -local -name $GROUP_NAME
    }                       
   
    if((Test-GroupExists -local -computername $REMOTE_COMPUTER -name $GROUP_NAME) -eq $TRUE){
        Remove-Group -local -computername $REMOTE_COMPUTER -name $GROUP_NAME
    }
    
    if(Test-GroupExists -domain $GROUP_NAME){
        Remove-Group -domain -name $GROUP_NAME
    }                       
}


function Initialize-Environment(){
    Initialize-Groups
    Initialize-Users
   
}

function Uninitialize-Environment(){
    Uninitialize-Groups
    Uninitialize-Users  
}

function Test-TestUserExists(){
    #local exists
    Test-Assert{(Test-UserExists -local -name $USER_NAME) -eq $TRUE}
    
    #local doesn't exist
    Test-Assert{(Test-UserExists -local -name $BAD_USER_NAME) -eq $FALSE}

    #local remote exists
    Test-Assert{(Test-UserExists -local -name $REMOTE_USER_NAME -computername $REMOTE_COMPUTER) -eq $TRUE}
    
    #local remote doesn't exist
    Test-Assert{(Test-UserExists -local -name $BAD_USER_NAME -computername $REMOTE_COMPUTER) -eq $FALSE}
    
    #domain exists
    Test-Assert{(Test-UserExists -domain -name $DOMAIN_USER_NAME) -eq $TRUE}                          
    
    #domain doesn't exists
    Test-Assert{(Test-UserExists -domain -name $BAD_USER_NAME) -eq $FALSE}
}

function Test-TestNewUser(){
    Uninitialize-Users
    
    #local
    Test-Assert {(Test-UserExists -local -name $USER_NAME) -eq $FALSE}
    New-User -local $USER_NAME -password $PASSWORD -verify
    Test-Assert {(Test-UserExists -local -name $USER_NAME) -eq $TRUE}
    
    
    #local remote                  
    Test-Assert {(Test-UserExists -local -name $USER_NAME -computername $REMOTE_COMPUTER) -eq $FALSE}
    New-User -local $REMOTE_USER_NAME -computername $REMOTE_COMPUTER  -password $PASSWORD -verify
    Test-Assert {(Test-UserExists -local -name $REMOTE_USER_NAME -computername $REMOTE_COMPUTER) -eq $TRUE}
        
    #domain     
    Test-Assert {(Test-UserExists -domain -name $DOMAIN_USER_NAME) -eq $FALSE}               
    New-User -domain $DOMAIN_USER_NAME  -password $PASSWORD -verify
    Test-Assert {(Test-UserExists -domain -name $DOMAIN_USER_NAME) -eq $TRUE}
}

function Test-TestRemoveUser(){
    #local
    Test-Assert {(Test-UserExists -local -name $USER_NAME) -eq $TRUE}
    Remove-User -local $USER_NAME -verify
    Test-Assert {(Test-UserExists -local -name $USER_NAME) -eq $FALSE}
    
    #local remote  
    Test-Assert {(Test-UserExists -local -name $REMOTE_USER_NAME -computername $REMOTE_COMPUTER) -eq $TRUE}                      
    Remove-User -local $REMOTE_USER_NAME -computername $REMOTE_COMPUTER -verify
    Test-Assert {(Test-UserExists -local -name $REMOTE_USER_NAME -computername $REMOTE_COMPUTER) -eq $FALSE}
    
    #domain
    Test-Assert {(Test-UserExists -domain -name $DOMAIN_USER_NAME) -eq $TRUE}
    REmove-User -domain $DOMAIN_USER_NAME -verify
    Test-Assert {(Test-UserExists -domain -name $DOMAIN_USER_NAME) -eq $FALSE}
    
}


#GET-USER Testing

function Test-GetUser(){
    #test get local user, exists
    $res =$NULL
    $res = Get-User -local -name $USER_NAME
    Test-Assert {($res -ne $NULL) -and ((Test-IsLocaluser $res) -eq $TRUE)}
    
    #test get local user, !exists
    $res = $NULL
    $res = Get-User -local -name BAD_USER_NAME
    Test-Assert {$res -eq $NULL}
    
    #test get remote local user, exists
    $res =$NULL
    $res = Get-User -local -computername $REMOTE_COMPUTER -name  $REMOTE_USER_NAME
    Test-Assert {($res -ne $NULL) -and ((Test-IsLocalUser -computerName $REMOTE_COMPUTER $res) -eq $TRUE)}
    
    #test get domain user, exists
    $res =$NULL
    $res = Get-User -domain -name $ADMINISTRATOR_NAME
    Test-Assert {($res -ne $NULL) -and ((Test-IsLocalUser $res) -eq $FALSE)}
    
    #test get domain user, !exists
    $res =$NULL
    $res = Get-User -domain -name $BAD_USER_NAME
    Test-Assert {$res -eq $NULL}
}

function Test-TestIsLocalUser(){
    $res = $NULL
    $localUsers = Get-Group -local | Get-GroupMembers -local
    #all should be true
    $res = $localusers | foreach{Test-IsLocalUser $_} | Where{$_ -eq $FALSE}
    Test-Assert {$res -eq $NULL}
    
    #all should be true
    $localRemoteUsers = Get-Group -local -computerName $REMOTE_COMPUTER | Get-GroupMembers -local -computerName $REMOTE_COMPUTER
    $res = $localRemoteUsers | foreach{Test-IsLocalUser -computerName $REMOTE_COMPUTER $_} | Where{$_ -eq $FALSE}
    Test-Assert {$res -eq $NULL}
    
    $domainUsers = Get-Group -domain | Get-GroupMembers -domain
    $res = $domainusers | foreach{Test-IsLocalUser $_} | Where{$_ -eq $TRUE}
    Test-Assert {$res -eq $NULL}
}


function Test-TestGroupExists(){
    #test localgroup exists
    $res =$NULL
    $res = Test-GroupExists -local -name $GROUP_NAME
    Test-Assert {$res -eq $TRUE}
    
    #test localgroup does not exists
    $res =$NULL
    $res = Test-GroupExists -local -name $BAD_GROUP_NAME
    Test-Assert {$res -eq $FALSE}
    
    #test domaingroup exists
    $res =$NULL
    $res = Test-GroupExists -domain -name $GROUP_NAME
    Test-Assert {$res -eq $TRUE}
    
    #test localgroup does not exists
    $res =$NULL
    $res = Test-GroupExists -domain -name $BAD_GROUP_NAME
    Test-Assert {$res -eq $FALSE}
    
    #test group exists amongst all groups
    $res =$NULL
    $res = Test-GroupExists -all -name $GROUP_NAME
    Test-Assert {$res -eq $TRUE}
    
    #test group doesn't exist amongst all groups
    $res =$NULL
    $res = Test-GroupExists -all -name $BAD_GROUP_NAME
    Test-Assert {$res -eq $FALSE}
}

function Test-GetGroupLocal(){
    #test get all groups on local machine
    $res =$NULL
    $res = Get-Group -local
    Test-Assert {($res | Test-ADSISuccess) -eq $TRUE }
    Test-Assert {($res | foreach{Test-IsLocalGroup $_} | Where{$_ -eq $FALSE}).count -eq 0 }
    #Test-Assert {($($res.path -match "$LOCALHOST/$GROUP_NAME").count -gt 0)}              
    
    #Test one group
    $res =$NULL
    $res = Get-Group -local -name $GROUP_NAME
    Test-Assert {($res | Test-ADSISuccess) -eq $TRUE }
    Test-Assert {($($res.path -match "$LOCALHOST/$GROUP_NAME").count -gt 0)}
    
    #Test one group
    $res =$NULL
    $res = Get-Group -local -name $BAD_GROUP_NAME
    Test-Assert {($res | Test-ADSISuccess) -eq $FALSE }
        
    #test one group on remote machine
    $res =$NULL
    $res = Get-Group -local -name $GROUP_NAME -computername $REMOTE_COMPUTER
    Test-Assert {($res | Test-ADSISuccess) -eq $TRUE}
    Test-Assert {($($res.path -match "$REMOTE_COMPUTER/$GROUP_NAME").count -gt 0)}
    
    #test one group on remote machine doesn't exist
    $res =$NULL
    $res = @(Get-Group -local -name $BAD_GROUP_NAME -computername $REMOTE_COMPUTER)
    Test-Assert {($res | Test-ADSISuccess) -eq $FALSE}
}

function Test-GetGroupDomain(){
    #test get all domain groups
    $res =$NULL
    $res = Get-Group -domain
    Test-Assert {($res | Test-ADSISuccess) -eq $TRUE}
    Test-Assert {($($res.path -match "$DOMAIN/$GROUP_NAME").count -gt 0)}              
    
    #Test one domain group
    $res =$NULL
    $res = Get-Group -domain -name $GROUP_NAME
    Test-Assert {($res | Test-ADSISuccess) -eq $TRUE}
    Test-Assert {($($res.path -match "$DOMAIN/$GROUP_NAME").count -gt 0)}
    
    #Test domain group doesn't exist
    $res =$NULL
    $res = Get-Group -domain -name $BAD_GROUP_NAME
    Test-Assert {($res | Test-ADSISuccess) -eq $FALSE }
}

function Test-NewGroupLocal(){
    UnInitialize-Groups
                              
    if(Test-GroupExists -local -name $GROUP_NAME){
        Remove-Group -local -name $GROUP_NAME
    }                       
    New-Group -local -name $GROUP_NAME
    Test-Assert {(Test-GroupExists -local $GROUP_NAME) -eq $TRUE}
}

function Test-NewGroupDomain(){
    UnInitialize-Groups                           
    
    if(Test-GroupExists -domain $GROUP_NAME){
        Remove-Group -domain -name $GROUP_NAME
    }                       
    New-Group -domain -name $GROUP_NAME
    Test-Assert {(Test-GroupExists -domain $GROUP_NAME) -eq $TRUE}
}

function Test-RemoveGroupLocal(){
    Remove-Group -local -name $GROUP_NAME
    Test-Assert {(Test-GroupExists -local $GROUP_NAME) -eq $FALSE}                        
    
}

function Test-RemoveGroupDomain(){
    Remove-Group -domain -name $GROUP_NAME
    Test-Assert {(Test-GroupExists -domain $GROUP_NAME) -eq $FALSE}
                               
}




function Test-GetGroupMembers(){
    Initialize-GroupMembers
    try{
        #Test Get-GroupMembers -local
        $res =$NULL
        $res = Get-Group -local -name $GROUP_NAME | Get-GroupMembers -local
        Test-Assert {($res | Test-ADSISuccess) -eq $TRUE}
        Test-Assert {($res.name | where {$_ -eq $USER_NAME}) -ne $NULL}
        
        #Test-GetGroupMembers -local not exists
        $res =$NULL
        $res = Get-Group -local -name $BAD_GROUP_NAME | Get-GroupMembers -local
        Test-Assert {($res | Test-ADSISuccess) -eq $FALSE}
        
        
        #Test Get-GroupMembers -local
        $res =$NULL
        $res = Get-Group -local -name $GROUP_NAME -computername $REMOTE_COMPUTER | Get-GroupMembers -local -computername $REMOTE_COMPUTER 
        Test-Assert {($res | Test-ADSISuccess) -eq $TRUE}
        Test-Assert {($res.name | where {$_ -eq $REMOTE_USER_NAME}) -ne $NULL}
        
        
        #Test Get-GroupMembers -domain
        $res =$NULL
        $res = Get-Group -domain -name $GROUP_NAME | Get-GroupMembers -domain
        Test-Assert {($res | Test-ADSISuccess) -eq $TRUE}
        Test-Assert {($res.name | where {$_ -eq $DOMAIN_USER_NAME}) -ne $NULL}
        
        #Test Get-GroupMembers -domain not exists
        $res =$NULL
        $res = Get-Group -domain -name $BAD_GROUP_NAME | Get-GroupMembers -domain
        Test-Assert {($res | Test-ADSISuccess) -eq $FALSE}
    }
    finally{
        Uninitialize-GroupMembers
    }
}

function Test-AddGroupMember(){
    $res = $NULL
    
    Add-GroupMember -group $GROUP_NAME -local -user $USER_NAME   
    $res = Get-User -local -name $USER_NAME
    Test-Assert {(Test-ADSISuccess $res) -eq $TRUE}
    $members = Get-Group -local  -name $GROUP_NAME |  Get-GroupMembers -local -username $USER_NAME
    Test-Assert {($members | Test-ADSISuccess) -eq $TRUE}
 
                               
    #remote
    $res = $NULL
    
    Add-GroupMember -group $GROUP_NAME -local -user $REMOTE_USER_NAME -computername $REMOTE_COMPUTER
    $res = Get-User -local -name $REMOTE_USER_NAME -computername $REMOTE_COMPUTER
    Test-Assert {(Test-ADSISuccess $res) -eq $TRUE}
    $members = Get-Group -local -computername $REMOTE_COMPUTER -name $GROUP_NAME |  Get-GroupMembers -local -username $REMOTE_USER_NAME -computername $REMOTE_COMPUTER 
    Test-Assert {($members | Test-ADSISuccess) -eq $TRUE}
    
    #domain
    $res = $NULL
    Add-GroupMember -group $GROUP_NAME -domain -user $DOMAIN_USER_NAME 
    $res = Get-User -domain -name $DOMAIN_USER_NAME 
    Test-Assert {(Test-ADSISuccess $res) -eq $TRUE}
    $members = Get-Group -domain -name $GROUP_NAME |  Get-GroupMembers -domain -username $DOMAIN_USER_NAME
    Test-Assert {($members | Test-ADSISuccess) -eq $TRUE}
}

function Test-RemoveGroupMember(){
    Initialize-GroupMembers
    try{
        #local
        Remove-GroupMember -group $GROUP_NAME -local -user $USER_NAME
        $members = Get-Group -local  -name $GROUP_NAME |  Get-GroupMembers -local -username $USER_NAME
        Test-Assert {($members | Test-ADSISuccess) -eq $FALSE}
        
        
        #remote
        Remove-GroupMember -group $GROUP_NAME -local -user $REMOTE_USER_NAME -computername $REMOTE_COMPUTER
        $members = Get-Group -local -computername $REMOTE_COMPUTER -name $GROUP_NAME |  Get-GroupMembers -local -username $REMOTE_USER_NAME -computername $REMOTE_COMPUTER
        Test-Assert {($members | Test-ADSISuccess) -eq $FALSE}
        
        #domain
        Remove-GroupMember -group $GROUP_NAME -domain -user $DOMAIN_USER_NAME
        $members = Get-Group -domain  -name $GROUP_NAME |  Get-GroupMembers -domain -username $DOMAIN_USER_NAME
        Test-Assert {($members | Test-ADSISuccess) -eq $FALSE}
    }
    finally{
        Uninitialize-GroupMembers
    }
}

#################
#User Account
#################

$success = $TRUE


#Test-UserExists
Write-Host "Testing Test-UserExists..." -nonewline
Initialize-Environment
try{
    Test-TestUserExists
    Write-Host "success"
}
catch{
    Write-Host "fail"
    $success= $FALSE
}
finally{
    Uninitialize-Environment
}
        



#New-User
Write-Host "Testing New-User..." -nonewline
Initialize-Environment
try{
    Test-TestNewUser
    Write-Host "success"
}
catch{
    Write-Host "fail"
    $success= $FALSE
}
finally{
    Uninitialize-Environment
}


#Remove-User
Write-Host "Testing Remove-User..." -nonewline
Initialize-Environment
try{
    Test-TestRemoveUser
    Write-Host "success"
}
catch{
    Write-Host "fail"
    $success= $FALSE
}
finally{
    Uninitialize-Environment
}

#Get-User
Write-Host "Testing Get-User..." -nonewline
Initialize-Environment
try{
    Test-GetUser
    Write-Host "success"
}
catch{
    Write-Host "fail"
    $success= $FALSE
}
finally{
    Uninitialize-Environment
}


#Test-IsLocalUser
Write-Host "Testing Test-IsLocalUser..." -nonewline
Initialize-Environment
try{
    Test-TestIsLocalUser
    Write-Host "success"
}
catch{
    Write-Host "fail"
    $success= $FALSE
}
finally{
    Uninitialize-Environment
}



##################

##################
#Group Account
##################

#Test-GroupExists
Write-Host "Testing Test-GroupExists..." -nonewline
Initialize-Environment
try{
    Test-TestGroupExists
    Write-Host "success"
}
catch{
    Write-Host "fail"
    $success= $FALSE
}
finally{
    Uninitialize-Environment
}


#Get-Group
Write-Host "Testing Get-Group..." -nonewline
Initialize-Environment
try{
    Test-GetGroupLocal
    Test-GetGroupDomain
    Write-Host "success"
}

finally{
    Uninitialize-Environment
}


#New-Group
Write-Host "Testing New-Group..." -nonewline
Initialize-Environment
try{
    Test-NewGroupLocal
    Test-NewGroupDomain
    Write-Host "success"
}
catch{
    Write-Host "fail"
    $success= $FALSE
}
finally{
    Uninitialize-Environment
}


#Remove-Group
Write-Host "Testing Remove-Group..." -nonewline
Initialize-Environment
try{
    Test-RemoveGroupLocal
    Test-RemoveGroupDomain
    Write-Host "success"
}
catch{
    Write-Host "fail"
    $success= $FALSE
}
finally{
    Uninitialize-Environment
}


#Get-GroupMembers
###################
Write-Host "Testing Get-GroupMembers..." -nonewline
Initialize-Environment
try{
    Test-GetGroupMembers
    Write-Host "success"
}
catch{
    Write-Host "fail"
    $success= $FALSE
}
finally{
    Uninitialize-Environment
}


#Add-GroupMember
Write-Host "Testing Add-GroupMember..." -nonewline
Initialize-Environment
try{
    Test-AddGroupMember
    Write-Host "success"
}
catch{
    Write-Host "fail"
    $success= $FALSE
}
finally{
    Uninitialize-Environment
}



#Remove-GroupMember
Write-Host "Testing Remove-GroupMember..." -nonewline
Initialize-Environment
try{
    Test-RemoveGroupMember
    Write-Host "success"
}
catch [System.Management.Automation.RuntimeException]{
    Write-Host "fail"
    $success= $FALSE
}
finally{
    Uninitialize-Environment
}

if($success){
    Write-Host "TestSuite: success"
}
else{
     Write-Host "TestSuite: fail"
}