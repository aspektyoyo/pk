# ��������, �� �������� ������ �� �����
function TestAdminRights {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    return $isAdmin
}

if (-not (TestAdminRights)) {
    Write-Host ">> This script must be run as admin." -ForegroundColor Red
    Pause
    Exit
}



# ����� �� �����
$pathCMS = "C:\Program Files (x86)\CMS\"
$pathPolyvision = "C:\Program Files (x86)\Polyvision\CMS\"

# ���������� ��������� �������
$isCMSInstalled = $false
$isPolyvisionInstalled = $false
$actualProgram;

# ���������� ���� �� ��������� ��������
$actualPath;



# ���������� ��������� ����
if (Test-Path $pathCMS -PathType Container) {
    Write-Host ">> Found CMS"  -ForegroundColor Green
    $isCMSInstalled = $true;
    $actualProgram = "CMS";
}

# ���������� ��������� ������/����
if (Test-Path $pathPolyvision -PathType Container) {
    Write-Host ">> Found Polyvision/CMS"  -ForegroundColor Green
    $isPolyvisionInstalled = $true;
    $actualProgram = "Polyvision/CMS";
} 



# ����������, ��� � ������� �����������
if ($isCMSInstalled -and -not $isPolyvisionInstalled) {
    # ���� ������������ ����� ���, ������������ ���� ���� �� ����������
    $actualPath = $pathCMS
    
} elseif (-not $isCMSInstalled -and $isPolyvisionInstalled) {
    # ���� ������������ ����� ������/���, ������������ ���� ���� �� ����������
    $actualPath = $pathPolyvision
} elseif (-not $isCMSInstalled -and -not $isPolyvisionInstalled) {
    # ���� �� ����������� ������ - �������� �������
    Write-Host ">> No CMS or Polyvision/CMS found! Exiting the script."  -ForegroundColor Red
    Pause
    Exit
} elseif ($isCMSInstalled -and $isPolyvisionInstalled) {
    # ���� ����������� ����� - �������� �������
    Write-Host ">> Both CMS and Polyvision/CMS found! Remove one of them and rerun the script. Exiting the script."  -ForegroundColor Red
    Pause
    Exit
}



# �������� ��������� bat-����� ����� ���� ����������
$batFilePath = $actualPath + 'CMS.bat'
if (Test-Path $batFilePath -PathType Leaf) {
    Write-Host ">> Bat-file is already exist. Remove it and rerun the script. Exiting the script."  -ForegroundColor Red
    Pause
    Exit
}
 
# ���������� ��� ��� �������
$code = 'cmd /min /C "set __COMPAT_LAYER=RUNASINVOKER && start "" "' + $actualPath + 'CMS.exe""'



# ��������� ����
Set-Content -Path $batFilePath -Value $code
Write-Host ">> File created" -ForegroundColor Yellow



# ��������� ������
function CreateShortcut {
    param (
        [string]$TargetPath,
        [string]$ShortcutPath,
        [string]$IconPath
    )

    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $TargetPath
    $Shortcut.IconLocation = $IconPath
    $Shortcut.Save()
}

# ���� ��� ���������� ������ �� �������� ����
$shortcutPath = "C:\Users\kassir\Desktop\������.lnk"

# ���� �� ������
$iconPath = (Get-Item -Path ".\cms.ico").FullName

# URl ������
$iconURLOldCMS = "https://raw.githubusercontent.com/maxraimer/cmsbat/main/cms_old.ico"
$iconURLNewCMS = "https://raw.githubusercontent.com/maxraimer/cmsbat/main/cms_new.ico"

# ���� ���������� ������
$iconPath = "C:\Users\kassir\Downloads\cms.ico"

# ������������ ������ � GitHub �������� �� ����, ��� �������� �����������
if ($actualProgram -eq "CMS") {
    Invoke-WebRequest -Uri $iconURLOldCMS -OutFile $iconPath
} elseif ($actualProgram -eq "Polyvision/CMS") {
    Invoke-WebRequest -Uri $iconURLNewCMS -OutFile $iconPath
}

# ��������� ������
CreateShortcut -TargetPath $batFilePath -ShortcutPath $shortcutPath -IconPath $iconPath

Write-Host ">> Shortcut created on the Desktop." -ForegroundColor Yellow

Write-Host ">> DONE!" -ForegroundColor Green

Pause
Exit