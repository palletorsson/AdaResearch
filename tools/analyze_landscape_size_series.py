"""Validate and describe the predeclared size series; never infer independent spheres."""
from pathlib import Path
import csv
import hashlib
import json
from collections import Counter

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'ada_run/landscape-size-series/results.json'
OUT = ROOT / 'doc/research/possible-bodies'
SURFACES = ['SINE', 'RANDOM HEIGHTS', 'PERLIN', 'WORLEY F1']
RADII = [.045, .075, .105]
SEEDS = [1729, 1730, 1731]


def analyze():
    raw = SOURCE.read_bytes()
    data = json.loads(raw)
    trials = data['trials']
    checks = []

    def check(condition, description):
        assert condition, description
        checks.append(description)

    check(data['status'] == 'complete' and not data['failures'], 'Godot series complete without trial failures')
    check(len(trials) == data['completed_trials'] == data['planned_trials'] == 18, 'All 18 planned trials retained')
    by_key = {(t['seed'], t['repeat'], t['radius_m']): t for t in trials}
    check(set(by_key) == {(s, n, r) for s in SEEDS for n in [1, 2] for r in RADII}, 'Every planned seed/repeat/radius occurs exactly once')
    check(data['time_scale'] == 1 and data['physics_hz'] == 60, 'Unscaled 60 Hz simulation')
    initial = trials[0]['initial_positions']
    sine = trials[0]['samples'][0]
    rows, contrasts, differences = [], [], []
    for t in trials:
        tag = f"Trial {t['trial']}"
        result = t['result']
        check(result['elapsed_ticks'] == 720 and result['window_seconds'] == 12, tag + ': complete declared window')
        check(result['tilt_degrees'] == 20 and result['relief_m'] == .3 and result['gravity'] == 9.8, tag + ': fixed tilt, relief and gravity')
        check(result['radius_m'] == t['radius_m'] and result['seed'] == t['seed'], tag + ': treatment metadata agrees')
        check(t['initial_positions'] == initial and len(initial) == 128, tag + ': identical initial centres across trials')
        check(t['samples'] == by_key[t['seed'], 1, RADII[0]]['samples'], tag + ': same four fields within seed block')
        check(t['samples'][0] == sine, tag + ': sine geometry unchanged across seed blocks')
        check(len(t['samples']) == 4 and all(len(f) == 693 and abs(min(f)) < 1e-6 and abs(max(f)-.3) < 1e-6 for f in t['samples']), tag + ': all sampled arrays complete and normalised')
        check([s['elapsed_ticks'] for s in t['timeline']] == list(range(0, 721, 60)), tag + ': complete per-second snapshots')
        check(t['timeline'][-1] == result, tag + ': terminal snapshot agrees')
        check(len(t['states']) == len(t['final_positions']) == 128, tag + ': complete body records')
        events = {e['body']: e for e in t['exit_observations']}
        check(len(events) == len(t['exit_observations']), tag + ': no duplicate exit observations')
        check(set(events) == {i for i, state in enumerate(t['states']) if state != 0}, tag + ': every recorded exit has exactly one event')
        check(all(e['tray'] == i//32 and e['slot'] == i%32 and e['outcome'] == t['states'][i] and 0 < e['observed_at_tick'] <= 720 for i, e in events.items()), tag + ': event identities and ticks agree')
        for mode, name in enumerate(SURFACES):
            counts = result['counts'][name]
            states = Counter(t['states'][mode*32:(mode+1)*32])
            check(counts == {'still_in': states[0], 'outlet': states[1], 'other_exit': states[2]} and sum(counts.values()) == 32, tag + ': complete ' + name + ' accounting')
            rows.append(dict(trial=t['trial'], seed=t['seed'], repeat=t['repeat'], radius_m=t['radius_m'], surface=name, **counts))
    ranges = {}
    for name in SURFACES:
        ranges[name] = {}
        for radius in RADII:
            values = [r['outlet'] for r in rows if r['surface'] == name and r['radius_m'] == radius]
            ranges[name][str(radius)] = {'min': min(values), 'max': max(values), 'values': values}
    for seed in SEEDS:
        for radius in RADII:
            a, b = by_key[seed, 1, radius], by_key[seed, 2, radius]
            for name in SURFACES:
                if a['result']['counts'][name] != b['result']['counts'][name]:
                    differences.append(dict(seed=seed, radius_m=radius, surface=name, repeat_1=a['result']['counts'][name], repeat_2=b['result']['counts'][name]))
        for repeat in [1, 2]:
            for radius in RADII[1:]:
                for name in SURFACES:
                    base = by_key[seed, repeat, RADII[0]]['result']['counts'][name]['outlet']
                    value = by_key[seed, repeat, radius]['result']['counts'][name]['outlet']
                    contrasts.append(dict(seed=seed, repeat=repeat, surface=name, reference_radius_m=RADII[0], radius_m=radius, reference_outlet=base, outlet=value, difference=value-base))
    source_matches = {p: hashlib.sha256((ROOT/p).read_bytes()).hexdigest() == h for p, h in data['source_sha256'].items()}
    # This is a provenance check at analysis time, in addition to the runner's before/after check.
    check(all(source_matches.values()), 'Recorded apparatus and runner source hashes still match the workspace')
    report = dict(status='complete', raw_sha256=hashlib.sha256(raw).hexdigest(), checks=checks, trial_count=18,
                  tray_observations=len(rows), total_body_releases=len(rows)*32, outlet_ranges=ranges,
                  paired_repeat_differences=differences, compared_repeat_pairs=36,
                  all_other_exits=sum(r['other_exit'] for r in rows), source_matches=source_matches,
                  interpretation='Descriptive selected-seed pilot. Spheres interact; sine has only one underlying landscape. No inferential statistics or generator-wide ranking.')
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT/'landscape-size-results.json').write_bytes(raw)
    (OUT/'landscape-size-analysis.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    for filename, records in [('landscape-size-trials.csv', rows), ('landscape-size-contrasts.csv', contrasts)]:
        with (OUT/filename).open('w', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=list(records[0]))
            writer.writeheader(); writer.writerows(records)
    plot_results(rows, by_key)
    print(json.dumps({k: report[k] for k in ['trial_count', 'tray_observations', 'total_body_releases', 'all_other_exits', 'paired_repeat_differences']}))
    print(f'{len(checks)} evidence integrity checks passed')
    return report


def plot_results(rows, by_key):
    plt.rcParams.update({'font.family': 'DejaVu Sans', 'font.size': 11, 'axes.spines.top': False,
                         'axes.spines.right': False, 'axes.facecolor': '#f7f4eb', 'figure.facecolor': '#f7f4eb',
                         'axes.labelcolor': '#243340', 'text.color': '#243340', 'xtick.color': '#243340', 'ytick.color': '#243340'})
    colors = ['#176a82', '#b35632', '#7d4d8b']
    fig, axes = plt.subplots(2, 2, figsize=(10, 8), sharey=True, sharex=True)
    for ax, name in zip(axes.flat, SURFACES):
        for si, seed in enumerate(SEEDS):
            for repeat in [1, 2]:
                values = [by_key[seed, repeat, radius]['result']['counts'][name]['outlet'] for radius in RADII]
                offset = (si-1)*1.8 + (repeat-1.5)*.8
                xs = [radius*1000+offset for radius in RADII]
                ax.plot(xs, values, color=colors[si], lw=.8, alpha=.45)
                ax.scatter(xs, values, color=colors[si], marker='o' if repeat == 1 else 'x', s=35, zorder=3)
        ax.set_title(name, loc='left', weight='bold', fontsize=12)
        ax.set_ylim(-1.5, 35); ax.set_yticks([0, 8, 16, 24, 32]); ax.set_xticks([45, 75, 105]); ax.grid(axis='y', alpha=.22)
        ax.tick_params(labelbottom=True)
        ax.set_xlabel('Sphere radius (mm)'); ax.set_ylabel('Outlet crossings / 32')
    legend = [Line2D([0], [0], color=c, label=f'Seed block {s}') for s, c in zip(SEEDS, colors)]
    fig.suptitle('The same terrain receives a different body', x=.075, ha='left', fontsize=20, weight='bold')
    fig.legend(handles=legend, loc='upper center', bbox_to_anchor=(.5,.93), ncol=3, frameon=False)
    fig.text(.075,.032, 'Each mark is one tray trial; circles / crosses distinguish repeats. Horizontal offsets separate marks.\n20° tilt · 0.30 m relief · 12 s declared window · sine geometry identical across all seed blocks.', fontsize=10)
    fig.subplots_adjust(top=.83, bottom=.14, hspace=.34, wspace=.25)
    fig.savefig(OUT/'landscape-size-outcomes.svg'); fig.savefig(OUT/'landscape-size-outcomes.png', dpi=180)
    plt.close(fig)

    fig, axes = plt.subplots(2, 2, figsize=(10, 7.6), sharex=True, sharey=True)
    for ax, name in zip(axes.flat, SURFACES):
        for radius, color in zip(RADII, colors):
            trial = by_key[1729, 1, radius]
            xs = [s['elapsed_ticks']/60 for s in trial['timeline']]
            ys = [s['counts'][name]['outlet'] for s in trial['timeline']]
            ax.plot(xs, ys, color=color, marker='o', ms=3, lw=1.8, label=f'{radius*1000:g} mm radius')
        ax.set_title(name, loc='left', fontsize=12, weight='bold'); ax.set_xlim(0,12); ax.set_ylim(-1,34)
        ax.set_xticks([0,3,6,9,12]); ax.set_yticks([0,8,16,24,32]); ax.grid(alpha=.2)
        ax.set_xlabel('Declared counter / 60 (s)'); ax.set_ylabel('Cumulative outlet / 32')
    fig.suptitle('What the deadline collects', x=.075, ha='left', fontsize=20, weight='bold')
    fig.legend(*axes.flat[0].get_legend_handles_labels(), loc='upper center', bbox_to_anchor=(.5,.93), ncol=3, frameon=False)
    fig.text(.075,.03, 'Preselected first repeat, seed 1729. Dots are recorded each second; connecting lines guide the eye.\nThe trial ends at counter 720. Later departures have not been measured.', fontsize=10)
    fig.subplots_adjust(top=.83, bottom=.15, hspace=.35, wspace=.25)
    fig.savefig(OUT/'landscape-size-time.svg'); fig.savefig(OUT/'landscape-size-time.png', dpi=180)
    plt.close(fig)


if __name__ == '__main__':
    analyze()
