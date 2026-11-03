"""The Unit's zoo as an animation: the picked drawings, each drawn again over its whole run.

Palle, 2026-11-03: "can we make an animation out of this?" Reads ada_run/workstation/unit_lab/zoo (unit_zoo.gd) and
takes the zoo poster's 100 picks (tools/unit_zoo_poster.py, the rotation-blind picker) sampled evenly from low to high
ink entropy, or the drawings you name. A grid of panels, each at its own scale like the poster, in rising ink entropy:
the ink grows as the run goes,
the two chassis (blue, red) drive, the link swings (dashed for a cord) and the pen is the dot. Every panel shares one
clock - the run's 600 s pressed into the video's length.

Usage: python tools/unit_zoo_animate.py [zoo dir] [--n=24] [--cols=8] [--k=100] [--seconds=30] [--fps=30]
           [--draw=z123:2,z045:0] [--out=<mp4>]
--draw names drawings as run id : pen (0 hub rim, 1 rod 0.25, 2 rod middle, 3 rod 0.75, 4 beyond the end).
Needs ffmpeg; the one bundled with imageio-ffmpeg is used when none is on the PATH.
"""
import glob, json, math, os, sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import animation
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import unit_zoo_poster as zp


def box(x, z, th):
    pts = np.array([(-.09, -.2), (.33, -.2), (.33, .2), (-.09, .2), (-.09, -.2)])
    c, s = math.cos(th), math.sin(th)
    return x + pts[:, 0] * c - pts[:, 1] * s, z + pts[:, 0] * s + pts[:, 1] * c


def ffmpeg_path():
    try:
        import imageio_ffmpeg
        return imageio_ffmpeg.get_ffmpeg_exe()
    except Exception:
        return "ffmpeg"


