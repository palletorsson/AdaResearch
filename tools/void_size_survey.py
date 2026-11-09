"""How many works overflow the Void tower, measured in the tower itself (Palle, 2026-11-09).

    python tools/void_size_survey.py run [--chunks=4] [--floors=a-b]   measure (parallel Godot runs, one per chunk)
    python tools/void_size_survey.py report [--markdown]               classify + summarise the last run

Probe: tools/probes/void_size_survey.gd writes each work's world box per floor (placement, scale, facing, config applied).
Raw rows: ada_run/void-size-survey/chunk-*/survey.json. Report: ada_run/void-size-survey/report.json (+ report.md).

Four towers at once ran the machine out of memory, and one tower that has visited ~80 floors does too (2026-11-09):
the default is 6 chunks run 2 at a time (--parallel=2); a crashed run keeps its floors and
`run --missing --tag=retry` measures only the rest.

A work OVERFLOWS when its box leaves the building: past the 42 x 18 m edge (by more than 0.3 m), up through the slab
above (its top over the floor's headroom) or down through its own slab (more than 0.3 m below). Deliberate exterior
extensions (void_floor_extension / void_exterior_walk) are counted apart. Also recorded, not counted as overflow: a
shaft opening under the work, a building column inside its box, floating (bottom > 0.3 m up with height 0).
For each overflowing work: whether it could fit by MOVING (its size fits the floor and headroom) or needs SHRINKING
(and the scale at which it would fit where it stands), or a taller floor."""
import json, os, re, subprocess, sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "ada_run/void-size-survey"
EDGE, DOWN = 0.3, 0.3


def run(args):
    sys.path.insert(0, str(ROOT / "tools"))
    from void_trial_runtime import stage_runtime
    rooms = json.loads((ROOT / "commons/void/rooms.json").read_text(encoding="utf-8"))
    n = len(rooms["floors"])
    lo, hi = 0, n - 1
    for a in args:
        if a.startswith("--floors="):
            lo, hi = [int(x) for x in a.split("=", 1)[1].split("-")]
    chunks = int(next((a.split("=")[1] for a in args if a.startswith("--chunks=")), 6))
    floors = list(range(lo, hi + 1))
    for a in args:
        if a.startswith("--maps="):
            want = a.split("=", 1)[1].split(",")
            floors = [i for i, f in enumerate(rooms["floors"]) if f["map"] in want]
    tag = next((a.split("=", 1)[1] for a in args if a.startswith("--tag=")), "chunk")
    if "--missing" in args:
        # only floors no earlier chunk measured (a run that crashed part-way keeps what it wrote)
        done = set(int(k) for k in load()[1])
        floors = [f for f in floors if f not in done]
        print("missing floors:", len(floors), flush=True)
    # interleave so every chunk gets a share of the heavy floors
    parts = [floors[i::chunks] for i in range(chunks)]
    stage = stage_runtime()
    parallel = int(next((a.split("=")[1] for a in args if a.startswith("--parallel=")), 2))
    procs = []
    for i, part in enumerate(parts):
        while sum(1 for p, _, _ in procs if p.poll() is None) >= parallel:
            # run in waves: a Godot that has visited ~80 floors runs out of memory beside another (2026-11-09)
            import time; time.sleep(5)
        d = OUT / ("%s-%d" % (tag, i))
        d.mkdir(parents=True, exist_ok=True)
        for stale in ("survey.json", "checks.json", "godot.log", "engine.log"):
            (d / stale).unlink(missing_ok=True)
        log = (d / "engine.log").open("w", encoding="utf8")
        cmd = [sys.executable, str(ROOT / "tools/godot_watchdog.py"), "--expect=" + str(d), "--grace=360", "--stall=600", "--",
               os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"),
               "--log-file", str(d / "godot.log"), "--path", str(stage), "--xr-mode", "off", "--rendering-method", "gl_compatibility",
               "--resolution", "640x400", "--position", "%d,3200" % (3200 + 700 * i),
               "--script", "res://tools/probes/void_size_survey.gd", "--", "--no-bridges", "--out=" + d.as_posix(),
               "--floors=" + ",".join(str(f) for f in part)]
        procs.append((subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT, creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0)), log, d))
        print("chunk %d: %d floors" % (i, len(part)), flush=True)
    for p, log, d in procs:
        p.wait(); log.close()
        print("%s exit %d, %s" % (d.name, p.returncode, "survey.json" if (d / "survey.json").exists() else "NO survey"), flush=True)


