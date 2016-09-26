Import-Module Assert -force
Import-Module Windows\Adsi -force


#test user that does not exist
$user = Get-ADSIUser "joe"
Test-Assert {$user -eq $NULL}


#test user that does exist
$user = Get-ADSIUser "Administrator"
Test-Assert {$user -ne $NULL}


#test group that does not exist
$group = Get-ADSIGroup "asdfasdfasdf"
Test-Assert {$group -eq $NULL}

#test group taht does exist
$group = Get-ADSIGroup "Domain Admins"
Test-Assert {$group -ne $NULL}

#test computer that does not exist
$computer = Get-ADSIComputer "asdfqwer"
Test-Assert {$computer -eq $NULL}


#test computer that does exist
$computer = Get-ADSIComputer "c1"
Test-Assert {$computer -ne $NULL}

#XXX Remote ADSI,comptuer queries do not work
#test computer that does exist
$computer = Get-ADSIComputer "c2"
Test-Assert {$computer -ne $NULL}

$computer = Get-ADSIComputer "c1337"
Test-Assert {$computer -eq $NULL}
