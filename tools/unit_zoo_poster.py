"""The Unit's zoo poster: the most different drawings the model makes, ordered from ordered to chaotic.

Palle, 2026-11-03: "there were other strange examples I liked ... we want as many different examples as possible,
with different looks and entropy". Reads ada_run/workstation/unit_lab/zoo (commons/testing/unit_zoo.gd): every run
records five pens, so every run gives five candidate drawings. For each drawing:

  ink entropy   how evenly the ink spreads over its own square box: the path resampled every half cell, its length
                binned on a 40 x 40 grid, Shannon entropy / log(1600). 0 = all in one cell, 1 = spread evenly.
  direction entropy  how evenly the pen's directions of travel spread: length-weighted over 36 bins / log(36).
                A straight drift is near 0, a circle or a scribble near 1.
  coverage      the share of the 40 x 40 cells the ink touches; retrace = path length / (touched cells x cell).
  look          blind to rotation and position: how the ink spreads out from its centre (12 radial bins) and how
                sharply it turns (12 log-spaced bins of turning per span), each length-weighted, square-rooted and
                normalised - so the same open drift at two angles counts as one look, not two.

The poster picks K drawings by farthest-point sampling over [look, the entropies, coverage and retrace] - each pick the
drawing least like every drawing already picked - keeping at least two and at most twice its share of every family, and at most two pens of one
run, then lays them out in rising ink entropy. Each panel is at its own scale (the look, not the reach, is what is
compared; its width is printed), with two timelines under it: link tension and the distance between the units.
A top plot shows every candidate's ink entropy against its direction entropy, the picked ones in colour.
Also writes descriptors.json beside the runs (every candidate's numbers).

Usage: python tools/unit_zoo_poster.py [zoo dir] [--k=80] [--cols=10] [--out=<png>]   - read-only, deterministic.
"""
import glob, json, math, os, sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

PAPER = "#f3efe6"
INK = "#1d2846"
UNIT_COLORS = ["#2f5fa8", "#c8402e"]
STRIP_BG = "#faf8f3"
PEN_NAMES = ["hub rim", "rod 0.25", "rod middle", "rod 0.75", "beyond the end (1.4)"]
FAMILY_COLORS = {"compliance": "#1d2846", "steer": "#c8402e", "steer_chiral": "#e07b39", "rhythm": "#2f8f5f", "rhythm_anti": "#7fbf3f",
                 "ease": "#2f5fa8", "phase": "#6a4fb0", "ease_flip": "#b04f8f", "keep": "#1f9fa8", "cord": "#8f8f3f", "free": "#888888"}
G = 40
THUMB = 16


def columns(run):
    lay = run["layout"]
    nu, nt, nl, uf = lay["units"], lay["tools"], lay["links"], lay["unit_fields"]
    tr = np.array(run["trace"], dtype=float)
    t = tr[:, 0]
    units = [tr[:, 1 + i * uf: 1 + (i + 1) * uf] for i in range(nu)]
    base = 1 + nu * uf + 2 * nu
    tools = [tr[:, base + 2 * j: base + 2 * j + 2] for j in range(nt)]
    base += 2 * nt
    links = [tr[:, base + 2 * j: base + 2 * j + 2] for j in range(nl)]
    return t, units, tools, links


def describe(q):
    """The entropies, coverage, retrace and thumbnail of one ink path (N x 2)."""
    seg = np.diff(q, axis=0)
    ln = np.hypot(seg[:, 0], seg[:, 1])
    path = float(ln.sum())
    span = float(max(np.ptp(q[:, 0]), np.ptp(q[:, 1])))
    if path < 1e-3 or span < 1e-3 or not np.all(np.isfinite(q)):
        return None
    cx, cz = (q[:, 0].max() + q[:, 0].min()) / 2, (q[:, 1].max() + q[:, 1].min()) / 2
    cell = span / G
    s = np.concatenate([[0.0], np.cumsum(ln)])
    u = np.arange(0.0, path, cell / 2)
    px, pz = np.interp(u, s, q[:, 0]), np.interp(u, s, q[:, 1])
    ix = np.clip(((px - cx) / span + .5) * G, 0, G - 1e-9).astype(int)
    iz = np.clip(((pz - cz) / span + .5) * G, 0, G - 1e-9).astype(int)
    h = np.zeros((G, G)); np.add.at(h, (iz, ix), 1.0)
    p = h[h > 0] / h.sum()
    h_ink = float(-(p * np.log(p)).sum() / math.log(G * G))
    ang = np.arctan2(seg[:, 1], seg[:, 0])
    hd, _ = np.histogram(ang, bins=36, range=(-math.pi, math.pi), weights=ln)
    pd = hd[hd > 0] / hd.sum()
    h_dir = float(-(pd * np.log(pd)).sum() / math.log(36))
    touched = int((h > 0).sum())
    # the look, blind to rotation and position: how the ink spreads out from its centre (12 radial bins), and how
    # sharply it turns (12 bins of turning per unit length, log-spaced), both length-weighted and normalised
    rr = np.hypot(px - cx, pz - cz) / (span / 2 * math.sqrt(2))
    radial, _ = np.histogram(rr, bins=12, range=(0, 1))
    radial = np.sqrt(radial / max(radial.sum(), 1))
    uu = np.stack([px, pz], 1)
    du = np.diff(uu, axis=0)
    a2 = np.arctan2(du[:, 1], du[:, 0])
    turn = np.abs((np.diff(a2) + math.pi) % (2 * math.pi) - math.pi) / (cell / 2)   # rad per metre
    curv, _ = np.histogram(np.log10(turn * span + 1e-3), bins=12, range=(-1, 3))   # turning per span, from nearly straight to tight
    curv = np.sqrt(curv / max(curv.sum(), 1))
    return {"h_ink": h_ink, "h_dir": h_dir, "coverage": touched / (G * G), "retrace": path / (touched * cell), "span": span, "path": path,
            "thumb": np.concatenate([radial, curv]) / math.sqrt(2)}


