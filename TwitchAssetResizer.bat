@echo off
setlocal
set "TWITCH_INPUT=%~1"
set "TWITCH_DIR=%~dp0"
if not exist "%TWITCH_DIR%TwitchAssetResizer.ps1" (
    echo ERRO: TwitchAssetResizer.ps1 nao foi encontrado.
    echo Extraia todos os arquivos do ZIP para a mesma pasta e execute novamente.
    pause
    exit /b 1
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TWITCH_DIR%TwitchAssetResizer.ps1"
set "TWITCH_EXIT=%ERRORLEVEL%"
if not "%TWITCH_EXIT%"=="0" echo O PowerShell terminou com codigo %TWITCH_EXIT%.
pause
exit /b %TWITCH_EXIT%
