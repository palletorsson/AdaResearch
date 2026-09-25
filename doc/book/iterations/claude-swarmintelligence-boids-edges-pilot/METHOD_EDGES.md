# How to add encounters at edges across the book

Palle's principle (24 Sept 2026): a chapter runs **Encounter → Disturbance → Search → Rule → Name → Edge**. Don't explain the rule; put the player where the rule begins to break. This note is the method for doing that to 196 chapters without inventing anything, learned on the Boids pilot.

## 1. The edge is already in the code. Find it, don't write it.

Every hall in the pilot had its edges in the source before anyone looked:

| where the rule ends | what the code did | event class |
|---|---|---|
| a boundary larger than the room | `boundary_size = (50, 30, 50)` in a 13 m hall | leak |
| a wrap that is a seam | `position.x -= bounds.x`, neighbours by plain `distance_to` | threshold |
| a wall that is only in the numbers | bounce at `tank_size * 0.45`, five panes, no lid | occlusion / collision |
| a hand the rule has no term for | three unset NodePaths | proximity (absent) |
| a reset that is not a return | unseeded `randf_range` vs `rng.seed = DEPOSIT_SEED` | repetition |

None of these took a design decision. They took a grep for the words the edge principle names: `bound`, `wrap`, `clamp`, `half`, `seed`, `randf`, `NodePath`, `get_node_or_null`, `collision`, `layers`. Method, per hall:

1. `grep -n "bound\|wrap\|clamp\|half\|seed\|randf\|_path\|get_node_or_null" <every .gd the map places>` — ten minutes, no agent.
2. For each hit ask: **what does the visitor see when this line fires?** If the answer is a thing in the hall (a prism through a wall, a fish turning at nothing), it is a beat. If the answer is nothing visible, it is not.
3. Write beat 1 from the largest visible thing that happens *before* any control is touched. Write beat 6 from the line where the rule stops agreeing with the room.

## 2. Which beat is usually missing

The spine reading found the same absences in almost every thin chapter:

- **Beat 1** exists but is an instruction ("Find the highlighted boid…"). An encounter is a thing that happens *to* the visitor, before they do anything. Rewrite the first paragraph so no imperative appears in it.
- **Beat 2** is nearly always missing. The chapter goes from "here is the artifact" to "here is what to do". The disturbance is the moment the artifact does something the visitor did not ask for: a boid crossing the seam, a crack plate that stops, a die that settles wrong.
- **Beat 5** comes too early. Most chapters name the concept in the title question or the second paragraph. Move the name after the rule has been watched. A footnote carries the attribution.
- **Beat 6** is present as a QFEP paragraph ("alignment is not consent") but never as an *architectural* edge — where the rule fails in the room. Put the room's edges first, then the model's.
- The closing "a future experiment could…" is beat 6 deferred. Replace it with a thing the hall can do today, or cut it.

## 3. Tagging, so the work can be managed

- Task `kind: encounter` already exists on `/book-tasks`. Add an `event` field from the ten classes (collision, threshold, proximity, occlusion, scale, repetition, failure, leak, trace, transformation) so a filter can show "every hall with no leak" or "every proximity event that is dead". `tools/book_tasks_ingest.py` passes unknown fields through; the page needs a chip.
- Per chapter, a **beat audit** line in the reading JSON: `"beats": {"encounter": "instruction", "disturbance": null, "search": "ok", "rule": "ok", "name": "para 2 — early", "edge": "qfep only"}`. This is what a reader agent can produce cheaply (one pass over `final.md`, no code), and it is what tells Palle where the book is thinnest in the sense that matters.
- A chapter is "edged" when it has beats 1, 2 and 6 grounded in a cited line of code. Count those, not words.

## 4. Order of work, to not deplete

1. Hand-pilot one hall per thin sequence (this one for swarmintelligence; next: graphtheory, softbodies, machinelearning) — reading the code by hand, ~40 min each, no agents. The pilot fixes the vocabulary the audit will use.
2. One cheap agent pass over all 196 `final.md` for the beat audit (text only, no code, ~1.5k tokens a chapter) — one batch, after the four pilots.
3. Grep-audits for edges (§1 step 1) only on halls the beat audit marks "disturbance: null" AND "edge: qfep only". That is where a rewrite changes the most.
4. Rewrites one hall at a time, each as an iteration folder like this one: `before/`, `final.candidate.md`, `final.diff`, `DECISIONS.md` with a beat table citing lines. Palle installs.

## 5. Two rules that keep it honest

- **An edge that is a bug is still an edge, but it is a decision.** The dead hand in Boids makes a better paragraph than a working one would; it is still a fault in the code's own promise. Every such case is written up as a decision for Palle, and the chapter and the code must end up agreeing.
- **A beat that the code changes under is a beat that must be re-read.** If a hall is later fitted, seeded, wired or clamped, its encounter paragraph is the first thing that goes stale. The `evidence` field on the task names the lines; a checker can diff them.
