# Scenes

Core scene infrastructure for Ada Research. Contains base scenes, grid scenes, lab scenes, desktop testing, VR staging, the landscape endgame, and supporting systems like the camera tour and main menu.

## How It Works

Scenes are layered on top of XRToolsSceneBase (via `base.tscn`) to preserve VR functionality while adding project-specific systems like GridSystem, SceneManager, and lab progression. The VR staging system (`vrStaging.gd`) manages scene loading with loading screens and fade transitions. Desktop variants replace XR input with keyboard/mouse controls for rapid testing without a headset.

## Scene Types

- **Base** -- `base.tscn` + `BaseSceneAddon.gd` -- Foundation scene that registers the XR player with GameManager and initializes SceneManager
- **Grid** -- `grid.tscn` + `GridScene.gd` -- Standard map scene that connects GridSystem to SceneManager, spawns entry geometry, and handles sequence progression
- **Lab** -- `lab.tscn` + `LabGridScene.gd` + `LabGridSystem.gd` -- Hub scene with progressive map support, lab-specific styling (off-white cubes, cool lighting), and artifact catalog system
- **Landscape** -- `landscape.tscn` + `LandscapeScene.gd` -- Endgame open world with procedural terrain, curated creatures, botanical gardens, QFEP formula, and a return portal
- **Desktop Lab** -- `lab_desktop.tscn` + `DesktopLabManager.gd` -- Desktop-mode lab for testing sequences with keyboard navigation (N/P/R keys)
- **Desktop Map Tester** -- `desktop_map_tester.tscn` + `DesktopMapTester.gd` -- Quick desktop map loading with game mode controls (F1-F6)
- **Desktop Player** -- `desktop_player.tscn` + `DesktopPlayer.gd` -- First-person CharacterBody3D with mouse look, WASD movement, and raycast interaction
- **VR Staging** -- `vr_staging.tscn` + `vrStaging.gd` -- Root VR entry point extending XRToolsStaging with loading screens, menu integration, and scene switching
- **Camera Tour** -- `camera_tour.tscn` + `CameraTourManager.gd` -- Automated flythrough of all maps in curriculum spine order with speed/pause/skip controls

## Files

- `BaseSceneAddon.gd` -- Initializes SceneManager and registers the XR player with GameManager
- `GridScene.gd` -- Connects GridSystem to SceneManager, spawns entry geometry, handles sequence flow
- `LabGridScene.gd` -- Progressive lab scene with map override resolution from multiple data sources
- `LabGridSystem.gd` -- GridSystem subclass with lab styling, progressive map detection, and artifact catalog
- `LandscapeScene.gd` -- Endgame vista with terrain, creatures, flowers, QFEP formula, and portals
- `DesktopLabManager.gd` -- Desktop sequence navigation respecting game modes (Story/Test/Explorer/TestPlus)
- `DesktopMapTester.gd` -- Standalone desktop map loader with PageUp/Down navigation
- `DesktopPlayer.gd` -- First-person controller with mouse look, gravity, sprint, and interaction raycast
- `ResetArea.gd` -- Area3D that catches falling players and resets them to a safe position
- `CameraTourManager.gd` -- Automated camera tour through curriculum spine with waypoint generation
- `SequelHookCinematic.gd` -- End-of-game cinematic: fog, ascent, cosmos reveal, title cards, fade to black
- `vrLabScene.gd` -- Legacy VR lab scene managing grid system initialization
- `vrStaging.gd` -- VR staging system with threaded scene loading, loading screens, and map loader kiosk spawning
- `env.gd` -- VR environment setup with themed lighting, rainbow sky shader, particles, and performance monitoring
