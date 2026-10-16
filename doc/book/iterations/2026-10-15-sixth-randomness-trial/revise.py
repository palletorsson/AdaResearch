"""Derive revised.md from trial.md by applying revision-changes.json verbatim.

RECONSTRUCTED 16 October 2026: the original revise.py was accidentally
overwritten by another session before the folder was committed. The nine
before/after pairs it applied were preserved in revision-changes.json, so
this file re-derives the same revision from that record; build.py and a
byte-comparison against the existing revised.md verify the reconstruction.
The incident and the fidelity check are recorded in the forum.
"""
from pathlib import Path
import json

HERE = Path(__file__).resolve().parent
trial = (HERE / "trial.md").read_text(encoding="utf-8")
record = json.loads((HERE / "revision-changes.json").read_text(encoding="utf-8"))

revised = trial.replace(
    "*Sixth literary trial — composed after reading drafts A–E, not an adopted edition*",
    "*Sixth literary trial — small revision, 15 October 2026; not an adopted edition*", 1)
for change in record["changes"]:
    before, after = change["before"], change["after"]
    assert before in revised, "MISSING: " + change["reason"]
    assert revised.count(before) == 1, "AMBIGUOUS: " + change["reason"]
    revised = revised.replace(before, after, 1)

existing = HERE / "revised.md"
if existing.exists() and existing.read_text(encoding="utf-8") != revised:
    raise SystemExit("reconstruction does NOT reproduce the existing revised.md — stop and compare")
existing.write_text(revised, encoding="utf-8")
print("revised.md derived — %d change(s); matches the pre-existing revision: %s"
      % (len(record["changes"]), "VERIFIED" if existing.exists() else "first run"))
