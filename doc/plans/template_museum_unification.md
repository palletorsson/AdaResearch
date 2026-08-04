# Unifying the template system and the museum templates

**Question (Palle, 2026-08-03):** relate the template system and the museum templates —
more flexibility for artifacts and DNA artifacts, series of artifacts, grid editing, reuse
of repetitive parts between museums; relate the artifact order in the final space; and
should the grid system be integrated with the museum templates?

## The finding that decides the design (measured, not argued)

A scan of all 20 museum tiles (`scratchpad/fragment_scan.py`, 2026-08-03):

| tile | rows | distinct | repeats |
|---|---|---|---|
| guggenheim-serpentine | 30 | 5 | **83%** |
| grande-galerie-axial | 36 | 7 | **80%** |
| pompidou-plateau-libre | 36 | 8 | 77% |
| chichu-buried-cells | 30 | 10 | 66% |
| … | | | 40–66% |
| sainsbury-false-perspective-enfilade | 30 | 18 | 40% (the least repetitive) |

**Every museum is 40–83% repetition.** The Grande Galerie is seven distinct rows repeated
across thirty-six; the Guggenheim is five. And across museums, 5×7 patches (a wall with a
door gap; a threshold band) recur in 5–6 *different* buildings — a shared vocabulary that
different extraction agents arrived at independently.

So the museum tiles are **unrolled loops**. The bays are already there; the format lost
them. Nothing needs inventing — the repetitive parts Palle wants to reuse can be *factored
out*, which is archaeology, not design (P-10: the bound must be found in the data).

## The relation, stated

Both systems already emit the same object: **(structure grid, ordered slot list)**.

- painted template: zones + params → *generator* → slots
- museum template: frozen tile → *lookup* → slots

The only difference is that one is live and one is frozen. Unify one level below both:

> **The BAY is the unit.** A bay is a small tile (its own cells + slots + repeat count).
> A museum is a sequence of bays. A painted zone is a bay generator. The grid is the target.

That single move gives all five things asked for:

| asked for | how the bay gives it |
|---|---|
| reuse repetitive parts between museums | shared bays in one registry; the Uffizi bay and the Grande bay become named, comparable objects |
| edit the grid | edit a bay once → every instance follows; or unroll one instance to edit it alone (the edited lineage, with a named ancestor) |
| flexibility for artifacts | bay count becomes **parametric** — a 12-artifact chapter gets 12 bays, a 4-artifact chapter gets 4, instead of today's fixed tile truncating or padding the cast |
| series / DNA artifacts | a bay run declared as a **series**: one token × N DNA values, one per bay — the DNA gallery walked instead of contact-sheeted |
| artifact order in the final space | order becomes a **declared policy per bay**, not an implicit sort |

## The three additions

### 1. `commons/data/museum_bays.json` — the bay registry
Factor the 20 tiles into bays. Every museum re-expressed as `[{bay, repeat}, …]`.
**Gate: recomposition must be byte-identical to today's tile** (the negative control —
the extraction is only true if it round-trips). Zero risk: pure re-encoding, existing tiles
stay the shipped truth until the round-trip proves out.

### 2. The typed slot
Today a slot is a rank (`1s`/`2s`/`3s` → floor/podium/hero). It needs a small grammar:

```
slot: { rank, role, size_class, series? }
  role:       hero | station | wall_hang | vitrine | underfoot | rest
  size_class: from the size oracle — a slot advertises what fits
  series:     { token, axis, values[] }   # one artifact, N variants, N bays
```
`series` is the DNA flexibility asked for: a bay run becomes a **family walk** — the same
artifact under `emergence = hatch|doors|slide|vent`, one per bay, in the architecture that
best shows it. This is the DNA gallery made walkable, and it is the strongest new thing in
this design: the corpus has 392 declared axes and exactly one map places a non-default
value.

### 3. The declared order policy
Order is currently implicit — `museum_match` deals hero-by-size then walk order; the painter
sorts by (z,x); `endless_museum` deals spine order. Make it a per-bay declaration with
provenance:

```
order: spine | dig (load-bearing first) | size | series | text | ruled[...]
```
`text` is now possible: `doc/book/text_mentions.json` (built 2026-08-03) knows which
artifacts the writing names and how often — so the room can be ordered by *the book's* order,
which is the last unclosed gap between the writing pipeline and the museum pipeline.

## Should the grid system be integrated with the museum templates?

**No — integrate at the compiler, not the runtime.** The grid system is the *target format*;
templates are a source language above it. A museum tile is already "a map_data with slots
instead of tokens", and `museum_match` already compiles one into the other. Growing
GridSystem to understand templates would put the source language inside the target and
violate the discipline the guard-lift asks for (additive hooks gated by new data).

What IS missing on the grid side is small and additive:
- **the utilities layer**: bays declare spawn / teleporter / ramp anchors, so a stamped museum
  is a playable map on its own instead of needing `endless_museum`'s synthetic lobby;
- **the sidecar round-trip**: the painted side already writes `template_layout.json`; museum
  tiles should carry the same sidecar so any museum opens in `/template-maps`, is edited, and
  saves as the edited lineage with its ancestor named.

## Build order (each ships alone)

1. **bay extraction + round-trip gate** — `tools/extract_museum_bays.py`, byte-identical proof
2. **bays as brushes** — the pattern editor palette gains museum bays; chimera museums (a
   Castelvecchio end-stop after a Soane cabinet wall) with named parents per zone
3. **typed slots + series** — the DNA family walk
4. **declared order policy** — including `text` order from `text_mentions.json`
5. **utilities compile** — museum stampings become standalone playable maps
6. **sidecar round-trip** — museums editable in `/template-maps`, saved as edited lineage

Everything stays inside the existing law: tiles propose, the ruled judge decides, crowns are
rulings, and no edit ships without being re-judged (edit-by-proxy ≠ edit-by-judge).
