# Chapter 7 (Cellular Automata) VR Translation Notes

## Example: 7_1_elementary_wolfram_ca
- **2D focus**: 1D binary cellular automaton generating rule-based patterns.
- **VR fish tank layout**: Mount a vertical ribbon surface across the tank; rows scroll upward while the newest row forms near the base.
- **Light pink palette**: Active cells glow medium pink; inactive cells fade to translucent white.
- **Line-derived controller**: Slider selects CA rule number (0–255) with click zones snapping to discrete values.
- **Testing notes**: Confirm rule evolution maps correctly to 3D grid instances and sustains 90 FPS during long sequences.

## Example: 7_2_game_of_life
- **2D focus**: Conway’s Game of Life using random initial population.
- **VR fish tank layout**: Project a 20×20 tile plane floating mid-tank; cells rise slightly when alive to reinforce state.
- **Light pink palette**: Alive cells emit soft pink light; dead cells remain nearly transparent.
- **Line-derived controller**: Slider toggles simulation speed; button derived from line primitive restarts with new seed.
- **Testing notes**: Verify neighbor counting in 3D grid and ensure plane fits entirely inside fish tank without clipping.

## Example: 7_3_game_of_life_oop
- **2D focus**: OOP refactor of Game of Life featuring Cell class.
- **VR fish tank layout**: Similar 20×20 plane but with per-cell mesh nodes referencing Cell objects for modular behaviors.
- **Light pink palette**: Alive cells swap to accent pink with emissive hatch lines.
- **Line-derived controller**: Slider adjusts survival/birth thresholds dynamically for experimentation.
- **Testing notes**: Confirm Cell class updates propagate to mesh material changes and maintain performance.

## Example: exercise_7_8_hexagon_ca
- **2D focus**: Hexagonal CA with oscillatory coloring and randomness.
- **VR fish tank layout**: Arrange hexagonal tiles on a tilted plane within the tank, slightly offset in height to emphasize geometry.
- **Light pink palette**: Use gradient pink transitions around hex edges to highlight neighbor interactions.
- **Line-derived controller**: Two sliders: one for oscillation rate, one for random mutation chance.
- **Testing notes**: Validate hex-grid neighbor indexing in 3D and keep draw calls optimized via instancing.
