<#
.SYNOPSIS
    Testes Pester 5 das funções puras do kit-suporte.
.DESCRIPTION
    Carrega scripts/_funcoes-manutencao.ps1 por dot-source e executa os
    testes das funções puras: conversão de bytes, soma de temporários,
    normalização de entradas do registro e verificação de administrador.

    Como rodar no Windows:
        Import-Module Pester
        Invoke-Pester -Script .\tests\Selmo.Tests.ps1
#>

beforeAll {
    . "$PSScriptRoot/../scripts/_funcoes-manutencao.ps1"
}

Describe "Convert-BytesToMB" {
    It "Converte 1 MB exato em 1,00" {
        Convert-BytesToMB -Bytes 1048576 | Should -Be 1
    }

    It "Converte 2 MB exato em 2,00" {
        Convert-BytesToMB -Bytes 2097152 | Should -Be 2
    }

    It "Converte 1536 bytes em 0,00 (arredonda para 2 casas)" {
        Convert-BytesToMB -Bytes 1536 | Should -Be 0
    }

    It "Converte 5242880 bytes (5 MB) em 5,00" {
        Convert-BytesToMB -Bytes 5242880 | Should -Be 5
    }

    It "Retorna 0 para valor negativo" {
        Convert-BytesToMB -Bytes -100 | Should -Be 0
    }

    It "Retorna 0 para zero bytes" {
        Convert-BytesToMB -Bytes 0 | Should -Be 0
    }
}

Describe "Get-TempFilesTotalMB" {
    It "Soma o tamanho de dois arquivos" {
        $a = [PSCustomObject]@{ Length = 1048576L }
        $b = [PSCustomObject]@{ Length = 1048576L }
        Get-TempFilesTotalMB -Files @($a, $b) | Should -Be 2
    }

    It "Ignora arquivos sem propriedade Length" {
        $a = [PSCustomObject]@{ Length = 1048576L }
        $b = [PSCustomObject]@{ SemLength = 100 }
        Get-TempFilesTotalMB -Files @($a, $b) | Should -Be 1
    }

    It "Retorna 0 para lista vazia" {
        Get-TempFilesTotalMB -Files @() | Should -Be 0
    }

    It "Retorna 0 para lista nula" {
        Get-TempFilesTotalMB -Files $null | Should -Be 0
    }
}

Describe "New-SoftwareObject" {
    It "Cria objeto com Nome, Versao, Fabricante e DataInstalacao" {
        $s = New-SoftwareObject -DisplayName "Git" -DisplayVersion "2.46" -Publisher "Git SCM" -InstallDate "20230315"
        $s.'Nome' | Should -Be "Git"
        $s.'Versao' | Should -Be "2.46"
        $s.'Fabricante' | Should -Be "Git SCM"
        $s.'DataInstalacao' | Should -Be ([DateTime]"2023-03-15")
    }

    It "Retorna nulo quando DisplayName e vazio ou nulo" {
        New-SoftwareObject -DisplayName "" | Should -Be $null
        New-SoftwareObject -DisplayName $null | Should -Be $null
        New-SoftwareObject -DisplayName "   " | Should -Be $null
    }

    It "Trimma o Nome (remove espacos nas bordas)" {
        $s = New-SoftwareObject -DisplayName "  Git  "
        $s.'Nome' | Should -Be "Git"
    }

    It "DataInstalacao e nula quando InstallDate esta em branco" {
        $s = New-SoftwareObject -DisplayName "Git" -InstallDate ""
        $s.'DataInstalacao' | Should -Be $null
    }

    It "DataInstalacao e nula quando InstallDate nao e yyyyMMdd" {
        $s = New-SoftwareObject -DisplayName "Git" -InstallDate "nao-é-data"
        $s.'DataInstalacao' | Should -Be $null
    }
}

Describe "Test-IsAdministrator" {
    It "Retorna falso quando o principal e nulo" {
        Test-IsAdministrator -Principal $null | Should -Be $false
    }

    It "Retorna falso quando o principal lanca excecao" {
        $falso = New-Object PSObject
        $falso | Add-Member -MemberType ScriptMethod -Name IsInRole -Value { throw "erro" }
        Test-IsAdministrator -Principal $falso | Should -Be $false
    }

    It "Retorna verdadeiro quando o principal confirma papel Administrador" {
        $verdadeiro = New-Object PSObject
        $verdadeiro | Add-Member -MemberType ScriptMethod -Name IsInRole -Value { $true }
        Test-IsAdministrator -Principal $verdadeiro | Should -Be $true
    }
}