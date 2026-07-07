#!/usr/bin/env python3
"""
apply_sieve_move.py — apply a single sieve proposal as a JSON edit.

Translates a proposal record into a structural edit on
`commons/maps/curriculum_spine.json` and/or
`commons/maps/sequences/<name>.json` and/or
`commons/maps/soft_stages.json`.

Supports four move types in v1:
  - phase change (e.g., phase E_entropy → phase λ_edge)
  - order change (e.g., order 9 → order 10)
  - layer change (e.g., layer X → layer Y, in the sequence file)
  - unlock-edge edit (add/remove from a sequence's `unlocks` array)

Everything else returns "manual move — apply by hand" with a clear note.

Every successful apply writes a backup to:
  data/sieve_proposals/backups/{pass_id}/{move_id}/
which contains the before-state of each affected JSON file so the move
can be rolled back deterministically.

Usage:
    python tools/apply_sieve_move.py --pass <id> --move <move_id>
    python tools/apply_sieve_move.py --pass <id> --move <move_id> --dry-run
    python tools/apply_sieve_move.py --rollback --pass <id> --move <move_id>

Background: doc/proposals/2026-05-13_chip-and-pause.md
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import shutil
import sys
from pathlib import Path
from typing import Optional

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

REPO_ROOT = Path(__file__).resolve().parent.parent
PROPOSALS_DIR = REPO_ROOT / "data" / "sieve_proposals"
BACKUPS_DIR = PROPOSALS_DIR / "backups"

SPINE_PATH = REPO_ROOT / "commons" / "maps" / "curriculum_spine.json"
SOFT_PATH = REPO_ROOT / "commons" / "maps" / "soft_stages.json"
SEQUENCES_DIR = REPO_ROOT / "commons" / "maps" / "sequences"


# -- Move-type detection -----------------------------------------------------

ORDER_RE = re.compile(r"order\s+([\d.]+)", re.IGNORECASE)
# Phase names may include unicode (λ_edge). Match any non-whitespace run after "phase ".
PHASE_RE = re.compile(r"phase\s+(\S+)", re.IGNORECASE)
LAYER_RE = re.compile(r"layer\s+(\S+)", re.IGNORECASE)
UNLOCK_RE = re.compile(r"unlocks?\b", re.IGNORECASE)


def detect_move_type(proposal: dict) -> str:
    """Return one of: phase, order, layer, unlock, schema, multi, unknown."""
    change = proposal.get("change", "")
    fs = proposal.get("from_state", "")
    ts = proposal.get("to_state", "")
    combined = f"{change} {fs} {ts}".lower()

    if ".unlocks" in change.lower() or UNLOCK_RE.search(change):
        return "unlock"
    # Detect both order and phase mentions
    has_order = ORDER_RE.search(fs) and ORDER_RE.search(ts)
    has_phase = PHASE_RE.search(fs) and PHASE_RE.search(ts)
    has_layer = "layer" in fs.lower() and "layer" in ts.lower()
    flags = [has_order, has_phase, has_layer]
    flag_count = sum(1 for x in flags if x)
    if flag_count > 1:
        return "multi"
    if has_phase:
        return "phase"
    if has_order:
        return "order"
    if has_layer:
        return "layer"
    if "duplicate" in combined or "schema" in combined:
        return "schema"
    return "unknown"


# -- Helpers -----------------------------------------------------------------

def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent="\t", ensure_ascii=False) + "\n", encoding="utf-8")


def backup_dir(pass_id: str, move_id: str) -> Path:
    return BACKUPS_DIR / pass_id / move_id


def backup_files(pass_id: str, move_id: str, paths: list[Path]) -> Path:
    """Copy the current state of each path under the backup dir. Returns dir."""
    bdir = backup_dir(pass_id, move_id)
    bdir.mkdir(parents=True, exist_ok=True)
    for p in paths:
        if p.exists():
            target = bdir / p.relative_to(REPO_ROOT)
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(p, target)
    # Record what was backed up
    manifest = {
        "pass_id": pass_id,
        "move_id": move_id,
        "backed_up_at": dt.datetime.now().isoformat(timespec="seconds"),
        "files": [str(p.relative_to(REPO_ROOT)) for p in paths if p.exists()],
    }
    (bdir / "manifest.json").write_text(json.dumps(manifest, indent="\t") + "\n", encoding="utf-8")
    return bdir


def restore_backup(pass_id: str, move_id: str) -> bool:
    bdir = backup_dir(pass_id, move_id)
    manifest_path = bdir / "manifest.json"
    if not manifest_path.exists():
        return False
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    for rel in manifest.get("files", []):
        src = bdir / rel
        dst = REPO_ROOT / rel
        if src.exists():
            shutil.copy2(src, dst)
    return True


# -- Move implementations ---------------------------------------------------

def find_spine_seq(spine: dict, name: str) -> Optional[dict]:
    for s in spine.get("spine", {}).get("sequences", []):
        if s.get("name") == name:
            return s
    return None


def apply_phase_move(proposal: dict, dry_run: bool) -> tuple[bool, str]:
    change = proposal["change"]
    new_phase_match = PHASE_RE.search(proposal["to_state"])
    if not new_phase_match:
        return False, "could not extract destination phase"
    new_phase = new_phase_match.group(1)
    # Normalise λ_edge → lambda_edge
    new_phase = new_phase.replace("λ_edge", "lambda_edge").replace("λedge", "lambda_edge")

    spine = load_json(SPINE_PATH)
    seq = find_spine_seq(spine, change)
    if not seq:
        return False, f"sequence {change!r} not found in spine"
    old_phase = seq.get("phase")
    if old_phase == new_phase:
        return False, f"already at phase {new_phase!r} — no-op"

    affected = [SPINE_PATH]
    seq_file = SEQUENCES_DIR / f"{change}.json"
    if seq_file.exists():
        affected.append(seq_file)

    if dry_run:
        return True, f"DRY-RUN: would set {change}.phase {old_phase!r} → {new_phase!r} in spine + sequence layer"

    backup_files(proposal["pass_id"], proposal["move_id"], affected)
    seq["phase"] = new_phase
    note = seq.get("note", "")
    timestamp = dt.datetime.now().strftime("%Y-%m-%d")
    seq["note"] = (note + f" | {timestamp}: phase moved from {old_phase} to {new_phase} via apply_sieve_move").strip(" |")
    write_json(SPINE_PATH, spine)

    # Update the sequence file's layer field if present
    if seq_file.exists():
        seq_data = load_json(seq_file)
        inner = seq_data.get("sequences", {}).get(change)
        if inner is not None and "layer" in inner:
            inner["layer"] = new_phase
            write_json(seq_file, seq_data)

    return True, f"applied {change}.phase {old_phase} → {new_phase}"


def apply_order_move(proposal: dict, dry_run: bool) -> tuple[bool, str]:
    change = proposal["change"]
    new_order_match = ORDER_RE.search(proposal["to_state"])
    if not new_order_match:
        return False, "could not extract destination order"
    new_order_str = new_order_match.group(1)
    new_order = float(new_order_str) if "." in new_order_str else int(new_order_str)

    spine = load_json(SPINE_PATH)
    seq = find_spine_seq(spine, change)
    if not seq:
        return False, f"sequence {change!r} not found in spine"
    old_order = seq.get("order")
    if old_order == new_order:
        return False, f"already at order {new_order} — no-op"

    affected = [SPINE_PATH, SOFT_PATH]
    if dry_run:
        return True, f"DRY-RUN: would set {change}.order {old_order} → {new_order} in spine + soft_stages"

    backup_files(proposal["pass_id"], proposal["move_id"], affected)
    seq["order"] = new_order
    write_json(SPINE_PATH, spine)
    # Soft_stages
    soft = load_json(SOFT_PATH)
    if change in soft.get("stages", {}):
        soft["stages"][change]["order"] = new_order
        write_json(SOFT_PATH, soft)

    return True, f"applied {change}.order {old_order} → {new_order}"


def apply_layer_move(proposal: dict, dry_run: bool) -> tuple[bool, str]:
    change = proposal["change"]
    new_layer_match = LAYER_RE.search(proposal["to_state"])
    if not new_layer_match:
        return False, "could not extract destination layer"
    new_layer = new_layer_match.group(1)

    seq_file = SEQUENCES_DIR / f"{change}.json"
    if not seq_file.exists():
        return False, f"sequence file {seq_file.name!r} not found"

    seq_data = load_json(seq_file)
    inner = seq_data.get("sequences", {}).get(change)
    if not inner:
        return False, f"sequence root {change!r} not found in file"
    old_layer = inner.get("layer")
    if old_layer == new_layer:
        return False, f"already at layer {new_layer!r} — no-op"

    if dry_run:
        return True, f"DRY-RUN: would set {change}.layer {old_layer!r} → {new_layer!r}"

    backup_files(proposal["pass_id"], proposal["move_id"], [seq_file])
    inner["layer"] = new_layer
    write_json(seq_file, seq_data)
    return True, f"applied {change}.layer {old_layer} → {new_layer}"


def apply_unlock_move(proposal: dict, dry_run: bool) -> tuple[bool, str]:
    change = proposal["change"]   # e.g., "qfeplaboratory.unlocks"
    if "." not in change:
        return False, f"expected <sequence>.unlocks form, got {change!r}"
    seq_name = change.split(".")[0]
    seq_file = SEQUENCES_DIR / f"{seq_name}.json"
    if not seq_file.exists():
        return False, f"sequence file {seq_file.name!r} not found"

    seq_data = load_json(seq_file)
    inner = seq_data.get("sequences", {}).get(seq_name)
    if not inner:
        return False, f"sequence root {seq_name!r} not found"
    old_unlocks = list(inner.get("unlocks", []))

    # Parse to_state for the new list. Accept formats like:
    #   "[]"
    #   "[\"foo\", \"bar\"]"
    #   "add postfoundationscrisis" (additive)
    ts = proposal["to_state"].strip("`")
    new_unlocks: Optional[list[str]] = None
    if ts.strip() in ("[]", "(terminal in thesis arc)") or "terminal" in ts.lower():
        new_unlocks = []
    elif ts.startswith("[") and ts.endswith("]"):
        try:
            new_unlocks = json.loads(ts.replace("'", '"'))
        except Exception:
            return False, f"could not parse unlock list {ts!r}"
    elif "add " in proposal["from_state"].lower() or "add " in ts.lower():
        # Additive form. Look for the token in the proposal's `to_state` or `from_state`.
        added_match = re.search(r"add\s+(\w+)", proposal["from_state"] + " " + ts, re.IGNORECASE)
        if added_match:
            token = added_match.group(1)
            new_unlocks = list(old_unlocks)
            if token not in new_unlocks:
                new_unlocks.append(token)
        else:
            return False, "could not parse additive unlock"

    if new_unlocks is None:
        return False, f"unrecognised unlock-edit form: from={proposal['from_state']!r} to={ts!r}"

    if new_unlocks == old_unlocks:
        return False, f"unlocks already {new_unlocks!r} — no-op"

    if dry_run:
        return True, f"DRY-RUN: would set {seq_name}.unlocks {old_unlocks} → {new_unlocks}"

    backup_files(proposal["pass_id"], proposal["move_id"], [seq_file])
    inner["unlocks"] = new_unlocks
    write_json(seq_file, seq_data)
    return True, f"applied {seq_name}.unlocks {old_unlocks} → {new_unlocks}"


# -- Dispatch ----------------------------------------------------------------

def apply_move(proposal: dict, dry_run: bool) -> tuple[bool, str]:
    mt = detect_move_type(proposal)
    if mt == "phase":
        return apply_phase_move(proposal, dry_run)
    if mt == "order":
        return apply_order_move(proposal, dry_run)
    if mt == "layer":
        return apply_layer_move(proposal, dry_run)
    if mt == "unlock":
        return apply_unlock_move(proposal, dry_run)
    if mt == "multi":
        return False, "MANUAL: combined order+phase move — apply phase first, then order"
    return False, f"MANUAL: move type {mt!r} not auto-supported. Apply by hand and mark status=applied."


# -- CLI ---------------------------------------------------------------------

def find_proposal(pass_id_part: str, move_id: str) -> Optional[tuple[Path, dict]]:
    if not PROPOSALS_DIR.exists():
        return None
    for jf in sorted(PROPOSALS_DIR.glob("*_proposals.json")):
        if pass_id_part not in jf.stem:
            continue
        data = json.loads(jf.read_text(encoding="utf-8"))
        for p in data.get("proposals", []):
            if p.get("move_id") == move_id:
                return jf, p
    return None


def update_proposal_status(jf: Path, move_id: str, new_status: str, note: str = "") -> None:
    data = json.loads(jf.read_text(encoding="utf-8"))
    for p in data.get("proposals", []):
        if p.get("move_id") == move_id:
            p["status"] = new_status
            p["applied_at"] = dt.datetime.now().isoformat(timespec="seconds")
            p["applied_by"] = "apply_sieve_move.py"
            if note:
                p["notes"] = (p.get("notes", "") + " | " + note).strip(" |")
            break
    jf.write_text(json.dumps(data, indent="\t", ensure_ascii=False) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--pass", dest="pass_id", required=True, help="Substring of the pass id to find.")
    parser.add_argument("--move", dest="move_id", required=True, help="The move_id to apply or rollback.")
    parser.add_argument("--dry-run", action="store_true", help="Print what would happen, don't write.")
    parser.add_argument("--rollback", action="store_true", help="Restore from backup, mark status pending.")
    args = parser.parse_args()

    found = find_proposal(args.pass_id, args.move_id)
    if not found:
        print(f"No proposal {args.move_id!r} in any pass matching {args.pass_id!r}", file=sys.stderr)
        return 1
    jf, proposal = found

    if args.rollback:
        ok = restore_backup(proposal["pass_id"], proposal["move_id"])
        if not ok:
            print(f"No backup found for {proposal['pass_id']}/{proposal['move_id']}", file=sys.stderr)
            return 1
        update_proposal_status(jf, proposal["move_id"], "pending", note="rolled back")
        print(f"rolled back {proposal['change']} ({proposal['move_id']})")
        return 0

    ok, msg = apply_move(proposal, args.dry_run)
    print(msg)
    if ok and not args.dry_run:
        update_proposal_status(jf, proposal["move_id"], "applied", note=msg)
    return 0 if ok else 2


if __name__ == "__main__":
    sys.exit(main())
