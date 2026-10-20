"""Verify and present the fresh student's existing run; do not rerun or edit it."""
from pathlib import Path
from datetime import datetime, timezone
from hashlib import sha256
from html import escape
from html.parser import HTMLParser
from urllib.parse import unquote, urlsplit
import json
import zipfile

import markdown
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-swarm-fresh-ghost-student'
STUDENT = OUT / 'student'


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8'))


def digest(path):
    return sha256(path.read_bytes()).hexdigest()


def save_json(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')


def verify():
    manifest = read_json(OUT / 'input-manifest.json')
    provenance = read_json(STUDENT / 'provenance.json')
    baseline = {h['hall']: h['named_files'] for h in read_json(OUT / 'supervisor-baseline.json')['halls']}
    assert digest(ROOT / manifest['package']) == manifest['package_sha256']
    for path, expected in manifest['protected'].items():
        assert digest(ROOT / path) == expected, path
    for path, expected in provenance['inputs'].items():
        assert digest(OUT / 'input' / path) == expected, path
    scripts = scenes = 0
    for path, record in provenance['outputs'].items():
        assert digest(STUDENT / path) == record['sha256'], path
        if record['derivation'] == 'exact fence':
            hall = Path(record['source']).parts[1]
            assert record['sha256'] == baseline[hall][record['marker']], path
            scripts += 1
        else:
            assert Path(path).suffix == '.tscn', path
            scenes += 1
    assert (scripts, scenes) == (22, 7)
    prediction = digest(STUDENT / 'PREDICTIONS.md')
    observer = read_json(OUT / 'observer-log.json')
    observed = next(x for x in observer if x['event'] == 'Student predictions and reconstruction observed')
    assert observed['prediction_sha256'] == prediction
    run = read_json(STUDENT / 'logs/20261011T183427Z.json')
    assert run['prediction_sha256'] == prediction
    assert run['probe_sha256'] == digest(STUDENT / 'probe.gd')
    started = datetime.strptime(run['started_utc'], '%Y%m%dT%H%M%SZ').replace(tzinfo=timezone.utc)
    assert datetime.fromisoformat(observed['time']) < started
    assert run['exit_code'] == 0
    log = (STUDENT / 'logs/20261011T183427Z.log').read_text(encoding='utf-8')
    assert 'FRESH_STUDENT_PROBE_DONE checks=120 failures=0' in log
    assert 'SCRIPT ERROR' not in log
    result = read_json(STUDENT / 'results.json')
    assert result['check_count'] == len(result['checks']) == 120
    assert result['failures'] == 0 and all(c['pass'] for c in result['checks'])
    loading = sum(c['name'].startswith('button exists') or c['name'].endswith('model loads') or 'full host loads and enters tree' in c['name'] for c in result['checks'])
    assert loading == 40
    for label in ['coarse', 'fine']:
        for filename in ['point_body.gd', 'study.gd', 'study.tscn']:
            assert (STUDENT / 'variants' / label / filename).read_bytes() == (STUDENT / 'reconstructed/flow' / filename).read_bytes()
    coarse = (STUDENT / 'variants/coarse/field.gd').read_text(encoding='utf-8')
    fine = (STUDENT / 'variants/fine/field.gd').read_text(encoding='utf-8')
    assert coarse.replace('const DT := 0.05', 'const DT := 0.025', 1) == fine
    experiment = result['measurements']['independent_variation']
    assert experiment['coarse']['first_exit_step'] == -1
    assert experiment['fine']['first_exit_step'] == 79
    fine_trace = experiment['fine']['trace']
    assert fine_trace[190][2] < fine_trace[189][2]
    assert fine_trace[283][2] < 7 <= fine_trace[284][2]
    audit = read_json(STUDENT / 'completion_audit.json')
    for path, expected in audit['artifacts'].items():
        assert digest(STUDENT / path) == expected, path
    verification = {
        'verified_utc': datetime.now(timezone.utc).isoformat(),
        'supervisor': 'Inspected first execution, code, prediction and measured trace; no second engine run',
        'printed_scripts_exact': scripts,
        'student_scene_count': scenes,
        'protected_files_unchanged': len(manifest['protected']),
        'checks_passed': 120,
        'loading_or_button_presence_checks_included': loading,
        'prediction_observed_before_execution': True,
        'prediction_sha256': prediction,
        'engine_exit_code': run['exit_code'],
        'scope': 'Fresh experienced AI; task-enforced source limits; prepared project; synthetic headless controls',
        'student_files_unchanged_after_completion': True,
        'first_run_results_sha256': digest(STUDENT / 'results.json'),
    }
    assert verification['protected_files_unchanged'] == 84
    save_json(OUT / 'verification.json', verification)
    return manifest, experiment


def plot(experiment):
    plt.rcParams.update({'font.family': 'DejaVu Sans', 'font.size': 11})
    fig, axes = plt.subplots(1, 2, figsize=(12, 4.7), layout='constrained')
    for ax in axes:
        ax.set_facecolor('#f8f6f0')
        ax.grid(alpha=.16)
        ax.set_xlabel('Model time (seconds)')
        ax.set_ylabel('Horizontal position x (cells)')
        ax.spines[['top', 'right']].set_visible(False)
        ax.axhspan(7, 9, color='#b2afa6', alpha=.2, label='Braking strip [7, 9)')
        ax.axhline(9, color='#555555', linestyle=':', linewidth=1)
        for key, colour, label in [('coarse', '#363946', 'DT .05'), ('fine', '#b23768', 'DT .025')]:
            trace = experiment[key]['trace']
            ax.plot([0] + [v[1] for v in trace], [7.6] + [v[2] for v in trace], color=colour, linewidth=2, label=label)
    axes[0].set(xlim=(0, 2.5), ylim=(7.55, 9.55), title='First encounter: only one crosses')
    axes[0].annotate('First exit: 1.975 s', xy=(1.975, 9.000226), xytext=(.6, 9.28), arrowprops={'arrowstyle': '->', 'color': '#b23768'}, color='#b23768')
    axes[1].set(xlim=(0, 10), ylim=(-.5, 16.5), title='Ten seconds: wrap and return')
    axes[1].annotate('Wrap', xy=(4.775, .05), xytext=(3.3, 3.7), arrowprops={'arrowstyle': '->'})
    axes[1].annotate('Re-entry: 7.125 s', xy=(7.125, 7.04), xytext=(5.6, 12), arrowprops={'arrowstyle': '->'})
    axes[1].legend(loc='upper left', fontsize=9)
    fig.suptitle('Same starting sphere, same field; different integration step', fontsize=15, fontweight='bold')
    fig.savefig(OUT / 'flow-variation.png', dpi=170)
    fig.savefig(OUT / 'flow-variation.svg')
    plt.close(fig)


STYLE = '''body{margin:0;background:#f4f1e9;color:#25272d;font:18px/1.65 system-ui,sans-serif}main{max-width:1120px;margin:auto;padding:46px 28px 90px}h1{font:600 clamp(32px,5vw,55px)/1.08 Georgia,serif;max-width:900px}h2{margin-top:2.3em;font-size:26px}p,li{max-width:930px}a{color:#8d2856;text-underline-offset:3px}nav{display:flex;gap:20px;flex-wrap:wrap;border-bottom:1px solid #c9c5bb;padding-bottom:16px;font-size:15px}table{display:block;overflow-x:auto;border-collapse:collapse;width:100%;font-size:15px}td,th{padding:14px 13px;border-bottom:1px solid #d2cec4;text-align:left;vertical-align:top}th{background:#e9e4d9}img{max-width:100%;height:auto}pre{overflow:auto;background:#e8e4da;padding:16px}code{font-size:.85em}.route{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:18px}.route figure{margin:0;background:#fff;padding:12px}.route figcaption{font-size:14px}.route img{width:100%;aspect-ratio:3/2;object-fit:cover}footer{border-top:1px solid #c9c5bb;margin-top:45px;padding-top:18px;font-size:14px}@media print{nav{display:none}body{background:white;font-size:11pt}main{padding:0}h2{break-after:avoid}tr,figure{break-inside:avoid}}'''


def page(title, body):
    return f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{escape(title)}</title><style>{STYLE}</style></head><body><main><nav><a href="index.html">Assessment</a><a href="student-report.html">Student report</a><a href="predictions.html">Prediction</a><a href="fresh-ghost-evidence.zip">Evidence ZIP</a></nav>{body}<footer>Endless Museum · Swarm Intelligence · Fresh ghost student · 11 October 2026<br>Actual Godot headless execution. Existing museum photographs identified separately.</footer></main></body></html>'''


def render(manifest):
    body = markdown.markdown((OUT / 'ASSESSMENT.md').read_text(encoding='utf-8'), extensions=['tables', 'fenced_code'])
    body += '<h2>The seven halls read</h2><p>Existing museum photographs supplied as context. These are not renders from the student’s run.</p><div class="route">'
    for hall in manifest['halls']:
        n, label, hall_id = hall['order'], escape(hall['name']), hall['hall']
        body += f'<figure><img loading="lazy" src="input/images/{n}.png" alt="Existing {label} museum encounter"><figcaption>{n}. {label}<br><a href="input/halls/{hall_id}/tutorial.md">Tutorial</a> · <a href="input/halls/{hall_id}/final.md">Reflection</a></figcaption></figure>'
    body += '</div>'
    (OUT / 'index.html').write_text(page('Swarm — fresh ghost student', body), encoding='utf-8')
    for source, target, title in [('REPORT.md', 'student-report.html', 'Fresh student report'), ('PREDICTIONS.md', 'predictions.html', 'Predictions before execution')]:
        body = markdown.markdown((STUDENT / source).read_text(encoding='utf-8'), extensions=['tables', 'fenced_code'])
        (OUT / target).write_text(page(title, body), encoding='utf-8')


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.targets = []

    def handle_starttag(self, tag, attrs):
        for key, value in attrs:
            if key in ('href', 'src'):
                self.targets.append(value)


def publish():
    manifest, experiment = verify()
    plot(experiment)
    render(manifest)
    archive = OUT / 'fresh-ghost-evidence.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        for path in sorted(OUT.rglob('*')):
            if path.is_file() and path != archive and path.suffix not in ('.uid', '.import', '.pyc') and '__pycache__' not in path.parts:
                z.write(path, path.relative_to(OUT).as_posix())
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        assert z.read('student/results.json') == (STUDENT / 'results.json').read_bytes()
    checked = 0
    for path in [OUT / name for name in ['index.html', 'student-report.html', 'predictions.html']]:
        parser = Links()
        parser.feed(path.read_text(encoding='utf-8'))
        for target in parser.targets:
            parts = urlsplit(target)
            if parts.scheme or parts.netloc:
                continue
            assert (path.parent / unquote(parts.path)).exists(), (path, target)
            checked += 1
    print(json.dumps({'report': str(OUT / 'index.html'), 'local_links_verified': checked, 'archive_bytes': archive.stat().st_size, 'protected_files': len(manifest['protected']), 'student_checks': 120}, indent=2))


if __name__ == '__main__':
    publish()
