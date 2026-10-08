"""Revisioned working memory for Ada, with live, read-only teaching context.

The CLI accepts a JSON object on stdin and an explicit --root. No imports from
the game or route builders are needed (some builders write on import).
"""
from __future__ import annotations

import argparse
from contextlib import contextmanager
from copy import deepcopy
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path, PurePosixPath, PureWindowsPath
import re
import sys
import tempfile
from typing import Any, Iterator
import uuid


MEMORY = "doc/book/memory"
STATE = MEMORY + "/state.json"
STORYBOARDS = "doc/book/course/storyboards"
ROUTE = "doc/book/iterations/2026-10-04-museum-tutorial-storyboards/route.json"
SPINE = "commons/maps/curriculum_spine.json"
MAX_INPUT = 128 * 1024
MAX_SOURCE = 512 * 1024
MAX_TEXT = 12000
MAX_LINKS = 20
KINDS = {"source", "decision", "proposal", "question"}
STATUSES = {"proposed", "accepted", "dismissed"}
SOURCE_EXTENSIONS = {".md", ".json", ".gd", ".gdshader", ".tscn", ".txt"}


class MemoryError(ValueError):
    """An expected, safe-to-display request or storage error."""

    def __init__(self, message: str, code: int = 400):
        super().__init__(message)
        self.code = code


def _root(root: str | Path) -> Path:
    path = Path(root).resolve()
    if not path.is_dir():
        raise MemoryError("Repository root does not exist", 404)
    return path


def _allowed_path(path: str) -> str:
    if not isinstance(path, str) or not path or len(path) > 1024:
        raise MemoryError("A repository-relative source path is required")
    value = path.replace("\\", "/")
    parts = value.split("/")
    if (PureWindowsPath(value).drive or PurePosixPath(value).is_absolute()
            or any(p in {"", ".", ".."} for p in parts)
            or any(":" in p or "\x00" in p for p in parts)
            or any(p.startswith(".") or p.lower() in {"private", "secrets", "system"}
                   or PureWindowsPath(p).is_reserved()
                   or p.endswith((".", " ")) for p in parts)):
        raise MemoryError("Source path must be safe and repository-relative")
    lowered = value.lower()
    if lowered.startswith(MEMORY + "/history/") or lowered == MEMORY + "/history":
        raise MemoryError("Memory history is not a source")
    if value != "project.godot":
        if not value.startswith(("commons/", "algorithms/", "doc/book/")):
            raise MemoryError("Source must be under commons, algorithms, or doc/book")
        if PurePosixPath(value).suffix.lower() not in SOURCE_EXTENSIONS:
            raise MemoryError("Source must be an allowed text file")
    return value


def _resolve_source(root: Path, path: str) -> tuple[str, Path]:
    value = _allowed_path(path)
    candidate = root / value
    try:
        resolved = candidate.resolve()
        canonical = resolved.relative_to(root).as_posix()
    except (OSError, RuntimeError, ValueError):
        raise MemoryError("Source symlink escapes the repository") from None
    _allowed_path(canonical)
    return value, resolved


def _source(root: Path, path: str) -> dict[str, Any]:
    value, resolved = _resolve_source(root, path)
    try:
        with resolved.open("rb") as handle:
            data = handle.read(MAX_SOURCE + 1)
    except FileNotFoundError:
        raise MemoryError(f"Source not found: {value}", 404) from None
    except OSError:
        raise MemoryError(f"Cannot read source: {value}") from None
    if len(data) > MAX_SOURCE:
        raise MemoryError("Source exceeds the 512 KiB response limit")
    try:
        text = data.decode("utf-8-sig")
    except UnicodeDecodeError:
        raise MemoryError("Source must be UTF-8 text") from None
    if "\x00" in text:
        raise MemoryError("Source must be text, not a binary file")
    return {"path": value, "text": text, "sha256": hashlib.sha256(data).hexdigest()}


def source(root: str | Path, path: str) -> dict[str, Any]:
    """Return bounded UTF-8 source text and a hash of its exact bytes."""
    return _source(_root(root), path)


def _read_json(root: Path, path: str, default: Any) -> Any:
    _, resolved = _resolve_source(root, path)
    if not resolved.exists():
        return deepcopy(default)
    try:
        return json.loads(resolved.read_text(encoding="utf-8-sig"))
    except (OSError, ValueError):
        raise MemoryError(f"Cannot read valid JSON: {path}") from None


