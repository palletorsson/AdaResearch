"""Plots for The Unit's lab (commons/testing/unit_lab.gd): Palle's Experiments 1 and 2, 2026-11-03.

For each start, one figure with a column per arm (topology x controller): the two chassis paths, the two pins, the
tool point's trace and the final pose drawn together (top), and below it, over time, the link's length and tension,
the hub phase difference and both units' turn rates. Then one summary figure comparing the arms over all starts:
the tool's covered area (reachable workspace), the settled mean |tension| and the peak, how far apart the units got,
the hub phase order, and the units' mean turn rate against the programme.

Usage: python tools/unit_lab_plots.py ada_run/workstation/unit_lab/exp1 [--starts c,seed100]
Writes <dir>/plots/<start>.png and <dir>/plots/summary.png. Reads only; deterministic.
"""
import json, math, os, sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

COL = {"u0": "#2f5fa8", "u1": "#c8402e", "tool": "#1d2846", "link": "#6f7880", "tension": "#d8432e", "phase": "#1f8f6a"}


def load(d):
    s = json.load(open(os.path.join(d, "summary.json"), encoding="utf-8"))
    return s


def arm_name(r):
    return r["topology"] if r["controller"] == "programme" else "%s + %s" % (r["topology"], r["controller"])


def per_start(d, s, start, out):
    runs = [r for r in s["runs"] if r["start"] == start]
    if not runs:
        return
    n = len(runs)
    fig, axes = plt.subplots(4, n, figsize=(4.2 * n, 12.5), gridspec_kw={"height_ratios": [3.2, 1, 1, 1]}, squeeze=False)
    for j, meta in enumerate(runs):
        run = json.load(open(os.path.join(d, meta["name"] + ".json"), encoding="utf-8"))
        f = {k: i for i, k in enumerate(run["fields"])}
        tr = np.array(run["trace"], dtype=float)
        t = tr[:, f["t"]]
        ax = axes[0][j]
        ax.plot(tr[:, f["x0"]], tr[:, f["z0"]], color=COL["u0"], lw=.6, alpha=.35, label="unit 1 path")
        ax.plot(tr[:, f["x1"]], tr[:, f["z1"]], color=COL["u1"], lw=.6, alpha=.35, label="unit 2 path")
        ax.plot(tr[:, f["toolx"]], tr[:, f["toolz"]], color=COL["tool"], lw=.8, label="tool (link middle)")
        last = tr[-1]
        for u, c in (("0", COL["u0"]), ("1", COL["u1"])):
            x, z, th = last[f["x" + u]], last[f["z" + u]], last[f["th" + u]]
            ax.add_patch(plt.Polygon(_box(x, z, th), closed=True, fill=False, ec=c, lw=1.2))
            ax.plot([last[f["pin%sx" % u]]], [last[f["pin%sz" % u]]], "o", color=c, ms=3)
        ax.plot([last[f["pin0x"]], last[f["pin1x"]]], [last[f["pin0z"]], last[f["pin1z"]]], color=COL["link"], lw=1.6 if meta["topology"] != "none" else .6,
                ls="-" if meta["topology"] != "none" else ":")
        ax.set_aspect("equal"); ax.set_title(arm_name(meta), fontsize=11)
        m = meta["metrics"]
        ax.text(.01, .01, "tool area %.2f m2, |T| %.1f N (peak %.0f)\nunits %.2f m apart at most, w %s" % (m["tool_area_m2"], m["tension_mean_window"], m["tension_peak"], m["units_apart_max"], m["w_mean_window"]),
                transform=ax.transAxes, fontsize=7.5, va="bottom")
        if j == 0:
            ax.legend(fontsize=7, loc="upper left")
        a1 = axes[1][j]
        a1.plot(t, tr[:, f["link"]], color=COL["link"], lw=.7); a1.set_ylabel("link m", fontsize=8)
        a1b = a1.twinx(); a1b.plot(t, tr[:, f["tension"]], color=COL["tension"], lw=.6); a1b.set_ylabel("tension N", fontsize=8, color=COL["tension"])
        a2 = axes[2][j]
        dphi = np.angle(np.exp(1j * ((tr[:, f["th0"]] + tr[:, f["ph0"]]) - (tr[:, f["th1"]] + tr[:, f["ph1"]]))))
        a2.plot(t, np.degrees(dphi), ".", color=COL["phase"], ms=1); a2.set_ylabel("hub phase diff deg", fontsize=8); a2.set_ylim(-185, 185)
        a3 = axes[3][j]
        a3.plot(t, tr[:, f["w0"]], color=COL["u0"], lw=.5); a3.plot(t, tr[:, f["w1"]], color=COL["u1"], lw=.5)
        a3.axhline(.25 if meta.get("programme_w", None) is None else meta["programme_w"], color="k", lw=.5, ls="--")
        a3.set_ylabel("turn rad/s", fontsize=8); a3.set_xlabel("s", fontsize=8)
        for a in (a1, a2, a3):
            a.tick_params(labelsize=7)
            a.axvspan(run["T"] - s["window"], run["T"], color="#e9e4d8", alpha=.6, lw=0)
    fig.suptitle("The Unit, experiment %s - start %s: paths, pins and tool together; link, tension, hub phase and turn rate over time (shaded: settled window)" % (s["experiment"], start), fontsize=11)
    fig.tight_layout(rect=(0, 0, 1, .97))
    fig.savefig(os.path.join(out, "%s.png" % start), dpi=90)
    plt.close(fig)


