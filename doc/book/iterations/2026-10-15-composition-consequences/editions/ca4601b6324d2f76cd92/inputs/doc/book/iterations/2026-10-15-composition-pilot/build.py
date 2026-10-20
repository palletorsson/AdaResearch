"""Freeze and replay a small, evidence-bound composition experiment."""
from pathlib import Path
import argparse
import hashlib
import html
import json
import platform
import re
from collections import Counter

import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
COMP = "commons/maps/Random_Definition/composition"
PILOT = "doc/book/iterations/2026-10-15-composition-pilot"
MARKER = re.compile(r"<!-- @([^\s]+) -->")


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode("utf-8")


def sha(data):
    return hashlib.sha256(data).hexdigest()


def safe(root, relative):
    target = (root / relative).resolve()
    target.relative_to(root.resolve())
    return target


def gather():
    files = {}

    def take(name):
        files[name] = safe(ROOT, name).read_bytes()
        return files[name].decode("utf-8-sig")

    composition = json.loads(take(COMP + "/map.json"))
    take(COMP + "/relationships.json")
    for item in composition["artifacts"]:
        artifact = json.loads(take(COMP + "/" + item))
        take(artifact["scene"])
        take(artifact["implementation_status"]["prior_technical_record"])
        for evidence in artifact["evidence"]:
            take(evidence["path"])
    for name in [composition["baseline"], composition["canonical"], composition["wall"],
                 "commons/maps/Random_Definition/map_data.json",
                 "commons/artifacts/randomness_space/hall_seed.gd",
                 "algorithms/randomness/seed_replay/opening_seed.json",
                 "doc/book/course/writing-patterns/AUTHOR_STRATEGIES.md",
                 PILOT + "/instructions.md", PILOT + "/supplied-proposal.txt", PILOT + "/build.py"]:
        take(name)
    for variant in composition["pilot"]["candidate_ids"]:
        take(PILOT + "/candidates/" + variant + ".md")
    files["environment.json"] = encoded({"python": platform.python_version(), "markdown": markdown.__version__, "assembly": "saved authored candidates; no model generation"})
    return files


def load(files, name):
    return json.loads(files[name].decode("utf-8-sig"))


def text(files, name):
    return files[name].decode("utf-8-sig").replace("\r\n", "\n")


def validate(files):
    comp = load(files, COMP + "/map.json")
    assert comp["schema"] == "ada-literary-composition/1"
    artifacts = [load(files, COMP + "/" + item) for item in comp["artifacts"]]
    ids = [a["id"] for a in artifacts]
    assert len(ids) == len(set(ids)) and ids == comp["order"], "Artifact order or IDs do not agree."
    for a in artifacts:
        assert a["schema"] == "ada-literary-artifact/1"
        assert a["implementation_status"]["status"] == "implemented_source_checked"
        assert a["literary"]["status"] == "proposed"
        for field in ["primary", "counterpoint", "refusal"]:
            assert a["literary"][field], f"Missing {field} on {a['id']}"
        assert a["scene"] in files
        for e in a["evidence"]:
            assert e["kind"] in ["implemented", "visible"]
            assert e["locator"] in text(files, e["path"]), f"Evidence locator missing: {e}"
    graph = load(files, COMP + "/relationships.json")
    assert graph["map"] == comp["map"]
    assert len({e["id"] for e in graph["edges"]}) == len(graph["edges"])
    for e in graph["edges"]:
        assert e["from"] in ids and e["to"] in ids, "Unknown relationship endpoint."
        if e["data_transfer"]:
            assert e.get("evidence") in files, "Data transfer needs retained implementation evidence."
    wall = load(files, comp["wall"])
    tagged = {m["id"] for m in wall["magnets"] if "final" in m.get("tags", [])}
    assert [i for i in wall["order"] if i in tagged] == ids, "Room/Final order changed. Prepare a new reading plan before assembling."
    baseline = text(files, comp["baseline"])
    assert MARKER.findall(baseline) == ids, "Baseline and composition order differ."
    assert MARKER.findall(text(files, comp["canonical"])) == ids, "Canonical order differs."
    assert baseline.count("All 96 detection times") == 1
    for variant in comp["pilot"]["candidate_ids"]:
        snippet = text(files, PILOT + "/candidates/" + variant + ".md")
        assert snippet.strip() and "<!-- @" not in snippet and "[^" not in snippet
        assert "435" in snippet and "RESTART" in snippet
    return comp, artifacts, graph, baseline


