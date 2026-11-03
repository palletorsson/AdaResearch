"""The Unit's collection poster: every gallery specimen overhead, with its timelines underneath.

Palle, 2026-11-03: "a collection poster of the experiment with overhead view"; "I like the timeline under each, and
these examples - add more". Reads ada_run/workstation/unit_lab/gallery (commons/testing/unit_gallery.gd). One row per
theme, one cell per specimen; each row at ONE scale (stated at its left), so reach reads directly inside a row.
Each cell: the chassis paths (faint, one colour per unit), the tool points' traces (ink; the triangle's plate pen in
navy and its rod pens in red, blue and green, as on the exhibit), the final pose (chassis, pins, links); under it,
over the whole run, three strips: link tension, the hub phase difference between unit 1 and the others, and the
distance between unit 1 and the others (for one unit alone: its turn rate).

Usage: python tools/unit_gallery_poster.py [gallery dir] --out=<png>
"""
import json, math, os, sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

PAPER = "#f3efe6"
UNIT_COLORS = ["#2f5fa8", "#c8402e", "#1f8f6a"]
TOOL_PAIR = "#1d2846"
TOOL_TRI = ["#1d2846", "#c8402e", "#2f5fa8", "#1f8f6a"]
STRIP_BG = "#faf8f3"


def box(x, z, th):
    pts = [(-.09, -.2), (.33, -.2), (.33, .2), (-.09, .2), (-.09, -.2)]
    c, s = math.cos(th), math.sin(th)
    return [x + px * c - pz * s for px, pz in pts], [z + px * s + pz * c for px, pz in pts]


def columns(run):
    lay = run["layout"]
    nu, nt, nl, uf = lay["units"], lay["tools"], lay["links"], lay["unit_fields"]
    tr = np.array(run["trace"], dtype=float)
    t = tr[:, 0]
    units = [tr[:, 1 + i * uf: 1 + (i + 1) * uf] for i in range(nu)]
    base = 1 + nu * uf
    pins = [tr[:, base + 2 * i: base + 2 * i + 2] for i in range(nu)]
    base += 2 * nu
    tools = [tr[:, base + 2 * j: base + 2 * j + 2] for j in range(nt)]
    base += 2 * nt
    links = [tr[:, base + 2 * j: base + 2 * j + 2] for j in range(nl)]
    return t, units, pins, tools, links


def run_half(run):
    """How far this run reaches from its own late centre: units late, tool points over the run, plus margin."""
    h = 0.0
    t, units, pins, tools, links = columns(run)
    late = t >= run["T"] - 300
    cx = np.mean([u[late, 0].mean() for u in units]); cz = np.mean([u[late, 1].mean() for u in units])
    for u in units:
        h = max(h, np.abs(u[late, 0] - cx).max(), np.abs(u[late, 1] - cz).max())
    for q in tools:
        h = max(h, np.abs(q[:, 0] - cx).max() * .8, np.abs(q[:, 1] - cz).max() * .8)
    return h + .45


def row_scales(runs):
    """One scale per row - except a panel more than twice the row's typical width, which gets its own (and says so)."""
    halves = [run_half(r) for r in runs]
    typical = float(np.median(halves))
    common = max(h for h in halves if h <= 2.0 * typical)
    return common, [common if h <= 2.0 * typical else h for h in halves]


