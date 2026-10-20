"""Record current tutorial sources and listing sizes; no runtime/learner claim."""
from pathlib import Path
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SEQUENCE = ROOT / "commons/maps/sequences/randomness.json"


def digest(data):
    return hashlib.sha256(data).hexdigest()


sequence_bytes = SEQUENCE.read_bytes()
maps = json.loads(sequence_bytes)["sequences"]["randomness"]["maps"]
chapters = []
for order, name in enumerate(maps, 1):
    path = ROOT / "commons/maps" / name / "tutorial.md"
    data = path.read_bytes()
    text = data.decode("utf-8").replace("\r\n", "\n")
    prose = re.sub(r"```.*?```", "", text, flags=re.S)
    prose = re.sub(r"<!--.*?-->", "", prose, flags=re.S)
    prose = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", prose)
    blocks = re.findall(r"```gdscript\n(.*?)```", text, re.S)
    files = []
    for filename, code in re.findall(
        r"<!-- student-code:(\S+) -->\s*```gdscript\s*\n(.*?)```", text, re.S
    ):
        files.append({
            "name": filename,
            "nonblank_lines": sum(bool(line.strip()) for line in code.splitlines()),
            "normalised_code_sha256": digest(code.strip().encode("utf-8")),
        })
    chapters.append({
        "order": order,
        "map": name,
        "source": path.relative_to(ROOT).as_posix(),
        "source_sha256": digest(data),
        "prose_tokens": len(prose.split()),
        "nonblank_gdscript_lines": sum(
            sum(bool(line.strip()) for line in code.splitlines()) for code in blocks
        ),
        "student_files": files,
    })

result = {
    "review_date": "2026-10-15",
    "status": "source audit; progression proposed; no new runtime or learner trial",
    "reference": "https://natureofcode.com/random/",
    "sequence": SEQUENCE.relative_to(ROOT).as_posix(),
    "sequence_sha256": digest(sequence_bytes),
    "method": {
        "prose_tokens": "Whitespace tokens after removing fenced code and HTML comments, and replacing Markdown links with labels; includes headings and table punctuation. Not a publication word count.",
        "nonblank_gdscript_lines": "All nonempty lines in GDScript fences, including comments and repeated support files; not newly introduced algorithm lines.",
        "student_files": "Fences identified by existing student-code markers; code hash normalises CRLF and strips outer whitespace.",
        "limits": "Tutorial source and sequence metadata only. No claim that all listed scenes are placed, executable, accessible in VR, or effective for a learner.",
    },
    "chapters": chapters,
}
(HERE / "audit.json").write_text(
    json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
)
print(f"Recorded {len(chapters)} tutorials in {HERE / 'audit.json'}")
for chapter in chapters:
    print(chapter["order"], chapter["map"], chapter["prose_tokens"], chapter["nonblank_gdscript_lines"])
