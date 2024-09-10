Creator: James B. Whitlock
Title: KSC Sr SP Admin
Email: james.b.whitlock@nasa.gov
Version: 1.4
Date: 9/3/2024

Description
Configure-SPFarm.ps1 is a PowerShell script designed to configure an initial SharePoint Subscription Edition (SPSE) farm. The script prompts for various inputs, such as:

Farm Administrator account
SQL Server name
Configuration database details
Server role
Web application details
Optional: Search Index location (for SingleServerFarm or Search roles)
The script automates the process of:

Creating the SharePoint configuration database
Provisioning Central Administration
Setting up Managed Metadata service applications
Configuring usage and health data collection
Creating a new web application and site collection
The script also includes logic for specifying a Search Index location if the server role is either SingleServerFarm or Search.

Requirements
PowerShell: This script should be run in PowerShell with Administrator privileges.
SharePoint Subscription Edition: Ensure that SharePoint Subscription Edition binaries are installed on the server.
SQL Server: Ensure that SQL Server 2017 (14.0.3430.2 or higher) or SQL Server 2019 (15.0.4323.1 or higher) is installed and configured.
Permissions: The account running this script must have appropriate privileges in SQL Server and SharePoint.
How to Use
1. Open PowerShell as Administrator
To run the script, you must launch PowerShell with administrative privileges. Right-click the PowerShell icon and select "Run as Administrator."

2. Navigate to the Script Location
Use cd to navigate to the directory where the Configure-SPFarm.ps1 script is located.

powershell
Copy code
cd D:\SPSE
3. Run the Script
Execute the script using the following command:

powershell
Copy code
.\Configure-SPFarm.ps1
4. Provide Input When Prompted
The script will prompt you to input various values:

Farm Administrator Account: Specify the account in the format DOMAIN\AccountName.
Farm Passphrase: Enter the passphrase securely (this will not be displayed).
SQL Server Name: Specify the SQL Server instance where SharePoint databases will be created.
Configuration Database Name: Default is SharePoint_Config.
Central Admin Content Database Name: Default is SharePoint_AdminContent.
Port Number for Central Administration: Default is 443 (or change it based on your requirements).
Farm Service Account: Specify the account in the format DOMAIN\AccountName.
Server Role: Choose from Application, WebFrontEnd, SingleServerFarm, or Search. If SingleServerFarm or Search is selected, you’ll be prompted to specify the Search Index location.
Default Search Index location is D:\SharePoint\Search.
5. Optional: Search Index Directory
If the server role selected is SingleServerFarm or Search, the script will prompt you to specify the location of the Search Index. The default location is D:\SharePoint\Search. If the directory doesn’t exist, it will be created automatically.

6. Automatic Configuration
Once the inputs are provided, the script will:

Create the configuration database and Central Administration content database
Start the SharePoint farm
Provision Central Administration
Set the farm service account
Set up the Managed Metadata service
Create a new web application and site collection
Sample Usage
Example of how the script will prompt you:

powershell
Copy code
Please enter the Farm Administrator account (e.g., DOMAIN\SPFarmAdmin): DOMAIN\SPFarmAdmin
Please enter the farm passphrase: ********
Please enter the SQL Server name (e.g., YourSQLServer): SPSE_SQLServer
Please enter the name for the SharePoint Configuration Database (default: SharePoint_Config): [Press Enter for default]
Please enter the name for the Central Admin Content Database (default: SharePoint_AdminContent): [Press Enter for default]
Please enter the port number for Central Administration (default: 443): [Press Enter for default]
Please enter the Farm Service Account (e.g., DOMAIN\SPFarmServiceAccount): DOMAIN\SPFarmServiceAccount
Select the server role:
Application
WebFrontEnd
SingleServerFarm
Search
Enter the server role (Application, WebFrontEnd, SingleServerFarm, Search): SingleServerFarm
Please specify the location for the Search Index (default: D:\SharePoint\Search): [Press Enter for default]
Known Issues
SQL Server Version: Ensure that the SQL Server version is supported (SQL Server 2017 or 2019). If you see the error SQL server has an unsupported version, refer to the SQL Server requirements for SharePoint Subscription Edition.
AppFabric Install Prompt: If AppFabric prompts for installation issues, you may need to cancel the pop-ups and continue the process manually.
Troubleshooting
SQL Server Compatibility Error:

If you encounter an error regarding the SQL Server version, upgrade to SQL Server 2017 (14.0.3430.2 or higher) or SQL Server 2019 (15.0.4323.1 or higher).
Permission Issues:

Ensure the account running the script has full permissions on the SQL Server instance and is a member of the local Administrators group on the SharePoint server.
Version History
Version 1.0 - Initial script creation for farm configuration.
Version 1.2 - Added user prompt for server role selection.
Version 1.3 - Added Search Index directory creation logic for SingleServerFarm and Search roles.
Version 1.4 - Enhanced error handling for missing search index path.
This README provides clear instructions on how to use the Configure-SPFarm.ps1 script, along with details on the expected input, script functionality, troubleshooting, and known issues. If you have any additional questions or face issues while running the script, feel free to reach out to James B. Whitlock at james.b.whitlock@nasa.gov.
