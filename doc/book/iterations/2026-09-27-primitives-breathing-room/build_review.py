"""Publish the frozen manuscript comparison and update manuscript pointers."""
from pathlib import Path
import difflib, hashlib, html, json, re
import markdown

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
BASE = '/book-review/doc/book/iterations/' + HERE.name + '/'
NAMES = ['Point_Trace', 'Point_Line_Grid', 'Primitives_Portals']
TITLES = dict(zip(NAMES, ['Trace', 'Grid', 'Portals']))
REASONS = [
    'Keep the movement gate and the short memory legible; give exact settings a companion. The ball, the head and the pause still produce different records.',
    'Keep rounding concrete, then leave room to dance with the interval. Distinguish the transformed drawing from its unchanged source without interrupting the walk with page controls.',
    'Keep the reverse walk and the halving demonstration. Let the shrinking gap carry the question, with fewer prompts to predict each button press.'
]
FILES = [f'commons/maps/{n}/final.md' for n in NAMES] + ['commons/maps/Point_Line_Grid/technical.md']
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
def read(path):
    return path.read_text(encoding='utf-8-sig')
def render(text):
    return markdown.markdown(text, extensions=['footnotes','fenced_code','tables'])
checks = []
def check(name, result):
    checks.append({'name':name, 'passed':bool(result)})
    if not result:
        raise ValueError(name)
stats = {}
for name in NAMES:
    path = ROOT/'commons/maps'/name/'final.md'
    old, new = read(HERE/'before'/path.relative_to(ROOT)), read(path)
    anchors = lambda t: re.findall(r'<!--\s*@([^>]*?)\s*-->', t)
    check(name+': encounter order retained', anchors(old) == anchors(new))
    definitions = re.findall(r'^\[\^([^\]]+)\]:', new, re.M)
    references = re.findall(r'\[\^([^\]]+)\](?!:)', new)
    check(name+': footnotes complete and unique', set(references)==set(definitions) and len(definitions)==len(set(definitions)))
    check(name+': code fences balanced', len(re.findall('^'+chr(96)*3, new, re.M))%2 == 0)
    urls = lambda t: set(re.findall(r'\]\((https?://[^)]+)\)', t))
    check(name+': external references retained', urls(old) <= urls(new))
    stats[name] = dict(before=len(old.split('\n[^')[0].split()), after=len(new.split('\n[^')[0].split()))
trace = read(ROOT/'commons/maps/Point_Trace/final.md')
grid = read(ROOT/'commons/maps/Point_Line_Grid/final.md')
portals = read(ROOT/'commons/maps/Primitives_Portals/final.md')
check('Point Zero counter reference', "Point Zero's counter keeps running" in trace)
ball = lambda t:t.split('## After the hand lets go')[1].split('## A line you did not hold')[0]
check('Ball encounter retained verbatim', ball(trace)==ball(read(HERE/'before/commons/maps/Point_Trace/final.md')))
check('Grid rounding calculation retained', 'var index = roundi(pos.x / grid_size)' in grid)
check('Grid controls in companion', all(s in read(ROOT/'commons/maps/Point_Line_Grid/technical.md') for s in ['PREVIOUS and NEXT','AUTO resumes']))
check('Trace exact settings in tutorial', all(s in read(ROOT/'commons/maps/Point_Trace/tutorial.md') for s in ['snappedf(rec.x, s)','4096','10, 40 and 80']))
check('Portals exact distance in companion', '0.005859375' in read(ROOT/'commons/maps/Primitives_Portals/technical.md'))
check('Stage schedule distinguished from physical motion', 'That schedule does not reproduce the shrinking durations' in portals)
for rel in FILES:
    source = ROOT/rel
    old, new = read(HERE/'before'/rel), read(source)
    dest = HERE/'current'/rel
    dest.parent.mkdir(parents=True,exist_ok=True)
    dest.write_bytes(source.read_bytes())
    diff = HERE/'diffs'/(rel+'.diff')
    diff.parent.mkdir(parents=True,exist_ok=True)
    diff.write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+rel,tofile='current/'+rel)),encoding='utf-8')
core_path = ROOT/'commons/data/museum_core_encounters.json'
core = json.loads(read(core_path))
original = json.loads(read(core_path))
for name in NAMES:
    core['rooms'][name]['text_sha256'] = sha(ROOT/'commons/maps'/name/'final.md')
    core['rooms'][name]['local_review'] = 'http://localhost:3003'+BASE+'index.html#reading-'+name
