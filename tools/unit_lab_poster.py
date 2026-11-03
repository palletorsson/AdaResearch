"""A collection poster of The Unit's lab runs (commons/testing/unit_lab.gd), overhead, like specimen plates.

Palle, 2026-11-03: "can you make a collection poster of the experiment with overhead view". One row per arm (link
topology, and controller once Experiment 2 adds them), one column per start; every panel the same size and the same
scale, so the reach of each arm reads directly. In each panel: the two chassis paths (faint blue and red), the tool
point's trace (ink) and the final pose - both chassis, their pins and the link. Beside each row: the medians of the
span of the tool's path (the larger side of its bounding box, over the run and over the settled window - the measure
of reach; covered area is not one, since a path that never re-crosses itself covers more cells however small it
stays), the settled mean force and the turn rate.

Usage: python tools/unit_lab_poster.py ada_run/workstation/unit_lab/exp1 [more lab dirs...] --out=<png> [--half=2.7]
Reads only; deterministic.
"""
import json, math, os, sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

PAPER = "#f3efe6"
INK = "#1d2846"
U0, U1 = "#2f5fa8", "#c8402e"
ROW_LABEL = {"none": "no link\neach unit\non its own", "rod": "rigid rod\npin to pin", "tendon": "tendon\npulls only"}


def start_label(st, starts):
    """c, parallel, crossed keep their names; seeded starts read as random 1, 2, ..."""
    seeded = [x for x in starts if x.startswith("seed")]
    return "random %d" % (seeded.index(st) + 1) if st in seeded else st


def arm_key(r):
    return (r["topology"], r["controller"])


CTRL_LABEL = {"steer": "+ sensing: steer\n(rod across the body)", "steer_chiral": "+ sensing: steer,\nchiral (rod on the left)",
              "rhythm": "+ sensing: rhythm\n(hub yields to torque)", "rhythm_anti": "+ sensing: rhythm,\nanti (hub resists)",
              "ease":"+ sensing: ease\n(unload the rod)", "ease_flip": "+ ease, sign flipped\n(ablation)", "phase": "+ sensing: phase\n(hold the bar)",
              "phase_hub": "+ hub reflex alone\n(ablation)", "keep": "+ sensing: keep\n(a distance)", "keep_pull": "+ pull half only\n(ablation)"}


EVENT_LABEL = {"kick": "kicked {deg:g}° at {at:g} s", "cut~kick": "sensing cut and\nkicked {deg:g}° at {at:g} s", "cut": "sensing cut at {at:g} s,\nno kick"}


def arm_label(t, c, event_at=-1.0, kick_deg=0.0):
    """The row's name; for Experiment 2h, the event as the run record states it (its time and kick size); for
    Experiment f, the family's programme the arm runs (named after '@')."""
    base = ROW_LABEL.get(t, t)
    c, _, event = c.partition("~")
    ctrl, _, preset = c.partition("@")
    if ctrl == "programme":
        return base + ("\n(%s's programme,\nno sensing)" % preset if preset else "")
    lab = base + "\n" + CTRL_LABEL.get(ctrl, "+ sensing: " + ctrl)
    return lab + ("\n" + EVENT_LABEL[event].format(deg=kick_deg, at=event_at) if event in EVENT_LABEL else "")


def box(x, z, th):
    pts = [(-.09, -.2), (.33, -.2), (.33, .2), (-.09, .2), (-.09, -.2)]
    c, s = math.cos(th), math.sin(th)
    return [x + px * c - pz * s for px, pz in pts], [z + px * s + pz * c for px, pz in pts]


