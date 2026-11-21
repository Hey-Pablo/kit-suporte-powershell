<#
.SYNOPSIS
Testa gateway, DNS, internet e portas TCP.
.PARAMETER DestinoInternet
Nome usado nos testes de DNS e conectividade.
.PARAMETER Portas
Portas TCP a verificar no destino de internet.
.EXAMPLE
.\scripts\Test-RedeBasico.ps1 -DestinoInternet example.com -Portas 80,443
#>
[CmdletBinding()]
param([string]$DestinoInternet = 'example.com', [ValidateRange(1,65535)][int[]]$Portas = @(80,443))
Import-Module (Join-Path $PSScriptRoot '../modulo/KitSuporte.psd1') -Force
function Invoke-TesteRede {
    param([string]$Nome, [scriptblock]$Acao)
    $relogio = [System.Diagnostics.Stopwatch]::StartNew()
    $sucesso = $false; $detalhe = ''
    try { $sucesso = [bool](& $Acao); if (-not $sucesso) { $detalhe = 'Sem resposta.' } }
    catch { $detalhe = $_.Exception.Message }
    $relogio.Stop()
    Format-ResultadoTeste -Teste $Nome -Sucesso $sucesso -TempoMs $relogio.ElapsedMilliseconds -Detalhe $detalhe
}
Invoke-TesteRede 'Gateway' {
    $gateway = Get-NetIPConfiguration -ErrorAction Stop | Where-Object { $_.IPv4DefaultGateway } | Select-Object -First 1
    if (-not $gateway) { throw 'Gateway IPv4 não encontrado.' }
    Test-Connection -ComputerName $gateway.IPv4DefaultGateway.NextHop -Count 1 -Quiet -ErrorAction Stop
}
Invoke-TesteRede "DNS: $DestinoInternet" { $null -ne (Resolve-DnsName -Name $DestinoInternet -ErrorAction Stop | Select-Object -First 1) }
Invoke-TesteRede "Internet: $DestinoInternet" { Test-Connection -ComputerName $DestinoInternet -Count 1 -Quiet -ErrorAction Stop }
foreach ($porta in $Portas) {
    Invoke-TesteRede "TCP: $DestinoInternet`:$porta" { (Test-NetConnection -ComputerName $DestinoInternet -Port $porta -WarningAction SilentlyContinue -ErrorAction Stop).TcpTestSucceeded }
}
