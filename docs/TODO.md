# TODO — AdaResearch

## Registry Cleanup (2026-01-30)

### P0: Critical
- [x] Fix placeholder descriptions (description = name) in:
  - `randomness.json` — ✅ 23 entries fixed (2026-01-30)
  - `qfep.json` — ✅ already clean, no placeholders
  - `cellular_automata.json` — ✅ 1 entry fixed (2026-01-30)
  - `soft_bodies.json` — ✅ 2 entries fixed (2026-01-30)
- [x] Mark or remove `status: planned` artifacts in `qfep.json` — ✅ already correct (3 planned items)

### P1: Important  
- [ ] Add consistent metadata across all registries:
  - `dev_themes` — thematic categories
  - `complexity` — beginner/intermediate/advanced/expert
  - `tags` — searchable keywords
- [ ] Align `category` fields with `category_registry.json` canonical categories

### P2: Cleanup
- [ ] Add `sequence` field to all artifacts (which learning sequence they belong to)
- [ ] Document interactions/signals for interactive artifacts
- [ ] Deduplicate `grid_artifacts.json` vs `registry/*.json`:
  - ~736 entries in legacy file
  - ~324 entries in registry files
  - Significant overlap — registry wins on conflict
  - Move unique legacy entries → appropriate registry files
  - Eventually deprecate `grid_artifacts.json`

### P3: Enhancement
- [ ] Write richer descriptions using `foundations.json` as model:
  - `gamwell_reference` — art/math history grounding
  - `qfep_connection` — theoretical tie-in
  - `signals`, `interactions`, `parameters` documentation

---

## Registry Stats (2026-01-30)

| File | Artifacts | Quality |
|------|-----------|---------|
| grid_artifacts.json | ~736 | Legacy bloat |
| arrays.json | 26 | ✅ Good |
| cellular_automata.json | 39 | Mixed |
| foundations.json | 6 | ✅ Exemplary |
| furniture.json | 28 | ✅ Good |
| lsystems.json | 5 | ✅ Clean |
| qfep.json | 35 | Many planned |
| randomness.json | 96 | Needs work |
| script_runner.json | 1 | ✅ Good |
| soft_bodies.json | 15 | Mixed |
| wavefunctions.json | 73 | Mixed |

---

## Documentation

### P0: Critical
- [ ] Update `README.md`
  - Add QFEP / theoretical framework
  - Add map sequences / learning progression
  - Add artifact system overview
  - Link to Claude guides

### P1: Important
- [ ] Maintain `CLAUDE_GUIDE_TO_PLAYING_ADA_RESEARCH.md`
  - Keep in sync with project changes
  - Update map sequences and file paths
  - Add new systems as they're built
- [ ] Maintain `doc/CLAUDE_PROJECT_NAVIGATOR.md`
  - Project vision and QFEP theory
  - Folder structure and architecture
  - Navigation patterns for AI agents

### P2: Cleanup
- [ ] Document system architecture
  - Core systems (grid, artifacts, sequences)
  - Player systems (XR, movement, interaction)
  - Data flow diagrams
- [ ] Document scenes
  - Map structure and conventions
  - Scene hierarchy patterns
  - Common node setups

### P3: Enhancement
- [ ] Add comments, READMEs, and markdown docs where needed
  - Script headers explaining purpose
  - README.md per major folder
  - Inline comments for complex logic

---

## Code Quality

- [ ] Review scripts for potential improvements
  - Refactoring opportunities
  - Performance bottlenecks
  - Dead code removal
  - Consistent naming conventions

---

## Playtesting

- [ ] Playtest and list improvements
  - UX pain points
  - Bugs and glitches
  - Difficulty/pacing issues
  - VR comfort (motion sickness, scale)
  - Missing feedback/affordances