def _box(x, z, th):
    pts = [(-.09, -.2), (.33, -.2), (.33, .2), (-.09, .2)]
    c, s = math.cos(th), math.sin(th)
    return [(x + px * c - pz * s, z + px * s + pz * c) for px, pz in pts]


def summary(s, out):
    arms = []
    for r in s["runs"]:
        a = arm_name(r)
        if a not in arms:
            arms.append(a)
    keys = [("tool_area_m2", "tool's covered area m2 (reach)"), ("tension_mean_window", "settled mean |tension| N"), ("tension_peak", "peak |tension| N"),
            ("units_apart_max", "units apart, max m"), ("hub_order_window", "hub phase order (1 = locked)"), ("w_mean", "mean turn rate rad/s")]
    fig, axes = plt.subplots(1, len(keys), figsize=(3.3 * len(keys), 4.2))
    for ax, (k, title) in zip(axes, keys):
        for i, a in enumerate(arms):
            vals = []
            for r in s["runs"]:
                if arm_name(r) != a:
                    continue
                m = r["metrics"]
                vals.append(float(np.mean(m["w_mean_window"])) if k == "w_mean" else float(m[k]))
            ax.scatter(np.full(len(vals), i) + np.linspace(-.12, .12, len(vals)), vals, s=14, alpha=.8)
            ax.hlines(np.median(vals), i - .25, i + .25, color="k", lw=1)
        ax.set_xticks(range(len(arms))); ax.set_xticklabels(arms, rotation=30, ha="right", fontsize=8)
        ax.set_title(title, fontsize=9); ax.tick_params(labelsize=7)
    fig.suptitle("The Unit, experiment %s - every start, each dot one run; bar = median (settled window: last %d s of %d)" % (s["experiment"], s["window"], s["T"]), fontsize=10)
    fig.tight_layout(rect=(0, 0, 1, .93))
    fig.savefig(os.path.join(out, "summary.png"), dpi=90)
    plt.close(fig)


def main():
    d = sys.argv[1]
    starts = None
    for a in sys.argv[2:]:
        if a.startswith("--starts="):
            starts = a.split("=", 1)[1].split(",")
    s = load(d)
    out = os.path.join(d, "plots"); os.makedirs(out, exist_ok=True)
    for st in (starts or s["starts"]):
        per_start(d, s, st, out)
    summary(s, out)
    print("plots ->", out)


if __name__ == "__main__":
    main()
