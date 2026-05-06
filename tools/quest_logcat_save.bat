@echo off
echo ============================================
echo   Quest Log Capture (saving to file)
echo   Press Ctrl+C to stop and save
echo ============================================

set LOGFILE=%USERPROFILE%\Desktop\quest_log_%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%.txt
set LOGFILE=%LOGFILE: =0%

echo Saving to: %LOGFILE%
echo.

C:\Users\palle\AppData\Local\Android\Sdk\platform-tools\adb.exe logcat -c
C:\Users\palle\AppData\Local\Android\Sdk\platform-tools\adb.exe logcat godot:V GodotEngine:V libc:F DEBUG:F *:S > "%LOGFILE%"

echo.
echo Log saved to %LOGFILE%
pause
