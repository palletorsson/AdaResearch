# InfoBoard Base Classes

Base infrastructure for the handheld 3D info board system.

## Key Files
- `AlgorithmInfoBoardBase.gd` — Base controller (extends Control) for all boards; manages page navigation, content display, visualization switching; page structure supports title, text, visualization, code blocks, axioms, poetics
- `AlgorithmVisualizationBase.gd` — Base class for all board visualizations; provides animation controls, drawing helpers, periodic updates, reset mechanism
- `UniversalInfoBoard.gd` — Template that loads content from JSON; three display modes: `SINGLE_SLIDE`, `SINGLE_BOARD`, `ALL_SLIDES`
- `VRInfoBoardInput.gd` — VR controller input handler for scrolling text, with haptic feedback and trigger sensitivity
- `ViewClearanceZone.gd` — Area3D that hides a lid mesh when the player enters the viewing zone in front of a board
- `HandheldInfoBoard.tscn` — 3D handheld tablet scene with Viewport2DIn3D, frame, interaction area, and ViewClearanceZone
- `InfoBoardUI.tscn` — Base 2D UI layout with title bar, navigation buttons, content area, and visualization container
- `UniversalInfoBoard.tscn` — Universal 2D template with split layout (left text, right visualization)

## Architecture

Three-level nesting:
1. **3D layer** — `HandheldInfoBoard.tscn` provides the physical grabbable tablet
2. **2D UI layer** — Board-specific script or `UniversalInfoBoard.gd` manages content and navigation
3. **Visualization layer** — `AlgorithmVisualizationBase` subclasses draw animated algorithm graphics

## Used By
All board scenes under `boards/` inherit from these base classes.
