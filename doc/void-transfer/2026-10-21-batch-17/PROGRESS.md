# Batch 17 completed

Pattern Foundry (Codex,17) and Tutorial Pattern (Claude Opus,12) transferred to tiling_02. Claude source and dependency review checked. 147 source / 227 native / 32 editor checks passed; 64 real models exported. Standard 42x32x6 floors retained, both shafts clear. Mouse and synthetic tracked XR tested, physical headset pending. Source scenes/scripts and chapter texts unchanged; curation deferred.

Editor: http://localhost:3003/lab-editor?mode=void&trial=tiling_02&floor=1
Review: http://localhost:3003/book-review/doc/book/iterations/2026-10-21-void-transfer-batch-17/index.html

See coordinator HANDOFF.md and source worker fragments in commons/void/trials/tiling_02. Shared adapters are in commons/void: pattern_architecture_receiver.gd, pattern_tile_desktop_hook.gd (shared carry, despite its historical filename), floor_grid_model.gd, pattern_loom_panels.gd. GPU runs serial.

Next untransferred Tiling pair: ArrayPatterns and SymmetrySeventeen; verify current sequence inventory before next batch. Claude should work directly on one floor, without a separate multi-reader workflow.
