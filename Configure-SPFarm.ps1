# ------------------------------------------------------------------------------
# Script Name: Configure-SPFarm.ps1
# Creator: James B. Whitlock
# Title: KSC Sr SP Admin
# Email: james.b.whitlock@nasa.gov
# Version: 1.4
# Date: 9/3/2024
#
# Description:
#   This script configures the initial SharePoint Subscription Edition (SPSE)
#   farm using PowerShell. It prompts for various input parameters such as
#   farm account, SQL server, database names, server roles, and web application details.
#   It includes logic to set the Search Index location if the user selects SingleServerFarm or Search role.
# ------------------------------------------------------------------------------

# Prompt for user input
$FarmAccount = Read-Host "Please enter the Farm Administrator account (e.g., DOMAIN\SPFarmAdmin)"
$Passphrase = Read-Host "Please enter the farm passphrase" -AsSecureString
$DBServer = Read-Host "Please enter the SQL Server name (e.g., YourSQLServer)"
$ConfigDBName = Read-Host "Please enter the name for the SharePoint Configuration Database (default: SharePoint_Config)" -Default "SharePoint_Config"
$AdminContentDBName = Read-Host "Please enter the name for the Central Admin Content Database (default: SharePoint_AdminContent)" -Default "SharePoint_AdminContent"
$CA_Port = Read-Host "Please enter the port number for Central Administration (default: 443)" -Default 443
$FarmServiceAccount = Read-Host "Please enter the Farm Service Account (e.g., DOMAIN\SPFarmServiceAccount)"

# Select the server role from predefined options
$ServerRoleOptions = @("Application", "WebFrontEnd", "SingleServerFarm", "Search")
Write-Host "Select the server role:"
$ServerRoleOptions | ForEach-Object { Write-Host "$($_)" }

$ServerRole = Read-Host "Enter the server role (Application, WebFrontEnd, SingleServerFarm, Search)"
while ($ServerRole -notin $ServerRoleOptions) {
    Write-Host "Invalid selection. Please enter a valid server role (Application, WebFrontEnd, SingleServerFarm, Search)." -ForegroundColor Red
    $ServerRole = Read-Host "Enter the server role (Application, WebFrontEnd, SingleServerFarm, Search)"
}

# Logic for Search Index Location if SingleServerFarm or Search role is selected
if ($ServerRole -eq "SingleServerFarm" -or $ServerRole -eq "Search") {
    $SearchIndexPath = Read-Host "Please specify the location for the Search Index (default: D:\SharePoint\Search)"
    
    # If user input is empty, set default path
    if ([string]::IsNullOrEmpty($SearchIndexPath)) {
        $SearchIndexPath = "D:\SharePoint\Search"
    }

    # Check if the directory exists, if not, create it
    if (-not (Test-Path -Path $SearchIndexPath)) {
        Write-Host "Creating directory for Search Index at $SearchIndexPath..." -ForegroundColor Cyan
        New-Item -Path $SearchIndexPath -ItemType Directory
    } else {
        Write-Host "Search Index directory already exists at $SearchIndexPath." -ForegroundColor Green
    }
    
    # Set the Search Index location (this can be part of later search service configuration)
    # Example for setting the Search Index Location
    # New-SPEnterpriseSearchIndexComponent -SearchTopology $SearchTopology -SearchServiceInstance $SearchServiceInstance -RootDirectory $SearchIndexPath
} else {
    Write-Host "Search Index location configuration is not required for $ServerRole role." -ForegroundColor Yellow
}

# Create the Configuration Database
Write-Host "Creating the Configuration Database..." -ForegroundColor Cyan
New-SPConfigurationDatabase -DatabaseName $ConfigDBName `
    -DatabaseServer $DBServer `
    -AdministrationContentDatabaseName $AdminContentDBName `
    -FarmCredentials (Get-Credential $FarmAccount) `
    -Passphrase $Passphrase `
    -LocalServerRole $ServerRole

# Start the SharePoint Farm
Write-Host "Starting the SharePoint farm..." -ForegroundColor Cyan
Initialize-SPFarm -Passphrase $Passphrase -LocalServerRole $ServerRole -ServerType Complete

# Provision Central Administration
Write-Host "Provisioning Central Administration..." -ForegroundColor Cyan
New-SPCentralAdministration -Port $CA_Port -WindowsAuthProvider "NTLM"

# Set the Farm Service Account
$FarmServiceCredentials = Get-Credential $FarmServiceAccount
Write-Host "Setting the Farm Service Account..." -ForegroundColor Cyan
Set-SPManagedAccount -Credential $FarmServiceCredentials

# Create Managed Metadata Service Application
$MMSAppPoolName = Read-Host "Please enter the name for the Managed Metadata Service Application Pool (default: SharePoint Services App Pool)" -Default "SharePoint Services App Pool"
$MMSDB = Read-Host "Please enter the name for the Managed Metadata Service Database (default: ManagedMetadataDB)" -Default "ManagedMetadataDB"

Write-Host "Creating Managed Metadata Service Application..." -ForegroundColor Cyan
$MMSAppPool = New-SPServiceApplicationPool -Name $MMSAppPoolName -Account $FarmServiceCredentials
$MMSApp = New-SPMetadataServiceApplication -Name "Managed Metadata Service" -ApplicationPool $MMSAppPool -DatabaseName $MMSDB
New-SPMetadataServiceApplicationProxy -Name "Managed Metadata Service Proxy" -ServiceApplication $MMSApp

# Configure Usage and Health Data Collection
Write-Host "Configuring Usage and Health Data Collection..." -ForegroundColor Cyan
$UsageApp = New-SPUsageApplication -Name "Usage and Health Data Collection"

# Create a New Web Application and Site Collection
$WebAppName = Read-Host "Please enter the name for the new Web Application (default: SharePoint Site)" -Default "SharePoint Site"
$WebAppPort = Read-Host "Please enter the port for the new Web Application (default: 80)" -Default 80
$WebAppURL = Read-Host "Please enter the URL for the Web Application (e.g., http://sp.domain.com)"
$WebAppAppPoolName = Read-Host "Please enter the name for the Web Application App Pool (default: SharePoint WebApp Pool)" -Default "SharePoint WebApp Pool"
$SiteOwner = Read-Host "Please enter the owner alias for the new Site Collection (e.g., DOMAIN\SPAdmin)"
$SiteTemplate = Read-Host "Please enter the template for the Site Collection (default: STS#0 for Team Site)" -Default "STS#0"

Write-Host "Creating a new Web Application and Site Collection..." -ForegroundColor Cyan
$WebApp = New-SPWebApplication -Name $WebAppName -Port $WebAppPort `
    -HostHeader $WebAppURL `
    -URL $WebAppURL `
    -ApplicationPool $WebAppAppPoolName `
    -ApplicationPoolAccount $FarmServiceCredentials

New-SPSite -URL $WebAppURL -OwnerAlias $SiteOwner -Template $SiteTemplate

# Start Required SharePoint Services
Write-Host "Starting required SharePoint services..." -ForegroundColor Cyan
Start-Service -Name "SPTimerV4"
Start-Service -Name "SPAdminV4"
Start-SPServiceInstance $(Get-SPServiceInstance | Where-Object { $_.TypeName -eq "Microsoft SharePoint Foundation Web Application" })

# Verify the Farm Configuration
Write-Host "Verifying the SharePoint farm configuration..." -ForegroundColor Cyan
Get-SPFarm | Select-Object -Property Id,Servers,Services
Get-SPCentralAdministration
