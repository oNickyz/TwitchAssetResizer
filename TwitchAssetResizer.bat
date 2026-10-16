@echo off
setlocal
set "TWITCH_SCRIPT=%~f0"
set "TWITCH_INPUT=%~1"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$p=$env:TWITCH_SCRIPT; $raw=[IO.File]::ReadAllText($p); $marker='# --- POWERSHELL SCRIPT ---'; $i=$raw.IndexOf($marker); if($i -lt 0){Write-Host 'Erro: nao foi possivel carregar o script.'; exit 1}; $code=$raw.Substring($i+$marker.Length); $tmp=Join-Path $env:TEMP ('TwitchAssetResizer_'+[guid]::NewGuid().ToString('N')+'.ps1'); [IO.File]::WriteAllText($tmp,$code,[Text.Encoding]::UTF8); try { & $tmp } finally { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }"
pause
exit /b
# --- POWERSHELL SCRIPT ---
$ErrorActionPreference = 'Stop'
$script:GeneratedFiles = @()
$script:MagickPath = $null
$script:SourceImage = $null
$script:InputPath = $null
$script:OutputRoot = $null
$script:BaseName = $null

function Write-Header {
    Clear-Host
    Write-Host ''
    Write-Host '====================================================' -ForegroundColor Magenta
    Write-Host '             TWITCH ASSET RESIZER' -ForegroundColor White
    Write-Host '====================================================' -ForegroundColor Magenta
    Write-Host ''
}

function New-UniqueOutputFolder {
    param([string]$Parent, [string]$Name)
    $candidate = Join-Path $Parent ($Name + '_Twitch_Exports')
    $counter = 2
    while (Test-Path -LiteralPath $candidate) {
        $candidate = Join-Path $Parent ($Name + '_Twitch_Exports_' + $counter)
        $counter++
    }
    New-Item -ItemType Directory -Path $candidate | Out-Null
    return $candidate
}

function Save-Image {
    param(
        [int]$Width,
        [int]$Height,
        [string]$Path,
        [bool]$ExactCanvas = $true,
        [bool]$AllowUpscale = $true
    )

    $source = $script:SourceImage
    $sourcePath = $script:InputPath

    if ($script:MagickPath) {
        if ($ExactCanvas) {
            $geometry = "${Width}x${Height}"
            $outputArgument = 'PNG32:' + $Path
            & $script:MagickPath $sourcePath -auto-orient -alpha on -filter Lanczos -resize $geometry -gravity center -background none -extent $geometry -define png:compression-level=9 $outputArgument
        }
        else {
            $geometry = "${Width}x${Height}"
            $outputArgument = 'PNG32:' + $Path
            if ($AllowUpscale) {
                & $script:MagickPath $sourcePath -auto-orient -alpha on -filter Lanczos -resize $geometry -define png:compression-level=9 $outputArgument
            }
            else {
                & $script:MagickPath $sourcePath -auto-orient -alpha on -filter Lanczos -resize ($geometry + '>') -define png:compression-level=9 $outputArgument
            }
        }
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Path)) {
            throw "O ImageMagick falhou ao criar: $Path"
        }
    }
    else {
        $drawWidth = $Width
        $drawHeight = $Height
        if (-not $ExactCanvas) {
            $scale = [Math]::Min(($Width / [double]$source.Width), ($Height / [double]$source.Height))
            if (-not $AllowUpscale) { $scale = [Math]::Min(1.0, $scale) }
            $drawWidth = [int][Math]::Max(1, [Math]::Round($source.Width * $scale))
            $drawHeight = [int][Math]::Max(1, [Math]::Round($source.Height * $scale))
        }

        $bitmapWidth = $Width
        $bitmapHeight = $Height
        if (-not $ExactCanvas) {
            $bitmapWidth = $drawWidth
            $bitmapHeight = $drawHeight
        }

        $bitmap = [System.Drawing.Bitmap]::new($bitmapWidth, $bitmapHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = $null
        $attributes = $null
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $x = 0
            $y = 0
            if ($ExactCanvas) {
                $scale = [Math]::Min(($Width / [double]$source.Width), ($Height / [double]$source.Height))
                $drawWidth = [int][Math]::Max(1, [Math]::Round($source.Width * $scale))
                $drawHeight = [int][Math]::Max(1, [Math]::Round($source.Height * $scale))
                $x = [int][Math]::Floor(($Width - $drawWidth) / 2.0)
                $y = [int][Math]::Floor(($Height - $drawHeight) / 2.0)
            }
            $destination = [System.Drawing.Rectangle]::new($x, $y, $drawWidth, $drawHeight)
            $attributes = [System.Drawing.Imaging.ImageAttributes]::new()
            $attributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
            $graphics.DrawImage($source, $destination, 0, 0, $source.Width, $source.Height, [System.Drawing.GraphicsUnit]::Pixel, $attributes)
            $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            if ($attributes) { $attributes.Dispose() }
            if ($graphics) { $graphics.Dispose() }
            $bitmap.Dispose()
        }
    }

    $script:GeneratedFiles += $Path
}

