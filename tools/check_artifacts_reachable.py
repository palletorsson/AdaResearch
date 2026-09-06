"""Every artifact a clone's registry declares is in the repository.

WHY THIS EXISTS
---------------
On 2026-09-06 five tracked maps placed artifacts a fresh clone cannot load,
and every instrument in the battery called the tree clean. The root cause was
one glob:

    .gitignore:74   data_*/          # in the Mono/C# block

Unanchored, that matched every artifact folder named `data_something` at any
depth -- and because git will not DESCEND into an excluded directory, the
`!*.gd` / `!*.tscn` re-includes eighty lines further down could not rescue
what was inside one. Three artifacts vanished:

  * commons/hazards/data_tree_walker/            placed in Hazards_Zoo_4
  * algorithms/.../data_locality_caching/        placed in its own map
  * commons/artifacts/data_labor_counter/        placed in CriticalAlgorithms_Bias_Gallery

The third is the shape worth remembering: its .tscn had been force-added at
some point and its .gd had not, so a clone got a scene that loads and a
script that does not exist. Half-landed is worse than absent, because the
scene resolves.

Two more were plainly never added: konigsberg_observation_court
(World_Konigsberg_Bridge) and drag_point_target (Point_One -- the map
FOCUS_VECTOR names as the model for the whole primitives sequence).

Gate B reports `unresolved_scene_files: 0` on all of it, because it asks
os.path.exists(). That is the same class gate H was written for on the tools
side and gate L on the prose side: the difference between `os.path.exists()`
and `git ls-tree`, in a project where several sessions write at once and only
one of them commits. This gate is the third surface -- the artifacts.

THE SCOPE, AND WHY IT IS DRAWN AT HEAD
--------------------------------------
An artifact is IN SCOPE if the registry file declaring it is IN HEAD, read as
it stands in HEAD. The question is exactly:

    booting a fresh clone, is there an artifact its registry declares that
    the clone does not have the files for?

That excludes, on purpose, a session's unlanded work. 56 entries in this tree
live in four registries that are themselves untracked (dream_figures.json and
three others). A clone never reads those entries, so it can never miss their
scenes -- convicting them would be telling somebody to commit half of
somebody else's change. Gate L's first run made exactly that mistake against
ten facade files; the scoping is the lesson, not the incident.

WHY THE CLOSURE, NOT JUST THE SCENE
-----------------------------------
Landing a script that preloads an untracked script only moves the hole. When
this gate's first sweep was repaired, museum_wall_piece.gd turned out to
preload museum_wall_architectural_spans.gd and museum_wall_opening_spans.gd,
neither of which was in git. So the gate follows res:// references out of a
declared scene transitively, and asks the same question of everything it
reaches.

WHAT THIS DOES NOT CHECK
------------------------
Whether an artifact EXISTS. A registry entry naming a scene that is on no
disk anywhere is gate B's `unresolved_scene_files`, and it is reported here
as its own metric rather than folded into the verdict -- one fault, one gate.

Nor whether a tracked file is COMMITTED in its current state. Tracked and
dirty is normal mid-session: a clone gets an older version of the artifact,
which is a different and much smaller loss than getting no file at all. The
same line gates H and L draw, for the same reason.

    python tools/check_artifacts_reachable.py            # human
    python tools/check_artifacts_reachable.py --json     # machine-readable
    python tools/check_artifacts_reachable.py --selftest # the gate still bites

Exit code is the number of unreachable artifact files, so it gates.
"""

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

REG_DIR = "commons/artifacts/registry"
MAP_DIR = "commons/maps"

RES_REF = re.compile(r'res://([^"\'\s\)]+)')

# addons/ is gitignored ON PURPOSE -- godot-xr-tools and the rest are vendored
# and installed, not committed, which is why a worktree cannot run Godot at all
# until they are copied in. This gate's first run convicted 143 addon files and
# was right about none of them: a clone is MEANT not to have those, and telling
# somebody to commit an upstream addon is the same false positive gate L made
# against ten facade files. Reported as its own count so the number stays
# visible, never folded into the verdict.
VENDORED = ("addons/",)

