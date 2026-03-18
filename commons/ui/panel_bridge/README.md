# Panel Bridge

JSON-driven VR panel system that loads layout definitions and data files, then spawns interactive 2D UI panels rendered in 3D via XRTools Viewport2DIn3D. Supports loom simulators, pattern makers, and grid editors.

## How It Works

`PanelBridgeLoader` reads a layout JSON (defining panel dimensions, roles, and widget elements) and an optional data JSON (containing domain-specific content). It branches on the page type -- `loom_simulator`, `pattern_maker`, or `grid_editor` -- to build the appropriate data model, spawns `VRPanelInstance` nodes for each panel, arranges them in an arc layout at comfortable VR reading distance, and wires cross-panel operations (e.g., connecting operation bars to data stores).

## Files

- `panel_bridge_loader.gd` -- Orchestrator. Loads layout + data JSON, spawns panels, positions them in an arc, wires operations.
- `vr_panel_instance.gd` -- Wraps XRToolsViewport2DIn3D and injects dynamically-built panel content into its SubViewport.
- `panel_content_builder.gd` -- Builds 2D Control trees from panel element definitions (grids, labels, operation bars).
- `draft_data_store.gd` -- Data model for loom simulator pages. Stores binary threading/treadling/tie-up matrices.
- `binary_grid_widget.gd` -- Interactive binary matrix widget for loom draft editing.
- `color_grid_widget.gd` -- Color-indexed grid widget for pattern maker and grid editor pages.
- `drawdown_widget.gd` -- Read-only drawdown preview computed from loom draft data.
- `operations_bar_widget.gd` -- Toolbar widget with operation buttons (clear, randomize, shift, rotate).
- `test_panel_bridge.gd` -- Test harness for loading and displaying panel bridge configurations.
