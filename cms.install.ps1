# ============================================================================
# CMS Setup
# ============================================================================

# Проверка прав администратора
function Test-AdminRights {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-AdminRights)) {
    Write-Host ">> Этот скрипт должен быть запущен с правами администратора." -ForegroundColor Red
    Pause
    exit 1
}

# ============================================================================
# КОНФИГУРАЦИЯ
# ============================================================================
$CMS_PATH = "C:\Program Files (x86)\Polyvision\CMS"
$SETUP_URL = "https://github.com/aspektyoyo/pk/raw/main/Setup.exe"
$ICON_URL = "https://raw.githubusercontent.com/aspektyoyo/pk/refs/heads/main/camera.ico"

$DOWNLOADS_DIR = "C:\Users\kassir\Downloads"
$DESKTOP_DIR = "C:\Users\kassir\Desktop"

$SETUP_FILE = Join-Path $DOWNLOADS_DIR "Setup.exe"
$ICON_FILE = Join-Path $DOWNLOADS_DIR "camera.ico"
$BAT_FILE = Join-Path $CMS_PATH "CMS.bat"
$SHORTCUT_FILE = Join-Path $DESKTOP_DIR "КАМЕРЫ.lnk"

$XML_DIR = Join-Path $CMS_PATH "XML"
$FILES_TO_COPY = @("Data.xml", "DevGroup.xml", "PlanTemplate.xml", "users.xml")

# ============================================================================
# ФУНКЦИИ
# ============================================================================

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "✓ Создана папка: $Path" -ForegroundColor Gray
    }
}

function Download-File {
    param(
        [string]$URL,
        [string]$OutFile,
        [string]$Description
    )
    
    try {
        Ensure-Directory (Split-Path $OutFile)
        Write-Host "⇓ Загрузка $Description..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $URL -OutFile $OutFile -ErrorAction Stop
        Write-Host "✓ $Description загружен" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Ошибка загрузки $Description : $($_)" -ForegroundColor Yellow
        return $false
    }
}

function Create-Shortcut {
    param(
        [string]$TargetPath,
        [string]$ShortcutPath,
        [string]$IconPath = ""
    )
    
    try {
        Ensure-Directory (Split-Path $ShortcutPath)
        
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = $TargetPath
        
        if ($IconPath -and (Test-Path $IconPath)) {
            $Shortcut.IconLocation = $IconPath
        }
        
        $Shortcut.Save()
        Write-Host "✓ Ярлык создан: $ShortcutPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Ошибка создания ярлыка: $($_)" -ForegroundColor Red
        return $false
    }
}

function Copy-XMLFromPaths {
    param([string[]]$Paths)
    $successCount = 0
    foreach ($path in $Paths) {
        if (Test-Path $path -PathType Container) {
            foreach ($file in $FILES_TO_COPY) {
                $srcFile = Join-Path $path $file
                if (Test-Path $srcFile) {
                    try {
                        Copy-Item -Path $srcFile -Destination "D:\" -Force -ErrorAction Stop
                        $successCount++
                    }
                    catch { }
                }
            }
        }
    }
    return $successCount -gt 0
}

# ============================================================================
# ОСНОВНОЙ ПРОЦЕСС
# ============================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "    CMS Setup - Запуск" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ШАГ 1: Поиск файлов конфигурации (локально + по сети) и сохранение на D:\
Write-Host "Поиск файлов конфигурации..." -ForegroundColor Cyan
$configFound = $false

$localPaths = @(
    "C:\Program Files (x86)\Polyvision\CMS\XML",
    "C:\Program Files (x86)\CMS\XML"
)
if (Copy-XMLFromPaths -Paths $localPaths) {
    Write-Host "✓ Файлы конфигурации найдены локально и скопированы на D:\" -ForegroundColor Green
    $configFound = $true
}

