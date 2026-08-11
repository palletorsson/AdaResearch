#!/usr/bin/env python3
"""build_dark_spot_dna.py — curate the DNA sweep into the dark spot's own gallery.

WHAT THIS IS. /the-dark-spot handed the grant and the as-built project to seven AI critics
and six of them walked to the same nerve: the harmony meter is, on the project's own terms,
a straightening / anti-entropy / taxonomy-enforcing machine. The grant swears fealty to
difference; the flagship tool optimises for alignment.

This gallery answers that from an unexpected direction: NOT with an argument, but with the
project's own set dressing. The lab props are stencilled — CARE, SCRAP, WORKS, PACKED, MASC,
FEM, DO NOT HANDLE, THIS WAY UP, AUTHORISED, PERSONS ONLY — and read in the critics' light
those words stop being flavour and start being a confession. A maintenance crate that says
CARE is the straightening machine naming itself in the vocabulary of upkeep. A bias
visualiser that stencils MASC and FEM prints the binary it exists to critique. A catalyst
declared "felt before it is seen, no numbers on screen ever" stands under glass, labelled,
marked READY, with DO NOT HANDLE on the rim.

NOTHING HERE IS INVENTED. Every word was already stencilled on a shipped prop by somebody
building furniture, long before the critics were spun up; this file only pairs each one with
the critique it accidentally answers. That is the honest form of the exercise, and it keeps
the dark spot page's own first honesty flag — we loaded the dice once already, so the
evidence here had better be found rather than authored.

THE LAST TILE IS WITHHELD ON PURPOSE. grey_point is the dark spot's answer artifact and its
@identity ends: "needs ... NOT to be captured, swept, harmonised, promoted, or measured", and
"the moment it BITES a still it has been captured, measured, reconciled — and it is no longer
becoming". So it is not swept. It appears as an absence with its own words, because a gallery
that measured it would have proved the critics right on the page meant to answer them.

Usage:
  python tools/build_dna_gallery.py --slug=dark-spot-dna --tokens=<the six props>
  python tools/build_dark_spot_dna.py            # then curate what that produced
"""
from __future__ import annotations
import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ENC = REPO.parent / "ada_encyclopedia" / "public"
GALLERY = ENC / "dark-spot-dna"

# The stage background capture_config_sweep paints (0.055, 0.055, 0.070 linear).
WITHHELD_RGB = (14, 14, 18)

