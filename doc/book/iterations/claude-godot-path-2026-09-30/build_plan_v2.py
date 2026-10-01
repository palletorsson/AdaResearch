"""Build and validate PLAN.md and godot_path.json from plan_stops_v2.py + plan_template_v2.md.
Read-only against the repo: it reads curriculum.json and two git-status snapshots saved in this folder."""
import json, os, sys, io, collections
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = "C:/Users/palle/Documents/GitHub/AdaResearch_46"
sys.path.insert(0, HERE)
from plan_stops_v2 import STOPS, CHECKPOINTS, CAPS, EXTRA_REQUIRES, EXCEPTIONS, OPTIONAL_FIRST

CHECKED = "2026-09-30"
survey = json.load(open(os.path.join(HERE, "survey_bundle.json"), encoding="utf-8"))
spines = json.load(open(os.path.join(HERE, "c2_spine.json"), encoding="utf-8"))
curr = json.load(open(os.path.join(REPO, "doc/book/tutorial-lineage/curriculum.json"), encoding="utf-8"))
tracked_tut = set(l.strip() for l in open(os.path.join(HERE, "tracked_tutorials.txt"), encoding="utf-8") if l.strip())
tut_status = {}
for l in open(os.path.join(HERE, "tutorial_status.txt"), encoding="utf-8"):
    if l.strip():
        st, path = l[:2].strip(), l[3:].strip()
        tut_status[path] = st

SPINE = [s for s, _ in spines["WT"]]
WT = dict(spines["WT"]); HEAD = dict(spines["HEAD"])
head_halls = set(h for v in HEAD.values() for h in v)
wt_halls = set(h for v in WT.values() for h in v)

REQ = {c["id"]: c["requires"] for c in survey["godot"]["capabilities"]}
REQ.update(EXTRA_REQUIRES)
DOC = {c["id"]: c.get("doc", "") for c in survey["godot"]["capabilities"]}
MCG = survey["godot"]["minimum_complete_game"]
HALL = {h["map"]: h for h in survey["halls"]}
KIND = {}
for n in curr["nodes"]:
    for h in n.get("halls", []):
        KIND.setdefault(h, []).append((n["id"], n["kind"]))
DEPTH = {"use": 1, "understand": 2, "change": 3}

errors, warnings = [], []
ids = [s["id"] for s in STOPS]
if len(ids) != len(set(ids)):
    errors.append("duplicate stop ids")
idx = {sid: i for i, sid in enumerate(ids)}

# ---------- hall order (working tree)
hall_pos = {}
for si, (seq, halls) in enumerate(spines["WT"]):
    for pi, h in enumerate(halls):
        hall_pos[h] = (si, pi + 1)
last = (-1, -1)
for s in STOPS:
    if s["kind"] == "hall":
        p = hall_pos.get(s["halls"][0])
        if p is None:
            errors.append(f"hall not in working-tree spine: {s['id']}"); continue
        if p < last:
            errors.append(f"hall out of walking order: {s['id']} {p} < {last}")
        last = p
    if s["kind"] != "checkpoint" and s["seq"] != "preface":
        for h in s["halls"]:
            if h not in hall_pos:
                errors.append(f"unknown hall {h} at {s['id']}")
    for k in ("route", "track", "starter"):
        if k not in s:
            errors.append(f"{s['id']} lacks {k}")

# ---------- first meetings
first = {}
for s in STOPS:
    for c in s.get("new", []) + s.get("boundary", []):
        if c in first:
            errors.append(f"{c} introduced twice: {first[c]} and {s['id']}")
        first[c] = s["id"]
missing = set(CAPS) - set(first); extra = set(first) - set(CAPS)
if missing: errors.append(f"caps without first stop: {sorted(missing)}")
if extra: errors.append(f"caps not in CAPS: {sorted(extra)}")
vocab = set(c["id"] for c in survey["godot"]["capabilities"])
unplaced = sorted(vocab - set(CAPS))
if unplaced: errors.append(f"vocabulary ids not placed: {unplaced}")

