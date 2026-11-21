BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../modulo/KitSuporte.psd1') -Force
}
Describe 'Funções compartilhadas' {
    It 'formata zero e unidades binárias' {
        ConvertTo-TamanhoLegivel 0 | Should -Be '0 B'
        ConvertTo-TamanhoLegivel 1024 | Should -Be '1 KB'
        ConvertTo-TamanhoLegivel 1536 | Should -Be '1,5 KB'
    }
    It 'calcula percentual e rejeita capacidade zero ou valores inválidos' {
        Get-PercentualLivre -Livre 25 -Total 100 | Should -Be 25
        { Get-PercentualLivre -Livre 0 -Total 0 } | Should -Throw
        { Get-PercentualLivre -Livre 101 -Total 100 } | Should -Throw
        { Get-PercentualLivre -Livre -1 -Total 100 } | Should -Throw
    }
    It 'classifica limites inclusivos e aceita limiares personalizados' {
        Get-ClassificacaoDisco 10 | Should -Be 'CRITICO'
        Get-ClassificacaoDisco 20 | Should -Be 'ALERTA'
        Get-ClassificacaoDisco 20.01 | Should -Be 'OK'
        Get-ClassificacaoDisco 30 -Critico 15 -Alerta 30 | Should -Be 'ALERTA'
        { Get-ClassificacaoDisco 10 -Critico 30 -Alerta 20 } | Should -Throw
        { Get-ClassificacaoDisco 101 } | Should -Throw
    }
    It 'formata resultado em objeto com tempo' {
        $resultado = Format-ResultadoTeste -Teste 'DNS' -Sucesso $false -TempoMs 12
        $resultado.Teste | Should -Be 'DNS'
        $resultado.Status | Should -Be 'FALHA'
        $resultado.TempoMs | Should -Be 12
    }
    It 'escapa HTML e aceita texto vazio' {
        ConvertTo-HtmlSeguro '<script a="x">&' | Should -Be '&lt;script a=&quot;x&quot;&gt;&amp;'
        ConvertTo-HtmlSeguro '' | Should -Be ''
    }
}
