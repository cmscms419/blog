# fix-images-all.ps1
# 흩어진 이미지를 attachments/로 모으고 경로 일괄 수정

param(
    [string]$ContentPath = ".\content",
    [string]$AttachFolder = "attachments"
)

$attachDir = Join-Path $ContentPath $AttachFolder
if (-not (Test-Path $attachDir)) {
    New-Item -ItemType Directory -Path $attachDir | Out-Null
    Write-Host "폴더 생성: $attachDir" -ForegroundColor Yellow
}

$imageExts = @("*.png","*.jpg","*.jpeg","*.gif","*.webp","*.svg","*.bmp")

Write-Host ""
Write-Host "[1단계] 이미지 파일 수집 중..." -ForegroundColor Cyan

$images = @{}
foreach ($ext in $imageExts) {
    Get-ChildItem -Path $ContentPath -Recurse -Filter $ext | Where-Object {
        $_.DirectoryName -ne $attachDir
    } | ForEach-Object {
        $dest = Join-Path $attachDir $_.Name

        if (Test-Path $dest) {
            $baseName = $_.BaseName
            $extName = $_.Extension
            $i = 1
            while (Test-Path (Join-Path $attachDir ($baseName + "_" + $i + $extName))) { $i++ }
            $dest = Join-Path $attachDir ($baseName + "_" + $i + $extName)
        }

        Move-Item $_.FullName $dest
        $images[$_.Name] = Split-Path $dest -Leaf
        Write-Host ("  이동: " + $_.FullName + " -> " + $dest) -ForegroundColor Gray
    }
}

Write-Host ("  총 " + $images.Count + " 개 이미지 이동됨") -ForegroundColor Green

Write-Host ""
Write-Host "[2단계] 마크다운 경로 수정 중..." -ForegroundColor Cyan

$mdFiles = Get-ChildItem -Path $ContentPath -Recurse -Filter "*.md"
$mdCount = 0

foreach ($file in $mdFiles) {
    $text = Get-Content $file.FullName -Raw -Encoding UTF8
    if (-not $text) { continue }
    $original = $text

    $text = [regex]::Replace($text,
        '!\[\[([^\]/\\]+\.(png|jpg|jpeg|gif|webp|svg|bmp))\]\]',
        {
            param($m)
            $name = $m.Groups[1].Value
            if ($images.ContainsKey($name)) { $mapped = $images[$name] } else { $mapped = $name }
            return "![$mapped]($AttachFolder/$mapped)"
        }
    )

    $text = [regex]::Replace($text,
        '!\[([^\]]*)\]\((?!attachments/)([^)]+\.(png|jpg|jpeg|gif|webp|svg|bmp))\)',
        {
            param($m)
            $alt  = $m.Groups[1].Value
            $path = $m.Groups[2].Value
            $name = Split-Path $path -Leaf
            if ($images.ContainsKey($name)) { $mapped = $images[$name] } else { $mapped = $name }
            return "![$alt]($AttachFolder/$mapped)"
        }
    )

    if ($text -ne $original) {
        Set-Content $file.FullName $text -Encoding UTF8 -NoNewline
        Write-Host ("  수정됨: " + $file.Name) -ForegroundColor Green
        $mdCount++
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host "완료!" -ForegroundColor Cyan
Write-Host ("  이미지 이동: " + $images.Count + " 개")
Write-Host ("  MD 수정:     " + $mdCount + " 개")
Write-Host "========================================"
Write-Host ""
