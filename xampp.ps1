$filePath = "C:\xampp\xampp-control.ini"

# Изменение прав доступа
$acl = Get-Acl $filePath

$permission = [System.Security.AccessControl.FileSystemRights]::FullControl
$inheritance = [System.Security.AccessControl.InheritanceFlags]::None
$propagation = [System.Security.AccessControl.PropagationFlags]::None
$accessControlType = [System.Security.AccessControl.AccessControlType]::Allow

$sid = New-Object System.Security.Principal.SecurityIdentifier "S-1-1-0" 

$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($sid, $permission, $inheritance, $propagation, $accessControlType)
$acl.SetAccessRule($accessRule)
Set-Acl $filePath $acl


$taskName = "XAMPPControlLogon"
$taskDescription = "Launch XAMPP Control Panel at user logon"
$exePath = "C:\xampp\xampp-control.exe"

# Создание действия для задачи
$action = New-ScheduledTaskAction -Execute $exePath

# Создание триггера для выполнения задачи при входе в систему
$trigger = New-ScheduledTaskTrigger -AtLogon

# Удаление существующей задачи, если она есть
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}


Register-ScheduledTask -TaskName $taskName -Description $taskDescription -Action $action -Trigger $trigger -RunLevel Highest

Write-Host "Scheduled task created: $taskName"



$shell = New-Object -ComObject WScript.Shell
$shortcutPath = [System.IO.Path]::Combine([Environment]::GetFolderPath('Desktop'), 'XAMPP Control Panel.lnk')
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $exePath
$shortcut.Save()

Start-Sleep -Seconds 1

Copy-Item -Path $filePath -Destination "C:\xampp\xampp-control_backup.ini" -Force
Start-Sleep -Seconds 1

$pathToIniFile = "C:\xampp\xampp-control.ini"
$currentContent = Get-Content -Path $pathToIniFile

if (-not ($currentContent -match '^\[Autostart\]')) {
    $currentContent += "`r`n[Autostart]"
    $currentContent += "Apache=1"
    $currentContent += "MySQL=1"
} else {
    $currentContent = $currentContent -replace '^(Apache=0)', 'Apache=1' -replace '^(MySQL=0)', 'MySQL=1'
}

Set-Content -Path $pathToIniFile -Value $currentContent

Start-Sleep -Seconds 1
Start-Process $exePath

exit
