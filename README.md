# Kit de Scripts PowerShell para Suporte

Scripts para as tarefas repetitivas de suporte N1/N2 em Windows, prontos para rodar sem instalar nada.

## Problema

No atendimento de suporte, as mesmas perguntas se repetem em toda máquina: qual é o hardware, a rede está de pé, o disco está cheio, o que está instalado, por que a impressora travou. Fazer isso à mão é lento e cada pessoa anota de um jeito. O kit padroniza a coleta e devolve objetos PowerShell (exportáveis) e um relatório HTML que pode ser anexado ao chamado.

## Solução

| Problema | Script | Exemplo de uso |
|---|---|---|
| Qual é a máquina? | `Get-InventarioPC.ps1` | `.\scripts\Get-InventarioPC.ps1 -Saida .\inventario.csv` |
| A rede está funcionando? | `Test-RedeBasico.ps1` | `.\scripts\Test-RedeBasico.ps1 -DestinoInternet example.com -Portas 80,443` |
| Disco cheio ou com defeito? | `Get-SaudeDisco.ps1` | `.\scripts\Get-SaudeDisco.ps1` |
| O que está instalado? | `Get-SoftwareInstalado.ps1` | `.\scripts\Get-SoftwareInstalado.ps1 -Saida .\software.csv` |
| Máquina lenta por temporários | `Clear-ArquivosTemporarios.ps1` | `.\scripts\Clear-ArquivosTemporarios.ps1 -WhatIf` |
| Impressora travada | `Repair-FilaImpressao.ps1` | `.\scripts\Repair-FilaImpressao.ps1` (como administrador) |
| Evidência para o chamado | `New-RelatorioSuporte.ps1` | `.\scripts\New-RelatorioSuporte.ps1 -Saida .\relatorio.html` |

Um exemplo do relatório, com dados fictícios, está em `exemplos/relatorio-exemplo.html`.

## Como rodar

Requisitos: Windows 10 ou 11 com Windows PowerShell 5.1 (já incluso). Baixe o repositório e, na pasta dele:

```powershell
# se a política de execução bloquear os scripts, apenas nesta sessão:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\Test-RedeBasico.ps1
```

Os scripts que alteram a máquina (`Clear-ArquivosTemporarios` e `Repair-FilaImpressao`) aceitam `-WhatIf` e `-Confirm`. `Repair-FilaImpressao` exige PowerShell como administrador e avisa quando não estiver.

### Testes e qualidade (para quem desenvolve)

Requer Pester 5 ou superior e PSScriptAnalyzer:

```powershell
Invoke-Pester -Path .\tests
Invoke-ScriptAnalyzer -Path . -Recurse -Settings .\PSScriptAnalyzerSettings.psd1
```

Os testes cobrem as funções puras (formatação de tamanho, percentual livre, classificação de disco, escape de HTML, conversão de bytes, filtro do registro). A coleta em si depende do Windows e é validada manualmente.

## Estrutura

```
scripts/    um script por problema, mais _funcoes-manutencao.ps1 (funções puras da manutenção)
modulo/     KitSuporte.psm1/.psd1: funções puras compartilhadas
tests/      testes Pester
exemplos/   relatório HTML de exemplo (dados fictícios)
```

## Decisões técnicas

- **Objetos, não texto.** Cada script emite objetos; o usuário decide se exporta para CSV, HTML ou segue o pipeline.
- **Lógica pura separada da coleta.** Cálculo, formatação e classificação ficam em funções sem dependência do Windows, testáveis em qualquer sistema.
- **`-WhatIf`/`-Confirm`** (`SupportsShouldProcess`) em tudo que apaga ou para serviços.
- **Software pelo registro**, não por `Win32_Product`, que é lento e pode disparar reparos de instalação.
- **Relatório HTML autossuficiente**: CSS embutido, sem rede, com escape de todo valor coletado.
- **Arquivos com BOM UTF-8**, para o Windows PowerShell 5.1 ler os acentos corretamente.

## Limitações

- Desenvolvido e testado automaticamente em PowerShell 7 com Pester; os cmdlets exclusivos do Windows (CIM, `Test-NetConnection`, `Resolve-DnsName`, spooler, registro) foram validados apenas por revisão e precisam de teste manual no Windows 10/11.
- `Test-RedeBasico` usa o gateway IPv4 padrão; ambientes só com IPv6 não são cobertos.
- `Clear-ArquivosTemporarios` ignora arquivos em uso e não limpa caches de navegadores.
- Sem execução remota: cada script roda na máquina local.

## Próximos passos

Execução remota por lista de máquinas; ponte com o projeto Monitor de Filiais, que usará estes scripts como agente de coleta.