byid = {s["id"]: s for s in STOPS}
track_of = lambda sid: byid[sid].get("track", "main")
route_of = lambda sid: byid[sid].get("route", "both")

returns = collections.defaultdict(list)
for s in STOPS:
    for c in s.get("ret", []):
        if c not in CAPS:
            errors.append(f"unknown capability in returns: {c} at {s['id']}"); continue
        if c in first and idx[s["id"]] <= idx[first[c]]:
            errors.append(f"{c} returns at {s['id']} before/at its first stop {first[c]}")
        returns[c].append(s["id"])
    for c in s.get("deep", {}):
        if c not in s.get("new", []) + s.get("ret", []):
            errors.append(f"deep key {c} at {s['id']} is neither new nor returning there")

# ---------- prerequisite order
violations = {}
for c, fs in first.items():
    bad = []
    for r in REQ.get(c, []):
        if r not in first:
            bad.append(r + "(never)")
        elif idx[first[r]] > idx[fs]:
            bad.append(f"{r}@{first[r]}")
    if bad:
        violations[c] = bad
        if c not in EXCEPTIONS:
            errors.append(f"UNEXPLAINED requires violation: {c}@{fs} needs {bad}")
for c in EXCEPTIONS:
    if c not in violations:
        errors.append(f"exception listed but no violation: {c}")

# ---------- depth: every meeting, with the depth it sets
meet = collections.defaultdict(list)   # cap -> [(stop_index, depth or None)]
for i, s in enumerate(STOPS):
    for c in s.get("new", []):
        d = s.get("deep", {}).get(c, CAPS[c][0])
        if s.get("deep", {}).get(c) and s["deep"][c] != CAPS[c][0]:
            errors.append(f"{c}: first-meeting depth {s['deep'][c]} at {s['id']} differs from CAPS {CAPS[c][0]}")
        meet[c].append((i, d))
    for c in s.get("ret", []):
        meet[c].append((i, s.get("deep", {}).get(c)))
depth_notes = []
for c, ms in meet.items():
    reached = 0
    for i, d in ms:
        if d is None:
            continue
        if DEPTH[d] == 3 and reached < 2:
            errors.append(f"depth jump: {c} at 'change' in {STOPS[i]['id']} with no earlier 'understand' meeting")
        if DEPTH[d] == 3:
            for r in REQ.get(c, []):
                rr = max([DEPTH[dd] for j, dd in meet.get(r, []) if dd and j < i] or [0])
                if rr < 2:
                    depth_notes.append(f"{c} reaches 'change' at {STOPS[i]['id']} while its prerequisite {r} has reached only {['nothing','use','understand','change'][rr]}")
        reached = max(reached, DEPTH[d])

def max_depth(c, main_only=True):
    best = 0; where = None
    for i, d in meet.get(c, []):
        if d and (not main_only or STOPS[i].get("track") == "main") and DEPTH[d] > best:
            best, where = DEPTH[d], STOPS[i]["id"]
    return (["-", "use", "understand", "change"][best], where)

# ---------- branch and route dependence
for s in STOPS:
    if s.get("track") != "main":
        continue
    uses = list(s.get("ret", [])) + [r for n in s.get("new", []) for r in REQ.get(n, [])]
    for c in uses:
        f = first.get(c)
        if f and track_of(f) != "main":
            errors.append(f"main stop {s['id']} uses {c}, first met only on branch stop {f}")
        if c in OPTIONAL_FIRST and s["id"] != OPTIONAL_FIRST[c]:
            errors.append(f"main stop {s['id']} uses {c}, first met only as an optional step at {OPTIONAL_FIRST[c]}")
for c, (d, place, route) in CAPS.items():
    f = first.get(c)
    if f and route_of(f) == "xr" and route != "xr":
        errors.append(f"{c} is first met on an xr-route stop ({f}) but is not itself an xr capability")
    if route == "xr":
        for i, _ in meet.get(c, []):
            if STOPS[i].get("route") == "desktop":
                errors.append(f"xr capability {c} met at desktop-route stop {STOPS[i]['id']}")