# Extensions worth following out of a scene or script. A missing .png is a
# missing picture; a missing .gd is an artifact that does not run.
FOLLOW = (".gd", ".tscn", ".gdshader", ".shader", ".tres", ".res")


def head_files():
    """Every path a fresh clone of HEAD would have.

    ls-tree, not ls-files: the index can hold a path HEAD does not, and the
    question this gate asks is about the clone.
    """
    out = subprocess.run(
        ["git", "ls-tree", "-r", "HEAD", "--name-only"],
        cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace"
    )
    if out.returncode != 0:
        return set()
    return {line.strip().replace("\\", "/") for line in out.stdout.splitlines()
            if line.strip()}


def head_blob(rel):
    """The HEAD content of a path, or None."""
    out = subprocess.run(["git", "show", "HEAD:%s" % rel],
                         cwd=ROOT, capture_output=True)
    if out.returncode != 0:
        return None
    return out.stdout.decode("utf-8", errors="replace")


def declared_artifacts(in_head):
    """token -> (registry path, scene path), read from the registries in HEAD.

    Only registries HEAD carries. An untracked registry declares nothing a
    clone can read.
    """
    found = {}
    for rel in sorted(p for p in in_head
                      if p.startswith(REG_DIR + "/") and p.endswith(".json")):
        if rel.endswith(".bak") or ".bak." in rel:
            continue
        blob = head_blob(rel)
        if blob is None:
            continue
        try:
            data = json.loads(blob)
        except (json.JSONDecodeError, ValueError):
            continue
        if not isinstance(data, dict):
            continue
        if isinstance(data.get("artifacts"), dict):
            data = data["artifacts"]
        for token, entry in data.items():
            if not isinstance(entry, dict):
                continue
            scene = entry.get("scene") or entry.get("scene_path")
            if not isinstance(scene, str) or not scene.startswith("res://"):
                continue
            found[token] = (rel, scene[len("res://"):])
    return found


def exact_on_disk(rel, disk):
    """Is this path on disk under EXACTLY this name?

    Path.exists() on Windows is case-insensitive and git is not, so a file
    stored as Foo/bar.gd answers yes to foo/BAR.gd and is then absent from
    git under the name asked for. Gate L's first run convicted ten files that
    way. `disk` is an exact-case set, so this asks the question git asks.
    """
    return rel in disk


def walk(entries, in_head, disk, read):
    """The verdict, as a pure function of the three inputs.

    entries: token -> (registry, scene path)   -- what a clone's registries say
    in_head: exact-case paths a clone would have
    disk:    exact-case paths this working tree has
    read:    rel -> text, for following res:// references

    Returns (unreachable, absent, vendored, checked). A file is UNREACHABLE
    when this tree has it and the clone does not -- that is the whole fault. A
    file no tree has is ABSENT, which belongs to gate B. A file under a
    VENDORED root is neither: the repository deliberately does not carry it.
    """
    unreachable, absent, vendored = [], [], []
    seen = set()
    queue = []
    origin = {}
    for token, (reg, scene) in sorted(entries.items()):
        queue.append(scene)
        origin.setdefault(scene, (token, reg))

    while queue:
        rel = queue.pop()
        if rel in seen:
            continue
        seen.add(rel)
        token, reg = origin.get(rel, ("?", "?"))
        is_vendored = rel.startswith(VENDORED)
        on_disk = exact_on_disk(rel, disk)
        if not on_disk:
            if not is_vendored:
                absent.append({"token": token, "registry": reg, "path": rel})
            continue
        if rel not in in_head:
            (vendored if is_vendored else unreachable).append(
                {"token": token, "registry": reg, "path": rel})
        # Follow the references either way: a landed scene can point at an
        # unlanded script, and so can an unlanded one.
        text = read(rel)
        if not text:
            continue
        for ref in RES_REF.findall(text):
            dep = ref.strip().rstrip('"\'')
            if not dep or dep.endswith("/") or not dep.endswith(FOLLOW):
                continue
            # "res://commons/artifacts/%s.tscn" is a path BUILT at runtime, not
            # a path. Following it produced 30-odd entries in the absent list
            # naming files that were never meant to exist, and a metric with
            # junk in it stops being read.
            if "%s" in dep or "%d" in dep or "{" in dep:
                continue
            origin.setdefault(dep, (token, reg))
            queue.append(dep)

    return unreachable, absent, vendored, len(seen)


