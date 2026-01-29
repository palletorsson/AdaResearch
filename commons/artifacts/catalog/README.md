# Artifact Catalog System

## Overview

The Artifact Catalog System is a dual-mode (VR + Desktop) browser for spawning and managing artifacts in AdaResearch. It provides:

- **VR Kiosk**: Physical catalog station in the Lab at coordinates [6,5]
- **Desktop Overlay**: Fullscreen UI toggled with Tab key
- **Theme-based filtering**: Browse 318+ artifacts across 10 thematic categories
- **Progression integration**: Artifacts unlock as sequences are completed
- **Beam spawn effects**: Elastic scale-up animation when spawning

## Architecture

```
ArtifactCatalogSystem
├── Data Layer
│   ├── ArtifactCatalogDataProvider.gd (queries registries, filters artifacts)
│   └── ArtifactThemeQuery.gd (theme/complexity indexing - already exists)
│
├── UI Layer (2D - shared by VR and desktop)
│   ├── ArtifactCatalogUI.tscn/gd (main controller)
│   ├── ArtifactBrowser.gd (tree widget with collapsible categories)
│   ├── ArtifactPreview.gd (preview panel with metadata)
│   └── ArtifactFilters.gd (theme, complexity, search filters)
│
├── VR Interface
│   └── ArtifactCatalogTablet3D.tscn/gd (Node3D with Viewport2Din3D)
│
├── Desktop Interface
│   └── DesktopArtifactCatalog.tscn/gd (CanvasLayer overlay)
│
└── Spawn Manager
    └── ArtifactSpawnManager.gd (instantiation + beam effects)
```

## Files Created

### Core Components
- `commons/artifacts/catalog/ArtifactCatalogDataProvider.gd` - Data provider for registry queries
- `commons/artifacts/catalog/ArtifactSpawnManager.gd` - Handles artifact instantiation and effects

### UI Components
- `commons/artifacts/catalog/ui/ArtifactCatalogUI.tscn` - Main 2D interface
- `commons/artifacts/catalog/ui/ArtifactCatalogUI.gd` - UI controller
- `commons/artifacts/catalog/ui/ArtifactBrowser.gd` - Tree browser widget
- `commons/artifacts/catalog/ui/ArtifactPreview.gd` - Artifact detail panel
- `commons/artifacts/catalog/ui/ArtifactFilters.gd` - Filter controls

### VR/Desktop Wrappers
- `commons/artifacts/catalog/ArtifactCatalogTablet3D.tscn` - VR kiosk scene
- `commons/artifacts/catalog/ArtifactCatalogTablet3D.gd` - VR kiosk script
- `commons/artifacts/catalog/DesktopArtifactCatalog.tscn` - Desktop overlay scene
- `commons/artifacts/catalog/DesktopArtifactCatalog.gd` - Desktop overlay script

## Files Modified

- `commons/maps/Lab/map_data.json` - Added catalog kiosk at [6,5], added furniture.json registry
- `commons/artifacts/registry/furniture.json` - Added artifact_catalog_kiosk definition
- `commons/scenes/LabGridSystem.gd` - Added spawn manager and desktop catalog integration
- `project.godot` - Added `toggle_artifact_catalog` input action (Tab key)

## Usage

### Desktop Mode
1. Launch the game in desktop mode
2. Load the Lab map
3. Press **Tab** to open the artifact catalog
4. Use filters to browse by theme/complexity
5. Use search box to find specific artifacts
6. Click an artifact to preview
7. Click "Spawn Artifact" to instantiate it
8. Press **Tab** again to close catalog

### VR Mode
1. Launch the game in VR mode
2. Teleport to the Lab
3. Find the catalog kiosk next to the world map (coordinates [6,5])
4. Use VR pointer to interact with the UI
5. Browse, filter, and select artifacts
6. Click "Spawn Artifact" to instantiate
7. Artifact spawns 2m in front of your VR camera

## Features

