"""Museum source index and editable connection memory. Compression never replaces sources."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys

import project_memory
import museum_connections

CAPSULES = "doc/book/memory/museum/capsules.json"


def fingerprint(root: Path, relative: str) -> str | None:
    try:
        return project_memory.source(root, relative)["sha256"]
    except project_memory.MemoryError as error:
        if error.code == 404:
            return None
        raise


def freshness(root: Path, receipts: dict) -> list[dict]:
    result = []
    for path, expected in receipts.items():
        actual = fingerprint(root, path)
        result.append({"path": path, "sha256": expected, "current_sha256": actual,
                       "status": "missing" if actual is None else "unchanged" if actual == expected else "changed"})
    return result


def learning_elements(text: str) -> list[str]:
    """Extract only the explicitly labelled list; never infer a curriculum from code."""
    match = re.search(r"(?im)^\s*(?:\*\*|#{1,6}\s*)Learning elements(?:\s*[—–-]\s*proposed focus)?(?:\*\*)?\s*$", text)
    if not match:
        return []
    lines = text[match.end():].splitlines()
    items = []
    for line in lines:
        if not line.strip():
            if items:
                break
            continue
        item = re.match(r"^\s*[-*]\s+(.+)$", line)
        if not item:
            if not items and line.strip() == "*The labels below set the revision focus; the existing lesson still needs alignment.*":
                continue
            break
        items.append(item.group(1))
    return items


def model(root: Path) -> dict:
    base = project_memory.model(root)
    saved = json.loads((root / CAPSULES).read_text(encoding="utf-8"))
    scopes = {s["id"]: s for s in base["scopes"]}
    rules_evidence = freshness(root, saved["rule_sources"])
    sequences, halls = [], []
    live_route = museum_connections.route(root)
    for live in live_route:
        seq = scopes[live["id"]]
        sequences.append({"id": seq["id"], "title": seq["title"], "order": seq["order"],
                          "halls": live["halls"], "arc": seq["full"], "source": seq["source"]})
        for sid in live["halls"]:
            scope = scopes[sid]
            mid = sid.removeprefix("map:")
            texts = {}
            for kind in ("tutorial", "final"):
                try:
                    texts[kind] = project_memory.source(root, f"commons/maps/{mid}/{kind}.md")
                except project_memory.MemoryError as error:
                    if error.code != 404:
                        raise
            entry = saved["halls"].get(mid)
            receipts = freshness(root, entry["sources"]) if entry else []
            stale = any(e["status"] != "unchanged" for e in receipts + rules_evidence)
            docs = [{"label": k, "path": v["path"], "sha256": v["sha256"]} for k, v in texts.items()]
            halls.append({"id": sid, "map": mid, "title": scope["title"], "sequence": seq["id"],
                          "order": scope["order"], "image": scope["image"],
                          "subjects": learning_elements(texts.get("tutorial", {}).get("text", "")),
                          "subject_status": "proposed" if re.search(r"(?im)^\*\*Learning elements.*proposed", texts.get("tutorial", {}).get("text", "")) else "declared",
                          "documents": docs, "capsule": entry,
                          "evidence": receipts, "status": "recheck" if entry and stale else "inspected" if entry else "index-only",
                          "source_words": sum(len(v["text"].split()) for v in texts.values()),
                          "memory_note": base["notes"].get(sid),
                          "findings": [f for f in base["findings"] if f["scope"] == sid]})
    connections = museum_connections.enrich(root, museum_connections.read(root), museum_connections.addresses(root))
    return {"schema": "museum-memory/2", "captured_at": saved["captured_at"], "revision": base["revision"],
            "rules": saved["rules"], "rule_evidence": rules_evidence, "sequences": sequences, "halls": halls,
            "core": base["core"], "notes": base["notes"],
            "stats": {**base["stats"], "sequences": len(sequences), "maps": len(halls), "capsules": len(saved["halls"]), "recheck": sum(h["status"] == "recheck" for h in halls)},
            "limits": saved["limits"], "links": saved["links"], "connections": connections,
            "existing_structures": museum_connections.existing_structures(root)}


def packet(data: dict, scope: str) -> dict:
    seqs = {s["id"]: s for s in data["sequences"]}
    halls = {h["id"]: h for h in data["halls"]}
    atlas = data["connections"]
    thread_id = scope.removeprefix("thread:") if scope.startswith("thread:") else None
    if scope != "project" and scope not in seqs and scope not in halls and thread_id not in atlas["threads"]:
        raise ValueError("Unknown memory address")
    selected = list(halls.values()) if scope == "project" else [h for h in halls.values() if h["sequence"] == scope] if scope in seqs else [halls[scope]] if scope in halls else []
    lines = [f"ENDLESS MUSEUM / {scope}", f"Memory revision {data['revision']}. Context only; not approval or runtime evidence.",
             "RULES: " + " | ".join(data["rules"]),
             "SOURCE AUTHORITY: current tutorial/final and author decisions; capsules are dated reading aids. Re-read changed/missing sources before using their claims."]
    lines.append("WORKING BRIEF (editable; separate from capsule): " + json.dumps(data["core"], ensure_ascii=False))
    if scope not in halls and data["notes"].get(scope):
        lines.append("SCOPE NOTE: " + json.dumps(data["notes"][scope], ensure_ascii=False))
    if any(e["status"] != "unchanged" for e in data["rule_evidence"]):
        lines.append("RECHECK: shared teaching agreement changed; read its exact source.")
    source_words = sum(h["source_words"] for h in selected)
    if scope == "project":
        lines.append("ROUTE: " + " → ".join(s["id"].removeprefix("sequence:") for s in seqs.values()))
        lines.append("Only six opening halls have inspected capsules. Other halls are a live subject index, not audited summaries.")
        selected = []  # Whole-spine memory uses sequence summaries; unfold halls as needed.
    sources = {e["path"]: e for e in data["rule_evidence"]}
    def touches(address: str) -> bool:
        return address == scope or (scope in seqs and address in seqs[scope]["halls"])
    edges = [e for e in atlas["connections"].values() if
             (thread_id and e["thread"] == thread_id) or
             (not thread_id and (scope == "project" or touches(e["from"]) or touches(e["to"])))]
    if thread_id:
        source_words = sum(halls[sid]["source_words"] for sid in {e[k] for e in edges for k in ("from", "to")} if sid in halls)
    summary_ids = list(seqs) if scope == "project" else [scope] if scope in seqs else [halls[scope]["sequence"]] if scope in halls else list(dict.fromkeys(
        addr if addr in seqs else halls[addr]["sequence"] for e in edges for addr in (e["from"], e["to"]) if addr in seqs or addr in halls))
    lines.append(f"\nSEQUENCE MEMORY / revision {atlas['revision']} / editable editorial readings, not runtime verdicts")
    for sid in summary_ids:
        summary = atlas["summaries"].get(sid)
        if summary:
            lines.append(f"{sid} [{summary['freshness']}]: {summary['summary']} CARRY: {summary['carry']} OPEN: {summary['question']}")
            if scope != "project":
                sources.update({e["path"]: e for e in summary["evidence"]})
    thread_ids = [thread_id] if thread_id else list(dict.fromkeys(e["thread"] for e in edges))
    lines.append("\nTHREADS / arrows run source → target; relation describes what target does with source")
    for tid in thread_ids:
        thread = atlas["threads"][tid]
        lines.append(f"thread:{tid} — {thread['title']}: {thread['summary']}")
        for edge in [e for e in edges if e["thread"] == tid]:
            marker = f"{edge['status']}; {edge['freshness']}" + ("; address unavailable" if edge["unavailable"] else "")
            lines.append(f"  {edge['from']} → {edge['to']} / {edge['relation']} [{marker}]: {edge['reason']}")
            if scope != "project":
                sources.update({e["path"]: e for e in edge["evidence"]})
    lines.append(f"Editable summaries, reasons and dated receipts: {museum_connections.STATE}. Full sources are retrieved, not reconstructed from these summaries.")
    for h in selected:
        c = h["capsule"]
        lines.append(f"\n{h['id']} [{h['status']}]")
        if c:
            for key in ("object", "bring", "change", "keep", "carry", "question", "do_not_infer"):
                lines.append(f"{key.upper()}: {c[key]}")
            sources.update({e["path"]: e for e in h["evidence"]})
        else:
            lines.append(f"SUBJECTS (verbatim tutorial labels; {h['subject_status']}): " + "; ".join(h["subjects"]))
            lines.append("OPEN: no inspected memory capsule. Read the lesson before describing its operation.")
            sources.update({d["path"]: {**d, "status": "live-index"} for d in h["documents"]})
        # User notes stay labelled; do not silently elevate a proposal into the capsule.
        if h.get("memory_note"):
            lines.append("WORKING NOTE (separate from source): " + json.dumps(h["memory_note"], ensure_ascii=False))
        for finding in h["findings"]:
            if finding["status"] != "dismissed":
                lines.append(f"FINDING [{finding['status']}; {finding['freshness']}; {finding.get('method', 'method unstated')}]: {finding['text']}")
                for e in finding.get("sources", []):
                    # Include finding provenance without replacing a capsule's older receipt.
                    lines.append(f"  evidence: {e['path']} [{e['status']}] recorded={e.get('sha256')} current={e.get('current_sha256')}")
        if scope in halls:
            neighbours = seqs[h["sequence"]]["halls"]
            index = neighbours.index(h["id"])
            lines.append("NEIGHBOURS: " + " → ".join(neighbours[max(0, index-1):index+2]))
    lines.append("\nSOURCES (exact bytes; unchanged is not proof):")
    for p, e in sources.items():
        lines.append(f"{p} [{e['status']}] sha256={e.get('current_sha256') or e.get('sha256') or 'missing'}")
    lines.append("\nRETURN OUTWARD: report local consequence, affected next hall, sequence implication and uncertainty. Open current source for code, facts or conflicts. No image-token saving or learning benefit has been measured.")
    text = "\n".join(lines)
    return {"scope": scope, "text": text, "words": len(text.split()), "source_words": source_words, "sources": list(sources.values())}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("command", choices=["model", "packet", "mutate"])
    parser.add_argument("--scope", default="project")
    args = parser.parse_args()
    try:
        if args.command == "mutate":
            raw = sys.stdin.buffer.read(project_memory.MAX_INPUT + 1)
            if len(raw) > project_memory.MAX_INPUT:
                raise project_memory.MemoryError("Update too large", 413)
            result = museum_connections.mutate(args.root.resolve(), json.loads(raw.decode("utf-8-sig")))
            print(json.dumps(result, ensure_ascii=False))
            return
        data = model(args.root.resolve())
        print(json.dumps(data if args.command == "model" else packet(data, args.scope), ensure_ascii=False))
    except (ValueError, OSError) as error:
        print(json.dumps({"error": str(error), "code": getattr(error, "code", 400)}))
        sys.exit(1)


if __name__ == "__main__":
    main()
