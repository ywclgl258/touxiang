@echo off
chcp 65001 >nul
cd /d "%~dp0"
setlocal

title PNG to JPG Recursive

echo Preparing...
echo This script will convert PNG files in current folder and all subfolders.
echo JPG quality: 80
echo PNG files will be deleted only after JPG is saved successfully.
echo Log file: png_to_jpg_log.txt
echo.

set "PS1=%TEMP%\png_to_jpg_convert_%RANDOM%.ps1"

del "%PS1%" 2>nul

> "%PS1%" echo Add-Type -AssemblyName System.Drawing
>> "%PS1%" echo $ErrorActionPreference = 'Continue'
>> "%PS1%" echo $root = (Get-Location).ProviderPath
>> "%PS1%" echo $log = Join-Path $root 'png_to_jpg_log.txt'
>> "%PS1%" echo Set-Content -LiteralPath $log -Value ('Start: ' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) -Encoding UTF8
>> "%PS1%" echo $codec = $null
>> "%PS1%" echo foreach ($enc in [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders()) {
>> "%PS1%" echo     if ($enc.MimeType -eq 'image/jpeg') {
>> "%PS1%" echo         $codec = $enc
>> "%PS1%" echo         break
>> "%PS1%" echo     }
>> "%PS1%" echo }
>> "%PS1%" echo if ($codec -eq $null) {
>> "%PS1%" echo     Add-Content -LiteralPath $log -Value 'ERROR: JPEG codec not found.'
>> "%PS1%" echo     throw 'JPEG codec not found.'
>> "%PS1%" echo }
>> "%PS1%" echo $qualityEncoder = [System.Drawing.Imaging.Encoder]::Quality
>> "%PS1%" echo $encParam = New-Object System.Drawing.Imaging.EncoderParameter($qualityEncoder, 80L)
>> "%PS1%" echo $params = New-Object System.Drawing.Imaging.EncoderParameters(1)
>> "%PS1%" echo $params.Param[0] = $encParam
>> "%PS1%" echo $files = Get-ChildItem -LiteralPath $root -Filter '*.png' -Recurse -ErrorAction SilentlyContinue
>> "%PS1%" echo $count = 0
>> "%PS1%" echo foreach ($file in $files) {
>> "%PS1%" echo     if ($file.PSIsContainer) { continue }
>> "%PS1%" echo     $count = $count + 1
>> "%PS1%" echo     $png = $file.FullName
>> "%PS1%" echo     $jpg = [System.IO.Path]::ChangeExtension($png, '.jpg')
>> "%PS1%" echo     $img = $null
>> "%PS1%" echo     $bmp = $null
>> "%PS1%" echo     $g = $null
>> "%PS1%" echo     try {
>> "%PS1%" echo         Write-Host ('Converting: ' + $png)
>> "%PS1%" echo         Add-Content -LiteralPath $log -Value ('Converting: ' + $png)
>> "%PS1%" echo         $img = [System.Drawing.Image]::FromFile($png)
>> "%PS1%" echo         $bmp = New-Object System.Drawing.Bitmap($img.Width, $img.Height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
>> "%PS1%" echo         $g = [System.Drawing.Graphics]::FromImage($bmp)
>> "%PS1%" echo         $g.Clear([System.Drawing.Color]::White)
>> "%PS1%" echo         $g.DrawImage($img, 0, 0, $img.Width, $img.Height)
>> "%PS1%" echo         $img.Dispose()
>> "%PS1%" echo         $img = $null
>> "%PS1%" echo         if (Test-Path -LiteralPath $jpg) {
>> "%PS1%" echo             Remove-Item -LiteralPath $jpg -Force
>> "%PS1%" echo         }
>> "%PS1%" echo         $bmp.Save($jpg, $codec, $params)
>> "%PS1%" echo         if ($g -ne $null) {
>> "%PS1%" echo             $g.Dispose()
>> "%PS1%" echo             $g = $null
>> "%PS1%" echo         }
>> "%PS1%" echo         if ($bmp -ne $null) {
>> "%PS1%" echo             $bmp.Dispose()
>> "%PS1%" echo             $bmp = $null
>> "%PS1%" echo         }
>> "%PS1%" echo         if (Test-Path -LiteralPath $jpg) {
>> "%PS1%" echo             Remove-Item -LiteralPath $png -Force
>> "%PS1%" echo             Write-Host ('Saved: ' + $jpg)
>> "%PS1%" echo             Add-Content -LiteralPath $log -Value ('Saved: ' + $jpg)
>> "%PS1%" echo         }
>> "%PS1%" echo     } catch {
>> "%PS1%" echo         Write-Host ('FAILED: ' + $png)
>> "%PS1%" echo         Write-Host $_.Exception.Message
>> "%PS1%" echo         Add-Content -LiteralPath $log -Value ('FAILED: ' + $png)
>> "%PS1%" echo         Add-Content -LiteralPath $log -Value ('Reason: ' + $_.Exception.Message)
>> "%PS1%" echo     } finally {
>> "%PS1%" echo         if ($img -ne $null) {
>> "%PS1%" echo             try { $img.Dispose() } catch {}
>> "%PS1%" echo         }
>> "%PS1%" echo         if ($g -ne $null) {
>> "%PS1%" echo             try { $g.Dispose() } catch {}
>> "%PS1%" echo         }
>> "%PS1%" echo         if ($bmp -ne $null) {
>> "%PS1%" echo             try { $bmp.Dispose() } catch {}
>> "%PS1%" echo         }
>> "%PS1%" echo     }
>> "%PS1%" echo }
>> "%PS1%" echo Add-Content -LiteralPath $log -Value ('PNG files found: ' + $count)
>> "%PS1%" echo Add-Content -LiteralPath $log -Value ('End: ' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"

echo.
echo ================================
echo Finished.
echo Check log file:
echo png_to_jpg_log.txt
echo ================================
echo.
pause