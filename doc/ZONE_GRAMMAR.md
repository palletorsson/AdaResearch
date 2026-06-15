# Zone Grammar — a constrained scene-archetype generator

> The §11 prototype from the essay *"the map is a compressed machine for possible actions."*
> Where `place.py` places artifacts into a fixed room and `grow_map.py` lets the placement
> leave the room behind, **`zone_grammar.py` starts from a named scene archetype** — a grammar —
> and paints a whole floor that obeys it, then fills it with the right real artifacts.

```
python tools/zone_grammar.py --list
python tools/zone_grammar.py --archetype=forbidden_wet_lab --size=12 --seed=3
python tools/zone_grammar.py --all
```

## The core move: six design layers → three runtime layers

The essay asked for six design-time layers. Ada's runtime only reads three. The generator
works in the richer set and **projects down** — and that projection *is* the essay's thesis in
code: *we do not lose the third dimension, we compress it into symbols, layers, constraints,
affordances.*

| design-time layer        | → | runtime layer | encoding |
|--------------------------|---|---------------|----------|
| floor + heights          | → | `structure`     | `0` void · `1` floor · `2`/`4` wall · `3` pedestal |
| services + danger        | → | `utilities`     | `sp` spawn · `t` exit · `h:toxic` hazard |
| occupancy                | → | `interactables` | artifact tokens, filtered by archetype |
| **zone + visibility**    | → | `map_info.metadata.zone_grid` | kept as 2D metadata — the compression made legible |

The zone layer survives the projection as metadata (`E`ntry · `T`eaching · `X`ploration ·
`R`eflection/threshold · `Z` exit · `#` wall · `.` void · ` ` floor). The runtime never needs
it; the *design intent* does. That sidecar is the honest record of what the 3 runtime layers
compressed away — and it answers the Sieve's Q3 ("what lives in the dark spot?") by refusing to
let the floor plan hide why each cell is what it is.

## The five archetypes (the essay's scene types)

Each archetype is `{ paint(size, rng) → layers + slots, want/avoid keyword filter }`. The
filter scores the whole 2088-artifact placeable pool by tag/category/theme overlap and fills
the grammar's slots with the best real artifacts for that scene.

| archetype | spatial grammar | who lives there (auto-selected) |
|-----------|-----------------|-------------------------------|
| `warehouse_lab` | walled hall, two clean aisles | force/instrument demos (catapult, force_vortex, centripetal_force_demo) |
| `temporal_storage` | tiered pedestal-shelves, taller = older = deeper | data structures (sparse_array, merge_sort, grid3d_bfs) |
| `observation_chamber` | 2-thick ring catwalk + bridge over a central void | one centrepiece + waves/chaos (oscillation_controlled_cube, edge_of_chaos) |
| `forbidden_wet_lab` | clean corridor cross + 4 sealed cells behind toxic thresholds | cellular life (game_of_life_petri, ca_growth_network, pulsing_ca) |
| `archive_of_machines` | dense parallel aisles, machines on raised racks | pattern engines (pattern_loom, lsystem_editor, mesh_grammar, room_grammar) |

All five generate, validate (`map_pathfinder.py` — every artifact reachable, spawn→exit clean),
and capture as spatially distinct, walkable scenes. The `forbidden_wet_lab`'s toxic threshold
sits on the cell *touching the corridor*: you may look in, but crossing to the specimen costs
you — danger as a property of going closer, not of the path.

## Where the rules stop and judgement begins

This is the essay's real question, and the project already named the boundary: **the Sieve.**

- **Rules own Q1** ("does this thicken the cognitive water?"). Walkability, reachability,
  encounter order, thematic fit — all measurable, all here. This half is large.
- **Judgement owns Q3** ("what lives in the dark spot?"). No scorer decides whether a generated
  `forbidden_wet_lab` *means* anything, or whether the centrepiece across the void earns the
  walk. The generator proposes a legible, correct skeleton; the artist interrupts, contaminates,
  re-symbolises. The generator cannot eat that, by construction.

So `zone_grammar.py` is deliberately a *candidate machine*, not a finisher. It gets you a
walkable, on-theme, narratively-phased floor in one command. What it hands you is the start of a
map, not the end of one.

## What it does NOT do yet (honest gaps)

- **One archetype per map.** No *layout grammar* that composes several zones into one larger
  map (a warehouse that opens onto an observation chamber). That's the natural next step.
- **No affordance edges.** Placement is by zone-phase slot, not by typed `sees → / powers → /
  requires →` relations between artifacts. (The separate affordance-graph gap.)
- **No placement explanation.** The grammar knows *why* each cell is what it is (it's in
  `zone_grid`), but `place.py` still discards its own scoring rationale. (The separate
  explanation gap.)
- **Centrepiece is reachable, not just observed.** The observation chamber's bridge leads all
  the way to the centre. A "look but don't reach" variant (pedestal at height 3) is one flag away.

Generated 2026-06-15. Tool: `tools/zone_grammar.py`. Example maps: `commons/maps/Zone_*`.
