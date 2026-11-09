"""Fit works to the Void tower, pass by pass, and learn which strategy worked (Palle, 2026-11-09).

    python tools/void_fit.py apply <decisions.json> [--stage]   edit rooms.json floor by floor (by map name)
    python tools/void_fit.py survey <decisions.json>            re-measure the floors the decisions touch
    python tools/void_fit.py overlaps <decisions.json>          pairs of works standing in each other, columns inside works
    python tools/void_fit.py record <decisions.json> --before=<report.json snapshot>
                                                                append one case per work to commons/void/fit_strategies.json

A decisions file is a list of rows {"map", "id", ...}:
    "set":    placement keys to change (position, height, scale, facing)
    "fit":    the placement's config.fit (strategies, strip, strip_parts, keep_parts, set, note) - merged
    "remove": true (the placement goes; say why in "note")
    "add":    a whole new placement (e.g. a void_slab_extension)
    "strategies", "note": what was tried and why (also written into config.fit)
    "before": (optional) what was wrong, for record, when the survey reads it as fitting (an overlap, a column inside)
Strategies: commons/void/fit_strategies.json. Measurements: tools/void_size_survey.py. Moves: tools/void_fit_pass.py.
--stage writes the same edits onto the staged (index) rooms.json, for floors whose committed and working records agree;
--stage-only does that alone (a pass already applied to the working tree, committed afterwards)."""
import copy, json, re, subprocess, sys, time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ROOMS = ROOT / "commons/void/rooms.json"
CATALOG = ROOT / "commons/void/fit_strategies.json"
OUT = ROOT / "ada_run/void-size-survey"


def _span(text, name):
    m = re.search(r'"map":\s*"%s"' % re.escape(name), text)
    assert m, name
    i = m.start(); depth = 0
    while True:
        i -= 1
        if text[i] == "}": depth += 1
        elif text[i] == "{":
            if depth == 0: break
            depth -= 1
    start = i; depth = 0; j = start; ins = False; esc = False
    while True:
        c = text[j]
        if ins:
            if esc: esc = False
            elif c == "\\": esc = True
            elif c == '"': ins = False
        elif c == '"': ins = True
        elif c == "{": depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0: return start, j + 1
        j += 1


def edit_text(raw, edits):
    nl = "\r\n" if "\r\n" in raw else "\n"
    for name, fn in edits.items():
        s, e = _span(raw, name)
        indent = raw[raw.rfind("\n", 0, s) + 1:s]
        block = json.loads(raw[s:e]); fn(block)
        out = json.dumps(block, indent=2, ensure_ascii=False).replace("\n", "\n" + indent)
        if nl == "\r\n": out = out.replace("\n", "\r\n")
        raw = raw[:s] + out + raw[e:]
    json.loads(raw)
    return raw


def floor_edits(rows):
    by_map = {}
    for r in rows: by_map.setdefault(r["map"], []).append(r)
    def make(rs):
        def fn(f):
            arts = f["artifacts"]
            for r in rs:
                if r.get("add"):
                    if not any(a["id"] == r["add"]["id"] for a in arts): arts.append(copy.deepcopy(r["add"]))
                    continue
                a = next((a for a in arts if a["id"] == r["id"]), None)
                if a is None:
                    print("  not on %s: %s" % (f["map"], r["id"])); continue
                if r.get("remove"):
                    arts.remove(a); continue
                for k, v in r.get("set", {}).items(): a[k] = v
                if r.get("fit") is not None or r.get("strategies"):
                    fit = a.setdefault("config", {}).setdefault("fit", {})
                    fit.update(copy.deepcopy(r.get("fit") or {}))
                    if r.get("strategies"): fit["strategies"] = sorted(set(fit.get("strategies", [])) | set(r["strategies"]))
                    if r.get("note"): fit["note"] = r["note"]
        return fn
    return {m: make(rs) for m, rs in by_map.items()}


def apply(path, stage, working=True):
    rows = json.loads(Path(path).read_text(encoding="utf-8"))
    edits = floor_edits(rows)
    if working:
        raw = ROOMS.read_bytes().decode("utf-8")
        ROOMS.write_bytes(edit_text(raw, edits).encode("utf-8"))
        print("working rooms.json: %d floors edited" % len(edits))
    if stage:
        head = subprocess.run(["git", "show", ":commons/void/rooms.json"], cwd=ROOT, capture_output=True, check=True).stdout
        doc = json.loads(head)
        F = {f["map"]: f for f in doc["floors"]}
        work = {f["map"]: f for f in json.loads(ROOMS.read_bytes())["floors"]}
        for m, fn in edits.items():
            if m in F: fn(F[m])
        data = (json.dumps(doc, indent=2, ensure_ascii=False) + "\n").encode("utf-8")
        sha = subprocess.run(["git", "hash-object", "-w", "--no-filters", "--stdin"], cwd=ROOT, input=data, capture_output=True, check=True).stdout.decode().strip()
        subprocess.run(["git", "update-index", "--cacheinfo", "100644,%s,commons/void/rooms.json" % sha], cwd=ROOT, check=True)
        differ = [m for m in edits if m in F and F[m] != work[m]]
        print("staged; floors whose staged record differs from the working one (others' uncommitted work):", differ or "none")