def _storage_path(root: Path, relative: str) -> Path:
    """Reject redirected storage, including junctions into another repo folder."""
    path = root / relative
    current = root
    for part in PurePosixPath(relative).parts:
        current = current / part
        if current.is_symlink() or (hasattr(current, "is_junction") and current.is_junction()):
            raise MemoryError("Memory storage cannot contain symlinks or junctions")
    if path.resolve() != path:
        raise MemoryError("Memory storage must stay in doc/book/memory")
    return path


def _state(root: Path) -> dict[str, Any]:
    path = _storage_path(root, STATE)
    if not path.is_file():
        raise MemoryError("Memory state has not been initialized", 404)
    try:
        state = json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, ValueError):
        raise MemoryError("Memory state is not valid JSON") from None
    if not isinstance(state, dict) or type(state.get("revision")) is not int or state["revision"] < 0:
        raise MemoryError("Memory state requires a nonnegative integer revision")
    for name, expected in (("core", dict), ("notes", dict), ("findings", list), ("journal", list)):
        if name in state and not isinstance(state[name], expected):
            raise MemoryError(f"Memory state {name} has an invalid type")
    return state


def _strings(value: Any) -> list[str]:
    if isinstance(value, str):
        return [value] if value else []
    return [v for v in value if isinstance(v, str)] if isinstance(value, list) else []


def _text(value: Any) -> str:
    return value if isinstance(value, str) else ""


def _scope(identifier: str, level: str, title: str, parent: str | None,
           order: int, authored: dict[str, Any], path: str) -> dict[str, Any]:
    return {
        "id": identifier, "level": level, "title": title, "parent": parent,
        "order": order, "summary": _text(authored.get("storyboard_short", authored.get("arc", ""))),
        "full": _text(authored.get("storyboard", authored.get("arc", ""))),
        "source": path, "children": [], "brings": _strings(authored.get("brings")),
        "learns": _strings(authored.get("learns")), "supplied": _strings(authored.get("supplied")),
        "carries": _strings(authored.get("carries")), "artifact_refs": _strings(authored.get("artifact_refs")),
        "documents": [], "image": None, "review_note": _text(authored.get("review_note")),
    }


def _signal(scope: str, kind: str, text: str, related: list[str] | None = None) -> dict[str, Any]:
    key = hashlib.sha256(f"{scope}|{kind}|{text}".encode()).hexdigest()[:16]
    return {"id": "signal-" + key, "scope": scope, "kind": kind, "text": text,
            "related_scopes": related or []}


def _identifier(value: Any) -> str:
    if not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9_-]+", value):
        raise MemoryError("Invalid identifier in storyboard or route metadata")
    return value


def _route_link(root: Path, value: Any, image: bool = False) -> str | None:
    if not isinstance(value, str) or not value:
        return None
    try:
        candidate = (root / ROUTE).parent / value
        relative = candidate.resolve().relative_to(root).as_posix()
        if image:
            if not relative.startswith("doc/book/iterations/"):
                return None
            if candidate.suffix.lower() not in {".png", ".webp", ".jpg", ".jpeg", ".gif"}:
                return None
        else:
            _resolve_source(root, relative)
        return relative if candidate.is_file() else None
    except (ValueError, OSError, RuntimeError):
        return None


def _registry(root: Path) -> dict[str, dict[str, Any]]:
    registry: dict[str, dict[str, Any]] = {}
    folder = root / "commons/artifacts/registry"
    for path in sorted(folder.glob("*.json")):
        raw = _read_json(root, path.relative_to(root).as_posix(), {})
        entries = raw.get("artifacts", {}) if isinstance(raw, dict) else {}
        if not isinstance(entries, dict):
            continue
        for key, entry in entries.items():
            if isinstance(entry, dict):
                record = dict(entry, registry=path.relative_to(root).as_posix())
                registry[key] = record
                registry[_text(entry.get("lookup_name")) or key] = record
    return registry


