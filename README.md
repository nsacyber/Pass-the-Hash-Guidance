# Pass the Hash Guidance

This project hosts scripts for aiding administrators in implementing Pass the Hash mitigations as outlined in the [Reducing the Effectiveness of Pass the Hash](https://www.iad.gov/iad/library/ia-guidance/security-configuration/applications/reducing-the-effectiveness-of-pass-the-hash.cfm) paper.


The [PtHTools](./PtHTools/) module contains the main commands for helping with implementing PtH mitigations:

* Find-PotentialPtHEvents 
* Invoke-DenyNetworkAccess 
* Edit-AllLocalAccountPasswords 
* Get-LocalAccountSummaryOnDomain 
* Invoke-SmartcardHashRefresh 
 
See the [PtHTools readme file](./PtHTools/README.md) for more information on how to use them.

## Microsoft guidance
* https://aka.ms/pth - Microsoft's Pass-the-Hash general resource page.
* [Mitigating Pass-the-Hash and Other Credential Theft v1](http://download.microsoft.com/download/7/7/A/77ABC5BD-8320-41AF-863C-6ECFB10CB4B9/Mitigating%20Pass-the-Hash%20(PtH)%20Attacks%20and%20Other%20Credential%20Theft%20Techniques_English.pdf)
* [Mitigating Pass-the-Hash and Other Credential Theft v2](http://download.microsoft.com/download/7/7/A/77ABC5BD-8320-41AF-863C-6ECFB10CB4B9/Mitigating-Pass-the-Hash-Attacks-and-Other-Credential-Theft-Version-2.pdf)
* [How Pass-the-Hash works](http://download.microsoft.com/download/C/3/B/C3BD2D13-FC9B-4FAB-A1E7-43FC5DE5CFB2/PassTheHashAttack-DataSheet.pdf)
* https://aka.ms/laps - Local Administrator Password Solution (LAPS) is a Microsoft supported tool that ensures local administrator accounts do not all have the same password. It is an alternative to the Edit-AllLocalAccountPasswords command.
* [krbtgt refresh script](http://blogs.microsoft.com/microsoftsecure/2015/02/11/krbtgt-account-password-reset-scripts-now-available-for-customers/) - Resets the krbtgt account password twice to invalidate Kerberos tickets created by attackers (e.g. Golden Ticket).

## License
This Work was prepared by a United States Government employee and, therefore, is excluded from copyright by Section 105 of the Copyright Act of 1976.

Copyright and Related Rights in the Work worldwide are waived through the [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) [Universal license](https://creativecommons.org/publicdomain/zero/1.0/legalcode).

## Disclaimer of Warranty
This Work is provided "as is." Any express or implied warranties, including but not limited to, the implied warranties of merchantability and fitness for a particular purpose are disclaimed. In no event shall the United States Government be liable for any direct, indirect, incidental, special, exemplary or consequential damages (including, but not limited to, procurement of substitute goods or services, loss of use, data or profits, or business interruption) however caused and on any theory of liability, whether in contract, strict liability, or tort (including negligence or otherwise) arising in any way out of the use of this Guidance, even if advised of the possibility of such damage.

The User of this Work agrees to hold harmless and indemnify the United States Government, its agents and employees from every claim or liability (whether in tort or in contract), including attorneys' fees, court costs, and expenses, arising in direct consequence of Recipient's use of the item, including, but not limited to, claims or liabilities made for injury to or death of personnel of User or third parties, damage to or destruction of property of User or third parties, and infringement or other violations of intellectual property or technical data rights.

Nothing in this Work is intended to constitute an endorsement, explicit or implied, by the United States Government of any particular manufacturer's product or service.

## Disclaimer of Endorsement
Reference herein to any specific commercial product, process, or service by trade name, trademark, manufacturer, or otherwise, in this Work does not constitute an endorsement, recommendation, or favoring by the United States Government and shall not be used for advertising or product endorsement purposes.