from pathlib import Path
import difflib, hashlib, json, re
import markdown

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
MAP = 'Trans_Introduction'
PREFIX = 'commons/maps/' + MAP + '/'
URL = 'http://localhost:3003/book-review/doc/book/iterations/' + HERE.name + '/index.html'
def read(p): return p.read_text(encoding='utf-8-sig')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def render(s): return markdown.markdown(s, extensions=['footnotes', 'fenced_code', 'tables'])
old = read(HERE/'before'/PREFIX/'final.md')
new = read(ROOT/PREFIX/'final.md')
baseline = json.loads(read(HERE/'before-sha256.json'))
checks = []
def check(name, ok):
    checks.append(dict(name=name, passed=bool(ok)))
    assert ok, name
check('Encounter markers preserved in order', re.findall(r'<!--.*?-->', old) == re.findall(r'<!--.*?-->', new))
code_pattern = chr(96)*3 + r'gdscript(.*?)' + chr(96)*3
check('All five code excerpts retained unchanged', len(re.findall(code_pattern, new, re.S)) == 5 and re.findall(code_pattern, old, re.S) == re.findall(code_pattern, new, re.S))
check('Opening and first gap retained', old.split('<!-- @tc -->')[0] == new.split('<!-- @tc -->')[0])
check('Closing and next-hall handover retained', old.rsplit('<!-- @ -->', 1)[1] == new.rsplit('<!-- @ -->', 1)[1])
check('Bank agreement retained', 'The crossing has lost one of its agreements.' in new)
check('Both existing museum images retained', re.findall(r'!\[[^\]]*\]\(([^)]+)\)', old) == re.findall(r'!\[[^\]]*\]\(([^)]+)\)', new))
for rel, digest in baseline.items():
    if rel not in [PREFIX+'final.md', PREFIX+'intent.md', 'commons/data/museum_core_encounters.json']:
        check('Unchanged: ' + rel, sha(ROOT/rel) == digest)
m = json.loads(read(ROOT/PREFIX/'map_data.json'))
check('Ferry at (5,6)', m['layers']['utilities'][6][5] == 'tc:2:z:auto')
check('Scale at deck with zero added lowering', m['layers']['utilities'][12][4] == 'sc:3:0.5:1:0#seat:deck')
check('Narrow bridge at deck with zero added lowering', m['layers']['utilities'][17][5] == 'rc:90:y:4:0#profile:bridge#seat:deck' and 'Vector3(3.6, 0.2, 1.0)' in read(ROOT/'commons/scenes/mapobjects/rotation_cube.gd'))
core = json.loads(read(ROOT/'commons/data/museum_core_encounters.json'))
prior = json.loads(read(HERE/'before/commons/data/museum_core_encounters.json'))
expected = json.loads(json.dumps(prior))
expected['rooms'][MAP]['text_sha256'] = sha(ROOT/PREFIX/'final.md')
expected['rooms'][MAP]['local_review'] = URL+'#reading'
check('Only this hall text hash and review link changed in core metadata', core == expected)
check('Learner validation not promoted', core['rooms'][MAP]['learner_verified'] is False)
manifest_path = ROOT/'doc/book/captures/transformation/transformation-book.manifest.json'
manifest = json.loads(read(manifest_path))
check('Seven-hall Transformation capture current', len(manifest['maps']) == 7 and all(sha(ROOT/item['path']) == item['sha256'] for item in manifest['maps']))
capture = ROOT/'doc/book/captures/transformation/transformation-book.md'
check('Capture content matches manifest', sha(capture) == manifest['output_sha256'])
for source in [capture, manifest_path]: (HERE/source.name).write_bytes(source.read_bytes())
for name in ['final.md', 'intent.md']:
    current = ROOT/PREFIX/name
    (HERE/('current-'+name)).write_bytes(current.read_bytes())
    (HERE/(name+'.diff')).write_text(''.join(difflib.unified_diff(read(HERE/'before'/PREFIX/name).splitlines(True), read(current).splitlines(True), fromfile='before/'+name, tofile='current/'+name)), encoding='utf-8')
