# Simplified test runner script 
extends SceneTree 
 
func _ready(): 
    print("=== SIMPLE ALGORITHM TEST START ===") 
    print("Godot version: ", Engine.get_version_info()) 
    print("Platform: ", OS.get_name()) 
    print("Project path: ", ProjectSettings.globalize_path("res://")) 
 
    # Test algorithms directory 
    var algorithms_dir = DirAccess.open("res://algorithms/") 
    if algorithms_dir == null: 
        print("ERROR: Cannot open algorithms directory") 
        quit(1) 
        return 
 
    print("SUCCESS: Algorithms directory found") 
    var scene_count = count_scenes() 
    print("Total .tscn files found: ", scene_count) 
 
    # Test loading a few scenes 
    test_sample_scenes() 
 
func count_scenes(): 
    var count = 0 
    var dir = DirAccess.open("res://algorithms/") 
    scan_recursive(dir, "res://algorithms/", count) 
    return count 
 
func scan_recursive(dir, path, count_ref): 
    if dir == null: 
        return 
    dir.list_dir_begin() 
    var file_name = dir.get_next() 
    while file_name != "": 
        if dir.current_is_dir() and not file_name.begins_with("."): 
            var subdir = DirAccess.open(path + "/" + file_name) 
            scan_recursive(subdir, path + "/" + file_name, count_ref) 
        elif file_name.ends_with(".tscn"): 
            count_ref += 1 
        file_name = dir.get_next() 
 
func test_sample_scenes(): 
    print("Testing sample scenes...") 
    var test_scenes = [ 
        "res://algorithms/primitives/arrays_grid_understanding/arrays_grid_understanding.tscn", 
        "res://algorithms/proceduralaudio/psychoacoustics/psychoacoustics.tscn", 
        "res://algorithms/randomness/digital_materiality_glitch/digital_materiality_glitch.tscn" 
    ] 
 
    for scene_path in test_scenes: 
        print("Testing: ", scene_path) 
        var scene_resource = load(scene_path) 
        if scene_resource == null: 
            print("  ❌ Failed to load: ", scene_path) 
        else: 
            print("  ✅ Loaded successfully: ", scene_path) 
            var instance = scene_resource.instantiate() 
            if instance: 
                print("  ✅ Instantiated successfully") 
                if instance.get_script(): 
                    print("  ✅ Script attached") 
                else: 
                    print("  ⚠️ No script attached") 
                instance.queue_free() 
            else: 
                print("  ❌ Failed to instantiate") 
 
    print("=== SIMPLE ALGORITHM TEST END ===") 
    quit(0) 