### Filtering System
- **Theme Filter**: Filter by 10 themes (primitives, audio, physics, procedural, emergence, qfep, waves, philosophy, puzzles, tools)
- **Complexity Filter**: Filter by difficulty (beginner, intermediate, advanced, expert)
- **Search**: Text search across artifact names, descriptions, lookup_names, and tags
- **Collapsible Categories**: Tree view groups artifacts by theme

### Progression System
- **Dev Mode**: All artifacts unlocked when `OS.is_debug_build()` returns true
- **Player Mode**: Artifacts unlock as sequences are completed
- **Lock Indicators**: Locked artifacts shown with 🔒 icon and grayed out
- **Stats Display**: Shows "X / Y Unlocked" in header (player mode) or "All Unlocked (Dev Mode)"

### Spawn System
- **Fixed Location**: Artifacts spawn at consistent position (2m in front of camera/spawn point)
- **Beam Effect**: Elastic scale-up animation with 360° rotation
- **Previous Cleanup**: Old artifact automatically removed before spawning new one
- **Transform Application**: Respects scale and rotation from artifact definition

## Testing Steps

### Phase 1: Data Provider
```gdscript
# In Godot script console:
var provider = ArtifactCatalogDataProvider.new()
print("Total artifacts: %d" % provider.get_total_artifact_count())
print("Audio artifacts: %d" % provider.get_artifacts_by_theme("audio").size())
print("Beginner artifacts: %d" % provider.get_artifacts_by_complexity("beginner").size())
```

### Phase 2: UI Components
1. Open `ArtifactCatalogUI.tscn` in Godot editor
2. Run scene (F6)
3. Verify tree populates with categories
4. Test theme filter dropdown
5. Test complexity filter dropdown
6. Test search box filtering
7. Click artifacts and verify preview updates
8. Verify spawn button enables/disables based on selection

### Phase 3: Spawn Manager
```gdscript
# Test spawning:
var manager = ArtifactSpawnManager.new()
get_tree().current_scene.add_child(manager)
manager.spawn_artifact("rotating_cube")
# Verify artifact appears with beam effect
```

### Phase 4: VR Kiosk
1. Launch in VR mode
2. Load Lab map
3. Look for catalog kiosk at [6,5] (next to world map)
4. Point VR controller at kiosk screen
5. Test clicking categories in tree
6. Test scrolling through artifacts
7. Test spawning - artifact should appear 2m in front
8. Verify beam effect plays

### Phase 5: Desktop Overlay
1. Launch in desktop mode
2. Load Lab map
3. Press **Tab** key
4. Verify catalog opens fullscreen
5. Verify game pauses when catalog is open
6. Browse and spawn an artifact
7. Verify catalog closes after spawn
8. Verify game unpauses
9. Press **Tab** to reopen catalog

### Phase 6: Progression Integration
1. **Test with fresh save**:
   - Start new game
   - Open catalog
   - Verify most artifacts are locked (🔒 icon)
   - Complete a sequence
   - Return to catalog
   - Verify unlocked artifacts now accessible

2. **Test dev mode**:
   - Run in debug build (`OS.is_debug_build()` true)
   - Open catalog
   - Verify all artifacts unlocked
   - Verify header shows "Dev Mode - All Unlocked"

### Phase 7: Full Integration Test
1. **VR Full Test**:
   - Browse all 10 themes
   - Spawn 5 different artifacts
   - Verify each spawns correctly with beam effect
   - Check for performance issues

2. **Desktop Full Test**:
   - Press Tab to open catalog
   - Test search: type "audio", verify only audio artifacts shown
   - Test filters: select "beginner", verify filtering
   - Spawn multiple artifacts
   - Verify each previous artifact is cleaned up

3. **Performance Test**:
   - Open catalog
   - Scroll through all categories (should be ~318 artifacts)
   - Check FPS/responsiveness
   - Look for console errors

## Known Limitations

1. **Single spawn location**: Artifacts spawn at fixed location, may overlap if spawning multiple
2. **No favorites**: Can't mark artifacts as favorites yet
3. **Basic beam effect**: Currently uses tween animation, could be upgraded to GPUParticles3D
4. **No sound effects**: Spawn and UI interactions are silent
5. **Basic UI styling**: Uses default Godot Control theme

