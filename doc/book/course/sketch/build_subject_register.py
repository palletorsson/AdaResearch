"""Render the authored subject plan and index lexical code uses in map tutorials.

No match is treated as proof that a topic is taught. No curriculum decision is
inferred here. The old section taxonomy and its checker remain unchanged.
"""
from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
COURSE = HERE.parent


def read_json(path):
    text = path.read_text(encoding="utf-8-sig")
    return json.loads(re.sub(r",\s*([}\]])", r"\1", text))


def route():
    result = []
    all_sequences = read_json(ROOT / "commons/maps/curriculum_spine.json")["spine"]["sequences"]
    for seq in sorted(all_sequences, key=lambda x: x["order"]):
        if seq["order"] > 10:
            break
        maps = read_json(ROOT / f"commons/maps/sequences/{seq['name']}.json")["sequences"][seq["name"]]["maps"]
        result.extend({"map": m, "sequence": seq["name"], "chapter": seq["order"]} for m in maps)
    return result, {x["name"] for x in all_sequences}


def code_lines(path):
    """Fenced GDScript/unlabelled code only, with approximate strings/comments removed."""
    fence = None
    active = False
    for number, original in enumerate(path.read_text(encoding="utf-8-sig").splitlines(), 1):
        marker = re.match(r"^\s*(`{3,}|~{3,})(.*)$", original)
        if marker:
            run, suffix = marker.groups()
            if fence is None:
                fence = run
                active = suffix.strip().lower() in ("", "gdscript", "gd")
            elif run[0] == fence[0] and len(run) >= len(fence) and not suffix.strip():
                fence = None
                active = False
            continue
        if active:
            cleaned = re.sub(r'''"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\#.*''', " ", original)
            yield number, original, cleaned


def token_pattern(form):
    # Compound illustrative call signatures are not reliable lexical tokens.
    if not re.fullmatch(r"[A-Za-z_@][A-Za-z_0-9.]*", form):
        return None
    return re.compile(r"(?<![A-Za-z_0-9])" + re.escape(form) + r"(?![A-Za-z_0-9])")


def first_chapter(value):
    m = re.search(r"(?:supplied:)?(\d+)\.", value or "")
    return int(m.group(1)) if m else None


def map_link(name):
    if name == "Day_Zero":
        return "Day Zero"
    return f"[{name}](../../../../commons/maps/{name}/tutorial.md)" if (ROOT / f"commons/maps/{name}/tutorial.md").exists() else f"[{name} — tutorial missing](../../../../commons/maps/{name}/final.md)"


