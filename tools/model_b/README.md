# Care Unit / Model B — first exploration brain

An opt-in developer player, using the actual Void body and camera. The connected assistant supplies reasoning through `tools/model_b.py`; `brain.gd` executes short physical actions, returns observations and retains evidence-linked session memory. No RT-1/RT-2 checkpoint, trained navigation policy or background LLM service is installed.

This follows `doc/book/MODEL_B_WORKING_SPEC.md`: the player plays Model B's body; intellect does not imply knowing the tower; care can shape attention without a score, compulsory repair or a purpose meter. Claims can be hypotheses, interpretations or matters of attention. Only the engine writes measured action outcomes.

## Start and observe

Run commands from the repository root. Use a fresh session directory each time.

```powershell
python tools/model_b.py run --session ada_run/model-b/my-session --floor 14
```

The launcher uses the shared OS native-test lock and an isolated `user://`. By default its window is hidden; `--visible` explicitly opens a desktop window. It neither changes room arrangements nor controls the human's existing running game.

In another terminal or tool call:

```powershell
python tools/model_b.py observe --session ada_run/model-b/my-session
python tools/model_b.py act --session ada_run/model-b/my-session --yaw-degrees -30 --seconds 0.2 --reason "Inspect the construction on my left."
python tools/model_b.py act --session ada_run/model-b/my-session --forward 1 --seconds 0.4 --reason "Approach the visible edge briefly."
python tools/model_b.py remember --session ada_run/model-b/my-session --kind hypothesis --text "This striped face may be a ramp." --evidence obs_0002
python tools/model_b.py stop --session ada_run/model-b/my-session
python tools/model_b.py resume --session ada_run/model-b/my-session
python tools/model_b.py close --session ada_run/model-b/my-session
python tools/model_b.py recall --session ada_run/model-b/my-session --query slope
```

Actions use local forward/strafe axes (-1 to 1), relative yaw (positive right, at most 90 degrees), relative pitch (positive up, at most 45 degrees), optional jump and 0.05–1.5 simulation seconds. Godot retains collision, slope, gravity, momentum, charge and checkpoint behavior. The pilot pauses the simulation between decisions, including imported mounts that otherwise process while paused. This establishes a turn-based observation/action loop, not real-time navigation performance.

Every action needs the current observation ID and a short public decision reason. The client supplies the latest ID by default. A consumed/stale frame, invalid action, exhausted body or missing jump support cannot drive another movement. During recovery the agent can look or wait. At ten charge or less movement yields for attention; this is a developer execution guard using the existing charge resource, not a new account of care.

`stop` interrupts even an action in flight and restores the original human input settings. It clears drive without teleporting or resetting momentum. `resume` explicitly reacquires this isolated body's controls. An unattended session closes after 180 wall-clock seconds (`--idle` changes this); the launcher also has an absolute watchdog. Close sessions when done to release the shared native slot.

## Perception and audit

`latest.json` links the real player-eye PNG and supplies body feedback, the stated goal, previous outcomes and bounded memory. It does not contain world coordinates, an artifact inventory, route waypoints, a navigation mesh or commands that edit/teleport the world. A reached checkpoint is reported as checkpoint evidence; semantic task completion remains unassessed.

`audit` is an explicitly privileged diagnostic operation. It returns coordinates and collision identities and records that access in `events.jsonl`. Developer audit snapshots are kept separately from perception. Do not feed them into a supposedly vision-only navigation evaluation.

The persisted `memory.json`, observation pairs and `events.jsonl` make claims and outcomes reviewable. Working memory keeps 24 entries; `recall` searches the persisted notebook even after shutdown. Retrieval does not revalidate a hypothesis in a changed layout. Human-readable reasons are brief action explanations, not model-internal reasoning traces.

## What this first version establishes

- A working connection for **observe → reason externally → act → observe**.
- A provider-neutral interface: another model can use the same client and action contract later.
- Evidence-linked hypotheses, interpretations, attention and measured outcomes.
- Bounded motion, source physics, clear human ownership and session closure.

It does not establish an independently running learned policy, unfamiliar-map competence, manipulation skills or headset control. Ordinary desktop and Quest launches are unchanged. All new pilot runtime code lives under `tools/`, already excluded by the game export presets.

Run `python tools/test_model_b_brain.py` for the native protocol checks. Run details and the first assistant-led exploration are in `ada_run/model-b-brain-2026-10-26/`.
