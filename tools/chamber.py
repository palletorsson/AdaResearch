#!/usr/bin/env python3
"""
chamber.py — auto-improvement loop for artifacts.

The chamber proposes changes without polluting the repo. Each iteration
produces three durable artifacts: a proposal.md (prompt), a changes.patch
(machine-applicable diff), and before/after captures.

Subcommands:
  init <artifact>           seed a new draft (context bundle + worktree + before/)
  finalize <artifact>       capture after/, write changes.patch + proposal.md
  approve <artifact>        promote latest draft to approved/
  reject  <artifact>        move latest draft to rejected/ with a reason
  list                      show drafts / approved / rejected counts

Spec: doc/CHAMBER_PROPOSAL_FORMAT.md

The script is intentionally lean — it's scaffolding, not the brain. Claude
fills in the proposal text and the code edits. The script handles paths,
context-gathering, captures, and lifecycle.

Run:
  python tools/chamber.py init point
  python tools/chamber.py finalize point
  python tools/chamber.py approve point
  python tools/chamber.py reject point --reason="visual cluttered"
  python tools/chamber.py list
"""

from __future__ import annotations

import argparse
import datetime
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

# ─────────────────────────────────────────────────────────────────
# Paths
# ─────────────────────────────────────────────────────────────────

REPO = Path(__file__).resolve().parent.parent
CHAMBER = REPO / "data" / "chamber"
DRAFT = CHAMBER / "draft"
APPROVED = CHAMBER / "approved"
REJECTED = CHAMBER / "rejected"
WORKTREES = REPO / ".claude" / "worktrees"
REGISTRY_DIR = REPO / "commons" / "artifacts" / "registry"
SEQUENCES_DIR = REPO / "commons" / "maps" / "sequences"
MAPS_DIR = REPO / "commons" / "maps"
GODOT_EXE = os.environ.get(
    "GODOT_EXE",
    r"C:\Users\palle\Desktop\Godot_v4.6-stable_win64.exe",
)
CAPTURE_SCRIPT = "res://commons/testing/capture_multi_angle.gd"


# ─────────────────────────────────────────────────────────────────
# Helpers — artifact lookup & @identity parsing
# ─────────────────────────────────────────────────────────────────

def find_artifact_in_registry(lookup_name: str) -> dict | None:
    """Search every commons/artifacts/registry/*.json for a matching entry.

    Returns the entry dict (with at least `lookup_name`, `scene_path`) plus
    a `category` field set to the registry filename, or None.
    """
    if not REGISTRY_DIR.is_dir():
        return None
    for reg_file in sorted(REGISTRY_DIR.glob("*.json")):
        try:
            with reg_file.open(encoding="utf-8") as f:
                doc = json.load(f)
        except Exception:
            continue
        # Registries vary in shape — handle:
        #   {"artifacts": {<name>: {...}, ...}}    ← most common in this repo
        #   {"artifacts": [{...}, ...]}            ← list form
        #   {<name>: {...}, ...}                   ← top-level dict
        #   [{...}, ...]                           ← top-level list
        entries = []
        if isinstance(doc, dict):
            arts = doc.get("artifacts")
            if isinstance(arts, dict):
                for k, v in arts.items():
                    if isinstance(v, dict):
                        v = dict(v)
                        v.setdefault("lookup_name", k)
                        entries.append(v)
            elif isinstance(arts, list):
                entries = arts
            else:
                # top-level dict keyed by lookup_name
                for k, v in doc.items():
                    if isinstance(v, dict):
                        v = dict(v)
                        v.setdefault("lookup_name", k)
                        entries.append(v)
        elif isinstance(doc, list):
            entries = doc
        for entry in entries:
            if not isinstance(entry, dict):
                continue
            if entry.get("lookup_name") == lookup_name:
                entry = dict(entry)
                entry["_registry_file"] = reg_file.name
                entry["_registry_category"] = reg_file.stem
                return entry
    return None