# id-suffix -> (stencilled word, critic persona, lineage, the line it answers, the reading)
CURATION: dict[str, tuple] = {
    "station_crates__upkeep-service": (
        "CARE",
        "Queer phenomenologist", "Ahmed / Munoz / Getsy",
        "Orientation is a question of which bodies a space is already shaped for. A path becomes a path by being walked; repetition straightens it.",
        "The maintenance crate of a working bay, stencilled with the word the critique uses for the harmony meter. Care is what straightening calls itself when it is being kind. Nobody chose this as an argument — it is a prop, dropped into spare corner cells by the composer, and it has been saying it in every room it stands in.",
    ),
    "station_crates__upkeep-scrap": (
        "SCRAP",
        "Media-archaeologist of the poor image", "Steyerl / the demoscene / glitch",
        "Every gotcha in your memory is a defeated glitch, archived as a triumph.",
        "The same crates at the end of their working life, stencilled SCRAP in oxide red. The project keeps its defeated things as set dressing — which is either the poor image honoured, or the glitch domesticated into decor. The prop cannot tell you which, and that is the point.",
    ),
    "station_crates__upkeep-works": (
        "WORKS",
        "Art historian of Klee's Bauhaus pedagogy", "Klee / abstraction / surrealism",
        "Klee's Pedagogisches Skizzenbuch is not a catalogue of forms; it is a grammar of Formung, forming.",
        "WORKS is the one upkeep value that means unfinished — a bay caught mid-operation rather than tidied. It is the only moment of this axis Klee would recognise, and it is one of four.",
    ),
    "station_pillar__upkeep-store": (
        "STORE",
        "Complexity scientist", "Shannon / Crutchfield / Prigogine",
        "Shannon's H measures the average surprise of a source; Boltzmann's S counts microstates of a macrostate; diversity as social good is a normative claim. They share a word, not a value, not units, not a sign convention.",
        "station_pillar is station_crates' kin — the structure and the stuff sharing one upkeep vocabulary, telling the same time. Two artifacts, one word, four states: a taxonomy of maintenance applied to a building. Stored is the lowest-entropy thing a bay can be.",
    ),
    "catalyst_pickup__offer-vitrine": (
        "DO NOT HANDLE",
        "Walking-sim & procedural-rhetoric critic", "Fez / Miegakure / procedural rhetoric",
        "In Miegakure the fourth dimension isn't taught to you; you rotate into it with your own hands, and the rotation is the argument.",
        "THE HINGE OF THIS GALLERY. The catalyst is the project's own figure for capability-as-relation — 'felt before it is seen', 'no numbers on screen, ever'. Here it is under glass on a plinth, titled RANDOMNESS CATALYST, its readout saying READY, and DO NOT HANDLE stencilled on the rim. The mechanic that was supposed to BE the argument, displayed as an exhibit about itself.",
    ),
    "catalyst_pickup__offer-shrine": (
        "READY",
        "Reflexive critic of the critique-machine", "Fraser / Ahmed / Han",
        "I am the problem I was hired to name. The fact that I can produce a competent objection in nine seconds is the first thing you should distrust about it.",
        "The same catalyst raised on a shrine. Institutional critique has a well-known ending: the gesture against the museum becomes the museum's best-lit object. A pickup you may not pick up, lit from below.",
    ),
    "bias_visualizer__disclosure-tally__analogy_type-0": (
        "MASC / FEM",
        "Critical-AI & infrastructure scholar", "Crawford / Noble / Zuboff / Buolamwini",
        "Take your own citations seriously and the project audits itself.",
        "The artifact that exists to visualise algorithmic bias stencils a hard binary on its own face. Buolamwini's Gender Shades is precisely about systems that sort faces into MASC and FEM and are wrong about who counts; the teaching prop reproduces the schema in vinyl. Cite Buolamwini, print the binary.",
    ),
    "bias_visualizer__disclosure-origin__analogy_type-0": (
        "ORIGIN",
        "Critical-AI & infrastructure scholar", "Crawford / Noble / Zuboff / Buolamwini",
        "You invoke Crawford's Atlas of AI — whose whole argument is that AI is never immaterial, but lithium, water, GPU foundries, ghost labour, and planetary cost.",
        "The most disclosing rung of the bias visualiser's own ladder: origin, where the machine shows where its numbers came from. The axis is called disclosure, and four of its five rungs disclose less than this one. Somebody built a dial for how much the system admits.",
    ),
    "tech_crate__consignment-seal": (
        "SEALED",
        "Media-archaeologist of the poor image", "Steyerl / the demoscene / glitch",
        "Your grant stakes the whole ontology on a single line: more entropy, more noise, more difference.",
        "A crate with both faces X-sealed and its clips shut. Elsewhere on this same prop the stencil reads THIS WAY UP — Ahmed's orientation printed on a box as a handling instruction — and OPENED, once somebody has. The consignment axis is a taxonomy of how closed a container is.",
    ),
    "tech_crate__consignment-manifest": (
        "THIS WAY UP",
        "Queer phenomenologist", "Ahmed / Munoz / Getsy",
        "A path becomes a path by being walked; repetition straightens it.",
        "The instruction that makes a body a body with a correct orientation. It is the most ordinary sentence in logistics and, read from Ahmed, it is the whole argument: not a description of the crate but an order about which way up it is permitted to be.",
    ),
    "pattern_loom__colophon-catalogue": (
        "PACKED",
        "Art historian of Klee's Bauhaus pedagogy", "Klee / abstraction / surrealism",
        "Not a catalogue of forms; it is a grammar of Formung, forming.",
        "The loom's colophon axis set to catalogue: the output filed, indexed, stamped PACKED. Klee's objection made literal by a prop — the difference between a grammar that forms and a catalogue that stores, and this artifact has a knob for it.",
    ),
    "pattern_loom__colophon-none": (
        "(no colophon)",
        "Art historian of Klee's Bauhaus pedagogy", "Klee / abstraction / surrealism",
        "Not a catalogue of forms; it is a grammar of Formung, forming.",
        "The same loom with the colophon withheld: cloth and no credit, pattern and no index. The only value on this axis that leaves the work unregistered — and it is available, and almost nothing uses it.",
    ),
}

