# ============================================================================
# CMS Setup Script
# ============================================================================

function Test-AdminRights {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-AdminRights)) {
    Write-Host "  ✗  Запустите скрипт от имени администратора." -ForegroundColor Red
    Pause
    exit 1
}

# ============================================================================
# КОНФИГУРАЦИЯ
# ============================================================================
$CMS_PATH    = "C:\Program Files (x86)\Polyvision\CMS"
$SETUP_URL   = "https://github.com/aspektyoyo/pk/raw/main/Setup.exe"
$ICON_URL    = "https://raw.githubusercontent.com/aspektyoyo/pk/refs/heads/main/camera.ico"

$DOWNLOADS_DIR = "C:\Users\kassir\Downloads"
$DESKTOP_DIR   = "C:\Users\kassir\Desktop"
$PUBLIC_DESKTOP = "C:\Users\Public\Desktop"

$SETUP_FILE    = Join-Path $DOWNLOADS_DIR "Setup.exe"
$ICON_FILE     = Join-Path $DOWNLOADS_DIR "camera.ico"
$BAT_FILE      = Join-Path $CMS_PATH "CMS.bat"
$SHORTCUT_FILE = Join-Path $DESKTOP_DIR "КАМЕРЫ.lnk"

$XML_DIR       = Join-Path $CMS_PATH "XML"
$D_DRIVE_DEST  = "D:\"
$FILES_TO_COPY = @("Data.xml", "DevGroup.xml", "PlanTemplate.xml", "users.xml")

# ============================================================================
# ФУНКЦИИ
# ============================================================================

function Write-Status {
    param(
        [string]$Icon,
        [string]$Label,
        [string]$Value = "",
        [string]$Color = "Gray"
    )
    $line = "  $Icon  $Label"
    if ($Value) { $line += "  $Value" }
    Write-Host $line -ForegroundColor $Color
}

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
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
        Invoke-WebRequest -Uri $URL -OutFile $OutFile -ErrorAction Stop
        return $true
    }
    catch {
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
        if ($IconPath -and $IconPath -ne "") {
            $Shortcut.IconLocation = $IconPath
        }
        $Shortcut.Save()
        return $true
    }
    catch {
        return $false
    }
}

function Remove-AllShortcuts {
    $shortcuts = @(
        "$DESKTOP_DIR\CMS.lnk",
        "$DESKTOP_DIR\CMS.exe - Shortcut.lnk",
        "$DESKTOP_DIR\КАМЕРЫ.lnk",
        "$PUBLIC_DESKTOP\CMS.lnk",
        "$PUBLIC_DESKTOP\CMS.exe - Shortcut.lnk",
        "$PUBLIC_DESKTOP\КАМЕРЫ.lnk"
    )
    foreach ($lnk in $shortcuts) {
        if (Test-Path $lnk) {
            Remove-Item $lnk -Force -ErrorAction SilentlyContinue
        }
    }
}

function Reset-IconCache {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Shell32 {
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);
}
"@ -ErrorAction SilentlyContinue
    try {
        [Shell32]::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero)
    } catch { }
}

function Copy-XMLToIntermediate {
    param(
        [string]$SourceFolder,
        [string]$DestinationFolder,
        [string[]]$FilesToCopy
    )
    $dataXmlFound = $false
    
    if (-not (Test-Path $SourceFolder -PathType Container)) {
        return $false
    }
    
    Ensure-Directory $DestinationFolder
    
    foreach ($file in $FilesToCopy) {
        $sourceFile = Join-Path $SourceFolder $file
        if (Test-Path $sourceFile) {
            try {
                Copy-Item -Path $sourceFile -Destination $DestinationFolder -Force -ErrorAction Stop
                if ($file -eq "Data.xml") { $dataXmlFound = $true }
            }
            catch { }
        }
    }
    
    return $dataXmlFound
}

# ============================================================================
# ШАПКА
# ============================================================================

Write-Host ""
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "          CMS Setup" -ForegroundColor Cyan
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

# ============================================================================
# ШАГ 1: Поиск и сохранение конфигурации на D:\
# ============================================================================

$configFound = $false
$configSource = ""

# Локальный поиск - Polyvision
$localFolderPathPolyvision = "C:\Program Files (x86)\Polyvision\CMS\XML"
if (Copy-XMLToIntermediate -SourceFolder $localFolderPathPolyvision -DestinationFolder $D_DRIVE_DEST -FilesToCopy $FILES_TO_COPY) {
    $configFound = $true
    $configSource = "локально (Polyvision)"
}

# Локальный поиск - CMS
if (-not $configFound) {
    $localFolderPathCMS = "C:\Program Files (x86)\CMS\XML"
    if (Copy-XMLToIntermediate -SourceFolder $localFolderPathCMS -DestinationFolder $D_DRIVE_DEST -FilesToCopy $FILES_TO_COPY) {
        $configFound = $true
        $configSource = "локально (CMS)"
    }
}

