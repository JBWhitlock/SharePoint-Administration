<#
=====================================================================================
Script:    Run-NWAdminMove.ps1
Author:    James B. Whitlock Sr Systems/SharePoint Architect NASA - Kennedy Space Center - NCAPS
Created:   2025-06-01
Version:   1.0
Purpose:   Executes NWAdmin.exe MoveData operation for Nintex DB Migration
=====================================================================================
#>

# Prompt for Site Collection URL
$SiteUrl = Read-Host "Site Collection URL"

# Resolve Site ID from URL
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
$Site = Get-SPSite $SiteUrl
$SiteId = $Site.ID
Write-Host "Resolved Site ID: $SiteId" -ForegroundColor Cyan

# Prompt for SQL Server and Database names
$sourceServer = Read-Host "Enter source SQL server"
$sourceDB = Read-Host "Enter source Nintex DB"
$targetServer = Read-Host "Enter target SQL server"
$targetDB = Read-Host "Enter target Nintex DB"

# Build connection strings
$sourceConn = "Data Source=$sourceServer;Initial Catalog=$sourceDB;Integrated Security=True;"
$targetConn = "Data Source=$targetServer;Initial Catalog=$targetDB;Integrated Security=True;"

Write-Host "`nSource DB: $sourceDB on $sourceServer" -ForegroundColor Yellow
Write-Host "Target DB: $targetDB on $targetServer`n" -ForegroundColor Yellow

# Run NWAdmin MoveData
$cmd = "NWAdmin.exe -o MoveData -Url `"$SiteUrl`" -SiteID $SiteId -SourceDatabase `"$sourceConn`" -TargetDatabase `"$targetConn`""
Write-Host "Executing command:" -ForegroundColor Green
Write-Host $cmd -ForegroundColor Cyan
Invoke-Expression $cmd
