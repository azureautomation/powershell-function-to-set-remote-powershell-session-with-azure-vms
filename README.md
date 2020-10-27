Powershell function to set remote powershell session with Azure VMs
===================================================================

            

[This is the same code published here,](https://gallery.technet.microsoft.com/Powershell-script-to-set-fbb963b5) but formatted as a function. This facilitates using this code repeatedly in other scripts.


In Azure Microsoft has a large list of VM templates that can be used in the Gallery to provision VMs. These VMs come with few pre-configured features to facilitate secure powershell remoting into the VMs:


- WinRM is enabled and configured to listen on HTTPS port 5986


- A certificate is already created to enable authentication from remote on-premises computers that do not belong to the same AD domain as the target Azure VM.


 


 

 

 


        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
