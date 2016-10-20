# Pass the Hash Guidance

This project hosts scripts for aiding administrators in implementing Pass the Hash mitigations as outlined in the [Reducing the Effectiveness of Pass the Hash](https://www.iad.gov/iad/library/ia-guidance/security-configuration/applications/reducing-the-effectiveness-of-pass-the-hash.cfm) paper.


The [PtHTools](./PtHTools/) module contains the main commands for helping with implementing PtH mitigations:

* Find-PotentialPtHEvents 
* Invoke-DenyNetworkAccess 
* Edit-AllLocalAccountPasswords 
* Get-LocalAccountSummaryOnDomain 
* Invoke-SmartcardHashRefresh 
* Find-OldSmartcardHash

See the [PtHTools readme file](./PtHTools/README.md) for more information on how to use them.

## Microsoft guidance
* https://aka.ms/pth - Microsoft's Pass-the-Hash general resource page.
* [Mitigating Pass-the-Hash and Other Credential Theft v1](http://download.microsoft.com/download/7/7/A/77ABC5BD-8320-41AF-863C-6ECFB10CB4B9/Mitigating%20Pass-the-Hash%20(PtH)%20Attacks%20and%20Other%20Credential%20Theft%20Techniques_English.pdf)
* [Mitigating Pass-the-Hash and Other Credential Theft v2](http://download.microsoft.com/download/7/7/A/77ABC5BD-8320-41AF-863C-6ECFB10CB4B9/Mitigating-Pass-the-Hash-Attacks-and-Other-Credential-Theft-Version-2.pdf)
* [How Pass-the-Hash works](http://download.microsoft.com/download/C/3/B/C3BD2D13-FC9B-4FAB-A1E7-43FC5DE5CFB2/PassTheHashAttack-DataSheet.pdf)
* [Local Administrator Password Solution](https://aka.ms/laps) - LAPS is a Microsoft supported tool that ensures local administrator accounts do not all have the same password. It is an alternative to the Edit-AllLocalAccountPasswords command found in PtHTools.
* [krbtgt refresh](http://blogs.microsoft.com/microsoftsecure/2015/02/11/krbtgt-account-password-reset-scripts-now-available-for-customers/) [script](http://blogs.microsoft.com/microsoftsecure/2015/02/11/krbtgt-account-password-reset-scripts-now-available-for-customers/) - Resets the krbtgt account password twice to invalidate Kerberos tickets created by attackers (e.g. Golden Ticket).
* [Securing Privileged Access](https://technet.microsoft.com/en-us/windows-server-docs/security/securing-privileged-access/securing-privileged-access)
* [Privileged Access Workstations](http://aka.ms/cyberpaw)
* [Enhanced Security Administrative Environment](http://aka.ms/ESAE)

## License
See [LICENSE](./LICENSE.md).

## Disclaimer
See [DISCLAIMER](./DISCLAIMER.md).