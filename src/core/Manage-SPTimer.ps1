#requires -runasadministrator
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [ValidateSet('Stop','Start','Restart')][string]$Action,
    [int]$TimeoutSeconds=120
)

#Add SP snapin if needed
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

#Enumerate farm servers (skip DB/Invalid roles)
try{
    $servers=Get-SPServer | Where-Object { $_.Role -ne 'Invalid' -and $_.Role -ne 'Database' }
    if(-not $servers){ Write-Error 'No eligible farm servers found.'; exit 1 }
}catch{
    Write-Error "Failed to enumerate farm servers. $($_.Exception.Message)"
    exit 1
}

#Interactive choice if -Action not provided
if(-not $Action){
    Write-Host 'Select action for SPTimerV4 on all farm nodes:' -ForegroundColor Cyan
    Write-Host '  1) Stop'
    Write-Host '  2) Start'
    Write-Host '  3) Restart'
    $choice=Read-Host 'Enter 1-3'
    switch($choice){
        '1' { $Action='Stop' }
        '2' { $Action='Start' }
        '3' { $Action='Restart' }
        default { Write-Error 'Invalid selection.'; exit 1 }
    }
}

function Wait-SPTimerState{
    param(
        [Parameter(Mandatory=$true)][string]$Server,
        [Parameter(Mandatory=$true)][ValidateSet('RUNNING','STOPPED')][string]$Desired,
        [int]$TimeoutSeconds=120
    )
    $deadline=(Get-Date).AddSeconds($TimeoutSeconds)
    while((Get-Date) -lt $deadline){
        Start-Sleep -Seconds 3
        $line=(sc.exe \\$Server query SPTimerV4 2>$null) | Select-String 'STATE'
        if($line -and ($line.Line -match $Desired)){ return $true }
    }
    return $false
}

foreach($s in $servers){
    $target=$s.Address
    try{
        switch($Action){
            'Stop'{
                if($PSCmdlet.ShouldProcess($target,'Stop SPTimerV4')){
                    Write-Host "Stopping SPTimerV4 on ${target}..." -ForegroundColor Yellow
                    sc.exe \\$target stop SPTimerV4 | Out-Null
                    if(Wait-SPTimerState -Server $target -Desired 'STOPPED' -TimeoutSeconds $TimeoutSeconds){
                        Write-Host "SPTimerV4 stopped on ${target}" -ForegroundColor Green
                    }else{
                        Write-Warning "Timeout waiting for STOPPED on ${target}"
                    }
                }
            }
            'Start'{
                if($PSCmdlet.ShouldProcess($target,'Start SPTimerV4')){
                    Write-Host "Starting SPTimerV4 on ${target}..." -ForegroundColor Yellow
                    sc.exe \\$target start SPTimerV4 | Out-Null
                    if(Wait-SPTimerState -Server $target -Desired 'RUNNING' -TimeoutSeconds $TimeoutSeconds){
                        Write-Host "SPTimerV4 running on ${target}" -ForegroundColor Green
                    }else{
                        Write-Warning "Timeout waiting for RUNNING on ${target}"
                    }
                }
            }
            'Restart'{
                if($PSCmdlet.ShouldProcess($target,'Restart SPTimerV4')){
                    Write-Host "Restarting SPTimerV4 on ${target}..." -ForegroundColor Yellow
                    sc.exe \\$target stop SPTimerV4 | Out-Null
                    if(-not (Wait-SPTimerState -Server $target -Desired 'STOPPED' -TimeoutSeconds $TimeoutSeconds)){
                        Write-Warning "Timeout waiting for STOPPED on ${target}"
                    }
                    sc.exe \\$target start SPTimerV4 | Out-Null
                    if(Wait-SPTimerState -Server $target -Desired 'RUNNING' -TimeoutSeconds $TimeoutSeconds){
                        Write-Host "SPTimerV4 running on ${target}" -ForegroundColor Green
                    }else{
                        Write-Warning "Timeout waiting for RUNNING on ${target}"
                    }
                }
            }
        }
    }catch{
        Write-Warning "Operation failed on ${target}: $($_.Exception.Message)"
    }
}
