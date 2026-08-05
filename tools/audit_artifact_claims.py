#!/usr/bin/env python3
"""Does the artifact do what its entry says it does?

Eleven promotion batches produced roughly 130 axes and about a dozen findings,
and the findings were worth more. Every one of them was the same shape: an
artifact whose registry entry asserts something the code does not do. None was
caught by measuring — the sweep photographs whatever is there and reports a
percentage, so an artifact that builds nothing scores 0.00% and reads as an inert
axis rather than as a corpse.

They were caught by an agent reading one file. That does not scale: at one agent
per two or three tokens, reading 2671 artifacts is hundreds of batches.

But four of the classes are STATIC. They can be checked over the whole corpus in
one pass, with no agents and no Godot, because each is a mismatch between two
things already written down. This is that pass.

    python tools/audit_artifact_claims.py [--class=NAME] [--limit=N]

Exit code is the number of findings, so it gates.

THE FOUR CLASSES, and the artifact that taught each one:

  hollow      A declared axis with no code that reads it. dna_specimen shipped an
              @export_enum, four constants and a doc block specifying four rungs
              to the centimetre, and no function implementing any of them. The
              declaration gate CANNOT see this: the export is real, the values are
              real, nothing acts on them. A sweep returns four identical frames
              and an INERT verdict about a missing function.

  unbuilt     A script that builds nothing. tile_meander_floor is a 149-line stub
              with no _ready and no _build; seven maps place it, one of them has a
              walked.md, and the floor has never been there. pattern_artifact
              returns before building unless a config names a file, and all ten
              placed tokens are bare.

  unreachable A typed export a map token can never set. lsystem_editor held seven
              L-system grammars behind an @export_enum INT called `preset`; a
              map_data.json config value arrives as a STRING, so
              `lsystem_editor#preset:5` was rejected and silently rendered Plant.
              Four maps, one grammar, never an error.

  miscased    A .tscn ext_resource whose path casing differs from the file git
              tracks. Invisible on Windows, fatal on a case-sensitive export, and
              it strands any declaration behind it. newtoncradle.tscn pointed at
              newtoncradle.gd while git tracks NewtonCradle.gd.
"""

from __future__ import annotations

import glob
import json
import os
import re
import subprocess
import sys
from collections import defaultdict

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REG_DIR = os.path.join(REPO, "commons", "artifacts", "registry")


# ── loading ──────────────────────────────────────────────────────────────────

def registry() -> dict:
    out: dict = {}
    for path in sorted(glob.glob(os.path.join(REG_DIR, "*.json"))):
        try:
            data = json.load(open(path, encoding="utf-8"))
        except Exception as exc:
            print(f"  ! registry unreadable, its tokens are invisible: "
                  f"{os.path.basename(path)} ({exc})")
            continue
        items = data.get("artifacts", data) if isinstance(data, dict) else data
        if not isinstance(items, dict):
            continue
        for token, entry in items.items():
            if isinstance(entry, dict) and ("scene" in entry or "delegate_to" in entry):
                out.setdefault(token, entry)
    return out


def res_to_abs(res: str) -> str | None:
    if not isinstance(res, str) or not res.startswith("res://"):
        return None
    return os.path.join(REPO, res[6:].replace("/", os.sep))


def script_for(entry: dict) -> str | None:
    """The .gd a scene actually loads, via its ext_resource."""
    scene = res_to_abs(entry.get("scene", ""))
    if not scene or not os.path.exists(scene):
        return None
    try:
        text = open(scene, encoding="utf-8", errors="replace").read(20000)
    except Exception:
        return None
    # THE ROOT NODE'S script, not the first one listed. capsule.tscn declares a
    # child's prismes/rotation.gd before its own capsule.gd, and taking the first
    # match reported capsule as building nothing and its `facture` axis as unread —
    # two findings that were facts about this parser. Same first-match-wins defect
    # the research runner's registry() docstring already warns about.
    ids = dict(re.findall(r'\[ext_resource\s+type="Script"[^\]]*?id="([^"]+)"', text)
               and re.findall(r'\[ext_resource\s+type="Script"[^\]]*?path="(res://[^"]+\.gd)"[^\]]*?id="([^"]+)"', text)
               or [])
    ids = {i: p for p, i in ids.items()} if ids else {}
    if not ids:  # attribute order varies; try the other way round
        ids = {i: p for p, i in re.findall(
            r'\[ext_resource\s+type="Script"[^\]]*?path="(res://[^"]+\.gd)"[^\]]*?id="([^"]+)"', text)}
        ids.update({i: p for i, p in re.findall(
            r'\[ext_resource\s+type="Script"[^\]]*?id="([^"]+)"[^\]]*?path="(res://[^"]+\.gd)"', text)})

    # the root node is the first [node] block with no parent= attribute
    root = re.search(r'\[node\s+name="[^"]*"(?:\s+type="[^"]*")?\s*\]\s*\n(.*?)(?=\n\[|\Z)',
                     text, re.S)
    if root:
        sm = re.search(r'^script\s*=\s*ExtResource\(\s*"?([^")\s]+)"?\s*\)', root.group(1), re.M)
        if sm and sm.group(1) in ids:
            return res_to_abs(ids[sm.group(1)])

    sibling = os.path.splitext(scene)[0] + ".gd"
    if os.path.exists(sibling):
        return sibling
    # last resort: a single script in the file is unambiguous
    if len(ids) == 1:
        return res_to_abs(next(iter(ids.values())))
    return None


