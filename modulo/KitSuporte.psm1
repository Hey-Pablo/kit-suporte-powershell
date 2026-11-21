﻿function ConvertTo-TamanhoLegivel {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position=0)][ValidateRange(0, [double]::MaxValue)][double]$Bytes)
    $unidades = @('B', 'KB', 'MB', 'GB', 'TB', 'PB')
    $indice = 0
    while ($Bytes -ge 1024 -and $indice -lt $unidades.Count - 1) { $Bytes /= 1024; $indice++ }
    '{0} {1}' -f $Bytes.ToString('0.##', [System.Globalization.CultureInfo]::InvariantCulture).Replace('.', ','), $unidades[$indice]
}
function Get-PercentualLivre {
    [CmdletBinding()]
    param([Parameter(Mandatory)][double]$Livre, [Parameter(Mandatory)][double]$Total)
    if ($Total -le 0 -or $Livre -lt 0 -or $Livre -gt $Total) { throw 'Capacidade ou espaço livre inválido.' }
    [math]::Round(100 * $Livre / $Total, 2)
}
function Get-ClassificacaoDisco {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position=0)][ValidateRange(0,100)][double]$PercentualLivre,
        [ValidateRange(0,100)][double]$Critico = 10, [ValidateRange(0,100)][double]$Alerta = 20)
    if ($Critico -gt $Alerta) { throw 'O limite crítico não pode superar o limite de alerta.' }
    if ($PercentualLivre -le $Critico) { 'CRITICO' } elseif ($PercentualLivre -le $Alerta) { 'ALERTA' } else { 'OK' }
}
function Format-ResultadoTeste {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Teste, [Parameter(Mandatory)][bool]$Sucesso,
        [Parameter(Mandatory)][ValidateRange(0,[double]::MaxValue)][double]$TempoMs, [string]$Detalhe = '')
    [pscustomobject]@{ Teste = $Teste; Status = $(if ($Sucesso) { 'OK' } else { 'FALHA' }); TempoMs = $TempoMs; Detalhe = $Detalhe }
}
function ConvertTo-HtmlSeguro {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position=0)][AllowEmptyString()][string]$Texto)
    [System.Net.WebUtility]::HtmlEncode($Texto)
}
Export-ModuleMember -Function ConvertTo-TamanhoLegivel, Get-PercentualLivre, Get-ClassificacaoDisco, Format-ResultadoTeste, ConvertTo-HtmlSeguro
