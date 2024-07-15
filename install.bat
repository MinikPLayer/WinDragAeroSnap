@echo off

goto main
EXIT /B

:run_as_Admin
	set "params=%*"
	cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~sdp0"" && ""%~s0"" %params%", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )
	EXIT /B 0

:check_Admin
    echo Checking for admin permissions...
    
    NET SESSION >nul 2>&1
    if NOT %errorLevel% EQU 0 (
		echo Running as user. Prompting for elevated privileges.
        CALL :run_as_Admin
		EXIT
    )
	
	echo Running as Admin. 
	EXIT /B 0

:main
	CALL :check_Admin
	
	set AHK_PATH=C:\Users\Minik\AppData\Local\Programs\AutoHotkey\UX\AutoHotKeyUX.exe
	set SCRIPT_PATH=%~dp0\WinDrag.ahk

	SCHTASKS /CREATE /SC ONLOGON /TN "WinDrag" /TR "%AHK_PATH% %SCRIPT_PATH%" /DELAY 0000:05 /RL HIGHEST