"""Publish the complete printed continuation; run_checks.py verifies extraction."""
from pathlib import Path

HERE = Path(__file__).resolve().parent
text = (HERE / "tutorial-introduction.md").read_text(encoding="utf-8") + "\n"
for name in ("seed_record.gd", "seed_study.gd", "seed_board.gd"):
    text += f"\n## {name}\n\n<!-- student-code:{name} -->\n```gdscript\n"
    text += (HERE / "runtime" / name).read_text(encoding="utf-8") + "```\n"
(HERE / "tutorial.md").write_text(text, encoding="utf-8")
