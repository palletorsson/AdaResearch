# Explicit studio surface ownership

2026-09-10. User approved continuing the workshop connection.

Added studio_surface_controls.gd: a separate six-button surface selector, confined to the same SimGrid hall. PREV/NEXT select WALL/NORTH/EAST/FLAT/CURVE/ARCHITECTURE/ALL FIVE; APPLY LIVE, HOLD, UNDO LINK and LOOM control registered receivers.

RecipeStudy now owns a shared 16-transaction receiver history. A snapshot contains material, source weak reference, linked state and accepted spacing/offset. External studio sources update their live receivers only. Held images and owner identity survive undo. Returning to the loom is explicit. A departing source freezes the last image. Studio history and local package save remain separate.

The shader receives an optional surface_metres UV multiplier (default one, preserving existing callers). The adapter maps a normalized square to 1.2 m and creates a local two-sided shader variant for the existing two-sided sheets. Receiving geometry, UV arrays and collision do not change. No avatar or other hall is searched. Panel Bridge's loom, colour-grid and facade/composition adapters remain further work.

Validation: 72 studio/adapter museum checks, plus the 99 existing Foundry checks. Checks include real pointer application, independent sources, held material/image stability, mixed-owner group undo, invalid-target atomicity, source departure, owner labels and clear reachable surface-panel controls. Captures show the actual museum. Headset interaction and performance remain untested.

Updated book passage, technical text and public workshop/sequence guide. Before snapshots excluded from Godot import. Existing unrelated missing UID warning remains. No commits.
