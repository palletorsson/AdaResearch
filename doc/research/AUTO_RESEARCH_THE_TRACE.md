# Auto-Research — The Point, beginning with The Trace

*Researcher / teacher / AI pass. 2026-06-02. Sequence: primitives. First target map: `Point_Trace`.*

> The brief: for each theme and map, auto-research new ways to explain the
> concept — what known form (a whiteboard, a slate, a drum, a black box) can
> carry it — and add the new artifact versions to DNA. Multiple, ad hoc,
> poetic, referential, conceptual, hyperpop, prefab *thingyness* and scientific
> at once. Half-Life 2, but more queer, more Ada, more AI, more contemporary.
> Alan Turing in VR, 2036, looking for an artifact to sink their mind into.

---

## What "auto-research" actually gives us

We already have ~750 artifacts. What we did **not** have is a *named grammar*
for them. Reading the strongest ones — `klee_walking_point`, `fontana_puncture`,
`you_are_here` — they are all the same shape. Each is a **triple**:

```
   artifact  =  (known form / art reference)
              × (concept facet — the scientific thing being taught)
              × (queer · AI · contemporary turn — what the form hides, put in drag)
```

- `klee_walking_point` = Klee's *Pedagogical Sketchbook* (1925) × point→line as motion × *meander vs straight = difference vs mode-collapse*.
- `fontana_puncture` = Fontana's *Concetto Spaziale* (1958) × point as subtraction × *the void as the wound that is also a window*.
- `you_are_here` = the wayfinding floor decal (c.2005) × point as index × *the located self reclaimed from the system that named it*.

So **auto-research is not "generate more artifacts."** It is: hold those three
as **axes**, and *sweep* them per theme. The payoff is that a pile of artifacts
becomes a **navigable space with named gaps**. Instead of "we have many," we get:

> *The Trace has* ***accumulation*** *(`draw_dot`) and an* ***anchor***
> *(`dark_sphere`) — but no* ***decay****, no* ***comparison****, no*
> ***export****, and no apparatus of* ***memory itself****.*

…and each gap arrives **pre-loaded with candidate referents** from the
art-historical / scientific / pop archive. That is the gift: not the answer, but
a well-shaped question with the search already done.

---

## The Trace — concept decomposed into facets

`Point_Trace` (map_info): *"duration and embodied residue… geometry as lived
process rather than a static system… the trace resists full discretization."*
Subtitle: *"There is no original behind the trace — only encodings at different
scales, each erasing differently, each affording differently, none closer to the
real."* (Derrida's trace; `intent.md` names the gaps: **decay, comparison,
data-export**.)

Facets of trace-ness a prop could make thinkable:

| # | Facet | One line |
|---|-------|----------|
| F1 | **Accumulation** | movement piling up as record (have: `draw_dot`) |
| F2 | **Anchor / persistence** | a fixed point the trace returns to (have: `dark_sphere`) |
| F3 | **Memory vs surface** | what "clearing" hides; depth keeps the lot |
| F4 | **Decay** | the trace fading, weighted by time |
| F5 | **Comparison / drift** | two traces of "the same" gesture — the difference is the work |
| F6 | **Export / encoding** | the trace as data; "only encodings at different scales" |
| F7 | **Residue as absence** | the index of a body that has gone |
| F8 | **Discipline / labour** | the trace as time spent, made to be swept away |

---

## The vocabulary sweep (candidate prop-forms)

Each row is a triple. **Build** = strongest, do first. *Status as of this pass.*

