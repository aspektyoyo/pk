$url = "https://github.com/aspektyoyo/pk/raw/main/Setup.exe"
$outputPath = "D:\Setup.exe"

try {
    # Загрузка файла
    Invoke-WebRequest -Uri $url -OutFile $outputPath
    Write-Host "Файл успешно загружен по пути: $outputPath"
}
catch {
    Write-Host "Произошла ошибка при загрузке файла: $_"
}


D:\Setup.exe /SILENT


Start-Sleep -Seconds 15



$url = "https://raw.githubusercontent.com/aspektyoyo/pk/main/Data.xml"
$outputPath = "C:\Program Files (x86)\Polyvision\CMS\XML\Data.xml"

# Создание объекта WebClient
$webClient = New-Object System.Net.WebClient

# Загрузка файла
$webClient.DownloadFile($url, $outputPath)

# Освобождение ресурсов WebClient
$webClient.Dispose()

Write-Host "Файл успешно загружен и сохранен по пути: $outputPath"



Invoke-WebRequest -Uri "https://raw.githubusercontent.com/aspektyoyo/pk/main/DevGroup.xml" -OutFile "C:\Program Files (x86)\Polyvision\CMS\XML\DevGroup.xml"




$DefaultGateway = (Get-NetRoute -AddressFamily IPv4 | Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' }).NextHop

if ($DefaultGateway) {
    $GatewayParts = $DefaultGateway -split '\.'

    if ($GatewayParts.Count -eq 4) {
        $GatewayParts[3] = "130"
        $NewGateway = $GatewayParts -join "."

        $FilePath = "C:\Program Files (x86)\Polyvision\CMS\XML\Data.xml"

        $FileContent = Get-Content -Path $FilePath

        $NewFileContent = $FileContent -replace 'host="[^"]*"', "host=`"$NewGateway`""

        $NewFileContent | Set-Content -Path $FilePath
    }
}