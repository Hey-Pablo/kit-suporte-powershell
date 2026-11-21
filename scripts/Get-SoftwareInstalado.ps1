<#
.SYNOPSIS
    Lista os softwares instalados a partir do registro.
.DESCRIPTION
    Lê as chaves de Uninstall do registro (HKLM 64 bits, HKLM 32 bits e HKCU)
    e retorna um objeto por software com Nome, Versao, Fabricante e
    DataInstalacao. Não usa Win32_Product (lento e dispara reparo do WMI).

    Exemplos de uso:
        .\Get-SoftwareInstalado.ps1
        .\Get-SoftwareInstalado.ps1 -Saida .\softwares.csv
.PARAMETER Saida
    Caminho do arquivo CSV para exportar a lista de softwares.
    Opcional. Se omitido, o resultado é exibido na tela.
.EXAMPLE
    .\Get-SoftwareInstalado.ps1
    Lista todos os softwares instalados na máquina.
#>
[CmdletBinding()]
param(
    [string]$Saida
)

. "$PSScriptRoot\_funcoes-manutencao.ps1"

function Get-UninstallRoots {
    <#
    .SYNOPSIS
        Retorna os caminhos das chaves de Uninstall do registro.
    .DESCRIPTION
        Lista os roots de 64 bits, 32 bits (na view de 32 bits do registro)
        e de usuário atual. Cada caminho é retornado como string pronta
        para Get-ChildItem.
    #>
    $roots = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    return $roots
}

try {
    $softwares = [System.Collections.Generic.List[PSObject]]::new()
    $roots = Get-UninstallRoots

    foreach ($root in $roots) {
        $chaves = Get-ChildItem -LiteralPath $root -ErrorAction SilentlyContinue
        foreach ($chave in $chaves) {
            $props = Get-ItemProperty -LiteralPath $chave.PSPath -ErrorAction SilentlyContinue
            if (-not $props) { continue }

            $software = New-SoftwareObject `
                -DisplayName $props.DisplayName `
                -DisplayVersion $props.DisplayVersion `
                -Publisher $props.Publisher `
                -InstallDate $props.InstallDate

            if ($software) {
                $softwares.Add($software)
            }
        }
    }

    $ordenado = $softwares | Sort-Object Nome
    if ($Saida) {
        $ordenado | Export-Csv -LiteralPath $Saida -NoTypeInformation -Encoding UTF8
        Write-Verbose "Lista exportada para $Saida"
    }

    Write-Output $ordenado
} catch {
    Write-Error "Falha ao listar softwares instalados: $($_.Exception.Message)"
    throw
}