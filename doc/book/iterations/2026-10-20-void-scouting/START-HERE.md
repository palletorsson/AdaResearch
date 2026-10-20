# Two independent scouts: Antigravity and Claude Code

Prepared 20 October 2026. Scope: Random_Definition and the opening Noise route, Random_Noise_Types → Noise_Columns → Noise_One.

## Current status

**Update: both desktop reports are complete and reviewed.** See [ASSESSMENT.md](ASSESSMENT.md) for the comparison, corrections and proposed first trial. The dispatch observations below record the earlier start of each run. No implementation or runtime testing has been performed for this scouting comparison.

- **Claude Code: running in the desktop app.** Computer control submitted the common brief in a fresh session titled “Museum to Void scouting trial,” using the existing AdaResearch_46 environment and its selected model. The app replied that it would read the brief, inventory and source index, then began a file search. The earlier standalone CLI authentication failure remains in `runs/claude.json`; it did not prevent the desktop session from starting.
- **Antigravity: running in the desktop app.** Computer control submitted the same brief in the AdaResearch_46 project, with its existing Gemini 4 Argon High selection. The session is titled “Void Skyscraper Scouting Report.” Its visible progress lists reads of tutorial.md, final.md, floor_content.gd, rooms.schema.json, hall_seed.gd and the source manifest.
- **Gemini CLI is not the requested Antigravity trial.** A preliminary command failed argument validation before a scouting response. It is excluded from comparison.
- **Both agents were instructed to read only and return reports in their conversations.** No implementation was requested. Dispatch and visible source reading are confirmed; completed reports and their claims have not yet been reviewed. Source inspection is not runtime, collision, VR or editorial approval.
- **Snapshot integrity:** all 182 captured files match their recorded hashes. The live Transformation trial's rooms.json changed after capture; its copy is only a reference example, not authority for a future edit. Re-read live layout and registration files before implementation. See `source-check.json`.

## Start in Antigravity

Open this folder as the scouting workspace, then paste the prompt below into a fresh conversation. Keep the report in that conversation. The packet is a source-reading snapshot, not a runnable project.

## Start in Claude Code

Sign in using Claude Code's normal login flow. Open this folder and paste the same prompt into a fresh conversation. The earlier authentication failure is retained as evidence; it is not a completed scouting attempt.

## Same prompt for both

> Read BRIEF.md, inventory.json and source-index.md in this folder. Inspect relevant source files under sources/. Independently scout how Random_Definition, Random_Noise_Types, Noise_Columns and Noise_One can inhabit the Void construction tower. Preserve the actual artifact operations and chosen tutorial focus. Propose both staged and architectural uses, connected visibly to the overhead supply line. Distinguish existing behaviour, proposed adapters and unknowns. Follow the output format and propose falsifiable tests. Read only: do not edit, run code, access accounts or delegate. Return your complete report in this conversation. Do not read COORDINATOR-NOTES.md or another agent's answer before making your proposal.

When using the repository rather than the extracted packet, the briefing folder is:

`C:\Users\palle\Documents\GitHub\AdaResearch_46\doc\book\iterations\2026-10-20-void-scouting`

## Compare, then build

1. Collect both independent answers; record provider, model if disclosed, date and source snapshot.
2. Review with REVIEW-CHECKLIST.md. Verify citations against the snapshot. Preserve disagreements and unresolved measurements.
3. Compare with COORDINATOR-NOTES.md only after each agent has made its own proposal.
4. Choose one separate selectable trial floor. Preserve the curated tower.
5. Implement the chosen adapter and test its actual behaviour, streaming, editor save/reload and desktop/VR parity. Only then record runtime results and inside-tower screenshots.

The downloadable `scout-packet.zip` includes the common brief, inventory, source index, manifest, source copies and Godot ignore marker. It deliberately excludes coordinator proposals, other agents' receipts and local tool settings.

Google documents a separate headless CLI, but its availability in documentation does not mean it is installed here: https://www.antigravity.google/docs/cli/headless/
