@{
    Rules = @{
        PSUseCompatibleSyntax = @{ Enable = $true; TargetVersions = @('5.1') }
        PSUseSingularNouns = @{ Enable = $false }
        # New-SoftwareObject é uma função de transformação de dados, não modifica sistema.
        PSUseShouldProcessForStateChangingFunctions = @{
            Enable = $true
            Exclude = @('scripts/_funcoes-manutencao.ps1')
        }
    }
}