# Random_Pheromone: decisions

**Verdict.** This is a targeted revision. The encounter is already fixed: `map_info.museum.artifact_placement = "map"` is at commons/maps/Random_Pheromone/map_data.json:197. The console instructions in paragraphs 1, 2 and the AVOID paragraph are now true, so they stay as written. The changes below cover two overstated sentences that the audit and its re-check both confirmed, one structural move, and five added sentences (a placed clipboard, a tie-break the terrain enforces, and the two handovers).

## Preserved
- The title, the opening question, the `<!-- @pheromone_terrain -->` / `<!-- @ -->` anchors, and every audit "Preserve" line.
- All console instructions ("leave ATTRACT selected", +1 STEP, +20 STEPS, AVOID, REPLAY). They are true once comparison mode is built: rule defaults to trail (pheromone_terrain.gd:58), the readout prints ATTRACT/AVOID (740-741), and the buttons are wired at 697-713.
- "Compare the resulting visits before deciding what the changed rule did." The re-check shows the auditor was wrong. Pressing ATTRACT again reseeds and replays exactly (600-612, 615-619).
- "Repeated use can reinforce it, but reinforcement does not establish that it is globally shortest, fairest or best." The re-check marks it true. The clipboard is answered by added sentences, and this one is unchanged.
- "Try identifying a route that may have begun as an accident." The re-check marks it hedged and true. The tie-break is added after it; the sentence itself is unchanged.
- No code excerpts or footnotes existed. None were added.

## Changes
1. **"Each visit leaves pheromone and changes the local height."** → "Each visit away from the flat border band leaves pheromone and, until that patch reaches its height ceiling, raises the local surface."
   - Reason: overstated; the audit and re-check agree. This is the re-checker's rewording, with "flat" added.
   - Evidence: a walker in the border band is clamped back and `continue`s, with no deposit and no raise (pheromone_terrain.gd:337-349; band defined at 511-514, border_size 10 at 31, 80 segments at pheromone_terrain.tscn:23-24). So border cells never rise, which is why "flat" is accurate. Height rises only while `y < max_height` (356-357), with raise 0.2 and max 4.0 (tscn:32-33).
2. **"Later choices can favour a stronger pheromone signal, while some movement remains random."** → "…while most movement remains random (the label over the field reads signal-guided: 40%)."
   - Reason: overstated; the audit and re-check agree. This is the re-checker's rewording plus the terrain's own label, so the reader can check the share.
   - Evidence: `pheromone_attraction = 0.4` (tscn:35). One draw per step, `< pheromone_attraction` guided, else uniform (gd:414, 434). The label text is "signal-guided" when comparison is on (542-545). In comparison mode it is positioned over the field at (0, 1.5, -1.6) (673).
3. **Structure.** The AVOID paragraph was after the closing `<!-- @ -->`. It now sits inside the `@pheromone_terrain` region. Its final sentence, the handover ("Next, the noise mixer…"), stays after the closing anchor as its own paragraph, as in Random_Walk, Randomness_Examples_of_Randomness and Random_Space. No sentence in it was altered.

## Added sentences
- Paragraph 4, handover repair (audit: the opening skipped the pipe the previous hall named): "The last room's pipe could cross its own earlier route for a similar reason: no place it had passed entered its next choice."
  - Evidence: PipeDream.gd:383-404 refuses only reversal and out-of-bounds, with no occupancy set; the note at 79-86 says so.
  - Sequence adjacency: Examples then Pheromone, with no interlude between them (randomness.json `maps` and `museum_interludes`).
- Paragraph 6, the placed clipboard the chapter ignored:
  - "A clipboard in this hall claims more: that shortest paths get reinforced and that the collective finds the optimal route."
  - "Its ants carry food back to a nest; these walkers have no nest and no food, so a route here has no two ends to be shortest between."
  - Evidence: token at map_data.json:772. It resolves via tutorial_text.json:383-384, and clipboard.gd:407-435 treats `pheromone_axioms: "194:1.0"` as a tutorial key. The claims are at pheromone_axioms.gd:22, 24, and nest/food at 78-82 and 131. pheromone_terrain.gd has no nest, food or target anywhere (read in full).
