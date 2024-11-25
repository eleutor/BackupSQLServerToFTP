@echo off
chcp 65001 >nul

REM Variables de configuración
set BACKUP_UBICA=C:\carpetaorixenscript

REM Carpeta destino do FTP (cambiala)
set DEST_FTP=/nome_da_maquina

REM Información DataBase
set SQL_SERVER="localhost\SQLEXPRESS" 
set DB_NAME=sps
set SQL_USER=sa
set SQL_PASSWD=sps

REM Crear carpeta se é necesario e ubicarse nela
if not exist %BACKUP_UBICA% (
    mkdir %BACKUP_UBICA%\script
)

cd %BACKUP_UBICA%/script

REM Obter data e hora

for /f "tokens=1-4 delims=/ " %%a in ("%date%") do set DATE=%%c%%a%%b
for /f "tokens=1-4 delims=:," %%a in ("%time%") do (
    set HORA=%%a
    set MINUTO=%%b
    set SEGUNDO=%%c
)
set TEMPO=%HORA%%MINUTO%%SEGUNDO%

REM Definir previamente o nome do arquivo de respaldo
set BACKUP_FILE=%BACKUP_UBICA%\%DB_NAME%_%DATE%_%TEMPO%.bak

REM Crear arquivo de SQL
(
    echo BACKUP DATABASE %DB_NAME%
    echo TO DISK = '%BACKUP_FILE%'
    echo WITH FORMAT, INIT, SKIP, NOREWIND, NOUNLOAD, STATS = 10;
) > backup.sql

REM Executar backup
if exist "backup.sql" (
    sqlcmd -S %SQL_SERVER% -U %SQL_USER% -P %SQL_PASSWD% -d %DB_NAME% -i "backup.sql"    
) else (
    echo "Erro, non se atopa o arquivo backup.sql"
)


REM Comprobar que se creou correctamente e seleccionar o último 
if exist "%BACKUP_FILE%" (
    for /f "delims=" %%i in ('dir /b /o-d %BACKUP_UBICA%\*.bak') do set LAST_BACKUP=%%i & goto :atopado
) else (
    echo Erro, non se atopa o arquivo de respaldo, comprobar SQL >> backup_log.txt
    echo.
)

:atopado
echo O último backup é %LAST_BACKUP%
echo.

REM Crear arquivo cos comandos de WinSCP
(
    echo open ftp://userFTP:userFTPpassword@ipdoservidorftp/
    echo cd %DEST_FTP%
    echo put "%BACKUP_UBICA%\%LAST_BACKUP%"
    echo close
    echo exit
) > "%BACKUP_UBICA%\script\winscp_comandos.txt"

REM Ejecutar WinSCP con el archivo de script (PODE QUE A RUTA DO WINSCP NON SEXA ESTA)
"C:\Program Files (x86)\WinSCP\WinSCP.com" /script="%BACKUP_UBICA%\script\winscp_comandos.txt"

echo Comando executado para subir arquivo ó servidor FTP: %DEST_FTP%/%LAST_BACKUP%
echo.

pause