def tracked_files() -> set:
    try:
        out = subprocess.run(["git", "ls-files"], cwd=REPO,
                             capture_output=True, text=True, timeout=120)
        return set(out.stdout.split("\n"))
    except Exception:
        return set()


# ── the four checks ──────────────────────────────────────────────────────────

def check_hollow(token, entry, src, findings, path):
    """A declared axis that the file DECLARING it never acts on.

    Ask it of the declaring file, not of the scene's root script. The forces
    family shares one root (forces_demo_root.gd) while each example declares and
    reads `evidence` in its own sibling — checking the root reported three
    correctly-implemented axes as hollow. Whichever file carries the @export is
    the file that owes an implementation.
    """
    axes = ((entry.get("dna") or {}).get("axes") or {})
    if not axes:
        return
    # candidate sources: the root script plus every .gd beside the scene
    cands = []
    if path and os.path.exists(path):
        cands.append(path)
    scene = res_to_abs(entry.get("scene", ""))
    if scene:
        cands += sorted(glob.glob(os.path.join(os.path.dirname(scene), "*.gd")))

    for axis in axes:
        decl_file, decl_src = None, None
        for c in dict.fromkeys(cands):
            try:
                text = open(c, encoding="utf-8", errors="replace").read()
            except Exception:
                continue
            if re.search(rf"^@export[^\n]*\bvar\s+{re.escape(axis)}\b", text, re.M):
                decl_file, decl_src = c, text
                break
        if decl_src is None:
            continue        # not declared in code at all — that is the gate's job
        body = "\n".join(l for l in decl_src.split("\n")
                         if not l.lstrip().startswith("#"))
        uses = [l for l in body.split("\n")
                if re.search(rf"\b{re.escape(axis)}\b", l) and "@export" not in l]
        if not uses:
            findings.append((
                "hollow", token,
                f"axis `{axis}` is exported in "
                f"{os.path.relpath(decl_file, REPO)} and nothing in that file reads "
                f"it — a sweep renders identical frames and blames the axis"))


GODOT_BUILTIN = re.compile(
    r"^(Node3D|Node|Node2D|Control|Resource|RefCounted|Object|SceneTree|"
    r"CharacterBody3D|RigidBody3D|StaticBody3D|Area3D|MeshInstance3D|"
    r"MultiMeshInstance3D|CSGShape3D|CSGCombiner3D|Camera3D|Label3D|"
    r"AnimatableBody3D|GridMap|Path3D|Sprite3D|GPUParticles3D)$")


def check_unbuilt(token, entry, src, findings):
    """A script with no entry point that constructs anything.

    FOLLOW `extends`. A subclass of a project base legitimately has no _ready:
    BaseCA._ready() calls initialize_grid(), which every ca_showcase member
    overrides, so seventeen correctly-working automata read as building nothing.
    Only a script extending a Godot BUILT-IN owes its own entry point — anything
    extending a project class may be handed one, and this pass cannot see that
    cheaply enough to be worth a false accusation.
    """
    if not src:
        return
    # _enter_tree is a deliberate choice, not an omission: reaction_diffusion
    # forwards to its child there because Godot notifies ENTER_TREE top-down
    # across the whole subtree before any _ready runs. And a script that only
    # drives nodes the SCENE already contains (draw_calls_display is seven lines
    # of _process updating a Label3D) has nothing to build and is not broken.
    if re.search(r"^func\s+(_ready|_enter_tree|_process|_physics_process)\s*\(", src, re.M):
        return
    if re.search(r"^func\s+(_build|_generate|build_scene|_setup|_create|initialize)\w*\s*\(",
                 src, re.M):
        return
    # And ask the SIBLINGS too, for the same reason check_hollow does: the forces
    # family's scene root is a shared forces_demo_root.gd while each example does
    # its building in its own .gd one node down. A root without an entry point is
    # not an artifact without one.
    scene = res_to_abs(entry.get("scene", ""))
    if scene:
        for sib in glob.glob(os.path.join(os.path.dirname(scene), "*.gd")):
            try:
                st = open(sib, encoding="utf-8", errors="replace").read()
            except Exception:
                continue
            if re.search(r"^func\s+(_ready|_enter_tree|_process|_physics_process|"
                         r"_build|_generate|build_scene|_setup|_create|initialize)\w*\s*\(",
                         st, re.M):
                return

    base = re.search(r"^extends\s+([A-Za-z_][\w.]*)", src, re.M)
    if base and not GODOT_BUILTIN.match(base.group(1)):
        return          # a project base may own the entry point
    if not re.search(r"^func\s", src, re.M):
        pass            # no functions at all — certainly inert
    findings.append((
        "unbuilt", token,
        f"no _ready and no builder in {os.path.relpath(src_path_of(entry), REPO)}, "
        f"and it extends {base.group(1) if base else '?'} — placed in maps and "
        f"constructs nothing"))


