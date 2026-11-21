<#
.SYNOPSIS
    Funções puras compartilhadas pelos scripts de manutenção do kit-suporte.
.DESCRIPTION
    Estas funções não dependem de estado externo (registro, filesystem ou privilege)
    e podem ser testadas isoladamente pelo Pester. Os scripts de manutencao
    as carregam por dot-source (_funcoes-manutencao.ps1) e usam como helper.
#>

function Convert-BytesToMB {
    <#
    .SYNOPSIS
        Converte uma quantidade de bytes em megabytes (MB).
    .DESCRIPTION
        Divide o valor em bytes por 1 MB (1048576) e arredonda para 2 casas
        decimais. Função pura: mesmo entrada, mesma saída, sem efeitos colaterais.
    .PARAMETER Bytes
        Quantidade de bytes (inteiro longo).
    .EXAMPLE
        Convert-BytesToMB -Bytes 2097152
        # retorna 2
    #>
    param(
        [long]$Bytes
    )

    if ($Bytes -lt 0) {
        return [Math]::Round(0.0, 2)
    }

    return [Math]::Round($Bytes / 1MB, 2)
}

function Get-TempFilesTotalMB {
    <#
    .SYNOPSIS
        Soma o tamanho (em MB) de uma lista de arquivos.
    .DESCRIPTION
        Recebe uma lista de arquivos (System.IO.FileInfo ou qualquer objeto
        com propriedade Length) e retorna a soma do tamanho em megabytes,
        usando Convert-BytesToMB. Função pura.
    .PARAMETER Files
        Lista de arquivos. Cada elemento precisa ter a propriedade Length.
    .EXAMPLE
        Get-TempFilesTotalMB -Files (Get-ChildItem -Path $env:TEMP -File)
    #>
    param(
        [object[]]$Files
    )

    if (-not $Files) {
        return 0
    }

    $totalBytes = 0
    foreach ($arquivo in $Files) {
        $length = $arquivo.Length
        if ($null -ne $length) {
            $totalBytes += [long]$length
        }
    }

    return Convert-BytesToMB -Bytes $totalBytes
}

function New-SoftwareObject {
    <#
    .SYNOPSIS
        Monta um objeto de software a partir de propriedades brutas do registro.
    .DESCRIPTION
        Normaliza uma entrada da.chave de Uninstall do registro em um
        [PSCustomObject] com as colunas Nome, Versao, Fabricante e
        DataInstalacao. Entradas sem DisplayName (nome) sao ignoradas
        (retorna $null), pois nao representam um software instalado util.
        A DataInstalacao e convertida de yyyyMMdd para [DateTime].
    .PARAMETER DisplayName
        Valor da propriedade DisplayName da chave de uninstall.
    .PARAMETER DisplayVersion
        Valor da propriedade DisplayVersion (versao do software).
    .PARAMETER Publisher
        Valor da propriedade Publisher (fabricante/editor).
    .PARAMETER InstallDate
        Valor da propriedade InstallDate no formato yyyyMMdd.
    .EXAMPLE
        New-SoftwareObject -DisplayName "Git" -DisplayVersion "2.46" -Publisher "Git SCM" -InstallDate "20230315"
    #>
    param(
        [string]$DisplayName,
        [string]$DisplayVersion,
        [string]$Publisher,
        [string]$InstallDate
    )

    if ([string]::IsNullOrWhiteSpace($DisplayName)) {
        return $null
    }

    $dataInstalacao = $null
    if (-not [string]::IsNullOrWhiteSpace($InstallDate)) {
        try {
            $dataInstalacao = [DateTime]::ParseExact(
                $InstallDate.Trim(),
                'yyyyMMdd',
                [System.Globalization.CultureInfo]::InvariantCulture
            )
        } catch {
            # Data mal formatada no registro: mantem como nula e nao quebra a saida
            $dataInstalacao = $null
        }
    }

    return [PSCustomObject]@{
        Nome           = $DisplayName.Trim()
        Versao         = $DisplayVersion
        Fabricante     = $Publisher
        DataInstalacao = $dataInstalacao
    }
}

function Test-IsAdministrator {
    <#
    .SYNOPSIS
        Verifica se o principal atual e membro do grupo Administradores.
    .DESCRIPTION
        Funcao pura: recebe um objeto de principal (por exemplo, um
        System.Security.Principal.WindowsPrincipal) e retorna $true se ele
        pertence ao papel Administrador. Usada pelos scripts que precisam de
        elevacao de privilegio. Nao chama WindowsIdentity::GetCurrent por si
        so, permitindo injecao em testes.
    .PARAMETER Principal
        Objeto com o metodo IsInRole (ex: WindowsPrincipal).
    .EXAMPLE
        Test-IsAdministrator -Principal (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent()))
    #>
    param(
        [object]$Principal
    )

    if (-not $Principal) {
        return $false
    }

    try {
        return [bool]$Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}