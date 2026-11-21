<#
.SYNOPSIS
    Limpa os arquivos temporários do Windows.
.DESCRIPTION
    Remove arquivos das pastas de temporários do sistema ($env:TEMP e
    C:\Windows\Temp). Aceita -WhatIf e -Confirm, ignora arquivos em uso sem
    falhar e, ao final, informa quantos megabytes foram liberados.

    Exemplos de uso:
        .\Clear-ArquivosTemporarios.ps1 -WhatIf
        .\Clear-ArquivosTemporarios.ps1 -Confirm:$false
        .\Clear-ArquivosTemporarios.ps1 -Saida .\limpeza.csv
.PARAMETER Saida
    Caminho do arquivo CSV para exportar o relatório de limpeza.
    Opcional. Se omitido, o resultado é exibido na tela.
.EXAMPLE
    .\Clear-ArquivosTemporarios.ps1
    Remove os temporários e exibe o total de MB liberados.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Saida
)

# Carrega as funções puras do kit (dot-source com guarda).
. "$PSScriptRoot\_funcoes-manutencao.ps1"

function Get-TempFolders {
    <#
    .SYNOPSIS
        Lista as pastas de temporários que devem ser limpas.
    .DESCRIPTION
        Retorna os caminhos de $env:TEMP e C:\Windows\Temp, deduplicados
        e normalizados. Usado para centralizar a lista de pastas alvo.
    #>
    $pastas = @($env:TEMP, "$env:SystemRoot\Temp")
    return $pastas | Where-Object { $_ } | ForEach-Object { (Get-Item -LiteralPath $_ -ErrorAction SilentlyContinue).FullName } | Select-Object -Unique
}

try {
    $pastas = Get-TempFolders
    $arquivosRemovidos = 0
    $bytesLiberados = 0L
    $itens = @()

    foreach ($pasta in $pastas) {
        if (-not (Test-Path -LiteralPath $pasta)) {
            Write-Verbose "Pasta nao encontrada, ignorada: $pasta"
            continue
        }

        $arquivos = Get-ChildItem -LiteralPath $pasta -File -ErrorAction SilentlyContinue
        foreach ($arquivo in $arquivos) {
            try {
                if ($PSCmdlet.ShouldProcess($arquivo.FullName, "Remover arquivo temporario")) {
                    Remove-Item -LiteralPath $arquivo.FullName -Force -ErrorAction Stop
                    $arquivosRemovidos++
                    $bytesLiberados += [long]$arquivo.Length
                    $itens += [PSCustomObject]@{
                        Caminho         = $arquivo.FullName
                        TamanhoBytes    = [long]$arquivo.Length
                        TamanhoMB       = Convert-BytesToMB -Bytes ([long]$arquivo.Length)
                        RemovidoEm      = Get-Date
                    }
                }
            } catch {
                # Arquivo em uso ou sem permissao: ignora sem falhar o script
                Write-Verbose "Nao foi possivel remover $($arquivo.FullName): $($_.Exception.Message)"
            }
        }
    }

    $mbLiberados = Convert-BytesToMB -Bytes $bytesLiberados
    $resultado = [PSCustomObject]@{
        PastasAnalisadas  = $pastas
        ArquivosRemovidos = $arquivosRemovidos
        MBLiberados       = $mbLiberados
        Itens             = $itens
    }

    if ($Saida) {
        $resultado.Itens | Export-Csv -LiteralPath $Saida -NoTypeInformation -Encoding UTF8
        Write-Verbose "Relatorio exportado para $Saida"
    }

    Write-Output $resultado
} catch {
    Write-Error "Falha ao limpar temporários: $($_.Exception.Message)"
    throw
}