def _catalog(root: Path) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    route = _read_json(root, ROUTE, {})
    authored: dict[str, dict[str, Any]] = {}
    hall_authored: dict[str, tuple[dict[str, Any], str]] = {}
    for part in ("opening", "early", "growth", "later"):
        path = f"{STORYBOARDS}/{part}.json"
        raw = _read_json(root, path, [])
        if not isinstance(raw, list):
            raise MemoryError(f"Storyboard must be a list: {path}")
        for sequence in raw:
            sid = _identifier(sequence.get("sequence"))
            if sid in authored:
                raise MemoryError(f"Duplicate authored sequence: {sid}")
            authored[sid] = dict(sequence, source=path)
            for hall in sequence.get("halls", []):
                mid = _identifier(hall.get("id"))
                if mid in hall_authored:
                    raise MemoryError(f"Duplicate authored hall: {mid}")
                hall_authored[mid] = (hall, path)

    route_sequences = route.get("sequences", [])
    sequence_metadata = {s["id"]: s for s in route_sequences}
    hall_metadata = {h["id"]: h for h in route.get("halls", [])}
    spine = _read_json(root, SPINE, {})
    spine_sequences = spine.get("spine", {}).get("sequences", [])
    live_sequences = []
    for item in sorted(spine_sequences, key=lambda s: s.get("order", 0)):
        sid = _identifier(item["name"])
        data = _read_json(root, f"commons/maps/sequences/{sid}.json", {})
        sequence = data.get("sequences", {}).get(sid, {})
        live_sequences.append({"id": sid, "label": sequence.get("name", sid),
                               "maps": sequence.get("maps", [])})
    # In isolated fixtures or an incomplete checkout, authored order is still
    # usable. Exported paragraphs are never substituted for missing live prose.
    ordered = live_sequences or [
        {"id": sid, "label": sequence_metadata.get(sid, {}).get("label", sid),
         "maps": [h["id"] for h in seq.get("halls", [])]}
        for sid, seq in authored.items()
    ]
    if not ordered:
        ordered = route_sequences
    present = {s["id"] for s in ordered}
    ordered = list(ordered) + [
        {"id": sid, "label": sid, "maps": [h["id"] for h in seq.get("halls", [])]}
        for sid, seq in authored.items() if sid not in present
    ]
    signals = []
    live_halls = {mid for seq in live_sequences for mid in seq.get("maps", [])}
    if live_sequences and authored:
        live_order = [(s["id"], s.get("maps", [])) for s in live_sequences]
        authored_order = [(sid, [h["id"] for h in entry.get("halls", [])]) for sid, entry in authored.items()]
        if live_order != authored_order:
            signals.append(_signal("project", "storyboard_spine_disagreement",
                "Authored storyboard grouping differs from the current spine. Current hall ownership follows the spine; live authored text remains attached to its hall."))
    if live_sequences and route_sequences:
        current = [(s["id"], s.get("maps", [])) for s in live_sequences]
        snapshot = [(s["id"], s.get("maps", [])) for s in route_sequences]
        if current != snapshot:
            signals.append(_signal("project", "route_spine_disagreement",
                "Generated route order differs from the current curriculum spine. Images are earlier museum captures; review the route snapshot."))

    brief_path = f"{STORYBOARDS}/BRIEF.md"
    try:
        brief = _source(root, brief_path)["text"]
    except MemoryError as error:
        if error.code != 404:
            raise
        brief = ""
    project = _scope("project", "project", "AdaResearch", None, 0,
                     {"storyboard": brief, "storyboard_short": "Working memory for the proposed teaching route through Ada's existing museum. Follow a sequence or hall to compare live storyboards, supplied support, open choices and source evidence."}, brief_path)
    scopes = [project]
    prep_path = f"{STORYBOARDS}/preparation.json"
    prep = _read_json(root, prep_path, {})
    if prep:
        scopes.append(_scope("preparation:day-zero", "preparation", prep.get("title", "Day Zero"),
                             "project", 0, prep, prep_path))
        project["children"].append("preparation:day-zero")
    registry = _registry(root)
    seen_halls: set[str] = set()
    for index, sequence in enumerate(ordered, 1):
        sid = _identifier(sequence["id"])
        sequence_id = "sequence:" + sid
        seq_authored = authored.get(sid, {})
        seq_source = seq_authored.get("source", f"commons/maps/sequences/{sid}.json")
        seq = _scope(sequence_id, "sequence", sequence.get("label", sid), "project",
                     index, seq_authored, seq_source)
        seq["documents"].append({"label": "Sequence source", "path": seq_source})
        scopes.append(seq)
        project["children"].append(sequence_id)
        mids = list(sequence.get("maps", []))
        if live_sequences and sid not in {s["id"] for s in live_sequences}:
            mids = [mid for mid in mids if mid not in live_halls]
        mids += [h["id"] for h in seq_authored.get("halls", [])
                 if h["id"] not in mids and h["id"] not in live_halls]
        for mid in mids:
            mid = _identifier(mid)
            if mid in seen_halls:
                raise MemoryError(f"Hall appears in more than one sequence: {mid}")
            seen_halls.add(mid)
            data, path = hall_authored.get(mid, ({}, f"commons/maps/{mid}/map_data.json"))
            scope_id = "map:" + mid
            hall = _scope(scope_id, "map", data.get("title", mid), sequence_id,
                          len(seen_halls), data, path)
            seq["children"].append(scope_id)
            hall["documents"].append({"label": "Storyboard source", "path": path})
            for label in ("map_data", "tutorial", "final", "intent", "critical", "technical", "artifacts"):
                doc_path = f"commons/maps/{mid}/{label}." + ("json" if label == "map_data" else "md")
                _, resolved = _resolve_source(root, doc_path)
                if resolved.is_file():
                    hall["documents"].append({"label": label.replace("_", " "), "path": doc_path})
            metadata = hall_metadata.get(mid, {})
            for label, href in metadata.get("docs", {}).items():
                doc_path = _route_link(root, href)
                if doc_path and doc_path not in {d["path"] for d in hall["documents"]}:
                    hall["documents"].append({"label": label, "path": doc_path})
            if data.get("storyboard_notes"):
                note_path, resolved = _resolve_source(root, data["storyboard_notes"])
                if resolved.is_file():
                    hall["documents"].append({"label": "Storyboard notes", "path": note_path})
            for picture in metadata.get("images", []):
                image_path = _route_link(root, picture.get("src"), image=True)
                if image_path:
                    hall["image"] = {"path": image_path, "label": "Earlier museum capture: " + picture.get("label", mid),
                                     "date": picture.get("date", route.get("date", ""))}
                    break
            if not data:
                signals.append(_signal(scope_id, "missing_storyboard", "No live authored storyboard for this hall."))
            for reference in hall["artifact_refs"]:
                entry = registry.get(reference)
                if entry is None:
                    signals.append(_signal(scope_id, "missing_artifact", f"Selected artifact is absent from the current registry: {reference}"))
                    continue
                scene = _text(entry.get("scene"))
                if scene.startswith("res://"):
                    scene_path = scene[6:]
                    try:
                        _, resolved = _resolve_source(root, scene_path)
                        exists = resolved.is_file()
                    except MemoryError:
                        exists = False
                    if not exists:
                        signals.append(_signal(scope_id, "missing_artifact", f"Selected artifact scene is missing or outside allowed sources: {reference}"))
            scopes.append(hall)
    for scope in scopes:
        if scope["review_note"]:
            signals.append(_signal(scope["id"], "open_review", scope["review_note"]))
    return scopes, signals