def main():
    arg = lambda key, default: next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--%s=" % key)), default)
    d = next((a for a in sys.argv[1:] if not a.startswith("--")), "ada_run/workstation/unit_lab/zoo")
    n, ncol = int(arg("n", 24)), int(arg("cols", 8))
    seconds, fps = float(arg("seconds", 30)), int(arg("fps", 30))
    out = arg("out", os.path.join(d, "zoo.mp4"))
    runs, cands = {}, []
    for f in sorted(glob.glob(os.path.join(d, "z*.json"))):
        run = json.load(open(f, encoding="utf-8"))
        if not run["metrics"].get("finite", True):
            continue
        runs[run["id"]] = run
        for j, q in enumerate(zp.columns(run)[2]):
            desc = zp.describe(q)
            if desc:
                desc.update({"id": run["id"], "pen": j, "family": run["config"]["family"]})
                cands.append(desc)
    named = arg("draw", "")
    if named:
        want = [(p.split(":")[0], int(p.split(":")[1]) if ":" in p else 2) for p in named.split(",")]
        chosen = [next(i for i, c in enumerate(cands) if c["id"] == rid and c["pen"] == pen) for rid, pen in want]
    else:
        # the poster's 100 picks, sampled evenly from low to high ink entropy - so the dense end is in the film too
        hundred = sorted(zp.pick(cands, int(arg("k", 100))), key=lambda i: cands[i]["h_ink"])
        chosen = [hundred[int(round(x))] for x in np.linspace(0, len(hundred) - 1, n)]
    nrow = math.ceil(len(chosen) / ncol)
    fig = plt.figure(figsize=(19.2, 10.8), dpi=100, facecolor="white")
    fig.suptitle("THE UNIT  -  a zoo of possible drawings", fontsize=22, family="serif", y=.985)
    clock = fig.text(.5, .935, "", ha="center", fontsize=12, family="serif", color="#444")
    fig.text(.5, .012, "Ada Research - The Unit (2026-11-03). Two units, one rule family per panel (frame colour), drawn by commons/artifacts/the_unit/unit_sim.gd; "
             "each panel at its own scale, in rising ink entropy. Ink entropy measures how the ink fills its box, not chaos.",
             ha="center", fontsize=9, family="serif", color="#666")
    gs = fig.add_gridspec(nrow, ncol, left=.01, right=.99, top=.9, bottom=.045, wspace=.06, hspace=.22)
    panels = []
    T = None
    for k, i in enumerate(chosen):
        c = cands[i]
        run = runs[c["id"]]
        t, units, tools, links = zp.columns(run)
        T = run["T"]
        q = tools[c["pen"]]
        ax = fig.add_subplot(gs[k // ncol, k % ncol]); ax.set_facecolor(zp.PAPER)
        for sp in ax.spines.values():
            sp.set_color(zp.FAMILY_COLORS.get(c["family"], "#2b2f33")); sp.set_linewidth(2.0)
        ax.set_xticks([]); ax.set_yticks([])
        cx, cz = (q[:, 0].max() + q[:, 0].min()) / 2, (q[:, 1].max() + q[:, 1].min()) / 2
        half = c["span"] / 2 * 1.12
        ax.set_xlim(cx - half, cx + half); ax.set_ylim(cz - half, cz + half); ax.set_aspect("equal")
        cfg = run["config"]
        ax.set_title("%s, %s\nL %.1f %s, %s" % (cfg["family"], zp.PEN_NAMES[c["pen"]], cfg["params"]["L"], cfg["link"], cfg["start"] + (" kicked" if cfg["kick"] else "")),
                     fontsize=7.5, family="serif", pad=2)
        ax.text(.03, .03, "H %.2f   %.2f m   %s" % (c["h_ink"], c["span"], c["id"]), transform=ax.transAxes, fontsize=6.5, family="serif", color="#555")
        ink, = ax.plot([], [], color=zp.INK, lw=.6, alpha=.92)
        bodies = [ax.plot([], [], color=zp.UNIT_COLORS[u], lw=1.1)[0] for u in range(len(units))]
        tendon = bool(run["links"][0][2]) if run["links"] else False
        rod, = ax.plot([], [], color="#6f7880", lw=1.4, ls=(0, (2, 1)) if tendon else "-")
        pen, = ax.plot([], [], "o", color="#c8402e", ms=3.2)
        lay = run["layout"]
        tr = np.array(run["trace"], dtype=float)
        pins = [tr[:, 1 + lay["units"] * lay["unit_fields"] + 2 * u: 3 + lay["units"] * lay["unit_fields"] + 2 * u] for u in range(lay["units"])]
        panels.append({"q": q, "units": units, "pins": pins, "linked": bool(run["links"]), "ink": ink, "bodies": bodies, "rod": rod, "pen": pen})
    frames = int(seconds * fps)
    nsamp = min(len(p["q"]) for p in panels)

    def draw(f):
        s = min(nsamp - 1, int((f + 1) * nsamp / frames))
        for p in panels:
            p["ink"].set_data(p["q"][:s + 1, 0], p["q"][:s + 1, 1])
            for u, b in enumerate(p["bodies"]):
                b.set_data(*box(p["units"][u][s, 0], p["units"][u][s, 1], p["units"][u][s, 2]))
            if p["linked"]:
                p["rod"].set_data([p["pins"][0][s, 0], p["pins"][1][s, 0]], [p["pins"][0][s, 1], p["pins"][1][s, 1]])
            p["pen"].set_data([p["q"][s, 0]], [p["q"][s, 1]])
        clock.set_text("t = %3.0f s of %d   (%.0fx speed)" % (s * T / (nsamp - 1), T, T / seconds))
        return []

    plt.rcParams["animation.ffmpeg_path"] = ffmpeg_path()
    writer = animation.FFMpegWriter(fps=fps, bitrate=8000, extra_args=["-pix_fmt", "yuv420p"])
    anim = animation.FuncAnimation(fig, draw, frames=frames, blit=False)
    anim.save(out, writer=writer, dpi=100)
    plt.close(fig)
    print("animation -> %s (%d drawings, %d frames, %.0f s)" % (out, len(chosen), frames, seconds))


if __name__ == "__main__":
    main()
