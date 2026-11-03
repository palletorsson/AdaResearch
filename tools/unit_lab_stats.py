"""The numbers behind The Unit's Experiments 1 and 2 report, computed from the lab's run files.

Reads ada_run/workstation/unit_lab/exp1 and exp2 (commons/testing/unit_lab.gd) and prints, per arm: the capability
test counts; true medians and ranges of the settled force, the settled and whole-run peaks, the rod's turning in the
window; the SPAN of the link middle's path (whole run and settled window - the measure of reach); the settle time (the
last moment the force exceeded 0.5 N); how many runs peak above the wheels' 25 N grip; footprint overlap (the model
has no contact force, so overlapping chassis pass through each other); the shortest cord in the window; the cord's
last tug; and for keep, the runs where the controller is idle in the window (cord slack, command = programme).
Also: each unit's realised rates against its programme across the runs (in %) and the largest in-window deviation;
when each run's force peaks and how high it goes in the first 300 s; the median force per 2-minute block (how long a
relation takes to form); the final pose (heading and hub differences, and how far apart the two turning centres are -
0 m is one shared circle, equal headings and hubs are translates); the footprint-overlap episodes (first and last
overlapping sample); the last moment anything acts (a realised rate off the programme); how the joined test's count
moves if its lower band edge is 0.90 m instead of 0.85 m (from the 0.5 s samples); and for exp2h (the hold test) the
timings after the event and which kicked runs are bit-for-bit the same with the sensing on and cut; for expf (the
steer and rhythm families) how far each run's twin - unit 2 moved 1 micrometre - ends from it, and when they part by 1 cm.
Tension times come from the 0.5 s samples, so a graze shorter than a sample can be missed.

Usage: python tools/unit_lab_stats.py [lab dir]  - read-only, deterministic.
"""
import json, math, os, sys
import numpy as np

V0, W0, H0 = .15, .25, 1.0
PRESETS = {"steer": (.25, .2, 1.6), "rhythm": (.10, .09, 1.2)}   # expf's programmes (unit_lab.gd PRESETS), named after '@' in the arm


def programme(controller):
    """The (v0, w0, h0) an arm runs: the default, or the preset named after '@' in its controller name."""
    return PRESETS.get(controller.partition("@")[2].partition("~")[0], (V0, W0, H0))


def load_runs(d):
    s = json.load(open(os.path.join(d, "summary.json"), encoding="utf-8"))
    out = []
    for r in s["runs"]:
        tr = json.load(open(os.path.join(d, r["name"] + ".json"), encoding="utf-8"))
        r["_trace"] = tr
        out.append(r)
    return s, out


def med_range(vals, fmt="%.2f"):
    v = np.array(vals, dtype=float)
    return (fmt + " (" + fmt + "-" + fmt + ")") % (np.median(v), v.min(), v.max())


def corners(x, z, th):
    c, s = math.cos(th), math.sin(th)
    return [(x + px * c - pz * s, z + px * s + pz * c) for px, pz in ((-.09, -.25), (.33, -.25), (.33, .25), (-.09, .25))]


def overlap(a, b):
    """The lab's separating-axis test on the two footprints (unit_lab.gd _overlap)."""
    ca, cb = corners(*a), corners(*b)
    for th in (a[2], b[2]):
        for ax in ((math.cos(th), math.sin(th)), (-math.sin(th), math.cos(th))):
            pa = [ax[0] * q[0] + ax[1] * q[1] for q in ca]; pb = [ax[0] * q[0] + ax[1] * q[1] for q in cb]
            if max(pa) < min(pb) or max(pb) < min(pa):
                return False
    return True