def _fresh_finding(root: Path, record: dict[str, Any], hashes: dict[str, str | None]) -> dict[str, Any]:
    result = {name: _text(record.get(name)) for name in (
        "id", "scope", "kind", "text", "reason", "sequence_effect", "project_effect",
        "status", "method", "created_by", "created_at", "review_note", "reviewed_at")}
    result["status"] = result["status"] or "proposed"
    result["related_scopes"] = _strings(record.get("related_scopes"))
    result["sources"] = []
    for evidence in record.get("sources", []):
        path = evidence["path"]
        if path not in hashes:
            try:
                hashes[path] = _source(root, path)["sha256"]
            except MemoryError as error:
                # An inaccessible or newly unsafe link is never fresh evidence.
                if error.code not in (400, 404):
                    raise
                hashes[path] = None
        current = hashes[path]
        observed = evidence.get("sha256")
        status = "missing" if current is None else "changed" if observed and observed != current else "current"
        result["sources"].append({"path": path, "sha256": observed,
                                  "current_sha256": current, "status": status})
    statuses = {item["status"] for item in result["sources"]}
    result["freshness"] = (
        "missing" if "missing" in statuses else "changed" if "changed" in statuses
        else "current" if any(s["sha256"] for s in result["sources"]) else "unlinked"
    )
    return result


