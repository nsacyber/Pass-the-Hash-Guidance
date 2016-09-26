Import-Module Assert -ErrorAction Stop -Force

$i = 2
$sb = {$i -eq 2}        
Test-Assert $sb

$i = 1.1
$sb = {$i -ne 2}

Test-Assert $sb


$s = ""
$sb = {$s -eq ""}

Test-Assert $sb

$s = "12345"
$sb = {$s -match "5"}

Test-Assert $sb


$b = $True
$sb = {$b -eq $TRUE}

Test-Assert $sb

$b = $false
$sb = {$b -ne $TRUE}

Test-Assert $sb

$sb = {$b -ne 2}
Test-Assert $sb

