# The Template Editor as the Match Cockpit — integrating museums, gates, and the judge

> Design note, 2026-08-01. The corpus now has three template machineries — the
> bred lineage (recipes + tournament), the inherited lineage (fourteen museums
> + crowns), and the gates/judge that adjudicate them. All of it runs from the
> CLI. The question: what does it look like inside a template EDITOR?

## The frame

The encyclopedia already has the surfaces: `/template-maps` (stamp-pattern
editor over `template_patterns.json` — the museum tiles are ALREADY in its
palette), `/map-builder`, and the reusable `GridEditor.tsx`. What is missing
is not an editor; it is the editor knowing what the last two days learned:
that a tile is a CLAIM which three gates and one judge can test. Integration
means moving the match loop's verbs — validate, join, walk, judge, crown —
into the surface where tiles are drawn.

## What the editor gains, in dependency order

**1. Provenance on the palette (data only, no new endpoints).** Each museum
tile in `/template-maps` shows its mechanism sentence, accent colour,
`em_order`, and — from `commons/data/museum_crowns.json` — crown badges: which
chapters it holds, with scores and the contested flag. The palette stops being
anonymous stamps and becomes a catalogue with reputations. Everything needed
is already JSON the encyclopedia can read via `ADA_RESEARCH_PATH`.

**2. The gate as a live linter (`POST /api/museum/validate`).** The server
shells to `tools/validate_museum_templates.py --candidate=<tmpfile>` and
returns the issue list. The editor paints verdicts on the exact cells: the
slot with no stop pocket, the sealed exit gap, the reachable void. The gate
that caught five broken ancestors becomes a red underline you see WHILE
drawing, not a postmortem. (Shell-out first; a TS port of the checker is a
later luxury — two implementations of one law is a drift risk the shell-out
avoids.)

**3. The walker as a preview (client-side, zero latency).** The autopilot's
planning half — BFS over standable cells from entry gap to exit gap — is
twenty lines of JS. Animate the route over the tile as you edit: you SEE the
walk your walls imply, the way `/map-wizard` shows the artifact strip. The
full physics walkthrough (gate F) stays repo-side; the preview is its shadow,
honest about being plan-not-body.

**4. The judge on demand (`POST /api/museum/match`).** Body: `{tile, seq}`.
The server stamps the candidate with that chapter's champion cast
(`tools/museum_match.py` already does everything; it needs a `--tile=` input
mode reading a JSON file instead of a pattern key) and returns the full
detail — tau, cov, promise, PATIENCE, dolly, rank1, cycles — plus where the
candidate lands in that chapter's merged leaderboard. Latency is real
(~90 s of gaze rides): run as a job with the score panel filling in when
done, exactly like the map-dna research lock pattern. The editing loop
becomes: draw → gate (instant) → walk preview (instant) → judge (a minute)
→ compare against BOTH lineages.

**5. The board as a page (`/museum-match`).** The match board and the rescore
audit rendered live from `doc/reports/museum_match_*.json` +
`bred_rescore/*.json` + the crowns file — the PNG logic as React. A cell
click opens the stamped Trial map in the map-sim live Godot viewer. Crowned
cells wear the accent; contested cells (primitives) wear both claims.

## The third lineage

The consequence that matters: the editor mints a THIRD provenance. A tile
saved from the editor is neither bred nor inherited — it is **edited**:
`{"provenance": "hand-edited", "ancestor": "castelvecchio-endstopped-enfilade",
"edited": "2026-08-XX"}`. Start from a museum, widen a bay, resite the hero,
re-judge. The tournament can then field all three lineages in one match, and
the crowns table stops being a two-party contest. This is the editor's real
role in the two-loop architecture: it is the slow loop's cockpit — breeding,
inheritance, and hand-editing feeding one judged pool — while the fast loop
(the endless museum) consumes whatever currently wears the crown, live, via
the same JSON files.

## Honest costs

- The judge's cast comes from surviving bred champion maps; if a champion is
  deleted the chapter can't be judged from the editor. (Fix: cache casts into
  a small JSON at match time.)
- Two sources of truth for "walkable" (JS preview vs python gate) WILL drift;
  the preview must always defer to the gate's verdict in the UI.
- Baselines predate the patience ruling — the board page must show ruled
  numbers from the rescore, not the stale tournament scores (the standing
  caveat, made visible).

## Build order (each step ships alone)

1. Palette provenance + crown badges (read-only, an afternoon).
2. `/museum-match` board page (read-only).
3. `POST /api/museum/validate` + cell-level linting.
4. Client-side walk preview.
5. `--tile=` mode on museum_match + `POST /api/museum/match` job.
6. Edited-lineage save + a three-lineage match run.
