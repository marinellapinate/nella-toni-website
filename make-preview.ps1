# Creates preview.jpg — a compressed, web-friendly version of the source photo
# for use as the WhatsApp / LinkedIn link preview image.
# Targets ~1200px on the longest side, JPEG quality 75, which keeps it well under 300 KB.

param(
    [string]$Source = "MARIANELLA&TONY16.jpg",
    [string]$Output = "preview.jpg",
    [int]$MaxSide  = 1200,
    [int]$Quality  = 75
)

Add-Type -AssemblyName System.Drawing

$srcPath = Join-Path $PSScriptRoot $Source
$outPath = Join-Path $PSScriptRoot $Output

if (-not (Test-Path $srcPath)) {
    Write-Error "Source not found: $srcPath"
    exit 1
}

$img = [System.Drawing.Image]::FromFile($srcPath)

# Compute new size, preserving aspect ratio
if ($img.Width -ge $img.Height) {
    $newW = $MaxSide
    $newH = [int]([math]::Round($img.Height * ($MaxSide / $img.Width)))
} else {
    $newH = $MaxSide
    $newW = [int]([math]::Round($img.Width * ($MaxSide / $img.Height)))
}

$bmp = New-Object System.Drawing.Bitmap $newW, $newH
$g   = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.DrawImage($img, 0, 0, $newW, $newH)

# JPEG encoder with quality setting
$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
    Where-Object { $_.MimeType -eq 'image/jpeg' }
$encParams = New-Object System.Drawing.Imaging.EncoderParameters 1
$encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter (
    [System.Drawing.Imaging.Encoder]::Quality, [long]$Quality
)

$bmp.Save($outPath, $jpegCodec, $encParams)

$g.Dispose(); $bmp.Dispose(); $img.Dispose()

$kb = [math]::Round((Get-Item $outPath).Length / 1KB, 1)
Write-Host "Created $Output  ($newW x $newH, ${kb} KB)"
