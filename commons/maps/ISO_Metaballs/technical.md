# ISO_Metaballs technical

The map preserves the original 18 × 17 structure at offset (6, 7) inside a longer 30 × 32 museum room. `metaball_world` is the single book-primary field; `raymarched_metaballs`, `nakama_metaballs` and `metaballs` remain secondary comparisons. `iso_metaball_console` is a decoration and forwards no field state of its own.

The console binds the `MetaballGenerator` child of `metaball_world`. EMPLACE cycles the exported `emplacement` enum; KERNEL cycles `kernel`; both call the generator's guarded `apply_grid_config`. HOLD duplicates the current ArrayMesh as a visible earlier boundary. RESET returns the shipped column/inverse-square pair. Controls use the project's pointer-aware push buttons and forgiving touch volumes.