- Paragraph 6, the list-order lead: "Not every beginning is an accident, though: where all eight sensed directions read the same, as on fresh ground, a signal-guided walker takes the first direction on its list, and that direction always points the same way."
  - Evidence: DIRS_8[0] = (1,0) (gd:91-93). `chosen` starts at directions[0] (412). The strict `>` / `<` against -1.0 / INF (416, 428) keeps the first entry on a tie under both trail and avoid. The comment at 44-45 says "ties to the first direction".
- Closing, handover bridge (audit: land made by use vs land made by formula): "Its picture is coloured like land, but no visit shaped it."
  - Evidence: noise_mixer.gd:31-42, an earth-tone ramp from water to peak. `_fbm` at 142-158 sums octaves with no history.

## Left alone, and why
- The auditor's claim that "the ATTRACT record is erased" is refuted by the re-check (replay is exact). The sentence stays.
- clipboard#queer_energy, which renders nothing, and dark_sphere, which is decoration, are not mentioned. Neither does work the inquiry needs.
- The sniff/grid laws are not exposed by the console (gd:616), so they are not mentioned.
- The sequence notes on seed re-teaching and hedging ("say which evidence is missing") concern preserved lines. They are not errors.
- The stale companion files (blurb/intent/technical) are outside this task.

## Limits
- *(Written by the text editor, before install; superseded in part by "Encounter change and museum evidence" below, where the main agent booted the hall in a scratch museum probe. That output was not saved.)* There was no Godot run. The museum state (comparison=true, StepComparison present) is taken from the task brief. The label's legibility and position in the hall, and the clipboard standing in the map-placed hall, were checked in code and in the pre-fix bake (ada_run/em_bake.json lists two clipboards placed, none refused). They were not checked in a live museum.
- "Always points the same way" is true in grid terms, +x of the terrain. I did not state it as left or right, because the hall's orientation relative to the visitor was not verified.

## Encounter change and museum evidence (added at install)

**Hall verdict: Development.** The encounter was broken in the museum before any text changed.

- **What was wrong.** The museum built this hall from the 26 August bench stamp, which hands a token only its first `#key:value` with the rest of the string attached: `pheromone_terrain` received `{"comparison": "true#walk_seed:190919"}`, the equality test for `"true"` failed, and the comparison console (ATTRACT/AVOID, step buttons, REPLAY, cyan start markers) was never built. The chapter's instructions described a console no museum visitor could find.
- **Change.** `commons/maps/Random_Pheromone/map_data.json`: `map_info.museum.artifact_placement: "map"` (`map.diff`). No artifact code changed.
- **Readback** (scratch museum probe that boots the hall and reads the placed nodes): `PheromonesTerrain … comparison=true walk_seed=190919 StepComparison=true`; `[em-pack] randomness · random pheromone <- Random_Pheromone: 4 verbatim + 0 slid of 4, 0 left behind`. Plan image: `hall_plan_map.png`.
- Companions `blurb.md` and `intent.md` rewritten (they claimed diffusion and Gaussian blur; the terrain only decays).

| file | before | after |
|---|---|---|
| `final.md` | `2ceed42c99417f61686b42d7293ca470d05cf79350be0cfc007c158c66638b5e` | `2883c0f7873b95d086b79ae5b8d36785464c3a9cc0093047e35de45250aca293` |
| `map_data.json` | `722f2c04562e4cf7181a8cdc164b5e89725726afa06562d4b88cd9c9d1cd8dfd` | `2283ff15d3743a64c70a477b58f524f40f6d74dd52ac635a38e0405958f91901` |
