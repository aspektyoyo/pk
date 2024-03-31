$url = "https://github.com/aspektyoyo/pk/raw/main/Setup.exe"
$outputPath = "D:\Setup.exe"

try {
    # �������� �����
    Invoke-WebRequest -Uri $url -OutFile $outputPath
    Write-Host "���� ������� �������� �� ����: $outputPath"
}
catch {
    Write-Host "��������� ������ ��� �������� �����: $_"
}





$outputPath = "D:\Setup.exe"

try {
    # ���������, ���������� �� ����
    if (Test-Path $outputPath) {
        # ������ ������������� ����� �� ����� ��������������
        Start-Process -FilePath $outputPath -Verb RunAs
        Write-Host "������������ ���� ������� �������."

        # ��������� �������� ��� �������� �������� �����������
        Start-Sleep -Seconds 1

        # ������� ��� �������� ������� ������
        function Send-UIKeyPress {
            $wshell = New-Object -ComObject WScript.Shell

            $wshell.SendKeys("{TAB}")
            Start-Sleep -Milliseconds 100

            $wshell.SendKeys("{UP}")
            Start-Sleep -Milliseconds 100

            $wshell.SendKeys("{ENTER}")
            Start-Sleep -Milliseconds 100

            for ($i = 1; $i -le 2; $i++) {
                $wshell.SendKeys("{ENTER}")
                Start-Sleep -Milliseconds 100
            }

            Start-Sleep -Seconds 5
			
			
			
			
			$url = "https://raw.githubusercontent.com/aspektyoyo/pk/main/Data.xml"
$outputPath = "C:\Program Files (x86)\Polyvision\CMS\XML\Data.xml"

# �������� ������� WebClient
$webClient = New-Object System.Net.WebClient

# �������� �����
$webClient.DownloadFile($url, $outputPath)

# ������������ �������� WebClient
$webClient.Dispose()

Write-Host "���� ������� �������� � �������� �� ����: $outputPath"
			
			# �������� IPv4-����� �� ������� ��������� ����������
$IPv4Addresses = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -ne 'Loopback Pseudo-Interface 1' }).IPAddress

# ���� ������ ���� �� ���� IPv4-�����
if ($IPv4Addresses) {
    # �������� ��������� ����� �� ������
    $IPv4Address = $IPv4Addresses[-1]

    # ��������� ������ ��� ������
    $ReplacementString = 'host="' + $IPv4Address + '"'

    # ���� � ����� test.xml �� ����� D
    $FilePath = "C:\Program Files (x86)\Polyvision\CMS\XML\data.xml"

    # ������ ���������� ����� � ����������
    $FileContent = Get-Content -Path $FilePath

    # �������� �������� �������� host �� IPv4-�����
    $NewFileContent = $FileContent -replace 'host="\d+\.\d+\.\d+\.\d+"', $ReplacementString

    # �������������� ���� � ����������� ����������
    $NewFileContent | Set-Content -Path $FilePath

    Write-Host "IPv4-����� $IPv4Address ������� ������� � ���� $FilePath."
} else {
    Write-Host "IPv4-����� �� ������."
}
			

            $wshell.SendKeys("{ENTER}")
            Start-Sleep -Milliseconds 100
        }

        # �������� ������� ��� �������� ������� ������
        Send-UIKeyPress
        Write-Host "������� ������� ������."
    } else {
        Write-Host "���� $outputPath �� ������."
    }
}
catch {
    Write-Host "��������� ������ ��� ������� ������������� �����: $_"
}