for s in STOPS:
    if s.get("route") in ("desktop", "both"):
        for n in s.get("new", []):
            for r in REQ.get(n, []):
                if CAPS.get(r, (0, 0, "both"))[2] == "xr" and n not in EXCEPTIONS:
                    errors.append(f"{n} at {s['id']} requires xr capability {r}")

# ---------- minimum complete game by CP3
cp3 = idx["CP3_playable_room"]
mcg_late = [c for c in MCG if c not in first or idx[first[c]] > cp3]
if mcg_late:
    errors.append(f"minimum-complete-game capabilities after CP3: {mcg_late}")

# ---------- derived per-stop fields
FORM2STATUS = {"runnable-study": "runnable", "script-fragments": "fragment-rewrite", "prose-only": "prose-rewrite", "missing": "new-page"}
LESSON_NOTES = {
 "day_zero": "Desktop part runnable from the kit; the Quest route is prose, unverified.",
 "Point_Coordinates": "Desktop study runnable; the pickup step needs the course project (XR Tools on disk, gitignored) and point_held.tscn (untracked); a portable XR starter is still to be supplied.",
 "Point_Lines": "Runnable and desktop-tested; the distance_between variation is a proposed addition that needs a native re-run.",
 "Point_One": "Runnable in the working tree; HEAD has the older fragment page.",
 "Random_Definition": "Runnable as a worked example; the my_room step is new writing.",
 "Point_Trace": "The list-first rewrite is curriculum issue trace-list; mover.gd and the line-strip helper are to be built.",
}
def tutorial_git(h):
    p = f"commons/maps/{h}/tutorial.md"
    if tut_status.get(p) == "??": return "untracked"
    if p in tracked_tut: return "modified" if tut_status.get(p) == "M" else "tracked"
    return "none"

def status_of(s):
    if s.get("status"): return s["status"]
    if s["id"] == "day_zero": return "runnable"
    if s["kind"] != "hall": return "new-page"
    return FORM2STATUS[HALL[s["halls"][0]]["tutorial_form"]]

def startable(v):
    return bool(v) and "to be built" not in v

derived = {}
for i, s in enumerate(STOPS):
    h = s["halls"][0] if s["halls"] else None
    o = {}
    o["lesson_status"] = status_of(s)
    o["lesson_note"] = LESSON_NOTES.get(s["id"], "")
    o["curriculum_kind"] = ", ".join(f"{k} ({n})" for n, k in KIND.get(h, [])) if (s["kind"] == "hall" and h) else None
    o["hall_in_head_walk"] = (h in head_halls) if h else None
    o["tutorial_git"] = tutorial_git(h) if (s["kind"] == "hall" and h) else None
    o["new_in_current_tutorial"] = sorted(set(s.get("new", [])) & set(HALL[h]["teaches"])) if (s["kind"] == "hall" and h in HALL) else []
    st = s["starter"]
    o["startable_at_head"] = startable(st.get("head"))
    o["startable_in_working_tree"] = startable(st.get("working_tree"))
    tags = []
    if h and h not in head_halls: tags.append("WT only")
    if not o["startable_at_head"]: tags.append("not startable at HEAD")
    if not o["startable_in_working_tree"]: tags.append("not startable until its parts are built")
    if s.get("route") == "xr": tags.append("xr route")
    if s.get("track") == "branch": tags.append("branch")
    o["tags"] = tags
    derived[s["id"]] = o

status_totals = collections.Counter(derived[s["id"]]["lesson_status"] for s in STOPS)
hall_status_totals = collections.Counter(derived[s["id"]]["lesson_status"] for s in STOPS if s["kind"] == "hall")
teachable = [s["id"] for s in STOPS if derived[s["id"]]["lesson_status"] == "runnable" and derived[s["id"]]["startable_in_working_tree"]]
not_head = [s["id"] for s in STOPS if not derived[s["id"]]["startable_at_head"]]
wt_only = [s["id"] for s in STOPS if "WT only" in derived[s["id"]]["tags"]]
no_new_supported = [s["id"] for s in STOPS if s["kind"] == "hall" and s.get("new") and not derived[s["id"]]["new_in_current_tutorial"]]

