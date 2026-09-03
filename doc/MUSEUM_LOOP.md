# The museum loop

2026-09-03, Palle: *"is this the perfect space room to express the essence of
this concept... see what I mean with this auto research loop? The thing is that
I think we can lean on the different modalities and aspects to let them lift up
each other."*

Yes. The lift is the design. Every step of this loop hands its output to the
next step **in a different medium**, because each medium catches what the last
one cannot: code catches what is true, space catches what is reachable, an image
catches what is legible, text catches what is meant, and a gate catches what
repeats. A loop that stayed in one medium would only ever polish that medium.

```
   registry + .gd  ──build──▶  shelf.json        code becomes DATA
   shelf + essence ──query──▶  a candidate       data becomes CHOICE
   candidate       ──place──▶  map_data.json     choice becomes SPACE
   map             ──shoot──▶  a capture         space becomes IMAGE
   capture         ──read───▶  what is seen      image becomes JUDGEMENT
   judgement+code  ──write──▶  final.md          judgement becomes TEXT
   text            ──gate───▶  wall_voice.py     text becomes DATA again
   the whole turn  ──learn──▶  a principle       and the next turn is faster
```

## Step 0 — the shelf, once

Measured 2026-09-03 before anything else, because the loop cannot start without
it: **2899 artifacts, 892 placed in the live spine, 2007 never placed. 1750 have
no capture. 619 are category "unknown", among 119 category values.** Two thirds
of the shelf is unsearchable and unseen.

    python tools/shelf.py --build          rebuild doc/shelf.json
    python tools/shelf.py rotation closed  what could express this concept
    python tools/shelf.py --blind          standing in a live map, never shot
    python tools/shelf.py --unseen         on the shelf, never placed

The search is a deterministic scored substring match over name, description,
tags, category, qfep connection and dna axes. It is the fast lookup, not the
judgement. The judgement is what the loop spends its agents on.

## The turn

**1. Essence.** One sentence: what does this room claim? Take it from the
triage argument and the KEEP line, not from the title. Titles name subjects;
KEEP lines make claims, and a claim is what an object can support or fail.

**2. Fit.** Is this space right for that claim? Read the floor plan as a walk:
where you arrive, what you meet, in what order, and what the walls do. A room
whose argument is a sequence needs a route; a room whose argument is a census
needs a hall you can sweep with your eyes.

**3. Candidates.** `shelf.py` with the terms of the KEEP line. Read the ones
marked `*` first — never placed — because the museum has not met them and they
are where the unspent value is. Prefer `seen` over `BLIND`: you cannot judge
what you cannot look at, and shooting it first is a legitimate move.

**4. Place.** What, where, how. Footprint against free cells, height against
wall height, and above all RELATION: an object is placed against the objects
already there, not into an empty coordinate. Write through
`POST /api/maps/cell-edit`, which is the one write lane. Then
`map_pathfinder.py check`.

**5. Shoot.** `capture_multi_angle.gd --mode=map`. One Godot at a time, wrapped
in the watchdog. This is the step that cannot be skipped and cannot be faked:
every wrong claim this project has shipped came from reasoning about a room
instead of looking at it.

**6. See.** Open the image. What is actually legible? Is the new object visible
at all, at the size and distance a visitor meets it? Does it read as part of the
argument or as furniture? Nine of the faults found on 2026-09-02 and 03 were
objects taller than their rooms, buried in floors, or floating over spawns, and
every one was invisible in the data and obvious in a picture.

**7. Write, in three registers.** The same room, three ways, and the three
disagree productively:
  - *tutorial* — how it works, in numbers a visitor can check
  - *critical* — what this encoding forecloses, what the dark spot hides
  - *poetic* — what it is like to stand there
The wall text is not the average of the three. It is what survives all three.

**8. The queer question.** Not decoration and not a tag. In this project queer
means the irreducible: the part of the thing that the encoding cannot compress
without losing it. So ask of the room: *what here refuses to be the diagram of
itself?* A room where everything is legible has no queer content and is usually
also a boring room. The best rooms so far kept a fault as an argument rather
than hiding it, which is the same move.

**9. Gate.** `wall_voice.py` for the mechanical half (forbidden words, em
dashes, repeated openings, and across-room repetition, which no single room
critic can see). `final_tags.py --check` for the region grammar.

**10. Principle.** Before looping, write down the one thing this turn taught
that would make the next turn faster, into `doc/museum_principles.json`. A loop
that does not accumulate is just a checklist run repeatedly.

## Where the agents go

Not everywhere. Measured over four waves on 2026-09-02 and 03:

