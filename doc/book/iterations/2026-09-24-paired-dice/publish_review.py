from pathlib import Path
import json, re, hashlib, difflib, html
from collections import Counter
H=Path(__file__).resolve().parent
R=H.parents[3]
def read(p): return p.read_text(encoding='utf-8')
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def data(p):return json.loads(read(p))
def save(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8')
checks=[]
def check(name,passed):
 checks.append({'name':name,'passed':bool(passed)})
 if not passed:raise AssertionError(name)
paths=[p.relative_to(H/'before') for p in (H/'before').rglob('*') if p.is_file()]
manifest=[];diff=[]
for f in sorted(paths):
 a=H/'before'/f;b=R/f;save(H/'after'/f,read(b));x=read(a);y=read(b)
 if f.as_posix()=='commons/data/museum_core_encounters.json':
  x=json.dumps({k:json.loads(x)['rooms'][k] for k in ['Random_Cubes','Random_Gaussian']},ensure_ascii=False,indent=2)+'\n'
  y=json.dumps({k:json.loads(y)['rooms'][k] for k in ['Random_Cubes','Random_Gaussian']},ensure_ascii=False,indent=2)+'\n'
 diff.extend(difflib.unified_diff(x.splitlines(True),y.splitlines(True),fromfile='before/'+f.as_posix(),tofile='after/'+f.as_posix()))
 manifest.append({'path':f.as_posix(),'before_sha256':digest(a),'after_sha256':digest(b)})
for f in sorted((R/'commons/artifacts/paired_dice_column').iterdir()):
 if not f.is_file():continue
 rel=f.relative_to(R);manifest.append({'path':rel.as_posix(),'after_sha256':digest(f)});save(H/'after'/rel,read(f))
 diff.extend(difflib.unified_diff([],read(f).splitlines(True),fromfile='/dev/null',tofile='after/'+rel.as_posix()))
save(H/'changes.diff',''.join(diff));save(H/'source-manifest.json',json.dumps(manifest,indent=2)+'\n')
old=data(H/'before/commons/maps/Random_Cubes/map_data.json');new=data(R/'commons/maps/Random_Cubes/map_data.json')
check('floor and utilities retained',all(new['layers'][k]==old['layers'][k] for k in ['structure','utilities']))
check('all layer rows match 12 by 20 dimensions',all(len(v)==20 and all(len(row)==12 for row in v) for v in new['layers'].values()))
def placements(d):return Counter(t.strip() for row in d['layers']['interactables'] for t in row if t.strip())
check('all former artifacts retained',placements(new)-Counter({'paired_dice_column:180':1})==placements(old))
check('paired dice correctly placed',new['layers']['interactables'][4][5]=='paired_dice_column:180')
changed=[(x,z) for z,(a,b) in enumerate(zip(old['layers']['interactables'],new['layers']['interactables'])) for x,(u,v) in enumerate(zip(a,b)) if u!=v]
check('only paired dice placement and sphere relocation change cells',set(changed)=={(5,4),(6,4),(9,5)})
oldseq=data(H/'before/commons/maps/sequences/randomness.json');newseq=data(R/'commons/maps/sequences/randomness.json')
check('fourteen-hall order retained',oldseq['sequences']['randomness']['maps']==newseq['sequences']['randomness']['maps'] and len(newseq['sequences']['randomness']['maps'])==14)
text=read(R/'commons/maps/Random_Cubes/final.md');before=read(H/'before/commons/maps/Random_Cubes/final.md')
back=re.sub(r'<!-- @paired_dice_column -->\s*.*?<!-- @ -->\s*','',text,flags=re.S).replace('Across from the first die,','Further along the entrance wall,').replace(' The paired dice let the same height keep different ingredients.','')
check('existing Random Cubes prose retained except two declared connective edits',back==before)
gtext=read(R/'commons/maps/Random_Gaussian/final.md');gprev=read(H/'before/commons/maps/Random_Gaussian/final.md')
added="The two dice could reach the same height by different throws. Their coloured columns kept those ingredients visible. Here we gather values into groups. What will the new picture keep of their differences?\n\n"
check('Gaussian prose retained with one return paragraph',gtext.replace(added,'')==gprev)
core=data(R/'commons/data/museum_core_encounters.json')['rooms']
for room in ['Random_Cubes','Random_Gaussian']:
 check(room+' text hash current',core[room]['text_sha256']==digest(R/f'commons/maps/{room}/final.md'))
check('five book encounters match primary order',core['Random_Cubes']['primary_tokens']==re.findall(r'<!-- @([a-z_]+) -->',text))
native=data(H/'native-checks.json');museum=data(H/'museum-runtime.json')
check('29 native checks pass',len(native['checks'])==29 and all(c['passed'] for c in native['checks']) and not native['failures'])
check('12 museum checks pass',len(museum['checks'])==12 and all(c['passed'] for c in museum['checks']) and not museum['failures'])
check('three sampled walking routes and approach floor pass',len(museum['walks'])==3 and all(w['passed'] for w in museum['walks']) and all(r['passed'] for r in museum['rays']))
check('real museum pair history matches photographed comparison',museum['pair_state']['history']==[[3,4],[5,2]])
for f in ['empty.png','three-plus-four.png','five-plus-two.png','room.png']:check('capture exists: '+f,(H/f).stat().st_size>1000)
concurrent_before=data(H/'before/commons/data/museum_core_encounters.json')['rooms']
other_changes=[k for k,v in core.items() if k not in ['Random_Cubes','Random_Gaussian'] and v!=concurrent_before.get(k)]
report={'checks':checks,'passed':True,'scope':'Focused preservation and evidence checks; shared core rows outside the two edited rooms are excluded from this change report.','other_core_rows_changed_during_work':other_changes}
save(H/'publication-checks.json',json.dumps(report,indent=2)+'\n')
save(H/'before-final.md',before);save(H/'after-final.md',text)
passage=re.search(r'<!-- @paired_dice_column -->\s*(.*?)\s*<!-- @ -->',text,re.S).group(1)
save(H/'new-passage.md',passage+'\n')
def prose(s):
 s=re.sub(r'<!--.*?-->','',s,flags=re.S).strip()
 return ''.join('<p>'+re.sub(r'\*\*(.*?)\*\*',r'<strong>\1</strong>',html.escape(p))+'</p>' for p in re.split(r'\n\s*\n',s))
body=f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Two throws, one height — Ada Research</title><style>
:root{{color-scheme:light;--paper:#f4f0e8;--ink:#262825;--muted:#656960;--blue:#11637b;--pink:#ab355e}}*{{box-sizing:border-box}}body{{margin:0;background:var(--paper);color:var(--ink);font:18px/1.65 system-ui,sans-serif}}main{{max-width:1180px;margin:auto;padding:42px 26px 90px}}h1{{font:clamp(2.3rem,5vw,4.2rem)/1.08 Georgia,serif;max-width:850px}}h2{{font:2rem/1.25 Georgia,serif;margin-top:2.4em}}.eyebrow{{letter-spacing:.12em;text-transform:uppercase;font-size:.78rem;color:var(--muted)}}.lead{{max-width:810px;font-size:1.3rem}}a{{color:var(--blue);text-underline-offset:.2em}}nav{{display:flex;gap:1.1em;flex-wrap:wrap;font-size:.9rem;margin:2em 0}}figure{{margin:0}}img{{width:100%;height:auto;display:block;border-radius:5px}}figcaption{{font-size:.85rem;color:var(--muted);padding:.65em 0 1.5em}}.pair{{display:grid;grid-template-columns:1fr 1fr;gap:20px}}.reading{{max-width:730px;font:1.15rem/1.8 Georgia,serif}}blockquote{{border-left:4px solid var(--pink);margin:2em 0;padding:.2em 1.3em;max-width:850px;font:1.55rem/1.5 Georgia,serif}}.note{{background:#e7e4dc;padding:1.2em 1.5em;border-radius:6px}}.small{{font-size:.88rem;color:var(--muted)}}details{{margin:1.5em 0}}summary{{cursor:pointer}}table{{border-collapse:collapse;width:100%;font-size:.93rem}}th,td{{padding:.65em;text-align:left;vertical-align:top;border-bottom:1px solid #ccc7ba}}@media(max-width:760px){{.pair{{grid-template-columns:1fr}}main{{padding:26px 18px}}}}
</style><main><div class="eyebrow">Ada Research · Random Cubes · 24 September 2026</div><h1>Two throws,<br>one height.</h1><p class="lead">Two dice become a column. Its height adds their results; its colours keep their separate contributions. Can the same height return by another pair of throws?</p>
<nav><a href="#encounter">In the hall</a><a href="#reading">New book passage</a><a href="text-diff.html">Before / after text</a><a href="#evidence">Evidence</a><a href="http://localhost:3003/compose/sources?map=Random_Cubes&amp;doc=final">Current chapter</a><a href="http://localhost:3003/necklace/thread?map=Random_Cubes&amp;role=primary">Primary encounters</a></nav>
<figure id="encounter"><a href="room.png"><img src="room.png" alt="The paired dice and column in the Random Cubes museum hall, behind the original throwing table"></a><figcaption>Built in Random_Cubes, after the original die. Both throwing trays, the large sum column and the shelf of recent pairs belong to one new primary artifact. Actual Godot museum render.</figcaption></figure>
<div class="pair"><figure><a href="three-plus-four.png"><img src="three-plus-four.png" alt="A column made from three blue and four pink units"></a><figcaption><strong>3 + 4 = 7.</strong> Three blue units and four pink ones. The shelf begins its record.</figcaption></figure><figure><a href="five-plus-two.png"><img src="five-plus-two.png" alt="A column made from five blue and two pink units, with both recent pairs on the shelf"></a><figcaption><strong>5 + 2 = 7.</strong> The height returns. The join moves. Both pairs remain on the shelf.</figcaption></figure></div>
<p class="small">Comparison captures use controlled physical drops to land these particular faces. They demonstrate reading, composition and retained history; they are not a random sample or a headset session.</p>
<blockquote>Look only at their tops. Now look at the join between the colours. Each view lets you call something different the same.</blockquote>
<h2>What this adds</h2><p>The visitor already knows the die as a physical event with a numerical result. Now two results compose a form. The column makes addition visible, and its two colours complicate what an equal result means. Later, Random_Gaussian returns to the question as values are gathered into groups.</p>
<p>There is no demonstration running on arrival: the column and shelf wait for throws. Both dice must be released again for a new pair. A die that falls away returns without adding an invented result. The shelf keeps the latest twelve pairs while the total count continues.</p>
<details><summary>See the encounter before any throws</summary><figure><a href="empty.png"><img src="empty.png" alt="Empty sum plinth and history shelf with the two dice ready"></a><figcaption>Empty on arrival. The visitor supplies the evidence.</figcaption></figure></details>
<h2 id="reading">New book passage</h2><div class="reading">{prose(passage)}</div>
<p><a href="text-diff.html">Read the exact manuscript comparison</a> · <a href="new-passage.md">Copy the new passage</a></p>
<details><summary>Read the complete revised Random Cubes chapter</summary><div class="reading">{prose(text)}</div></details>
<h2 id="evidence">What was checked</h2><table><tr><th>Layer</th><th>Result</th></tr><tr><td>Native interaction</td><td>29 checks pass: real rigid-body face readings, held-die exclusion, fresh pairs, bounded history, clearing and recovery at a translated, rotated host.</td></tr><tr><td>Museum</td><td>12 checks pass, plus three sampled walking routes and a floor ray. Registry loading, placement and both physical comparison pairs verified.</td></tr><tr><td>Preservation</td><td>All previous artifacts remain. The secondary dark sphere moves aside. Floor and utilities are unchanged; declared width now matches the existing twelve cells. The fourteen-hall sequence stays in order.</td></tr><tr><td>Book</td><td>One new encounter after the original die, two connective edits, and a brief return in Random_Gaussian. Five primary encounters now match the Random Cubes book order.</td></tr></table>
<p class="note">Headset reach, comfort and freely thrown results still need an in-headset visit. The probability paragraph explicitly assumes independent, equally likely faces. This implementation does not certify fairness; the ideal two-dice sum is triangular, not Gaussian.</p>
<details><summary>Files, decisions and source provenance</summary><p><a href="DECISIONS.md">Decisions</a> · <a href="changes.diff">Scoped source diff</a> · <a href="source-manifest.json">Source hashes</a> · <a href="publication-checks.json">Preservation checks</a> · <a href="native-checks.json">Native results</a> · <a href="museum-runtime.json">Museum results</a></p><p>The source diff isolates our two room records in the shared encounter file. Complete snapshots can also contain concurrent updates from other work. Original die implementation retained; the new local variant reuses its physical faces and pickup behaviour.</p><p>Started from the multiple-dice discussion in <a href="https://www.youtube.com/watch?v=Srgva9gEJDw&amp;t=545s">Uncertainty in Games</a>. The <a href="../2026-09-24-randomness-physical-examples/index.html">research proposal</a> and its <a href="../2026-09-24-randomness-physical-examples/SOURCES.md">sources</a> distinguish probability distributions, temporal correlation and when uncertainty enters a decision.</p></details>
<p class="small">Next encounter to investigate: two visible hoppers, sampling with and without replacement, in Random_Remove.</p></main></html>'''
save(H/'index.html',body)
for link in re.findall(r'(?:href|src)="([^"]+)"',body):
 if link.startswith(('http:','https:','#')):continue
 check('review link exists: '+link,(H/link).exists())
save(H/'publication-checks.json',json.dumps(report,indent=2)+'\n')
print(f'Published review; {len(checks)} preservation, result and link checks pass.')