def survey(path):
    rows = json.loads(Path(path).read_text(encoding="utf-8"))
    maps = sorted({r["map"] for r in rows})
    tag = "fit%d" % int(time.time())
    subprocess.run([sys.executable, str(ROOT / "tools/void_size_survey.py"), "run", "--maps=" + ",".join(maps), "--chunks=1", "--tag=" + tag], cwd=ROOT, check=True)
    subprocess.run([sys.executable, str(ROOT / "tools/void_size_survey.py"), "report"], cwd=ROOT, check=True, capture_output=True)
    print("re-measured", maps)


def status(report, floor_map, ident):
    for r in report.get("overflowing", []):
        if r["map"] == floor_map and r["id"] == ident: return "overflows: " + "; ".join(r["overflow"])
    for r in report.get("displaced", []):
        if r["map"] == floor_map and r["id"] == ident: return "displaced: " + r["displaced"]
    return "fits"


def record(path, before_path):
    rows = json.loads(Path(path).read_text(encoding="utf-8"))
    before = json.loads(Path(before_path).read_text(encoding="utf-8"))
    after = json.loads((OUT / "report.json").read_text(encoding="utf-8"))
    cat = json.loads(CATALOG.read_text(encoding="utf-8"))
    n = 0
    for r in rows:
        ident = r.get("id") or (r.get("add") or {}).get("id")
        # a row may say what was wrong when the survey could not see it (two works in each other, a column inside)
        b = r.get("before") or status(before, r["map"], ident); a = "removed" if r.get("remove") else status(after, r["map"], ident)
        cat["cases"].append({"at": time.strftime("%Y-%m-%d"), "map": r["map"], "id": ident, "token": r.get("token", ""),
                             "strategies": r.get("strategies", []), "before": b, "after": a,
                             "verdict": "worked" if a in ("fits", "removed") and b != "fits" else ("unchanged" if a == b else "partly" if a != "fits" else "kept fitting"),
                             "note": r.get("note", "")})
        n += 1
    CATALOG.write_text(json.dumps(cat, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    worked = sum(1 for c in cat["cases"][-n:] if c["verdict"] == "worked")
    print("%d cases recorded, %d worked" % (n, worked))
    for c in cat["cases"][-n:]:
        print("  %-8s %-26s %-40s %s -> %s" % (c["verdict"], c["map"][:26], c["id"][:40], c["before"][:40], c["after"][:50]))


def overlaps(path, margin=0.3):
    """The survey judges each work alone, against the slab and the ceiling: two works standing in each other, or a
    tower column inside a work, both read "fits". This compares every pair on the floors a decisions file touches,
    from the last measured boxes (footprints only; side slabs, the floor's own playgrounds and flat or point-like
    boxes left out). A pair is reported when the boxes cross by more than `margin` on both axes."""
    sys.path.insert(0, str(ROOT / "tools"))
    import void_size_survey as S
    building, floors = S.load()
    rooms = json.loads(ROOMS.read_text(encoding="utf-8"))
    index = {f["map"]: i for i, f in enumerate(rooms["floors"])}
    rows = json.loads(Path(path).read_text(encoding="utf-8"))
    cw = building["column_width"] / 2
    found = 0
    kept_n = 0
    for m in sorted({r["map"] for r in rows}):
        f = floors.get(str(index[m]))
        if not f: continue
        kept = kept_ids(rooms["floors"][index[m]])
        kept_n += len(kept)
        ws = [w for w in f["works"] if w.get("box") and None not in w["box"] and w.get("token") not in ("void_slab_extension", "playground_spec_hall")
              and not w.get("extension") and (w["box"][3] - w["box"][0]) < 40 and w["id"] not in kept]
        for a_i, a in enumerate(ws):
            ax0, _, az0, ax1, _, az1 = a["box"]
            for cx in building["column_x"]:
                for cz in building["column_z"]:
                    if ax0 < cx + cw - .05 and ax1 > cx - cw + .05 and az0 < cz + cw - .05 and az1 > cz - cw + .05 and (ax1 - ax0) > 1 and (az1 - az0) > 1:
                        print("  %-24s %-40s column (%g, %g) in it" % (m[:24], a["id"][:40], cx, cz)); found += 1
            for b in ws[a_i + 1:]:
                bx0, _, bz0, bx1, _, bz1 = b["box"]
                ox, oz = min(ax1, bx1) - max(ax0, bx0), min(az1, bz1) - max(az0, bz0)
                if ox > margin and oz > margin:
                    print("  %-24s %-40s x %-40s %.1f x %.1f m" % (m[:24], a["id"][:40], b["id"][:40], ox, oz)); found += 1
    print("%d overlaps (%d works kept on purpose: config.fit.strategies has \"kept\", the note says why)" % (found, kept_n))
    return found


def kept_ids(floor_record):
    """Works a fit pass KEPT where they stand on purpose (config.fit.strategies holds "kept", config.fit.note says why):
    a body bigger than a column bay, a work that draws its probe through another. The overlap checks leave them out."""
    return {a["id"] for a in floor_record.get("artifacts", []) if "kept" in ((a.get("config") or {}).get("fit") or {}).get("strategies", [])}


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf8")
    cmd, path = sys.argv[1], sys.argv[2]
    if cmd == "apply": apply(path, "--stage" in sys.argv or "--stage-only" in sys.argv, working="--stage-only" not in sys.argv)
    elif cmd == "overlaps": overlaps(path)
    elif cmd == "survey": survey(path)
    elif cmd == "record": record(path, next(a.split("=", 1)[1] for a in sys.argv if a.startswith("--before=")))
