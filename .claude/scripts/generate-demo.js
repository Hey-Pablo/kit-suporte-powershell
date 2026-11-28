const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const DOCS_DIR = __dirname; // .claude/scripts
const IMAGES_DIR = path.join(DOCS_DIR, '..', '..', 'docs', 'img');
const FILES_DIR = path.join(DOCS_DIR, '..', '..', 'docs');

// Mock PowerShell script output data
const mockOutputs = {
    'Get-InventarioPC': {
        title: 'Inventário de Hardware',
        output: `Computador     : SUPORTE-PC01
Fabricante     : Dell Inc.
Modelo         : OptiPlex 7090
MemoriaBytes   : 17179869184 (16 GB)
Serial         : 8F2K3J1L2M3
Processador    : Intel Core i7-10700 CPU @ 2.90GHz
Sistema        : Microsoft Windows 11 Pro
Versao         : 10.0.22631
UltimoBoot     : 27/11/2026 08:15:23
IP             : 192.168.1.45
Discos         : C: (452 GB livres de 931 GB)`
    },
    'Test-RedeBasico': {
        title: 'Diagnóstico de Rede',
        output: `Teste                     Status  TempoMs
------                    ------  -------
Gateway IPv4                OK          3ms
DNS: example.com           OK         18ms
Internet: example.com       OK         32ms
TCP: example.com:80         OK         41ms
TCP: example.com:443        OK         38ms`
    },
    'Get-SaudeDisco': {
        title: 'Status dos Discos',
        output: `Nome  TamanhoGB  LivreGB  PercentualLivre  Status
----  ---------  -------  ---------------  ------
C:    931        421      45%              OK
D:    466        200      43%              OK`
    },
    'Get-SoftwareInstalado': {
        title: 'Software Instalado',
        output: `Nome                Versao     Fabricante        DataInstalacao
----                ------     ----------        --------------
Git                 2.46.0     Git SCM           15/03/2024
Visual Studio Code  1.94.0     Microsoft Corp.   10/10/2024
7-Zip               24.05      Igor Pavlov       22/01/2024
Google Chrome       131.0      Google LLC        05/11/2024
PowerShell 7        7.4.6      Microsoft Corp.   18/09/2024`
    }
};

async function capturePage(page, scriptName, output) {
    const html = generateHtmlPage(scriptName, output);
    await page.setContent(html, { waitUntil: 'networkidle' });
    await page.waitForTimeout(1000);
}

function generateHtmlPage(scriptName, data) {
    return `
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${data.title} - Demo</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Cascadia Code', 'Fira Code', 'Consolas', monospace;
            background: #0d1117;
            color: #e6edf3;
            min-height: 100vh;
            padding: 20px;
            line-height: 1.6;
        }
        .container {
            max-width: 900px;
            margin: 0 auto;
            background: #161b22;
            border: 1px solid #30363d;
            border-radius: 8px;
            padding: 24px;
            box-shadow: 0 8px 24px rgba(0,0,0,0.5);
        }
        h1 {
            color: #58a6ff;
            margin-bottom: 16px;
            font-size: 24px;
        }
        .prompt {
            color: #7ee787;
            margin-bottom: 16px;
        }
        .command {
            color: #f2cc60;
        }
        .output {
            background: #0d1117;
            border: 1px solid #30363d;
            border-radius: 6px;
            padding: 16px;
            font-size: 14px;
            overflow-x: auto;
            white-space: pre-wrap;
            word-wrap: break-word;
        }
        .output-table {
            border-collapse: collapse;
            margin: 12px 0;
        }
        .output-table th, .output-table td {
            border: 1px solid #30363d;
            padding: 8px 12px;
            text-align: left;
        }
        .output-table th {
            background: #21262d;
            color: #f2cc60;
        }
        .output-table tr:nth-child(even) { background: #1c2128; }
        .footer {
            color: #8b949e;
            font-size: 12px;
            margin-top: 24px;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>PS> .\\scripts\\${scriptName}.ps1</h1>
        <div class="prompt">Sugestão: ${data.title}</div>
        <div class="output">${data.output}</div>
        <div class="footer">Saída simulada do PowerShell 7 (Windows PowerShell 5.1)</div>
    </div>
</body>
</html>`;
}

async function main() {
    const all = process.argv.includes('--all');

    if (!fs.existsSync(IMAGES_DIR)) {
        fs.mkdirSync(IMAGES_DIR, { recursive: true });
    }

    const browser = await chromium.launch({ headless: true });
    const context = await browser.newContext({
        viewport: { width: 1440, height: 900 }
    });
    const page = await context.newPage();

    try {
        for (const [scriptName, data] of Object.entries(mockOutputs)) {
            console.log(`Capturando ${scriptName}...`);
            await capturePage(page, scriptName, data);
            const outputPath = path.join(IMAGES_DIR, `${scriptName}.png`);
            await page.screenshot({ path: outputPath, fullPage: true });
            console.log(`Salvo: ${outputPath}`);
        }

        console.log('\nGerando demo.gif...');
        // Create a simple HTML page for the animated demo
        const demoHtml = generateDemoHtml();
        const demoPath = path.join(FILES_DIR, 'demo.html');
        fs.writeFileSync(demoPath, demoHtml);

        // Use ffmpeg to create GIF from a simulated recording
        // Since we can't actually record PowerShell, we create a sequence from the PNGs
        await browser.close();

        console.log('Demo HTML criado:', demoPath);
        console.log('Para criar o GIF, instale ffmpeg e execute manualmente.');

    } finally {
        await browser.close();
    }
}

function generateDemoHtml() {
    const sections = Object.entries(mockOutputs).map(([name, data]) => `
    <div class="section">
        <h2>PS> .\\scripts\\${name}.ps1</h2>
        <div class="output">${data.output.replace(/\t/g, '&nbsp;&nbsp;')}</div>
    </div>`).join('');

    return `
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kit Suporte PowerShell - Demo</title>
    <style>
        body {
            font-family: 'Cascadia Code', monospace;
            background: #0d1117;
            color: #e6edf3;
            padding: 20px;
            line-height: 1.6;
        }
        .header {
            color: #58a6ff;
            margin-bottom: 30px;
        }
        .section {
            margin-bottom: 30px;
            padding: 20px;
            background: #161b22;
            border-radius: 8px;
            border: 1px solid #30363d;
        }
        .section h2 {
            color: #7ee787;
            margin-bottom: 12px;
        }
        .output {
            background: #0d1117;
            padding: 16px;
            border-radius: 6px;
            font-size: 14px;
            white-space: pre-wrap;
            overflow-x: auto;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Kit de Suporte PowerShell - Demonstração</h1>
    </div>
    ${sections}
</body>
</html>`;
}

main().catch(console.error);