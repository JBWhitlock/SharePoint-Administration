#requires -runasadministrator
<#
=====================================================================================
Script:    Manage-WorkflowService.ps1
Revised:   2025-08-18
Version:   1.1 (auto-resolve)
Purpose:   Enable, Disable, RunNow, or view Status for the workflow timer job.
           Automatically resolves the job GUID using Name = 'job-workflow'.
=====================================================================================
.SYNOPSIS
    Manage the SharePoint workflow timer job without typing the GUID.

.DESCRIPTION
    If -JobId is not provided, the script finds the timer job via:
        Get-SPTimerJob | Where-Object { $_.Name -Like 'job-workflow' } | Select-Object -First 1
    and uses that Id for all actions. No guessing, no prompts.

.PARAMETER Action
    Enable | Disable | RunNow | Status. If omitted, prompts interactively.

.PARAMETER JobId
    Optional override. If supplied, script uses it instead of auto-resolving.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [ValidateSet('Enable','Disable','RunNow','Status')]
    [string]$Action,
    [Guid]$JobId
)

#Load SP snapin quietly
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

#Prompt for Action if missing
if(-not $Action){
    Write-Host 'Manage Workflow Timer Job:' -ForegroundColor Cyan
    Write-Host '  1) Enable'
    Write-Host '  2) Disable'
    Write-Host '  3) RunNow'
    Write-Host '  4) Status'
    switch(Read-Host 'Enter 1-4'){
        '1'{$Action='Enable'}
        '2'{$Action='Disable'}
        '3'{$Action='RunNow'}
        '4'{$Action='Status'}
        default{ Write-Error 'Invalid selection.'; exit 1 }
    }
}

#Auto-resolve JobId from the canonical name if not provided
if(-not $PSBoundParameters.ContainsKey('JobId')){
    $resolved = Get-SPTimerJob | Where-Object { $_.Name -Like 'job-workflow' } | Select-Object -First 1
    if(-not $resolved){
        Write-Error "Timer job with Name 'job-workflow' not found. Run:`n  Get-SPTimerJob | ? { `$_.Name -like 'job-workflow' -or `$_.DisplayName -like 'Workflow' }"
        exit 1
    }
    $JobId = $resolved.Id
    Write-Host "Resolved 'job-workflow' Id: $JobId" -ForegroundColor DarkGray
}

function Get-WorkflowJobById{
    param([Guid]$Id)
    Get-SPTimerJob | Where-Object { $_.Id -eq $Id } | Select-Object -First 1
}

$job = Get-WorkflowJobById -Id $JobId
if(-not $job){
    Write-Error "No timer job found with Id $JobId"
    exit 1
}

switch($Action){
    'Enable'{
        if($job.IsDisabled){
            if($PSCmdlet.ShouldProcess($job.Name,'Enable')){
                $job.IsDisabled=$false
                $job.Update()
                Write-Host "Enabled '$($job.Name)' ($($job.Id))." -ForegroundColor Green
            }
        }else{
            Write-Host "'$($job.Name)' is already enabled."
        }
    }
    'Disable'{
        if(-not $job.IsDisabled){
            if($PSCmdlet.ShouldProcess($job.Name,'Disable')){
                $job.IsDisabled=$true
                $job.Update()
                Write-Host "Disabled '$($job.Name)' ($($job.Id))." -ForegroundColor Yellow
            }
        }else{
            Write-Host "'$($job.Name)' is already disabled."
        }
    }
    'RunNow'{
        if($PSCmdlet.ShouldProcess($job.Name,'RunNow')){
            try{
                Start-SPTimerJob -Identity (Get-SPTimerJob | Where-Object { $_.Id -eq $JobId }) -ErrorAction Stop
            }catch{
                #Fallback that works when Start-SPTimerJob throws a mood
                ($job=Get-WorkflowJobById -Id $JobId).RunNow()
            }
            Write-Host "Triggered '$($job.Name)' ($($job.Id)) to run now."
        }
    }
    'Status'{
        Get-SPTimerJob | Where-Object { $_.Id -eq $JobId } |
          Select-Object Name, DisplayName, Id, Schedule, IsDisabled |
          Format-Table -AutoSize
    }
}
