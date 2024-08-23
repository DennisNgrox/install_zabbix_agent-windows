@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION


REM Baixar instalador do Zabbix Agent (versão 7.0.2)
curl https://cdn.zabbix.com/zabbix/binaries/stable/7.0/7.0.2/zabbix_agent-7.0.2-windows-amd64-openssl.msi --silent --output %TEMP%\zabbix_agent.msi

REM Liberar porta 10050 no Firewall
netsh advfirewall firewall add rule name="Zabbix Agent" dir=in action=allow protocol=TCP localport=10050

REM Instalar Zabbix Agent
msiexec /l*v %TEMP%\install-zabbix-agent-log.txt /i %TEMP%\zabbix_agent.msi^
 SERVER=10.202.45.13,146.235.38.74^
 SERVERACTIVE=10.202.45.13,146.235.38.74^
 HOSTNAME=teste^
 TIMEOUT=15^
 /qn

REM Definindo o caminho do arquivo de configuração do Zabbix Agent
set "ZABBIX_AGENT_CONF=%PROGRAMFILES%\Zabbix Agent\zabbix_agentd.conf"

REM Backup do arquivo original
copy "%ZABBIX_AGENT_CONF%" "%ZABBIX_AGENT_CONF%.bak"

REM Substituir ou adicionar entradas no arquivo de configuração
(
    set "foundAllowKey=false"
    for /f "delims=" %%i in ('type "%ZABBIX_AGENT_CONF%"') do (
        set "line=%%i"
        if "!line!"=="Server=127.0.0.1" (
            echo Server=%server%
        ) else if "!line!"=="ServerActive=127.0.0.1" (
            echo ServerActive=%server%
        ) else if "!line!"=="Hostname=teste" (
            echo # Hostname=
        ) else if "!line!"=="# HostnameItem=system.hostname" (
            echo HostnameItem=system.hostname
        ) else if "!line!"=="# HostMetadataItem=" (
            echo HostMetadataItem=system.uname
        ) else if "!line!"=="# Timeout=3" (
            echo Timeout=30
        ) else if "!line!"=="# DenyKey=system.run[*]" (
            echo AllowKey=system.run[*]
        ) else (
            echo !line!
        )
    )
    
    REM Adiciona a linha AllowKey=system.run[*] se não estiver presente
    if "%foundAllowKey%"=="false" (
        echo AllowKey=system.run[*]
    )
) > "%ZABBIX_AGENT_CONF%.new"

REM Substitui o arquivo original pelo modificado
move /y "%ZABBIX_AGENT_CONF%.new" "%ZABBIX_AGENT_CONF%"

ENDLOCAL
