"""Retain three formal interventions and their complete, comparable chapters."""
from pathlib import Path
import argparse
import html
import importlib.util
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PILOT = "doc/book/iterations/2026-10-15-composition-consequences"
PREVIOUS = "doc/book/iterations/2026-10-15-composition-pilot"
COMP = "commons/maps/Random_Definition/composition"
EXPERIMENT = COMP + "/experiments/geiger-consequences.json"
HELPER = PREVIOUS + "/build.py"


def helper(path):
    spec = importlib.util.spec_from_file_location("composition_helpers", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


base = helper(ROOT / HELPER)


def gather():
    files = base.gather()
    experiment = json.loads((ROOT / EXPERIMENT).read_text(encoding="utf-8"))
    names = [EXPERIMENT, PREVIOUS + "/review.json",
             PREVIOUS + "/editions/" + experiment["predecessor_edition"] + "/manifest.json",
             PILOT + "/instructions.md", PILOT + "/supplied-feedback.txt",
             PILOT + "/build.py", PILOT + "/test_experiment.py",
             "doc/book/course/ENCOUNTER_RESEARCH_LOOP.md"]
    names.extend(PILOT + "/candidates/" + c["id"] + ".md" for c in experiment["candidates"])
    for name in names:
        files[name] = base.safe(ROOT, name).read_bytes()
    return files


def validate(files):
    comp, artifacts, graph, reference = base.validate(files)
    experiment = base.load(files, EXPERIMENT)
    assert experiment["schema"] == "ada-writing-orientation-experiment/1"
    assert experiment["status"] == "awaiting_reading"
    predecessor = base.load(files, PREVIOUS + "/editions/" + experiment["predecessor_edition"] + "/manifest.json")
    assert base.sha(files[comp["baseline"]]) == predecessor["inputs"][comp["baseline"]], "Reference drift: this experiment must keep the reviewed baseline."
    previous_review = base.load(files, PREVIOUS + "/review.json")
    assert previous_review["edition_id"] == experiment["predecessor_edition"]
    assert previous_review["selected_variant"] == "reference"
    ids = [c["id"] for c in experiment["candidates"]]
    assert ids == ["repetition", "montage", "recurrence"]
    receipt = reference[reference.index("> Received:"):reference.index("\n\nNo new sample")]
    for c in experiment["candidates"]:
        body = base.text(files, PILOT + "/candidates/" + c["id"] + ".md")
        assert "<!-- @" not in body and not body.startswith("#"), "Candidate must be a passage, not another route."
        assert receipt in body, "Receipt was changed."
        assert all(x in body for x in ["435", "96", "RESTART", "[^record]", "[^receipt]", "[^entropy]"]), "A shared fact or source note is missing."
        assert c["artifact_test"] and c["map_test"]
        assert c["observed_effect"] is None, "An intention cannot be installed as an observed effect."
        assert set(c["test_results"].values()) == {"unassessed"}
    return comp, artifacts, graph, reference, experiment


STYLE = """
main{max-width:1800px}.columns{grid-template-columns:repeat(2,minmax(0,1fr));align-items:start}
.local{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:32px;align-items:start}
.local article{font-size:18px;min-width:0}.intro{max-width:78ch;margin:0 auto 32px}
.reference{max-width:none;margin:0 0 36px;padding:18px 24px;background:#edf0e8}
.reference article{font:19px/1.7 Georgia,serif;margin:24px auto}.method{max-width:78ch;margin:60px auto 0}
.columns article{font-size:20px;max-width:65ch;margin:0 auto 40px}.label{padding-bottom:10px;border-bottom:2px solid #9cb6a0}
@media(max-width:850px){.local{grid-template-columns:1fr}.local article{font-size:20px;max-width:65ch;margin:0 auto 40px}}
@media(max-width:1000px){.columns{display:block}}@media print{.local,.columns{display:block}}
"""


def page(title, body, columns=False):
    links = [("reference.html", "Reference"), ("repetition.html", "Repetition"), ("montage.html", "Montage"),
             ("recurrence.html", "Recurrence"), ("middle.html", "Compare Geiger passages"),
             ("compare.html", "Complete chapters"), ("protocol.html", "Tests and evidence"), ("manifest.json", "Edition record")]
    nav = "".join(f'<a href="{url}">{label}</a>' for url, label in links)
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{base.CSS}{STYLE}</style></head><body><header><p>Writing orientations · new candidates, reading pending</p><nav>{nav}</nav></header><main class="{"columns" if columns else "reading"}">{body}</main></body></html>'


def assemble(files):
    comp, artifacts, graph, reference, experiment = validate(files)
    start = reference.index("<!-- @geiger_counter -->") + len("<!-- @geiger_counter -->")
    end = reference.index("<!-- @seed_replay_demo/movement_sampler -->", start)
    texts = {"reference": reference}
    for candidate in experiment["candidates"]:
        id = candidate["id"]
        texts[id] = reference[:start] + "\n\n" + base.text(files, PILOT + "/candidates/" + id + ".md").strip() + "\n\n" + reference[end:]
        assert texts[id][:start] == reference[:start] and texts[id][texts[id].index("<!-- @seed_replay_demo/movement_sampler -->"):] == reference[end:]
        assert base.MARKER.findall(texts[id]) == comp["order"]
    counts = {k: base.word_count(v) for k, v in texts.items()}
    assert all(600 <= count <= 1500 for count in counts.values()), counts
    audits = {id: base.audit(body, artifacts, "reference") for id, body in texts.items()}
    for id, audit in audits.items():
        audit["manual_checks"] = [experiment["tests"]["artifact"], experiment["tests"]["map"],
                                  "Does any gain justify the extra duration, register change or recap?", "Could the reference do this work more economically?"]
        audit["scope"] = "Surface patterns only; candidate effects and map consequences require reading evidence."
    labels = {"reference": "Reference · preferred in the previous supplied reading", **{c["id"]: c["label"] + " · new candidate" for c in experiment["candidates"]}}
    outputs = {"counts.json": base.encoded(counts), "audit.json": base.encoded(audits)}
    for id, body in texts.items():
        saved = body.replace("(../2026-10-15-seed-435-middle/README.md)", "(../../../2026-10-15-seed-435-middle/README.md)")
        saved = saved.replace("(opening-receipt.json)", "(inputs/algorithms/randomness/seed_replay/opening_seed.json)")
        outputs[id + ".md"] = saved.encode("utf-8")
        article = f'<article><div class="label">{labels[id]} · {counts[id]} words</div>{base.render(body, id)}</article>'
        outputs[id + ".html"] = page(labels[id], article).encode("utf-8")
    full = "".join(f'<article><div class="label"><a href="{id}.html">{labels[id]}</a> · {counts[id]} words</div>{base.render(body, id)}</article>' for id, body in texts.items())
    outputs["compare.html"] = page("Four complete readings", full, True).encode("utf-8")
    notes = reference[reference.index("[^record]:"):]
    middle = '<div class="intro"><h1>Three changes to one encounter</h1><p>The reference is retained below. Read the passages first; predictions and test questions are on a separate page. Each candidate also has a complete chapter.</p></div>'
    middle += f'<details class="reference"><summary>Read the reference · previous preference · {counts["reference"]} words in the complete chapter</summary><article>{base.render(base.sections(reference)["geiger_counter"] + chr(10)*2 + notes, "ref")}</article></details><div class="local">'
    for id, body in texts.items():
        if id == "reference":
            continue
        passage = base.sections(body)["geiger_counter"] + "\n\n" + notes
        middle += f'<article><div class="label">{labels[id]} · <a href="{id}.html">complete chapter, {counts[id]} words</a></div>{base.render(passage, id)}</article>'
    middle += '</div><div class="method"><p><a href="compare.html">Read the complete chapters</a> before judging what changes elsewhere. <a href="protocol.html">Open tests, hypotheses and evidence status</a> after the first reading.</p></div>'
    outputs["middle.html"] = page("Compare Geiger passages", middle).encode("utf-8")
    protocol = '<article><h1>Did the orientation change anything?</h1><p>The previous supplied reading preferred the reference. Patient and inquiry are set aside as replacements; their editions remain available. This is a new experiment, not an adoption decision.</p>'
    protocol += '<h2>Two tests</h2>' + "".join(f'<p><b>{kind.capitalize()}:</b> {html.escape(experiment["tests"][kind])}</p>' for kind in ["artifact", "map"])
    protocol += f'<p>{html.escape(experiment["tests"]["decision_rule"])}</p><h2>Intended effects · recorded before reading</h2>'
    for c in experiment["candidates"]:
        protocol += f'<h3>{c["label"]}</h3><p>{html.escape(c["formal_change"])}</p><p><b>Artifact:</b> {html.escape(c["artifact_test"])}</p><p><b>Map:</b> {html.escape(c["map_test"])}</p><p><b>Risk:</b> {html.escape(c["risk"])}</p><p><b>Observed effect:</b> not collected. Both tests unassessed.</p>'
    protocol += '<h2>What remains fixed</h2><p>' + html.escape(", ".join(experiment["held_fixed"])) + '.</p><p>' + html.escape(" ".join(experiment["confounds"])) + '</p>'
    protocol += '<p>The clauses about clicks describe supported interactions, not a participant transcript. Printed gaps carry no measured durations. The receipt is a document in the book; its labels and montage headings are not room signs. Implementation is tied to the retained source and earlier integration record. The editor previously reported MOVE / KEEP missing from its placed-artifact list, so this is not verification of a complete room walk.</p><p>Record exact response, edition ID, reading order, setting and any editorial inference separately in <a href="../../review.json">the review record</a>. First ask what remains noticeable and which other encounter changed; explain the prediction afterwards. No candidate has been read or adopted on behalf of the user.</p></article>'
    outputs["protocol.html"] = page("Tests and evidence", protocol).encode("utf-8")
    return outputs, comp, artifacts, graph, counts, audits, experiment


def main():
    global base
    parser = argparse.ArgumentParser()
    parser.add_argument("--replay", type=Path)
    args = parser.parse_args()
    if args.replay:
        folder = args.replay.resolve()
        manifest = json.loads((folder / "manifest.json").read_text(encoding="utf-8"))
        base.verify(folder, manifest)
        # Replay uses the retained helper, not a later revision of that module.
        base = helper(folder / "inputs" / HELPER)
        files = {n: base.safe(folder / "inputs", n).read_bytes() for n in manifest["inputs"]}
        outputs, *_ = assemble(files)
        assert {n: base.sha(b) for n, b in outputs.items()} == manifest["outputs"], "Replay differs from retained outputs."
        print(f"Verified {manifest['edition_id']}: retained inputs and replayed outputs match.")
        return
    files = gather()
    outputs, comp, artifacts, graph, counts, audits, experiment = assemble(files)
    hashes = {n: base.sha(b) for n, b in files.items()}
    edition = base.sha(base.encoded(hashes))[:20]
    manifest = {"schema": "ada-composition-edition/1", "edition_id": edition, "experiment_id": experiment["id"],
                "status_at_creation": "candidate", "predecessor_edition": experiment["predecessor_edition"],
                "inputs": hashes, "outputs": {n: base.sha(b) for n, b in outputs.items()}, "environment": base.load(files, "environment.json"),
                "changed_passage": "Complete Geiger passage only; other four encounters, footnotes and room/Final order retained."}
    folder = HERE / "editions" / edition
    if folder.exists():
        retained = json.loads((folder / "manifest.json").read_text(encoding="utf-8"))
        assert retained == manifest, "Never replace an existing edition."
        base.verify(folder, manifest)
    else:
        folder.mkdir(parents=True)
        for n, b in files.items():
            target = base.safe(folder / "inputs", n)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(b)
        for n, b in outputs.items():
            (folder / n).write_bytes(b)
        (folder / "manifest.json").write_bytes(base.encoded(manifest))
    url = "/book-review/" + PILOT + "/editions/" + edition + "/"
    data = {"schema": "ada-composition-pilot/1", "map": comp["map"], "title": comp["title"], "composition": comp,
            "artifacts": artifacts, "relationships": graph["edges"], "experiment": experiment,
            "edition": {"id": edition, "base_url": url, "counts": counts, "audit": audits}, "source_hashes": hashes}
    base.safe(ROOT, COMP + "/pilot.json").write_bytes(base.encoded(data))
    review_path = HERE / "review.json"
    review = json.loads(review_path.read_text(encoding="utf-8"))
    if review["edition_id"] not in [None, edition]:
        print("Review belongs to another edition; left intact. Begin a separate review before collecting responses.")
    elif review["edition_id"] is None:
        review["edition_id"] = edition
        review_path.write_bytes(base.encoded(review))
    landing = '<article><h1>What does a writing orientation change?</h1><p>The reference remains the preferred reading from the first comparison. Three new Geiger passages now test repetition, montage and recurrence.</p><ul>'
    for name, label in [("middle.html", "Compare the three Geiger passages, with the reference available"), ("compare.html", "Read all four complete chapters"), ("protocol.html", "Tests, predictions and evidence status")]:
        landing += f'<li><a href="{url}{name}">{label}</a></li>'
    landing += '<li><a href="/long-museum/writing-wall?map=Random_Definition&amp;view=literary">Writing wall · Literary view</a></li><li><a href="review.json">Reading record</a></li><li><a href="README.md">Method and verification</a></li></ul>'
    landing += '<p>' + " · ".join(f'{id}: {count} words' for id, count in counts.items()) + '.</p><p>All are complete chapters within the 600–1,500-word range. Effects remain unassessed. No new chapter is adopted.</p></article>'
    landing_html = page("Composition consequences", landing)
    landing_html = re.sub(r"<nav>.*?</nav>", '<nav><a href="../2026-10-15-composition-pilot/index.html">Earlier pilot</a><a href="supplied-feedback.txt">Supplied feedback</a></nav>', landing_html)
    (HERE / "index.html").write_text(landing_html, encoding="utf-8")
    print(json.dumps({"edition": edition, "counts": counts, "files_retained": len(files), "base_url": url}, indent=2))


if __name__ == "__main__":
    main()