check('Other curation entries preserved', {k:v for k,v in core['rooms'].items() if k not in NAMES}=={k:v for k,v in original['rooms'].items() if k not in NAMES})
core_path.write_bytes((json.dumps(core,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
(HERE/'current-sha256.json').write_text(json.dumps({rel:sha(ROOT/rel) for rel in FILES},indent=2)+'\n',encoding='utf-8')
(HERE/'checks.json').write_text(json.dumps(dict(passed=all(c['passed'] for c in checks),checks=checks,reading_words=stats),indent=2)+'\n',encoding='utf-8')
readings, comparisons = [], []
for name, reason in zip(NAMES,REASONS):
    old = read(HERE/'before/commons/maps'/name/'final.md')
    new = read(ROOT/'commons/maps'/name/'final.md')
    readings.append(f'<article class="reading" id="reading-{name}"><p class="eyebrow">{TITLES[name]} · CANONICAL FINAL.MD</p><p class="links"><a href="/compose/sources?map={name}&amp;doc=final">Read and comment in Sources</a> · <a href="#diff-{name}">Compare this chapter</a></p>{render(new)}</article>')
    table = difflib.HtmlDiff(wrapcolumn=64).make_table(old.splitlines(),new.splitlines(),'Before this pass','Current final.md',context=True,numlines=3)
    s = stats[name]
    comparisons.append(f'<section id="diff-{name}"><h3>{TITLES[name]}</h3><p>{reason}</p><p class="links">{s["before"]:,} → {s["after"]:,} words before endnotes, including code. <a href="#reading-{name}">Read continuously</a> · <a href="diffs/commons/maps/{name}/final.md.diff">Plain diff</a></p><div class="diff-scroll">{table}</div></section>')
css = """*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:35px}body{margin:0;background:#f1eee7;color:#252a27;font:19px/1.8 Georgia,serif}main{max-width:1240px;margin:auto;padding:46px 26px 90px}header{max-width:850px}h1{font-size:clamp(40px,6vw,70px);font-weight:normal;line-height:1.12;letter-spacing:-.03em}h2,h3{font-weight:normal;line-height:1.3}h2{font-size:31px;margin-top:2em}h3{font-size:26px}a{color:#37594b;text-underline-offset:4px}a:hover{color:#161c16}.eyebrow,nav,.links,summary,figcaption{font:13px/1.65 system-ui,sans-serif}.eyebrow{letter-spacing:.12em}nav{display:flex;gap:12px 24px;flex-wrap:wrap;padding:17px 0;border-block:1px solid #ccc8bd}header>p{max-width:740px}.reading{max-width:760px;margin:85px auto;padding-top:24px;border-top:1px solid #c9c5ba}.reading h1{font-size:43px;letter-spacing:-.02em}.reading p{margin:1.1em 0}.reading .footnote{font-size:15px;line-height:1.65}.reading img{max-width:100%}code{font-size:.82em}pre{background:#e5e3db;padding:18px;overflow:auto;line-height:1.6}pre code{font-size:14px}#changes{margin-top:100px}#changes>section{padding:22px 0 44px}#changes p{max-width:850px}.diff-scroll{overflow:auto;border:1px solid #ccc8bd;max-height:700px}table.diff{border-collapse:collapse;width:100%;font:12px/1.55 monospace;background:#faf9f5}table.diff th,table.diff td{padding:6px;vertical-align:top}table.diff th{position:sticky;top:0;background:#e4e1d8}.diff_header,.diff_next{background:#ece9e0}.diff_add{background:#dbead9}.diff_sub{background:#f0dcd4}.diff_chg{background:#eee2ac}details{margin-top:35px}summary{cursor:pointer}footer{font:14px/1.7 system-ui;border-top:1px solid #ccc8bd;margin-top:60px;padding-top:24px;max-width:820px}@media(max-width:650px){main{padding:25px 18px}body{font-size:18px}.reading{margin-top:55px}.reading h1{font-size:35px}}"""
page = f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Primitives — room to read</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">PRIMITIVES · 27 SEPTEMBER 2026 · EDITORIAL PASS</p><h1>Room to read.</h1><p>The hand leaves a line. An address waits while the body moves. A gap shrinks without disappearing. Three chapters now spend less time directing each action and more time with what the encounter lets us notice.</p>
<nav><a href="#reading-Point_Trace">Trace</a><a href="#reading-Point_Line_Grid">Grid</a><a href="#reading-Primitives_Portals">Portals</a><a href="#changes">Before / after</a><a href="primitives-book.md">Full Primitives capture</a></nav>
<p>All three revised texts are in their canonical <code>final.md</code> files. Exact settings remain available through the notes and technical companions. Every encounter stays in the same reading order.</p></header>
<section id="reading">{''.join(readings)}</section>
<section id="changes"><h2>Before and after</h2><p>These comparisons start from the manuscripts immediately before this pass. Green marks additions; rose marks removals. The continuous reading above includes the full current chapters.</p>{''.join(comparisons)}</section>
<details><summary>Decisions and future returns</summary>{render(read(HERE/'DECISIONS.md'))}</details>
<footer><p>This is a text revision. Previous museum captures and runtime checks remain with their original reviews. This pass checks encounter markers, references, companions and publication; it makes no new claim about VR comfort or learner testing.</p><p><a href="checks.json">Publication checks</a> · <a href="current-sha256.json">Source versions</a> · <a href="DECISIONS.md">Editorial decisions</a></p></footer>
</main></body></html>"""
for filename in ['primitives-book.md', 'primitives-book.manifest.json']:
    (HERE/filename).write_bytes((ROOT/'doc/book/captures/primitives'/filename).read_bytes())
(HERE/'index.html').write_text(page,encoding='utf-8')
print(json.dumps(dict(url='http://localhost:3003'+BASE+'index.html',reading_words=stats,checks_passed=len(checks)),indent=2))
