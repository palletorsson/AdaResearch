"""Editable editorial connections over the live museum; never changes the spine."""
from __future__ import annotations

from copy import deepcopy
import hashlib
import json
import os
from pathlib import Path
import re
import tempfile
import uuid

import project_memory as store

STATE = "doc/book/memory/museum/connections.json"
RELATIONS = {
    "reuses": "Target reuses a construction or record from source",
    "depends-on": "Target needs a capability introduced at source",
    "revisits": "Target returns to a question under different conditions",
    "resembles": "An association; no shared implementation is implied",
    "complicates": "Target puts an earlier understanding under pressure",
}
STATUSES = {"documented", "interpretation", "proposed"}


def route(root: Path) -> list[dict]:
    spine = json.loads((root / store.SPINE).read_text(encoding="utf-8"))
    result = []
    for item in sorted(spine["spine"]["sequences"], key=lambda s: s["order"]):
        name = item["name"]
        source = f"commons/maps/sequences/{name}.json"
        seq = json.loads((root / source).read_text(encoding="utf-8"))["sequences"][name]
        result.append({"id": "sequence:" + name, "order": item["order"], "source": source,
                       "halls": ["map:" + m for m in seq["maps"]]})
    return result


def addresses(root: Path) -> set[str]:
    return {sid for seq in route(root) for sid in [seq["id"], *seq["halls"]]}


def read(root: Path) -> dict:
    path = store._storage_path(root, STATE)
    if not path.exists():
        return {"schema": "museum-connections/1", "revision": 0, "summaries": {}, "threads": {}, "connections": {}, "journal": []}
    data = json.loads(path.read_text(encoding="utf-8"))
    if type(data.get("revision")) is not int or any(not isinstance(data.get(k), dict) for k in ("summaries", "threads", "connections")):
        raise store.MemoryError("Invalid museum connection store")
    return data


def enrich(root: Path, data: dict, known: set[str]) -> dict:
    result = deepcopy(data)
    for group in ("summaries", "connections"):
        for identifier, record in result[group].items():
            record["id"] = identifier
            evidence = []
            for path, recorded in record.get("sources", {}).items():
                _, target = store._resolve_source(root, path)
                current = hashlib.sha256(target.read_bytes()).hexdigest() if target.is_file() else None
                evidence.append({"path": path, "sha256": recorded, "current_sha256": current,
                                 "status": "missing" if current is None else "unchanged" if current == recorded else "changed"})
            record["evidence"] = evidence
            record["freshness"] = "recheck" if any(e["status"] != "unchanged" for e in evidence) else "unchanged" if evidence else "unlinked"
            addresses = [identifier] if group == "summaries" else [record["from"], record["to"]]
            record["unavailable"] = [sid for sid in addresses if sid not in known]
    result["relations"] = RELATIONS
    return result


def _text(value, name: str, required=False, limit=1800) -> str:
    text = store._input_text(value, name, required).strip()
    if len(text) > limit:
        raise store.MemoryError(f"{name} is too long (maximum {limit} characters)")
    return text


def _receipts(root: Path, raw, previous: dict) -> dict:
    paths = store._links(raw, "source_paths")
    canonical = [store._resolve_source(root, p)[0] for p in paths]
    if len(set(canonical)) != len(canonical):
        raise store.MemoryError("Duplicate source paths")
    # Editing prose never silently renews an old receipt.
    return {p: previous[p] if p in previous else store.source(root, p)["sha256"] for p in canonical}