WITHHELD = {
    "id": "grey_point__withheld",
    "prop": "grey_point",
    "index": 999,
    "label": "grey_point - withheld",
    "subtitle": "the answer artifact, not swept",
    "notes": (
        "THE ONLY TILE HERE THAT IS NOT A CAPTURE. grey_point is the dark spot's answer — "
        "Klee's non-dimensional origin 'between becoming and passing', the dark_sphere witness "
        "at the instant it becomes catalyst, 'the anti-harmony-meter: where the meter measures "
        "reconciliation (and reconciliation is death, low entropy), the catalyst keeps "
        "difference hot'. Its own @identity ends: needs a semi-transparent dark orb, a halo, one "
        "outward pulse, AND NOT to be captured, swept, harmonised, promoted, or measured. Its "
        "critical_parameter is 'none - but as deferral, not pure refusal', and it says plainly "
        "that the moment it bites a still it has been captured, measured, reconciled, and is no "
        "longer becoming. So it was not swept for this gallery. Every other tile is a prop whose "
        "stencil confesses something; this is the one that declined to be evidence, and the "
        "frame is what declining looks like. Measuring it here would have proved the critics "
        "right on the page built to answer them."
    ),
    "image": "/dark-spot-dna/grey_point__withheld.png",
    "dna": {},
}


def make_withheld_frame() -> None:
    try:
        from PIL import Image
    except ImportError:
        print("  (Pillow missing - withheld frame not written)")
        return
    out = GALLERY / "grey_point__withheld.png"
    Image.new("RGB", (760, 760), WITHHELD_RGB).save(out)
    print(f"  withheld frame -> {out.name}")


def main() -> int:
    mf = GALLERY / "manifest.json"
    if not mf.exists():
        print(f"no manifest at {mf} - run build_dna_gallery.py --slug=dark-spot-dna first")
        return 1
    man = json.loads(mf.read_text(encoding="utf-8"))
    kept: list[dict] = []
    missing: list[str] = []

    for key, (word, persona, lineage, line, reading) in CURATION.items():
        src = next((e for e in man.get("entries", []) if str(e.get("id")) == key), None)
        if src is None:
            missing.append(key)
            continue
        e = dict(src)
        e["label"] = word
        e["subtitle"] = f"{src.get('prop','?')} - {src.get('label','')}"
        e["notes"] = (
            f"{word}   //   {persona} ({lineage}) says: “{line}”   //   {reading}"
        )
        e["dark_spot"] = {"word": word, "persona": persona, "lineage": lineage,
                          "critique": line, "reading": reading}
        kept.append(e)

    make_withheld_frame()
    kept.append(WITHHELD)

    out = {
        "version": 1,
        "description": (
            "The dark spot, read off the project's own set dressing. Every word here was "
            "stencilled on a shipped prop by somebody building furniture, long before the "
            "critics were spun up. Nothing is invented; each tile pairs a found word with the "
            "critique it accidentally answers. The last tile is withheld at the artifact's "
            "own request."
        ),
        "capture_size": man.get("capture_size", [760, 760]),
        "entries": kept,
    }
    mf.write_text(json.dumps(out, indent=1, ensure_ascii=False), encoding="utf-8")
    print(f"dark-spot-dna: curated {len(kept)} tiles ({len(kept)-1} found + 1 withheld)")
    if missing:
        print("  MISSING (swept ids not found, so not curated):")
        for m in missing:
            print(f"    {m}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