def sections(body):
    matches = list(MARKER.finditer(body))
    return {m[1]: body[m.end():(matches[i + 1].start() if i + 1 < len(matches) else body.index("<!-- @ -->"))].strip()
            for i, m in enumerate(matches)}


def word_count(body):
    body = re.split(r"^\[\^[^]]+\]:", body, maxsplit=1, flags=re.M)[0]
    body = re.sub(r"<!--[\s\S]*?-->|^#.*$", "", body, flags=re.M)
    body = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", body)
    body = re.sub(r"\[\^[^]]+\]", "", body)
    return len([w for w in body.split() if w != ">"])


def audit(body, artifacts, variant):
    notices = []
    for id, block in sections(body).items():
        paragraphs = [p.strip() for p in block.split("\n\n") if p.strip() and not p.startswith((">", "*Saved"))]
        starts = Counter(re.findall(r"^([A-Za-z]+)", p)[0] for p in paragraphs if re.match(r"[A-Za-z]+", p))
        for word, count in starts.items():
            if count >= 4:
                notices.append({"artifact": id, "kind": "paragraph_opening", "detail": f"{count} paragraphs begin with {word!r}. Inspect the rhythm; recurrence may be deliberate."})
        if paragraphs and paragraphs[-1].endswith("?"):
            notices.append({"artifact": id, "kind": "question_ending", "detail": "This encounter ends with a question. Check its function beside neighbouring endings."})
        sentences = Counter(s.strip() for s in re.split(r"(?<=[.!?])\s+", " ".join(paragraphs)) if len(s.split()) >= 5)
        for sentence, count in sentences.items():
            if count > 1:
                notices.append({"artifact": id, "kind": "exact_recurrence", "detail": f"Repeated {count} times: {sentence}"})
    ops = [a["literary"]["primary"]["id"] for a in artifacts]
    if variant != "reference":
        ops[2] = "observe" if variant == "patient" else "investigate"
    for i in range(2, len(ops)):
        if len(set(ops[i-2:i+1])) == 1:
            notices.append({"artifact": artifacts[i]["id"], "kind": "operation_run", "detail": f"Three consecutive declared operations are {ops[i]}. Deliberate repetition is allowed."})
    return {"mode": "advisory", "quality_score": None, "notices": notices,
            "manual_checks": ["Does each opening inventory the space again?", "Does interpretation immediately follow every action?", "Does an aphorism settle what could remain an encounter?", "What work is deliberate repetition doing here?"]}


CSS = """
:root{color-scheme:light}*{box-sizing:border-box}body{margin:0;background:#f8f5ed;color:#24342e;font:20px/1.7 Georgia,serif}header{padding:20px 4vw;border-bottom:1px solid #d4d9ce;font:15px/1.5 system-ui}nav{display:flex;gap:12px 24px;flex-wrap:wrap}a{color:#266557;text-underline-offset:3px}a:focus-visible,summary:focus-visible{outline:3px solid #266557;outline-offset:4px}main{padding:28px 4vw 80px;max-width:1600px;margin:auto}article{max-width:68ch;margin:auto}h1{font-size:34px;font-weight:normal;line-height:1.2}h2{font-size:25px}p{margin:0 0 1.2em}.columns{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:36px}.columns article{font-size:17px;margin:0;min-width:0}.columns h1{font-size:24px}.label{font:14px/1.5 system-ui;color:#45644f;margin-bottom:20px}blockquote{margin:22px 0;padding:16px 20px;background:#eaf0e5;border-left:3px solid #789783}blockquote p:last-child{margin:0}details{font:15px/1.6 system-ui;margin-top:30px;border-top:1px solid #cbd4c6;padding-top:14px}summary{cursor:pointer}.stop{display:block;height:18px;scroll-margin-top:20px}li{margin-bottom:14px}@media(max-width:1000px){.columns{display:block}.columns article{margin:0 auto 55px;font-size:19px;max-width:68ch}}@media print{header{display:none}body{font-size:11pt}.columns article{font-size:9pt}}
"""