def main():
    plan_path = HERE / "subject_lineage.json"
    plan = read_json(plan_path)
    subjects = plan["subjects"]
    rows, sequences = route()
    order = {"Day_Zero": -1, **{row["map"]: i for i, row in enumerate(rows)}}
    assert plan["scope"]["map_count"] == len(rows), "Scope map count differs from spine"
    assert plan["scope"]["sequence_count"] == len({r["sequence"] for r in rows}), "Scope sequence count differs from spine"
    ids = {s["id"] for s in subjects}
    assert len(ids) == len(subjects), "Duplicate subject id"
    by_id = {s["id"]: s for s in subjects}
    taxonomy = read_json(COURSE / "taxonomy.json")
    tax_by_id = {e["id"]: e for e in taxonomy["entries"]}
    for s in subjects:
        assert s["status"] == "proposed_not_promoted", (s["id"], "This register records proposals")
        assert s["introduced"]["map"] in order, s["id"]
        assert s["taxonomy_ids"], s["id"]
        assert set(s["taxonomy_ids"]) <= tax_by_id.keys(), (s["id"], set(s["taxonomy_ids"]) - tax_by_id.keys())
        assert set(s["prerequisites"]) <= ids, s["id"]
        assert set(s["used_in"]) <= order.keys(), s["id"]
        for need in s["prerequisites"]:
            assert order[by_id[need]["introduced"]["map"]] <= order[s["introduced"]["map"]], (s["id"], "late prerequisite", need)
        assert all(order[m] >= order[s["introduced"]["map"]] for m in s["used_in"]), (s["id"], "use before introduction")
        for preview in s["previews"]:
            assert preview["map"] in order, preview
            assert preview["kind"] in ("encountered", "supplied"), preview
            assert preview["scope"].strip(), preview
            assert order[preview["map"]] < order[s["introduced"]["map"]], (s["id"], "Preview must precede introduction")
        for deeper in s["deepen"]:
            if "map" in deeper:
                assert deeper["map"] in order, deeper
                assert order[deeper["map"]] >= order[s["introduced"]["map"]], (s["id"], "deepening before introduction")
            else:
                assert deeper["sequence"] in sequences, deeper
    # Dependencies can be taught within the same hall, but may not form a cycle.
    visited, active = set(), set()
    def visit(key):
        assert key not in active, ("Prerequisite cycle", key)
        if key in visited:
            return
        active.add(key)
        for need in by_id[key]["prerequisites"]:
            visit(need)
        active.remove(key)
        visited.add(key)
    for key in ids:
        visit(key)

    uses = {key: [] for key in tax_by_id}
    patterns = {}
    for key, e in tax_by_id.items():
        pats = [token_pattern(f) for f in e.get("forms", {}).get("code", [])]
        patterns[key] = [p for p in pats if p is not None]
    sources = []
    for row in rows:
        path = ROOT / f"commons/maps/{row['map']}/tutorial.md"
        if not path.exists():
            sources.append({**row, "path": str(path.relative_to(ROOT)).replace("\\", "/"), "status": "missing"})
            continue
        sources.append({**row, "path": str(path.relative_to(ROOT)).replace("\\", "/"), "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
        for number, original, cleaned in code_lines(path):
            for key, pats in patterns.items():
                if any(p.search(cleaned) for p in pats):
                    uses[key].append({"map": row["map"], "line": number, "excerpt": original.strip()[:180]})

    entry_index = []
    technical = {"concept", "maths", "gdscript", "godot", "supplied"}
    for e in taxonomy["entries"]:
        links = [s["id"] for s in subjects if e["id"] in s["taxonomy_ids"]]
        chapter = first_chapter(e.get("introduced_at"))
        if links:
            disposition = "linked_to_proposed_subject"
        elif e["kind"] not in technical:
            disposition = "vocabulary_or_administration"
        elif chapter is not None and chapter > 10:
            disposition = "later_taxonomy_entry_with_early_use_to_review" if uses[e["id"]] else "outside_current_scope"
        else:
            disposition = "needs_mapping_review"
        entry_index.append({"id": e["id"], "kind": e["kind"], "existing_introduced_at": e.get("introduced_at"), "subjects": links, "disposition": disposition, "observed_code_uses": uses[e["id"]]})
    index = {"scope": plan["scope"], "status": "lexical_observations_and_proposed_links_not_teaching_proof", "scan_limits": "Fenced gdscript/gd/unlabelled code in tutorial.md only. Simple identifier forms, approximate strings/comments removed. No prose inference, shader-language scan, operator parsing, or recursive implementation scan. No match proves availability or instruction.", "plan_sha256": hashlib.sha256(plan_path.read_bytes()).hexdigest(), "taxonomy_sha256": hashlib.sha256((COURSE / 'taxonomy.json').read_bytes()).hexdigest(), "sources": sources, "entries": entry_index}
    (HERE / "taxonomy_use_index.json").write_text(json.dumps(index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    out = ["# Subject register: first use, usable introduction and deeper study", "", "3 October 2026. Proposed curriculum through Randomness; teaching locations are not completion claims.", "", "Authored decisions: [subject_lineage.json](subject_lineage.json). Existing token/word taxonomy: [taxonomy.json](../taxonomy.json). Observed tutorial-code occurrences and a disposition for every existing taxonomy entry: [taxonomy_use_index.json](taxonomy_use_index.json).", "", "## How to read this", "", *[f"- {r}" for r in plan["rules"]], "", "A usable introduction is a small contract: what the operation receives, returns or changes, and one variation the learner can deliberately make. Deeper study adds a named capability; it does not invalidate the earlier use. The provided renderer or input device remains distinct from the operation taught.", "", "The register uses stable map names. The existing taxonomy's numeric section locations continue to describe the older functional draft. Promote locations into that checker only as each rewritten lesson, its signature and its runnable example are revised together. The checker has not been changed to enforce this new plan.", "", "## The two immediate examples", "", "**Sine in Trans_Pre:** use elapsed time to obtain a smooth value between -1 and 1; change the extent and duration of a repeating height. With a positive period, `height = centre + amplitude * sin(TAU * elapsed / period)`. Name each input and the output; show one cycle. Circle geometry, phase relationships, sampled waves and sound are later developments. Sine's behaviour is introduced; its implementation is borrowed.", "", "**Random draws in Array:** generate a bounded offset for a copy; keep the address and the copy. Change the range and compare. A small local generator and resettable seed make a repeatable comparison possible. Generator state, request order, distributions, estimation and feedback become the Randomness sequence's work. Do not call random results unique or balanced by guarantee.", "", "## Subjects", ""]
    groups = list(dict.fromkeys(s["group"] for s in subjects))
    for group in groups:
        out += [f"### {group}", "", "| Subject | Usable introduction and learner action | Later uses | Deeper treatment | Needs |", "|---|---|---|---|---|"]
        for s in [s for s in subjects if s["group"] == group]:
            deep = "; ".join((map_link(d["map"]) if "map" in d else f"Later sequence: {d['sequence']}") + " — " + d["capability"] for d in s["deepen"]) or "Consolidate through use; no separate deep dive prescribed."
            needs = ", ".join(by_id[x]["title"] for x in s["prerequisites"]) or "Day Zero / named supplied context"
            later = ", ".join(map_link(m) for m in s["used_in"]) or "Local first lesson; return as needed."
            out.append(f"| **{s['title']}** (`{s['id']}`) | {map_link(s['introduced']['map'])}: {s['introduced']['capability']} | {later} | {deep} | {needs} |")
        out.append("")
    out += ["## Earlier encounters and supplied parts", "", "An encounter lets the student notice something. A supplied interface permits a stated use while keeping its implementation outside the task. Neither silently grants every later capability of that subject. Explain any exposed operation the student must edit.", "", "| Subject | Earlier hall | Status | Limit of this appearance |", "|---|---|---|---|"]
    for s in subjects:
        for preview in s["previews"]:
            out.append(f"| {s['title']} | {map_link(preview['map'])} | {preview['kind']} | {preview['scope']} |")
    out += ["", "## Map checklist", "", "These are deliberately selected teaching uses, not an inventory of every operation inside every artifact. An empty cell can be a reflective hall, not a missing lesson. A dependency within a hall must be explained before the example that needs it.", "", "| Hall | Earlier encounter / supplied | Introduce | Reuse | Deepen |", "|---|---|---|---|---|"]
    for row in [{"map": "Day_Zero"}] + rows:
        m = row["map"]
        introductions = [s["title"] for s in subjects if s["introduced"]["map"] == m]
        reuses = [s["title"] for s in subjects if m in s["used_in"]]
        deepens = [s["title"] for s in subjects if any(d.get("map") == m for d in s["deepen"])]
        previews = [f"{s['title']} ({p['kind']})" for s in subjects for p in s["previews"] if p["map"] == m]
        out.append(f"| {map_link(m)} | {'; '.join(previews) or '—'} | {'; '.join(introductions) or '—'} | {'; '.join(reuses) or '—'} | {'; '.join(deepens) or '—'} |")
    out += ["", "## Exact taxonomy crosswalk", "", "The subject groups organise teaching; existing taxonomy IDs retain their exact identities. Listing an ID here does not mean every API in its group must appear in the first example. A lesson declares only the tokens it actually uses. Review the exact token introduction when promoting that lesson.", "", "| Subject | Existing taxonomy IDs |", "|---|---|"]
    for s in subjects:
        out.append(f"| {s['title']} | {', '.join('`'+x+'`' for x in s['taxonomy_ids'])} |")
    review = [e for e in entry_index if e["disposition"] in ("needs_mapping_review", "later_taxonomy_entry_with_early_use_to_review")]
    out += ["", "## Unresolved taxonomy items", "", "These are kept visible rather than assigned an invented teaching date. An old template, unused helper, prose-only concept or a legitimate advanced API can all produce different decisions. This is a review queue, not a list of confirmed curriculum defects: identifiers can share names, and entries with no match may belong entirely after Randomness. Inspect the excerpt in the JSON index before changing a lesson.", "", "| Entry | Existing location | First candidate code occurrence | Disposition |", "|---|---|---|---|"]
    for e in review:
        use = e["observed_code_uses"]
        first = f"{map_link(use[0]['map'])}, line {use[0]['line']}" if use else "No identifier match in this scan"
        out.append(f"| `{e['id']}` | {e['existing_introduced_at']} | {first} | {e['disposition']} |")
    out += ["", f"Coverage: {len(subjects)} authored subject groups; {len(rows)} map positions plus Day Zero; every one of the {len(entry_index)} existing taxonomy entries is indexed. {len(review)} entries need mapping or early-use review. This is not a claim to cover every possible subject in Godot or every implementation dependency in the museum.", "", "## What the taxonomy should enforce", "", "1. A lesson may require only a named capability already introduced, introduced earlier within that lesson, or provided through an explicit supplied interface.", "2. An early use must teach enough to make a deliberate change. Merely showing a control or naming sine/randomness is not that introduction.", "3. A deeper return states what becomes newly possible. It should not restart the definition or imply that earlier use was illegitimate.", "4. The same data type can have different meanings. Vector3 position, displacement, velocity and force have different contracts and units.", "5. A lexical token match is evidence to inspect, never proof that a subject is taught. A passing code check cannot certify the student's understanding.", "6. The hard teaching dependencies apply to tutorial tasks and executable examples. They do not ban a critical word or museum artifact from appearing before its construction lesson.", "7. Unmapped prerequisites remain unresolved until an editor chooses a small introduction, a supplied interface, a later return or a local order change.", "", "Regenerate observations and tables with `python doc/book/course/sketch/build_subject_register.py` after editing the authored JSON or the tutorials. The script validates references, prerequisite order and cycles; it does not invent a curriculum or update the legacy checker.", ""]
    (HERE / "SUBJECT_REGISTER.md").write_text("\n".join(out), encoding="utf-8")
    print(f"Validated {len(subjects)} subjects across {len(rows)} halls; indexed {len(entry_index)} taxonomy entries; {len(review)} review items.")


if __name__ == "__main__":
    main()