def _model(root: Path, state: dict[str, Any]) -> dict[str, Any]:
    scopes, signals = _catalog(root)
    hashes: dict[str, str | None] = {}
    findings = [_fresh_finding(root, record, hashes) for record in state.get("findings", [])]
    notes = {scope: dict(note, **{key: _text(note.get(key)) for key in ("summary", "reason", "open_question", "updated_at")})
             for scope, note in state.get("notes", {}).items()}
    for finding in findings:
        if finding["freshness"] in {"changed", "missing"} and finding["status"] != "dismissed":
            signals.append(_signal(finding["scope"], "source_" + finding["freshness"],
                f"Finding {finding['id']} has {finding['freshness']} source evidence: {finding['text'][:160]}", finding["related_scopes"]))
    for sid, note in notes.items():
        if note["open_question"]:
            signals.append(_signal(sid, "open_question", note["open_question"]))
    core = {key: _text(state.get("core", {}).get(key)) for key in ("text", "reason", "open_question")}
    if core["open_question"]:
        signals.append(_signal("project", "open_question", core["open_question"]))
    journal = [{key: _text(entry.get(key)) for key in ("at", "action", "scope", "summary")}
               for entry in state.get("journal", [])[-40:]]
    return {
        "revision": state["revision"], "updated_at": _text(state.get("updated_at")),
        "core": core, "scopes": scopes, "notes": notes, "findings": findings,
        "signals": signals, "history": journal,
        "stats": {"sequences": sum(s["level"] == "sequence" for s in scopes),
                  "maps": sum(s["level"] == "map" for s in scopes), "findings": len(findings),
                  "needs_recheck": sum(f["freshness"] in {"changed", "missing"} and f["status"] != "dismissed" for f in findings),
                  "open_questions": sum(s["kind"] == "open_question" for s in signals)
                      + sum(bool(re.search(r"\bOpen:", s["summary"], re.IGNORECASE)) for s in scopes)
                      + sum(f["kind"] == "question" and f["status"] != "dismissed" for f in findings)},
    }


def model(root: str | Path) -> dict[str, Any]:
    """Read memory and derive fresh context, without creating or changing files."""
    repo = _root(root)
    return _model(repo, _state(repo))


def _excerpt(text: str, words: int) -> str:
    pieces = text.split()
    return text if len(pieces) <= words else " ".join(pieces[:words]) + " … [excerpt; read linked source]"


