"""Retain the supplied evidence once; render a portable literary handoff."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import zipfile

import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
REFERENCE = "doc/book/iterations/2026-10-15-composition-consequences/editions/ca4601b6324d2f76cd92/reference.md"
PATHS = [
    "commons/maps/Random_Definition/final.md",
    "commons/maps/Random_Definition/map_data.json",
    "commons/maps/Random_Definition/writing_wall.json",
    "commons/artifacts/random_touch/random_touch.gd",
    "commons/artifacts/random_touch/motion_record.gd",
    "commons/artifacts/random_touch/hand_follower.gd",
    "commons/artifacts/random_touch/ink_wall.gd",
    "commons/artifacts/randomness_space/hall_seed.gd",
    "algorithms/randomness/seed_replay/opening_seed.json",
    "algorithms/randomness/seed_replay/movement_seed.gd",
    "algorithms/randomness/seed_replay/movement_sampler.gd",
    "algorithms/randomness/seed_replay/seed_replay_demo.gd",
    "algorithms/randomness/seed_replay/editor_parts.gd",
    "algorithms/randomness/randomnumbergeneration/scripts/random_number_book_page_1995.gd",
    "commons/artifacts/geiger_counter/geiger_counter.gd",
    "commons/artifacts/geiger_counter/geiger_model.gd",
    "commons/artifacts/random_return/random_return.gd",
    "doc/book/iterations/2026-10-15-random-abacus/README.md",
    "doc/book/iterations/2026-10-15-random-abacus/hand-test.log",
    "doc/book/iterations/2026-10-15-random-abacus/hall-seed-test.log",
    "commons/maps/CA_ExpandingSpace/final.md",
    "commons/maps/CA_ExpandingSpace/map_data.json",
    "algorithms/cellularautomata/living_architecture/decaying_bridge.gd",
    "algorithms/cellularautomata/living_architecture/proximity_study.gd",
    REFERENCE,
]
IMAGES = {
    "bridge.png": "commons/maps/CA_ExpandingSpace/images/presence-depleted.png",
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def retained(path):
    return (HERE / "sources" / path).read_text(encoding="utf-8-sig")


def between(text, start, end):
    return text.split(start, 1)[1].split(end, 1)[0].strip()


def main():
    evidence = []
    changed = []
    for path in PATHS:
        target = HERE / "sources" / path
        if not target.exists():
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / path, target)
        digest = sha(target.read_bytes())
        evidence.append({"path": path, "snapshot": target.relative_to(HERE).as_posix(), "sha256": digest})
        if sha((ROOT / path).read_bytes()) != digest:
            changed.append(path)
    for name, path in IMAGES.items():
        target = HERE / name
        if not target.exists():
            shutil.copyfile(ROOT / path, target)
        evidence.append({"path": path, "snapshot": name, "sha256": sha(target.read_bytes())})
        if sha((ROOT / path).read_bytes()) != sha(target.read_bytes()):
            changed.append(path)

    abacus = between(retained(PATHS[0]), "<!-- @random_touch -->", "<!-- @random_number_book_page_1955 -->")
    geiger_original = between(retained(REFERENCE), "<!-- @geiger_counter -->", "<!-- @seed_replay_demo/movement_sampler -->")
    # Excerpt alone remains readable; the omitted note markers point to the
    # complete retained reference, not to new evidence invented in this packet.
    geiger = re.sub(r"\[\^[^\]]+\]", "", geiger_original)
    bridge = between(retained("commons/maps/CA_ExpandingSpace/final.md"), "<!-- @decaying_bridge -->", "![")
    calibration = f"""# Three encounters to calibrate from

These are existing passages, retained for selection and refinement. They are not new rewrites and not yet three approved exemplars. Palle selected cellular automata as the third area; the exact bridge passage is the researcher's nomination.

## A · Embodied encounter: five-row abacus

Source: Random Definition's final as captured for this packet, including its new recording wall. Its earlier opening established the local “we” reference; this revised encounter still needs a reading. This excerpt concerns the visible hand, not bodily travel.

{abacus}

## B · Epistemological encounter: Geiger

Source: the reference chapter in retained edition `ca4601b6324d2f76cd92`. Palle's earlier response to the Geiger direction was “The balance is closer”; that is local feedback, not adoption of this whole chapter or selection as a calibration exemplar. Footnote markers alone are omitted here; the complete source is retained. The machine synthesizes sound from calculated event times.

{geiger}

## C · Cellular automata: The surface includes you

Source: CA_ExpandingSpace's current final, opening excerpt. A continuously valued cellular field controls tile appearance and support. This is not Conway's binary Game of Life. The installed rule reads proximity to a body's origin, not pressure or weight. The passage's direct address remains visible for judgement; no voice change has been adopted.

