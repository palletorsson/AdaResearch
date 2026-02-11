@echo off
echo =============================================
echo   Capturing Godot Editor Warnings
echo   This opens Godot, captures output, then you close it
echo =============================================
echo.

set GODOT=C:\Users\palle\Desktop\Godot_v4.6-stable_win64_console.exe
set PROJECT=C:\Users\palle\Documents\GitHub\AdaResearch_46
set OUTPUT=%USERPROFILE%\Desktop\godot_editor_warnings.txt

echo Output will be saved to: %OUTPUT%
echo.
echo Starting Godot... (close it when done loading)
echo.

"%GODOT%" --path "%PROJECT%" --editor > "%OUTPUT%" 2>&1

echo.
echo Done! Check: %OUTPUT%
echo.
pause
