#!/bin/bash
# run_tests.sh - Linux/Mac version
# Automated testing script for VR Algorithm Visualization Library

echo "🧪 VR Algorithm Library - Automated Testing"
echo "============================================"

# Check if Godot is available
if ! command -v godot &> /dev/null; then
    echo "❌ Godot not found in PATH. Please install Godot 4.4+ or add it to PATH"
    echo "💡 You can also edit this script to use the full path to your Godot executable"
    exit 1
fi

# Get Godot version
GODOT_VERSION=$(godot --version 2>&1 | head -n 1)
echo "🔧 Using: $GODOT_VERSION"

# Check if we're in a Godot project directory
if [ ! -f "project.godot" ]; then
    echo "❌ No project.godot found. Please run this script from your Godot project root directory"
    exit 1
fi

# Check if algorithms directory exists
if [ ! -d "algorithms" ]; then
    echo "❌ No 'algorithms' directory found. This script is designed for the VR Algorithm Library"
    exit 1
fi

SCENE_COUNT=$(find algorithms -name "*.tscn" | wc -l)
echo "📁 Found algorithms directory with $SCENE_COUNT scene files (expected: 283)"
echo "🚀 Starting automated testing across 33 algorithm categories..."
echo ""

# Create the testing script if it doesn't exist
cat > temp_test_script.gd << 'EOF'
# Temporary test runner script
extends SceneTree

const AutomatedSceneTester = preload("res://automated_scene_tester.gd")

func _ready():
    var tester = AutomatedSceneTester.new()
    # The tester will handle everything from here
EOF

# Run the tests
echo "⏳ Executing tests (this may take several minutes)..."
godot --headless --script temp_test_script.gd

# Check if test results were generated
if [ -d "$HOME/.local/share/godot/app_userdata/[YourProjectName]/test_results" ] || [ -d "$(godot --print-user-data-dir)/test_results" 2>/dev/null ]; then
    echo ""
    echo "✅ Testing completed successfully!"
    echo "📊 Results saved to user data directory"
    echo "🔍 Check the test_results folder for:"
    echo "   • Screenshots of each scene"
    echo "   • Detailed JSON report"
    echo "   • CSV summary for analysis"
else
    echo ""
    echo "⚠️ Testing completed but results directory not found"
    echo "🔍 Check Godot console output for details"
fi

# Cleanup
rm -f temp_test_script.gd

echo ""
echo "🎉 VR Algorithm Library testing complete!"

# Windows batch file version
cat > run_tests.bat << 'EOF'
@echo off
REM run_tests.bat - Windows version
REM Automated testing script for VR Algorithm Visualization Library

echo 🧪 VR Algorithm Library - Automated Testing
echo ============================================

REM Check if Godot is available
where godot >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Godot not found in PATH. Please install Godot 4.4+ or add it to PATH
    echo 💡 You can also edit this script to use the full path to your Godot executable
    pause
    exit /b 1
)

REM Get Godot version
for /f "delims=" %%i in ('godot --version 2^>^&1') do set GODOT_VERSION=%%i
echo 🔧 Using: %GODOT_VERSION%

REM Check if we're in a Godot project directory
if not exist "project.godot" (
    echo ❌ No project.godot found. Please run this script from your Godot project root directory
    pause
    exit /b 1
)

REM Check if algorithms directory exists
if not exist "algorithms" (
    echo ❌ No 'algorithms' directory found. This script is designed for the VR Algorithm Library
    pause
    exit /b 1
)

echo 📁 Found algorithms directory
echo 🚀 Starting automated testing...
echo.

REM Create the testing script
echo # Temporary test runner script > temp_test_script.gd
echo extends SceneTree >> temp_test_script.gd
echo. >> temp_test_script.gd
echo const AutomatedSceneTester = preload("res://automated_scene_tester.gd") >> temp_test_script.gd
echo. >> temp_test_script.gd
echo func _ready(): >> temp_test_script.gd
echo     var tester = AutomatedSceneTester.new() >> temp_test_script.gd

REM Run the tests
echo ⏳ Executing tests (this may take several minutes)...
godot --headless --script temp_test_script.gd

echo.
echo ✅ Testing completed!
echo 📊 Check the user data directory for results
echo 🔍 Look for test_results folder with screenshots and reports

REM Cleanup
del temp_test_script.gd

echo.
echo 🎉 VR Algorithm Library testing complete!
pause
EOF

chmod +x run_tests.sh
echo ""
echo "📝 Created platform-specific scripts:"
echo "   • run_tests.sh (Linux/Mac)"
echo "   • run_tests.bat (Windows)"