_SRC_PATH: dict = {}


def src_path_of(entry):
    return _SRC_PATH.get(id(entry), "?")


def check_unreachable(token, entry, src, findings):
    """Typed exports a string config key can never set."""
    if not src:
        return
    # does the artifact take config at all?
    if "apply_grid_config" not in src:
        return
    for m in re.finditer(r"^@export(?:_enum\([^)]*\))?\s+var\s+(\w+)\s*:\s*(int|bool|float)\b",
                         src, re.M):
        name, typ = m.group(1), m.group(2)
        # is it read out of config_data / config without a conversion?
        raw = re.search(rf'config\w*\[\s*"{name}"\s*\]', src)
        if not raw:
            continue
        near = src[max(0, raw.start() - 300):raw.end() + 300]
        if re.search(r"\b(int|float|bool)\s*\(", near) or "to_int" in near or "to_float" in near:
            continue
        findings.append((
            "unreachable", token,
            f"`{name}` is typed {typ} and read straight from a config dict — a map "
            f"token delivers a STRING, so the assignment is rejected and the "
            f"artifact silently keeps its default"))


def check_miscased(token, entry, src, findings, tracked):
    """A scene pointing at a path whose casing git does not have."""
    scene = res_to_abs(entry.get("scene", ""))
    if not scene or not os.path.exists(scene) or not tracked:
        return
    try:
        text = open(scene, encoding="utf-8", errors="replace").read(20000)
    except Exception:
        return
    for m in re.finditer(r'path="(res://[^"]+\.(?:gd|tscn|tres))"', text):
        rel = m.group(1)[6:]
        if rel in tracked:
            continue
        lower = {t.lower(): t for t in tracked}
        actual = lower.get(rel.lower())
        if actual and actual != rel:
            findings.append((
                "miscased", token,
                f"scene points at {rel} but git tracks {actual} — invisible on "
                f"Windows, fatal on a case-sensitive export"))


# ── main ─────────────────────────────────────────────────────────────────────

def main() -> int:
    only = None
    limit = 40
    for a in sys.argv[1:]:
        if a.startswith("--class="):
            only = a.split("=", 1)[1]
        elif a.startswith("--limit="):
            limit = int(a.split("=", 1)[1])

    reg = registry()
    tracked = tracked_files()
    findings: list = []

    # placements, so findings can be ranked by how many rooms they touch
    placed: dict = defaultdict(int)
    for path in glob.glob(os.path.join(REPO, "commons", "maps", "*", "map_data.json")):
        try:
            data = json.load(open(path, encoding="utf-8"))
        except Exception:
            continue
        for row in ((data.get("layers") or {}).get("interactables") or []):
            if isinstance(row, list):
                for cell in row:
                    if isinstance(cell, str) and cell.strip():
                        placed[cell.split(":")[0]] += 1

    scanned = 0
    for token, entry in sorted(reg.items()):
        if placed[token] == 0:          # a finding nobody can meet is not urgent
            continue
        path = script_for(entry)
        _SRC_PATH[id(entry)] = path or "?"
        src = None
        if path and os.path.exists(path):
            try:
                src = open(path, encoding="utf-8", errors="replace").read()
            except Exception:
                src = None
        scanned += 1
        if only in (None, "hollow"):
            check_hollow(token, entry, src, findings, path)
        if only in (None, "unbuilt") and path:
            check_unbuilt(token, entry, src, findings)
        if only in (None, "unreachable"):
            check_unreachable(token, entry, src, findings)
        if only in (None, "miscased"):
            check_miscased(token, entry, src, findings, tracked)

    by_class: dict = defaultdict(list)
    for cls, token, why in findings:
        by_class[cls].append((placed[token], token, why))

    print(f"\naudited {scanned} placed artifacts · {len(findings)} findings\n")
    order = ["unbuilt", "hollow", "unreachable", "miscased"]
    for cls in order:
        rows = sorted(by_class.get(cls, []), reverse=True)
        if not rows:
            continue
        reach = sum(r[0] for r in rows)
        print(f"── {cls.upper()}  {len(rows)} artifacts · {reach} placements")
        for n, token, why in rows[:limit]:
            print(f"   {n:>3}p  {token}")
            print(f"         {why}")
        if len(rows) > limit:
            print(f"   … {len(rows) - limit} more")
        print()

    if not findings:
        print("every placed artifact builds, and every declared axis is read.")
    return len(findings)


if __name__ == "__main__":
    sys.exit(main())
