@echo off
REM run_tests_simple.bat - Simplified Windows testing script
REM Automated testing script for VR Algorithm Visualization Library

echo 🧪 VR Algorithm Library - Simplified Testing
echo ==========================================

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
echo 🚀 Starting simplified testing...
echo.

REM Create a simplified testing script that bypasses version issues
echo # Simplified test runner script > temp_simple_test.gd
echo extends SceneTree >> temp_simple_test.gd
echo. >> temp_simple_test.gd
echo func _ready(): >> temp_simple_test.gd
echo     print("=== SIMPLE ALGORITHM TEST START ===") >> temp_simple_test.gd
echo     print("Godot version: ", Engine.get_version_info()) >> temp_simple_test.gd
echo     print("Platform: ", OS.get_name()) >> temp_simple_test.gd
echo     print("Project path: ", ProjectSettings.globalize_path("res://")) >> temp_simple_test.gd
echo. >> temp_simple_test.gd
echo     # Test algorithms directory >> temp_simple_test.gd
echo     var algorithms_dir = DirAccess.open("res://algorithms/") >> temp_simple_test.gd
echo     if algorithms_dir == null: >> temp_simple_test.gd
echo         print("ERROR: Cannot open algorithms directory") >> temp_simple_test.gd
echo         quit(1) >> temp_simple_test.gd
echo         return >> temp_simple_test.gd
echo. >> temp_simple_test.gd
echo     print("SUCCESS: Algorithms directory found") >> temp_simple_test.gd
echo     var scene_count = count_scenes() >> temp_simple_test.gd
echo     print("Total .tscn files found: ", scene_count) >> temp_simple_test.gd
echo. >> temp_simple_test.gd
echo     # Test loading a few scenes >> temp_simple_test.gd
echo     test_sample_scenes() >> temp_simple_test.gd
echo. >> temp_simple_test.gd
echo func count_scenes(): >> temp_simple_test.gd
echo     var count = 0 >> temp_simple_test.gd
echo     var dir = DirAccess.open("res://algorithms/") >> temp_simple_test.gd
echo     scan_recursive(dir, "res://algorithms/", count) >> temp_simple_test.gd
echo     return count >> temp_simple_test.gd
echo. >> temp_simple_test.gd
echo func scan_recursive(dir, path, count_ref): >> temp_simple_test.gd
echo     if dir == null: >> temp_simple_test.gd
echo         return >> temp_simple_test.gd
echo     dir.list_dir_begin() >> temp_simple_test.gd
echo     var file_name = dir.get_next() >> temp_simple_test.gd
echo     while file_name != "": >> temp_simple_test.gd
echo         if dir.current_is_dir() and not file_name.begins_with("."): >> temp_simple_test.gd
echo             var subdir = DirAccess.open(path + "/" + file_name) >> temp_simple_test.gd
echo             scan_recursive(subdir, path + "/" + file_name, count_ref) >> temp_simple_test.gd
echo         elif file_name.ends_with(".tscn"): >> temp_simple_test.gd
echo             count_ref += 1 >> temp_simple_test.gd
echo         file_name = dir.get_next() >> temp_simple_test.gd
echo. >> temp_simple_test.gd
echo func test_sample_scenes(): >> temp_simple_test.gd
echo     print("Testing sample scenes...") >> temp_simple_test.gd
echo     var test_scenes = [ >> temp_simple_test.gd
echo         "res://algorithms/primitives/arrays_grid_understanding/arrays_grid_understanding.tscn", >> temp_simple_test.gd
echo         "res://algorithms/proceduralaudio/psychoacoustics/psychoacoustics.tscn", >> temp_simple_test.gd
echo         "res://algorithms/randomness/digital_materiality_glitch/digital_materiality_glitch.tscn" >> temp_simple_test.gd
echo     ] >> temp_simple_test.gd
echo. >> temp_simple_test.gd
echo     for scene_path in test_scenes: >> temp_simple_test.gd
echo         print("Testing: ", scene_path) >> temp_simple_test.gd
echo         var scene_resource = load(scene_path) >> temp_simple_test.gd
echo         if scene_resource == null: >> temp_simple_test.gd
echo             print("  ❌ Failed to load: ", scene_path) >> temp_simple_test.gd
echo         else: >> temp_simple_test.gd
echo             print("  ✅ Loaded successfully: ", scene_path) >> temp_simple_test.gd
echo             var instance = scene_resource.instantiate() >> temp_simple_test.gd
echo             if instance: >> temp_simple_test.gd
echo                 print("  ✅ Instantiated successfully") >> temp_simple_test.gd
echo                 if instance.get_script(): >> temp_simple_test.gd
echo                     print("  ✅ Script attached") >> temp_simple_test.gd
echo                 else: >> temp_simple_test.gd
echo                     print("  ⚠️ No script attached") >> temp_simple_test.gd
echo                 instance.queue_free() >> temp_simple_test.gd
echo             else: >> temp_simple_test.gd
echo                 print("  ❌ Failed to instantiate") >> temp_simple_test.gd
echo. >> temp_simple_test.gd
echo     print("=== SIMPLE ALGORITHM TEST END ===") >> temp_simple_test.gd
echo     quit(0) >> temp_simple_test.gd

echo ⏳ Running simplified tests...
echo.

REM Run the simplified test with your specific Godot version
"C:\Users\palle\Desktop\Godot_v4.1.4-stable_win64.exe" --headless --disable-plugins --script temp_simple_test.gd 2>&1

REM Show results
echo.
echo ✅ Simplified testing completed!
echo 📋 Check the output above for results

REM Cleanup
if exist temp_simple_test.gd del temp_simple_test.gd

echo.
echo 🎉 Testing complete!
pause