def mutate(root: Path, request: dict) -> dict:
    request = store._object(request, "request")
    if len(json.dumps(request).encode("utf-8")) > store.MAX_INPUT:
        raise store.MemoryError("Update exceeds 128 KiB", 413)
    expected = request.get("expected_revision")
    if type(expected) is not int or expected < 0:
        raise store.MemoryError("A nonnegative expected_revision is required")
    action = request.get("action")
    if action not in {"summary", "thread", "connection", "delete_connection", "delete_thread"}:
        raise store.MemoryError("Unknown museum edit")
    with store._writer(root):
        data = read(root)
        if data["revision"] != expected:
            raise store.MemoryError("Museum memory changed in another window. Refresh, compare and save your draft again.", 409)
        known = addresses(root)
        identifier = request.get("id", "")
        group = "summaries" if action == "summary" else "threads" if action.endswith("thread") else "connections"
        if action == "summary":
            if identifier not in known or not identifier.startswith("sequence:"):
                raise store.MemoryError("Choose a current sequence")
        elif not identifier and action in {"thread", "connection"}:
            identifier = ("thread-" if action == "thread" else "link-") + uuid.uuid4().hex[:12]
        elif not isinstance(identifier, str) or not re.fullmatch(r"[a-zA-Z0-9_-]{1,80}", identifier):
            raise store.MemoryError("Invalid record identifier")
        before = deepcopy(data[group].get(identifier))
        now = store._now()
        if action.startswith("delete_"):
            if before is None:
                raise store.MemoryError("Record no longer exists", 404)
            if action == "delete_thread" and any(e["thread"] == identifier for e in data["connections"].values()):
                raise store.MemoryError("Remove or move this thread's connections first")
            del data[group][identifier]
            after = None
        else:
            raw = store._object(request.get("record"), "record")
            if action == "summary":
                after = {k: _text(raw.get(k, ""), k, k == "summary") for k in ("summary", "carry", "question")}
            elif action == "thread":
                after = {"title": _text(raw.get("title", ""), "title", True, 100),
                         "summary": _text(raw.get("summary", ""), "summary", True)}
            else:
                if raw.get("from") not in known or raw.get("to") not in known:
                    raise store.MemoryError("Both ends must be current sequences or halls")
                if raw["from"] == raw["to"]:
                    raise store.MemoryError("Choose two different addresses")
                if raw.get("thread") not in data["threads"]:
                    raise store.MemoryError("Choose an existing thread")
                if raw.get("relation") not in RELATIONS or raw.get("status") not in STATUSES:
                    raise store.MemoryError("Choose a named relationship and status")
                after = {k: raw[k] for k in ("from", "to", "thread", "relation", "status")}
                after["reason"] = _text(raw.get("reason", ""), "reason", True)
                for other_id, other in data[group].items():
                    if other_id != identifier and all(other[k] == after[k] for k in ("from", "to", "thread", "relation")):
                        raise store.MemoryError("That connection already exists; edit it instead")
            if action != "thread":
                after["sources"] = _receipts(root, raw.get("source_paths", []), (before or {}).get("sources", {}))
                if action == "connection" and after["status"] == "documented" and not after["sources"]:
                    raise store.MemoryError("A documented connection needs a source; otherwise choose interpretation or proposed")
            after["updated_at"] = now
            after["edited_by"] = "user"
            data[group][identifier] = after
        data["revision"] += 1
        data["updated_at"] = now
        change = {"revision": data["revision"], "at": now, "action": action, "id": identifier, "before": before, "after": after}
        data["journal"] = (data.get("journal", []) + [change])[-40:]
        _save(root, data)
        return {"revision": data["revision"], "id": identifier, "saved": True}


def _save(root: Path, data: dict) -> None:
    target = store._storage_path(root, STATE)
    history = store._storage_path(root, store.MEMORY + "/history")
    history.mkdir(exist_ok=True)
    if target.exists():
        snapshot = history / f"museum-{data['revision']-1:08d}-{uuid.uuid4().hex}.json"
        with snapshot.open("xb") as handle:
            handle.write(target.read_bytes())
            handle.flush()
            os.fsync(handle.fileno())
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=target.parent, prefix=".connections-", suffix=".tmp", delete=False) as handle:
            temporary = handle.name
            json.dump(data, handle, indent=2, ensure_ascii=False, allow_nan=False)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, target)
        temporary = None
    finally:
        if temporary:
            Path(temporary).unlink(missing_ok=True)


def existing_structures(root: Path) -> list[dict]:
    """References, not a second copy of their plans or placement edges."""
    specs = [
        ("Live route", "commons/maps/curriculum_spine.json", "/spine-graph", "Owns sequence order; per-sequence maps own hall membership. Older descriptive notes can lag behind the museum."),
        ("Tutorial execution plan", "doc/book/course/execution-plan/plan.json", "/tutorial-plan?view=sequences", "Editable lesson summaries, prerequisites, reusable objects and topic returns. Plans remain plans until checked."),
        ("Working memory", "doc/book/memory/state.json", "/project-memory", "Author brief, notes, review findings and revision history. Museum packets keep these alongside the new summaries."),
        ("Authored red thread", "commons/data/red_thread_rulings.json", "/red-thread", "Short authored room arguments. A room's argument is distinct from its programming lesson."),
        ("Artifact relationship graph", "commons/data/museum_relational_graph.json", "/graphify", "Named, co-placed and other artifact relations guide space. Co-placement alone does not establish a teaching dependency."),
        ("Teaching focus lineage", "doc/book/course/hall-cards/lineage-opening.json", "/tutorial-cards/overview", "Learning labels and carries across opening, middle and later registers. These retain their own editorial status."),
    ]
    return [{"title": title, "path": path, "href": href, "role": role, "exists": (root / path).is_file()} for title, path, href, role in specs]