def disk_paths():
    """Exact-case paths of every file that could be referenced.

    Scanning the whole tree is wasteful; the reference closure only ever
    reaches source under these roots.
    """
    out = set()
    for top in ("commons", "algorithms", "addons", "scenes", "assets"):
        base = ROOT / top
        if not base.is_dir():
            continue
        for p in base.rglob("*"):
            if p.is_file():
                out.add(p.relative_to(ROOT).as_posix())
    return out


def read_file(rel):
    try:
        return (ROOT / rel).read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def placed_tokens():
    """token -> maps placing it, from the map_data.json a clone would read."""
    placed = {}
    for md in (ROOT / MAP_DIR).glob("*/map_data.json"):
        try:
            data = json.loads(md.read_text(encoding="utf-8", errors="replace"))
        except (OSError, json.JSONDecodeError, ValueError):
            continue
        layers = data.get("layers", data)
        rows = layers.get("interactables") if isinstance(layers, dict) else None
        if not isinstance(rows, list):
            continue
        for row in rows:
            if not isinstance(row, list):
                continue
            for cell in row:
                if not isinstance(cell, str) or not cell.strip():
                    continue
                tok = cell.split(":")[0].split("#")[0].strip()
                if tok and tok not in (" ", "-"):
                    placed.setdefault(tok, set()).add(md.parent.name)
    return placed


def selftest():
    """The gate reads zero on a good day, which is indistinguishable from one
    that stopped checking. Each fixture trips one rule deliberately, and two
    of them are the false positives this class has already produced once.
    """
    files = {
        "r/a.tscn": 'res://r/a.gd',
        "r/a.gd": 'const X = preload("res://r/dep.gd")',
        "r/dep.gd": "",
        "r/ok.tscn": 'res://r/ok.gd',
        "r/ok.gd": "",
        "r/Cased.gd": "",
        "r/vend.tscn": 'res://addons/kit/thing.gd',
        "addons/kit/thing.gd": "",
    }
    read = lambda rel: files.get(rel, "")
    disk = set(files)
    cases = []

    # 1. The plain fault: declared, on disk, not in HEAD.
    ur, ab, ve, _ = walk({"a": ("reg.json", "r/a.tscn")},
                         in_head={"reg.json"}, disk=disk, read=read)
    #    All three of the closure are unreachable, not just the scene named.
    cases.append(("catches an unlanded scene and all it reaches",
                  sorted(u["path"] for u in ur) == ["r/a.gd", "r/a.tscn", "r/dep.gd"]
                  and ab == []))

    # 2. The closure: the scene landed, the script it preloads did not.
    ur, _, _, _ = walk({"a": ("reg.json", "r/a.tscn")},
                       in_head={"reg.json", "r/a.tscn", "r/a.gd"}, disk=disk, read=read)
    cases.append(("follows res:// into an unlanded dependency",
                  [u["path"] for u in ur] == ["r/dep.gd"]))

    # 3. Everything landed reads clean.
    ur, ab, _, _ = walk({"ok": ("reg.json", "r/ok.tscn")},
                        in_head={"reg.json", "r/ok.tscn", "r/ok.gd"}, disk=disk, read=read)
    cases.append(("stays quiet when the artifact is whole", ur == [] and ab == []))

    # 4. Scoping -- an entry only an untracked registry declares is not this
    #    gate's business. declared_artifacts() enforces it by reading HEAD, so
    #    the fixture is the empty entry set that produces.
    ur, _, _, _ = walk({}, in_head=set(), disk=disk, read=read)
    cases.append(("ignores artifacts no clone registry declares", ur == []))

    # 5. Case folding. On Windows Path.exists() says yes to r/cased.gd; git
    #    says no. The gate must read the disk case-sensitively, or it convicts
    #    files that are committed -- gate L did this to ten of them.
    ur, ab, _, _ = walk({"c": ("reg.json", "r/cased.gd")},
                        in_head={"reg.json", "r/Cased.gd"}, disk=disk, read=read)
    cases.append(("does not convict on a case-folded name",
                  [a["path"] for a in ab] == ["r/cased.gd"] and ur == []))

    # 6. A file no tree has is ABSENT, not unreachable -- gate B's fault.
    ur, ab, _, _ = walk({"g": ("reg.json", "r/ghost.tscn")},
                        in_head={"reg.json"}, disk=disk, read=read)
    cases.append(("calls a file nobody has absent, not unreachable",
                  ur == [] and [a["path"] for a in ab] == ["r/ghost.tscn"]))

    # 7. The vendored root. This gate's own first run convicted 143 addon
    #    files, every one of them correctly absent from the repository by
    #    project decision. It must count them and convict none.
    ur, ab, ve, _ = walk({"v": ("reg.json", "r/vend.tscn")},
                         in_head={"reg.json", "r/vend.tscn"}, disk=disk, read=read)
    cases.append(("counts a vendored addon file without convicting it",
                  ur == [] and ab == []
                  and [v["path"] for v in ve] == ["addons/kit/thing.gd"]))

    bad = [name for name, ok in cases if not ok]
    for name, ok in cases:
        print("  %-52s %s" % (name, "ok" if ok else "FAIL"))
    print("selftest: %d/%d" % (len(cases) - len(bad), len(cases)))
    return 1 if bad else 0


