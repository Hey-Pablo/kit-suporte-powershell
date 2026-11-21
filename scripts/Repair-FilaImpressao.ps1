<#
.SYNOPSIS
    Repara a fila de impressão do Windows.
.DESCRIPTION
    Exige execução como administrador. Se não houver privilégio suficiente,
    exibe uma mensagem clara e encerra. Caso contrário, para o serviço de
    impressão (Spooler), apaga os arquivos da fila (C:\Windows\System32\spool\PRINTERS)
    e reinicia o serviço, confirmando o estado final.

    Exemplos de uso:
        .\Repair-FilaImpressao.ps1
        .\Repair-FilaImpressao.ps1 -WhatIf
.PARAMETER WhatIf
    Mostra o que seria feito sem parar o spooler nem apagar arquivos.
.EXAMPLE
    .\Repair-FilaImpressao.ps1
    Repara a fila de impressão (requer administrador).
#>
[CmdletBinding(SupportsShouldProcess)]
param()

. "$PSScriptRoot\_funcoes-manutencao.ps1"

function Test-Administrador {
    <#
    .SYNOPSIS
        Verifica se o contexto atual é administrador.
    .DESCRIPTION
        Cria um WindowsPrincipal com a identidade atual e usa Test-IsAdministrator
        para avaliar a pertença ao papel Administrador. Mantém a lógica pura
        separada da verificação real de identidade.
    .EXAMPLE
        Test-Administrador
        # retorna $true ou $false
    #>
    $principal = New-Object System.Security.Principal.WindowsPrincipal(
        [System.Security.Principal.WindowsIdentity]::GetCurrent()
    )
    return Test-IsAdministrator -Principal $principal
}

try {
    if (-not (Test-Administrador)) {
        Write-Error "Este script exige execução como Administrador. Clique com o botão direito em PowerShell e escolha 'Executar como administrador', depois rode novamente .\Repair-FilaImpressao.ps1"
        exit 1
    }

    $spooler = Get-Service -Name Spooler -ErrorAction SilentlyContinue
    if (-not $spooler) {
        Write-Error "Servico de impressao (Spooler) nao encontrado na maquina."
        exit 1
    }

    Write-Host "Parando o servico de impressao (Spooler)..." -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess("Servico Spooler", "Parar servico de impressao")) {
        Stop-Service -Name Spooler -Force -ErrorAction Stop
    }

    $pastaFila = "$env:SystemRoot\System32\spool\PRINTERS"
    if ($PSCmdlet.ShouldProcess($pastaFila, "Apagar arquivos da fila de impressao")) {
        if (Test-Path -LiteralPath $pastaFila) {
            $arquivos = Get-ChildItem -LiteralPath $pastaFila -File -ErrorAction SilentlyContinue
            foreach ($arquivo in $arquivos) {
                try {
                    Remove-Item -LiteralPath $arquivo.FullName -Force -ErrorAction Stop
                    Write-Verbose "Arquivo removido: $($arquivo.FullName)"
                } catch {
                    Write-Verbose "Nao foi possivel remover $($arquivo.FullName): $($_.Exception.Message)"
                }
            }
        } else {
            Write-Verbose "Pasta da fila nao encontrada: $pastaFila"
        }
    }

    Write-Host "Iniciando o servico de impressao (Spooler)..." -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess("Servico Spooler", "Iniciar servico de impressao")) {
        Start-Service -Name Spooler -ErrorAction Stop
    }

    $estadoFinal = Get-Service -Name Spooler -ErrorAction SilentlyContinue
    $resultado = [PSCustomObject]@{
        Servico         = $spooler.Name
        EstadoAnterior  = $spooler.Status
        EstadoFinal     = $estadoFinal.Status
        PastaFila       = $pastaFila
        ArquivosApagados = (Get-ChildItem -LiteralPath $pastaFila -File -ErrorAction SilentlyContinue).Count
        ReparadoEm      = Get-Date
    }

    Write-Output $resultado
} catch {
    Write-Error "Falha ao reparar a fila de impressao: $($_.Exception.Message)"
    throw
}