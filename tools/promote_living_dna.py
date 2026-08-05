#!/usr/bin/env python3
"""promote_living_dna.py — every living thing joins the DNA structure.

2671 artifacts can be promoted into `dna.axes` and swept by the DNA loop
(propose variants -> render one PNG each -> the bite critic asks whether the
axis actually changes the picture -> weakest gets improved). The BIOME's living
things were outside that structure entirely: a mushroom, a tree, a grub and a
mycelium web are the most variable objects in the project, and none of them had
a declared axis, a sweep, or a bite verdict.

They were outside for a structural reason: `apply_dna_block.py` DERIVES axes
from an artifact's @export vars, and a biome organism has none — it is not a
scene, it is a GRAMMAR TOKEN (kingdom:algo:role:mods) rendered by a morphology.
So this tool is the bridge: it derives each living thing's axes from the biome
grammar + the morphology's real parameter ladders, and writes the same
`dna` block shape the artifact registry uses, into a registry of its own.

DERIVED, NEVER TRANSCRIBED (the science_screen lesson): every value list below
comes from a real enum in the code — the dispatcher's algo branches, the
grammar's role list, the preset families on disk, the tier ladder — not from
prose. `python tools/check_dna_declarations.py` is the gate.

  python tools/promote_living_dna.py --list        # what will be promoted, and from where
  python tools/promote_living_dna.py --apply       # write commons/artifacts/registry/living.json
"""
import argparse
import datetime
import glob
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY = os.path.join(ROOT, "commons", "artifacts", "registry", "living.json")
FD_DIR = os.path.join(ROOT, "algorithms", "nature_system", "morphology", "fungus_presets")
SF_DIR = os.path.join(ROOT, "algorithms", "nature_system", "morphology", "fungus_presets_softbody")
DISPATCHER = os.path.join(ROOT, "commons", "biome_layers", "biome_paint_dispatcher.gd")
TOKENS = os.path.join(ROOT, "commons", "grid", "BiomeGridTokens.gd")


def _families(preset_dir, prefix):
    """Preset families ON DISK — derived, not typed."""
    fams = set()
    for p in glob.glob(os.path.join(preset_dir, "%s_*.json" % prefix)):
        base = os.path.basename(p)[len(prefix) + 1:-5]
        fams.add(base.rsplit("_", 1)[0])
    return sorted(fams)


def _grammar_roles():
    """ROLES from BiomeGridTokens.gd — the parser is authoritative."""
    if not os.path.isfile(TOKENS):
        return []
    for line in open(TOKENS, encoding="utf-8"):
        if line.strip().startswith("const ROLES"):
            return sorted(v.strip().strip('"') for v in
                          line.split("[", 1)[1].rsplit("]", 1)[0].split(",") if v.strip())
    return []


def _fungus_algos():
    """The fungus algo branches the dispatcher really implements. Derived from
    the actual dispatch lines (deposit.get("algo") == "<x>"), plus `ca` which is
    the fall-through default (no branch tests for it — it is what you get when
    none of the others match), so it must be added explicitly and honestly."""
    algos = {"ca"}   # the documented fall-through in _spawn_fungus
    if os.path.isfile(DISPATCHER):
        src = open(DISPATCHER, encoding="utf-8").read()
        for line in src.splitlines():
            if 'deposit.get("algo"' in line and "==" in line:
                tail = line.split("==", 1)[1]
                if '"' in tail:
                    algos.add(tail.split('"')[1])
    return sorted(a for a in algos if a)


TIERS = ["1", "2", "3", "4", "5"]   # the t= ladder, clamped 1..5 in BiomeGridTokens