def main():
    if "--selftest" in sys.argv:
        return selftest()

    in_head = head_files()
    disk = disk_paths()
    entries = declared_artifacts(in_head)
    unreachable, absent, vendored, checked = walk(entries, in_head, disk, read_file)

    # Not this gate's verdict: a token a map places that no registry in HEAD
    # declares. That is gate G's business (check_map_tokens reads the working
    # tree). Printed because a clone hits it as a missing object in a room
    # somebody walks, and nothing else in the battery asks it of HEAD.
    placed = placed_tokens()
    unreachable_rooms = sorted({
        room
        for u in unreachable
        for room in placed.get(u["token"], ())
    })

    report = {
        "registries_in_head": sum(1 for p in in_head
                                  if p.startswith(REG_DIR + "/") and p.endswith(".json")),
        "artifacts_declared": len(entries),
        "files_checked": checked,
        "unreachable_from_a_clone": len(unreachable),
        "absent_from_every_tree": len(absent),
        "vendored_not_in_repo": len(vendored),
        "rooms_affected": len(unreachable_rooms),
        "unreachable": unreachable,
        "absent": absent,
        "rooms": unreachable_rooms,
    }

    if "--json" in sys.argv:
        print(json.dumps(report, indent=1))
    else:
        print("artifacts declared by a registry in HEAD : %d" % report["artifacts_declared"])
        print("files reached through them               : %d" % report["files_checked"])
        print("UNREACHABLE FROM A CLONE                 : %d" % report["unreachable_from_a_clone"])
        for u in unreachable:
            print("   %-34s %s" % (u["token"], u["path"]))
        print("absent from every tree (gate B's)        : %d" % report["absent_from_every_tree"])
        for a in absent:
            print("   %-34s %s" % (a["token"], a["path"]))
        print("vendored, not in the repo by decision     : %d" % report["vendored_not_in_repo"])
        if unreachable_rooms:
            print("rooms a clone cannot build             : %s" % ", ".join(unreachable_rooms))

    return len(unreachable)


if __name__ == "__main__":
    sys.exit(main())
