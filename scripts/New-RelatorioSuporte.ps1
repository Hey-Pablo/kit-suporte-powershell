<#
.SYNOPSIS
Gera relatório HTML local com inventário, rede, discos e software disponível.
.PARAMETER Saida
Caminho do arquivo HTML a criar.
.EXAMPLE
.\scripts\New-RelatorioSuporte.ps1 -Saida .\relatorio.html
#>
[CmdletBinding()]
param([string]$Saida = '.\relatorio-suporte.html')
Import-Module (Join-Path $PSScriptRoot '../modulo/KitSuporte.psd1') -Force
function ConvertTo-TabelaRelatorio {
    param([object[]]$Itens)
    if (-not $Itens -or $Itens.Count -eq 0) { return '<p>Dados indisponíveis.</p>' }
    $colunas = @($Itens | ForEach-Object { $_.PSObject.Properties.Name } | Select-Object -Unique)
    $html = '<table><thead><tr>' + (($colunas | ForEach-Object { '<th>' + (ConvertTo-HtmlSeguro ([string]$_)) + '</th>' }) -join '') + '</tr></thead><tbody>'
    foreach ($item in $Itens) {
        $html += '<tr>'
        foreach ($coluna in $colunas) {
            $valor = $item.$coluna
            $html += '<td>' + (ConvertTo-HtmlSeguro ([string]($valor -join '; '))) + '</td>'
        }
        $html += '</tr>'
    }
    $html + '</tbody></table>'
}
$secoes = @(
    @{ Titulo = 'Inventário'; Script = 'Get-InventarioPC.ps1' },
    @{ Titulo = 'Rede'; Script = 'Test-RedeBasico.ps1' },
    @{ Titulo = 'Discos'; Script = 'Get-SaudeDisco.ps1' },
    @{ Titulo = 'Software'; Script = 'Get-SoftwareInstalado.ps1' }
)
$conteudo = foreach ($secao in $secoes) {
    $caminho = Join-Path $PSScriptRoot $secao.Script
    $dados = @()
    $mensagem = ''
    if (Test-Path -LiteralPath $caminho) {
        try { $dados = @(& $caminho -ErrorAction Stop) }
        catch { $mensagem = $_.Exception.Message }
    } else { $mensagem = 'Script não disponível.' }
    '<section><h2>' + (ConvertTo-HtmlSeguro $secao.Titulo) + '</h2>' + $(if ($mensagem) { '<p>Falha na coleta: ' + (ConvertTo-HtmlSeguro $mensagem) + '</p>' } else { ConvertTo-TabelaRelatorio $dados }) + '</section>'
}
$html = @'
<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Relatório de suporte</title><style>body{font:16px Arial,sans-serif;max-width:1200px;margin:2rem auto;padding:0 1rem;color:#192634}h1,h2{color:#174b75}section{overflow-x:auto;margin:2rem 0}table{border-collapse:collapse;width:100%}th,td{border:1px solid #b8c8d5;padding:.6rem;text-align:left;vertical-align:top}th{background:#e7f1f8}</style></head><body><h1>Relatório de suporte</h1>
'@ + ($conteudo -join "`n") + '</body></html>'
try {
    Set-Content -LiteralPath $Saida -Value $html -Encoding UTF8 -ErrorAction Stop
    Get-Item -LiteralPath $Saida -ErrorAction Stop
} catch { Write-Error "Falha ao gerar relatório: $_" }
