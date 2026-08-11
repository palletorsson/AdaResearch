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

# ── SECOND MOVEMENT: the layer of hidden interfaced processes ────────────────
#
# The first movement reads words the props were already stencilled with. This one is
# about something quieter and stranger: ordinary furniture that turns out to be an
# INTERFACE to an administrative process you cannot see. A door is not a door, it is an
# access-control terminal with an occupancy count. A fire extinguisher is not equipment,
# it is the one object in the building whose appearance is written down in law — and its
# axis asks what the building DID with that law. A workbench has a duty roster.
#
# The uncanny here is not that the props are sinister. It is that every one of these
# readouts, tags, permissions and states was authored as set dressing, by somebody making
# a room feel lived-in — and together they describe a facility that is administering
# itself continuously, in a vocabulary nobody sat down and chose.
CURATION_PROPS: dict[str, tuple] = {
    "lab_sliding_door__welcome-plate": (
        "AUTHORISED / PERSONS ONLY",
        "Queer phenomenologist", "Ahmed / Munoz / Getsy",
        "Orientation is a question of which bodies a space is already shaped for.",
        "THE SENTENCE ONLY EXISTS WHEN THE DOOR IS SHUT. AUTHORISED is stencilled on the left leaf and PERSONS ONLY on the right, and the code comment says so outright: 'half of a sentence - the other half is on the right leaf, so the line only completes itself when the door is shut.' The permission is legible only in the state of exclusion; open the door and it says nothing. Beside it the room is named SPECIMEN PREP on a readout, with a second plate reading ACCESS OPEN, OCCUPANCY 6. The comment for that builder: 'the door is not just named, it is administered.'",
    ),
    "lab_sliding_door__welcome-bolt": (
        "AUTHORISED",
        "Critical-AI & infrastructure scholar", "Crawford / Noble / Zuboff / Buolamwini",
        "Take your own citations seriously and the project audits itself.",
        "Half the sentence, alone on a bolted leaf. This is the whole grammar of access in one word and no object to apply it to - authorisation as a property of the door rather than of anybody standing at it.",
    ),
    "fire_extinguisher__support-bracket__statute-notice": (
        "FULL SUBMISSION",
        "Critical-AI & infrastructure scholar", "Crawford / Noble / Zuboff / Buolamwini",
        "AI is never immaterial, but lithium, water, GPU foundries, ghost labour, and planetary cost.",
        "The artifact's own header calls this out: 'this is the one class of object whose appearance is written down in law rather than chosen. So: what did this building do with that law?' At notice the building submits completely - backing board, mandatory sign, projecting flag, painted floor zone. The material infrastructure of compliance, rendered as furniture.",
    ),
    "fire_extinguisher__support-bracket__statute-joinery": (
        "ABSORBED",
        "Art historian of Klee's Bauhaus pedagogy", "Klee / abstraction / surrealism",
        "Not a catalogue of forms; it is a grammar of Formung, forming.",
        "The same law, absorbed. The alarm red is retinted into the building's own cabinetwork and the shout becomes one small engraved plate. The source comment for this branch is the most dark-spot sentence in the corpus: 'the building would rather not say it.'",
    ),
    "fire_extinguisher__support-bracket__statute-lapse": (
        "EXPIRED",
        "Media-archaeologist of the poor image", "Steyerl / the demoscene / glitch",
        "Every gotcha in your memory is a defeated glitch, archived as a triumph.",
        "The promise left to rot: chalked paint, rust, and a small yellow service tag hanging off the neck with a date that has passed. A safety guarantee that is still hanging on the wall and is no longer true - and it is the only value on this axis that admits time has passed at all.",
    ),
    "fire_hose_box__support-cabinet__statute-notice": (
        "FIRE POINT",
        "Complexity scientist", "Shannon / Crutchfield / Prigogine",
        "They share a word, not a value, not units, not a sign convention.",
        "The extinguisher's kin, under the same statute ladder - two artifacts, one legal vocabulary, four states each. FIRE POINT is a designation, not a description: the building declaring a coordinate where the law is satisfied.",
    ),
    "curation_station__bay-apse__duty-watch": (
        "MONITORED",
        "Reflexive critic of the critique-machine", "Fraser / Ahmed / Han",
        "I am the problem I was hired to name.",
        "The workbench where artifacts are prepared has a DUTY ROSTER, and its states are MONITORED, ON SHOW, IN STORE, IN TRANSIT, with OPERATOR, CONTROL, HANDLING and LINK OK printed around them. This is the station that curates the project's own objects, and it is watching them. Nobody designed an argument here; somebody was making a workbench feel real.",
    ),
    "curation_station__bay-apse__duty-show": (
        "ON SHOW",
        "Walking-sim & procedural-rhetoric critic", "Fez / Miegakure / procedural rhetoric",
        "In Miegakure the fourth dimension isn't taught to you; you rotate into it with your own hands, and the rotation is the argument.",
        "The other end of the same roster. An artifact is either watched, shown, stored or in transit - four administrative states, and none of them is 'being used by somebody'. The vocabulary has no word for the thing the project says it is for.",
    ),
    "exit_sign__support-gantry": (
        "EXIT",
        "Queer phenomenologist", "Ahmed / Munoz / Getsy",
        "A path becomes a path by being walked; repetition straightens it.",
        "The most ordinary object in any building, hung from an overhead gantry so it reads from down the corridor. It is a single word that exists to make everybody move the same way, and it is the one piece of signage nobody experiences as an instruction.",
    ),
    "station_wall__upkeep-scrap": (
        "SCRAP",
        "Media-archaeologist of the poor image", "Steyerl / the demoscene / glitch",
        "More entropy, more noise, more difference.",
        "The third artifact on the shared upkeep ladder - crates, pillar, wall. A whole facility conjugated through one four-state grammar of maintenance, down to the walls. At scrap even the architecture is filed as waste, which is a state the building has a word for.",
    ),
    "control_console__mounting-lectern__demo_apparatus-none": (
        "(no apparatus)",
        "Art historian of Klee's Bauhaus pedagogy", "Klee / abstraction / surrealism",
        "Your headline is the boldest thing in the dossier, and it is the thing your build most betrays.",
        "A control console on a lectern with nothing to control. The demo_apparatus axis has four things it can hold and one value where it holds none - the interface surviving the removal of its object, which is the cleanest picture of a hidden process this gallery has: all switch, no referent.",
    ),
}