def render(body, prefix):
    body = body.replace("../2026-10-15-seed-435-middle/README.md", "/book-review/doc/book/iterations/2026-10-15-seed-435-middle/README.md")
    body = body.replace("(opening-receipt.json)", "(inputs/algorithms/randomness/seed_replay/opening_seed.json)")
    body = MARKER.sub(lambda m: f'<span class="stop" id="{prefix}-{m[1].replace("/", "-")}"></span>', body).replace("<!-- @ -->", "")
    result = markdown.markdown(body, extensions=["footnotes"])
    result = re.sub(r'(id|href)="(#?)(fn[^\"]*)"', lambda m: f'{m[1]}="{m[2]}{prefix}-{m[3]}"', result)
    where = result.find('<div class="footnote">')
    if where >= 0:
        result = result[:where] + '<details><summary>Sources and technical distinctions</summary>' + result[where:] + '</details>'
    return result


def page(title, body, columns=False):
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{CSS}</style></head><body><header><p>Composition pilot · proposals, not adopted editions</p><nav><a href="reference.html">Complete reference</a><a href="patient.html">Complete patient version</a><a href="inquiry.html">Complete inquiry version</a><a href="compare.html">Compare complete chapters</a><a href="middle.html">Compare Geiger passages</a><a href="manifest.json">Edition record</a></nav></header><main class="{"columns" if columns else "reading"}">{body}</main></body></html>'


def assemble(files):
    comp, artifacts, graph, baseline = validate(files)
    start = baseline.index("<!-- @geiger_counter -->") + len("<!-- @geiger_counter -->")
    end = baseline.index("All 96 detection times", start)
    texts = {"reference": baseline}
    for variant in comp["pilot"]["candidate_ids"]:
        texts[variant] = baseline[:start] + "\n\n" + text(files, PILOT + "/candidates/" + variant + ".md").strip() + "\n\n" + baseline[end:]
        assert texts[variant][texts[variant].index("All 96 detection times"):] == baseline[end:]
        assert all(sections(texts[variant])[id] == block for id, block in sections(baseline).items() if id != "geiger_counter")
    counts = {k: word_count(v) for k, v in texts.items()}
    assert all(600 <= c <= 1500 for c in counts.values())
    audits = {k: audit(v, artifacts, k) for k, v in texts.items()}
    labels = {"reference": "Reference · existing witness trial", "patient": "Candidate · patient observation", "inquiry": "Candidate · limits of observation"}
    outputs = {"counts.json": encoded(counts), "audit.json": encoded(audits)}
    for variant, body in texts.items():
        # Rebase only source-note links for the retained Markdown's deeper folder.
        # Narrative passages and their order remain byte-for-byte comparable.
        saved_markdown = body.replace("(../2026-10-15-seed-435-middle/README.md)", "(../../../2026-10-15-seed-435-middle/README.md)")
        saved_markdown = saved_markdown.replace("(opening-receipt.json)", "(inputs/algorithms/randomness/seed_replay/opening_seed.json)")
        outputs[variant + ".md"] = saved_markdown.encode("utf-8")
        article = f'<article><div class="label">{labels[variant]} · {counts[variant]} words</div>{render(body, variant)}</article>'
        outputs[variant + ".html"] = page(labels[variant], article).encode("utf-8")
    for name, middle in [("compare.html", False), ("middle.html", True)]:
        articles = []
        for variant, body in texts.items():
            passage = sections(body)["geiger_counter"] if middle else body
            if middle:
                passage += "\n\n" + body[body.index("[^record]:"):]
            articles.append(f'<article><div class="label">{labels[variant]} · full chapter {counts[variant]} words</div>{render(passage, variant)}</article>')
        outputs[name] = page("Three readings of the same encounter", "".join(articles), True).encode("utf-8")
    return outputs, comp, artifacts, graph, counts, audits