comparison = difflib.HtmlDiff(wrapcolumn=62).make_table(old.splitlines(), new.splitlines(), 'Before this pass', 'Current final.md', context=True, numlines=3)
css = """*{box-sizing:border-box}html{scroll-behavior:smooth}body{background:#f3efe7;color:#2d302b;margin:0;font:19px/1.8 Georgia,serif}main{max-width:1210px;margin:auto;padding:42px 25px 80px}header,.reading,.decisions{max-width:760px;margin:0 auto}h1,h2{font-weight:normal;line-height:1.2}header h1{font-size:clamp(40px,6vw,64px)}h2{margin-top:2em}a{color:#3e6552;text-underline-offset:4px}nav,.eyebrow,summary,footer{font:14px/1.7 system-ui}nav{display:flex;flex-wrap:wrap;gap:12px 23px;padding:16px 0;border-block:1px solid #c9c5ba}.reading{margin-top:70px;padding-top:20px;border-top:1px solid #c9c5ba}.reading h1{font-size:40px}.reading img{display:block;width:100%;height:auto;margin:32px 0 12px;background:#e5e2d8}.reading p:has(>em:only-child){font-size:16px;color:#50574d}pre{padding:20px;background:#e5e2d8;overflow:auto;line-height:1.6}code{font-size:.82em}pre code{font-size:14px}.diff-scroll{overflow:auto;max-height:760px;border:1px solid #c9c5ba}table.diff{font:12px/1.55 monospace;background:#faf9f6;border-collapse:collapse}table.diff td,table.diff th{padding:6px;vertical-align:top}.diff_header,.diff_next{background:#e5e2d8}.diff_add{background:#dcebd7}.diff_sub{background:#f0dbd3}.diff_chg{background:#eee2ab}footer{max-width:760px;margin:55px auto 0;padding-top:20px;border-top:1px solid #c9c5ba}@media(max-width:600px){main{padding:25px 16px}body{font-size:18px}}"""
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Transformation — crossing the gap</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">TRANS_INTRODUCTION · 27 SEPTEMBER 2026 · WRITING PASS</p><h1>The far bank is already there.</h1><p>Three ways across a gap. Return to the turning plank and move the place it needs to reach.</p><nav><a href="#reading">Read the revision</a><a href="#changes">Before / after</a><a href="#decisions">Editorial decisions</a><a href="transformation-book.md">Full Transformation capture</a></nav></header>
<article class="reading" id="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Trans_Introduction&amp;doc=final">READ AND COMMENT IN SOURCES</a></p>{render(new)}</article>
<section id="changes"><h2>Before and after</h2><p><a href="final.md.diff">Plain text diff</a> · <a href="intent.md.diff">Intent correction</a></p><div class="diff-scroll">{comparison}</div></section>
<section class="decisions" id="decisions">{render(read(HERE/'DECISIONS.md'))}</section>
<footer><p>The bank pair shows two settings inside the museum. These existing photographs are retained unchanged. This pass checks prose against source and authored placement; it does not add a runtime or headset test.</p><p><a href="checks.json">Checks and scope</a> · <a href="/compose/sources?map=Trans_Introduction&amp;doc=tutorial">Companion tutorial</a> · <a href="/book-review/doc/book/iterations/2026-09-25-private-writing-notes/index.html#Trans_Introduction">Private encounter note</a> · <a href="../2026-09-27-transformation-invitation/index.html#reading">Previous: a cube you can take</a></p></footer>
</main></body></html>'''
(HERE/'index.html').write_text(page, encoding='utf-8')
(HERE/'checks.json').write_text(json.dumps(dict(passed=True, checks=checks, scope='Manuscript, current authored placement, source preservation and capture freshness. No new runtime or headset test.', private_notes='Index refreshed; pre-existing Point_Zero and Point_One note-template and grounding flags are retained, not counted as failures of this chapter.'), indent=2)+'\n', encoding='utf-8')
print(json.dumps(dict(url=URL+'#reading', checks=len(checks), words_before=len(old.split()), words_after=len(new.split())), indent=2))