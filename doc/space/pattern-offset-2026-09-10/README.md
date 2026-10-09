# Pattern Foundry: surface offset

2026-09-10

OFFSET +5CM advances source sampling along each sheet's U coordinate in five-centimetre steps from zero to thirty, then wraps to zero. It preserves the motif, repeat spacing, receiving geometry and historical carpet. Positive U is a texture address, not a museum compass direction.

Live receivers follow the source; held receivers retain their image, repeat and offset. Relink and undo restore the appropriate state. Source recipes save the offset; older recipes default to zero. At a 30 cm p1 repeat, offsets zero and thirty produce equal images despite distinct stored state.

The eight-button console was widened to 2.6 m. The book, tutorial, technical account, critical text, intent, summary and public guide describe the implemented experiment. Next is explicit held-hand control, including release and tracking-loss handling; garment transfer and shaders remain later work.

Validation: 99 checks pass in the actual desktop museum, including pointer press/release, exact five-pixel shift at 100 pixels/metre, held offsets, save/restore, invalid and legacy imports, full-period recurrence, undo, unchanged geometry and neighbouring loom. Fresh console and wall captures were inspected. No headset test has been performed.

During validation, Godot's class cache resolved live classes to archived before-snapshots. Added .gdignore to the nine doc/space before-directories containing GDScript snapshots, and refreshed the editor cache. Live GridInteractablesComponent and PatternMachineA paths now resolve correctly. Archived source remains available for comparison.

Evidence: doc/research/possible-bodies/pattern-recipe-check.json and the four pattern museum captures; verification.json records source hashes. The before/ directory preserves this step's input files.
