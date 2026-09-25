"""Turn a spine reading into task goal files the encyclopedia can manage.

Input:  doc/book/readings/spine_reading_<date>.json — a list of sequence entries, each
        {"sequence", "read_at", "source", "reading": {...}, "tasks": [...]} as the readers
        return them (see doc/book/readings/README.md).
Output: doc/tasks/book_<sequence>.json — one goal per sequence in the doc/tasks schema
        (doc/tasks/_schema.md), with a `book` block carrying the reading, and one task per
        proposed improvement. The page /book-tasks in the encyclopedia reads these files
        and PATCHes status and notes back into them.

Re-runnable: an existing goal file keeps every task's id, status, claimed_by, done_at
and notes. A task is matched by (hall, title); a task that is no longer in the reading is
kept and marked "stale": true rather than dropped, because Palle may have started it.

    python tools/book_tasks_ingest.py doc/book/readings/spine_reading_2026-09-24.json
    python tools/book_tasks_ingest.py <readings.json> --only=primitives,noise
"""
from __future__ import annotations

import json
import os
import re
import sys
from datetime import date

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TASKS_DIR = os.path.join(ROOT, "doc", "tasks")
SPINE = os.path.join(ROOT, "commons", "maps", "curriculum_spine.json")
SEQ_DIR = os.path.join(ROOT, "commons", "maps", "sequences")
MAPS_DIR = os.path.join(ROOT, "commons", "maps")

EFFORT = {"S": "10min", "M": "1h", "L": "half-day"}
SKILL = {
    "prose": "edit", "structure": "edit", "handover": "edit", "footnote": "edit", "vr": "edit",
    "figure": "design", "encounter": "build", "code-claim": "verify",
}


def spine_info() -> dict[str, dict]:
    sp = json.load(open(SPINE, encoding="utf-8"))
    out = {}
    for s in sp["spine"]["sequences"]:
        sid = s["name"]
        p = os.path.join(SEQ_DIR, sid + ".json")
        if not os.path.exists(p):
            continue
        d = json.load(open(p, encoding="utf-8"))
        node = d["sequences"].get(sid) or list(d["sequences"].values())[0]
        maps = [m if isinstance(m, str) else (m.get("map") or m.get("name") or m.get("id")) for m in node.get("maps", [])]
        words = 0
        for m in maps:
            f = os.path.join(MAPS_DIR, m, "final.md")
            if os.path.exists(f):
                words += len(open(f, encoding="utf-8", errors="ignore").read().split())
        out[sid] = {
            "sequence": sid, "order": s.get("order"), "phase": s.get("phase"),
            "title": node.get("name") or sid, "chapters": maps, "words": words,
        }
    return out