def gd_path_for_scene(scene_path: str) -> Path | None:
    """Given a scene path like 'res://algorithms/.../point.tscn', try to find
    the matching .gd file. Looks for sibling .gd with the same stem first."""
    if not scene_path:
        return None
    rel = scene_path.replace("res://", "").replace("/", os.sep)
    abs_scene = REPO / rel
    if not abs_scene.exists():
        # Try just the stem under common roots
        stem = Path(rel).stem
        for root in ["algorithms", "commons", "addons"]:
            for p in (REPO / root).rglob(f"{stem}.gd"):
                return p
        return None
    sibling_gd = abs_scene.with_suffix(".gd")
    if sibling_gd.exists():
        return sibling_gd
    # Read the scene file for an ext_resource pointing at a .gd
    try:
        text = abs_scene.read_text(encoding="utf-8")
        m = re.search(r'path="(res://[^"]+\.gd)"', text)
        if m:
            return REPO / m.group(1).replace("res://", "").replace("/", os.sep)
    except Exception:
        pass
    return None


IDENTITY_KEYS = [
    "essence", "desire", "critical_parameter", "triggers",
    "emerges", "needs", "relationships", "truth",
]


def extract_identity(gd_path: Path) -> dict:
    """Pull the # @identity block out of a .gd file. Returns {} if none."""
    if not gd_path.exists():
        return {}
    try:
        lines = gd_path.read_text(encoding="utf-8").splitlines()
    except Exception:
        return {}
    in_block = False
    out: dict = {}
    for line in lines:
        s = line.strip()
        if s.startswith("# @identity"):
            in_block = True
            continue
        if not in_block:
            continue
        if not s.startswith("#"):
            break
        body = s.lstrip("#").strip()
        if not body:
            break
        for key in IDENTITY_KEYS:
            prefix = key + ":"
            if body.startswith(prefix):
                out[key] = body[len(prefix):].strip()
                break
    return out


# ─────────────────────────────────────────────────────────────────
# Helpers — placement & neighbours
# ─────────────────────────────────────────────────────────────────

