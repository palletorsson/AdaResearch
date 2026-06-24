# The Curation Rule

> Learned from the `curation_station` work (`commons/artifacts/station/`). A general rule for **all** text, artifacts, and visualizations in the project.

## The Rule (one sentence)

**Every piece presents itself: its words become framed, surface-pinned 2D-in-3D text; its size dictates its form (small → plinth, large → platform + bridge, empty → framed void); and it joins one Dieter-Rams visual family as a DNA-driven prop — so the whole project reads as a single curated station where presentation is itself an argument made with placement.**

---

## Sub-principles

### 1. Text is framed and surface-pinned, never floating
Words live **on a surface** as `BakedTextAlbedo` 2D-in-3D plates (frame + dark/light face + header + lines), pinned flat to a wall, plinth caption, or screen. A piece's own text is **harvested** into a framed panel above it and joined to it by a **connector line** (`with_text_frames`, `_build_text_frame`). Floating billboard `Label3D` chrome is suppressed (`hide_floating_labels`); only surface-baked text survives. *A place that presents must also explain — in plain pinned words.*

### 2. Size drives form
The artifact's measured footprint chooses its body:
- **Small** (≤ `large_cells`, footprint 1–3 cells) → a **plinth** that lifts it to hand height. *A vector on the ground is litter; the same vector at hand height on a lit plinth is an instrument.*
- **Large** (> `large_cells`) → a forward **platform + bridge** (n-size, sized to the artifact, capped at `max_platform_cells`), walked out to from the bay.
- The reach decision (`top_height`) and footprint (`width_cells × depth_cells`) are the load-bearing parameters. **How a thing meets the floor is part of what the thing IS.**

### 3. Negative space is framed on purpose
An empty slot is not absent — it becomes a **framed void** (`frame_voids`), an open portal frame around pure negative space. Large open/lattice artifacts get the same treatment (`frame_large`): a portal frame around the artifact **and** the space it sits in. Absence is presented, not hidden.

### 4. A piece becomes DNA
Every prop is a full DNA artifact, not a static mesh:
- `@export_group` genes for every trait (Grid / Dimensions / Style / Surface / Color / Content) — fully sweepable.
- An `@identity` block (essence / desire / critical_parameter / triggers / emerges / needs / relationships / truth).
- Lifecycle `_ready → _read_metadata_overrides → _build`, plus `apply_grid_config()` that re-reads meta and rebuilds.
- Reference implementations: `hangar_podium.gd`, `station_plinth.gd`, `station_panel.gd`, `station_cabinet.gd`.

### 5. One shared visual language (Dieter Rams / Braun)
Everything goes through `HangarKit` so the family reads as one set: light matte housing that **recedes** so the artifact is the expressive thing, one warm accent (`BRAUN_ACCENT`), a calm anthracite display, functional dark type, subtle wear (not heavy grime). Grid-modular pieces tile cell-to-cell (`width_cells`, 1 m `CELL`). One alternate finish (`"terminal"`) exists as a DNA choice, not a free-for-all. *Less, but better.*

---

## Checklist — apply to any artifact

- [ ] **Text on a surface?** All words are `BakedTextAlbedo` plates pinned to a frame/wall/face — no floating `Label3D` billboards in the presented view.
- [ ] **Text harvested + connected?** The piece's own text appears in a framed panel joined by a connector line, not just hovering near it.
- [ ] **Form matches size?** Small → plinth at reach height; large → platform + bridge sized to the real footprint; footprint measured (AABB), not guessed.
- [ ] **Void framed?** Empty/absent slots and open-lattice negative space are wrapped in a portal frame, presented on purpose.
- [ ] **Full DNA?** `@export_group` genes for every trait + `@identity` block + `_ready → _read_metadata_overrides → _build` + `apply_grid_config()`.
- [ ] **Rams family?** Routes color/material through `HangarKit`; housing recedes, one warm accent, subtle wear; grid-modular pieces tile on the 1 m cell.
- [ ] **Presentation is an argument?** The placement says *why these belong together, here, on purpose* — measured, repeatable, buildable on grid lines.

---

## Candidate artifacts to apply it to next

From the discovery inventory — pieces that are partial or off-pattern:

| Artifact | File | Gap to close |
|---|---|---|
| `soft_stage_dashboard` | `commons/artifacts/soft_stage_dashboard/soft_stage_dashboard.gd` | **PARTIAL DNA.** Has `_ready → _build` + `@identity` + signal-driven `Label3D` refresh, but lacks full `@export_group` genes (panel colors, text sizing, column layout, logging params). Promote to a full DNA sweep; keep text surface-pinned. |
| `poke_pillar_room` | `commons/artifacts/poke_pillar_room/poke_pillar_room.gd` | **Off-registry.** Full `@identity` + `apply_grid_config`, but not in a standard registry — register it and confirm its color/material routes through `HangarKit` for family coherence. |
| `pillarcolorcollection` | `algorithms/color/pillarcolorcollection/pillarcolorcollection.gd` | **Family check.** Complete `@identity` + palette cycling, but palette comes from `color_palettes.tres` — verify it reads as the Rams family (or document the deliberate exception) and that any swatch labels are surface-pinned. |
| (general) older `algorithms/` demos used as map artifacts | various | Per MEMORY: ~18+ leaked floating CanvasLayer UIs + own cameras into maps (centrally suppressed in `GridInteractablesComponent`). Re-audit for floating-text / oversized-in-map; bring text to surface-pinned, ground/size per the size→form rule. |

Reference (already gold — copy these): `hangar_podium`, `station_plinth`, `station_stage`, `hangar_step_base`, `station_panel`, `station_cabinet`, `station_pillar`, and the `curation_station` composer.
