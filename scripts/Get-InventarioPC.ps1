﻿<#
.SYNOPSIS
Coleta inventário de hardware e sistema.
.PARAMETER Saida
Caminho opcional para exportar o inventário em CSV.
.EXAMPLE
.\scripts\Get-InventarioPC.ps1 -Saida .\inventario.csv
#>
[CmdletBinding()]
param([string]$Saida)
try {
    $computador = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
    $bios = Get-CimInstance Win32_BIOS -ErrorAction Stop
    $processadores = @(Get-CimInstance Win32_Processor -ErrorAction Stop)
    $sistema = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $discos = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType = 3' -ErrorAction Stop)
    $ips = @(Get-CimInstance Win32_NetworkAdapterConfiguration -Filter 'IPEnabled = TRUE' -ErrorAction Stop | ForEach-Object { $_.IPAddress })
    $inventario = [pscustomobject]@{
        Computador = $computador.Name; Fabricante = $computador.Manufacturer; Modelo = $computador.Model
        MemoriaBytes = $computador.TotalPhysicalMemory; Serial = $bios.SerialNumber
        Processador = ($processadores.Name -join '; '); Sistema = $sistema.Caption; Versao = $sistema.Version
        UltimoBoot = $sistema.LastBootUpTime; IP = ($ips -join '; ')
        Discos = (($discos | ForEach-Object { '{0} ({1} bytes livres de {2})' -f $_.DeviceID, $_.FreeSpace, $_.Size }) -join '; ')
    }
    if ($Saida) { $inventario | Export-Csv -Path $Saida -NoTypeInformation -Encoding UTF8 -ErrorAction Stop }
    $inventario
} catch { Write-Error "Falha ao coletar ou exportar inventário: $_" }