def draw_cell(fig, cell, run, half, own_scale=False):
    sub = cell.subgridspec(4, 1, height_ratios=[3.3, .62, .62, .62], hspace=.06)
    ax = fig.add_subplot(sub[0])
    ax.set_facecolor(PAPER)
    for sp in ax.spines.values():
        sp.set_color("#2b2f33"); sp.set_linewidth(1.1)
    ax.set_xticks([]); ax.set_yticks([])
    t, units, pins, tools, links = columns(run)
    late = t >= run["T"] - 300
    cx = np.mean([u[late, 0].mean() for u in units]); cz = np.mean([u[late, 1].mean() for u in units])
    for i, u in enumerate(units):
        ax.plot(u[:, 0], u[:, 1], color=UNIT_COLORS[i % 3], lw=.42, alpha=.35)
    tri = len(units) == 3
    for j, q in enumerate(tools):
        ax.plot(q[:, 0], q[:, 1], color=(TOOL_TRI[j % 4] if tri else TOOL_PAIR), lw=.55 if tri else .6, alpha=.9)
    for i, u in enumerate(units):
        bx, bz = box(u[-1, 0], u[-1, 1], u[-1, 2])
        ax.plot(bx, bz, color=UNIT_COLORS[i % 3], lw=1.0)
        ax.plot([pins[i][-1, 0]], [pins[i][-1, 1]], "o", color=UNIT_COLORS[i % 3], ms=2.4)
    for a, b, tendon in run["links"]:
        ax.plot([pins[a][-1, 0], pins[b][-1, 0]], [pins[a][-1, 1], pins[b][-1, 1]], color="#6f7880", lw=1.6, ls=(0, (2, 1)) if tendon else "-", solid_capstyle="round")
    ax.set_xlim(cx - half, cx + half); ax.set_ylim(cz - half, cz + half); ax.set_aspect("equal")
    ax.set_title(run["label"], fontsize=8.6, family="serif", pad=3)
    m = run["metrics"]
    ax.text(.03, .03, "reach %.2f m2   %.1f N   turn %.3f" % (m["reach_m2"], m["tension_mean"], m["w_mean"]), transform=ax.transAxes, fontsize=6.4, family="serif", color="#333")
    if own_scale:
        ax.text(.97, .97, "own scale: %.1f m across" % (2 * half), transform=ax.transAxes, fontsize=6.6, family="serif", color="#a33", ha="right", va="top")
    strips = [fig.add_subplot(sub[k]) for k in (1, 2, 3)]
    for s in strips:
        s.set_facecolor(STRIP_BG); s.tick_params(labelsize=5, length=2, pad=1)
        for sp in s.spines.values():
            sp.set_color("#bbb"); sp.set_linewidth(.6)
        s.set_xlim(0, run["T"])
    # 1 tension
    if links:
        for j, l in enumerate(links):
            strips[0].plot(t, l[:, 1], color=("#d8432e" if not tri else TOOL_TRI[(j + 1) % 4]), lw=.45)
    else:
        strips[0].text(.5, .5, "no link", transform=strips[0].transAxes, ha="center", va="center", fontsize=6, color="#999")
    # 2 hub phase difference to unit 1 (world hub angles)
    if len(units) > 1:
        for i in range(1, len(units)):
            d = np.degrees(np.angle(np.exp(1j * ((units[0][:, 2] + units[0][:, 3]) - (units[i][:, 2] + units[i][:, 3])))))
            strips[1].plot(t, d, ".", ms=.6, color=UNIT_COLORS[i % 3])
        strips[1].set_ylim(-190, 190); strips[1].set_yticks([-180, 0, 180])
    else:
        strips[1].text(.5, .5, "one hub", transform=strips[1].transAxes, ha="center", va="center", fontsize=6, color="#999")
    # 3 distance to unit 1 (or one unit's turn rate)
    if len(units) > 1:
        for i in range(1, len(units)):
            strips[2].plot(t, np.hypot(units[0][:, 0] - units[i][:, 0], units[0][:, 1] - units[i][:, 1]), lw=.45, color=UNIT_COLORS[i % 3])
    else:
        strips[2].plot(t, units[0][:, 5], lw=.5, color=UNIT_COLORS[0])
    for s in strips[:2]:
        s.set_xticklabels([])
    return strips


def main():
    d = next((a for a in sys.argv[1:] if not a.startswith("--")), "ada_run/workstation/unit_lab/gallery")
    out = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--out=")), os.path.join(d, "poster_gallery.png"))
    index = json.load(open(os.path.join(d, "index.json"), encoding="utf-8"))
    rows = index["rows"]
    nc = max(len(r["specimens"]) for r in rows)
    nr = len(rows)
    H = 4.15 * nr + 1.6
    fig = plt.figure(figsize=(3.05 * nc + 2.1, H), facecolor="white")
    gs = fig.add_gridspec(nr, nc + 1, width_ratios=[.68] + [1] * nc, left=.008, right=.995, top=1 - 1.05 / H, bottom=.5 / H, wspace=.07, hspace=.2)
    fig.suptitle("THE UNIT  -  a collection: one unit, two, and three, joined and not", fontsize=21, family="serif", y=1 - .3 / H)
    fig.text(.5, 1 - .72 / H, "each specimen seen from above, its timelines underneath (link tension N, hub phase difference to unit 1 in degrees, distance to unit 1 in m) over %d s; every row at one scale, unless a panel says otherwise"
             % int(index["T"]), ha="center", fontsize=11, family="serif", color="#444")
    for i, row in enumerate(rows):
        runs = [json.load(open(os.path.join(d, s["id"] + ".json"), encoding="utf-8")) for s in row["specimens"]]
        half, halves = row_scales(runs)
        lab = fig.add_subplot(gs[i, 0]); lab.axis("off")
        lab.text(.04, .66, row["title"].replace(", ", ",\n"), fontsize=13.5, family="serif", va="center", linespacing=1.15)
        lab.text(.04, .38, "panels %.1f m across" % (2 * half), fontsize=8.5, family="serif", color="#555")
        lab.text(.04, .14, "tension N\nhub phase deg\ndistance m", fontsize=7.5, family="serif", color="#777", linespacing=2.1)
        for j, run in enumerate(runs):
            strips = draw_cell(fig, gs[i, j + 1], run, halves[j], own_scale=halves[j] != half)
            if j == 0 and i == nr - 1:
                strips[2].set_xlabel("s", fontsize=6, labelpad=0)
    fig.text(.5, .16 / H, "Ada Research - The Unit (2026-11-03). Model commons/artifacts/the_unit/unit_sim.gd, runs commons/testing/unit_gallery.gd. Each unit drives its own programme "
             "(pairs: v 0.15 m/s, turn 0.25, hub 1.0 rad/s; triangle: turn 0.8) through a compliant drive and senses nothing.", ha="center", fontsize=8.5, family="serif", color="#666")
    fig.savefig(out, dpi=150, facecolor="white")
    plt.close(fig)
    print("poster ->", out)


if __name__ == "__main__":
    main()
