# Kit de Scripts PowerShell para Suporte

> **Status: em desenvolvimento.** O código entra aos poucos; abaixo está o planejamento do projeto.

## O que é

Conjunto de scripts para as tarefas repetitivas de suporte N1/N2 em Windows: inventário da máquina, diagnóstico de rede, limpeza de temporários, lista de softwares, reparo da fila de impressão, saúde de disco e um relatório HTML que junta tudo.

## O que prova

Automação de suporte, PowerShell com boas práticas (parâmetros, ajuda, `-WhatIf`, tratamento de erro) e documentação.

## Stack

Windows PowerShell 5.1, sem módulos externos para executar. Pester para testes e PSScriptAnalyzer para qualidade durante o desenvolvimento.

## Estrutura

```
kit-suporte-powershell/
├─ scripts/
│  ├─ Get-InventarioPC.ps1           # hardware, SO, serial, IP, último boot
│  ├─ Test-RedeBasico.ps1            # gateway, DNS, internet, portas
│  ├─ Clear-ArquivosTemporarios.ps1
│  ├─ Get-SoftwareInstalado.ps1
│  ├─ Repair-FilaImpressao.ps1       # para o spooler, limpa a fila, reinicia
│  ├─ Get-SaudeDisco.ps1             # espaço livre e estado dos discos
│  └─ New-RelatorioSuporte.ps1       # HTML com tudo
├─ modulo/KitSuporte.psm1            # funções compartilhadas
├─ tests/                            # Pester
├─ exemplos/relatorio-exemplo.html
└─ README.md
```

## Plano

1. Liste os 7 problemas mais comuns que você resolvia e associe um script a cada um.
2. Inventário com `Get-CimInstance` (`Win32_ComputerSystem`, `Win32_BIOS`, `Win32_Processor`, `Win32_OperatingSystem`, `Win32_LogicalDisk`).
3. Rede com `Test-NetConnection` e `Resolve-DnsName`, com saída em tabela de OK ou FALHA.
4. Scripts que alteram a máquina com `[CmdletBinding(SupportsShouldProcess)]`, para aceitar `-WhatIf` e `-Confirm`.
5. Saída sempre em objetos, com opção de exportar para CSV ou HTML.
6. Ajuda em cada script (`.SYNOPSIS`, `.PARAMETER`, `.EXAMPLE`) e erros tratados com `try/catch`.
7. Testes Pester das funções puras: cálculo de espaço livre, formatação, classificação em OK ou alerta.
8. Rode o PSScriptAnalyzer e corrija os avisos.
9. README com tabela "problema, script, exemplo de uso" e capturas de tela.

## Como deve funcionar

- `.\Get-InventarioPC.ps1 -Saida .\inventario.csv` gera o arquivo com os dados da máquina.
- `.\Test-RedeBasico.ps1` mostra cada teste com resultado e tempo.
- `.\Clear-ArquivosTemporarios.ps1 -WhatIf` lista o que seria apagado sem apagar. Sem o parâmetro, informa os MB liberados.
- `.\Repair-FilaImpressao.ps1` exige execução como administrador e avisa quando não tem.
- `.\New-RelatorioSuporte.ps1` gera um HTML único, pronto para anexar ao chamado.
- Tudo roda em Windows 10 e 11 sem instalar nada.

## Prazo

3 a 5 dias.

## Autor

Pablo Dilio · [Portfólio](https://hey-pablo.github.io/pablo-dilio-portfolio/) · [LinkedIn](https://www.linkedin.com/in/pablo-dilio-4063991b2)
