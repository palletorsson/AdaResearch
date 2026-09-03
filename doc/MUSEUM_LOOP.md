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

## What the loop turned out to be, after running it once end to end

2026-09-03, one full turn on Vectors_Act5_ForceAsPlace. Three things changed in
how this is understood, and they are worth more than the turn itself.

### It is TWO loops, and they run at different speeds

The deterministic sweep over all 185 halls — `stamp.py --all`,
`argument_shape.py`, `coherence.py` — costs **three seconds**. A full turn on one
hall costs most of a day: five reader agents on five artifacts, an adversarial
cross-check, a rewrite, three code fixes and two probes.

So they are not the same loop and should never have been drawn as one.

    FAST   every hall, every day, 3 seconds     ->  WHERE TO LOOK
    SLOW   one hall, most of a day              ->  WHAT ACTUALLY CHANGES

The fast loop cannot fix anything and the slow loop cannot scale. The fast one
did not exist yesterday, which is why the slow one used to be pointed by taste.

### The engine is DISAGREEMENT, not any single instrument

Every finding of consequence today came from two instruments contradicting each
other. Not one instrument being run.

| what disagreed | what it found |
|---|---|
| registry said 4 m, code said 5 m | four surfaces carrying a wrong number, one of them a placard |
| intent said "no floor", the map had a catwalk | a real collision between VR and the museum walker |
| my flow and networkx | the answer agreed, the WITNESS did not, so the classifier was ill-posed |
| my fit script and `stamp.py` | `span_of` was ignoring a token's scale |
| greedy and Hungarian | they agreed exactly, which refuted my own prediction |
| the docs and `endless_museum.gd:660` | the museum does not reverse the subtitles, it deletes them |
| a plan and a photograph | a body drawn half its own length from where it stands |

So the modalities are not decoration. Each is in the loop because it **fails
differently**: code cannot see space, space cannot see order, order cannot see
what a thing looks like, a picture cannot see a number, a number cannot see a
claim, and a claim cannot check itself.

The corollary is the useful part. **A step that agrees with the step before it
taught you nothing.** Budget the expensive steps for where two cheap ones
already disagree.

### The step that was missing was FIX

The loop as first written ended at *write the text and record a principle*. It
described faults beautifully and changed no code. Act5's three faults — a dead
yaw fader, a weightless probe, a field five centimetres out of reach — were all
one-line changes once found, and each needed a probe to prove it from the engine
rather than from arithmetic. Two of the three fixes were nearly wrong in the
same way: `_home` read in `_ready` before `call_deferred` grounding, and a ghost
arrow frozen by the same early return it existed to cure.

A loop that only writes is criticism. The turn is not finished until something
in the room is different.

### And ORDER is a step, not a detail

Palle: *"in the museum, so in the first z row and out at last."* Nothing measured
what a visitor meets, in what sequence, entering the way the museum enters.
Adding it found that Act5's four spoken truths arrive backwards — and then the
cross-check found something worse, that the museum drops them entirely. 163 of
185 halls walk row 0 to row H-1; 121 are narrower than their own doorways.

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

**Judge the room.** The museum's traversal is IN at the first z row and OUT at the last,
not spawn to teleporter — measured over the 185 live rooms, **163 walk row 0 to row H-1**,
10 have doors that do not connect, 12 have no door at all, and **91 of the 163 pinch to a
single cell** somewhere along the way. 97 artifacts in 35 rooms are walled off from the
entrance entirely.


| tool | run it | what it answers |
|---|---|---|
| `tools/map_plan.py` | `<Map> [<Map>…]` | the room as an architectural **plan**, not a photograph. Bodies at measured footprint, honouring centre offset and yaw; red where a body leaves the room, hatched where unmeasured. ~1 s per room |
| `tools/argument_shape.py` | `--mismatch` · `--map=X --why` | does the room's **form** argue its **claim**. Seven kinds; form fights claim in 46 of 185 |
| `tools/coherence.py` | (no args) | one row per room, one column per modality — CLAIM · BODIES · SEEN · TEXT · SPACE · VARY — each gap naming its next action |
| `tools/map_pathfinder.py` | `check <Map> --verbose` | can the player get there. **Has one error rule** — "pathfinder OK" is not evidence of much |
| `tools/walk_evaluator.py` | `--map=X` | detour ratio, encounter order, backtracking |
| `tools/stamp.py` | `--map=X` · `--apply` · `--width=N` · `--svg` · `--typology` · `--revert` | seat every body. Carves the wall cells a body needs and **displaces** the literal it carved rather than deleting it, so the wall multiset is conserved exactly. Re-checks the **museum traversal** after every move — in at row 0, out at row H-1, every artifact still approachable — and replans up to 8 times, banning whichever displacement broke it. Journals every cell with its pre-image, replayable backwards |

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