def per_run(r, window):
    tr = r["_trace"]; f = {k: i for i, k in enumerate(tr["fields"])}
    v0, w0, h0 = programme(r["controller"])
    a = np.array(tr["trace"], dtype=float)
    t = a[:, f["t"]]; T = tr["T"]; late = t >= T - window
    m = r["metrics"]
    span_all = max(m["tool_extent_m"]); span_win = m["tool_span_window_m"]  # the lab's per-tick measure, as on the posters
    ten = np.abs(a[:, f["tension"]])
    over = np.where(ten > .5)[0]
    settle = float(t[over[-1]]) if len(over) else 0.0
    tug = np.where(a[:, f["tension"]] > 0)[0]
    last_tug = float(t[tug[-1]]) if len(tug) else None
    link = a[:, f["link"]]
    off = np.zeros(len(t), dtype=bool); big = np.zeros(len(t), dtype=bool); dev_win = 0.0
    for u in "01":
        dev = np.maximum.reduce([np.abs(a[:, f["v" + u]] - v0), np.abs(a[:, f["w" + u]] - w0), np.abs(a[:, f["h" + u]] - h0)])
        off |= dev > 1e-6; big |= dev > 1e-3; dev_win = max(dev_win, float(dev[late].max()))
    idle = bool(np.all(a[late, f["tension"]] <= 0) and not off[late].any())  # both units, all three rates on the programme
    acts = np.where(off)[0]; swings = np.where(big)[0]
    early = t < 300
    peak_k = int(np.argmax(ten))
    # the final pose: heading and hub-direction differences, and how far apart the two turning centres are
    # (0 apart: one shared circle; headings and hubs equal: translates)
    e = a[-1]
    wrapd = lambda x: math.degrees((x + math.pi) % (2 * math.pi) - math.pi)
    centre = lambda u: (e[f["x" + u]] - e[f["v" + u]] / e[f["w" + u]] * math.sin(e[f["th" + u]]), e[f["z" + u]] + e[f["v" + u]] / e[f["w" + u]] * math.cos(e[f["th" + u]]))
    c0, c1 = centre("0"), centre("1")
    pose = (round(wrapd(e[f["th0"]] - e[f["th1"]]), 2), round(wrapd(e[f["th0"]] + e[f["ph0"]] - e[f["th1"]] - e[f["ph1"]]), 2), round(math.hypot(c0[0] - c1[0], c0[1] - c1[1]), 3))
    blocks = [float(ten[(t >= b) & (t < b + 120)].mean()) for b in range(0, int(T), 120)]
    ov = np.array([overlap((a[k, f["x0"]], a[k, f["z0"]], a[k, f["th0"]]), (a[k, f["x1"]], a[k, f["z1"]], a[k, f["th1"]])) for k in range(len(t))])
    oi = np.where(ov)[0]
    band90 = float(np.mean((link[late] >= .90) & (link[late] <= 1.008)))
    ev = float(tr.get("event_at", -1.0))
    after = np.where((t > ev) & (ten > .5))[0] if ev > 0 else []
    depart = round(float(t[after[0]] - ev), 1) if len(after) else None  # exp2h: how long after the kick or switch-off the force first passes 0.5 N
    return {"span_all": span_all, "span_win": span_win, "settle": settle, "last_tug": last_tug, "link_min_win": float(link[late].min()), "idle": idle,
            "last_act": float(t[acts[-1]]) if len(acts) else 0.0, "last_swing": float(t[swings[-1]]) if len(swings) else 0.0, "overlap": (float(t[oi[0]]), float(t[oi[-1]])) if len(oi) else None, "band90": band90,
            "depart": depart, "event_at": ev, "dev_win": dev_win, "peak_t": float(t[peak_k]), "early_peak": float(ten[early].max()), "pose": pose, "blocks": blocks,
            "kick_deg": float(tr.get("kick_deg", 0.0)), "trace": a}


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "ada_run/workstation/unit_lab"
    for exp in ("exp1", "exp2", "exp2h", "expf"):
        d = os.path.join(root, exp)
        if not os.path.exists(os.path.join(d, "summary.json")):
            continue
        s, runs = load_runs(d)
        win = s["window"]
        print("\n## %s  (%d runs, %d s each, settled window %d s)" % (exp, len(runs), s["T"], win))
        arms = []
        traces = {}
        for r in runs:
            k = (r["topology"], r["controller"])
            if k not in arms:
                arms.append(k)
        for k in arms:
            rs = [r for r in runs if (r["topology"], r["controller"]) == k]
            ms = [r["metrics"] for r in rs]
            pr = [per_run(r, win) for r in rs]
            n = len(rs)
            print("\n### %s + %s" % k)
            if "test_carry" in ms[0]:
                print("tests: carry %d/%d, bar %d/%d, joined %d/%d" % (sum(m["test_carry"] for m in ms), n, sum(m["test_bar"] for m in ms), n, sum(m["test_joined"] for m in ms), n))
            print("settled mean force N: " + med_range([m["tension_mean_window"] for m in ms], "%.3f"))
            print("settled peak N: " + med_range([m["tension_peak_window"] for m in ms], "%.1f") + "; whole-run peak N: " + med_range([m["tension_peak"] for m in ms], "%.1f")
                  + "; runs peaking above 25 N: %d" % sum(1 for m in ms if m["tension_peak"] > 25))
            print("whole-run peak per run N: %s, at s (0.5 s samples): %s; highest in the first 300 s N: %s"
                  % ([round(m["tension_peak"], 2) for m in ms], [p["peak_t"] for p in pr], [round(p["early_peak"], 2) for p in pr]))
            print("mean force per 2-minute block N, median over the runs: %s" % [round(float(np.median([p["blocks"][b] for p in pr])), 2) for b in range(len(pr[0]["blocks"]))])
            print("largest realised rate off the programme in the window: %.1e" % max(p["dev_win"] for p in pr))
            print("final pose (heading diff deg, hub diff deg, turning centres apart m): %s" % [p["pose"] for p in pr])
            print("span of the middle's path m, whole run: " + med_range([p["span_all"] for p in pr]) + "; settled window: " + med_range([p["span_win"] for p in pr]))
            print("settle (last |T| > 0.5 N) s: " + med_range([p["settle"] for p in pr], "%.1f"))
            if "rod_pp_window_deg" in ms[0]:
                print("rod turning in the window deg: " + med_range([m["rod_pp_window_deg"] for m in ms], "%.1f") + "  per run: %s" % [round(m["rod_pp_window_deg"], 1) for m in ms])
                print("footprint overlap, share of the window: %s" % [round(m["contact_ticks_window"] / (win * 120), 3) for m in ms] + "; runs with any overlap: %d" % sum(1 for m in ms if m["contact_ticks"] > 0))
                print("band share: %s" % [round(m["band_fraction_window"], 3) for m in ms])
            v0, w0, h0 = programme(k[1])
            pct = lambda key, p0: "%+.1f..%+.1f %%" % (min(100 * (x / p0 - 1) for m in ms for x in m[key]), max(100 * (x / p0 - 1) for m in ms for x in m[key]))
            fast = [max(m["v_mean_window"]) for m in ms]; slow = [min(m["v_mean_window"]) for m in ms]
            if "twin_div_end_m" in ms[0]:
                print("twin (unit 2 moved 1 micrometre): tool points apart at the end m %s; first 1 cm apart at s %s; sensitive (apart > 1 cm at the end): %d of %d"
                      % ([float("%.2g" % m["twin_div_end_m"]) for m in ms], [m["twin_div_1cm_s"] for m in ms], sum(1 for m in ms if m["twin_div_end_m"] > .01), n))
            print("rates in the window against the programme: hub %s, turn %s; the faster unit %+.1f..%+.1f %%, the slower %+.1f..%+.1f %%"
                  % (pct("h_mean_window", h0), pct("w_mean_window", w0), 100 * (min(fast) / v0 - 1), 100 * (max(fast) / v0 - 1), 100 * (min(slow) / v0 - 1), 100 * (max(slow) / v0 - 1)))
            print("last moment anything acts (a realised rate off the programme) s: %s; off by more than 0.001: %s" % ([p["last_act"] for p in pr], [p["last_swing"] for p in pr]))
            print("footprint overlap episodes (first, last overlapping sample s): %s" % [p["overlap"] for p in pr])
            if "test_joined" in ms[0]:
                j90 = sum(1 for m, p in zip(ms, pr) if m["test_joined"] and p["band90"] >= .95)
                print("joined with the band's lower edge at 0.90 m instead of 0.85 m: %d/%d" % (j90, n))
            print("shortest link in the window m: %s" % [round(p["link_min_win"], 3) for p in pr])
            for r, p in zip(rs, pr):
                traces[(k, r["start"])] = p["trace"]
            if pr[0]["event_at"] > 0:
                print("after the event at %d s (kick %.1f deg): force first above 0.5 N after (s) %s; last above 0.5 N after (s) %s"
                      % (pr[0]["event_at"], pr[0]["kick_deg"], [p["depart"] for p in pr], [round(p["settle"] - p["event_at"], 1) if p["settle"] > p["event_at"] else None for p in pr]))
                base, _, event = k[1].partition("~")
                if event == "cut~kick" and ((k[0], base + "~kick"), rs[0]["start"]) in traces:
                    same = [r["start"] for r in rs if np.array_equal(traces[((k[0], base + "~kick"), r["start"])], traces[(k, r["start"])])]
                    print("bit-for-bit the same as with the sensing left on (%s~kick): %d of %d - %s" % (base, len(same), n, same))
            if k[0] == "tendon":
                print("last tug s: %s" % [p["last_tug"] for p in pr] + "; controller idle and cord slack all window: %d of %d" % (sum(p["idle"] for p in pr), n))


if __name__ == "__main__":
    main()
