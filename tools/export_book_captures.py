#!/usr/bin/env python3
"""Export current final.md files in sequence order, without artifact routing.

python tools/export_book_captures.py --sequence color
python tools/export_book_captures.py --all-spine
python tools/export_book_captures.py --all-spine --output-root ../ada_encyclopedia/captures/book

Source manuscripts are read only. Existing different captures get a dated backup.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
MAPS = ROOT / "commons/maps"
ANCHOR = re.compile(r"^[ \t]*<!--\s*@[^>\r\n]*-->[ \t]*$")
FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")
FOOTNOTE = re.compile(r"\[\^([^\]\s]+)\]")


def clean_text(text: str, map_name: str) -> str:
    """Leave fenced code intact; namespace footnotes across concatenated halls."""
    lines = []
    fence_char, fence_size = "", 0
    for line in text.replace("\r\n", "\n").splitlines():
        match = FENCE.match(line)
        if fence_char:
            lines.append(line)
            if match and match[1][0] == fence_char and len(match[1]) >= fence_size and not match[2].strip():
                fence_char, fence_size = "", 0
            continue
        if match:
            fence_char, fence_size = match[1][0], len(match[1])
            lines.append(line)
        elif not ANCHOR.fullmatch(line):
            lines.append(FOOTNOTE.sub(lambda m: f"[^{map_name}--{m[1]}]", line))
    return "\n".join(lines).strip("\n")


def read_json(path: Path):
    # Fail on malformed source instead of repairing quoted prose with a regex.
    return json.loads(path.read_text(encoding="utf-8-sig"))


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def git_value(*args: str) -> str:
    result = subprocess.run(["git", "-c", f"safe.directory={ROOT.as_posix()}", *args],
                            cwd=ROOT, capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else "unavailable"


def export(sequences: list[str], output_root: Path) -> None:
    captured = datetime.now(timezone.utc).isoformat()
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    base = {"captured_at": captured, "base_commit": git_value("rev-parse", "HEAD"),
            "branch": git_value("branch", "--show-current"), "source": "current working copy, including uncommitted edits",
            "transform": "Artifact-routing comments removed outside fenced code; footnote identifiers scoped per hall; footnote text and code preserved."}
    prepared = []
    # Read and validate every requested source before replacing any output.
    for seq in sequences:
        if not re.fullmatch(r"[\w-]+", seq):
            raise ValueError(f"Invalid sequence identifier: {seq}")
        sequence_path = MAPS / "sequences" / f"{seq}.json"
        maps = read_json(sequence_path)["sequences"][seq]["maps"]
        parts, sources = [f"# {seq}: the chapters", ""], []
        for name in maps:
            if not re.fullmatch(r"[\w-]+", name):
                raise ValueError(f"Invalid map identifier: {name}")
            path = MAPS / name / "final.md"
            raw = path.read_bytes()  # A missing hall must not disappear silently.
            text = clean_text(raw.decode("utf-8-sig"), name)
            parts += [f"## {name.replace('_', ' ')}", "", f"*{name}*", "", text, "", "---", ""]
            sources.append({"map": name, "path": path.relative_to(ROOT).as_posix(), "sha256": sha(raw)})
        body = "\n".join(parts).encode("utf-8")
        manifest = dict(base, sequence=seq, sequence_sha256=sha(sequence_path.read_bytes()),
                        maps=sources, output_sha256=sha(body))
        prepared.append((seq, body, manifest))
    for seq, body, manifest in prepared:
        folder = output_root / seq
        folder.mkdir(parents=True, exist_ok=True)
        dest = folder / f"{seq}-book.md"
        if dest.exists() and dest.read_bytes() != body:
            backup = folder / "history" / f"{seq}-book-{stamp}.md"
            backup.parent.mkdir(parents=True, exist_ok=True)
            backup.write_bytes(dest.read_bytes())
        dest.write_bytes(body)
        (folder / f"{seq}-book.manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    index = "# Book captures\n\nCurrent final.md texts in declared spine/sequence order. Source versions are recorded in each adjacent manifest.\n\n"
    index += "\n".join(f"- [{seq}]({seq}/{seq}-book.md) — {len(manifest['maps'])} halls" for seq, _, manifest in prepared)
    # Only a complete spine export owns the shared index.
    if len(sequences) > 1:
        (output_root / "index.md").write_text(index + "\n", encoding="utf-8")
    print(f"Exported {len(prepared)} sequences / {sum(len(m['maps']) for _, _, m in prepared)} halls to {output_root}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    choice = parser.add_mutually_exclusive_group(required=True)
    choice.add_argument("--sequence")
    choice.add_argument("--all-spine", action="store_true")
    parser.add_argument("--output-root", type=Path, default=ROOT / "doc/book/captures")
    args = parser.parse_args()
    sequences = [args.sequence] if args.sequence else [s["name"] for s in sorted(
        read_json(MAPS / "curriculum_spine.json")["spine"]["sequences"], key=lambda s: float(s["order"]))]
    export(sequences, args.output_root.resolve())


if __name__ == "__main__":
    main()