function Export-Sizes {
    param(
        [string]$RelativeFolder,
        [int[]]$Dimensions
    )
    $folder = Join-Path $script:OutputRoot $RelativeFolder
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    for ($i = 0; $i -lt $Dimensions.Count; $i += 2) {
        $w = $Dimensions[$i]
        $h = $Dimensions[$i + 1]
        $filename = '{0}_{1}x{2}.png' -f $script:BaseName, $w, $h
        $destination = Join-Path $folder $filename
        Save-Image -Width $w -Height $h -Path $destination -ExactCanvas $true
    }
}

function Export-Panel {
    $folder = Join-Path $script:OutputRoot 'Paineis_de_Informacoes'
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    $source = $script:SourceImage
    $scale = [Math]::Min((320 / [double]$source.Width), (600 / [double]$source.Height))
    $scale = [Math]::Min(1.0, $scale)
    $w = [int][Math]::Max(1, [Math]::Round($source.Width * $scale))
    $h = [int][Math]::Max(1, [Math]::Round($source.Height * $scale))
    $filename = '{0}_Painel_{1}x{2}.png' -f $script:BaseName, $w, $h
    $destination = Join-Path $folder $filename
    Save-Image -Width 320 -Height 600 -Path $destination -ExactCanvas $false -AllowUpscale $false
}

function Export-ProfileBanner {
    Export-Sizes -RelativeFolder 'Banner_do_Perfil' -Dimensions @(1200,480)
}

function Export-OfflineBanner {
    Export-Sizes -RelativeFolder 'Banner_do_Player_Offline' -Dimensions @(1920,1080)
}

function Export-FullPackage {
    Export-Sizes -RelativeFolder 'Distintivos_18_36_72' -Dimensions @(18,18,36,36,72,72)
    Export-Sizes -RelativeFolder 'Emotes_e_Cheermotes_28_56_112' -Dimensions @(28,28,56,56,112,112)
    Export-Sizes -RelativeFolder 'Pontos_do_Canal_28_56_112' -Dimensions @(28,28,56,56,112,112)
    Export-Sizes -RelativeFolder 'Foto_de_Perfil' -Dimensions @(256,256)
    Export-ProfileBanner
    Export-OfflineBanner
    Export-Panel
}