def pick(cands, k):
    """Farthest-point sampling, deterministic: start from the candidate nearest the median ink entropy."""
    X = np.array([np.concatenate([c["thumb"], 1.5 * np.array([c["h_ink"], c["h_dir"], c["coverage"] * 2, math.log10(c["retrace"]) / 2])]) for c in cands])
    med = np.median([c["h_ink"] for c in cands])
    first = int(np.argmin([abs(c["h_ink"] - med) for c in cands]))
    chosen = [first]
    dmin = np.linalg.norm(X - X[first], axis=1)
    per_run = {cands[first]["id"]: 1}
    fams = sorted({c["family"] for c in cands})
    cap = math.ceil(2.0 * k / len(fams))   # no family takes more than twice its share
    per_fam = {cands[first]["family"]: 1}
    while len(chosen) < k:
        order = np.argsort(-dmin)
        nxt = next((int(i) for i in order if dmin[i] > 0 and per_run.get(cands[i]["id"], 0) < 2 and per_fam.get(cands[i]["family"], 0) < cap), None)
        if nxt is None:
            break
        chosen.append(nxt); per_run[cands[nxt]["id"]] = per_run.get(cands[nxt]["id"], 0) + 1
        per_fam[cands[nxt]["family"]] = per_fam.get(cands[nxt]["family"], 0) + 1
        dmin = np.minimum(dmin, np.linalg.norm(X - X[nxt], axis=1))
    # at least two of every family
    for fam in sorted({c["family"] for c in cands}):
        have = [i for i in chosen if cands[i]["family"] == fam]
        while len(have) < 2:
            pool = [i for i in range(len(cands)) if cands[i]["family"] == fam and i not in chosen]
            if not pool:
                break
            best = max(pool, key=lambda i: min(np.linalg.norm(X[i] - X[j]) for j in chosen))
            chosen.append(best); have.append(best)
    return chosen