def find_maps_using(lookup_name: str, limit: int = 10) -> list[dict]:
    """Return a list of {map_name, position} for maps whose interactables
    layer references this lookup_name."""
    found = []
    if not MAPS_DIR.is_dir():
        return found
    for map_dir in sorted(MAPS_DIR.iterdir()):
        if not map_dir.is_dir():
            continue
        md = map_dir / "map_data.json"
        if not md.exists():
            continue
        try:
            with md.open(encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            continue
        layers = data.get("layers", {})
        inter = layers.get("interactables")
        if not isinstance(inter, list):
            continue
        positions: list[list[int]] = []
        for z, row in enumerate(inter):
            if not isinstance(row, list):
                continue
            for x, cell in enumerate(row):
                if not isinstance(cell, str):
                    continue
                # cells may be "lookup_name:rotation:y_offset" — match the prefix
                if cell.split(":")[0] == lookup_name:
                    positions.append([x, 0, z])
        if positions:
            found.append({
                "name": map_dir.name,
                "positions": positions[:5],
            })
        if len(found) >= limit:
            break
    return found


def find_sequences_for_map(map_name: str) -> list[dict]:
    """Walk sequence files, return any that include map_name."""
    out = []
    if not SEQUENCES_DIR.is_dir():
        return out
    for seq_file in sorted(SEQUENCES_DIR.glob("*.json")):
        try:
            with seq_file.open(encoding="utf-8") as f:
                doc = json.load(f)
        except Exception:
            continue
        # Sequence shapes vary; do a simple "is map_name a string anywhere?"
        text_blob = json.dumps(doc)
        if f'"{map_name}"' in text_blob:
            out.append({"id": seq_file.stem, "file": seq_file.name})
    return out


# ─────────────────────────────────────────────────────────────────
# Subcommands
# ─────────────────────────────────────────────────────────────────

def cmd_init(args) -> int:
    lookup = args.artifact
    print(f"chamber init: {lookup}")
    print("=" * 60)

    # 1. Find the artifact
    entry = find_artifact_in_registry(lookup)
    if entry is None:
        print(f"  !! could not find '{lookup}' in any registry under {REGISTRY_DIR}",
              file=sys.stderr)
        return 1
    print(f"  registry: {entry.get('_registry_file')}")
    scene_path = entry.get("scene_path") or entry.get("scene") or ""
    print(f"  scene:    {scene_path}")
    gd_path = gd_path_for_scene(scene_path)
    if gd_path:
        gd_rel = gd_path.relative_to(REPO).as_posix()
        print(f"  code:     {gd_rel}")
    else:
        gd_rel = ""
        print("  code:     (not found — Claude will need to locate manually)")

    # 2. @identity
    identity = extract_identity(gd_path) if gd_path else {}
    if identity:
        print(f"  identity: {len(identity)}/8 fields parsed")
    else:
        print("  identity: (none — artifact may need an @identity block first)")

    # 3. Placement
    maps = find_maps_using(lookup)
    print(f"  maps:     {len(maps)} reference(s)")
    sequences = []
    seen_seqs: set = set()
    for m in maps:
        for s in find_sequences_for_map(m["name"]):
            if s["id"] not in seen_seqs:
                seen_seqs.add(s["id"])
                sequences.append(s)
    print(f"  sequences: {len(sequences)}")

    # 4. Build context bundle
    timestamp = datetime.datetime.now().strftime("%Y-%m-%dT%H-%M")
    draft_dir = DRAFT / lookup / timestamp
    draft_dir.mkdir(parents=True, exist_ok=True)
    (draft_dir / "before").mkdir(exist_ok=True)
    (draft_dir / "after").mkdir(exist_ok=True)

    bundle = {
        "artifact": {
            "lookup_name": lookup,
            "code_path":   gd_rel,
            "scene_path":  scene_path,
            "category":    entry.get("_registry_category"),
            "registry_entry": {k: v for k, v in entry.items()
                               if not k.startswith("_")},
            "identity":    identity,
        },
        "placement": {
            "sequences": sequences,
            "maps":      maps,
            "scenes_before": [],   # populated by future fractal-API enrichment
            "scenes_after":  [],
        },
        "neighbors": {
            "siblings_in_scene":    [],
            "siblings_in_sequence": [],
            "related_by_essence":   [],
        },
        "constraints": {
            "curriculum_honesty": [
                "no random before seq 7",
                "no noise before seq 8",
                "no cellular automata before seq 9",
                "no fractals before seq 10",
                "no L-systems before seq 11",
                "no DNA-driven procgen before seq 12",
                "no soft bodies before seq 13",
                "no flocking before seq 14",
            ]
        },
        "history": {"recent_changes": [], "open_questions": []},
        "_meta": {"generated_by": "chamber.py init", "timestamp": timestamp},
    }
    (draft_dir / "context_bundle.json").write_text(
        json.dumps(bundle, indent=2), encoding="utf-8"
    )

    # 5. Worktree
    worktree_path = WORKTREES / f"chamber-{lookup}-{timestamp}"
    worktree_branch = f"chamber/{lookup}-{timestamp}"
    print(f"  worktree: {worktree_path.relative_to(REPO).as_posix()}")
    if worktree_path.exists():
        print("    (already exists — reusing)")
    else:
        try:
            subprocess.run(
                ["git", "worktree", "add", str(worktree_path), "-b", worktree_branch],
                cwd=REPO, check=True, capture_output=True, text=True
            )
        except subprocess.CalledProcessError as e:
            print(f"    !! git worktree add failed: {e.stderr}", file=sys.stderr)
            print("       leaving the draft scaffolded; create the worktree manually",
                  file=sys.stderr)

    # 6. meta.json
    meta = {
        "lookup_name": lookup,
        "timestamp":   timestamp,
        "status":      "draft",
        "created_at":  datetime.datetime.now().isoformat(timespec="seconds"),
        "worktree":    worktree_path.relative_to(REPO).as_posix() \
                       if worktree_path.exists() else None,
        "rating":      None,
        "decision":    None,
        "decided_at":  None,
    }
    (draft_dir / "meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")

    # 7. Print next steps
    print()
    print(f"  draft:    {draft_dir.relative_to(REPO).as_posix()}")
    print()
    print("Next steps for Claude:")
    print(f"  1. Read {draft_dir.relative_to(REPO).as_posix()}/context_bundle.json")
    print(f"  2. Edit the artifact in the worktree:")
    if gd_rel:
        print(f"     {worktree_path.as_posix()}/{gd_rel}")
    print(f"  3. python tools/chamber.py finalize {lookup}")
    return 0


def cmd_finalize(args) -> int:
    """Capture after/, generate changes.patch, scaffold proposal.md.

    proposal.md gets a template with the prompt structure; Claude fills
    in 'What to change' / 'Why' / 'Curriculum honesty' from context.
    """
    lookup = args.artifact
    draft_dir = _latest_draft(lookup)
    if draft_dir is None:
        print(f"  !! no draft for '{lookup}' under {DRAFT}", file=sys.stderr)
        return 1
    print(f"chamber finalize: {draft_dir.relative_to(REPO).as_posix()}")

    meta = _read_meta(draft_dir)
    worktree = REPO / meta.get("worktree", "") if meta.get("worktree") else None
    if not worktree or not worktree.exists():
        print(f"  !! worktree missing: {worktree}", file=sys.stderr)
        return 1

    # 1. git diff > changes.patch (run inside the worktree)
    try:
        result = subprocess.run(
            ["git", "diff", "--no-color"],
            cwd=worktree, check=True, capture_output=True, text=True
        )
        patch_text = result.stdout
    except subprocess.CalledProcessError as e:
        print(f"  !! git diff failed: {e.stderr}", file=sys.stderr)
        return 1
    (draft_dir / "changes.patch").write_text(patch_text, encoding="utf-8")
    n_lines = patch_text.count("\n")
    print(f"  patch:    changes.patch ({n_lines} lines)")
    if n_lines == 0:
        print("  ⚠ patch is empty — no changes detected in worktree")

    # 2. Capture after/ (best-effort; user may run capture separately)
    bundle = json.loads((draft_dir / "context_bundle.json").read_text(encoding="utf-8"))
    code_path = bundle.get("artifact", {}).get("code_path", "")
    if code_path and Path(GODOT_EXE).exists():
        # Capture from the worktree project root
        cmd = [
            GODOT_EXE, "--path", str(worktree),
            "--xr-mode", "off", "--no-window",
            "--script", CAPTURE_SCRIPT, "--",
            "--mode=artifact", f"--target={lookup}",
            f"--out=user://chamber_after_{lookup}",
        ]
        print("  capture:  godot (after/)")
        try:
            subprocess.run(cmd, check=False, capture_output=True, timeout=120)
        except Exception as e:
            print(f"    !! capture failed: {e}", file=sys.stderr)
    else:
        print("  capture:  skipped (no code_path or GODOT_EXE not found)")

    # 3. Scaffold proposal.md if not present (Claude fills in the body)
    prop_path = draft_dir / "proposal.md"
    if not prop_path.exists():
        identity = bundle.get("artifact", {}).get("identity", {})
        seqs = bundle.get("placement", {}).get("sequences", [])
        maps = bundle.get("placement", {}).get("maps", [])
        prop_path.write_text(
            "# Improvement: %s — <slug>\n" % lookup
            + "artifact: %s\n" % code_path
            + "date:     %s\n" % datetime.datetime.now().isoformat(timespec='minutes')
            + "sequence: %s\n" % (", ".join(s["id"] for s in seqs) or "<none>")
            + "maps:     %s\n" % (", ".join(m["name"] for m in maps) or "<none>")
            + "identity: \"%s\"\n\n" % identity.get("essence", "")
            + "## What to change\n<2-5 sentences describing the change.>\n\n"
            + "## Why\n@identity essence: \"%s\"\n" % identity.get("essence", "")
            + "<connect change to essence — what does the player feel/understand?>\n\n"
            + "## Curriculum honesty\n✓ Uses: <techniques + seq>\n"
            + "✓ Does NOT use: <forbidden by curriculum at this seq>\n\n"
            + "## Captures\nbefore/{front,left,right,top}.png\n"
            + "after/{front,left,right,top}.png\n\n"
            + "## Apply with\n"
            + "git apply data/chamber/draft/%s/%s/changes.patch\n"
            % (lookup, draft_dir.name)
            + "  OR\n"
            + "/ada-artifact-improver %s --proposal=<path>\n" % lookup,
            encoding="utf-8",
        )
        print(f"  proposal: scaffolded {prop_path.relative_to(REPO).as_posix()} "
              "— Claude should fill in the body")
    else:
        print(f"  proposal: {prop_path.relative_to(REPO).as_posix()} (already present)")

    print()
    print("Review:")
    print(f"  {draft_dir.relative_to(REPO).as_posix()}")
    print(f"Approve: python tools/chamber.py approve {lookup}")
    print(f"Reject:  python tools/chamber.py reject  {lookup} --reason=\"...\"")
    return 0


def cmd_approve(args) -> int:
    lookup = args.artifact
    draft_dir = _latest_draft(lookup)
    if draft_dir is None:
        print(f"  !! no draft for '{lookup}'", file=sys.stderr)
        return 1
    target = APPROVED / lookup / draft_dir.name
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(draft_dir), str(target))
    _update_meta(target, status="approved", decision="approve",
                 decided_at=datetime.datetime.now().isoformat(timespec="seconds"),
                 rating=args.rating)
    print(f"  approved -> {target.relative_to(REPO).as_posix()}")
    return 0


