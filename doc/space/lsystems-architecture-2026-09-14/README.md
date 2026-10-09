# Architecture — 14 September 2026

[Photographs and book](http://localhost:3003/research/possible-bodies/lsystems-architecture.html) · [Primary card](http://localhost:3003/necklace/thread?map=LSystems_Architecture&role=primary)

Architecture's first-pass encounter is implemented. One rewrite of the existing branch grammar gives `F[+RF][-RF]F`: four segments, two R records and one shared room address. The same records become a full-size plan or a built corridor. The six controls are PLAN, BUILD, WIDTH, ROOMS, RESET and RULE.

The 0.6-metre desktop capsule traverses the 1.4-metre corridor, turns into a side branch, returns and exits. At 0.4 metres it stops at the entrance, at local z≈0.424. The optional 2.8×2.8-metre junction gives it room to stand away from the centreline. These changes preserve the grammatical records. An occupied-space check refuses rebuilding until a fresh press outside the brass frame.

## Preserved work

All nine authored artifact tokens remain. Roles remain one primary, seven secondary and one decoration. The original 13×12 structure is embedded at (3,23) in a 19×39 hall. Its raised cells and the eight other placements are preserved, and the obsolete teleporter hole is filled. Two rear floor rows provide turning space between the retained wall and the museum's exit frame; earlier captures showed the outer route stopping there.

The original dungeon miniature stands on a rear plinth. Its four grammar definitions, default warren/depth-three settings and interpreter remain. The ordinary miniature still reports 306 segments, 138 room records and 612 side walls. A shared production/interpretation interface supplies both the miniature and the opt-in lesson without changing the miniature's settings. Secondary algorithms and the registry are unchanged from the start of this turn.

The old room texts substantially overstated the miniature's implementation: they described navigable collision geometry, per-cell boundary construction, city block extraction and a tree topology guaranteed by context-free rewriting. The new text separates those claims and describes the implemented encounter. Earlier essays and source are retained in `before/`; the successful baseline run is in `baseline/`.

## Evidence

- Final hidden Godot PID **35740**, exit 0: **53 checks**, zero failures. See `receipt.json`, `runtime-report.json` and `engine.log`. Current sources match every recorded hash. All six controls were exercised through the real DesktopPlayer pointer; geometry refusal checks called the action handler with an actual player body inside. Route tests use synthetic movement through DesktopPlayer.
- **38 scoped content checks** pass: all artifacts, structure, roles, primary/book alignment, unchanged other hall entries, original grammar/interpreter, retained sources and current receipt hashes. See `content-checks.json`.
- **23 published assets** have exact HTTP hashes. See `http-checks.json` and `published-files.json`.
- Browser inspection confirms ten loaded review photographs, no horizontal overflow, both working book disclosures and the **675-word lsystem_dungeon primary passage**. The working method advances to Competition. See `browser-checks.json`.

The run used isolated hand/control/plan files and muted hidden Godot, preserving editor PID 40112 and the saved hand. No existing game was stopped; no agents or commits were used. A first baseline probe had an indentation error, corrected before the successful baseline capture. Intermediate route failures prompted the two rear rows; the final route passes.

## Limits and next iteration

Headset reach, readability, comfort, Quest timing and other player-body configurations remain pending. DesktopPlayer input is a distinct test lane from the museum's native walker and a human headset visit. The original miniature does not implement the new junction/door policy or player collision. Secondary controls, more complicated or angled grammars, stronger shared-consent rules and the partly overlapping rear catalyst/model presentation can be refined later.

Earlier receipts are not silently renewed by this run. Grammar Lab remains valid under exact executable hashes and archive-backed per-hall shared records. Growth was already stale after independent source changes. Curves' recorded registry file differs from the version already present at the start of this turn; its executable scripts still match. The validator remains conservative about that registry difference. No unrelated edit was reverted or hash requirement weakened.

**Next: LSystems_Competition.** Inspect all existing material and the actual conditions that permit or interrupt growth before making claims about shared resources or ecology. Continue the full spine before rewriting the book as a whole.

Do not rerun `prepare_architecture.py`, `implement_architecture.py` or `finish_architecture_layout.py` over later work; they are one-time migrations. Verification: `python -X utf8 ada_run/check_architecture_content.py --http`. Publishing builder: `tools/build_lsystems_architecture_review.py`.
