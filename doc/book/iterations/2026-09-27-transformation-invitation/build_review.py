from pathlib import Path
import difflib, hashlib, html, json, re
import markdown
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
MAP='Trans_Pre'
URL='http://localhost:3003/book-review/doc/book/iterations/'+HERE.name+'/index.html'
def read(p):return p.read_text(encoding='utf-8-sig')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def render(s):return markdown.markdown(s,extensions=['footnotes','fenced_code','tables'])
old=read(HERE/'before/commons/maps/Trans_Pre/final.md')
new=read(ROOT/'commons/maps/Trans_Pre/final.md')
checks=[]
def check(name,ok):
    checks.append(dict(name=name,passed=bool(ok)))
    assert ok,name
check('Encounter marker unchanged',re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',new))
check('Three code excerpts retained', re.findall(chr(96)*3+'gdscript(.*?)'+chr(96)*3,old,re.S)==re.findall(chr(96)*3+'gdscript(.*?)'+chr(96)*3,new,re.S))
check('Recognisable operations retained',all(s in new for s in ['**translation**','**rotation**','**scale**']))
check('Conditional first collection retained', 'The still cube has gone if you collected it; the three moving examples remain.' in new)
check('Melencolia handover retained',new.split('\n\n')[1]==old.split('\n\n')[1])
check('Next-hall handover retained',new[new.index('Translation kept its size and facing.'):]==old[old.index('Translation kept its size and facing.'):])
for rel in ['commons/maps/Trans_Pre/map_data.json','commons/maps/Trans_Pre/tutorial.md','commons/scenes/mapobjects/pick_up_cube.gd']:
    check('Preserved '+rel,sha(ROOT/rel)==sha(HERE/'before'/rel))
current_map=json.loads(read(ROOT/'commons/maps/Trans_Pre/map_data.json'))
grid=current_map['layers']['interactables']
check('First cube collectible at (4,3)',grid[3][4].startswith('pick_up_cube:') and '#hold:collect' in grid[3][4])
check('Three moving demonstrations remain', all('#hold:demo' in grid[z][4] for z in [5,8,11]))
for name in ['final.md','intent.md']:
    p=ROOT/'commons/maps/Trans_Pre'/name
    (HERE/('current-'+name)).write_bytes(p.read_bytes())
    (HERE/(name+'.diff')).write_text(''.join(difflib.unified_diff(read(HERE/'before/commons/maps/Trans_Pre'/name).splitlines(True),read(p).splitlines(True),fromfile='before/'+name,tofile='current/'+name)),encoding='utf-8')
core_path=ROOT/'commons/data/museum_core_encounters.json'
core=json.loads(read(core_path))
core['rooms'][MAP]['text_sha256']=sha(ROOT/'commons/maps/Trans_Pre/final.md')
core['rooms'][MAP]['local_review']=URL+'#reading'
core_path.write_bytes((json.dumps(core,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
for name in ['transformation-book.md','transformation-book.manifest.json']:
    (HERE/name).write_bytes((ROOT/'doc/book/captures/transformation'/name).read_bytes())
(HERE/'checks.json').write_text(json.dumps(dict(passed=True,checks=checks,scope='Text, authored placement and relevant source branches; no new runtime or headset test'),indent=2)+'\n',encoding='utf-8')
table=difflib.HtmlDiff(wrapcolumn=62).make_table(old.splitlines(),new.splitlines(),'Before this pass','Current final.md',context=True,numlines=3)
css="""*{box-sizing:border-box}html{scroll-behavior:smooth}body{background:#f3efe7;color:#2d302b;margin:0;font:19px/1.8 Georgia,serif}main{max-width:1210px;margin:auto;padding:42px 25px 80px}header,.reading,.decisions{max-width:760px;margin:0 auto}h1,h2{font-weight:normal;line-height:1.2}header h1{font-size:clamp(40px,6vw,64px)}h2{margin-top:2em}a{color:#3e6552;text-underline-offset:4px}nav,.eyebrow,summary,footer{font:14px/1.7 system-ui}nav{display:flex;flex-wrap:wrap;gap:12px 23px;padding:16px 0;border-block:1px solid #c9c5ba}.reading{margin-top:70px;padding-top:20px;border-top:1px solid #c9c5ba}.reading h1{font-size:40px}pre{padding:20px;background:#e5e2d8;overflow:auto;line-height:1.6}code{font-size:.82em}pre code{font-size:14px}.diff-scroll{overflow:auto;max-height:760px;border:1px solid #c9c5ba}table.diff{font:12px/1.55 monospace;background:#faf9f6;border-collapse:collapse}table.diff td,table.diff th{padding:6px;vertical-align:top}.diff_header,.diff_next{background:#e5e2d8}.diff_add{background:#dcebd7}.diff_sub{background:#f0dbd3}.diff_chg{background:#eee2ab}details{margin-top:35px}summary{cursor:pointer}footer{max-width:760px;margin:55px auto 0;padding-top:20px;border-top:1px solid #c9c5ba}@media(max-width:600px){main{padding:25px 16px}body{font-size:18px}}"""
page=f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Transformation — an invitation to collect</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">TRANS_PRE · 27 SEPTEMBER 2026 · WRITING PILOT</p><h1>A cube you can take.</h1><p>The opening keeps its simple progression: meet a still cube, watch movements join it, then walk up the wedges and collect one. The room is described before the close observations begin.</p><nav><a href="#reading">Read the revision</a><a href="#changes">Before / after</a><a href="#decisions">Two editing passes</a><a href="transformation-book.md">Full Transformation capture</a></nav></header>
<article class="reading" id="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Trans_Pre&amp;doc=final">READ AND COMMENT IN SOURCES</a></p>{render(new)}</article>
<section id="changes"><h2>Before and after</h2><p><a href="final.md.diff">Plain text diff</a> · <a href="intent.md.diff">Intent correction</a></p><div class="diff-scroll">{table}</div></section>
<section class="decisions" id="decisions">{render(read(HERE/'DECISIONS.md'))}</section>
<footer><p>The source confirms the collection sound and removal, the animation branches and the four-station arrangement. These are source checks; no new museum or headset test was needed for this prose pass.</p><p><a href="checks.json">Checks and scope</a> · <a href="feedback.txt">Supplied feedback</a> · <a href="/book-review/doc/book/iterations/2026-09-25-private-writing-notes/index.html#Trans_Pre">Private encounter note</a></p></footer>
</main></body></html>"""
(HERE/'index.html').write_text(page,encoding='utf-8')
print(json.dumps(dict(url=URL,checks=len(checks),words_before=len(old.split()),words_after=len(new.split())),indent=2))
