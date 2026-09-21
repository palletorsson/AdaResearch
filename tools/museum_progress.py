#!/usr/bin/env python3
"""Read the live museum completion scaffold; never edit curriculum or prose.

    python tools/museum_progress.py --json
    python tools/museum_progress.py --out path/to/snapshot.json

The live curriculum spine and its sequence files own membership and order.
Source scaffolds are labelled extracts and authoring prompts, not reviewed
ontologies. Authored proposals live in commons/data/completion_outlines/*.json.
File presence, assigned roles and placements never establish a working lesson.
Only an explicit, current completion_reviews.json record can mark a baseline.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import quote

try:
    from . import final_tags
    from .museum_actions import build_work_queue
except ImportError:
    import final_tags
    from museum_actions import build_work_queue

ROOT = Path(__file__).resolve().parents[1]
ROLES = ("primary", "secondary", "decoration")
OUTLINE_FIELDS = ("inherited", "question", "ontology", "experiment", "observe",
                  "limit", "variation", "handoff")
EVIDENCE_FIELDS = ("text", "behavior", "access", "order", "critical", "continuity")
DOC_NAMES = ("intent.md", "blurb.md", "tutorial.md", "summary.md", "technical.md",
             "critical.md", "final.md")
RESOURCE = re.compile(r'res://[^\s\"\'<>]+\.(?:tscn|gd|tres)')


def read_json(path: Path, default=None):
    """Absent optional records are normal; corrupt records must not look absent."""
    if not path.exists() and default is not None:
        return default
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, ValueError) as exc:
        raise ValueError(f"Cannot read {path}: {exc}") from exc


def unique(values):
    return list(dict.fromkeys(values))


def short(text: str, length: int = 620) -> str:
    text = re.sub(r"\s+", " ", str(text)).strip()
    if len(text) <= length:
        return text
    return text[:length].rsplit(" ", 1)[0] + "…"


def paragraphs(text: str) -> list[str]:
    text = re.sub(r"<!--.*?-->", "", text, flags=re.S)
    text = re.sub(r"```.*?```", "", text, flags=re.S)
    blocks = []
    for block in re.split(r"\n\s*\n", text):
        lines = [line for line in block.splitlines()
                 if line.strip() and not re.match(r"^\s*(?:#{1,6}\s|\||---+$)", line)]
        if lines:
            blocks.append(short(" ".join(lines)))
    return blocks


def plain_words(text: str) -> int:
    text = re.sub(r"<!--.*?-->", "", text, flags=re.S)
    # Headings alone do not constitute a manuscript.
    text = re.sub(r"^\s*#{1,6}\s+.*$", "", text, flags=re.M)
    return len(re.findall(r"\b[\w’'-]+\b", text))


def cells(layer) -> list[str]:
    return [cell.strip() for row in layer if isinstance(row, list)
            for cell in row if isinstance(cell, str) and cell.strip() not in ("", "-")]


def base_token(cell: str) -> str:
    return cell.split("#", 1)[0].split(":", 1)[0].strip()


def configured_generated_artifacts(root: Path, map_data: dict, map_source: str,
                                   opening_room: bool) -> list[dict]:
    """Resolve the opening lobby's known view, without inventing grid placements.

    endless_museum._dress_lobby runs only for segment zero; its view fitting
    instances Folding Past outside the interactables layer. Require an explicit
    map-owned lobby and the current source mapping, rather than treating a book
    tag or a stale museum plan as evidence. This is configuration, not a runtime
    observation or a check that the visitor can see the fitting.
    """
    if not opening_room:
        return []
    info = map_data.get("map_info", {})
    museum = info.get("museum", {}) if isinstance(info, dict) else {}
    lobby = museum.get("lobby", {}) if isinstance(museum, dict) else {}
    if not isinstance(lobby, dict):
        return []
    try:
        if not float(lobby.get("enabled", 0)) > 0.5:
            return []
    except (TypeError, ValueError):
        return []

    layout_source = "commons/data/em_layout.json"
    view_source = map_source
    if "with_view" in lobby:
        with_view = lobby["with_view"]
    else:
        # Match _L: an explicit map value wins, then the shared layout, then 1.
        layout_lobby = read_json(root / layout_source, {}).get("lobby", {})
        with_view = layout_lobby.get("with_view", 1) if isinstance(layout_lobby, dict) else 1
        view_source = layout_source if isinstance(layout_lobby, dict) and "with_view" in layout_lobby else "provider default"
    try:
        if not float(with_view) > 0.5:
            return []
    except (TypeError, ValueError):
        return []

    provider = "commons/scenes/endless_museum.gd"
    scene = "commons/primitives/temporal/animated_folding_past.tscn"
    if not (root / provider).is_file() or not (root / scene).is_file():
        return []
    source = (root / provider).read_text(encoding="utf-8-sig")
    pieces = re.search(r"(?m)^const LOBBY_PIECES\s*:=\s*\{([^}]+)\}", source)
    view = re.search(r'(?m)^\s*"view"\s*:\s*"([^"]+)"', pieces[1]) if pieces else None
    if not view or view[1] != "res://" + scene:
        return []
    return [{"token": "folding_past", "runtime_token": "lobby:view",
             "provider": provider, "scene": "res://" + scene,
             "configuration_source": map_source,
             "configuration": {"enabled": lobby["enabled"], "with_view": with_view,
                               "with_view_source": view_source, "opening_room": True},
             "status": "configured", "runtime_verified": False,
             "source_hashes": {path: hashlib.sha256((root / path).read_bytes()).hexdigest()
                               for path in (provider, scene)}}]


def role_of(value) -> tuple[str, str]:
    if isinstance(value, dict):
        return str(value.get("role", "")), str(value.get("group", ""))
    return str(value or ""), ""


def assigned_tokens(placed: list[str], rulings: dict, order: dict, role: str) -> list[str]:
    """Expand the existing @group and role|group order without inventing a walk."""
    members = [token for token in placed if role_of(rulings.get(token))[0] == role]
    result = []
    for item in order.get(role, []):
        if not isinstance(item, str):
            continue
        if item.startswith("@"):
            group = item[1:]
            grouped = [token for token in members if role_of(rulings[token])[1] == group]
            result.extend(token for token in order.get(role + "|" + group, []) if token in grouped)
            result.extend(grouped)
        elif item in members:
            result.append(item)
    # A group may have internal order even if its parent column has no ruling.
    for token in members:
        group = role_of(rulings[token])[1]
        if group:
            grouped = [t for t in members if role_of(rulings[t])[1] == group]
            result.extend(t for t in order.get(role + "|" + group, []) if t in grouped)
            result.extend(grouped)
        else:
            result.append(token)
    return unique(result)


def registry_index(root: Path) -> dict:
    index = {}
    for path in sorted((root / "commons/artifacts/registry").glob("*.json")):
        for token, entry in read_json(path).get("artifacts", {}).items():
            if isinstance(entry, dict):
                index[token] = {"entry": entry, "source": path.relative_to(root).as_posix()}
    return index


def source_outline(room: dict, previous: dict | None, following: dict | None,
                   registry: dict) -> dict:
    """Make room-specific, attributed starting material; leave certainty visible."""
    brief, docs = room["brief"], room["docs"]
    sources = [room["map_source"]]
    if brief:
        sources.append("commons/data/spine_briefs.json")

    def extract(names, action=False):
        for name in names:
            blocks = paragraphs(docs.get(name, ""))
            if action:
                blocks = [b for b in blocks if re.search(
                    r"\b(drag|move|change|press|touch|walk|compare|place|adjust|choose|try|observe)\b", b, re.I)]
            if blocks:
                source = f"commons/maps/{room['id']}/{name}"
                sources.append(source)
                return f"Source extract ({name}; unreviewed): {blocks[0]}"
        return ""

    premise = short(brief.get("for", ""))
    ontology = ("Source claim (room brief; unreviewed): " + short(brief["claim"])) if brief.get("claim") else extract(
        ("intent.md", "blurb.md", "technical.md", "summary.md"))
    if not ontology:
        description = room["map_data"].get("map_info", {}).get("description", "")
        ontology = ("Source description (map_data.json; unreviewed): " + short(description)) if description else (
            "Open authoring task: define what kind of thing this room encounters, its relations and permitted changes. No substantive source proposition found.")
    if not premise:
        premise = extract(("intent.md", "blurb.md", "summary.md")) or ontology
    question = "Proposed authoring question: what could the visitor do to investigate this room's premise? " + premise
    candidates = (room["space"]["primary"] or room["space"]["tokens"])[:4]
    experiment = extract(("tutorial.md", "intent.md", "technical.md", "summary.md"), action=True)
    if not experiment and candidates:
        candidate = next((token for token in candidates if token in registry), "")
        if candidate:
            entry = registry[candidate]["entry"]
            detail = entry.get("interactions") or entry.get("description") or ""
            if isinstance(detail, list):
                detail = "; ".join(str(x) for x in detail)
            if detail:
                experiment = f"Candidate registry encounter ({candidate}; unverified): {short(detail)}"
                sources.append(registry[candidate]["source"])
    if not experiment:
        experiment = "Open authoring task: inspect " + (", ".join(candidates) if candidates else "the room and select a candidate artifact") + "; establish an action the visitor can perform. No supported experiment has been identified by this census."
    limit = ("Unresolved source reading (room brief): " + short(brief["unsure"])) if brief.get("unsure") else extract(("critical.md",))
    if not limit:
        limit = "Open authoring task: identify a particular assumption or omission in this room's mechanism; no critical source was found."
    inherited = (f"Proposed handoff from {previous['name']} ({previous['id']}), the previous room in the live spine. Check which of its distinctions this encounter actually requires.") if previous else (
        "Entry to the current spine. Establish the visitor's starting vocabulary and access needs without assuming earlier museum encounters.")
    if previous:
        prior = previous["brief"].get("claim") or previous["brief"].get("for")
        prior_source = "commons/data/spine_briefs.json"
        if not prior:
            for name in ("blurb.md", "intent.md", "summary.md"):
                blocks = paragraphs(previous["docs"].get(name, ""))
                if blocks:
                    prior, prior_source = blocks[0], f"commons/maps/{previous['id']}/{name}"
                    break
        if prior:
            inherited += " Prior source extract (unreviewed): " + short(prior, 350)
            sources.append(prior_source)
    handoff = (f"Proposed next check: can this encounter prepare {following['name']} ({following['id']}), the next room in the live spine? State the reusable distinction and any unresolved prerequisite.") if following else (
        "End of the current spine. Propose a transfer experiment using earlier distinctions and record what remains unresolved.")
    return {"status": "source_scaffold", "inherited": inherited, "question": question,
            "ontology": ontology, "experiment": experiment,
            "observe": "Proposed evidence task: use the candidate encounter above to record a before/after difference, repeated outcome or invariant. The observable result still needs checking in the implementation and room.",
            "limit": limit,
            "variation": "Proposed variation task: choose one convention from this room's limit above and change a permitted action, relation or criterion of success. Specify what the changed experiment would reveal before describing it as available.",
            "handoff": handoff, "sources": unique(sources), "candidate_artifacts": candidates}


def load_overlays(root: Path) -> tuple[dict, dict]:
    rooms, sequences = {}, {}
    for path in sorted((root / "commons/data/completion_outlines").glob("*.json")):
        doc = read_json(path)
        meta = doc.get("_meta", {})
        if meta.get("sequence") and doc.get("question"):
            sequences[meta["sequence"]] = str(doc["question"])
        for room_id, proposal in doc.get("rooms", {}).items():
            if room_id in rooms:
                raise ValueError(f"Duplicate authored outline for {room_id}: {path}")
            if not isinstance(proposal, dict):
                raise ValueError(f"Outline for {room_id} must be an object: {path}")
            rooms[room_id] = (proposal, path.relative_to(root).as_posix())
    return rooms, sequences


def apply_overlay(outline: dict, overlay: tuple | None) -> dict:
    if not overlay:
        return outline
    proposal, source = overlay
    result = dict(outline)
    authored = [field for field in OUTLINE_FIELDS if isinstance(proposal.get(field), str) and proposal[field].strip()]
    for field in authored:
        result[field] = proposal[field].strip()
    # A metadata-only or hostile "verified" overlay is not an authored outline.
    if len(authored) == len(OUTLINE_FIELDS):
        result["status"] = "authored_proposal"
    result["authored_fields"] = authored
    result["missing_authored_fields"] = [field for field in OUTLINE_FIELDS if field not in authored]
    result["sources"] = unique(outline["sources"] + [s for s in proposal.get("sources", []) if isinstance(s, str)] + [source])
    if isinstance(proposal.get("candidate_artifacts"), list):
        result["candidate_artifacts"] = unique(t for t in proposal["candidate_artifacts"] if isinstance(t, str) and t)
    result["open_questions"] = [q for q in proposal.get("open_questions", []) if isinstance(q, str)]
    return result


def primary_fingerprint_inputs(root: Path, tokens: list[str], registry: dict, cache: dict) -> dict:
    """Include registry entries, primary scenes and their direct scene/script refs.

    This deliberately describes its scope; matching a hash never verifies
    behaviour, and indirect dependencies/runtime changes still need a review.
    """
    result = {}
    for token in tokens:
        record = registry.get(token)
        result[token] = record or {"registry": "missing"}
        if not record:
            continue
        scene = record["entry"].get("scene", "")
        if not isinstance(scene, str) or not scene.startswith("res://"):
            continue
        relative = scene[6:]
        if relative not in cache:
            paths = [relative]
            path = root / relative
            if path.is_file():
                paths.extend(match[6:] for match in RESOURCE.findall(path.read_text(encoding="utf-8", errors="replace")))
            cache[relative] = {p: hashlib.sha256((root / p).read_bytes()).hexdigest() if (root / p).is_file() else "missing"
                               for p in unique(paths)}
        result[token] = {**record, "resources": cache[relative]}
    return result


def fingerprint(root: Path, room: dict, roles: dict, registry: dict, cache: dict) -> str:
    payload = {"format": 1, "map": room["map_data"], "docs": room["docs"], "brief": room["brief"],
               "outline": room["outline"], "sequence": room["sequence"], "previous": room["previous"], "next": room["next"],
               "roles": {key: roles.get(key, {}).get(room["id"], {}) for key in ("roles", "groups", "order")},
               "primary": primary_fingerprint_inputs(root, room["space"]["primary"], registry, cache)}
    if room["space"]["generated_artifacts"]:
        payload["generated_artifacts"] = room["space"]["generated_artifacts"]
    encoded = json.dumps(payload, sort_keys=True, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def review_status(room: dict, record) -> dict:
    scope = "Review record tied to room documents, outline, roles/order/groups, spine neighbours, primary registry entries/scenes/direct resources, and any configured generated-artifact providers/scenes. Runtime and indirect dependencies require manual review."
    result = {"status": "unverified", "baseline_ready": False, "scope": scope}
    if not isinstance(record, dict):
        return result
    evidence = record.get("evidence", {})
    valid_evidence = isinstance(evidence, dict) and all(isinstance(evidence.get(k), str) and evidence[k].strip() for k in EVIDENCE_FIELDS)
    current = record.get("fingerprint") == room["fingerprint"]
    complete = bool(record.get("reviewed_at") and record.get("reviewer") and valid_evidence)
    essentials = bool(room["text"]["words"] and room["space"]["exists"] and room["space"]["primary"] and not room["text"]["missing_tags"])
    result.update({"status": "verified" if current and complete and essentials else "needs_review",
                   "baseline_ready": bool(current and complete and essentials),
                   "reviewed_at": record.get("reviewed_at", ""), "reviewer": record.get("reviewer", ""),
                   "evidence": evidence, "fingerprint_matches": current})
    return result


def build_progress(root: Path = ROOT) -> dict:
    root = root.resolve()
    spine = read_json(root / "commons/maps/curriculum_spine.json")
    roles = read_json(root / "commons/data/artifact_roles.json", {})
    briefs = read_json(root / "commons/data/spine_briefs.json", {}).get("briefs", {})
    overlays, sequence_questions = load_overlays(root)
    reviews = read_json(root / "commons/data/completion_reviews.json", {}).get("rooms", {})
    registry = registry_index(root)
    sequences, rooms, seen = [], [], set()
    for seq in sorted(spine.get("spine", {}).get("sequences", []), key=lambda row: row.get("order", 999)):
        seq_id = seq["name"]
        seq_source = f"commons/maps/sequences/{seq_id}.json"
        entry = read_json(root / seq_source).get("sequences", {}).get(seq_id)
        if not isinstance(entry, dict) or not isinstance(entry.get("maps"), list):
            raise ValueError(f"Missing sequence maps in {seq_source}")
        sequence = {"id": seq_id, "name": entry.get("name") or seq_id, "order": seq.get("order"),
                    "phase": seq.get("phase", ""), "question": sequence_questions.get(seq_id) or entry.get("truth") or entry.get("description") or seq.get("qfep_role", ""),
                    "rooms": list(entry["maps"])}
        sequences.append(sequence)
        for room_id in sequence["rooms"]:
            if not isinstance(room_id, str) or room_id in seen:
                raise ValueError(f"Invalid or duplicate spine room {room_id!r} in {seq_source}")
            seen.add(room_id)
            folder = root / "commons/maps" / room_id
            map_source = f"commons/maps/{room_id}/map_data.json"
            map_data = read_json(root / map_source, {})
            layers = map_data.get("layers", {})
            placed = [base_token(cell) for cell in cells(layers.get("interactables", []))]
            placed = [token for token in placed if token]
            utility_cells = cells(layers.get("utilities", []))
            # Same utility grammar as final_tags.placed_tokens (including #3t).
            utilities = unique(cell.split(":", 1)[0].lstrip("@#") for cell in utility_cells)
            tokens = unique(placed)
            generated = configured_generated_artifacts(root, map_data, map_source, opening_room=not rooms)
            text_references = set(tokens + utilities + [item["token"] for item in generated])
            rulings = roles.get("roles", {}).get(room_id, {})
            order = roles.get("order", {}).get(room_id, {})
            role_eligible = unique(tokens + [token for token in utilities if token in rulings])
            space = {"exists": (root / map_source).is_file(), "placed_count": len(placed), "tokens": tokens,
                     "utility_tokens": utilities, "generated_artifacts": generated,
                     **{role: assigned_tokens(role_eligible, rulings, order, role) for role in ROLES},
                     "unruled": [token for token in tokens if role_of(rulings.get(token))[0] not in ROLES],
                     "exits": unique(cell.split(":", 1)[1].split("#", 1)[0] for cell in utility_cells if cell.startswith("t:"))}
            docs = {name: (folder / name).read_text(encoding="utf-8-sig") for name in DOC_NAMES if (folder / name).is_file()}
            final = docs.get("final.md", "")
            tags = final_tags.tokens_of(final_tags.parse(final))
            brief = briefs.get(room_id) or {}
            encoded = quote(room_id, safe="")
            rooms.append({"id": room_id, "name": map_data.get("map_info", {}).get("name") or room_id,
                          "sequence": seq_id, "sequence_name": sequence["name"], "index": len(rooms) + 1,
                          "previous": None, "next": None, "outline": {},
                          "text": {"exists": "final.md" in docs, "words": plain_words(final), "tags": tags,
                                   "missing_tags": [tag for tag in tags if tag not in text_references]},
                          "space": space, "critical": {"exists": "critical.md" in docs},
                          "comment": brief.get("comment", ""), "commented_at": brief.get("commented_at", ""),
                          "issues": [], "next_action": "",
                          "links": {"compose": "/compose?map=" + encoded, "map": "/map-viewer?map=" + encoded,
                                    "thread": "/necklace/thread?map=" + encoded, "brief": "/spine-brief?map=" + encoded},
                          "map_source": map_source, "map_data": map_data, "docs": docs, "brief": brief})
    resource_cache = {}
    for index, room in enumerate(rooms):
        previous = rooms[index - 1] if index else None
        following = rooms[index + 1] if index + 1 < len(rooms) else None
        room["previous"], room["next"] = previous["id"] if previous else None, following["id"] if following else None
        room["outline"] = apply_overlay(source_outline(room, previous, following, registry), overlays.get(room["id"]))
        room["outline"]["sources"] = unique(room["outline"]["sources"] + ["commons/maps/curriculum_spine.json", f"commons/maps/sequences/{room['sequence']}.json"])
        room["fingerprint"] = fingerprint(root, room, roles, registry, resource_cache)
        room["verification"] = review_status(room, reviews.get(room["id"]))
        issues = room["issues"]
        def issue(kind, message):
            issues.append({"kind": kind, "message": message})
        if not room["text"]["exists"]:
            issue("missing_text", "Write final.md around the essential encounter.")
        elif not room["text"]["words"]:
            issue("empty_text", "final.md has no substantive text beyond headings/comments.")
        if not room["space"]["exists"]:
            issue("missing_map", "No map_data.json found for this spine room.")
        if not room["space"]["placed_count"]:
            issue("no_artifacts", "No interactable placements found; identify the essential encounter.")
        if not room["space"]["primary"]:
            issue("primary_unassigned", "No placed token has an explicit primary role; implicit primary defaults are not an authored decision.")
        if room["text"]["missing_tags"]:
            issue("stale_tags", "Text tags name absent placements: " + ", ".join(room["text"]["missing_tags"]))
        missing_candidates = [t for t in room["outline"]["candidate_artifacts"] if t not in room["space"]["tokens"] + room["space"]["utility_tokens"]]
        if missing_candidates:
            issue("proposed_artifacts", "Proposed candidates are not placed: " + ", ".join(missing_candidates))
        if following and following["sequence"] == room["sequence"] and room["space"]["exits"] and following["id"] not in room["space"]["exits"]:
            issue("route_mismatch", f"Declared teleporter destinations ({', '.join(room['space']['exits'])}) omit the next spine room {following['id']}; check the actual route.")
        if room["outline"].get("authored_fields") and room["outline"].get("missing_authored_fields"):
            issue("missing_outline_fields", "Authored proposal still needs: " + ", ".join(room["outline"]["missing_authored_fields"]))
        if not room["critical"]["exists"]:
            issue("critical_source_missing", "No critical.md source; a critical opening may still be present in final.md and needs review.")
        if room["comment"]:
            # Keep user corrections visible even when an authored proposal exists.
            issue("user_comment", "User comment to reconcile with the current outline: " + str(room["comment"]))
        for question in room["outline"].get("open_questions", []):
            issue("authoring_question", question)
        if room["verification"]["status"] == "needs_review":
            issue("review_stale_or_incomplete", "Saved review is incomplete or its source fingerprint no longer matches; repeat the affected checks.")
        if room["verification"]["baseline_ready"]:
            room["next_action"] = "Develop optional variations; revisit the recorded review when the encounter changes."
        elif room["comment"]:
            room["next_action"] = "Reconcile the user's comment with the room outline and record the resulting decision."
        elif room["text"]["missing_tags"]:
            room["next_action"] = "Reconcile absent artifact tags with the intended encounter and current floor."
        elif room["outline"].get("open_questions"):
            room["next_action"] = room["outline"]["open_questions"][0]
        elif room["outline"]["status"] == "source_scaffold":
            room["next_action"] = "Turn these labelled source extracts into a room-specific authored question, ontology and experiment proposal."
        elif not room["text"]["words"]:
            room["next_action"] = "Inspect candidate behavior, arrange the essential experiment, and draft final.md."
        else:
            room["next_action"] = "Read and walk the encounter against final.md; record evidence for behavior, access, order, critical opening and continuity."
    # Drop working inputs only after all neighbouring-source scaffolds are built.
    for room in rooms:
        for key in ("map_source", "map_data", "docs", "brief"):
            room.pop(key)
    for sequence in sequences:
        members = [room for room in rooms if room["sequence"] == sequence["id"]]
        sequence.update({"room_count": len(members), "written": sum(room["text"]["words"] > 0 for room in members),
                         "outlined": sum(room["outline"]["status"] == "authored_proposal" for room in members),
                         "baseline_ready": sum(room["verification"]["baseline_ready"] for room in members)})
    meta = {"generated": datetime.now(timezone.utc).isoformat(), "sequences": len(sequences), "rooms": len(rooms),
            "outlined": sum(r["outline"]["status"] == "authored_proposal" for r in rooms),
            "source_scaffolded": sum(r["outline"]["status"] == "source_scaffold" for r in rooms),
            "written": sum(r["text"]["words"] > 0 for r in rooms),
            "critical": sum(r["critical"]["exists"] for r in rooms),
            "with_artifacts": sum(r["space"]["placed_count"] > 0 for r in rooms),
            "primary_assigned": sum(bool(r["space"]["primary"]) for r in rooms),
            "needs_attention": sum(bool(r["issues"]) for r in rooms),
            "baseline_ready": sum(r["verification"]["baseline_ready"] for r in rooms),
            "note": "Written counts nonempty manuscript files; outlined counts authored proposals. Placement and role counts are inventory facts, not evidence of working or reachable lessons.",
            "orphan_outlines": sorted(set(overlays) - seen)}
    return {"meta": meta, "sequences": sequences, "rooms": rooms,
            "work_queue": build_work_queue(root, rooms)}


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="Print the full live JSON (no writes).")
    parser.add_argument("--out", type=Path, help="Explicitly write a JSON snapshot to this path.")
    parser.add_argument("--root", type=Path, default=ROOT, help=argparse.SUPPRESS)
    args = parser.parse_args(argv)
    try:
        payload = build_progress(args.root)
        encoded = json.dumps(payload, ensure_ascii=False, indent=2) + "\n"
        if args.out:
            args.out.parent.mkdir(parents=True, exist_ok=True)
            args.out.write_text(encoded, encoding="utf-8")
        if args.json:
            print(encoded, end="")
        else:
            m = payload["meta"]
            print(f"{m['sequences']} sequences / {m['rooms']} rooms; {m['outlined']} authored outlines, "
                  f"{m['written']} manuscripts with text, {m['with_artifacts']} rooms with placements; "
                  f"{m['baseline_ready']} explicitly reviewed baselines.")
        return 0
    except (ValueError, OSError) as exc:
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