| token | known form / reference | facet | queer · AI turn | status |
|-------|------------------------|-------|------------------|--------|
| **`mystic_writing_pad`** | Freud's *Wunderblock* (1925) → Derrida (1967) — the magic slate | **F3 memory vs surface** | the surface that says "forgotten" over a log that forgot nothing; the delete-button as the friendly face of retained data | **✅ BUILT** |
| `marey_drum` | Marey/Muybridge chronophotography + the seismograph/EEG drum (1880s) | F1 accumulation + the body's weight | the machine that "objectively records you" is also the surveillance pen | proposed |
| `molnar_drift_plates` | Vera Molnár's *1% disorder* — same figure drawn twice | **F5 comparison / drift** | the deviation *is* the identity; rhymes with the map/lab diff tools (delta as the work) | proposed |
| `black_box_recorder` | the flight recorder / black box | **F6 export / encoding** | your movement as telemetry — who reads the box, and at what scale of erasure | proposed |
| `chalk_outline` | the forensic body-outline (Weegee pop) | F7 residue as absence | the queer body chalked — outline as both memorial and criminalisation | proposed |
| `opalka_counting_slab` | Roman Opałka counting 1→∞, photographing his aging face | F4 decay + F8 labour | the trace as a life spent; the count that ages the counter | proposed |
| `sand_mandala_floor` | Tibetan sand mandala / Tehching Hsieh's durational pieces | F8 discipline | accumulation built to be erased; the discipline, not the relic, is the work | proposed |

Seven candidates, three gaps closed (F3 built; F5/F6 are the two `intent.md`
explicitly asked for and are the next two builds). The point is not to build all
seven — it is that the *space is now legible* and each cell is a known referent
away from existing.

---

## Row one, built: `mystic_writing_pad`

Freud's Mystic Writing-Pad — the literal apparatus Derrida built the trace on.
A red-framed magic slate: a stylus writes a bright trace of **points** on a
clearing celluloid sheet; every few seconds the sheet is "lifted" — the surface
goes blank — and the trace does not vanish, it **sinks into the wax below** as a
faint warm ghost, where all the earlier traces already lie, overlapping: a
palimpsest. *The surface forgets; the depth remembers.*

- **critical_parameter:** `clear_interval × ghost_persistence`. Short clear + high persistence → the surface is always blank while the wax goes black with history (maximal trace, the unconscious that keeps everything). Long clear + zero persistence → an ordinary whiteboard that truly forgets when wiped (mode-collapse; a present with no past).
- **the turn:** the Pad lies the way every memory system lies — it shows a clean surface and keeps the wax. "Clear" is the politest word a machine knows for *kept, where you can no longer see it.*
- **placement:** `Point_Trace`, beside `draw_dot` — the Pad is the memory the hand's gesture lands in. Pathfinder OK (5 artifacts, 0 issues). Renders: a hyperpop red toy slate, cyan live marks tangled with warm fading ghosts.
- **files:** `commons/primitives/mystic_writing_pad/{.gd,.tscn}` (+ `@identity` DNA), registry `commons/artifacts/registry/primitives.json`.

It also closes a loop with the tools built the night before: the **diff** is
what a trace *reads*; the Pad is the trace a diff reads *from*. Memory, then the
delta off it — the same idea at two scales.

---

## Built this pass: the trace triad — wax · database · skin

The Mystic Pad asks how a surface *keeps* a hand. Two more artifacts ask how a
surface *receives* one — and the three together stage the politics of the trace
as three materials. All three read the same input (a hand) and differ only in
what kind of surface meets it.

- **`mystic_writing_pad`** — **WAX**. Keeps the trace as buried residue under a surface that pretends to be clean. (Freud/Derrida.)
- **`hand_telemetry_display`** — **DATABASE**. A big Half-Life-2 / Combine-style ops monitor on a grey pipe-clamp arm, streaming the **right hand's** live world position: large orange X/Y/Z numerals over a scrolling timecoded coordinate log, newest bright and fading down, a blinking REC dot. The point *that is watched*. Closes the **F6 export / surveillance** facet — *"you are at (0.42, 1.13, −0.88)"* spoken as a service and kept as a feed. (Reference: the surveillance-monitor wall; falls back to a demo drift so the feed reads full in capture.)
- **`living_paper`** — **SKIN**. A hanging sheet of warm paper that *breathes* (a standing-wave ripple) and reads the **right hand** into itself: the paper bulges toward the nearby hand like skin under a touch and blooms a fading ink trace of dots where it passes. The point *that is felt*. Closes the **F4 decay + body-weight** facet — the trace received and softly kept, where it is hard to say whether being read by a living surface is tenderness or a gentler capture.

