# Artifact Catalog UI

2D UI components for the artifact catalog system, providing the tree browser, filter controls, detail preview panel, and main controller that coordinates them.

## How It Works

ArtifactCatalogUI is the main controller that wires together ArtifactFilters (theme, complexity, sequence, and text search dropdowns), ArtifactBrowser (a Tree widget grouping artifacts by scene folder), and ArtifactPreview (detail panel with name, description, metadata, lock status, and spawn button). When filters change, the browser repopulates; when an artifact is selected, the preview updates and a spawn request is emitted. The UI also includes a comment panel for writing feedback that is saved to `desktop_feedback.md`.

## Features

- Tree-based artifact browser grouped by scene folder with collapsible sections
- Multi-criteria filtering: theme, complexity, sequence, and free-text search
- Detail preview showing name, description, tags, themes, complexity, and lock status
- Spawn button with progression-aware lock checking
- Comment writing panel with artifact token insertion and file-based persistence
- Auto-refresh on GridSystem map_generation_complete signal
- Next-artifact keyboard navigation

## Files

- `ArtifactBrowser.gd` -- Tree widget for browsing artifacts grouped by scene folder
- `ArtifactCatalogUI.gd` -- Main UI controller coordinating filters, browser, and preview
- `ArtifactCatalogUI.tscn` -- Scene layout for the catalog UI
- `ArtifactFilters.gd` -- Filter controls with theme, complexity, sequence, and search
- `ArtifactPreview.gd` -- Preview panel showing artifact details and spawn button
