#!/usr/bin/env python3
"""
Query artifact @identity blocks.

Usage:
    python tools/query_identities.py                     # list all
    python tools/query_identities.py search "spring"     # search all fields
    python tools/query_identities.py needs-missing       # artifacts with [missing] needs
    python tools/query_identities.py needs-has           # artifacts with [has] needs
    python tools/query_identities.py desires             # all desires
    python tools/query_identities.py truths              # all truths
    python tools/query_identities.py relationships       # relationship graph
    python tools/query_identities.py field essence       # show one field from all
    python tools/query_identities.py asks "what emerges" # natural language query
"""

import sys
import re
import json
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SEARCH_DIRS = [REPO / "algorithms", REPO / "commons" / "artifacts"]
IDENTITY_FIELDS = ["essence", "desire", "critical_parameter", "triggers",
                   "emerges", "needs", "relationships", "truth"]


def extract_all():
    identities = []
    for search_dir in SEARCH_DIRS:
        if not search_dir.exists():
            continue
        for gd_file in sorted(search_dir.rglob("*.gd")):
            text = gd_file.read_text(encoding="utf-8", errors="replace")
            if "@identity" not in text:
                continue
            ident = {
                "name": gd_file.stem,
                "file": str(gd_file.relative_to(REPO)),
                "folder": str(gd_file.parent.relative_to(REPO)),
            }
            for field in IDENTITY_FIELDS:
                match = re.search(rf"#\s*{field}:\s*(.+)", text)
                if match:
                    ident[field] = match.group(1).strip()
            identities.append(ident)
    return identities


def cmd_list(identities):
    for i in identities:
        print(f"{i['name']}: {i.get('essence', '(no essence)')}")


def cmd_search(identities, query):
    query_lower = query.lower()
    results = []
    for i in identities:
        all_text = " ".join(str(v) for v in i.values()).lower()
        if query_lower in all_text:
            results.append(i)
    if not results:
        print(f"No artifacts match '{query}'")
        return
    print(f"{len(results)} artifacts match '{query}':\n")
    for i in results:
        print(f"  {i['name']}")
        # Show which fields matched
        for field in IDENTITY_FIELDS:
            val = i.get(field, "")
            if query_lower in val.lower():
                print(f"    {field}: {val}")
        print()


def cmd_needs_missing(identities):
    print("Artifacts with [missing] needs:\n")
    for i in identities:
        needs = i.get("needs", "")
        missing = re.findall(r"([^.]+?\[missing[^\]]*\])", needs)
        if missing:
            print(f"  {i['name']}:")
            for m in missing:
                print(f"    - {m.strip()}")
            print()


def cmd_needs_has(identities):
    print("Artifacts with [has] capabilities:\n")
    for i in identities:
        needs = i.get("needs", "")
        has = re.findall(r"([^.]+?\[has\])", needs)
        if has:
            print(f"  {i['name']}:")
            for h in has:
                print(f"    + {h.strip()}")
            print()


def cmd_desires(identities):
    print("What each artifact desires:\n")
    for i in identities:
        desire = i.get("desire", "")
        if desire:
            print(f"  {i['name']}: {desire}")


def cmd_truths(identities):
    print("What each artifact claims is true:\n")
    for i in identities:
        truth = i.get("truth", "")
        if truth:
            print(f"  {i['name']}: {truth}")


def cmd_field(identities, field_name):
    if field_name not in IDENTITY_FIELDS:
        print(f"Unknown field: {field_name}")
        print(f"Available: {', '.join(IDENTITY_FIELDS)}")
        return
    print(f"All '{field_name}' values:\n")
    for i in identities:
        val = i.get(field_name, "")
        if val:
            print(f"  {i['name']}: {val}")


def cmd_relationships(identities):
    print("Artifact relationship graph:\n")
    # Parse relationships into unlocks/depends/contrasts
    for i in identities:
        rels = i.get("relationships", "")
        if not rels:
            continue
        print(f"  {i['name']}:")
        # Parse "Unlocks X. Depends on Y. Contrasts with Z."
        for part in rels.split("."):
            part = part.strip()
            if not part:
                continue
            if "unlock" in part.lower():
                print(f"    -> unlocks: {part}")
            elif "depend" in part.lower():
                print(f"    <- depends: {part}")
            elif "contrast" in part.lower():
                print(f"    <> contrasts: {part}")
            elif "feed" in part.lower() or "live" in part.lower():
                print(f"    >> feeds: {part}")
            elif "complement" in part.lower() or "complete" in part.lower():
                print(f"    == complements: {part}")
            else:
                print(f"    -- {part}")
        print()


def cmd_asks(identities, question):
    """Simple natural language query — match question words against identity fields."""
    question_lower = question.lower()

    # Map question patterns to fields
    field_hints = {
        "what is": "essence",
        "what does": "essence",
        "what want": "desire",
        "desire": "desire",
        "need": "needs",
        "missing": "needs",
        "parameter": "critical_parameter",
        "slider": "critical_parameter",
        "trigger": "triggers",
        "happen": "triggers",
        "emerge": "emerges",
        "produce": "emerges",
        "relate": "relationships",
        "connect": "relationships",
        "unlock": "relationships",
        "depend": "relationships",
        "truth": "truth",
        "claim": "truth",
        "mean": "truth",
    }

    target_field = None
    for hint, field in field_hints.items():
        if hint in question_lower:
            target_field = field
            break

    # Extract subject (artifact name or topic)
    subject_words = []
    skip = {"what", "is", "does", "do", "the", "from", "about", "how", "why", "can", "a", "an", "of"}
    for word in question_lower.split():
        if word not in skip and word not in field_hints:
            subject_words.append(word)
    subject = " ".join(subject_words)

    results = []
    for i in identities:
        all_text = " ".join(str(v) for v in i.values()).lower()
        if subject and subject not in all_text:
            continue
        if target_field:
            val = i.get(target_field, "")
            if val:
                results.append((i["name"], target_field, val))
        else:
            # Show everything
            for field in IDENTITY_FIELDS:
                val = i.get(field, "")
                if val and (not subject or subject in val.lower()):
                    results.append((i["name"], field, val))

    if not results:
        print(f"No answer found for: '{question}'")
        return

    print(f"Answering: '{question}'\n")
    for name, field, val in results:
        print(f"  {name}.{field}: {val}")


def main():
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    identities = extract_all()

    if len(sys.argv) < 2:
        cmd_list(identities)
        return

    cmd = sys.argv[1]

    if cmd == "search" and len(sys.argv) > 2:
        cmd_search(identities, " ".join(sys.argv[2:]))
    elif cmd == "needs-missing":
        cmd_needs_missing(identities)
    elif cmd == "needs-has":
        cmd_needs_has(identities)
    elif cmd == "desires":
        cmd_desires(identities)
    elif cmd == "truths":
        cmd_truths(identities)
    elif cmd == "relationships":
        cmd_relationships(identities)
    elif cmd == "field" and len(sys.argv) > 2:
        cmd_field(identities, sys.argv[2])
    elif cmd == "asks" and len(sys.argv) > 2:
        cmd_asks(identities, " ".join(sys.argv[2:]))
    elif cmd == "--json":
        print(json.dumps(identities, indent=2, ensure_ascii=False))
    else:
        print("Commands: search <query>, needs-missing, needs-has, desires, truths,")
        print("          relationships, field <name>, asks <question>, --json")


if __name__ == "__main__":
    main()