def packet(root: str | Path, scope: str = "project") -> dict[str, Any]:
    """Build deterministic local/global handoffs; open choices are never clipped."""
    data = model(root)
    by_id = {s["id"]: s for s in data["scopes"]}
    if not isinstance(scope, str) or scope not in by_id:
        raise MemoryError("Unknown scope", 404)
    current = by_id[scope]
    ancestors = []
    parent = current["parent"]
    while parent:
        ancestors.insert(0, parent)
        parent = by_id[parent]["parent"]
    descendants: set[str] = set()
    pending = list(current["children"])
    while pending:
        child = pending.pop(0)
        descendants.add(child)
        pending.extend(by_id[child]["children"])
    selected = [scope]
    if current["level"] == "project":
        selected += current["children"]
    elif current["level"] == "sequence":
        selected += current["children"]
    elif current["level"] == "map":
        halls = [s["id"] for s in data["scopes"] if s["level"] == "map"]
        index = halls.index(scope)
        selected += halls[max(0, index - 1):index] + halls[index + 1:index + 2]
    relevant = set(selected) | set(ancestors) | descendants
    lines = [f"# Ada project memory — {current['title']}",
             f"Revision {data['revision']} · Scope {scope}",
             "CONTEXT ONLY: this packet is not implementation permission or proof. Authored teaching remains proposed. Supplied objects are support, not learned prerequisites. Editorial acceptance is separate from source freshness and technical verification. Museum images are earlier captures.",
             "", "## Working brief", data["core"]["text"], "Reason: " + data["core"]["reason"]]
    if data["core"]["open_question"]:
        lines.append("OPEN CHOICE: " + data["core"]["open_question"])
    for ancestor in ancestors:
        item = by_id[ancestor]
        if item["level"] == "project":
            continue
        lines += ["", f"## Ancestor arc — {item['title']}", item["summary"], "Source: " + item["source"]]
    for sid in dict.fromkeys(selected):
        item = by_id[sid]
        lines += ["", f"## {item['title']} ({sid})"]
        # Compact source summaries are already authored; do not truncate their
        # Open/Defer clauses by applying an arbitrary word slice to them.
        lines += [item["summary"], "Source: " + item["source"]]
        if sid == scope and item["level"] == "map":
            for label, key in (("Brings", "brings"), ("Learns", "learns"), ("Supplied", "supplied"), ("Carries", "carries")):
                lines.append(label + ": " + "; ".join(item[key]))
    for item in data["scopes"]:
        sid = item["id"]
        if sid not in relevant:
            continue
        note = data["notes"].get(sid)
        if note:
            lines += ["", f"Working note ({sid}): {note['summary']}", "Reason: " + note["reason"]]
            if note["open_question"]:
                lines.append("OPEN CHOICE: " + note["open_question"])
        if item["review_note"] and not (current["level"] == "project" and item["level"] == "map"):
            lines.append(f"OPEN REVIEW ({sid}): {item['review_note']} [Source: {item['source']}]")
    # At project scope, hall summaries are intentionally replaced by sequence
    # arcs; retain explicit Open clauses when no separate review note holds it.
    if current["level"] == "project":
        lines += ["", "## Hall review coverage",
                  "Detailed hall review notes are not expanded here. Counts and live source paths follow; use a sequence or hall packet to read every review note. Explicit authored Open choices are retained below, including choices in halls that also have review notes."]
        for item in data["scopes"]:
            if item["level"] == "sequence":
                count = sum(bool(by_id[sid]["review_note"]) for sid in item["children"])
                if count:
                    lines.append(f"{item['id']}: {count} hall review notes — {item['source']}")
        lines += ["", "## Explicit open choices"]
        for sid in sorted(descendants, key=lambda key: (by_id[key]["order"], key)):
            item = by_id[sid]
            if sid in selected:
                continue
            choices = re.findall(r"\bOpen:\s*[^\n]+", item["summary"], re.IGNORECASE)
            if choices:
                lines.append(f"{sid} — {' '.join(choices)}")
    for finding in data["findings"]:
        if finding["status"] == "dismissed":
            continue
        if finding["scope"] not in relevant and not relevant.intersection(finding["related_scopes"]):
            continue
        lines += ["", f"Finding {finding['id']} · {finding['kind']} · {finding['status']} · evidence {finding['freshness']}",
                  finding["text"], "Reason: " + finding["reason"],
                  "Method: " + (finding["method"] or "unspecified") + "; by " + (finding["created_by"] or "unspecified"),
                  "Sequence effect: " + finding["sequence_effect"], "Project effect: " + finding["project_effect"]]
        for evidence in finding["sources"]:
            lines.append(f"Evidence: {evidence['path']} [{evidence['status']}; observed {evidence['sha256'] or 'uninspected'}; current {evidence['current_sha256'] or 'missing'}]")
        if finding["review_note"]:
            lines.append("Review: " + finding["review_note"])
    lines += ["", "Return to sequence/project: explain what this changes in the containing arc and shared brief. Record a proposed finding with source paths; keep unresolved choices explicit."]
    text = "\n".join(lines).strip() + "\n"
    count = len(text.split())
    # No arbitrary total cap can preserve an unbounded number of pending
    # questions. Make exceptional growth explicit rather than silently dropping
    # evidence or choices; ordinary packets select only local summaries/arcs.
    if count > 10000:
        text += "\nPacket exceeds 10,000 words because all relevant notes, findings and unresolved choices were retained. Select a sequence or hall for a smaller handoff.\n"
        count = len(text.split())
    return {"text": text, "word_count": count}


def _input_text(value: Any, name: str, required: bool = False) -> str:
    if not isinstance(value, str) or len(value) > MAX_TEXT:
        raise MemoryError(f"{name} must be text of at most {MAX_TEXT} characters")
    if required and not value.strip():
        raise MemoryError(f"{name} is required")
    return value


def _object(value: Any, name: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise MemoryError(f"{name} must be an object")
    return value


def _links(value: Any, name: str) -> list[str]:
    if not isinstance(value, list) or len(value) > MAX_LINKS:
        raise MemoryError(f"{name} must be an array of at most {MAX_LINKS} items")
    for item in value:
        _input_text(item, name, required=True)
    if len(set(value)) != len(value):
        raise MemoryError(f"{name} cannot contain duplicates")
    return value


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="microseconds").replace("+00:00", "Z")