def specimens():
    """The living things, each with axes DERIVED from code/disk."""
    roles = _grammar_roles()
    growth_roles = [r for r in roles if r in ("seed", "field", "halo", "mute", "edge")]
    out = {}

    out["living_fungus_fruit"] = {
        "what": "the fruiting mushroom — FungusMorphology cap+stem+gills from a curated preset",
        "token": "fungus:dna:seed",
        "source": "fungus_presets/ families on disk + the t= ladder",
        "axes": {"family": _families(FD_DIR, "fd"), "tier": TIERS},
        "note": "family is the mushroom's SPECIES (five curated bodies, 12 variants each); "
                "tier is how big it stands. The axis the loop should bite on is family.",
    }
    out["living_fungus_pose"] = {
        "what": "the same mushroom under a soft-body pose (static, no physics)",
        "token": "fungus:softbody:seed",
        "source": "fungus_presets_softbody/ families on disk",
        "axes": {"pose": _families(SF_DIR, "sf"), "tier": TIERS},
        "note": "pose is what GRAVITY did to it — droop, bloat, squash, wilt, lean. "
                "A settled thing lies flat and level.",
    }
    out["living_fungus_colony"] = {
        "what": "the fungus colony substrates — computed (CA voxel network) vs grown (mycelium filaments)",
        "token": "fungus:<algo>:seed",
        "source": "dispatcher algo branches",
        "axes": {"algo": _fungus_algos(), "tier": TIERS},
        "note": "the kingdom's argument: the same organism as a CA that is visibly COMPUTED, "
                "filaments visibly GROWN, a fruiting body, a posed body, or one continuous SDF skin.",
    }
    out["living_flora_tree"] = {
        "what": "the tree — L-system tubes vs one continuous SDF trunk",
        "token": "flora:<algo>:seed",
        "source": "dispatcher flora branches",
        "axes": {"algo": ["lsystem", "sdf"], "tier": TIERS},
        "note": "lsystem grows a branching grammar; sdf welds the same skeleton into one skin. "
                "Two ontologies of the same tree.",
    }
    out["living_flora_bloom"] = {
        "what": "the botanical flower — species by tier",
        "token": "flora:scatter:seed",
        "source": "flower presets by intensity (biome_config)",
        "axes": {"tier": TIERS},
        "note": "the tier ladder is really a SPECIES ladder here (bluebell -> orchid -> daisy); "
                "the gallery's flower strip found that. Whether tier should mean bigger or "
                "other is a ruling, not a default.",
    }
    out["living_fauna_body"] = {
        "what": "the creature — a continuous SDF grub, spine+head+legs smooth-unioned",
        "token": "fauna:dna:seed",
        "source": "CreatureSdfMorphology + the t= ladder",
        "axes": {"tier": TIERS},
        "note": "position seeds the DNA, so every cell grows a different individual; "
                "tier is the only declared axis, and the loop should test whether it bites.",
    }
    out["living_ground_role"] = {
        "what": "what a declared cell DOES — the grammar's role vocabulary",
        "token": "<kingdom>:<algo>:<role>",
        "source": "BiomeGridTokens.ROLES",
        "axes": {"role": growth_roles},
        "note": "seed grows now; field waits to be claimed; halo spills wilderness past the rim; "
                "mute is the declared vacuum. The role is the cell's verb. SWEEP FINDING "
                "(2026-07-27): only seed and halo render — field is dormant BY DESIGN "
                "(claimable), but `edge` ('transition band' in the design doc) is declared in "
                "BiomeGridTokens.ROLES and implemented NOWHERE in GridBiomeComponent. A "
                "declared role with no renderer: either build the blend band or drop the word.",
    }
    return out


def cmd_list():
    for tok, s in specimens().items():
        axes = ", ".join("%s=%d" % (k, len(v)) for k, v in s["axes"].items())
        variants = 1
        for v in s["axes"].values():
            variants *= max(len(v), 1)
        print("%-22s %-28s %s  (%d variants)" % (tok, s["token"], axes, variants))
        print("      derived from: %s" % s["source"])
        for k, v in s["axes"].items():
            print("      %-8s %s" % (k, "|".join(v)))


def cmd_apply():
    specs = specimens()
    reg = {}
    if os.path.isfile(REGISTRY):
        reg = json.load(open(REGISTRY, encoding="utf-8"))
    arts = reg.get("artifacts", reg if reg else {})
    if "artifacts" not in reg:
        reg = {"_readme": "LIVING registry — the biome's organisms as DNA-promoted "
                          "specimens. Not scenes: each entry is a grammar token rendered "
                          "by a morphology, so its axes are derived from the biome grammar "
                          "+ the preset families on disk (tools/promote_living_dna.py), not "
                          "from @export vars. Swept and judged by the same DNA loop as the "
                          "artifacts.", "artifacts": arts}
    today = datetime.date.today().isoformat()
    for tok, s in specs.items():
        entry = arts.get(tok, {})
        entry["name"] = tok
        entry["description"] = s["what"]
        entry["biome_token"] = s["token"]
        entry["dna"] = {
            "promoted": today,
            "stage": "2 - variation",
            "derived_from": s["source"],
            "axes": s["axes"],
            "note": s["note"],
        }
        arts[tok] = entry
    reg["artifacts"] = arts
    os.makedirs(os.path.dirname(REGISTRY), exist_ok=True)
    with open(REGISTRY, "w", encoding="utf-8") as f:
        json.dump(reg, f, indent=1, ensure_ascii=True)
        f.write("\n")
    total = sum(len(v) for s in specs.values() for v in s["axes"].values())
    print("promoted %d living specimens, %d declared axis values -> %s" % (
        len(specs), total, os.path.relpath(REGISTRY, ROOT)))
    print("next: sweep them (build_dna_gallery), then the bite critic")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    if a.apply:
        cmd_apply()
    else:
        cmd_list()


if __name__ == "__main__":
    main()