def main():
    d = next((a for a in sys.argv[1:] if not a.startswith("--")), "ada_run/workstation/unit_lab/zoo")
    k = int(next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--k=")), 80))
    ncol = int(next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--cols=")), 10))
    out = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--out=")), os.path.join(d, "poster_zoo.png"))
    cands, runs, dropped = [], {}, 0
    for f in sorted(glob.glob(os.path.join(d, "z*.json"))):   # the run files themselves, so a zoo still running can be drawn
        try:
            run = json.load(open(f, encoding="utf-8"))
        except ValueError:
            continue   # a file being written right now
        s = {"id": run["id"], "label": run["label"], "config": run["config"], "metrics": run["metrics"]}
        if not s["metrics"].get("finite", True):
            dropped += 1
            continue
        runs[s["id"]] = run
        t, units, tools, links = columns(run)
        for j, q in enumerate(tools):
            desc = describe(q)
            if desc is None:
                dropped += 1
                continue
            desc.update({"id": s["id"], "pen": j, "family": s["config"]["family"], "label": s["label"]})
            cands.append(desc)
    json.dump([{kk: (v.tolist() if isinstance(v, np.ndarray) else v) for kk, v in c.items() if kk != "thumb"} for c in cands],
              open(os.path.join(d, "descriptors.json"), "w", encoding="utf-8"), indent=1)
    chosen = pick(cands, k)
    chosen.sort(key=lambda i: cands[i]["h_ink"])
    print("%d runs, %d candidate drawings (%d dropped: non-finite runs or still pens); picked %d" % (len(runs), len(cands), dropped, len(chosen)))
    nrow = math.ceil(len(chosen) / ncol)
    head = 3.2
    H = 3.55 * nrow + head + 1.85
    fig = plt.figure(figsize=(2.7 * ncol + .4, H), facecolor="white")
    fig.suptitle("THE UNIT  -  a zoo: the %d most different drawings of %d, from ordered to chaotic" % (len(chosen), len(cands)), fontsize=24, family="serif", y=1 - .32 / H)
    fig.text(.5, 1 - .75 / H, "two units, %d rule families, rods 0.6-1.5 m, five pens per run; each panel at its own scale (width printed), "
             "ink entropy H and direction entropy D under the title; under each: link tension and the distance between the units over %d s"
             % (len({c['family'] for c in cands}), int(next(iter(runs.values()))["T"])), ha="center", fontsize=11, family="serif", color="#444")
    # the entropy map
    ax0 = fig.add_axes([.06, 1 - (head + .95) / H, .62, (head - .55) / H])
    ax0.scatter([c["h_ink"] for c in cands], [c["h_dir"] for c in cands], s=5, color="#cccccc", lw=0)
    for i in chosen:
        c = cands[i]
        ax0.scatter([c["h_ink"]], [c["h_dir"]], s=22, color=FAMILY_COLORS.get(c["family"], "#000"), lw=0)
    ax0.set_xlabel("ink entropy H (how evenly the ink fills its box)", fontsize=9, family="serif")
    ax0.set_ylabel("direction entropy D", fontsize=9, family="serif")
    ax0.tick_params(labelsize=7)
    for sp in ("top", "right"):
        ax0.spines[sp].set_visible(False)
    lg = fig.add_axes([.71, 1 - (head + .95) / H, .27, (head - .55) / H]); lg.axis("off"); lg.set_xlim(0, 1); lg.set_ylim(0, 1)
    fams = sorted({c["family"] for c in cands})
    for n, fam in enumerate(fams):
        y = 1 - (n + .5) / len(fams)
        lg.scatter([.03], [y], s=40, color=FAMILY_COLORS.get(fam, "#000"))
        cnt = sum(1 for i in chosen if cands[i]["family"] == fam)
        lg.text(.08, y, "%s  (%d picked)" % (fam, cnt), va="center", fontsize=9.5, family="serif")
    gs = fig.add_gridspec(nrow, ncol, left=.01, right=.995, top=1 - (head + 1.75) / H, bottom=.55 / H, wspace=.08, hspace=.28)
    for n, i in enumerate(chosen):
        c = cands[i]
        run = runs[c["id"]]
        t, units, tools, links = columns(run)
        q = tools[c["pen"]]
        sub = gs[n // ncol, n % ncol].subgridspec(3, 1, height_ratios=[3.3, .55, .55], hspace=.05)
        ax = fig.add_subplot(sub[0]); ax.set_facecolor(PAPER)
        for sp in ax.spines.values():
            sp.set_color(FAMILY_COLORS.get(c["family"], "#2b2f33")); sp.set_linewidth(1.6)
        ax.set_xticks([]); ax.set_yticks([])
        for ui, u in enumerate(units):
            ax.plot(u[:, 0], u[:, 1], color=UNIT_COLORS[ui % 2], lw=.35, alpha=.28)
        ax.plot(q[:, 0], q[:, 1], color=INK, lw=.45, alpha=.92)
        cx, cz = (q[:, 0].max() + q[:, 0].min()) / 2, (q[:, 1].max() + q[:, 1].min()) / 2
        half = c["span"] / 2 * 1.08
        ax.set_xlim(cx - half, cx + half); ax.set_ylim(cz - half, cz + half); ax.set_aspect("equal")
        cfg = run["config"]
        ax.set_title("%s, %s\nL %.1f %s, %s" % (cfg["family"], PEN_NAMES[c["pen"]], cfg["params"]["L"], cfg["link"], cfg["start"] + (" kicked" if cfg["kick"] else "")),
                     fontsize=7, family="serif", pad=2)
        ax.text(.03, .03, "H %.2f  D %.2f  %.2f m" % (c["h_ink"], c["h_dir"], c["span"]), transform=ax.transAxes, fontsize=6.2, family="serif", color="#333")
        ax.text(.97, .03, c["id"], transform=ax.transAxes, fontsize=5.5, family="serif", color="#999", ha="right")
        s1, s2 = fig.add_subplot(sub[1]), fig.add_subplot(sub[2])
        for s in (s1, s2):
            s.set_facecolor(STRIP_BG); s.tick_params(labelsize=4.5, length=1.5, pad=1); s.set_xlim(0, run["T"]); s.ticklabel_format(axis="y", useOffset=False, style="plain")
            for sp in s.spines.values():
                sp.set_color("#bbb"); sp.set_linewidth(.5)
        if links:
            s1.plot(t, links[0][:, 1], color="#d8432e", lw=.4)
        else:
            s1.text(.5, .5, "no link", transform=s1.transAxes, ha="center", va="center", fontsize=5, color="#999")
        s2.plot(t, np.hypot(units[0][:, 0] - units[1][:, 0], units[0][:, 1] - units[1][:, 1]), color=UNIT_COLORS[1], lw=.4)
        s1.set_xticklabels([])
    fig.text(.5, .2 / H, "Ada Research - The Unit (2026-11-03). Model commons/artifacts/the_unit/unit_sim.gd, runs commons/testing/unit_zoo.gd, picked and drawn by "
             "tools/unit_zoo_poster.py. Frame colour = rule family. steer and rhythm are the Python study's rules ported onto this model's compliant drive, not copies of the study's figures.",
             ha="center", fontsize=8.5, family="serif", color="#666")
    fig.savefig(out, dpi=130, facecolor="white")
    plt.close(fig)
    print("poster ->", out)


if __name__ == "__main__":
    main()
