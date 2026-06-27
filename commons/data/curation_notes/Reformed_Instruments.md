# Curation — Reformed Instruments (forces)

> *"Curation is an argument made with placement."* This map's subject is **the interface itself**: six
> bespoke teaching workbenches rebuilt on one canonical ControlConsole + Braun panel + smooth slider.
> The wall's job is to make *that* legible — so the curation language is held deliberately uniform
> (every artifact stands on the same painted-metal `station_plinth`, every caption rendered as the same
> framed surface-plate) **exactly as the ControlConsole unifies the six control surfaces.** The form of
> the wall is the content of the map. One grammar, six worlds.

## The argument (3 sentences)
The map proves a thesis — that a consistent interface lets attention rest on the idea instead of
relearning the buttons — so the wall echoes it: one plinth grammar and one plate-caption grammar carry
six incommensurable problems (a non-commutative group, Wolfram rule space, the P/exp gap, the QFEP
balance, the halting decision, a paradox loop), and the *only* thing that varies is what floats above.
Two of the six are pure-tuple consoles with a [1,1] footprint (transform = the **F** term, QFEP balance
= the whole **Q** frame); they are raised **high and narrow** on slim 1×1 plinths — "this one is
precious" — while the four big-visualization benches sit **low and broad** on 2×2 plinths as "worlds you
operate." The QFEP balance is the centerpiece because it is the term that contains the others, so it is
pushed forward into its own pillar-framed bay, raised highest, under the only amber truth-header.

## Reading order (left → right, +X)
The six read left→right in the order a walker meets them down the central aisle, with depth staggered
into a front rank (broad benches, set forward to be read) and a back rank (the high-narrow consoles and
the closing alcove):

| x | artifact | tier | footprint → prop | top_height | z (depth) | rank |
|---|----------|------|------------------|-----------|-----------|------|
| 0.0 | Transform Composition Workbench | medium | [1,1] → slim 1×1 plinth | **1.35** | 0.8 | back / high-narrow |
| 2.5 | CA Rules Workbench | applied | [2,3]→2×2 plinth | 0.9 | 1.9 | front / low-broad |
| 5.0 | Complexity Dial Workbench | applied | [2,3]→2×2 plinth | 0.9 | 0.9 | back (stagger behind QFEP) |
| 7.5 | **QFEP Balance Workbench** | applied | [1,1] → slim 1×1 plinth | **1.45** | **2.4** | **focal bay, forward + highest** |
| 10.0 | Halting Workbench | applied | [2,3]→2×2 plinth | 0.9 | 1.9 | front / low-broad |
| 12.5 | Russell's Paradox Workbench | applied | [2,3]→2×2 plinth | 0.9 | 0.85 | back / closing alcove |

Depth sequence 0.8 / 1.9 / 0.9 / **2.4** / 1.9 / 0.85 and height sequence 1.35 / 0.9 / 0.9 / **1.45** /
0.9 / 0.9 give a genuine 3D zig-zag that still reads cleanly as an iso strip from the front and rewards
orbiting with foreground/background bays.

Tier counts: **small 0, medium 1, applied 5, large 0** (matches the map's actual ladder — these are
finished interactive instruments; the lone "medium" is transform_composition_workbench per the
transformation concept map; the other five are tier "applied").

## Focal point
**qfep_balance_workbench** (x=7.5). It is the QFEP frame made into a console — the one term whose four
knobs are "the four parameters of the project's own thinking-shape." It earns the focus: deepest forward
push (z 2.4), tallest plinth (1.45), flanked by two `station_pillar` uprights so the bay reads as built
architecture rather than furniture-in-a-void, and backed by the only amber-headed wall panel
(`THE FRAME ITSELF`). Centerpiece by meaning, not by size — a slim, precious, raised tuple.

## Why each prop
- **`station_plinth` ×6 — the unifier.** Every artifact stands on the same plinth, because the map's
  whole point is *one chassis, many ideas* — the plinth IS the ControlConsole-of-the-curation. Sized to
  each real footprint per the plinth's own truth ("size IS part of the argument; high+narrow = precious,
  low+broad = a world"): slim 1×1 (`cap_inset 0.3`, top_height 1.35–1.45) for the two [1,1] tuple
  consoles; broad 2×2 (top_height 0.9) for the four [2,3]→2-cell visualization benches. Each plinth's
  `caption_text` is the artifact's display name → the framed surface-plate the editor pins to the front
  face (Requirement 2: the only label, since the editor hides each artifact's floating Label3D).
- **`station_panel` ×3 (wall, 2D-in-3D) — the truth-beats.** Three wall headers carry the map's own
  argument as group-headers, not per-object captions: left `ONE CONSOLE · SIX IDEAS` (the thesis),
  centre `THE FRAME ITSELF` over the QFEP bay (amber, the focal truth), right `SAME GRAMMAR · DIFFERENT
  WORLDS` (the critical/foreclosure beat from `intent.md` — *does the shared handle make genuinely
  different problems look interchangeable?*). These voice the Sieve's Q2 right on the wall.
- **`station_pillar` ×2 — architecture for the focal bay.** Per the pillar's soul ("one upright,
  repeated, makes a room out of an open floor"), they turn the centerpiece's patch into a framed bay so
  the QFEP console reads as the room's altar.

## Prop gaps flagged
- **Micro-pedestal gap (Requirement 1).** The two console-only instruments (transform, QFEP balance) are
  genuinely sub-1 m control surfaces. A slim 1×1 `station_plinth` is the right call and reads well at
  top_height 1.35–1.45, but its **foot still claims a full 1 m cell** — slightly oversized for a held
  control panel. *Future micro-pedestal prop:* a sub-cell high-narrow stalk (≈0.5 m foot, 1.3–1.5 m
  column) for tuple-consoles, so "precious" can go even narrower than the grid allows. Until then the
  slim 1×1 is the honest best fit.
- **`station_panel` text-fit unverified in headset.** Header + 2 body lines at `width_cells 3`,
  `height 0.62` should fit, but line-length wrapping on the dark face is not yet confirmed against a VR
  capture — verify the three headers don't clip.

## What to try next
1. **Capture** `--mode=map --target=Reformed_Instruments` (and orbit angles) to confirm the front-rank /
   back-rank depth stagger reads, the QFEP bay framing works, and the six plates are legible.
2. **Walk the aisle** — the live map spawns at the back (4.5,1.2,11.5) facing −Z; confirm the curated
   left→right reading order still tells a story when approached down the central aisle, not just as a
   front elevation.
3. If the foreclosure beat lands, consider promoting the right-hand `SAME GRAMMAR · DIFFERENT WORLDS`
   panel into the map itself (it currently lives only on the curated wall) — `intent.md` flags exactly
   this missing "before/after the overhaul" label as the map's narrative gap.
4. Longer term: build the micro-pedestal prop above and re-seat transform + QFEP on it.
