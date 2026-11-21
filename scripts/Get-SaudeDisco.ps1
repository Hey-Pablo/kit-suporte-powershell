﻿<#
.SYNOPSIS
Exibe espaço livre dos volumes e saúde dos discos físicos.
.PARAMETER Critico
Percentual máximo de espaço livre classificado como crítico.
.PARAMETER Alerta
Percentual máximo de espaço livre classificado como alerta.
.EXAMPLE
.\scripts\Get-SaudeDisco.ps1 -Critico 10 -Alerta 20
#>
[CmdletBinding()]
param([ValidateRange(0,100)][double]$Critico = 10, [ValidateRange(0,100)][double]$Alerta = 20)
Import-Module (Join-Path $PSScriptRoot '../modulo/KitSuporte.psd1') -Force
if ($Critico -gt $Alerta) { throw 'O limite crítico não pode superar o limite de alerta.' }
try {
    Get-CimInstance Win32_LogicalDisk -Filter 'DriveType = 3' -ErrorAction Stop | ForEach-Object {
        if ($_.Size -gt 0 -and $null -ne $_.FreeSpace) {
            $percentual = Get-PercentualLivre -Livre $_.FreeSpace -Total $_.Size
            [pscustomobject]@{ Tipo = 'Volume'; Nome = $_.DeviceID; Total = ConvertTo-TamanhoLegivel $_.Size; Livre = ConvertTo-TamanhoLegivel $_.FreeSpace; PercentualLivre = $percentual; Status = Get-ClassificacaoDisco $percentual -Critico $Critico -Alerta $Alerta }
        } else { [pscustomobject]@{ Tipo = 'Volume'; Nome = $_.DeviceID; Total = ''; Livre = ''; PercentualLivre = $null; Status = 'INDISPONIVEL' } }
    }
} catch { Write-Error "Falha ao consultar volumes: $_" }
try {
    Get-PhysicalDisk -ErrorAction Stop | ForEach-Object {
        [pscustomobject]@{ Tipo = 'Físico'; Nome = $_.FriendlyName; Total = ConvertTo-TamanhoLegivel $_.Size; Livre = ''; PercentualLivre = $null; Status = [string]$_.HealthStatus }
    }
} catch { Write-Error "Falha ao consultar discos físicos: $_" }