# ---------- JSON
stops_json = []
for i, s in enumerate(STOPS):
    d = derived[s["id"]]
    o = dict(index=i, id=s["id"], kind=s["kind"], sequence=s["seq"], halls=s["halls"], title=s["title"], track=s.get("track", "main"),
             route=s.get("route", "both"), curriculum_kind=d["curriculum_kind"], lesson_status=d["lesson_status"],
             lesson_status_checked=CHECKED, lesson_note=d["lesson_note"], starter=s["starter"],
             startable_at_head=d["startable_at_head"], startable_in_working_tree=d["startable_in_working_tree"],
             hall_in_head_walk=d["hall_in_head_walk"], tutorial_git=d["tutorial_git"], tags=d["tags"], session_estimate=None)
    if s["kind"] == "checkpoint":
        cp = CHECKPOINTS[s["id"]]
        o.update(after=cp["after"], criteria=cp["criteria"], open_task=cp["open_task"], evidence=cp["evidence"], course_exit=cp["exit"], basis=cp["basis"])
    else:
        o.update(new=s.get("new", []), returns=s.get("ret", []), names_boundary=s.get("boundary", []),
                 depth={c: s.get("deep", {}).get(c, CAPS[c][0] if c in s.get("new", []) else None) for c in s.get("new", []) + s.get("ret", [])},
                 new_in_current_tutorial=d["new_in_current_tutorial"],
                 make=s["make"], learner_room=s["room"],
                 borrows=[{"part": p, "depth": dd} for p, dd in s.get("borrows", [])],
                 check=s["check"], contrast=s["contrast"], carries=s["carries"], basis=s["basis"])
        if s["kind"] == "workshop":
            o["reason"] = s.get("reason", "")
    stops_json.append(o)

caps_json = []
for c in sorted(CAPS, key=lambda c: (idx[first[c]], c)):
    depth, place, route = CAPS[c]
    o = dict(id=c, first_stop=first[c], placement=place, route=route, requires=REQ.get(c, []), returns=returns.get(c, []))
    if depth: o["depth_at_first"] = depth
    md, where = max_depth(c)
    o["max_depth_on_main"] = md; o["max_depth_first_at"] = where
    o["depth_by_stop"] = [[STOPS[i]["id"], dd] for i, dd in meet.get(c, [])]
    if c in OPTIONAL_FIRST: o["first_meeting_optional"] = True
    if c in violations:
        o["requires_after_first_stop"] = violations[c]; o["why"] = EXCEPTIONS[c]
    if DOC.get(c): o["doc"] = DOC[c]
    caps_json.append(o)

workshops_json = [dict(id=s["id"], at_hall=(s["halls"][0] if s["halls"] else None), sequence=s["seq"], title=s["title"],
                       track=s.get("track", "main"), route=s.get("route"), reason=s.get("reason", ""), new=s.get("new", []), returns=s.get("ret", []),
                       make=s["make"], check=s["check"], contrast=s["contrast"], basis=s["basis"])
                  for s in STOPS if s["kind"] == "workshop"]
checkpoints_json = [dict(id=s["id"], at_hall=s["halls"][0], sequence=s["seq"], title=s["title"], **{k: v for k, v in CHECKPOINTS[s["id"]].items()})
                    for s in STOPS if s["kind"] == "checkpoint"]

head_wt_rows = []
for seq in SPINE:
    a, b = WT[seq], HEAD.get(seq, [])
    wo = [x for x in a if x not in b]; ho = [x for x in b if x not in a]
    order = [x for x in a if x in b] != [x for x in b if x in a]
    if wo or ho or order:
        head_wt_rows.append(dict(sequence=seq, working_tree=len(a), head=len(b), working_tree_only=wo, head_only=ho, order_differs=order))