def norm(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", (s or "").lower()).strip()


def task_from(sid: str, t: dict, n: int, read_at: str, source: str) -> dict:
    hall = t.get("hall") or "sequence"
    kind = t.get("kind") or "prose"
    spec = (
        f"[{kind}] {hall}\n"
        + (f"Quote: “{t.get('quote')}”\n" if t.get("quote") else "")
        + f"Why: {t.get('why', '')}\n"
        + f"Do: {t.get('proposal', '')}\n"
        + (f"Evidence: {t.get('evidence')}\n" if t.get("evidence") else "")
        + f"File: commons/maps/{hall}/final.md" if hall != "sequence" else f"[{kind}] whole sequence\nWhy: {t.get('why', '')}\nDo: {t.get('proposal', '')}"
    )
    return {
        "id": f"book_{sid}.{n:03d}",
        "title": t.get("title", "").strip(),
        "spec": spec,
        "effort": EFFORT.get(t.get("effort", "S"), t.get("effort", "10min")),
        "skill": SKILL.get(kind, "edit"),
        "depends_on": [],
        "status": "open",
        "claimed_by": None,
        "done_at": None,
        "map_refs": [] if hall == "sequence" else [hall],
        "sequence_refs": [sid],
        "verification": ("re-read the sentence in the headset, or against the code the evidence names" if kind in ("code-claim", "encounter") else "re-read the chapter after the change"),
        "kind": kind,
        "hall": hall,
        "quote": t.get("quote", ""),
        "why": t.get("why", ""),
        "proposal": t.get("proposal", ""),
        "evidence": t.get("evidence", ""),
        # the skeptic's verdict travels in the reader output's `verification` field ("kept: ...")
        "review": t.get("review") or (t.get("verification", "") if str(t.get("verification", "")).split(":")[0] in ("kept", "amended", "unreviewed") else ""),
        "notes": "",
        "source": t.get("source") or source,
        "created_at": read_at,
    }


def ingest(readings_path: str, only: set[str] | None = None) -> None:
    entries = json.load(open(readings_path, encoding="utf-8"))
    info = spine_info()
    os.makedirs(TASKS_DIR, exist_ok=True)
    for e in entries:
        sid = e["sequence"]
        if only and sid not in only:
            continue
        if sid not in info:
            print("skip (not on the spine):", sid)
            continue
        meta = info[sid]
        path = os.path.join(TASKS_DIR, f"book_{sid}.json")
        existing = json.load(open(path, encoding="utf-8")) if os.path.exists(path) else None
        old_tasks = (existing or {}).get("tasks", [])
        by_key = {(norm(t.get("hall", "")), norm(t.get("title", ""))): t for t in old_tasks}
        used_ids = {t["id"] for t in old_tasks}
        tasks: list[dict] = []
        seen: set[tuple[str, str]] = set()
        n = 0
        read_at = e.get("read_at") or date.today().isoformat()
        source = e.get("source") or "reading"
        for t in e.get("tasks", []):
            key = (norm(t.get("hall", "")), norm(t.get("title", "")))
            if key in seen:
                continue
            seen.add(key)
            old = by_key.get(key)
            if old:
                merged = task_from(sid, t, 0, read_at, source)
                # Palle's state survives a re-run; the reading's own fields are refreshed
                for k in ("id", "status", "claimed_by", "done_at", "notes", "created_at", "triage", "triaged_at", "updated_at"):
                    if k in old:
                        merged[k] = old[k]
                if old.get("source") == "palle":
                    merged["source"] = "palle"
                merged.pop("stale", None)
                tasks.append(merged)
            else:
                while True:
                    n += 1
                    cand = f"book_{sid}.{n:03d}"
                    if cand not in used_ids:
                        break
                used_ids.add(cand)
                tasks.append(task_from(sid, t, n, read_at, source))
        # keep tasks Palle added or that fell out of a re-run
        for old in old_tasks:
            key = (norm(old.get("hall", "")), norm(old.get("title", "")))
            if key not in seen:
                kept = dict(old)
                if kept.get("source") != "palle":
                    kept["stale"] = True
                tasks.append(kept)
        reading = e.get("reading") or {}
        goal = {
            "goal_id": f"book_{sid}",
            "goal_title": f"Book: {meta['title']} — improvements from the spine reading",
            "why": f"The whole spine was read as a book on {read_at}, one sequence at a time, and every stumble, false claim or broken handover in {sid} became a task Palle can pick up one at a time. Reader: the VR visitor.",
            "success_criteria": [
                "every open task here is done or skipped with a note",
                "the chapters read through without a stumble in the headset",
                "every code excerpt and number in the chapters matches the source",
            ],
            "prerequisites": [],
            "book": {
                "sequence": sid, "order": meta["order"], "phase": meta["phase"], "title": meta["title"],
                "chapters": meta["chapters"], "words": meta["words"], "read_at": read_at, "source": source,
                "chapters_read": e.get("chapters_read", meta["chapters"]),
                "reading": reading,
                "dropped": e.get("dropped", []),
            },
            "tasks": tasks,
        }
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            json.dump(goal, f, indent=2, ensure_ascii=False)
            f.write("\n")
        print(f"{sid:24} {len(tasks):3d} tasks -> {os.path.relpath(path, ROOT)}")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = set(a.split("=", 1)[1].split(","))
    if not args:
        print(__doc__)
        sys.exit(2)
    ingest(args[0], only)
