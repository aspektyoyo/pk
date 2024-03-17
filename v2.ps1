Get-Process -Name "PC_EKKA" | Stop-Process -Force
Start-Sleep -Seconds 1
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut([System.IO.Path]::Combine($env:APPDATA, 'Microsoft\Windows\Start Menu\Programs\Startup\XAMPP Control.lnk'))
$shortcut.TargetPath = 'C:\xampp\xampp-control.exe'
$shortcut.Save()
Start-Sleep -Seconds 1
Copy-Item -Path "C:\xampp\xampp-control.ini" -Destination "C:\xampp\xampp-control_backup.ini" -Force
Start-Sleep -Seconds 1
$pathToIniFile = "C:\xampp\xampp-control.ini"
$currentContent = Get-Content -Path $pathToIniFile
if (-not ($currentContent -match '^\[Autostart\]')) {
    $currentContent += "[Autostart]"
    $currentContent += "Apache=1"
    $currentContent += "MySQL=1"

} else {
    $currentContent = $currentContent -replace '^(Apache=0)', 'Apache=1' -replace '^(MySQL=0)', 'MySQL=1'
}

Set-Content -Path $pathToIniFile -Value $currentContent
Start-Sleep -Seconds 1
Start-Process "C:\xampp\xampp-control.exe"
Start-Sleep -Seconds 1
exit