ID_MAP = [("W01_scene_from_nothing", "W02_scene_from_nothing", "moved after CP1; camera, WorldEnvironment and material moved out"),
          ("W02_known_revision", "W03_known_revision", "moved after CP1"),
          ("W03_break_it_on_purpose", "W01_break_it_on_purpose", "same place; adds class-reference lookup and an @onready fault"),
          ("W04_signal_and_door", "W05_signal_and_door", "same hall; reason restated"),
          ("W05_import_one_thing", "W04_import_one_thing", "moved from Melencolia to Primitives_Ignorance"),
          ("W06_export_it", "W06_export_it", "same"),
          ("W07_body_and_camera", "W07_body_and_camera", "adds input rules and the 'player' group"),
          ("W08_room_in_headset", "W08_headset_day + W09_room_in_headset", "split; xr route"),
          ("W09_menu_pause_retry", "W10_pause_and_retry + W13_settings", "split; settings moved to Color_Grid_Pallet"),
          ("W10_two_rooms", "W11_two_rooms", "same"),
          ("W11_particles", "W12_particles", "basis corrected; now a comparison"),
          ("-", "W14_game_in_headset", "new; xr route"),
          ("-", "W15_many_rooms", "new"),
          ("W12_checks_without_you", "W16_checks_without_you", "adds an in-editor route and the Windows console note"),
          ("W13_character_studio", "W17_character_studio", "same (branch)"),
          ("W14_release", "W18_release", "takes the versioned atomic save")]

counts = collections.Counter(s["kind"] for s in STOPS)
making_halls = counts["hall"]
place_counts = collections.Counter(v[1] for v in CAPS.values())
branch_halls = sum(1 for s in STOPS if s["kind"] == "hall" and s.get("track") == "branch")
reflect_optional = [s["id"] for s in STOPS if s["kind"] == "hall" and s.get("track") == "branch" and "reflect" in (derived[s["id"]]["curriculum_kind"] or "")]
xr_stops = [s["id"] for s in STOPS if s.get("route") == "xr"]
both_stops = [s["id"] for s in STOPS if s.get("route") == "both" and s["kind"] != "checkpoint"]
heavy = [(s["id"], n) for s in STOPS for n in [len([c for c in s.get("new", []) if OPTIONAL_FIRST.get(c) != s["id"]])] if n >= 4]
summary = dict(stops=len(STOPS), kinds=dict(counts), making_halls=making_halls, branch_halls=branch_halls,
               workshops=counts["workshop"], checkpoints=counts["checkpoint"], caps=len(CAPS),
               placement=f"{place_counts['main']} main, {place_counts['branch']} branch, {place_counts['outside']} outside",
               exceptions=len(EXCEPTIONS), lesson_status=dict(status_totals), hall_lesson_status=dict(hall_status_totals),
               teachable_today=teachable, not_startable_at_head=not_head, wt_only=wt_only, xr_route=xr_stops)