## Future Enhancements

1. **Enhanced beam effect**: Replace tween with GPUParticles3D for more dramatic spawn
2. **Sound effects**: Add whoosh for spawn, clicks for UI interactions
3. **Favorites system**: Allow marking artifacts for quick access
4. **Spawn history**: Show recently spawned artifacts
5. **Grid spawn layout**: Spawn multiple artifacts in organized grid
6. **Custom spawn location**: Allow dragging spawn preview to choose position
7. **Thumbnail previews**: Show small 3D preview of artifact in UI
8. **Advanced sorting**: Sort by date added, popularity, etc.

## Troubleshooting

### Catalog kiosk not appearing in Lab
- Check `commons/maps/Lab/map_data.json` line 48 - should have `artifact_catalog_kiosk:180:0.2:2`
- Verify `furniture.json` is in artifact_registries array (line 56)
- Check console for loading errors

### Tab key not working in desktop mode
- Verify `project.godot` has `toggle_artifact_catalog` input action with keycode 4194306
- Check console for DesktopArtifactCatalog initialization message
- Verify LabGridSystem is initializing catalog system

### Artifacts not spawning
- Check console for spawn_failed errors
- Verify ArtifactSpawnManager is initialized in LabGridSystem
- Check artifact scene path exists in registry
- Verify GridInteractablesComponent is loaded

### Locked artifacts in dev mode
- Verify `OS.is_debug_build()` returns true
- Check ArtifactCatalogDataProvider.is_artifact_unlocked() logic
- Force export as debug build in Godot export settings

### VR pointer not working on kiosk
- Verify XRToolsViewport2Din3D is properly configured
- Check collision shape exists on kiosk
- Verify kiosk is on correct physics layer (layer_21 "Pointable Objects")
- Test with AudioCatalogTablet3D as reference

## API Reference

### ArtifactCatalogDataProvider

```gdscript
# Get all artifacts
var all = ArtifactCatalogDataProvider.get_all_artifacts()

# Filter by theme
var audio = ArtifactCatalogDataProvider.get_artifacts_by_theme("audio")

# Filter by complexity
var beginner = ArtifactCatalogDataProvider.get_artifacts_by_complexity("beginner")

# Multi-criteria filtering
var filtered = ArtifactCatalogDataProvider.get_filtered_artifacts("qfep", "advanced", "entropy")

# Check unlock status
var unlocked = ArtifactCatalogDataProvider.is_artifact_unlocked("lambda_slider")

# Get stats
var total = ArtifactCatalogDataProvider.get_total_artifact_count()
var unlocked_count = ArtifactCatalogDataProvider.get_unlocked_artifact_count()
```

### ArtifactSpawnManager

```gdscript
# Spawn artifact
var success = spawn_manager.spawn_artifact("rotating_cube")

# Get currently spawned artifact
var current = spawn_manager.get_spawned_artifact()

# Clear spawned artifact
spawn_manager.clear_spawned_artifact()

# Signals
spawn_manager.artifact_spawned.connect(func(lookup_name, artifact):
    print("Spawned: ", lookup_name)
)
spawn_manager.spawn_failed.connect(func(lookup_name, error):
    print("Failed: ", error)
)
```

### DesktopArtifactCatalog

```gdscript
# Open catalog
desktop_catalog.open()

# Close catalog
desktop_catalog.close()

# Toggle catalog
desktop_catalog.toggle()

# Check if open
var is_open = desktop_catalog.is_open()

# Refresh catalog
desktop_catalog.refresh()
```

## Credits

- **Pattern**: Based on AudioCatalogTablet3D architecture
- **Theme System**: Built on ArtifactThemeQuery utility
- **Integration**: LabGridSystem progression system
- **XR**: Uses godot-xr-tools Viewport2Din3D for VR embedding

## License

Part of AdaResearch project.