try {
    Add-Type -AssemblyName System.Drawing
    Write-Header

    $inputPath = $env:TWITCH_INPUT
    if ([string]::IsNullOrWhiteSpace($inputPath)) {
        Write-Host 'Nenhum PNG foi arrastado para cima do arquivo .bat.' -ForegroundColor Yellow
        $inputPath = Read-Host 'Arraste um PNG para esta janela (ou digite o caminho completo) e pressione ENTER'
    }
    $inputPath = $inputPath.Trim().Trim('"').Trim("'")
    if ([string]::IsNullOrWhiteSpace($inputPath)) { throw 'Nenhum arquivo foi informado.' }
    if (-not (Test-Path -LiteralPath $inputPath -PathType Leaf)) { throw "Arquivo nao encontrado: $inputPath" }
    if ([IO.Path]::GetExtension($inputPath).ToLowerInvariant() -ne '.png') { throw 'O arquivo precisa estar no formato PNG.' }
    $script:InputPath = [IO.Path]::GetFullPath($inputPath)
    $script:BaseName = [IO.Path]::GetFileNameWithoutExtension($script:InputPath)
    $parent = Split-Path -LiteralPath $script:InputPath -Parent
    $script:OutputRoot = New-UniqueOutputFolder -Parent $parent -Name $script:BaseName
    $script:SourceImage = [System.Drawing.Image]::FromFile($script:InputPath)

    $magick = Get-Command magick -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($magick -and $magick.Source) {
        $script:MagickPath = $magick.Source
        Write-Host 'Motor: ImageMagick + filtro Lanczos (alta qualidade).' -ForegroundColor Green
    }
    else {
        Write-Host 'Motor: GDI+ HighQualityBicubic (integrado ao Windows).' -ForegroundColor DarkCyan
        Write-Host 'Dica: se o ImageMagick estiver instalado, o script usa Lanczos automaticamente.' -ForegroundColor DarkGray
    }
    Write-Host ('Imagem original: {0}x{1}' -f $script:SourceImage.Width, $script:SourceImage.Height)
    Write-Host ('Pasta de saida: {0}' -f $script:OutputRoot)
    Write-Host ''
    Write-Host 'ESCOLHE O TIPO DE ASSET:' -ForegroundColor Cyan
    Write-Host '  1. Distintivos (inscricao, Bits e outros)       18 / 36 / 72 px'
    Write-Host '  2. Emotes e Cheermotes                         28 / 56 / 112 px'
    Write-Host '  3. Pontos do canal / icones de recompensa      28 / 56 / 112 px'
    Write-Host '  4. Foto de perfil                              256 x 256 px'
    Write-Host '  5. Banner do perfil                            1200 x 480 px'
    Write-Host '  6. Banner do player offline                    1920 x 1080 px'
    Write-Host '  7. Painel de informacoes                       max. 320 x 600 px'
    Write-Host '  8. PACOTE COMPLETO (gera todas as categorias)'
    Write-Host ''
    $choice = Read-Host 'Digite 1 a 8'

    switch ($choice) {
        '1' { Export-Sizes -RelativeFolder 'Distintivos' -Dimensions @(18,18,36,36,72,72) }
        '2' { Export-Sizes -RelativeFolder 'Emotes_e_Cheermotes' -Dimensions @(28,28,56,56,112,112) }
        '3' { Export-Sizes -RelativeFolder 'Pontos_do_Canal' -Dimensions @(28,28,56,56,112,112) }
        '4' { Export-Sizes -RelativeFolder 'Foto_de_Perfil' -Dimensions @(256,256) }
        '5' { Export-ProfileBanner }
        '6' { Export-OfflineBanner }
        '7' { Export-Panel }
        '8' { Export-FullPackage }
        default { throw 'Opcao invalida. Execute o arquivo novamente e escolha um numero de 1 a 8.' }
    }

    Write-Host ''
    Write-Host 'ARQUIVOS GERADOS:' -ForegroundColor Green
    foreach ($file in $script:GeneratedFiles) {
        $info = Get-Item -LiteralPath $file
        $sizeKB = [Math]::Round($info.Length / 1KB, 1)
        Write-Host ('  {0}  ({1} KB)' -f $info.Name, $sizeKB)
        if ($file -match 'Distintivos' -and $info.Length -gt 25KB) {
            Write-Host '    AVISO: distintivos de inscricao exigem PNG de no maximo 25 KB.' -ForegroundColor Yellow
        }
        if ($file -match 'Paineis_de_Informacoes' -and $info.Length -ge 1MB) {
            Write-Host '    AVISO: a Twitch exige que a imagem do painel fique abaixo de 1 MB.' -ForegroundColor Yellow
        }
        if (($file -match 'Banner_do_Perfil|Banner_do_Player_Offline') -and $info.Length -gt 10MB) {
            Write-Host '    AVISO: confira o limite de 10 MB para banners.' -ForegroundColor Yellow
        }
    }
    Write-Host ''
    Write-Host ('Concluido! {0} arquivo(s) criado(s).' -f $script:GeneratedFiles.Count) -ForegroundColor Green
    Write-Host 'A arte teve a proporcao preservada; quando necessario, foi centralizada em uma tela transparente.' -ForegroundColor Gray
    Write-Host 'Observacao: redimensionar nao cria detalhes que nao existiam na imagem original.' -ForegroundColor Gray
}
catch {
    Write-Host ''
    Write-Host ('ERRO: ' + $_.Exception.Message) -ForegroundColor Red
}
finally {
    if ($script:SourceImage) { $script:SourceImage.Dispose() }
}