out = dict(
  title="Godot making path through Ada Research",
  date=CHECKED,
  status="PROPOSED plan, revised after review. Built from survey_bundle.json and re-measured facts (working tree unless stated). No tutorial, study kit or curriculum.json was changed. Not tested with a learner, not run in Godot.",
  state=("Hall order is the WORKING TREE spine: 25 sequences, 204 halls. HEAD's spine has 196 halls. 15 working-tree halls are absent at HEAD "
         "(Point_Zero, Point_Coordinates, Tutorial_3D, Tutorial_Tiling_Floor, Tutorial_Tiling_Walls, Color_Flashlight, Color_Rainbow, Color_Grid_Pallet, Color_Paint, "
         "Pattern_Disco, Ribbon_Patterns_01-03, Change_Choreography, LSystems_Shape_Grammars) and 7 HEAD halls are absent from the working tree "
         "(Trans_AxisDecomposition, Trans_RotationSpectacle, Accumulation_Riemann, Change_Reconciliation, Fractal_JuliaSet, Fractal_MandelbrotSet, Fractal_CrossSequence). "
         "24 of the 25 spine sequence files are modified in the working tree; their hall lists differ in 9 and only the order differs in 2 (proceduralgeneration, softbodies). "
         f"{len(wt_only)} stops of this path sit at working-tree-only halls: {', '.join(wt_only)}."),
  learner_project=("Two working places. The Ada course project (this repository, with XR Tools on disk) for held and walked encounters on the xr route; "
                   "and my_room, the learner's own Godot 4.6 project, created empty at W02 and carried to a release. Before W02 the learner works in copies of the opening study kits."),
  desktop_only_exception=("A desktop-only cohort skips the xr route (the headset part of day_zero, the pickup steps of Point_Coordinates, W08, W09, W14 and the xr steps of later stops). "
                          "No desktop-route stop depends on them (checked by the build). Such a cohort does not meet the project's primary medium, and says so."),
  short_course="Stops 0 to 30 (Day Zero to CP3). Every capability of the survey's 33-item minimum complete game is first met in it (checked by the build).",
  depth_levels={"use": "can operate it", "understand": "has opened it and can explain it", "change": "can change or replace it independently"},
  lesson_status_levels={"runnable": "a runnable study covers the stop's core make", "fragment-rewrite": "the tutorial has script fragments that need rewriting into steps",
                        "prose-rewrite": "the tutorial is prose; the steps must be written", "new-page": "no page exists (workshops, checkpoints, halls without tutorial.md)"},
  summary=summary, head_vs_working_tree=head_wt_rows,
  id_map_from_draft=[dict(draft=a, final=b, change=c) for a, b, c in ID_MAP],
  stops=stops_json, capabilities=caps_json, workshops=workshops_json, checkpoints=checkpoints_json)