def main():
    dirs = [a for a in sys.argv[1:] if not a.startswith("--")]
    out = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--out=")), os.path.join(dirs[0], "poster.png"))
    half = float(next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--half=")), 2.7))
    runs, starts, arms, title_exp = [], [], [], []
    for d in dirs:
        s = json.load(open(os.path.join(d, "summary.json"), encoding="utf-8"))
        title_exp.append(str(s["experiment"]))
        for r in s["runs"]:
            r["_dir"] = d
            runs.append(r)
            if r["start"] not in starts:
                starts.append(r["start"])
            if arm_key(r) not in arms:
                arms.append(arm_key(r))
    window = s["window"]
    nr, nc = len(arms), len(starts)
    fig = plt.figure(figsize=(2.55 * nc + 1.9, 2.75 * nr + 1.7), facecolor="white")
    gs = fig.add_gridspec(nr, nc + 1, width_ratios=[.72] + [1] * nc, left=.01, right=.995, top=1 - 1.15 / (2.75 * nr + 1.7), bottom=.55 / (2.75 * nr + 1.7), wspace=.05, hspace=.16)
    hold = s["experiment"] == "2h"
    fig.suptitle("THE UNIT  -  experiment %s: the same commands, %s" % (" + ".join(title_exp), "three links" if all(c == "programme" for _, c in arms) else
                 ("a kick, with the sensing on and off" if hold else "links and sensing")),
                 fontsize=19, family="serif", y=1 - .32 / (2.75 * nr + 1.7))
    fig.text(.5, 1 - .78 / (2.75 * nr + 1.7), "seen from above, every panel %.1f m across at one scale: unit 1 and unit 2's chassis paths (blue, red), the point a link's middle holds (ink), and where all of it ends after %d s"
             % (2 * half, int(s["T"])), ha="center", fontsize=10.5, family="serif", color="#444")
    for i, (topo, ctrl) in enumerate(arms):
        lab = fig.add_subplot(gs[i, 0]); lab.axis("off")
        row = [r for r in runs if arm_key(r) == (topo, ctrl)]
        span = np.median([max(r["metrics"]["tool_extent_m"]) for r in row])
        span_w = np.median([r["metrics"]["tool_span_window_m"] for r in row])
        ten = np.median([r["metrics"]["tension_mean_window"] for r in row])
        w = np.median([np.mean(r["metrics"]["w_mean_window"]) for r in row])
        lab.text(.04, .64, arm_label(topo, ctrl, float(row[0].get("event_at", -1.0)), float(row[0].get("kick_deg", 0.0))), fontsize=(10 if "~" in ctrl else 11.5) if ctrl != "programme" else 12.5, family="serif", va="center", linespacing=1.15)
        lab.text(.04, .22, "span %.2f m (settled %.2f)\nsettled force %.1f N\nturn %.3f rad/s" % (span, span_w, ten, w), fontsize=8.5, family="serif", color="#555", va="center")
        for j, st in enumerate(starts):
            ax = fig.add_subplot(gs[i, j + 1])
            ax.set_facecolor(PAPER)
            for sp in ax.spines.values():
                sp.set_color("#2b2f33"); sp.set_linewidth(1.2)
            ax.set_xticks([]); ax.set_yticks([])
            run = next((r for r in row if r["start"] == st), None)
            if run is None:
                continue
            data = json.load(open(os.path.join(run["_dir"], run["name"] + ".json"), encoding="utf-8"))
            f = {k: n for n, k in enumerate(data["fields"])}
            tr = np.array(data["trace"], dtype=float)
            late = tr[:, f["t"]] >= data["T"] - window
            cx = float(np.mean(np.r_[tr[late, f["x0"]], tr[late, f["x1"]]]))
            cz = float(np.mean(np.r_[tr[late, f["z0"]], tr[late, f["z1"]]]))
            ax.plot(tr[:, f["x0"]], tr[:, f["z0"]], color=U0, lw=.45, alpha=.38)
            ax.plot(tr[:, f["x1"]], tr[:, f["z1"]], color=U1, lw=.45, alpha=.38)
            ax.plot(tr[:, f["toolx"]], tr[:, f["toolz"]], color=INK, lw=.6, alpha=.9)
            last = tr[-1]
            for u, c in (("0", U0), ("1", U1)):
                bx, bz = box(last[f["x" + u]], last[f["z" + u]], last[f["th" + u]])
                ax.plot(bx, bz, color=c, lw=1.1)
                ax.plot([last[f["pin%sx" % u]]], [last[f["pin%sz" % u]]], "o", color=c, ms=2.6)
            if topo != "none":
                ax.plot([last[f["pin0x"]], last[f["pin1x"]]], [last[f["pin0z"]], last[f["pin1z"]]], color="#6f7880", lw=1.8, solid_capstyle="round")
            ax.plot([last[f["toolx"]]], [last[f["toolz"]]], "o", color=INK, ms=3.2)
            ax.set_xlim(cx - half, cx + half); ax.set_ylim(cz - half, cz + half); ax.set_aspect("equal")
            m = run["metrics"]
            ax.text(.03, .03, "span %.2f m  %.1f N" % (max(m["tool_extent_m"]), m["tension_mean_window"]), transform=ax.transAxes, fontsize=7, family="serif", color="#333")
            if i == 0:
                ax.set_title(start_label(st, starts), fontsize=11, family="serif")
            if i == nr - 1 and j == 0:
                ax.plot([cx - half + .25, cx - half + 1.25], [cz - half + .45] * 2, color="#222", lw=1.6)
                ax.text(cx - half + .75, cz - half + .58, "1 m", ha="center", fontsize=7, family="serif")
    prog = ("steer's v 0.25 m/s, turn 0.2 rad/s, hub 1.6 rad/s; rhythm's v 0.10, turn 0.09, hub 1.2" if any("@" in c for _, c in arms)
            else "v 0.15 m/s, turn 0.25 rad/s, hub 1.0 rad/s")
    fig.text(.5, .18 / (2.75 * nr + 1.7), "Ada Research - The Unit, Palle's Experiment %s (2026-11-03). Model: commons/artifacts/the_unit/unit_sim.gd; runs: commons/testing/unit_lab.gd; "
             "each unit drives its programme (%s) through a compliant drive; rows marked sensing change the command from what the unit feels at its own pin."
             % (" + ".join(title_exp), prog), ha="center", fontsize=8, family="serif", color="#666")
    fig.savefig(out, dpi=170, facecolor="white")
    plt.close(fig)
    print("poster ->", out)


if __name__ == "__main__":
    main()