@contextmanager
def _writer(root: Path) -> Iterator[None]:
    directory = _storage_path(root, MEMORY)
    if not directory.is_dir():
        raise MemoryError("Memory state has not been initialized", 404)
    lock = _storage_path(root, MEMORY + "/.writer.lock")
    try:
        descriptor = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    except FileExistsError:
        raise MemoryError("Memory writer is busy. Refresh and retry; an abandoned lock requires manual review.", 409) from None
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(json.dumps({"pid": os.getpid(), "at": _now()}))
            handle.flush()
            os.fsync(handle.fileno())
        yield
    finally:
        lock.unlink(missing_ok=True)


def _save(root: Path, state: dict[str, Any], previous: bytes) -> None:
    directory = _storage_path(root, MEMORY)
    history = _storage_path(root, MEMORY + "/history")
    history.mkdir(exist_ok=True)
    snapshot = history / f"revision-{state['revision'] - 1:08d}-{uuid.uuid4().hex}.json"
    with snapshot.open("xb") as handle:
        handle.write(previous)
        handle.flush()
        os.fsync(handle.fileno())
    temporary: str | None = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=directory,
                                         prefix=".state-", suffix=".tmp", delete=False) as handle:
            temporary = handle.name
            json.dump(state, handle, ensure_ascii=False, indent=2, allow_nan=False)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, _storage_path(root, STATE))
        temporary = None
        if os.name != "nt":
            descriptor = os.open(directory, os.O_RDONLY)
            try:
                os.fsync(descriptor)
            finally:
                os.close(descriptor)
    finally:
        if temporary:
            Path(temporary).unlink(missing_ok=True)