if (-not $configFound) {
    $ipAddresses = Get-NetNeighbor -State Reachable,Stale,Delay,Probe -ErrorAction SilentlyContinue |
                   Where-Object { $_.IPAddress -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$' } |
                   Select-Object -ExpandProperty IPAddress -Unique

    foreach ($ip in $ipAddresses) {
        try {
            $remotePaths = @(
                "\\$ip\C`$\Program Files (x86)\Polyvision\CMS\XML",
                "\\$ip\C`$\Program Files (x86)\CMS\XML"
            )
            if (Copy-XMLFromPaths -Paths $remotePaths) {
                Write-Host "✓ Файлы конфигурации найдены по сети и скопированы на D:\" -ForegroundColor Green
                $configFound = $true
                break
            }
        }
        catch { }
    }
}

if (-not $configFound) {
    Write-Host "✗ Не удалось найти файлы конфигурации" -ForegroundColor Red
}

# Проверка и установка CMS
Write-Host "Проверка наличия старых папок CMS..." -ForegroundColor Cyan
$PATHS_TO_DELETE = @(
    "C:\Program Files (x86)\Polyvision",
    "C:\Program Files (x86)\CMS"
)

foreach ($folder in $PATHS_TO_DELETE) {
    if (Test-Path $folder -PathType Container) {
        Write-Host "✓ Найдена папка: $folder" -ForegroundColor Yellow
        Write-Host "⇓ Удаляем..." -ForegroundColor Cyan
        try {
            Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
            Write-Host "✓ Папка удалена: $folder" -ForegroundColor Green
        }
        catch {
            Write-Host "✗ Ошибка удаления $folder : $($_)" -ForegroundColor Red
            Pause
            exit 1
        }
    } else {
        Write-Host "✓ Не найдена: $folder" -ForegroundColor Gray
    }
}

Write-Host "`nУстановка CMS..." -ForegroundColor Cyan
if (Download-File -URL $SETUP_URL -OutFile $SETUP_FILE -Description "установщик CMS") {
    try {
        $proc = Start-Process -FilePath $SETUP_FILE -ArgumentList "/SILENT" -Wait -PassThru -WindowStyle Hidden
        if ($proc.ExitCode -eq 0) {
            Write-Host "✓ Установка завершена" -ForegroundColor Green
        }
        else {
            Write-Host "✗ Установщик вернул код: $($proc.ExitCode)" -ForegroundColor Red
            Pause
            exit 1
        }
    }
    catch {
        Write-Host "✗ Ошибка запуска установщика: $($_)" -ForegroundColor Red
        Pause
        exit 1
    }
}
else {
    Write-Host "✗ Не удалось скачать установщик. Выход." -ForegroundColor Red
    Pause
    exit 1
}

if (-not (Test-Path $CMS_PATH -PathType Container)) {
    Write-Host "✗ После установки папка CMS не найдена: $CMS_PATH" -ForegroundColor Red
    Pause
    exit 1
}

Ensure-Directory $XML_DIR

# ШАГ 2: Копируем конфиг из D:\ в папку CMS (если он там есть)
$configOnD = $true
foreach ($file in $FILES_TO_COPY) {
    if (-not (Test-Path "D:\$file")) { $configOnD = $false; break }
}
if ($configOnD) {
    foreach ($file in $FILES_TO_COPY) {
        Copy-Item -Path "D:\$file" -Destination $XML_DIR -Force -ErrorAction SilentlyContinue
    }
    Write-Host "✓ Конфигурация применена из D:\" -ForegroundColor Green
}

# Создание BAT-файла
Write-Host "`nСоздание BAT-файла..." -ForegroundColor Cyan
$batContent = "cmd /min /C `"set __COMPAT_LAYER=RUNASINVOKER && start `"`" `"$CMS_PATH\CMS.exe`"`""
Set-Content -Path $BAT_FILE -Value $batContent -Force
Write-Host "✓ BAT-файл создан: $BAT_FILE" -ForegroundColor Green

# Загрузка иконки
Write-Host "`nПолучение иконки..." -ForegroundColor Cyan
$iconExists = Download-File -URL $ICON_URL -OutFile $ICON_FILE -Description "иконки"

# Создание ярлыка
Write-Host "`nСоздание ярлыка..." -ForegroundColor Cyan
$iconParam = if ($iconExists) { $ICON_FILE } else { "" }
Create-Shortcut -TargetPath $BAT_FILE -ShortcutPath $SHORTCUT_FILE -IconPath $iconParam | Out-Null

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "    ✓ ЗАВЕРШЕНО!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Pause
exit 0
