# Artifact Catalog

Complete artifact browsing and spawning system with support for desktop, VR tablet, and standalone 3D preview modes. Provides data access, filtering, spawning with beam effects, and a desktop sidebar with comment writing.

## How It Works

ArtifactCatalogDataProvider loads artifact definitions from the modular JSON registry files (or falls back to standalone file loading when GridSystem is unavailable). It normalizes entries, validates scene paths, and substitutes placeholders for missing scenes. The catalog supports multiple front-ends: a desktop overlay (DesktopArtifactCatalog) with fullscreen UI, a standalone 3D viewer (ArtifactCatalogDesktop3D) with orbit camera, a VR tablet kiosk (ArtifactCatalogTablet3D) using Viewport2Din3D, and a sidebar switcher (DesktopArtifactSwitcherOverlay) with collapsible sequence groups and a comment writer panel. ArtifactSpawnManager handles instantiation with elastic scale-up beam effects.

## Features

- Multi-source registry loading: GridInteractablesComponent registry or standalone JSON files
- Placeholder system for missing or invalid scene paths with diagnostic reporting
- Filtering by theme, complexity, category, sequence, and text search via ArtifactThemeQuery
- Progression-aware unlock checking through LabGridSystem
- Desktop overlay catalog with Tab-key toggle and game pausing
- Standalone 3D preview with orbit camera (yaw/pitch/zoom/pan), auto-rotation, and AABB-based framing
- VR tablet kiosk embedding 2D UI in 3D space
- Desktop sidebar with collapsible sequence sections, filter, and persistent state
- Comment writer panel that saves timestamped feedback to desktop_feedback.md
- Claude Bridge integration for sending artifact selection events to local AI sessions
- Artifact spawning with beam effects (elastic scale-up + rotation animation)

## Files

- `ArtifactCatalogDataProvider.gd` -- Static data provider: registry loading, filtering, placeholder coercion
- `ArtifactCatalogDesktop3D.gd` -- Standalone 3D artifact viewer with orbit camera
- `ArtifactCatalogDesktop3D.tscn` -- Scene for standalone desktop 3D catalog
- `ArtifactCatalogTablet3D.gd` -- VR kiosk embedding 2D catalog in 3D via Viewport2Din3D
- `ArtifactCatalogTablet3D.tscn` -- Scene for VR tablet catalog
- `ArtifactSpawnManager.gd` -- Spawning with position calculation, validation, and beam effects
- `DesktopArtifactCatalog.gd` -- Fullscreen desktop overlay with Tab toggle and spawn integration
- `DesktopArtifactCatalog.tscn` -- Scene for desktop overlay catalog
- `DesktopArtifactSwitcherOverlay.gd` -- Sidebar with collapsible sequence groups, filter, and comment writer