{bridge}

![Retained view of the bridge and the corresponding marked cell on the frieze.](bridge.png)

## Selection record

All three exact passages await selection/refinement. For each, identify the sentence or action worth keeping, where its attention weakens, and what kind of writing becomes possible there. They may demonstrate different strengths. No requirement follows that every chapter use all three operations or sound alike.
"""
    (HERE / "calibration.md").write_text(calibration, encoding="utf-8")
    brief = (HERE / "writer-brief.md").read_text(encoding="utf-8")
    dossier = (HERE / "dossier.md").read_text(encoding="utf-8")
    packet = brief + "\n\n---\n\n" + calibration + "\n\n---\n\n" + dossier
    (HERE / "writer-packet.md").write_text(packet, encoding="utf-8")

    bodies = []
    for section, text in [("brief", brief), ("calibration", calibration), ("evidence", dossier)]:
        bodies.append(f'<section id="{section}">' + markdown.markdown(text, extensions=["tables", "fenced_code"]) + '</section>')
    html = """<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Evidence for an independent writer · Ada Research</title>
<style>
:root{color-scheme:light}*{box-sizing:border-box}body{margin:0;background:#f5f2e9;color:#203733;font-family:Georgia,serif;font-size:19px;line-height:1.7}
nav{position:sticky;top:0;z-index:1;background:#f5f2e9f5;border-bottom:1px solid #ccd4c6;padding:12px 22px;display:flex;flex-wrap:wrap;gap:8px 25px;font:15px/1.6 system-ui}
a{color:#1d665a;text-underline-offset:4px}main{max-width:78ch;margin:36px auto 100px;padding:0 26px}section{scroll-margin-top:75px;margin:0 0 70px;padding-top:12px}
h1{font-size:2.05rem;line-height:1.2;font-weight:500;margin:20px 0 24px}h2{font:600 18px/1.4 system-ui;margin:40px 0 16px;color:#31564a}p{margin:0 0 1.2em}
blockquote{border-left:3px solid #b8aa77;margin:24px 0;padding:4px 22px;background:#eeeadc}blockquote p:last-child{margin-bottom:0}img{max-width:100%;max-height:650px;object-fit:contain;display:block;margin:26px auto}
code{font-size:.8em;overflow-wrap:anywhere}strong{font-weight:600}section+section{border-top:1px solid #b8c4b5}a:focus{outline:3px solid #bc8d35;outline-offset:5px}
@media(max-width:650px){body{font-size:18px}main{margin-top:15px;padding:0 18px}h1{font-size:1.8rem}nav{gap:6px 14px}}
@media print{nav{display:none}section{page-break-before:always}section:first-child{page-break-before:auto}body{background:white;font-size:12pt}main{margin:0;max-width:none}}
</style>
<nav aria-label="Packet sections"><a href="#brief">Writer brief</a><a href="#calibration">Three candidates</a><a href="#evidence">Encounter evidence</a><a href="writer-packet.zip">Download packet</a></nav>
<main>""" + "\n".join(bodies) + "</main></html>"
    (HERE / "index.html").write_text(html, encoding="utf-8")
    payload = ["writer-brief.md", "calibration.md", "dossier.md", "writer-packet.md", "index.html", *IMAGES]
    manifest = {
        "schema": "ada-independent-writer-packet/1",
        "date": "2026-10-15",
        "map": "Random_Definition",
        "status": "prepared_calibration_selection_pending",
        "third_area_selected_by_palle": "cellular_automata",
        "calibration_accepted": [],
        "sources": evidence,
        "changed_live_sources": changed,
        "excerpts": [
            {"id": "abacus", "source": PATHS[0], "sha256": sha(abacus.encode()), "transformation": "artifact-marker boundaries only"},
            {"id": "geiger", "source": REFERENCE, "sha256": sha(geiger.encode()), "transformation": "artifact-marker boundaries; footnote markers omitted"},
            {"id": "cellular-automata", "source": "commons/maps/CA_ExpandingSpace/final.md", "sha256": sha(bridge.encode()), "transformation": "from artifact marker to first image"},
        ],
        "writer_payload": [{"path": name, "sha256": sha((HERE / name).read_bytes())} for name in payload],
    }
    (HERE / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    # No interpretation plans, review answers or whole repository go to the writer.
    with zipfile.ZipFile(HERE / "writer-packet.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for name in payload:
            archive.write(HERE / name, name)
    print(json.dumps({"sources": len(evidence), "excerpt_words": [len(t.split()) for t in [abacus, geiger, bridge]], "packet_files": len(payload), "changed_sources": changed}))


if __name__ == "__main__":
    main()