| step | agents? | why |
|---|---|---|
| 3 candidates | no | `shelf.py` is deterministic and instant |
| 4 place | no | judgement, but one person's, and it is one write |
| 6 see | **yes** | vision, one agent per capture |
| 7 write | **no** | seven rooms by seven agents do not share a voice; every multi-drafter attempt this session failed or was thrown away |
| 1, 2, and the read behind 7 | **yes, heavily** | reading every placed artifact's script and scene is the expensive, parallel, high-yield half |
| 9 gate | no | a tool |

The rule that came out of it: **agents read and check; one hand writes.**

## The toolchain — what each step actually runs

Every step of the loop has a command. Where a step has no command it is either
judgement (step 4, step 7) or vision (step 6), and that is the whole reason
those three are the expensive ones. Nothing here needs a model, a server or a
key unless the row says so.

**Measure and index — the ground the rest stands on.**

| tool | run it | what it answers |
|---|---|---|
| `tools/measure_artifact_aabbs.py` | `--only=a,b` · `--registry=X` · `--dry-run` | how big is this body, really. Boots Godot once, merges into the registry, preserves tab indent. Resolves **delegates**, feeds **`dna.fixture`** to gated artifacts, and retries any body that measures zero |
| `commons/testing/measure_artifacts.gd` | (driven by the above) | the Godot half. Settle 0.35 s, second reading to catch a simulation still growing, `IMPLAUSIBLE_M` guard |
| `commons/testing/probe_yaw_span.gd` | `--token=X` | does the Python footprint math agree with the engine on all four yaws. Run it whenever the placement geometry changes |
| `tools/shelf.py` | `--build` · `<terms>` · `--unseen` · `--blind` | what could express this concept. 3367 entries with category, tags, axes, placements, capture, `wall_backing`, aabb + centre |
| `tools/sync_footprints.py` | `--apply --cap=9` | push measured cells back into `spatial_needs.footprint_cells` — **224 of 893 placed artifacts declare a footprint 2× too small** |

**Judge the room.**

| tool | run it | what it answers |
|---|---|---|
| `tools/map_plan.py` | `<Map> [<Map>…]` | the room as an architectural **plan**, not a photograph. Bodies at measured footprint, honouring centre offset and yaw; red where a body leaves the room, hatched where unmeasured. ~1 s per room |
| `tools/argument_shape.py` | `--mismatch` · `--map=X --why` | does the room's **form** argue its **claim**. Seven kinds; form fights claim in 46 of 185 |
| `tools/coherence.py` | (no args) | one row per room, one column per modality — CLAIM · BODIES · SEEN · TEXT · SPACE · VARY — each gap naming its next action |
| `tools/map_pathfinder.py` | `check <Map> --verbose` | can the player get there. **Has one error rule** — "pathfinder OK" is not evidence of much |
| `tools/walk_evaluator.py` | `--map=X` | detour ratio, encounter order, backtracking |
| `tools/stamp.py` | *(being built)* | seat every body: carve and **displace** walls, journal it reversibly, seed the room shape from a typology keyed to the argument, keep a walkable corridor |

**Write and gate the text.**

| tool | run it | what it answers |
|---|---|---|
| `tools/wall_voice.py` | `<seq>` · `--all` | the deterministic half of the wall-text standard: forbidden words, repeated openings, and the across-room repetition check (6-shingle, measured not guessed) |
| `tools/final_tags.py` | `--check` | does every `<!-- @token -->` region name a body the map actually places |
| `tools/book.py` | `compile` | the book — a pearl is a list of lines |
| `tools/red_thread_page.py` | (no args) | regenerate the triage page |

**Curate the families.**

| tool | run it | what it answers |
|---|---|---|
| `tools/check_dna_declarations.py` | (no args) | does each declared axis match its code. Exit code = broken count, so it gates |
| `tools/build_dna_gallery.py` | `--slug=S --tokens=a,b` | one PNG per variant plus a manifest |
| `tools/artifact_dna_critic.py` | `--gallery=S` | does the axis change the picture. Emits `INERT?` / `ANAMORPHIC` / `INERT` |
| `tools/probe_anamorphic.py` | `--token=X --axis=Y` | is a dead verdict a fact about the artifact or about where the camera stood |
| `tools/build_dna_deck.py` | (no args) | 5164 variant cards for `/map-curator`. **26 of 185 rooms place any variant** |

**Talk to the other sessions.**

| tool | run it | what it answers |
|---|---|---|
| `tools/forum.py` | `open` · `ask` · `answer <id>` · `settle <id>` | several Claude sessions edit this repo at once and none can see the others. Post before touching shared data, and after a regeneration that moves numbers |
| `tools/fold_ledger.py` | `--check` | a fold balances by **artifact**, not by map — and `--check` must run *before* the sequence file changes |
| `tools/sieve.py` | `<target>` | the three questions |

## The cost of skipping step 5

Rooms written before their readers landed were wrong about something a visitor
would notice, every time, in five out of five cases. Rooms written after were
not. That is the whole argument for the loop having an order.