def mutate(root: str | Path, request: dict[str, Any]) -> dict[str, Any]:
    """Apply one revision-guarded edit, retaining the exact previous state."""
    repo = _root(root)
    request = _object(request, "request")
    if len(json.dumps(request, ensure_ascii=False).encode("utf-8")) > MAX_INPUT:
        raise MemoryError("Input exceeds 128 KiB")
    expected = request.get("expected_revision")
    if type(expected) is not int or expected < 0:
        raise MemoryError("expected_revision must be a nonnegative integer")
    action = request.get("action")
    if not isinstance(action, str) or action not in {"core", "note", "finding", "review", "recheck"}:
        raise MemoryError("Unknown mutation action")
    with _writer(repo):
        state = _state(repo)
        if state["revision"] != expected:
            raise MemoryError(f"Revision conflict: expected {expected}, current {state['revision']}", 409)
        previous = _storage_path(repo, STATE).read_bytes()
        scopes, _ = _catalog(repo)
        known = {s["id"] for s in scopes}

        def scope_id(value: Any) -> str:
            if not isinstance(value, str) or value not in known:
                raise MemoryError("Unknown scope")
            return value

        now = _now()
        sid = "project"
        summary = ""
        if action == "core":
            core = _object(request.get("core"), "core")
            state["core"] = {name: _input_text(core.get(name, ""), name) for name in ("text", "reason", "open_question")}
            summary = "Updated the working brief"
        elif action == "note":
            sid = scope_id(request.get("scope"))
            note = _object(request.get("note"), "note")
            current = state.setdefault("notes", {}).setdefault(sid, {})
            for name in ("summary", "reason", "open_question"):
                if name in note:
                    current[name] = _input_text(note[name], name)
                else:
                    current.setdefault(name, "")
            current["updated_at"] = now
            summary = "Updated the scope note"
        elif action == "finding":
            raw = _object(request.get("finding"), "finding")
            sid = scope_id(raw.get("scope"))
            kind = raw.get("kind")
            if not isinstance(kind, str) or kind not in KINDS:
                raise MemoryError("Invalid finding kind")
            finding = {name: _input_text(raw.get(name, ""), name, required=name == "text") for name in (
                "text", "reason", "sequence_effect", "project_effect", "method", "created_by")}
            related = _links(raw.get("related_scopes", []), "related_scopes")
            for related_scope in related:
                scope_id(related_scope)
            sources = []
            paths = _links(raw.get("source_paths", []), "source_paths")
            canonical_paths = [_resolve_source(repo, path)[0] for path in paths]
            if len(set(canonical_paths)) != len(paths):
                raise MemoryError("source_paths cannot contain equivalent duplicate paths")
            for path in canonical_paths:
                try:
                    fingerprint = _source(repo, path)["sha256"]
                except MemoryError as error:
                    if error.code != 404:
                        raise
                    fingerprint = None
                sources.append({"path": path, "sha256": fingerprint})
            finding.update(id="finding-" + uuid.uuid4().hex, scope=sid, kind=kind,
                           related_scopes=related, sources=sources, status="proposed",
                           created_at=now, review_note="", reviewed_at="")
            state.setdefault("findings", []).append(finding)
            summary = f"Added proposed {kind}: {finding['text'][:160]}"
        else:
            finding = next((f for f in state.get("findings", []) if f.get("id") == request.get("id")), None)
            if finding is None:
                raise MemoryError("Finding not found", 404)
            sid = finding["scope"]
            if action == "review":
                status = request.get("status")
                if not isinstance(status, str) or status not in STATUSES:
                    raise MemoryError("Invalid review status")
                note = _input_text(request.get("review_note", ""), "review_note", required=status != "proposed")
                finding["status"] = status
                summary = f"Marked {finding['id']} {status}"
            else:
                note = _input_text(request.get("review_note", ""), "review_note", required=True)
                current_sources = request.get("current_sources")
                if not isinstance(current_sources, list) or len(current_sources) > MAX_LINKS:
                    raise MemoryError("current_sources must list every stored source")
                supplied: dict[str, str] = {}
                for record in current_sources:
                    record = _object(record, "current source")
                    path, _ = _resolve_source(repo, record.get("path"))
                    digest = record.get("sha256")
                    if not isinstance(digest, str) or not re.fullmatch(r"[0-9a-f]{64}", digest):
                        raise MemoryError("Each current source requires its observed SHA-256")
                    if path in supplied:
                        raise MemoryError("Duplicate current source")
                    supplied[path] = digest
                if set(supplied) != {s["path"] for s in finding.get("sources", [])}:
                    raise MemoryError("current_sources must include exactly every stored source")
                if not supplied:
                    raise MemoryError("An unlinked finding has no sources to recheck")
                for path, digest in supplied.items():
                    try:
                        actual = _source(repo, path)["sha256"]
                    except MemoryError as error:
                        if error.code == 404:
                            raise MemoryError("Missing sources cannot be restamped", 409) from None
                        raise
                    if actual != digest:
                        raise MemoryError("Source changed since it was inspected; reopen it before rechecking", 409)
                finding["sources"] = [{"path": s["path"], "sha256": supplied[s["path"]]} for s in finding["sources"]]
                summary = f"Rechecked evidence for {finding['id']}: {note[:120]}"
            finding["review_note"] = note
            finding["reviewed_at"] = now
        state["revision"] += 1
        state["updated_at"] = now
        state["journal"] = (state.get("journal", []) + [{"at": now, "action": action, "scope": sid, "summary": summary}])[-40:]
        # Derive before publication: malformed source metadata cannot commit an
        # edit and then report failure to the caller.
        result = _model(repo, state)
        _save(repo, state, previous)
        return result


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True)
    parser.add_argument("command", choices=("model", "packet", "source", "mutate"))
    args = parser.parse_args(argv)
    try:
        raw = sys.stdin.buffer.read(MAX_INPUT + 1)
        if len(raw) > MAX_INPUT:
            raise MemoryError("Input exceeds 128 KiB")
        try:
            payload = json.loads(raw.decode("utf-8-sig")) if raw.strip() else {}
        except (ValueError, UnicodeDecodeError):
            raise MemoryError("Input must be a JSON object") from None
        _object(payload, "Input")
        if args.command == "model":
            result = model(args.root)
        elif args.command == "packet":
            result = packet(args.root, payload.get("scope", "project"))
        elif args.command == "source":
            result = source(args.root, payload.get("path"))
        else:
            result = mutate(args.root, payload)
        print(json.dumps(result, ensure_ascii=True, allow_nan=False))
        return 0
    except MemoryError as error:
        print(json.dumps({"error": str(error), "code": error.code}))
        return 1
    except OSError:
        print(json.dumps({"error": "Memory storage is unavailable; no successful save was confirmed", "code": 400}))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
