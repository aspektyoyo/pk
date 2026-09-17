# Установка видео в аптеке. Тип регистратора определяется по адресу шлюз + .130:
#   TCP 37777 (Dahua)  -> SmartPSS: тихая установка, без Storage Service, автовход, регистратор, все каналы
#   TCP 34567 (CMS)    -> прежний сценарий CMS
#
# Запуск:
#   irm https://raw.githubusercontent.com/aspektyoyo/pk/main/cms.install.ps1 | iex
#
# Установщик SmartPSS (DH_SmartPSS*.exe, любая версия; проверена V2.02.1.R.180619) должен лежать
# на ПК аптеки: в корне D:\ или в D:\LPROG\Видеонаблюдение. Другой путь:
#   $env:PK_SMARTPSS_INSTALLER = 'E:\soft\DH_SmartPSS....exe'; irm ... | iex
#

& {
    $ErrorActionPreference = 'Stop'
    $ScriptUrl = 'https://raw.githubusercontent.com/aspektyoyo/pk/main/cms.install.ps1'
    $ICON_URL = 'https://raw.githubusercontent.com/aspektyoyo/pk/refs/heads/main/camera.ico'
    $SmartPSSConfigDirectory = 'C:\Users\Public\SmartPSS'
    # Any installer version is allowed; components and config format were inspected only for this build.
    $SmartPSSInstallerName = 'DH_SmartPSS_International_Win32_IS_V2.02.1.R.180619.exe'
    $SmartPSSInstaller = $env:PK_SMARTPSS_INSTALLER
    $RecorderName = 'Видеорегистратор'

    # CMS recorder login. Passwords differ between pharmacies, so several are tried to read the
    # channel count and to pick which credential CMS stores in Data.xml. The cipher is exactly what
    # CMS writes for that password (DecryptStringEX inverts these; verified against a live device).
    # vendor=0 is XM(NETIP), the protocol these recorders use (vendor=2 would be Dahua).
    $CMSRecorderUser = 'admin'
    $CMSRecorderVendor = '0'
    $CMSRecorderCredentials = [ordered]@{
        ''         = '44E4FFB1A5C504A3'
        '23Qwerty' = '2E41A403A3D6D07944E4FFB1A5C504A3'
    }
    # Fallback when the recorder does not answer: most recorders have no password.
    $CMSRecorderPasswordCipher = '44E4FFB1A5C504A3'
    # Testing flag: $env:PK_CMS_FORCE_CREATE=1 skips the search for an existing config and always
    # builds a fresh Data.xml, so the create-from-scratch path can be checked without deleting configs.
    $CMSForceCreate = "$env:PK_CMS_FORCE_CREATE" -in @('1', 'true', 'yes', 'on')

    # Login and Organization must come from the same SmartPSS installation:
    # device credentials are encrypted differently for another local account/ID.
    # BEGIN EMBEDDED TEMPLATES
    $EmbeddedTemplates = @{
        'Login\conf.xml' = 'PD94bWwgdmVyc2lvbj0iMS4wIj8+CjxVc2VySW5mbyB2ZXJzaW9uPSIyLjAiPgoJPEN1ck1heElkIHZhbHVlPSIxIiAvPgoJPFVzZXJzPgoJCTxVc2VyIGlkPSIxIiBuYW1lPSJhZG1pbiIgcHdkPSJFZjJDVjhmWkZoRGtqQmtBdmh4WkZQaEhGVmFXWnF3QVFFaU5Ld1JGamNWWWRmM21YRWpmeUxJNEhiZFNJcllobjl6VHd2RG95Z2ZQalBVcFJJdEJQd3FLa2hXaElnTjYiIHR5cGU9IjAiIHJvbGVJZD0iMSIgZGVzYz0iYWRtaW4gdXNlciIgcmlnaHQ9IjIxNDc0ODM2NDciIENoZWNrPSJnRktQdzZNZnhlVFNIVG1Tb1NzYm52VHFicDZZYzQxODhSV1dDMmdTQ1hsd1NJRnpBYTc3aEZTVjBZQi9PZUZkdlVBUFo1MDhQMHNtc1FucVdmK0trcFBoWGhSRkkyeXEiIC8+Cgk8L1VzZXJzPgo8L1VzZXJJbmZvPgo='
        'Login\role.xml' = 'PD94bWwgdmVyc2lvbj0iMS4wIj8+CjxSb2xlSW5mbyB2ZXJzaW9uPSIxLjAiPgoJPEN1ck1heElkIHZhbHVlPSIxIiAvPgoJPFJvbGVzPgoJCTxSb2xlIGlkPSIxIiBuYW1lPSJhZG1pbiIgdHlwZT0iMCIgZGVzYz0iYWRtaW4gcm9sZSIgcmlnaHQ9IjIxNDc0ODM2NDciIC8+Cgk8L1JvbGVzPgo8L1JvbGVJbmZvPgo='
        'Login\code.dat' = 'JfgHzktaliQOVbszRjmhZ5mjuxE='
        'Login\ClientConfig.xml' = 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPENsaWVudENvbmZpZz4KICAgIDxOb2RlIGlkPSIwIiBjaGVjaz0iZGZqSE5CSHI3SytEUW9uK3FBUE9pSHN2UlRrTEJCZDFDWTEzOFFXRWh3VmcweXNGdXJjbERrNEQreW9RNDZ2ck9QN3g5VHJ0ZmFYcm8yL2Ntb0Ewd2RKWFhPVTFPUXpXIi8+CiAgICA8Tm9kZSBpZD0iMTAiIGNoZWNrPSIwRWZmc294QW1lRGhXRWZWMVJ3Zng3TzV5YnFpdlo3aGdmT0IzaFRMaXM4clFadDBmcXJ3T25ZSS9TZHRFelIxZUVoZGJGVWdicWt6dGhFWlFKa3pNNkxkMUZ3eXJGVWsiLz4KICAgIDxOb2RlIGlkPSIyMCIgY2hlY2s9InB6SnBnOU5WTzhtMWVEanZJaWhwMW5IRkM4NUIwVkNiWkpkWmhMOTMwdHNTT3JhYklNN0tZSFNCeEp4VHArM2R1dEw0KzQrc0krM0pFR2hDcVZYYVJVakZPQ1A3Zk93cCIvPgo8L0NsaWVudENvbmZpZz4K'
        'Login\loginconfig.ini' = 'UW5WSk9LRkovRUtLZmFPRlJBSFo5SHBOc0pnSDBPUnVSeHNXVjdGZzN4ZU1ITGdBU1FmL1hDYnJxLzROanQxZFc1TnpaNXVYSVYwSzFoMDg='
        'Organization\Organization.xml' = 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPE9yZ2FuaXphdGlvbiB2ZXJzaW9uPSIxLjAiPgoJPEdyb3VwPk9yZ2FuaXphdGlvbkdyb3VwLnhtbDwvR3JvdXA+Cgk8UmVnaW9uPk9yZ2FuaXphdGlvblJlZ2lvbi54bWw8L1JlZ2lvbj4KCTxEZXZpY2U+T3JnYW5pemF0aW9uRGV2aWNlLnhtbDwvRGV2aWNlPgoJPENoYW5uZWw+T3JnYW5pemF0aW9uQ2hhbm5lbC54bWw8L0NoYW5uZWw+Cgk8RW1hcD5Pcmdhbml6YXRpb25FbWFwLnhtbDwvRW1hcD4KPC9Pcmdhbml6YXRpb24+Cg=='
        'Organization\OrganizationDevice.xml' = 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPE9yZ2FuaXphdGlvbkRldmljZSB2ZXJzaW9uPSIyLjAiIGlkQ291bnQ9IjEiPgoJPERldmljZSBpZFVuaXF1ZT0iMSIgaWRHcm91cD0iMSIgbmFtZT0i0JLQuNC00LXQvtGA0LXQs9C40YHRgtGA0LDRgtC+0YAiIGRvbWFpbj0iMTkyLjE2OC4xLjEzMCIgcG9ydD0iMzc3NzciIHVzZXJuYW1lPSJXUVNSYm14S2xRUXY4ZzlRVzlLakNRPT0iIHBhc3N3b3JkPSIza0dRNVluR3NOb3NGQytNY2Q4cFp3PT0iIHByb3RvY29sPSIxIiBjb25uZWN0PSIwIiAvPgo8L09yZ2FuaXphdGlvbkRldmljZT4K'
        'Organization\OrganizationGroup.xml' = 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPE9yZ2FuaXphdGlvbkdyb3VwIHZlcnNpb249IjEuMCIgaWRDb3VudD0iMSI+Cgk8R3JvdXAgaWRVbmlxdWU9IjEiIGlkR3JvdXA9Ii0xIiBuYW1lPSLQn9C+INGD0LzQvtC70YfQsNC90LjRjiIgLz4KPC9Pcmdhbml6YXRpb25Hcm91cD4K'
        'Organization\OrganizationRegion.xml' = 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPE9yZ2FuaXphdGlvblJlZ2lvbiB2ZXJzaW9uPSIxLjAiIGlkQ291bnQ9IjEiPgoJPFJlZ2lvbiBpZFVuaXF1ZT0iMSIgaWRSZWdpb249Ii0xIiBuYW1lPSLQoNC10LPQuNC+0L0g0L/QviDRg9C80L7Qu9GH0LDQvdC40Y4iIC8+CjwvT3JnYW5pemF0aW9uUmVnaW9uPgo='
        'Organization\OrganizationChannel.xml' = 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPE9yZ2FuaXphdGlvbkNoYW5uZWwgdmVyc2lvbj0iMS4wIiBpZENvdW50PSIwIiAvPgo='
        'Organization\OrganizationEmap.xml' = 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPE9yZ2FuaXphdGlvbkVtYXAgdmVyc2lvbj0iMS4wIiBpZENvdW50PSIwIiAvPgo='
    }
    # END EMBEDDED TEMPLATES

    # ========================================================================
    # Общие функции
    # ========================================================================

    function Test-AdminRights {
        $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

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
            Invoke-WebRequest -Uri $URL -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
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
            [string]$IconPath = "",
            [string]$WorkingDirectory = ""
        )
        try {
            Ensure-Directory (Split-Path $ShortcutPath)
            $WshShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
            $Shortcut.TargetPath = $TargetPath
            if ($WorkingDirectory) { $Shortcut.WorkingDirectory = $WorkingDirectory }
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
            "C:\Users\kassir\Desktop\CMS.lnk",
            "C:\Users\kassir\Desktop\CMS.exe - Shortcut.lnk",
            "C:\Users\kassir\Desktop\КАМЕРЫ.lnk",
            "C:\Users\Public\Desktop\CMS.lnk",
            "C:\Users\Public\Desktop\CMS.exe - Shortcut.lnk",
            "C:\Users\Public\Desktop\КАМЕРЫ.lnk"
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

    # ========================================================================
    # Определение регистратора
    # ========================================================================

    function Get-RecorderAddress {
        # Windows chooses routes by route metric + interface metric.
        $interfaces = @(Get-NetIPInterface -AddressFamily IPv4 -ErrorAction Stop)
        $candidates = @(foreach ($route in @(Get-NetRoute -AddressFamily IPv4 -DestinationPrefix '0.0.0.0/0' -ErrorAction Stop)) {
            $interface = $interfaces | Where-Object { $_.InterfaceIndex -eq $route.InterfaceIndex -and $_.ConnectionState -eq 'Connected' } | Select-Object -First 1
            if ($null -eq $interface -or $route.NextHop -eq '0.0.0.0') { continue }
            [pscustomobject]@{
                Gateway = [string]$route.NextHop
                Metric = [long]$route.RouteMetric + [long]$interface.InterfaceMetric
            }
        })
        if (-not $candidates.Count) { throw 'Не найден активный IPv4-шлюз.' }
        $bestMetric = ($candidates | Measure-Object -Property Metric -Minimum).Minimum
        $gateways = @($candidates | Where-Object Metric -eq $bestMetric | Select-Object -ExpandProperty Gateway -Unique)
        if ($gateways.Count -ne 1) {
            throw "Несколько равноприоритетных шлюзов: $($gateways -join ', '). Адрес регистратора неоднозначен."
        }
        $address = [System.Net.IPAddress]::Parse($gateways[0])
        if ($address.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
            throw 'Шлюз должен иметь IPv4-адрес.'
        }
        $octets = $address.GetAddressBytes()
        $octets[3] = 130
        [pscustomobject]@{ Gateway = $gateways[0]; Address = ($octets -join '.') }
    }

    function Test-RecorderPort {
        param([string]$Address, [int]$Port, [int]$TimeoutMilliseconds = 1500)
        $client = New-Object System.Net.Sockets.TcpClient
        $pending = $null
        try {
            $pending = $client.BeginConnect($Address, $Port, $null, $null)
            if (-not $pending.AsyncWaitHandle.WaitOne($TimeoutMilliseconds)) { return $false }
            $client.EndConnect($pending)
            return $true
        } catch [System.Net.Sockets.SocketException] {
            return $false
        } finally {
            if ($null -ne $pending) { $pending.AsyncWaitHandle.Close() }
            $client.Close()
        }
    }

    function Get-VideoSystemDetection {
        $recorder = Get-RecorderAddress
        # Default ports identify a candidate, not a verified device model.
        $cmsOpen = Test-RecorderPort -Address $recorder.Address -Port 34567
        $smartOpen = Test-RecorderPort -Address $recorder.Address -Port 37777
        $candidate = 'Unknown'
        $reason = 'Оба порта недоступны: регистратор выключен, недоступен или использует другие порты.'
        if ($cmsOpen -and $smartOpen) {
            $reason = 'Открыты оба порта. Автоматический выбор неоднозначен.'
        } elseif ($cmsOpen) {
            $candidate = 'CMS'; $reason = 'Доступен стандартный TCP-порт CMS.'
        } elseif ($smartOpen) {
            $candidate = 'SmartPSS'; $reason = 'Доступен стандартный TCP-порт Dahua.'
        }
        [pscustomobject]@{
            Gateway = $recorder.Gateway; RecorderAddress = $recorder.Address
            CMSPort34567 = $cmsOpen; SmartPSSPort37777 = $smartOpen
            Candidate = $candidate; Reason = $reason
        }
    }

    # ========================================================================
    # SmartPSS: установка
    # ========================================================================

    function Get-SmartPSSState {
        $roots = @('C:\Program Files (x86)\Smart Professional Surveillance System',
                   'C:\Program Files\Smart Professional Surveillance System')
        $registry = @()
        foreach ($view in @([Microsoft.Win32.RegistryView]::Registry32,
                            [Microsoft.Win32.RegistryView]::Registry64)) {
            $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', $view)
            try {
                foreach ($product in @('SmartPSS', 'PC-NVR', 'PSS')) {
                    $key = $base.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$product")
                    if ($null -eq $key) { continue }
                    try {
                        $directory = [string]$key.GetValue('Directory')
                        $path = [string]$key.GetValue('Path')
                        $registry += [pscustomobject]@{
                            View = [string]$view; Product = $product
                            Directory = $directory; Path = $path
                            Installed = $key.GetValue('Installed')
                        }
                        if ($directory) { $roots += $directory }
                        if ($path) { $roots += $path }
                    } finally { $key.Dispose() }
                }
            } finally { $base.Dispose() }
        }
        $clients = @()
        $storageFiles = @()
        foreach ($root in @($roots | Select-Object -Unique)) {
            foreach ($relative in @('SmartPSS\SmartPSS.exe', 'SmartPSS.exe')) {
                $candidate = Join-Path $root $relative
                if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                    $clients += (Get-Item -LiteralPath $candidate).FullName
                }
            }
            $storage = Join-Path $root 'PC-NVR'
            if (Test-Path -LiteralPath $storage -PathType Container) {
                $storageFiles += @(Get-ChildItem -LiteralPath $storage -File -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName)
            }
        }
        $services = @(Get-CimInstance Win32_Service -ErrorAction Stop |
            Where-Object { $_.PathName -match 'PC-NVR|PCNVR' -or $_.Name -match 'PC.?NVR' } |
            Select-Object Name, PathName, StartMode, State)
        [pscustomobject]@{
            Clients = @($clients | Sort-Object -Unique)
            StorageFiles = @($storageFiles | Sort-Object -Unique)
            StorageServices = $services
            Registry = $registry
        }
    }

    function Test-SmartPSSStoragePresent {
        param([Parameter(Mandatory = $true)]$State)
        $storageFiles = @($State.StorageFiles | Where-Object { $null -ne $_ })
        $storageServices = @($State.StorageServices | Where-Object { $null -ne $_ })
        if ($storageFiles.Count -gt 0 -or $storageServices.Count -gt 0) { return $true }
        $registry = @($State.Registry | Where-Object { $null -ne $_ })
        return @($registry | Where-Object { $_.Product -eq 'PC-NVR' -and $_.Installed -eq 1 }).Count -gt 0
    }

    function Stop-SmartPSSProcesses {
        # Only processes started from the SmartPSS installation (Challenge.exe has a generic name).
        foreach ($process in @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
                    $_.Path -like '*\Smart Professional Surveillance System\*' -or $_.Name -in @('SmartPSS', 'PC-NVR', 'PCNVR', 'DSMessageNotify') })) {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 1
    }

    function Remove-SmartPSSStorageService {
        $ErrorActionPreference = 'Stop'
        if (-not (Test-AdminRights)) { throw 'Удаление Storage Service требует прав администратора.' }
        $state = Get-SmartPSSState
        if (-not (Test-SmartPSSStoragePresent -State $state)) {
            return [pscustomobject]@{ Removed = $false; Paths = @() }
        }
        Stop-SmartPSSProcesses
        foreach ($service in @($state.StorageServices)) {
            if ($service.State -ne 'Stopped') { Stop-Service -Name $service.Name -Force -ErrorAction Stop }
            & sc.exe delete $service.Name | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "Не удалось удалить службу Storage Service: $($service.Name)." }
        }
        $installRoots = @(
            'C:\Program Files (x86)\Smart Professional Surveillance System',
            'C:\Program Files\Smart Professional Surveillance System',
            'C:\Users\Public'
        )
        $paths = @()
        foreach ($root in $installRoots) {
            $path = Join-Path $root 'PC-NVR'
            if (Test-Path -LiteralPath $path -PathType Container) {
                $item = Get-Item -LiteralPath $path -ErrorAction Stop
                if ($item.Name -ne 'PC-NVR') { throw "Небезопасный путь удаления: $path" }
                Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction Stop
                $paths += $item.FullName
            }
        }
        foreach ($view in @([Microsoft.Win32.RegistryView]::Registry32, [Microsoft.Win32.RegistryView]::Registry64)) {
            $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', $view)
            try {
                $keyPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PC-NVR'
                $key = $base.OpenSubKey($keyPath)
                if ($null -ne $key) {
                    $key.Dispose()
                    $base.DeleteSubKeyTree($keyPath)
                }
            } finally { $base.Dispose() }
        }
        if (Test-SmartPSSStoragePresent -State (Get-SmartPSSState)) {
            throw 'Storage Service удалён не полностью.'
        }
        [pscustomobject]@{ Removed = $true; Paths = $paths }
    }

    function Find-SmartPSSInstaller {
        $candidates = @()
        if ($SmartPSSInstaller) { $candidates += $SmartPSSInstaller }
        # Pharmacies keep the installer in the root of D: or in D:\LPROG\Видеонаблюдение.
        $searchRoots = @('D:\', 'D:\LPROG', 'D:\LPROG\Видеонаблюдение')
        foreach ($root in $searchRoots) {
            if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }
            $candidates += @(Get-ChildItem -LiteralPath $root -Filter 'DH_SmartPSS*.exe' -File -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty FullName)
        }
        if ($SmartPSSInstaller -and (Test-Path -LiteralPath $SmartPSSInstaller -PathType Leaf)) {
            return (Get-Item -LiteralPath $SmartPSSInstaller).FullName
        }
        $found = @($candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } | Select-Object -Unique | ForEach-Object { Get-Item -LiteralPath $_ })
        if ($found.Count) {
            # Any version is allowed; prefer the inspected build, otherwise the newest file.
            $known = @($found | Where-Object { $_.Name -eq $SmartPSSInstallerName })
            if ($known.Count) { return $known[0].FullName }
            return ($found | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
        }
        throw "Не найден установщик $SmartPSSInstallerName. Положите его в корень D:\ или в D:\LPROG\Видеонаблюдение и запустите снова."
    }

    function Install-SmartPSS {
        $ErrorActionPreference = 'Stop'
        $installer = Find-SmartPSSInstaller
        Write-Status "•" "Установщик" $installer "Gray"
        if ((Split-Path $installer -Leaf) -ne $SmartPSSInstallerName) {
            Write-Status "!" "Версия установщика не проверялась" "проверьте вход, регистратор и каналы" "Yellow"
        }
        Stop-SmartPSSProcesses
        # NSIS silent mode installs both selected sections; Storage Service is removed afterwards.
        $process = Start-Process -FilePath $installer -ArgumentList '/S' -Wait -PassThru
        if ($process.ExitCode -ne 0) { throw "Установщик SmartPSS завершился с кодом $($process.ExitCode)." }
        $deadline = (Get-Date).AddMinutes(2)
        do {
            $state = Get-SmartPSSState
            if ($state.Clients.Count) { break }
            Start-Sleep -Seconds 2
        } while ((Get-Date) -lt $deadline)
        if ($state.Clients.Count -ne 1) {
            throw "После установки ожидался один SmartPSS.exe, найдено: $($state.Clients.Count)."
        }
        # The installer may start the client or PC-NVR after finishing.
        Start-Sleep -Seconds 3
        Stop-SmartPSSProcesses
        $state.Clients[0]
    }

    # ========================================================================
    # SmartPSS: настройка
    # ========================================================================

    function Read-SmartPSSXml {
        param([string]$Path)
        $file = Get-Item -LiteralPath $Path -ErrorAction Stop
        if ($file.PSIsContainer -or $file.Length -gt 1MB) { throw 'Неожиданный размер файла конфигурации.' }
        $settings = New-Object Xml.XmlReaderSettings
        $settings.DtdProcessing = [Xml.DtdProcessing]::Prohibit
        $settings.XmlResolver = $null
        $reader = $null
        try {
            $reader = [Xml.XmlReader]::Create($file.FullName, $settings)
            $doc = New-Object Xml.XmlDocument
            $doc.XmlResolver = $null
            $doc.Load($reader)
            return ,$doc
        } catch { throw "Не удалось прочитать XML: $($file.Name)." }
        finally { if ($null -ne $reader) { $reader.Dispose() } }
    }

    function Expand-SmartPSSTemplates {
        $required = @('Login\conf.xml', 'Login\role.xml', 'Login\code.dat', 'Login\ClientConfig.xml', 'Login\loginconfig.ini',
                      'Organization\Organization.xml', 'Organization\OrganizationDevice.xml', 'Organization\OrganizationGroup.xml',
                      'Organization\OrganizationRegion.xml', 'Organization\OrganizationChannel.xml', 'Organization\OrganizationEmap.xml')
        foreach ($leaf in $required) {
            if (-not $EmbeddedTemplates.ContainsKey($leaf)) { throw "В скрипт не встроен шаблон $leaf." }
        }
        $root = Join-Path ([IO.Path]::GetTempPath()) ('pk-smartpss-' + [guid]::NewGuid())
        foreach ($leaf in $required) {
            $path = Join-Path $root $leaf
            [IO.Directory]::CreateDirectory((Split-Path $path)) | Out-Null
            [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($EmbeddedTemplates[$leaf]))
        }
        $root
    }

    function Initialize-SmartPSSConfigDirectory {
        param([Parameter(Mandatory = $true)][string]$Client, [Parameter(Mandatory = $true)][string]$ConfigDirectory)
        # SmartPSS copies its defaults to Public on first start; before that only the install dir has them.
        [IO.Directory]::CreateDirectory($ConfigDirectory) | Out-Null
        $settings = Join-Path $ConfigDirectory 'Settings.ini'
        if (-not (Test-Path -LiteralPath $settings -PathType Leaf)) {
            Copy-Item -LiteralPath (Join-Path (Split-Path $Client) 'Settings.ini') -Destination $settings
        }
    }

    function Initialize-SmartPSSLogin {
        param([string]$TemplateDirectory, [string]$ConfigDirectory)
        $ErrorActionPreference = 'Stop'
        if (@(Get-Process -Name SmartPSS -ErrorAction SilentlyContinue).Count) { throw 'Закройте SmartPSS перед настройкой входа.' }
        $files = @('conf.xml','role.xml','code.dat','ClientConfig.xml','loginconfig.ini')
        foreach ($leaf in $files) {
            $item = Get-Item -LiteralPath (Join-Path $TemplateDirectory $leaf)
            if ($item.PSIsContainer -or $item.Length -eq 0 -or $item.Length -gt 1MB) { throw "Некорректный файл шаблона входа: $leaf" }
        }
        $source = Read-SmartPSSXml (Join-Path $TemplateDirectory 'conf.xml')
        $users = @($source.SelectNodes('/UserInfo/Users/User'))
        if ($source.DocumentElement.GetAttribute('version') -ne '2.0' -or $users.Count -ne 1 -or
            $users[0].GetAttribute('name') -ne 'admin' -or [string]::IsNullOrWhiteSpace($users[0].GetAttribute('pwd')) -or
            [string]::IsNullOrWhiteSpace($users[0].GetAttribute('Check'))) { throw 'Шаблон должен содержать настроенного локального администратора SmartPSS 2.02.' }
        $config = Get-Item -LiteralPath $ConfigDirectory
        $targetConf = Join-Path $config.FullName 'conf.xml'
        if (Test-Path -LiteralPath $targetConf) {
            $existing = Read-SmartPSSXml $targetConf
            $existingUsers = @($existing.SelectNodes('/UserInfo/Users/User'))
            if ($existingUsers.Count -ne 1 -or $existingUsers[0].GetAttribute('name') -ne 'admin') { throw 'Существующие локальные пользователи SmartPSS не будут заменены.' }
            if (-not [string]::IsNullOrEmpty($existingUsers[0].GetAttribute('pwd')) -and
                ($existingUsers[0].GetAttribute('pwd') -cne $users[0].GetAttribute('pwd') -or
                 $existingUsers[0].GetAttribute('Check') -cne $users[0].GetAttribute('Check'))) {
                throw 'В SmartPSS уже задан другой локальный пароль (настроен вручную). Замена отменена.'
            }
        }
        $systemPath = Join-Path $config.FullName 'SystemConfig.ini'
        $systemText = if (Test-Path -LiteralPath $systemPath) { [IO.File]::ReadAllText($systemPath) } else { '' }
        $section = [regex]::Match($systemText, '(?ms)^\[NormalConfig\][^\S\r\n]*\r?\n.*?(?=^\[|\z)')
        $sectionText = if ($section.Success) { $section.Value } else { "[NormalConfig]`r`n" }
        foreach ($setting in @(@('IsAutoLoginPSS','1'), @('StartPCNVR','0'), @('FirstInstalled','0'))) {
            $pattern = '(?m)^' + $setting[0] + '=[^\r\n]*'
            $line = $setting[0] + '=' + $setting[1]
            if ([regex]::IsMatch($sectionText, $pattern)) { $sectionText = [regex]::Replace($sectionText, $pattern, $line) }
            else { $sectionText = $sectionText.TrimEnd() + "`r`n$line`r`n" }
        }
        if ($section.Success) { $systemText = $systemText.Remove($section.Index,$section.Length).Insert($section.Index,$sectionText) }
        else { $systemText = $systemText.TrimEnd() + "`r`n" + $sectionText }
        $backup = Join-Path $config.FullName ('pk-login-backup-' + [guid]::NewGuid())
        [IO.Directory]::CreateDirectory($backup) | Out-Null
        $writes = @()
        foreach ($leaf in @($files + @('SystemConfig.ini','conf.xml.usertmp','role.xml.usertmp'))) {
            $target = Join-Path $config.FullName $leaf
            $existed = Test-Path -LiteralPath $target
            if ($existed) { [IO.File]::Copy($target, (Join-Path $backup $leaf), $false) }
            $staged = Join-Path $backup ($leaf + '.new')
            if ($leaf -eq 'SystemConfig.ini') { [IO.File]::WriteAllText($staged,$systemText,(New-Object Text.UTF8Encoding($false))) }
            else { [IO.File]::Copy((Join-Path $TemplateDirectory ($leaf -replace '\.usertmp$','')), $staged, $false) }
            $writes += [pscustomobject]@{ Target=$target; Leaf=$leaf; Staged=$staged; Existed=$existed }
        }
        $attempted = @()
        try {
            foreach ($write in $writes) { $attempted += $write; [IO.File]::Copy($write.Staged,$write.Target,$true) }
        } catch {
            foreach ($write in $attempted) {
                if ($write.Existed) { [IO.File]::Copy((Join-Path $backup $write.Leaf),$write.Target,$true) }
                elseif (Test-Path -LiteralPath $write.Target) { Remove-Item -LiteralPath $write.Target }
            }
            throw "Не удалось настроить локальный вход. Резервные копии: $backup"
        }
        [pscustomobject]@{ AutoLogin=$true; Backup=$backup }
    }

    function Initialize-SmartPSSOrganization {
        param([string]$TemplateDirectory, [string]$ConfigDirectory, [string]$Address, [string]$Name)
        $ErrorActionPreference = 'Stop'
        if (@(Get-Process -Name SmartPSS -ErrorAction SilentlyContinue).Count) {
            throw 'Полностью закройте SmartPSS перед настройкой.'
        }
        $ip = $null
        if (-not [Net.IPAddress]::TryParse($Address, [ref]$ip) -or
            $ip.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork -or $ip.GetAddressBytes()[3] -ne 130) {
            throw 'Ожидается IPv4-адрес регистратора с окончанием .130.'
        }
        if ([string]::IsNullOrWhiteSpace($Name)) { throw 'Имя устройства не задано.' }
        if (-not (Test-Path -LiteralPath $ConfigDirectory -PathType Container)) {
            throw 'Каталог настроек SmartPSS отсутствует.'
        }
        $names = @('Organization', 'OrganizationDevice', 'OrganizationGroup', 'OrganizationRegion', 'OrganizationChannel', 'OrganizationEmap')
        $docs = @{}
        foreach ($item in $names) {
            $doc = Read-SmartPSSXml (Join-Path $TemplateDirectory "$item.xml")
            $version = if ($item -eq 'OrganizationDevice') { '2.0' } else { '1.0' }
            if ($doc.DocumentElement.Name -ne $item -or $doc.DocumentElement.GetAttribute('version') -ne $version) {
                throw "Неподдерживаемый формат $item.xml."
            }
            $docs[$item] = $doc
        }
        foreach ($link in @('Device','Group','Region','Channel','Emap')) {
            $node = $docs.Organization.SelectSingleNode("/Organization/$link")
            if ($null -eq $node -or $node.InnerText -cne "Organization$link.xml") {
                throw "Некорректная ссылка Organization/$link."
            }
        }
        $devices = @($docs.OrganizationDevice.SelectNodes('/OrganizationDevice/Device'))
        if ($devices.Count -ne 1) { throw 'Нужен шаблон ровно одного регистратора.' }
        $device = $devices[0]
        $deviceId = $device.GetAttribute('idUnique')
        if ($deviceId -notmatch '^\d+$' -or $device.GetAttribute('port') -ne '37777' -or
            $device.GetAttribute('protocol') -ne '1' -or $device.GetAttribute('connect') -ne '0' -or
            [string]::IsNullOrWhiteSpace($device.GetAttribute('username')) -or
            [string]::IsNullOrWhiteSpace($device.GetAttribute('password'))) {
            throw 'Некорректная запись регистратора в шаблоне.'
        }
        $groups = @($docs.OrganizationGroup.SelectNodes('/OrganizationGroup/Group') | ForEach-Object { $_.GetAttribute('idUnique') })
        $regions = @($docs.OrganizationRegion.SelectNodes('/OrganizationRegion/Region') | ForEach-Object { $_.GetAttribute('idUnique') })
        if ($groups -notcontains $device.GetAttribute('idGroup')) { throw 'Группа устройства отсутствует в шаблоне.' }
        $channels = @($docs.OrganizationChannel.SelectNodes('/OrganizationChannel/Channel'))
        # A template captured right after import has no channels yet; they are discarded anyway.
        foreach ($channel in $channels) {
            if ($channel.GetAttribute('idDevice') -ne $deviceId -or $regions -notcontains $channel.GetAttribute('idRegion')) {
                throw 'Нарушена связь каналов с устройством или регионом.'
            }
        }
        # Pharmacy recorders have different channel counts: SmartPSS discovers them itself.
        foreach ($channel in $channels) { $channel.ParentNode.RemoveChild($channel) | Out-Null }
        $docs.OrganizationChannel.DocumentElement.SetAttribute('idCount', '0')
        $device.SetAttribute('domain', $ip.ToString())
        $device.SetAttribute('name', $Name)
        $target = Join-Path $ConfigDirectory 'Organization'
        $targetDevice = Join-Path $target 'OrganizationDevice.xml'
        if (Test-Path -LiteralPath $targetDevice) {
            $existing = Read-SmartPSSXml $targetDevice
            if ($existing.DocumentElement.Name -ne 'OrganizationDevice') {
                throw 'Неизвестная конфигурация OrganizationDevice.'
            }
            $existingDevices = @($existing.DocumentElement.SelectNodes('*'))
            if ($existingDevices.Count -gt 0) {
                # Internal credential encoding includes the device ID. Never copy it to a different ID.
                if ($existingDevices.Count -ne 1 -or $existingDevices[0].LocalName -ne 'Device' -or
                    $existingDevices[0].GetAttribute('domain') -ne $Address -or
                    $existingDevices[0].GetAttribute('idUnique') -ne $deviceId -or
                    $existingDevices[0].GetAttribute('port') -ne '37777') {
                    throw 'В SmartPSS уже добавлены другие устройства (настроено вручную). Автоматическая перезапись отменена.'
                }
                $existingDevices[0].SetAttribute('username', $device.GetAttribute('username'))
                $existingDevices[0].SetAttribute('password', $device.GetAttribute('password'))
                $backup = "$targetDevice.pk-backup-$([guid]::NewGuid())"
                $temporary = "$targetDevice.$([guid]::NewGuid()).tmp"
                try {
                    $existing.Save($temporary)
                    [IO.File]::Replace($temporary, $targetDevice, $backup)
                } finally { if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary } }
                Set-SmartPSSAllChannels -ConfigDirectory $ConfigDirectory | Out-Null
                return [pscustomobject]@{ Address = $Address; DeviceID = $deviceId; Channels = 'Preserved'; Backup = $backup }
            }
        } elseif (Test-Path -LiteralPath $target -PathType Container) {
            if (@(Get-ChildItem -LiteralPath $target -Force).Count) { throw 'Неполная существующая конфигурация Organization. Перезапись отменена.' }
        }
        $show = New-Object Xml.XmlDocument
        $show.LoadXml('<ShowChannl version="1.0"/>')
        $entry = $show.CreateElement('ShowChannlInfo')
        $entry.SetAttribute('DeviceID', $deviceId)
        $entry.SetAttribute('ChannlMode', '6')
        $show.DocumentElement.AppendChild($entry) | Out-Null
        # Stage all content and back up every target before the first overwrite.
        $backup = Join-Path $ConfigDirectory ('pk-backup-' + [guid]::NewGuid())
        [IO.Directory]::CreateDirectory($backup) | Out-Null
        $writes = @()
        foreach ($item in $names) {
            $writes += [pscustomobject]@{ File = (Join-Path $target "$item.xml"); Doc = $docs[$item]; Leaf = "$item.xml"; Existed = $false }
        }
        $writes += [pscustomobject]@{ File = (Join-Path $ConfigDirectory 'ShowChannl.xml'); Doc = $show; Leaf = 'ShowChannl.xml'; Existed = $false }
        foreach ($write in $writes) {
            $write.Existed = Test-Path -LiteralPath $write.File -PathType Leaf
            if ($write.Existed) { [IO.File]::Copy($write.File, (Join-Path $backup $write.Leaf), $false) }
            $settings = New-Object Xml.XmlWriterSettings
            $settings.Encoding = New-Object Text.UTF8Encoding($false)
            $settings.Indent = $true
            $writer = [Xml.XmlWriter]::Create((Join-Path $backup ($write.Leaf + '.new')), $settings)
            try { $write.Doc.Save($writer) } finally { $writer.Dispose() }
        }
        [IO.Directory]::CreateDirectory($target) | Out-Null
        $attempted = @()
        try {
            foreach ($write in $writes) {
                $attempted += $write
                [IO.File]::Copy((Join-Path $backup ($write.Leaf + '.new')), $write.File, $true)
            }
        } catch {
            $failure = $_
            foreach ($write in $attempted) {
                try {
                    if ($write.Existed) { [IO.File]::Copy((Join-Path $backup $write.Leaf), $write.File, $true) }
                    elseif (Test-Path -LiteralPath $write.File) { Remove-Item -LiteralPath $write.File -Force }
                } catch { Write-Warning "Не удалось восстановить $($write.File). Копии: $backup" }
            }
            throw "Настройка не завершена. Резервные копии: $backup. Причина: $($failure.Exception.Message)"
        }
        [pscustomobject]@{ Address = $ip.ToString(); DeviceID = $deviceId; Channels = 0; Backup = $backup }
    }

    function Set-SmartPSSRussianLanguage {
        param([string]$ConfigDirectory)
        if (@(Get-Process -Name SmartPSS -ErrorAction SilentlyContinue).Count) {
            throw 'Полностью закройте SmartPSS перед выбором языка.'
        }
        $path = Join-Path $ConfigDirectory 'Settings.ini'
        $content = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
        $section = [regex]::Match($content, '(?ms)^\[Language\]\s*\r?\n(?<body>.*?)(?=^\[|\z)')
        $russian = [regex]::Matches($section.Value, '(?m)^LanguageCode(\d+)\s*=\s*ru\s*$')
        $current = [regex]::Matches($section.Value, '(?m)^CurrentLanguage\s*=\s*\d+[^\S\r\n]*')
        if (-not $section.Success -or $russian.Count -ne 1 -or $current.Count -ne 1) {
            throw 'Не удалось однозначно определить русский язык и CurrentLanguage в Settings.ini.'
        }
        $replacement = 'CurrentLanguage=' + $russian[0].Groups[1].Value
        if ($current[0].Value -eq $replacement) { return }
        $position = $section.Index + $current[0].Index
        $updated = $content.Remove($position, $current[0].Length).Insert($position, $replacement)
        $temporary = "$path.$([guid]::NewGuid()).tmp"
        try {
            [IO.File]::WriteAllText($temporary, $updated, (New-Object Text.UTF8Encoding($false)))
            [IO.File]::Replace($temporary, $path, "$path.pk-backup-$([guid]::NewGuid())")
        } finally { if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary } }
    }

    function Set-SmartPSSAllChannels {
        param([Parameter(Mandatory = $true)][string]$ConfigDirectory)
        $ErrorActionPreference = 'Stop'
        if (@(Get-Process -Name SmartPSS -ErrorAction SilentlyContinue).Count) {
            throw 'Полностью закройте SmartPSS: работающая программа может перезаписать настройки.'
        }
        $path = Join-Path $ConfigDirectory 'ShowChannl.xml'
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw 'ShowChannl.xml ещё не создан. DeviceID автоматически не угадывается.'
        }
        $file = Get-Item -LiteralPath $path
        if ($file.Length -gt 1MB) { throw 'Неожиданный размер ShowChannl.xml.' }
        # SmartPSS writes the nonstandard declaration encoding="UTF_8".
        # Decode UTF-8 explicitly and parse as text, then save standard UTF-8.
        $sourceBytes = [IO.File]::ReadAllBytes($file.FullName)
        $utf8 = New-Object Text.UTF8Encoding($false, $true)
        $reader = $null
        $textReader = $null
        try {
            $source = $utf8.GetString($sourceBytes).TrimStart([char]0xFEFF)
            $settings = New-Object Xml.XmlReaderSettings
            $settings.DtdProcessing = [Xml.DtdProcessing]::Prohibit
            $settings.XmlResolver = $null
            $textReader = New-Object IO.StringReader($source)
            $reader = [Xml.XmlReader]::Create($textReader, $settings)
            $document = New-Object Xml.XmlDocument
            $document.PreserveWhitespace = $true
            $document.XmlResolver = $null
            $document.Load($reader)
        } catch {
            throw 'Не удалось прочитать ShowChannl.xml как UTF-8 XML. Исходный файл не изменён.'
        } finally {
            if ($null -ne $reader) { $reader.Dispose() }
            if ($null -ne $textReader) { $textReader.Dispose() }
        }
        $root = $document.DocumentElement
        if ($root.Name -ne 'ShowChannl' -or $root.GetAttribute('version') -ne '1.0') {
            throw 'Ожидается ShowChannl версии 1.0. Файл не изменён.'
        }
        $entries = @($root.SelectNodes('ShowChannlInfo'))
        if (-not $entries.Count) { throw 'В ShowChannl.xml нет записей устройств.' }
        foreach ($entry in $entries) {
            if (-not $entry.HasAttribute('DeviceID') -or $entry.GetAttribute('DeviceID') -notmatch '^\d+$') {
                throw 'Некорректный DeviceID в ShowChannl.xml. Файл не изменён.'
            }
        }
        $changed = 0
        foreach ($entry in $entries) {
            if ($entry.GetAttribute('ChannlMode') -ne '6') {
                $entry.SetAttribute('ChannlMode', '6')
                $changed++
            }
        }
        $backupPath = $null
        if ($changed) {
            $temporaryPath = $file.FullName + '.' + [guid]::NewGuid() + '.tmp'
            $backupPath = $file.FullName + '.' + [guid]::NewGuid() + '.bak'
            $writerSettings = New-Object Xml.XmlWriterSettings
            $writerSettings.Encoding = $utf8
            $writer = $null
            try {
                $writer = [Xml.XmlWriter]::Create($temporaryPath, $writerSettings)
                $document.Save($writer)
                $writer.Dispose(); $writer = $null
                # Detect changes made while the script was reading the configuration.
                if ([Convert]::ToBase64String([IO.File]::ReadAllBytes($file.FullName)) -cne [Convert]::ToBase64String($sourceBytes)) {
                    throw 'ShowChannl.xml изменился во время обработки. Повторите после закрытия SmartPSS.'
                }
                [IO.File]::Replace($temporaryPath, $file.FullName, $backupPath)
            } finally {
                if ($null -ne $writer) { $writer.Dispose() }
                if (Test-Path -LiteralPath $temporaryPath) { Remove-Item -LiteralPath $temporaryPath -Force }
            }
        }
        [pscustomobject]@{ Path = $file.FullName; Devices = $entries.Count; Changed = $changed; Backup = $backupPath }
    }

    function Remove-PCNVRShortcuts {
        param([string[]]$Roots)
        if (-not $Roots) {
            $Roots = @('C:\Users\Public\Desktop', (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs'))
            foreach ($profile in @(Get-ChildItem -LiteralPath 'C:\Users' -Directory -ErrorAction SilentlyContinue)) {
                $Roots += (Join-Path $profile.FullName 'Desktop')
                $Roots += (Join-Path $profile.FullName 'AppData\Roaming\Microsoft\Windows\Start Menu\Programs')
            }
        }
        $shell = New-Object -ComObject WScript.Shell
        $removed = @()
        foreach ($root in @($Roots | Select-Object -Unique)) {
            if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }
            foreach ($link in @(Get-ChildItem -LiteralPath $root -Filter '*.lnk' -File -Recurse -Depth 2 -ErrorAction SilentlyContinue)) {
                $target = try { $shell.CreateShortcut($link.FullName).TargetPath } catch { '' }
                # PC-NVR files may already be deleted, but the link still stores the old target path.
                if ($link.BaseName -notmatch 'PC-?NVR' -and $target -notmatch '\\PC-NVR\\') { continue }
                Remove-Item -LiteralPath $link.FullName -Force
                $removed += $link.FullName
                $parent = $link.Directory
                if ($parent.Name -match 'PC-?NVR' -and -not @(Get-ChildItem -LiteralPath $parent.FullName -Force).Count) {
                    Remove-Item -LiteralPath $parent.FullName -Force
                }
            }
        }
        $removed
    }

    function Set-SmartPSSShortcut {
        param([Parameter(Mandatory = $true)][string]$Client)
        # Old CMS shortcuts (including КАМЕРЫ.lnk) would open the old video.
        Remove-AllShortcuts
        Remove-PCNVRShortcuts | Out-Null
        # Earlier script versions replaced SmartPSS.lnk with a camera icon.
        $oldIcon = Join-Path $SmartPSSConfigDirectory 'camera.ico'
        if (Test-Path -LiteralPath $oldIcon -PathType Leaf) { Remove-Item -LiteralPath $oldIcon -Force }
        $shortcut = 'C:\Users\Public\Desktop\SmartPSS.lnk'
        if (-not (Test-Path -LiteralPath $shortcut -PathType Leaf)) {
            if (-not (Create-Shortcut -TargetPath $Client -ShortcutPath $shortcut -IconPath "$Client,0" -WorkingDirectory (Split-Path $Client))) {
                throw 'Не удалось создать ярлык SmartPSS.'
            }
        }
        Reset-IconCache
        $shortcut
    }

    function Invoke-SmartPSSAutomaticSetup {
        param([Parameter(Mandatory = $true)][string]$Address)
        $ErrorActionPreference = 'Stop'
        if (-not (Test-AdminRights)) { throw 'Нужны права администратора.' }
        $state = Get-SmartPSSState
        if ($state.Clients.Count -gt 1) {
            throw "Найдено несколько SmartPSS.exe: $($state.Clients -join '; ')"
        }
        if ($state.Clients.Count -eq 0) {
            Write-Status "•" "Установка SmartPSS" "1-2 минуты" "Cyan"
            $client = Install-SmartPSS
            Write-Status "✓" "SmartPSS установлен" "" "Green"
        } else {
            $client = $state.Clients[0]
            Write-Status "✓" "SmartPSS уже установлен" "" "Green"
        }
        Stop-SmartPSSProcesses
        if (Test-SmartPSSStoragePresent -State (Get-SmartPSSState)) {
            Remove-SmartPSSStorageService | Out-Null
            Write-Status "✓" "Storage Service удалён" "" "Green"
        }
        Initialize-SmartPSSConfigDirectory -Client $client -ConfigDirectory $SmartPSSConfigDirectory
        $templates = Expand-SmartPSSTemplates
        try {
            Set-SmartPSSRussianLanguage -ConfigDirectory $SmartPSSConfigDirectory
            Initialize-SmartPSSLogin -TemplateDirectory (Join-Path $templates 'Login') -ConfigDirectory $SmartPSSConfigDirectory | Out-Null
            Write-Status "✓" "Русский язык и автовход" "" "Green"
            $configuration = Initialize-SmartPSSOrganization -TemplateDirectory (Join-Path $templates 'Organization') -ConfigDirectory $SmartPSSConfigDirectory -Address $Address -Name $RecorderName
            Write-Status "✓" "Регистратор добавлен" "$($configuration.Address), все каналы" "Green"
        } finally {
            Remove-Item -LiteralPath $templates -Recurse -Force -ErrorAction SilentlyContinue
        }
        # Files are written by the elevated script; the pharmacy user runs SmartPSS without elevation.
        & icacls.exe $SmartPSSConfigDirectory /grant '*S-1-5-32-545:(OI)(CI)M' /T /C /Q | Out-Null
        $shortcut = Set-SmartPSSShortcut -Client $client
        Write-Status "✓" "Ярлыки" "SmartPSS, без PC-NVR" "Green"
        [pscustomobject]@{
            Client = $client; Shortcut = $shortcut
            Address = $configuration.Address; DeviceID = $configuration.DeviceID; Backup = $configuration.Backup
        }
    }

    # ========================================================================
    # CMS: установка старого видео и добавление регистратора
    # ========================================================================

    function Find-CMSExistingData {
        # Reads an existing CMS config (local, then networked PCs) into memory so it survives the
        # reinstall. Returns the Data/DevGroup documents and the source label, or $null.
        $locals = @(
            'C:\Program Files (x86)\Polyvision\CMS\XML',
            'C:\Program Files (x86)\CMS\XML'
        )
        foreach ($profile in @(Get-ChildItem -LiteralPath 'C:\Users' -Directory -ErrorAction SilentlyContinue)) {
            $locals += (Join-Path $profile.FullName 'AppData\Local\VirtualStore\Program Files (x86)\Polyvision\CMS\XML')
        }
        $sources = foreach ($dir in $locals) { [pscustomobject]@{ Label = "локально ($dir)"; Dir = $dir } }
        $neighbors = @(Get-NetNeighbor -State Reachable, Stale, Delay, Probe -ErrorAction SilentlyContinue |
            Where-Object { $_.IPAddress -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$' } |
            Select-Object -ExpandProperty IPAddress -Unique)
        foreach ($ip in $neighbors) {
            foreach ($share in @("\\$ip\C`$\Program Files (x86)\Polyvision\CMS\XML", "\\$ip\C`$\Program Files (x86)\CMS\XML")) {
                $sources = @($sources) + [pscustomobject]@{ Label = "по сети ($ip)"; Dir = $share }
            }
        }
        foreach ($source in $sources) {
            $dataPath = Join-Path $source.Dir 'Data.xml'
            if (-not (Test-Path -LiteralPath $dataPath -PathType Leaf)) { continue }
            try {
                $data = New-Object Xml.XmlDocument
                $data.Load($dataPath)
                if ($data.DocumentElement.Name -ne 'DATAROOT' -or -not @($data.SelectNodes('/DATAROOT/DEVINFO/DEV')).Count) { continue }
            } catch { continue }
            $devgroup = $null
            $groupPath = Join-Path $source.Dir 'DevGroup.xml'
            if (Test-Path -LiteralPath $groupPath -PathType Leaf) {
                try { $devgroup = New-Object Xml.XmlDocument; $devgroup.Load($groupPath) } catch { $devgroup = $null }
            }
            return [pscustomobject]@{ Source = $source.Label; Data = $data; DevGroup = $devgroup }
        }
        $null
    }

    function Set-CMSConfigAddress {
        param([Parameter(Mandatory = $true)][xml]$Data, [Parameter(Mandatory = $true)][string]$Address)
        $devices = @($Data.SelectNodes('/DATAROOT/DEVINFO/DEV'))
        if (-not $devices.Count) { throw 'В найденной конфигурации CMS нет регистратора.' }
        foreach ($device in $devices) { $device.SetAttribute('host', $Address) }
    }

    function Get-SofiaHash {
        param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text)
        $md5 = [Security.Cryptography.MD5]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))
        $chars = for ($i = 0; $i -lt 8; $i++) {
            $n = ($md5[2 * $i] + $md5[2 * $i + 1]) % 62
            if ($n -lt 10) { [char](48 + $n) } elseif ($n -lt 36) { [char](55 + $n) } else { [char](61 + $n) }
        }
        -join $chars
    }

    function Invoke-CMSDvripLogin {
        param([string]$Address, [string]$User, [string]$Hash)
        # DVRIP-Web login; returns the parsed answer object or $null. Never throws.
        $tcp = New-Object Net.Sockets.TcpClient
        try {
            if (-not $tcp.ConnectAsync($Address, 34567).Wait(3000)) { return $null }
            $body = [Text.Encoding]::ASCII.GetBytes((@{ EncryptType = 'MD5'; LoginType = 'DVRIP-Web'; PassWord = $Hash; UserName = $User } | ConvertTo-Json -Compress) + "`n") + [byte[]](0)
            $header = New-Object byte[] 20
            $header[0] = 0xFF
            [BitConverter]::GetBytes([uint16]1000).CopyTo($header, 14)
            [BitConverter]::GetBytes([uint32]$body.Length).CopyTo($header, 16)
            $stream = $tcp.GetStream(); $stream.ReadTimeout = 5000
            $stream.Write($header, 0, 20); $stream.Write($body, 0, $body.Length)
            $head = New-Object byte[] 20; $read = 0
            while ($read -lt 20) { $r = $stream.Read($head, $read, 20 - $read); if ($r -le 0) { return $null }; $read += $r }
            $length = [BitConverter]::ToUInt32($head, 16)
            if ($length -eq 0 -or $length -gt 65536) { return $null }
            $data = New-Object byte[] $length; $read = 0
            while ($read -lt $length) { $r = $stream.Read($data, $read, $length - $read); if ($r -le 0) { break }; $read += $r }
            return ([Text.Encoding]::ASCII.GetString($data, 0, $read).Trim([char]0, [char]10, [char]13, ' ') | ConvertFrom-Json)
        } catch { return $null }
        finally { $tcp.Close() }
    }

    function Get-CMSRecorderInfo {
        param([Parameter(Mandatory = $true)][string]$Address)
        # Tries the known recorder passwords; on the first that logs in, returns the channel count
        # and the matching Data.xml password cipher. Recorder passwords differ between pharmacies.
        foreach ($password in $CMSRecorderCredentials.Keys) {
            $answer = Invoke-CMSDvripLogin -Address $Address -User $CMSRecorderUser -Hash (Get-SofiaHash $password)
            if ($null -ne $answer -and [int]$answer.Ret -eq 100) {
                $channels = [int]$answer.ChannelNum
                if ($channels -ge 1 -and $channels -le 64) {
                    return [pscustomobject]@{ Channels = $channels; Cipher = $CMSRecorderCredentials[$password] }
                }
            }
        }
        $null
    }

    function New-CMSDataXml {
        param(
            [Parameter(Mandatory = $true)][string]$Address,
            [Parameter(Mandatory = $true)][int]$Channels,
            [string]$PasswordCipher = $CMSRecorderPasswordCipher
        )
        if ($Channels -lt 1 -or $Channels -gt 64) { throw "Недопустимое число каналов: $Channels." }
        $doc = New-Object Xml.XmlDocument
        $doc.AppendChild($doc.CreateXmlDeclaration('1.0', 'UTF-8', $null)) | Out-Null
        $root = $doc.AppendChild($doc.CreateElement('DATAROOT'))
        $devinfo = $root.AppendChild($doc.CreateElement('DEVINFO'))
        $dev = $devinfo.AppendChild($doc.CreateElement('DEV'))
        $attributes = [ordered]@{
            id = '1'; ip = '1'; area = 'apt'; name = $Address; host = $Address; port = '34567'; port2 = '0'
            cameras = [string]$Channels; devcType = '1'; alarmcameras = '0'; ddnsFlag = '0'; DDNSHost = ''; pos = '0'
            desc = ''; username = $CMSRecorderUser; OrgId = '1'; vendor = $CMSRecorderVendor; SerialID = ''; 'link-mode' = '0'
            arspstatus = '0'; password = $PasswordCipher
        }
        foreach ($pair in $attributes.GetEnumerator()) { $dev.SetAttribute($pair.Key, $pair.Value) }
        for ($channel = 0; $channel -lt $Channels; $channel++) {
            $child = $dev.AppendChild($doc.CreateElement('DEV'))
            $child.SetAttribute('id', [string]($channel + 2))
            $child.SetAttribute('type', '0')
            # Latin placeholder; CMS replaces it with the recorder's real channel name once online.
            $child.SetAttribute('name', "CAM $($channel + 1)")
            $child.SetAttribute('channel', [string]$channel)
            $child.SetAttribute('desc', '')
        }
        $root.AppendChild($doc.CreateElement('IMGINFO')) | Out-Null
        $root.AppendChild($doc.CreateElement('MAPINFO')) | Out-Null
        $global = $root.AppendChild($doc.CreateElement('GLOBAL'))
        $global.SetAttribute('index', [string]($Channels + 2))
        $doc
    }

    function New-CMSDevGroupXml {
        $doc = New-Object Xml.XmlDocument
        $doc.AppendChild($doc.CreateXmlDeclaration('1.0', 'UTF-8', $null)) | Out-Null
        $root = $doc.AppendChild($doc.CreateElement('DEVGROUP'))
        $group = $root.AppendChild($doc.CreateElement('GROUP'))
        $group.SetAttribute('name', 'apt'); $group.SetAttribute('groupID', '1'); $group.SetAttribute('parentID', '0')
        $device = $group.AppendChild($doc.CreateElement('DEVICE')); $device.SetAttribute('devID', '1')
        ($root.AppendChild($doc.CreateElement('GLOBAL'))).SetAttribute('index', '2')
        ($root.AppendChild($doc.CreateElement('VERSION'))).SetAttribute('version', '1')
        $doc
    }

    function Get-CMSXmlDirectories {
        # Real install XML dirs where the elevated script writes, plus every user's VirtualStore
        # shadow of them. CMS runs non-elevated and reads the VirtualStore shadow when it exists,
        # so both must carry our config for CMS to pick it up.
        $installs = @('C:\Program Files (x86)\Polyvision\CMS\XML', 'C:\Program Files (x86)\CMS\XML')
        $dirs = @($installs)
        foreach ($profile in @(Get-ChildItem -LiteralPath 'C:\Users' -Directory -ErrorAction SilentlyContinue)) {
            foreach ($install in $installs) {
                $relative = $install -replace '^[A-Za-z]:\\', ''
                $dirs += Join-Path $profile.FullName ("AppData\Local\VirtualStore\$relative")
            }
        }
        @($dirs | Select-Object -Unique)
    }

    function Write-CMSConfig {
        param([Parameter(Mandatory = $true)][xml]$Data, [xml]$DevGroup, [Parameter(Mandatory = $true)][string[]]$Destinations)
        $written = @()
        foreach ($dir in $Destinations) {
            # Write only where CMS is actually installed (real dir), or where a VirtualStore shadow
            # already exists; do not create CMS folders under an install path that has none.
            $parent = Split-Path $dir
            if (-not (Test-Path -LiteralPath $dir -PathType Container) -and -not (Test-Path -LiteralPath $parent -PathType Container)) { continue }
            Ensure-Directory $dir
            foreach ($pair in @(@('Data.xml', $Data), @('DevGroup.xml', $DevGroup))) {
                if ($null -eq $pair[1]) { continue }
                $path = Join-Path $dir $pair[0]
                if (Test-Path -LiteralPath $path -PathType Leaf) {
                    Copy-Item -LiteralPath $path -Destination "$path.pk-backup-$([guid]::NewGuid())" -Force -ErrorAction SilentlyContinue
                }
                $settings = New-Object Xml.XmlWriterSettings
                $settings.Encoding = New-Object Text.UTF8Encoding($false)
                $settings.Indent = $true
                $writer = [Xml.XmlWriter]::Create($path, $settings)
                try { $pair[1].Save($writer) } finally { $writer.Dispose() }
            }
            $written += $dir
        }
        @($written | Select-Object -Unique)
    }

    function Invoke-CMSSetup {
        $ErrorActionPreference = 'Continue'

        $CMS_PATH    = "C:\Program Files (x86)\Polyvision\CMS"
        $SETUP_URL   = "https://github.com/aspektyoyo/pk/raw/main/Setup.exe"

        $DOWNLOADS_DIR  = "C:\Users\kassir\Downloads"
        $DESKTOP_DIR    = "C:\Users\kassir\Desktop"

        $SETUP_FILE    = Join-Path $DOWNLOADS_DIR "Setup.exe"
        $ICON_FILE     = Join-Path $DOWNLOADS_DIR "camera.ico"
        $BAT_FILE      = Join-Path $CMS_PATH "CMS.bat"
        $SHORTCUT_FILE = Join-Path $DESKTOP_DIR "КАМЕРЫ.lnk"

        $XML_DIR       = Join-Path $CMS_PATH "XML"
        # Real install dirs and their VirtualStore shadows (CMS runs non-elevated, reads the shadow).
        $configDestinations = Get-CMSXmlDirectories

        # --- ШАГ 1: Адрес регистратора ---

        $recorder = Get-RecorderAddress

        # --- ШАГ 2: Поиск готовой конфигурации CMS (в память, до переустановки) ---

        if ($CMSForceCreate) {
            $existing = $null
            Write-Status "•" "Поиск настройки пропущен" "PK_CMS_FORCE_CREATE, создаётся заново" "Yellow"
        } elseif ($existing = Find-CMSExistingData) {
            Write-Status "✓" "Конфигурация" "найдена $($existing.Source)" "Green"
        } else {
            Write-Status "•" "Конфигурация" "не найдена, будет создана" "Gray"
        }

        Write-Host "  ─────────────────────────────" -ForegroundColor DarkGray

        # --- ШАГ 3: Удаление старых папок CMS ---

        foreach ($folder in @("C:\Program Files (x86)\Polyvision", "C:\Program Files (x86)\CMS")) {
            if (Test-Path $folder -PathType Container) {
                try {
                    Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
                }
                catch {
                    Write-Status "✗" "Не удалось удалить $folder" "" "Red"
                    Write-Status "  " $_.Exception.Message "" "DarkGray"
                    return
                }
            }
        }

        # --- ШАГ 4: Загрузка и установка CMS ---

        if (-not (Download-File -URL $SETUP_URL -OutFile $SETUP_FILE -Description "Setup.exe")) {
            Write-Status "✗" "Не удалось скачать установщик" "" "Red"
            return
        }

        try {
            $proc = Start-Process -FilePath $SETUP_FILE -ArgumentList "/SILENT" -Wait -PassThru -WindowStyle Hidden
            if ($proc.ExitCode -ne 0) {
                Write-Status "✗" "Установщик завершился с ошибкой" "код $($proc.ExitCode)" "Red"
                return
            }
        }
        catch {
            Write-Status "✗" "Ошибка запуска установщика" "" "Red"
            return
        }

        if (-not (Test-Path $CMS_PATH -PathType Container)) {
            Write-Status "✗" "Папка CMS не найдена после установки" "" "Red"
            return
        }

        Ensure-Directory $XML_DIR

        Write-Status "✓" "CMS установлена" "" "Green"

        # --- ШАГ 5: Конфигурация регистратора (.130) ---

        if ($existing) {
            Set-CMSConfigAddress -Data $existing.Data -Address $recorder.Address
            $devgroup = $existing.DevGroup
            $cameras = @($existing.Data.SelectNodes('/DATAROOT/DEVINFO/DEV[1]/DEV')).Count
            Write-CMSConfig -Data $existing.Data -DevGroup $devgroup -Destinations $configDestinations
            Write-Status "✓" "Регистратор" "$($recorder.Address), каналов $cameras (из старой настройки)" "Green"
        } else {
            $info = Get-CMSRecorderInfo -Address $recorder.Address
            if ($info) {
                $channels = $info.Channels
                $cipher = $info.Cipher
                Write-Status "✓" "Каналов на регистраторе" $channels "Green"
            } else {
                $channels = 16
                $cipher = $CMSRecorderPasswordCipher
                Write-Status "!" "Регистратор не ответил" "ставлю $channels каналов, стандартный пароль" "Yellow"
            }
            $data = New-CMSDataXml -Address $recorder.Address -Channels $channels -PasswordCipher $cipher
            $devgroup = New-CMSDevGroupXml
            Write-CMSConfig -Data $data -DevGroup $devgroup -Destinations $configDestinations
            Write-Status "✓" "Регистратор" "$($recorder.Address), каналов $channels (создано)" "Green"
        }

        # --- ШАГ 6: BAT-файл ---

        $batContent = "cmd /min /C `"set __COMPAT_LAYER=RUNASINVOKER && start `"`" `"$CMS_PATH\CMS.exe`"`""
        Set-Content -Path $BAT_FILE -Value $batContent -Force
        Write-Status "✓" "BAT-файл создан" "" "Green"

        # --- ШАГ 7: Загрузка иконки ---

        if (Test-Path $ICON_FILE) {
            Remove-Item $ICON_FILE -Force -ErrorAction SilentlyContinue
        }

        $iconExists = Download-File -URL $ICON_URL -OutFile $ICON_FILE -Description "camera.ico"

        # --- ШАГ 8: Удаление всех ярлыков + сброс кэша иконок ---

        Remove-AllShortcuts
        Reset-IconCache

        # --- ШАГ 9: Создание ярлыка КАМЕРЫ ---

        if ($iconExists -and (Test-Path $ICON_FILE)) {
            $iconParam = "$ICON_FILE,0"
        } else {
            $iconParam = ""
        }

        Create-Shortcut -TargetPath $BAT_FILE -ShortcutPath $SHORTCUT_FILE -IconPath $iconParam | Out-Null
        Write-Status "✓" "Ярлык КАМЕРЫ.lnk" "создан" "Green"

        Write-Host ""
        Write-Host "  ✓  ЗАВЕРШЕНО" -ForegroundColor Green
    }

    # ========================================================================
    # Запуск
    # ========================================================================

    if (-not (Test-AdminRights)) {
        Write-Host "  Нужны права администратора: открывается окно PowerShell от администратора..." -ForegroundColor Yellow
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -NoExit -Command irm '$ScriptUrl' | iex"
        return
    }

    Write-Host ""
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "          Видео: установка" -ForegroundColor Cyan
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""

    try {
        $detection = Get-VideoSystemDetection
        Write-Status "•" "Регистратор" $detection.RecorderAddress "Cyan"
        switch ($detection.Candidate) {
            'SmartPSS' {
                Write-Status "✓" "Новое видео" "SmartPSS (порт 37777)" "Green"
                Write-Host "  ─────────────────────────────" -ForegroundColor DarkGray
                $result = Invoke-SmartPSSAutomaticSetup -Address $detection.RecorderAddress
                # explorer.exe starts the shortcut without the script's elevation.
                Start-Process explorer.exe -ArgumentList "`"$($result.Shortcut)`""
                Write-Host ""
                Write-Host "  ✓  ЗАВЕРШЕНО: SmartPSS открывается" -ForegroundColor Green
            }
            'CMS' {
                Write-Status "✓" "Старое видео" "CMS (порт 34567)" "Green"
                Write-Host "  ─────────────────────────────" -ForegroundColor DarkGray
                Invoke-CMSSetup
            }
            default {
                Write-Status "✗" "Тип видео не определён" $detection.Reason "Red"
            }
        }
    } catch {
        Write-Host ""
        Write-Status "✗" "Ошибка" $_.Exception.Message "Red"
    }

    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    Pause
}