def load():
    building, floors = None, {}
    # oldest first, so a floor measured again later (a fitting pass) is read from its newest run
    for d in sorted(OUT.glob("*-[0-9]*"), key=lambda d: (d / "survey.json").stat().st_mtime if (d / "survey.json").exists() else 0):
        p = d / "survey.json"
        if not p.exists():
            continue
        s = json.loads(p.read_text(encoding="utf-8"))
        building = s["building"]
        floors.update(s["floors"])
    return building, floors


def _slabs(floor_record):
    for a in floor_record.get("artifacts", []):
        if a.get("artifact") != "void_slab_extension": continue
        c = a.get("config") or {}
        L = min(max(float(c.get("length", 12)), 2.0), 42.0); D = min(max(float(c.get("depth", 6)), 1.0), 10.0)
        px, pz = (float(v) for v in a.get("position", [0, 0])[:2])
        turn = round(float(a.get("facing", 0))) % 360
        if turn == 0: yield (px - L / 2, pz - .025, px + L / 2, pz + D + .025), turn
        elif turn == 180: yield (px - L / 2, pz - D - .025, px + L / 2, pz + .025), turn
        elif turn == 90: yield (px - .025, pz - L / 2, px + D + .025, pz + L / 2), turn
        elif turn == 270: yield (px - D - .025, pz - L / 2, px + .025, pz + L / 2), turn


def slab_decks(floor_record):
    """A floor's side-slab DECKS as (x0, z0, x1, z1), from their placements (commons/void/slab_extension.gd: `length`
    along the edge, `depth` out along the slab's facing, 5 cm into the building). Not the measured box: that holds the
    tangled beams too, whose feet spread up to 1 m past the deck's ends, so a work there reads as standing on air."""
    return [d for d, _ in _slabs(floor_record)]


def slab_grounds(floor_record, margin):
    """The ground a side slab adds, as (x0, z0, x1, z1) for an `x0 <= x <= x1 and z0 <= z <= z1` test: its deck kept
    `margin` in from the rails on its three open sides, and run 0.5 m into the building on the fourth (the side it
    faces away from), so a point crossing the building's edge is never caught between two margins."""
    out = []
    for d, turn in _slabs(floor_record):
        x0, z0, x1, z1 = d[0] + margin, d[1] + margin, d[2] - margin, d[3] - margin
        if turn == 0: z0 = d[1] - .5
        elif turn == 180: z1 = d[3] + .5
        elif turn == 90: x0 = d[0] - .5
        else: x1 = d[2] + .5
        out.append((x0, z0, x1, z1))
    return out


