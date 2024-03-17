# Перевірка, чи запущено скрипт від адміна
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



# Шляхи до папок
$pathCMS = "C:\Program Files (x86)\CMS\"
$pathPolyvision = "C:\Program Files (x86)\Polyvision\CMS\"

# Перевіряємо наявність програм
$isCMSInstalled = $false
$isPolyvisionInstalled = $false
$actualProgram;

# Актуальний шлях до актуальної програми
$actualPath;



# Перевіряємо наявність ЦМСа
if (Test-Path $pathCMS -PathType Container) {
    Write-Host ">> Found CMS"  -ForegroundColor Green
    $isCMSInstalled = $true;
    $actualProgram = "CMS";
}

# Перевіряємо наявність Полівіжн/ЦМСа
if (Test-Path $pathPolyvision -PathType Container) {
    Write-Host ">> Found Polyvision/CMS"  -ForegroundColor Green
    $isPolyvisionInstalled = $true;
    $actualProgram = "Polyvision/CMS";
} 



# Перевіряємо, яка з програм встановлена
if ($isCMSInstalled -and -not $isPolyvisionInstalled) {
    # Якщо встановлений тільки ЦМС, встановлюємо його шлях як актуальний
    $actualPath = $pathCMS
    
} elseif (-not $isCMSInstalled -and $isPolyvisionInstalled) {
    # Якщо встановлений тільки Полівіжн/ЦМС, встановлюємо його шлях як актуальний
    $actualPath = $pathPolyvision
} elseif (-not $isCMSInstalled -and -not $isPolyvisionInstalled) {
    # Якщо не встановлено нічого - виводимо помилку
    Write-Host ">> No CMS or Polyvision/CMS found! Exiting the script."  -ForegroundColor Red
    Pause
    Exit
} elseif ($isCMSInstalled -and $isPolyvisionInstalled) {
    # Якщо встановлені обидві - виводимо помилку
    Write-Host ">> Both CMS and Polyvision/CMS found! Remove one of them and rerun the script. Exiting the script."  -ForegroundColor Red
    Pause
    Exit
}



# Перевірка існування bat-файлу перед його створенням
$batFilePath = $actualPath + 'CMS.bat'
if (Test-Path $batFilePath -PathType Leaf) {
    Write-Host ">> Bat-file is already exist. Remove it and rerun the script. Exiting the script."  -ForegroundColor Red
    Pause
    Exit
}
 
# Актуальний код для батніка
$code = 'cmd /min /C "set __COMPAT_LAYER=RUNASINVOKER && start "" "' + $actualPath + 'CMS.exe""'



# Створюємо файл
Set-Content -Path $batFilePath -Value $code
Write-Host ">> File created" -ForegroundColor Yellow



# Створення ярлика
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

# Шлях для збереження ярлика на робочому столі
$shortcutPath = "C:\Users\kassir\Desktop\КАМЕРЫ.lnk"

# Шлях до іконки
$iconPath = (Get-Item -Path ".\cms.ico").FullName

# URl іконки
$iconURLOldCMS = "https://raw.githubusercontent.com/maxraimer/cmsbat/main/cms_old.ico"
$iconURLNewCMS = "https://raw.githubusercontent.com/maxraimer/cmsbat/main/cms_new.ico"

# Шлях збереження іконки
$iconPath = "C:\Users\kassir\Downloads\cms.ico"

# Завантаження іконки з GitHub відповідно до того, яка програма встановлена
if ($actualProgram -eq "CMS") {
    Invoke-WebRequest -Uri $iconURLOldCMS -OutFile $iconPath
} elseif ($actualProgram -eq "Polyvision/CMS") {
    Invoke-WebRequest -Uri $iconURLNewCMS -OutFile $iconPath
}

# Створення ярлика
CreateShortcut -TargetPath $batFilePath -ShortcutPath $shortcutPath -IconPath $iconPath

Write-Host ">> Shortcut created on the Desktop." -ForegroundColor Yellow

Write-Host ">> DONE!" -ForegroundColor Green

Pause
Exit