Both new artifacts find the right-hand `XRController3D` (`tracker == "right_hand"`,
with name + demo fallbacks), so the *same hand* is rendered three ways at once —
cold log, kept wax, warm skin. Placed in `Point_Trace`: the monitor (west) and
the paper (east) face each other across the corridor at row 12, with the Mystic
Pad just north — a small museum of what a surface does with a hand. Pathfinder OK
(7 artifacts, 0 issues).

> Rig note: `living_paper`'s per-frame `ArrayMesh` defeats the artifact-mode
> capture framing (a `custom_aabb` is set, but the rig samples earlier); it
> renders correctly in-map. Standalone gallery capture is a known limitation.

### In the lab: the diptych and the writing desk

The set moved into the lab room (`trace.lab.json` mounted props) and grew two
members that read the body as *parts*:

- **`hand_telemetry_diptych`** — the database, doubled. Two ops monitors on one pipe-clamp mount: **left hand** (cyan) and **right hand** (orange), each its own live coordinate log. A Renaissance diptych re-cast as a security desk — the body split down the middle and read in stereo. Composes two `hand_telemetry_display` panels (now parametrised by `hand` + `show_mount`). Mounted on the lab's north wall.
- **`automatic_writing_desk`** — a new driver: the **head**. A desk whose paper writes itself from the **headset's motion** — a pen sweeps left→right, drops a row at the margin, fills the page top→bottom with **asemic script** whose jaggedness scales with head speed (still = a calm ruled line, moving = jagged handwriting). Surrealist automatic writing / the spiritualist planchette, the headset as medium; it transcribes your *attention*, the one input you can't hold still, in a hand you can't read. Driven by `XRCamera3D`; demo head-drift fallback. Mounted on the lab floor in front of the diptych — warm desk, cold monitors behind.

So the trace set now spans three drivers — **hand** (diptych), **head** (desk),
and **drawn gesture** (mystic_writing_pad) — and three temperatures — database,
skin/attention, wax. The lab is becoming a small museum of what a surface does
with a body.

---

## The method, generalised — the point, then the line

The same sweep is ready to run on the rest of the **point** (verbs on a
timeline) and then the **line**:

**The point as a timeline of verbs** — already latent in the relationships:
moves (`klee_walking_point`, 1925) → cuts (`fontana_puncture`, 1958) → locates
(`you_are_here`, 2005) → **remembers** (`mystic_writing_pad`, 1925/1967/2036, this
pass). Open cells on that timeline: the point that **counts** (Opałka / Kusama's
"obliteration"), the point that **is watched** (the cursor / the tracked dot /
the red recording dot), the point that **refuses position** (the quantum
non-localised point — Point_Trace's own *"resists full discretization"*).

**Toward the line** (`Point_Line`, next map): a line is a point that refused to
stay still. Candidate forms waiting: the **plumb line** (gravity's honest line),
the **horizon** (the line as the not-yet — already sketched as `horizon_line`),
the **timeline / spectrogram** (the line as recorded duration — the Pad's ghost
made horizontal), the **queue / the border** (the line as social ordering, in
drag), the **geodesic** (the straight line on a curved world — "straight" was
always a local fiction).

Each is a known form one referent away. That is the standing offer of
auto-research: hand it a theme, it hands back a vocabulary with the gaps marked.

---

## Next builds (proposed, in priority order)

1. `molnar_drift_plates` — closes **F5 comparison**; rhymes with the diff tools.
2. `black_box_recorder` — closes **F6 export**; "only encodings at different scales" made literal.
3. `marey_drum` — closes **F1+body-weight**; the most *thingy*, pop-scientific object of the set.

Then re-run the sweep on `Point_Line`.
