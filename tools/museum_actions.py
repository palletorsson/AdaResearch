"""Build a read-only queue of small museum improvements from the live spine.

Authored actions live in commons/data/museum_improvements.json. Their evidence
is a source fingerprint, not a runtime test. Changed evidence asks for a recheck;
the queue never marks a proposal, room or reusable lesson complete by inference.
"""
from __future__ import annotations

from copy import deepcopy
import hashlib
import json
from pathlib import Path

ACTION_PATH = "commons/data/museum_improvements.json"
LESSON_PATH = "doc/curation_lessons.json"
ITERATION_PATH = "commons/data/museum_iteration.json"
POLICY = (
    "Choose one ready action and improve its question, encounter and text together. "
    "Source scaffolds are planning prompts; ready describes the task, not a verified room. "
    "Changed or missing source evidence requires a recheck before resuming a ready proposal. "
    "Shared tokens identify possible reuse. Test the mechanism in a contrasting room before recording a lesson or rolling it out."
)


def unique_strings(values) -> list[str]:
    if not isinstance(values, list):
        return []
    return list(dict.fromkeys(value for value in values if isinstance(value, str) and value))


def source_evidence(root: Path, records) -> list[dict]:
    """Read only repository-contained files, including after symlink resolution."""
    out = []
    for record in records if isinstance(records, list) else []:
        if not isinstance(record, dict):
            raise ValueError("Action evidence entries must be objects with path and sha256.")
        relative = record.get("path", "")
        entry = {"path": relative, "changed": True, "missing": True}
        if not isinstance(relative, str) or not relative:
            entry["reason"] = "invalid_path"
            out.append(entry)
            continue
        try:
            path = (root / relative).resolve()
            path.relative_to(root)
        except (OSError, ValueError):
            entry["reason"] = "outside_repository"
            out.append(entry)
            continue
        if path.is_file():
            try:
                actual = hashlib.sha256(path.read_bytes()).hexdigest()
                expected = record.get("sha256")
                entry["missing"] = False
                entry["changed"] = not isinstance(expected, str) or actual != expected.lower()
            except OSError:
                entry["reason"] = "unreadable_file"
        out.append(entry)
    return out


def live_reuse(reuse: dict, current: dict, rooms: list[dict]) -> dict:
    """Distinguish exact token overlaps from authored candidates for a method."""
    result = deepcopy(reuse)
    selected = unique_strings(reuse.get("tokens", []))
    result["tokens"] = selected
    # Preserve authored candidates, but shared components must still be present
    # in the pilot as well as the other room. A stale proposal is not placement.
    pilot_tokens = set(current.get("space", {}).get("tokens", []))
    live_selected = [token for token in selected if token in pilot_tokens]
    result["shared_rooms"] = []
    by_id = {room["id"]: room for room in rooms}
    for room in rooms:
        if room["id"] == current["id"]:
            continue
        placed = set(room.get("space", {}).get("tokens", []))
        intersection = [token for token in live_selected if token in placed]
        if intersection:
            result["shared_rooms"].append({"id": room["id"], "name": room.get("name", room["id"]),
                                           "sequence": room.get("sequence", ""), "tokens": intersection})
    shared = {room["id"] for room in result["shared_rooms"]}
    methods, seen = [], set()
    for candidate in reuse.get("method_rooms", []):
        if not isinstance(candidate, dict):
            continue
        room_id = candidate.get("id")
        if room_id not in by_id or room_id in shared or room_id in seen or room_id == current["id"]:
            continue
        room = by_id[room_id]
        seen.add(room_id)
        methods.append({"id": room_id, "name": room.get("name", room_id),
                        "sequence": room.get("sequence", ""), "reason": candidate.get("reason", "")})
    result["method_rooms"] = methods
    second = reuse.get("second_room")
    result["second_room"] = second if second in by_id and second != current["id"] else None
    return result