# ── THIRD MOVEMENT: the Half-Life reversal ───────────────────────────────────
#
# Palle's reading, and it reorganises the whole gallery. In Half-Life there is another
# world, and that world is hostile: Xen is where the other comes from, the other is the
# threat, and the entire architecture of Black Mesa exists to contain it. You arrive with
# a crowbar. The goal is to close the portal.
#
# Ada Research runs that backwards. Here the other world IS THE GOAL — the hidden, the
# dark spots, the anamorphic bodies are the thing the project is for. And the artifact
# that carries it says so in its own truth line: "the catalyst doesn't kill — it
# phase-shifts."
#
# THE REVERSAL IS PROPERLY BUILT, and this is worth saying before the criticism. catalyst_foe
# carries TWO ORTHOGONAL AXES. `body` is what the other IS — cube, mote, serpent, octapod,
# grand — and at octapod it is a pink, soft, many-legged thing with one eye, which is a
# headcrab's morphology drained of menace. `phase` is how the other is MET — foe, wary,
# neutral, curious, friend. The two do not depend on each other: you can meet a cube as a
# friend or an octapod as a foe. In Half-Life morphology and threat are welded together —
# alien shape IS hostility. Here they are decoupled by construction, and the decoupling is
# a declared axis anyone can set from map data.
#
# SO WHERE IS THE DARK SPOT? In the room around it. The facility that hosts this thesis was
# modelled on the facility built to refute it. SPECIMEN appears in 33 source files. SEALED
# in 13, DANGER in 11, HAZARD in 10, CONTAINMENT in 6, CLEARANCE in 5; there is a
# BIOHAZARD CONTAINMENT label and a SECURITY BREACH label in the corpus. The door to the
# room is stencilled AUTHORISED PERSONS ONLY and names the room SPECIMEN PREP. The catalyst
# stands under glass marked DO NOT HANDLE. The furniture still believes the other is a
# threat, because it is quoting an architecture whose whole logic is containment.
#
# And the reversal's own control surface is the tell: progression_driver, whose essence
# line calls it "a VR control surface for the curriculum's hidden state machine", carries a
# panel headed BEFRIEND HAZARD with one button per registered hazard type. The inversion of
# Half-Life exists, it works, and it is administered from a debug console.
CURATION_REVERSAL: dict[str, tuple] = {
    "catalyst_foe__body-octapod__phase-foe": (
        "THE OTHER, AS MET",
        "the Half-Life reversal", "Xen / Black Mesa / the crowbar",
        "In Half-Life the other world is hostile and the architecture exists to contain it. Here the other world is the goal.",
        "A pink, soft, many-legged body with a single eye, in a black void. It is a headcrab's morphology with the menace drained out. This is `phase=foe` — the most hostile rung the artifact has — and the body is still tender. In the game this gallery is quoting, that shape would be coming at you and you would have a crowbar.",
    ),
    "catalyst_foe__body-octapod__phase-friend": (
        "FRIEND",
        "the Half-Life reversal", "Xen / Black Mesa / the crowbar",
        "The catalyst doesn't kill - it phase-shifts.",
        "The same body at the far end of the arc. `phase` runs foe, wary, neutral, curious, friend — five rungs, and the artifact's own truth line is that the catalyst does not kill. The reversal is not a mood here, it is a declared axis with five values that a map author sets from a token.",
    ),
    "catalyst_foe__body-cube__phase-foe": (
        "A WHITE CUBE",
        "Complexity scientist", "Shannon / Crutchfield / Prigogine",
        "They share a word, not a value, not units, not a sign convention.",
        "The same hostile rung on the plainest body: a white cube in a void. `body` and `phase` are ORTHOGONAL — otherness and hostility are decoupled by construction, so the most alien morphology can be met as a friend and the blankest box can be met as a foe. In Half-Life those two are welded: alien shape IS the threat. Decoupling them is the most substantive thing this project does with the genre it borrows from.",
    ),
    "catalyst_foe__body-cube__phase-friend": (
        "THE SAME CUBE, GREEN",
        "Reflexive critic of the critique-machine", "Fraser / Ahmed / Han",
        "I am the problem I was hired to name.",
        "And here is the cost of that decoupling, stated fairly. On the cube body the whole foe-to-friend arc renders as a hue: identical geometry, identical size, identical position, recoloured by its relation to you. Read generously that IS the thesis — friendship is a relation, not a property of the body, so nothing about the body needs to change. Read hard, the other has been admitted as a colour. The gallery cannot decide this for you; both readings survive the picture.",
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

    # The second movement is swept into its own slug, so its images live there. Copy
    # them next to the first movement's so one manifest can carry both.
    import shutil
    extra: list[dict] = []
    for slug, curation in (("dark-spot-props", CURATION_PROPS),
                           ("dark-spot-reversal", CURATION_REVERSAL)):
        d = ENC / slug
        f = d / "manifest.json"
        if not f.exists():
            continue
        extra += json.loads(f.read_text(encoding="utf-8")).get("entries", [])
        for key in curation:
            src_png = d / f"{key}.png"
            if src_png.exists():
                shutil.copy2(src_png, GALLERY / src_png.name)

    combined = list(man.get("entries", [])) + extra
    ordered = (list(CURATION.items()) + list(CURATION_PROPS.items())
               + list(CURATION_REVERSAL.items()))

    for key, (word, persona, lineage, line, reading) in ordered:
        src = next((e for e in combined if str(e.get("id")) == key), None)
        if src is None:
            missing.append(key)
            continue
        e = dict(src)
        e["image"] = f"/dark-spot-dna/{key}.png"
        e["movement"] = ("found words" if key in CURATION
                         else "the interface layer" if key in CURATION_PROPS
                         else "the half-life reversal")
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
