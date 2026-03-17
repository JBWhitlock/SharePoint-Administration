<#
=====================================================================================
Script:    Invoke-NintexMigration.ps1
Author:    James B. Whitlock Sr Systems/SharePoint Architect NASA - Kennedy Space Center - NCAPS
Created:   2025-06-01
Version:   1.0
Purpose:   Master orchestration script to migrate Nintex workflow data across DBs
=====================================================================================
.SYNOPSIS
    Master Orchestrator for Nintex Workflow DB Migration
.DESCRIPTION
    Automates the key steps for migrating a site collection's workflows between Nintex databases.
    This script calls modular tools and guides the user through each step.
#>

# Step 1: Prompt for Site Collection URL and resolve Site ID
$siteUrl = Read-Host "Enter the Site Collection URL"
try {
    $site = Get-SPSite $siteUrl
    $siteId = $site.ID
    Write-Host "Resolved Site ID: $siteId" -ForegroundColor Green
} catch {
    Write-Host "Failed to resolve site collection. Exiting." -ForegroundColor Red
    exit
}

# Step 2: Query Nintex databases to find where workflows exist
Write-Host "Checking which Nintex databases contain workflows for this Site ID..."
& "./Query-NintexWorkflows.ps1" -SiteId $siteId

# Step 3: Disable Workflow Timer Job
Write-Host "Disabling the Workflow Timer Job in Central Admin..."

# Load SharePoint PowerShell Snap-in if not already loaded
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null) {
    Add-PSSnapin Microsoft.SharePoint.PowerShell
}

# Get the SharePoint farm
$farm = Get-SPFarm

# Find and disable the Workflow Timer Job
$workflowTimerJob = $farm.TimerService.JobDefinitions | Where-Object { $_.Name -eq "job-workflow" }
if ($workflowTimerJob -ne $null) {
    $workflowTimerJob.IsDisabled = $true
    $workflowTimerJob.Update()
    Write-Host "✅ Workflow Timer Job has been disabled successfully." -ForegroundColor Green
} else {
    Write-Host "⚠️ Workflow Timer Job not found." -ForegroundColor Yellow
}

# Step 4: Prompt to stop IIS Web App
$stopWeb = Read-Host "Stop associated Web Application on all WFE servers? (Y/N)"
if ($stopWeb -eq 'Y') {
    & "./Manage-IISWebApps_No_SSL.ps1"
}

# Step 5: Run NWAdmin MoveData
$move = Read-Host "Continue with NWAdmin MoveData to migrate workflows? (Y/N)"
if ($move -eq 'Y') {
    & "./Run-NWAdminMove.ps1" -SiteUrl $siteUrl -SiteId $siteId
}

# Step 6: Prompt to restart services
$restart = Read-Host "Restart IIS Web App and re-enable Workflow Timer Job now? (Y/N)"
if ($restart -eq 'Y') {
    & "./Restart-Services.ps1"
}

Write-Host "Nintex DB Migration script completed." -ForegroundColor Cyan
