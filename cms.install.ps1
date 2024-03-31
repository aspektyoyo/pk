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





$outputPath = "D:\Setup.exe"

try {
    # Проверяем, существует ли файл
    if (Test-Path $outputPath) {
        # Запуск установочного файла от имени администратора
        Start-Process -FilePath $outputPath -Verb RunAs
        Write-Host "Установочный файл успешно запущен."

        # Добавляем задержку для ожидания загрузки установщика
        Start-Sleep -Seconds 1

        # Функция для эмуляции нажатий клавиш
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

# Создание объекта WebClient
$webClient = New-Object System.Net.WebClient

# Загрузка файла
$webClient.DownloadFile($url, $outputPath)

# Освобождение ресурсов WebClient
$webClient.Dispose()

Write-Host "Файл успешно загружен и сохранен по пути: $outputPath"
			
			# Получаем IPv4-адрес из текущей настройки компьютера
$IPv4Addresses = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -ne 'Loopback Pseudo-Interface 1' }).IPAddress

# Если найден хотя бы один IPv4-адрес
if ($IPv4Addresses) {
    # Выбираем последний адрес из списка
    $IPv4Address = $IPv4Addresses[-1]

    # Формируем строку для замены
    $ReplacementString = 'host="' + $IPv4Address + '"'

    # Путь к файлу test.xml на диске D
    $FilePath = "C:\Program Files (x86)\Polyvision\CMS\XML\data.xml"

    # Читаем содержимое файла в переменную
    $FileContent = Get-Content -Path $FilePath

    # Заменяем значение атрибута host на IPv4-адрес
    $NewFileContent = $FileContent -replace 'host="\d+\.\d+\.\d+\.\d+"', $ReplacementString

    # Перезаписываем файл с обновленным содержимым
    $NewFileContent | Set-Content -Path $FilePath

    Write-Host "IPv4-адрес $IPv4Address успешно записан в файл $FilePath."
} else {
    Write-Host "IPv4-адрес не найден."
}
			

            $wshell.SendKeys("{ENTER}")
            Start-Sleep -Milliseconds 100
        }

        # Вызываем функцию для эмуляции нажатий клавиш
        Send-UIKeyPress
        Write-Host "Клавиши успешно нажаты."
    } else {
        Write-Host "Файл $outputPath не найден."
    }
}
catch {
    Write-Host "Произошла ошибка при запуске установочного файла: $_"
}