def cmd_reject(args) -> int:
    lookup = args.artifact
    draft_dir = _latest_draft(lookup)
    if draft_dir is None:
        print(f"  !! no draft for '{lookup}'", file=sys.stderr)
        return 1
    target = REJECTED / lookup / draft_dir.name
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(draft_dir), str(target))
    reason_path = target / "reason.md"
    reason_path.write_text(
        f"# Why rejected: {lookup} — {target.name}\n\n"
        f"## What didn't work\n{args.reason}\n\n"
        f"## What to try instead\n<optional>\n\n"
        f"## Tags\n{args.tag or '<one or more>'}\n",
        encoding="utf-8",
    )
    _update_meta(target, status="rejected", decision="reject",
                 decided_at=datetime.datetime.now().isoformat(timespec="seconds"))
    # Always remove rejected worktrees — no further iteration
    meta = _read_meta(target)
    wt_rel = meta.get("worktree")
    if wt_rel:
        wt_abs = REPO / wt_rel
        if wt_abs.exists():
            try:
                subprocess.run(
                    ["git", "worktree", "remove", "--force", str(wt_abs)],
                    cwd=REPO, check=True, capture_output=True
                )
                print(f"  worktree removed: {wt_rel}")
            except subprocess.CalledProcessError:
                print(f"  ⚠ worktree remove failed; rm manually: {wt_rel}")
    print(f"  rejected -> {target.relative_to(REPO).as_posix()}")
    return 0