def scaffold_action(room: dict, rooms: list[dict]) -> dict:
    """A bounded next task for every room not covered by an authored action."""
    room_id = room["id"]
    name = room.get("name", room_id)
    outline = room.get("outline", {})
    space = room.get("space", {})
    placed = unique_strings(space.get("tokens", []))
    primary = [token for token in unique_strings(space.get("primary", [])) if token in placed]
    candidate = (primary or placed or [""])[0]
    encounter = candidate or "the room's spatial encounter"
    issue_messages = [issue["message"] for issue in room.get("issues", []) if isinstance(issue, dict) and issue.get("message")]
    if room.get("verification", {}).get("baseline_ready"):
        title = f"Try one optional variation in {name}"
        next_step = f"Choose one assumption from the critical opening in {name}; change it in a reversible experiment and compare the result with the recorded baseline."
        done_when = ["The changed assumption and predicted observation are written down.",
                     "The observed difference and the variation's limits are recorded beside the baseline."]
    elif outline.get("status") != "authored_proposal":
        title = f"Inspect {encounter} and outline {name}"
        next_step = f"Inspect {encounter} in {name}; write one visitor question, one permitted action and one observable consequence, keeping untested behavior labelled as a proposal."
        done_when = ["One candidate encounter has a source or observation record.",
                     "The room outline states a question, action and observable consequence.",
                     "At least one limit or unresolved assumption is named."]
    elif not room.get("text", {}).get("words"):
        title = f"Draft the opening encounter in {name}"
        next_step = f"Use the authored question and candidate experiment to draft {name}'s opening in final.md: question, attempt and observation before explanation. Check the described action against {encounter}."
        done_when = ["The opening gives the visitor an action before explaining its outcome.",
                     "The described encounter names current placements or explicitly labelled proposals.",
                     "One observation is recorded as checked or still needing a walk."]
    else:
        title = f"Walk {encounter} against the text in {name}"
        next_step = f"Walk {encounter} in {name} while reading its associated final.md passage; record what can be reached, changed and observed, then name one discrepancy or supported claim."
        done_when = ["One primary or spatial encounter has a recorded observation.",
                     "The associated text is checked against the observed action and result.",
                     "Any remaining discrepancy names a specific next change."]
    why = issue_messages[0] if issue_messages else outline.get("question") or "This room has no authored improvement action yet."
    reuse = {
        "principle": "Candidate reuse to investigate; no transferable lesson established yet.",
        "mechanism": ("Inspect the current primary tokens: " + ", ".join(primary)) if primary else "",
        "tokens": primary, "method_rooms": [], "second_room": None,
        "second_test": "Choose a contrasting live room and repeat the observation using that room's own settings; record where the mechanism helps and where it fails.",
        "limits": ["An exact shared token does not establish matching configuration, behavior or educational purpose."],
        "lesson_ids": [],
    }
    return {
        "id": "scaffold:" + room_id, "room_id": room_id, "sequence": room.get("sequence", ""),
        "kind": "scaffold", "title": title, "stage": "proposal", "status": "ready",
        "priority": 100 + int(room.get("index", 0)), "why": why, "next_step": next_step,
        "done_when": done_when, "registers": ["space", "tutorial", "book", "critical"],
        "critical_question": outline.get("limit") or "Which assumption does this encounter depend on, and what would changing it make possible?",
        "evidence": [], "dependencies": [], "reuse": live_reuse(reuse, room, rooms),
        "source_note": "Planning prompt derived from the live room outline and inventory. It is not an authored diagnosis or evidence of runtime readiness.",
    }


def build_work_queue(root: Path, rooms: list[dict]) -> dict:
    """Join authored proposals and scaffold tasks to current spine membership."""
    root = root.resolve()
    path = root / ACTION_PATH
    document = json.loads(path.read_text(encoding="utf-8-sig")) if path.is_file() else {"actions": []}
    if not isinstance(document, dict) or not isinstance(document.get("actions"), list):
        raise ValueError(f"{ACTION_PATH} must contain an actions array.")
    live = sorted(rooms, key=lambda room: room.get("index", 0))
    by_id = {room["id"]: room for room in live}
    actions, covered, seen = [], set(), set()
    for original in document["actions"]:
        if not isinstance(original, dict):
            raise ValueError("Museum improvement actions must be objects.")
        room_id = original.get("room_id")
        if room_id not in by_id:
            continue
        action_id = original.get("id")
        if not isinstance(action_id, str) or not action_id or action_id in seen:
            raise ValueError(f"Missing or duplicate museum action id: {action_id!r}")
        seen.add(action_id)
        room = by_id[room_id]
        action = deepcopy(original)
        action.update({"kind": "curated", "sequence": room.get("sequence", ""),
                       "evidence": source_evidence(root, original.get("evidence", [])),
                       "source_note": f"Authored proposal from {ACTION_PATH}. Source fingerprints detect changed inputs; they do not verify the learning encounter."})
        if not action["evidence"]:
            action["source_note"] += " No source evidence is recorded; inspect the premise before starting this authored proposal."
        if action.get("status") == "ready" and (not action["evidence"] or any(item["changed"] or item["missing"] for item in action["evidence"])):
            action["status"] = "recheck"
        # Closing one improvement does not complete the room. Keep its record,
        # and offer a next task when no active authored action covers the room.
        if action.get("status") not in ("closed", "deferred"):
            covered.add(room_id)
        reuse = original.get("reuse", {})
        action["reuse"] = live_reuse(reuse if isinstance(reuse, dict) else {}, room, live)
        actions.append(action)
    actions.extend(scaffold_action(room, live) for room in live if room["id"] not in covered)

    def order(action):
        if action["kind"] == "curated" and action.get("status") == "ready":
            group = 0
        elif action["kind"] == "scaffold":
            group = 2 if by_id[action["room_id"]].get("verification", {}).get("baseline_ready") else 1
        else:
            group = {"recheck": 3, "blocked": 4, "deferred": 5, "closed": 6}.get(action.get("status"), 7)
        priority = action.get("priority", 100)
        return group, priority if isinstance(priority, (int, float)) else 100, by_id[action["room_id"]].get("index", 0), action["id"]

    actions.sort(key=order)
    result = {"actions": actions, "policy": POLICY, "lesson_path": LESSON_PATH}
    iteration_path = root / ITERATION_PATH
    if iteration_path.is_file():
        iteration = json.loads(iteration_path.read_text(encoding="utf-8-sig"))
        if not isinstance(iteration, dict) or not isinstance(iteration.get("items"), list) or not isinstance(iteration.get("lessons"), list):
            raise ValueError(f"{ITERATION_PATH} must contain an object with items and lessons arrays.")
        result["iteration"] = iteration
    return result