json.dump(out, open(os.path.join(HERE, "godot_path.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)

# ---------- Markdown fragments
def caps_str(lst, s=None):
    if not lst: return "none"
    parts = []
    for c in lst:
        d = (s or {}).get("deep", {}).get(c)
        parts.append(f"`{c}`" + (f" ({d})" if d else ""))
    return ", ".join(parts)

stop_halls = set(s["halls"][0] for s in STOPS if s["kind"] == "hall")

def header_tags(s):
    d = derived[s["id"]]
    bits = [s["kind"]]
    if s.get("track") == "branch": bits.append("optional studio" if s["kind"] == "hall" else "branch")
    if s.get("route") == "xr": bits.append("xr route")
    elif s.get("route") == "both" and s["kind"] != "checkpoint": bits.append("desktop + xr steps")
    if "WT only" in d["tags"]: bits.append("WT only")
    if not d["startable_in_working_tree"]: bits.append("not startable until its supplied parts are built")
    elif not d["startable_at_head"]: bits.append("not startable at HEAD")
    return ", ".join(bits)

def render_stop(s):
    i = idx[s["id"]]; d = derived[s["id"]]
    at = f" at `{s['halls'][0]}`" if s["kind"] in ("workshop", "checkpoint") and s["halls"] else ""
    lines = [f"**{i:02d} · {s['id']}**{at} ({header_tags(s)}): {s['title']}"]
    if s["kind"] == "checkpoint":
        cp = CHECKPOINTS[s["id"]]
        for c in cp["criteria"]:
            lines.append(f"- {c}")
        lines.append(f"- Open task: {cp['open_task']}")
        lines.append(f"- Evidence: {'; '.join(cp['evidence'])}.")
        if cp["exit"]:
            lines.append(f"- Course exit: {cp['exit']}.")
        lines.append(f"- Basis: {cp['basis']}")
        return "\n".join(lines)
    stat = f"- Lesson: {d['lesson_status']}"
    if d["curriculum_kind"]: stat += f"; curriculum kind {d['curriculum_kind']}"
    if d["tutorial_git"]: stat += f"; tutorial.md {d['tutorial_git']}"
    stat += f". Starts from: {s['starter']['working_tree'] or 'nothing yet'}" + ("" if (d["startable_at_head"] or not d["startable_in_working_tree"]) else f" (at HEAD: {s['starter']['head'] or 'absent'})") + "."
    if d["lesson_note"]: stat += " " + d["lesson_note"]
    lines.append(stat)
    if s["kind"] == "workshop" and s.get("reason"):
        lines.append(f"- Why here: {s['reason']}")
    lines.append(f"- New: {caps_str(s.get('new', []), s)}. Returns: {caps_str(s.get('ret', []), s)}." + (f" Names as outside: {caps_str(s['boundary'])}." if s.get("boundary") else ""))
    lines.append(f"- Make (worked example): {s['make']}")
    if s["room"]:
        lines.append(f"- In the learner's own work: {s['room']}")
    if s.get("borrows"):
        lines.append("- Borrows: " + "; ".join(f"{p} ({dd})" for p, dd in s["borrows"]) + ".")
    chk = f"- Check: {s['check']}"
    if s["contrast"]:
        chk += f" Contrast: {s['contrast']}"
    lines.append(chk)
    lines.append(f"- Carries forward: {s['carries']}")
    lines.append(f"- Basis: {s['basis']}")
    return "\n".join(lines)

seq_blocks = {}
for seq in ["preface"] + SPINE:
    ss = [s for s in STOPS if s["seq"] == seq]
    txt = "\n\n".join(render_stop(s) for s in ss)
    if seq in WT:
        enc = [m for m in WT[seq] if m not in stop_halls and not any(m in s["halls"] for s in ss)]
        if enc:
            txt += "\n\nEncounters without a making lesson in this path: " + ", ".join(f"`{m}`" for m in enc) + "."
    seq_blocks[seq] = txt

cov_rows = ["| capability | first stop | depth at first | deepest on main (where) | placement | route | returns at | requires met? |", "|---|---|---|---|---|---|---|---|"]
for o in caps_json:
    req_ok = "yes" if "requires_after_first_stop" not in o else "no, see A.1"
    rets = ", ".join(o["returns"]) if o["returns"] else "none"
    md = o["max_depth_on_main"] + (f" ({o['max_depth_first_at']})" if o["max_depth_first_at"] else "")
    fs = o["first_stop"] + (" (optional step)" if o.get("first_meeting_optional") else "")
    cov_rows.append(f"| `{o['id']}` | {fs} | {o.get('depth_at_first', '-')} | {md} | {o['placement']} | {o['route']} | {rets} | {req_ok} |")
coverage = "\n".join(cov_rows)

exceptions_md = "\n".join(f"- `{c}` at {first[c]}: requires {', '.join(violations[c])}. {why}" for c, why in EXCEPTIONS.items())

stop_index = ["| # | stop | kind | sequence | at hall | route | lesson | HEAD | new capabilities |", "|---|---|---|---|---|---|---|---|---|"]
for i, s in enumerate(STOPS):
    d = derived[s["id"]]
    k = s["kind"] + (" (optional)" if s.get("track") == "branch" else "")
    hd = "WT only" if "WT only" in d["tags"] else ("not startable" if not d["startable_at_head"] else "ok")
    stop_index.append(f"| {i} | {s['id']} | {k} | {s['seq']} | {s['halls'][0] if s['halls'] else '-'} | {s.get('route')} | {d['lesson_status']} | {hd} | {', '.join(s.get('new', [])) or '-'} |")
stop_index_md = "\n".join(stop_index)

hw = ["| sequence | halls WT / HEAD | working-tree only | HEAD only | order differs |", "|---|---|---|---|---|"]
for r in head_wt_rows:
    hw.append(f"| {r['sequence']} | {r['working_tree']} / {r['head']} | {', '.join(r['working_tree_only']) or '-'} | {', '.join(r['head_only']) or '-'} | {'yes' if r['order_differs'] else '-'} |")
head_wt_md = "\n".join(hw)

# writing load per segment between checkpoints
segs = []; cur = []; start = 0
for i, s in enumerate(STOPS):
    cur.append(s)
    if s["kind"] == "checkpoint" or i == len(STOPS) - 1:
        segs.append((start, i, cur)); cur = []; start = i + 1
seg_rows = ["| segment | stops | main | runnable | fragment-rewrite | prose-rewrite | new-page | kits or helpers to build |", "|---|---|---|---|---|---|---|---|"]
for a, b, ss in segs:
    main = [s for s in ss if s.get("track") == "main"]
    c = collections.Counter(derived[s["id"]]["lesson_status"] for s in main)
    tb = [s["id"] for s in main if not derived[s["id"]]["startable_in_working_tree"]]
    seg_rows.append(f"| {STOPS[a]['id']} to {STOPS[b]['id']} | {a}-{b} | {len(main)} | {c['runnable']} | {c['fragment-rewrite']} | {c['prose-rewrite']} | {c['new-page']} | {', '.join(tb) or '-'} |")
seg_md = "\n".join(seg_rows)

idmap_md = "\n".join(["| draft id | final id | change |", "|---|---|---|"] + [f"| {a} | {b} | {c} |" for a, b, c in ID_MAP])

kind_rows = ["| stop | curriculum kind | in this plan |", "|---|---|---|"]
for s in STOPS:
    k = derived[s["id"]]["curriculum_kind"]
    if k and "reflect" in k:
        kind_rows.append(f"| {s['id']} | {k} | {'optional studio' if s.get('track') == 'branch' else 'main, no new code'} |")
kind_md = "\n".join(kind_rows)

status_line = ", ".join(f"{k} {v}" for k, v in sorted(status_totals.items(), key=lambda kv: -kv[1]))
hall_status_line = ", ".join(f"{k} {v}" for k, v in sorted(hall_status_totals.items(), key=lambda kv: -kv[1]))

fills = {
 "STOPS": str(len(STOPS)), "MAKING_HALLS": str(making_halls), "BRANCH_HALLS": str(branch_halls),
 "REFLECT_OPTIONAL": str(len(reflect_optional)), "WORKSHOPS": str(counts["workshop"]), "CHECKPOINTS": str(counts["checkpoint"]),
 "ENCOUNTERS": str(204 - making_halls), "CAPS": str(len(CAPS)), "PLACEMENT": summary["placement"],
 "STATUS_TOTALS": status_line, "HALL_STATUS_TOTALS": hall_status_line,
 "TEACHABLE_TODAY": ", ".join(f"{idx[t]} `{t}`" for t in teachable),
 "NOT_HEAD": ", ".join(f"{idx[t]} `{t}`" for t in not_head),
 "WT_ONLY": ", ".join(f"{idx[t]} `{t}`" for t in wt_only), "WT_ONLY_N": str(len(wt_only)),
 "XR_STOPS": ", ".join(f"{idx[t]} `{t}`" for t in xr_stops), "BOTH_STOPS": ", ".join(f"{idx[t]} `{t}`" for t in both_stops),
 "NO_NEW_SUPPORTED": str(len(no_new_supported)),
 "HEAVY": ", ".join(f"`{a}` ({n})" for a, n in heavy),
 "HEAD_WT_TABLE": head_wt_md, "SEGMENT_LOAD": seg_md, "ID_MAP": idmap_md, "KIND_TABLE": kind_md,
 "COVERAGE": coverage, "EXCEPTIONS": exceptions_md, "STOP_INDEX": stop_index_md,
 "DEPTH_NOTES": "\n".join(f"- {n}" for n in depth_notes) or "- none",
}
tpl_path = os.path.join(HERE, "plan_template_v2.md")
if os.path.exists(tpl_path):
    tpl = open(tpl_path, encoding="utf-8").read()
    for seq, txt in seq_blocks.items():
        tpl = tpl.replace("{{SEQ:" + seq + "}}", txt)
    for k, v in fills.items():
        tpl = tpl.replace("{{" + k + "}}", v)
    left = [l for l in tpl.splitlines() if "{{" in l]
    if left: errors.append(f"unfilled placeholders: {left[:5]}")
    open(os.path.join(HERE, "PLAN.md"), "w", encoding="utf-8").write(tpl)

print(json.dumps(summary, indent=1))
print("heavy stops (>=4 new):", heavy)
print("hall stops whose new caps are not in the current tutorial:", len(no_new_supported), no_new_supported)
print("violations:", violations)
print("depth notes:", len(depth_notes)); [print("  ", n) for n in depth_notes]
print("ERRORS:" if errors else "OK", *errors, sep="\n")