def cmd_list(args) -> int:
    print("Chamber state:")
    print()
    for label, root in [("draft", DRAFT), ("approved", APPROVED), ("rejected", REJECTED)]:
        if not root.is_dir():
            print(f"  {label:9s}: 0")
            continue
        items: list[tuple[str, str]] = []
        for art_dir in sorted(root.iterdir()):
            if not art_dir.is_dir():
                continue
            for ts_dir in sorted(art_dir.iterdir()):
                if ts_dir.is_dir():
                    items.append((art_dir.name, ts_dir.name))
        print(f"  {label:9s}: {len(items)}")
        for art, ts in items[-10:]:
            print(f"      {art:30s}  {ts}")
    return 0


# ─────────────────────────────────────────────────────────────────
# Internals
# ─────────────────────────────────────────────────────────────────

def _latest_draft(lookup: str) -> Path | None:
    art_dir = DRAFT / lookup
    if not art_dir.is_dir():
        return None
    candidates = sorted([p for p in art_dir.iterdir() if p.is_dir()], reverse=True)
    return candidates[0] if candidates else None


def _read_meta(d: Path) -> dict:
    p = d / "meta.json"
    if not p.exists():
        return {}
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return {}


def _update_meta(d: Path, **kwargs) -> None:
    meta = _read_meta(d)
    meta.update(kwargs)
    (d / "meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")


# ─────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("init", help="seed a new draft for an artifact")
    p.add_argument("artifact", help="artifact lookup_name (e.g. 'point')")
    p.set_defaults(func=cmd_init)

    p = sub.add_parser("finalize", help="finalize a draft (capture after, write patch)")
    p.add_argument("artifact")
    p.set_defaults(func=cmd_finalize)

    p = sub.add_parser("approve", help="promote latest draft to approved/")
    p.add_argument("artifact")
    p.add_argument("--rating", choices=["gold", "silver", "bronze"], default=None)
    p.set_defaults(func=cmd_approve)

    p = sub.add_parser("reject", help="move latest draft to rejected/")
    p.add_argument("artifact")
    p.add_argument("--reason", required=True, help="why rejected (1-2 sentences)")
    p.add_argument("--tag", default="", help="visual-cluttered | curriculum-broken | ...")
    p.set_defaults(func=cmd_reject)

    p = sub.add_parser("list", help="show drafts/approved/rejected counts")
    p.set_defaults(func=cmd_list)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
