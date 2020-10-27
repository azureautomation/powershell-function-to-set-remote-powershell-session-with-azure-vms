function AzureVM-RemotePS {
<# 
 .Synopsis
  Function to establish Powershell remoting to Azure VM using certificate authentication

 .Description
  Function to establish Powershell remoting to Azure VM using certificate authentication

 .Parameter SubscriptionName
  Name of the Azure subscription where the VM is configured

 .Parameter VMName
  (NetBIOS) Name of the Azure VM to run remote PS commands on

 .Parameter AdminName
  The VM local admin name

 .Parameter Workfolder
  Local path to save encrypted VM admin pwd files

 .Example
  AzureVM-RemotePS -SubscriptionName 'My subscription' -VMName 'MyVM1' -AdminName 'MyAdmin' -WorkFolder 'c:\temp'
  Once the session is established, use it as in:
  $MySession = Get-PSSession | where { $_.ComputerName -match 'MyVM1' }
  Invoke-command -Session $MySession -ScriptBlock { Get-Process } 
  This command runs Get-Process on the remote Azure VM

 .Link
  https://superwidgets.wordpress.com/2016/02/15/managing-azure-vms-using-powershell-from-your-local-desktop/

 .Notes
  Function by Sam Boutros
  v1.0 - 15 February, 2016

#>

    [CmdletBinding(ConfirmImpact='Low')] 
    Param(
        [Parameter(Mandatory=$true,
                   Position=0)]
            [String]$SubscriptionName,         
        [Parameter(Mandatory=$true,
                   Position=0)]
            [String]$VMName,         
        [Parameter(Mandatory=$true,
                   Position=0)]
            [String]$AdminName,         
        [Parameter(Mandatory=$true,
                   Position=0)]
            [String]$WorkFolder 

    )

    #region Initial VM connectivity

    if (!(Test-Path -Path $WorkFolder)) {
        try {
            New-Item -Path $WorkFolder -ItemType directory -Force -Confirm:$false
        } catch {
            throw "Unable to create workfolder $WorkFolder"
        }
    } 
    $PwdFile = "$WorkFolder\$VMName-$AdminName.txt" # Local path tp save encrypted VM admin pwd

    try { 
        Select-AzureSubscription -SubscriptionName $SubscriptionName -ErrorAction Stop 
    } catch { 
        throw "unable to select Azure subscription '$SubscriptionName', check correct spelling.. " 
    }
    try { 
        $ServiceName = (Get-AzureVM -ErrorAction Stop | where { $_.Name -eq $VMName }).ServiceName 
    } catch { 
        throw "unable to get Azure VM '$VMName', check correct spelling, or run Add-AzureAccount to enter Azure credentials.. " 
    }
    $objVM  = Get-AzureVM -Name $VMName -ServiceName $ServiceName
    $VMFQDN = (Get-AzureWinRMUri -ServiceName $ServiceName).Host
    $Port   = (Get-AzureWinRMUri -ServiceName $ServiceName).Port
    
    # Get certificate for Powershell remoting to the Azure VM if not installed already
    if ((Get-ChildItem -Path Cert:\LocalMachine\Root).Subject -notcontains "CN=$VMFQDN") {
        Write-Verbose "Adding certificate 'CN=$VMFQDN' to 'LocalMachine\Root' certificate store.." 
        $Thumbprint = (Get-AzureVM -ServiceName $ServiceName -Name $VMName | 
            select -ExpandProperty VM).DefaultWinRMCertificateThumbprint
        $Temp = [IO.Path]::GetTempFileName()
        (Get-AzureCertificate -ServiceName $ServiceName -Thumbprint $Thumbprint -ThumbprintAlgorithm sha1).Data | Out-File $Temp
        $Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $Temp
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store "Root","LocalMachine"
        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        $store.Add($Cert)
        $store.Close()
        Remove-Item $Temp -Force -Confirm:$false
    }

    #endregion


    #region Open PS remote session

    # Attempt to open Powershell session to Azure VM
    Write-Verbose "Opening PS session with computer '$VMName'.." 
    if (-not (Test-Path -Path $PwdFile)) { 
            Write-Verbose "Pwd file '$PwdFile' not found, prompting to pwd.."
            Read-Host "Enter the pwd for '$AdminName' on '$VMFQDN'" -AsSecureString | 
                ConvertFrom-SecureString | Out-File $PwdFile 
        }
    $Pwd = Get-Content $PwdFile | ConvertTo-SecureString 
    $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AdminName, $Pwd

    try { 
        New-PSSession -ComputerName $VMFQDN -Port $Port -UseSSL -Credential $Cred -Name "$VMName-Session" -ErrorAction Stop 
    } catch {
        throw "Unable to establish PS remote session with '$VMName'.."
    }

    #endregion

}
