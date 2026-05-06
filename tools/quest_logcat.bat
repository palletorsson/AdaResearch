@echo off
echo ============================================
echo   Quest Live Log Viewer
echo   Press Ctrl+C to stop
echo ============================================
echo.

C:\Users\palle\AppData\Local\Android\Sdk\platform-tools\adb.exe logcat -c
C:\Users\palle\AppData\Local\Android\Sdk\platform-tools\adb.exe logcat godot:V GodotEngine:V libc:F DEBUG:F *:S

pause