# Сетевой поиск
if (-not $configFound) {
    $ipAddresses = Get-NetNeighbor -State Reachable,Stale,Delay,Probe -ErrorAction SilentlyContinue |
                   Where-Object { $_.IPAddress -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$' } |
                   Select-Object -ExpandProperty IPAddress -Unique

    foreach ($ip in $ipAddresses) {
        try {
            # Сетевой поиск - Polyvision
            $remoteFolderPathPolyvision = "\\$ip\C`$\Program Files (x86)\Polyvision\CMS\XML"
            if (Copy-XMLToIntermediate -SourceFolder $remoteFolderPathPolyvision -DestinationFolder $D_DRIVE_DEST -FilesToCopy $FILES_TO_COPY) {
                $configFound = $true
                $configSource = "по сети ($ip) - Polyvision"
                break
            }
            
            # Сетевой поиск - CMS
            $remoteFolderPathCMS = "\\$ip\C`$\Program Files (x86)\CMS\XML"
            if (Copy-XMLToIntermediate -SourceFolder $remoteFolderPathCMS -DestinationFolder $D_DRIVE_DEST -FilesToCopy $FILES_TO_COPY) {
                $configFound = $true
                $configSource = "по сети ($ip) - CMS"
                break
            }
        }
        catch { }
    }
}

if ($configFound) {
    Write-Status "✓" "Конфигурация" "найдена $configSource" "Green"
    Write-Status "✓" "Сохранена на" "D:\" "Cyan"
} else {
    Write-Status "✗" "Конфигурация" "не найдена" "Red"
}

Write-Host "  ─────────────────────────────" -ForegroundColor DarkGray

# ============================================================================
# ШАГ 2: Удаление старых папок CMS
# ============================================================================

$PATHS_TO_DELETE = @(
    "C:\Program Files (x86)\Polyvision",
    "C:\Program Files (x86)\CMS"
)

foreach ($folder in $PATHS_TO_DELETE) {
    if (Test-Path $folder -PathType Container) {
        try {
            Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
        }
        catch {
            Write-Host ""
            Write-Status "✗" "Не удалось удалить $folder" "" "Red"
            Write-Status "  " $_.Exception.Message "" "DarkGray"
            Write-Host ""
            Pause
            exit 1
        }
    }
}

# ============================================================================
# ШАГ 3: Загрузка и установка CMS
# ============================================================================

if (-not (Download-File -URL $SETUP_URL -OutFile $SETUP_FILE -Description "Setup.exe")) {
    Write-Host ""
    Write-Status "✗" "Не удалось скачать установщик" "" "Red"
    Write-Host ""
    Pause
    exit 1
}

try {
    $proc = Start-Process -FilePath $SETUP_FILE -ArgumentList "/SILENT" -Wait -PassThru -WindowStyle Hidden
    if ($proc.ExitCode -ne 0) {
        Write-Host ""
        Write-Status "✗" "Установщик завершился с ошибкой" "код $($proc.ExitCode)" "Red"
        Write-Host ""
        Pause
        exit 1
    }
}
catch {
    Write-Host ""
    Write-Status "✗" "Ошибка запуска установщика" "" "Red"
    Write-Host ""
    Pause
    exit 1
}

if (-not (Test-Path $CMS_PATH -PathType Container)) {
    Write-Host ""
    Write-Status "✗" "Папка CMS не найдена после установки" "" "Red"
    Write-Host ""
    Pause
    exit 1
}

Ensure-Directory $XML_DIR

Write-Status "✓" "CMS установлена" "" "Green"

# ============================================================================
# ШАГ 4: Применение конфигурации из D:\ в XML_DIR
# ============================================================================

$localDestination = "C:\Program Files (x86)\Polyvision\CMS\XML"
if (Test-Path "D:\Data.xml") {
    foreach ($file in $FILES_TO_COPY) {
        $intermediateFile = "D:\$file"
        if (Test-Path $intermediateFile) {
            Copy-Item -Path $intermediateFile -Destination $localDestination -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Status "✓" "Конфигурация применена" "" "Green"
}

# ============================================================================
# ШАГ 5: BAT-файл
# ============================================================================

$batContent = "cmd /min /C `"set __COMPAT_LAYER=RUNASINVOKER && start `"`" `"$CMS_PATH\CMS.exe`"`""
Set-Content -Path $BAT_FILE -Value $batContent -Force
Write-Status "✓" "BAT-файл создан" "" "Green"

# ============================================================================
# ШАГ 6: Загрузка иконки
# ============================================================================

if (Test-Path $ICON_FILE) {
    Remove-Item $ICON_FILE -Force -ErrorAction SilentlyContinue
}

$iconExists = Download-File -URL $ICON_URL -OutFile $ICON_FILE -Description "camera.ico"

# ============================================================================
# ШАГ 7: Удаление всех ярлыков + сброс кэша иконок
# ============================================================================

Remove-AllShortcuts
Reset-IconCache

# ============================================================================
# ШАГ 8: Создание ярлыка КАМЕРЫ
# ============================================================================

if ($iconExists -and (Test-Path $ICON_FILE)) {
    $iconParam = "$ICON_FILE,0"
} else {
    $iconParam = ""
}

Create-Shortcut -TargetPath $BAT_FILE -ShortcutPath $SHORTCUT_FILE -IconPath $iconParam | Out-Null
Write-Status "✓" "Ярлык КАМЕРЫ.lnk" "создан" "Green"

# ============================================================================
# ГОТОВО
# ============================================================================

Write-Host ""
Write-Host "  ✓  ЗАВЕРШЕНО" -ForegroundColor Green
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

Pause
exit 0