def classify(b, f, w, above_closed=()):
    hw, hd = b["width"] / 2, b["depth"] / 2
    box = w.get("box")
    out = {"overflow": [], "notes": []}
    if not w.get("mounted"):
        out["notes"].append("not mounted"); return out
    if box is None:
        out["notes"].append("no mesh"); return out
    if any(v is None for v in box):
        out["notes"].append("unmeasurable box (infinite)"); return out
    x0, y0, z0, x1, y1, z1 = box
    sx, sy, sz = x1 - x0, y1 - y0, z1 - z0
    if sx > 80 or sz > 80:
        out["notes"].append("box %.0f x %.0f m (a stage or sky, not a footprint)" % (sx, sz)); return out
    head = f.get("headroom") or 1e9
    # DISPLACED: the whole work is drawn away from its floor (a top_level mesh at world coordinates, an orbit, a
    # stray instance) - not too big, misplaced; a different fault with a different remedy
    gr = w.get("ground") or {}
    if x1 < -hw or x0 > hw or z1 < -hd or z0 > hd or y0 > head + 1 or y1 < -1:
        if not w.get("extension") and not (gr.get("under", 0) > 0 and -1 <= y0 and y0 <= head):
            # nothing of it over any floor or landing: drawn away from where it is placed
            out["displaced"] = "drawn %s, box centre (%.1f, %.1f, %.1f)" % (
                "above its floor" if y0 > head + 1 else "below its floor" if y1 < -1 else "outside the building", (x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
            out["size"] = [round(sx, 2), round(sy, 2), round(sz, 2)]
            return out
    over = {}
    if x0 < -hw - EDGE: over["west"] = -hw - x0
    if x1 > hw + EDGE: over["east"] = x1 - hw
    if z0 < -hd - EDGE: over["north"] = -hd - z0
    if z1 > hd + EDGE: over["south"] = z1 - hd
    if over:
        held = gr.get("outside", 0) > 0 and gr.get("outside_held", 0) >= gr.get("outside", 0)
        if held:
            out["notes"].append("past the 42 x 18 m slab onto a landing or balcony (ground under it)")
        else:
            out["overflow"].append("edge: " + ", ".join("%s %.1f m" % kv for kv in over.items()) +
                                   (" (%d of %d samples past the slab have ground)" % (gr.get("outside_held", 0), gr.get("outside", 0)) if gr else ""))
    if y1 > head + 0.05:
        # above the slab INSIDE a shaft opening is the same thing upward: the slab above has the same hole (unless the
        # floor above closes that shaft), so a tall work stood under it rises into the floor above - the spectrum
        # forest in shaft A, a pendulum hung in shaft B (2026-11-09)
        foot = max((x1 - x0) * (z1 - z0), 1e-6)
        rising = [s["name"] for s in b["shafts"] if s["name"] not in above_closed and
                  max(0, min(x1, float(s["x"]) + b["shaft_width"] / 2) - max(x0, float(s["x"]) - b["shaft_width"] / 2)) *
                  max(0, min(z1, b["shaft_depth"] / 2) - max(z0, -b["shaft_depth"] / 2)) >= .5 * foot]
        if rising: out["notes"].append("rises %.1f m through shaft %s into the floor above" % (y1 - head, rising[0]))
        else: out["overflow"].append("ceiling: %.1f m through the slab above (top %.1f, headroom %.1f)" % (y1 - head, y1, head))
    if y0 < -DOWN:
        # below the slab INSIDE a shaft opening is a descent the floor is built for (a wheel down to the next floor,
        # a falling bend), not an overflow; anywhere else it pokes into the floor beneath
        foot = max((x1 - x0) * (z1 - z0), 1e-6)
        in_shaft = any(max(0, min(x1, float(s["x"]) + b["shaft_width"] / 2) - max(x0, float(s["x"]) - b["shaft_width"] / 2)) *
                       max(0, min(z1, b["shaft_depth"] / 2) - max(z0, -b["shaft_depth"] / 2)) >= .5 * foot for s in b["shafts"])
        if in_shaft: out["notes"].append("descends %.1f m through a shaft" % -y0)
        else: out["overflow"].append("floor: %.1f m down through its own slab" % -y0)
    if w.get("extension"):
        out["extension"] = bool(out["overflow"]); out["overflow"] = []
    for s in b["shafts"]:
        cx = float(s["x"]); ox = min(x1, cx + b["shaft_width"] / 2) - max(x0, cx - b["shaft_width"] / 2)
        oz = min(z1, b["shaft_depth"] / 2) - max(z0, -b["shaft_depth"] / 2)
        if ox > .3 and oz > .3 and y0 < 2.5: out["notes"].append("over shaft %s" % s["name"])
    cw = b["column_width"] / 2
    for cx in b["column_x"]:
        for cz in b["column_z"]:
            if x0 < cx - cw and x1 > cx + cw and z0 < cz - cw and z1 > cz + cw: out["notes"].append("column (%g, %g) inside" % (cx, cz))
    if y0 > .3 and float(w.get("height") or 0) == 0: out["notes"].append("floats %.1f m" % y0)
    out["size"] = [round(sx, 2), round(sy, 2), round(sz, 2)]
    if out["overflow"]:
        fits_floor = sx <= 2 * hw and sz <= 2 * hd and sy <= head
        cxm, czm = (x0 + x1) / 2, (z0 + z1) / 2
        # the scale (about the box centre, on the slab) at which it would fit where it stands
        lim = [((hw - abs(cxm)) * 2) / sx if sx else 9, ((hd - abs(czm)) * 2) / sz if sz else 9, head / sy if sy else 9]
        out["fit"] = "move" if fits_floor else ("taller floor" if sx <= 2 * hw and sz <= 2 * hd else "shrink or exterior")
        out["fit_scale_here"] = round(max(0.0, min(lim)) * float(w.get("scale") or 1), 2)
        out["fit_scale_anywhere"] = round(min((2 * hw) / sx if sx else 9, (2 * hd) / sz if sz else 9, head / sy if sy else 9) * float(w.get("scale") or 1), 2)
    return out


def report(args):
    b, floors = load()
    if not floors:
        print("no survey yet: python tools/void_size_survey.py run"); return
    rows = []
    records = json.loads((ROOT / "commons/void/rooms.json").read_text(encoding="utf-8"))["floors"]
    for k in sorted(floors, key=int):
        f = floors[k]
        # the slab above this floor is the floor above's own: a shaft it encloses has no hole to rise through
        above_closed = records[int(k) - 1].get("enclosed_shafts", []) if 0 < int(k) <= len(records) else ["A", "B"]
        for w in f["works"]:
            c = classify(b, f, w, above_closed)
            ident = str(w.get("id"))
            origin = "museum transfer" if re.match(r"f\d+_", ident) else "museum restore" if ident.startswith("museum-") or w.get("museum") else "tower"
            rows.append({"floor": int(k), "map": f["map"], "origin": origin, **{x: w.get(x) for x in ("id", "token", "museum", "scale", "at", "copy", "parts")}, **c})
    over = [r for r in rows if r["overflow"]]
    kinds = Counter(o.split(":")[0] for r in over for o in r["overflow"])
    by_token = defaultdict(list)
    for r in over: by_token[r["token"]].append(r)
    displaced = [r for r in rows if r.get("displaced")]
    by_origin = {o: {"works": sum(1 for r in rows if r["origin"] == o), "overflowing": sum(1 for r in over if r["origin"] == o),
                     "displaced": sum(1 for r in displaced if r["origin"] == o)} for o in ("museum transfer", "museum restore", "tower")}
    museum_all = sum(1 for r in rows if r["museum"]); museum_over = sum(1 for r in over if r["museum"])
    summary = {"floors": len(floors), "works": len(rows), "overflowing": len(over), "displaced": len(displaced), "by_origin": by_origin, "kinds": dict(kinds),
               "museum_works": museum_all, "museum_overflowing": museum_over,
               "non_museum_overflowing": len(over) - museum_over,
               "extensions_outside": sum(1 for r in rows if r.get("extension")),
               "fit": dict(Counter(r["fit"] for r in over)),
               "tokens_overflowing": len(by_token),
               "notes": dict(Counter(n.split(" (")[0].split(" ")[0] + " " + (n.split(" ")[1] if n.startswith(("over", "column")) else "") for r in rows for n in r["notes"]))}
    (OUT / "report.json").write_text(json.dumps({"summary": summary, "overflowing": over, "displaced": displaced,
        "by_token": {t: [{"floor": r["floor"], "id": r["id"]} for r in v] for t, v in sorted(by_token.items(), key=lambda kv: -len(kv[1]))}},
        indent=1, ensure_ascii=False), encoding="utf-8")
    md = ["# Works overflowing the Void tower", "", "Measured %d works on %d floors in the built tower." % (len(rows), len(floors)), "",
          "| | count |", "|---|---|"]
    for k, v in summary.items():
        if not isinstance(v, dict): md.append("| %s | %s |" % (k, v))
    md += ["", "Overflow kinds: " + ", ".join("%s %d" % kv for kv in kinds.items()), "Remedy class: " + ", ".join("%s %d" % kv for kv in summary["fit"].items()), "",
           "| floor | map | work | token | museum | size m | overflow | fit | scale here | largest part |", "|---|---|---|---|---|---|---|---|---|---|"]
    for r in sorted(over, key=lambda r: (r["floor"], r["id"])):
        part = (r.get("parts") or [{}])[0]
        md.append("| %d | %s | %s | %s | %s | %s | %s | %s | %s | %s %s m |" % (r["floor"], r["map"], r["id"], r["token"], "yes" if r["museum"] else "",
                  " x ".join("%.1f" % v for v in r["size"]), "; ".join(r["overflow"]), r["fit"], r["fit_scale_here"],
                  part.get("name", ""), part.get("extent", "")))
    (OUT / "report.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    print(json.dumps(summary, indent=1))
    if "--markdown" in args: print("\n".join(md))


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf8")
    {"run": run, "report": report}[sys.argv[1]](sys.argv[2:])
