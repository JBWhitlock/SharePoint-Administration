<#
.SYNOPSIS
    Tool to remotely Start/Stop/Restart IIS Web Applications (Sites)
.DESCRIPTION
    Uses PowerShell Remoting with SSL to manage IIS websites without affecting App Pools.
#>

# Prompt for remote server
$pc = Read-Host "Enter the remote server's computer name or IP address (FQDN if needed)"

# Get the list of IIS sites from remote
$scriptBlock = {
    Import-Module WebAdministration
    Get-ChildItem IIS:\Sites | Select-Object Name, State
}

$sites = Invoke-Command -ComputerName $pc -UseSSL -ScriptBlock $scriptBlock

# Display sites
Write-Host "`nAvailable IIS Web Applications:"
$sites | ForEach-Object { Write-Host "$($_.Name) - $($_.State)" }

# Prompt for selection
$selectedSite = Read-Host "`nEnter the name of the Web Application you want to manage"

if ($sites.Name -contains $selectedSite) {
    $action = Read-Host "Enter the action you want to perform (Start/Stop/Restart)"

    # Action blocks
    $startBlock = {
        param ($siteName)
        Import-Module WebAdministration
        Start-Website -Name $siteName
    }

    $stopBlock = {
        param ($siteName)
        Import-Module WebAdministration
        Stop-Website -Name $siteName
    }

    $restartBlock = {
        param ($siteName)
        Import-Module WebAdministration
        Stop-Website -Name $siteName
        Start-Sleep -Seconds 2
        Start-Website -Name $siteName
    }

    # Execute
    switch ($action.ToLower()) {
        "start" {
            Invoke-Command -ComputerName $pc -UseSSL -ScriptBlock $startBlock -ArgumentList $selectedSite
            Write-Host "✅ Web App '$selectedSite' started."
        }
        "stop" {
            Invoke-Command -ComputerName $pc -UseSSL -ScriptBlock $stopBlock -ArgumentList $selectedSite
            Write-Host "✅ Web App '$selectedSite' stopped."
        }
        "restart" {
            Invoke-Command -ComputerName $pc -UseSSL -ScriptBlock $restartBlock -ArgumentList $selectedSite
            Write-Host "✅ Web App '$selectedSite' restarted."
        }
        default {
            Write-Host "❌ Invalid action. Use Start, Stop, or Restart."
        }
    }
} else {
    Write-Host "❌ The Web App '$selectedSite' does not exist on $pc."
}