def verify(folder, manifest):
    for group, prefix in [("inputs", "inputs/"), ("outputs", "")]:
        for name, digest in manifest[group].items():
            assert sha(safe(folder, prefix + name).read_bytes()) == digest, f"Retained file changed: {name}"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--replay", type=Path)
    args = parser.parse_args()
    if args.replay:
        folder = args.replay.resolve()
        manifest = json.loads((folder / "manifest.json").read_text(encoding="utf-8"))
        verify(folder, manifest)
        files = {name: safe(folder / "inputs", name).read_bytes() for name in manifest["inputs"]}
        outputs, *_ = assemble(files)
        assert {n: sha(b) for n, b in outputs.items()} == manifest["outputs"], "Replay differs from retained outputs. Check the recorded builder and environment."
        print(f"Verified {manifest['edition_id']}: retained inputs and replayed outputs match.")
        return
    files = gather()
    outputs, comp, artifacts, graph, counts, audits = assemble(files)
    hashes = {name: sha(body) for name, body in files.items()}
    edition = sha(encoded(hashes))[:20]
    manifest = {"schema": "ada-composition-edition/1", "edition_id": edition, "status_at_creation": "candidate", "inputs": hashes, "outputs": {n: sha(b) for n, b in outputs.items()}, "environment": load(files, "environment.json"), "changed_passage": "Geiger opening only; other four passages and shared Geiger continuation unchanged"}
    folder = HERE / "editions" / edition
    if folder.exists():
        retained = json.loads((folder / "manifest.json").read_text(encoding="utf-8"))
        assert retained == manifest, "Existing edition differs; never overwrite it."
        verify(folder, retained)
    else:
        folder.mkdir(parents=True)
        for name, body in files.items():
            target = folder / "inputs" / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(body)
        for name, body in outputs.items():
            (folder / name).write_bytes(body)
        (folder / "manifest.json").write_bytes(encoded(manifest))
    base_url = "/book-review/" + PILOT + "/editions/" + edition + "/"
    data = {"schema": "ada-composition-pilot/1", "map": comp["map"], "title": comp["title"], "composition": comp, "artifacts": artifacts, "relationships": graph["edges"], "edition": {"id": edition, "base_url": base_url, "counts": counts, "audit": audits}, "source_hashes": hashes}
    safe(ROOT, COMP + "/pilot.json").write_bytes(encoded(data))
    landing = f'<article><h1>A small composition instrument</h1><p>Five encounters, a relationship graph and two Geiger alternatives. Each candidate retains the complete chapter around it.</p><ul><li><a href="{base_url}compare.html">Compare all three complete chapters</a></li><li><a href="{base_url}middle.html">Compare the Geiger passages</a></li><li><a href="/long-museum/writing-wall?map=Random_Definition&amp;view=literary">Open the Literary view on the writing wall</a></li><li><a href="README.md">Method, evidence and review protocol</a></li><li><a href="review.json">Pending decision record</a></li></ul><p>Reference: {counts["reference"]} words. Patient: {counts["patient"]}. Inquiry: {counts["inquiry"]}. No variant is adopted.</p><p>Frozen input set: <code>{edition}</code>. The 48-value bench remains the first runtime pilot.</p></article>'
    # The landing page has its own navigation; edition navigation belongs inside the edition.
    landing_html = page("Ada composition pilot", landing)
    landing_html = re.sub(r"<nav>.*?</nav>", '<nav><a href="../2026-10-15-situated-voice/strategies.html">Author toolbox</a></nav>', landing_html)
    (HERE / "index.html").write_text(landing_html, encoding="utf-8")
    print(json.dumps({"edition": edition, "counts": counts, "files_retained": len(files), "path": str(folder)}, indent=2))


if __name__ == "__main__":
    main()
