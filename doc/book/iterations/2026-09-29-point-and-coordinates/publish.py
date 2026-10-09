"""Build the reading/review edition from the current two halls and native evidence."""
from pathlib import Path
import difflib,hashlib,html,json,re,shutil,zipfile
import markdown
ROOT=Path(__file__).resolve().parents[4];OUT=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding='utf-8-sig')
write=lambda p,s:p.write_bytes(s.encode('utf-8'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
render_count=0
def rendered(s):
    global render_count
    render_count+=1
    s=re.sub(r'\[\^([^\]]+)\]',lambda m:'[^part'+str(render_count)+'-'+m[1]+']',s)
    return markdown.markdown(re.sub(r'<!--\s*@[^>]*-->','',s),extensions=['fenced_code','tables','footnotes'])
def figure(src,caption):return '<figure><a href="'+src+'"><img src="'+src+'" alt="'+html.escape(caption,quote=True)+'" loading="lazy"></a><figcaption>'+caption+'</figcaption></figure>'
native=[]
for m in ['Point_One','Point_Coordinates']:
    folder=ROOT/'ada_run/encounter_pilot'/m;target=OUT/m;target.mkdir(exist_ok=True)
    report=json.loads(read(folder/'report.json'));assert report['passed'],report
    native.append(report)
    for p in folder.glob('*.png'):shutil.copy2(p,target/p.name)
    for name in ['report.json','source_manifest.json']:
        if (folder/name).exists():shutil.copy2(folder/name,target/name)
    for name in ['final.md','tutorial.md','intent.md','technical.md','map_data.json']:
        shutil.copy2(ROOT/'commons/maps'/m/name,target/name)
    before=OUT/'before/commons/maps'/m/'final.md'
    diff=''.join(difflib.unified_diff(read(before).splitlines(True) if before.exists() else [],read(target/'final.md').splitlines(True),fromfile='before/'+m+'/final.md',tofile='after/'+m+'/final.md'))
    write(target/'final.diff',diff)

study=ROOT/'doc/book/studies/point-coordinates'
with zipfile.ZipFile(OUT/'point-coordinates-study.zip','w',zipfile.ZIP_DEFLATED) as package:
    for p in study.iterdir():
        if p.is_file() and not p.name.endswith('.uid'):package.write(p,'point-coordinates/'+p.name)

# Source validity, route continuity, and protection against teaching by stale IDs.
sequence=json.loads(read(ROOT/'commons/maps/sequences/primitives.json'))['sequences']['primitives']['maps']
assert sequence[:4]==['Point_Zero','Point_One','Point_Coordinates','Point_Lines']
registry=json.loads(read(ROOT/'commons/artifacts/registry/commons_artifacts.json'))['artifacts']
route_checks=[]
for m in ['Point_One','Point_Coordinates']:
    d=json.loads(read(ROOT/'commons/maps'/m/'map_data.json'));layers=d['layers'];w=d['map_info']['dimensions']['width'];h=d['map_info']['dimensions']['depth']
    assert all(len(layer)==h and all(len(row)==w for row in layer) for layer in layers.values())
    points={}
    for z,row in enumerate(layers['utilities']):
        for x,t in enumerate(row):
            if t.split(':')[0] in ['s','sp']:points['spawn']=(x,z)
            if t.startswith('t:'):points['exit']=(x,z)
    seen={points['spawn']};queue=[points['spawn']]
    for x,z in queue:
        for nx,nz in [(x-1,z),(x+1,z),(x,z-1),(x,z+1)]:
            if 0<=nx<w and 0<=nz<h and layers['structure'][nz][nx]=='1' and (nx,nz) not in seen:seen.add((nx,nz));queue.append((nx,nz))
    assert points['exit'] in seen,m+' lacks a floor route'
    for row in layers['interactables']:
        for t in row:
            if t.strip() and t.split(':')[0].split('#')[0].startswith('point_'):
                token=t.split(':')[0].split('#')[0];assert token in registry,token
                assert (ROOT/registry[token]['scene'].removeprefix('res://')).exists()
    route_checks.append(dict(map=m,rectangular=True,spawn_to_exit_floor_connected=True))

counts={r['room']:len(r['checks']) for r in native}
verification=dict(passed=True,native=counts,desktop_study_checks=6,structure=route_checks,atlas_browser_checks=15,scope='Native museum and standalone desktop study; supplied XR pointer/poke and grab routes exercised without a headset. Learner and headset acceptance remain open.')
write(OUT/'verification.json',json.dumps(verification,indent=2)+'\n')
sources=[ROOT/'commons/maps'/m/name for m in ['Point_One','Point_Coordinates'] for name in ['final.md','tutorial.md','map_data.json','intent.md','technical.md']]
sources += [ROOT/'commons/primitives/point/point_sun_switch.gd',ROOT/'commons/primitives/point/point_sun_switch.tscn',ROOT/'commons/maps/sequences/primitives.json',ROOT/'doc/book/tutorial-lineage/curriculum.json']
write(OUT/'source-manifest.json',json.dumps({p.relative_to(ROOT).as_posix():sha(p) for p in sources},indent=2)+'\n')

decision='''# Point One, then Coordinates

29 September 2026. Implemented the author's new boundary in map placement, final.md, tutorial.md and the teaching graph.

- Point One: absent point, visible sphere, identical solid sphere, removable directional light, large pedestal sphere. The position line stays; the component-by-component reading moves out.
- Point Coordinates: starts with the black production pickable, then WORLD/LOCAL, the frame in its floor-level L basin, and the existing target. The older secondary ecology moves with this wider room. Distance remains in Point Lines.
- The actual Point_Zero origin artifact and basin were not edited.
- The light study uses one directional sun and a low, unshadowed fill. Switching off the sun removes the long shadows; mesh and collision stay. The added floor plates have been removed at the author's request: shadows now fall on the museum's existing floor, with its original material and normal lighting. The sun lights that floor on a separate receiver layer, while only the study bodies cast its shadows. Light and floor masks are restored on unload.
- Retired the obsolete August 21 `primitives|point` hand-placement override. It was replacing the current source corridor with the pre-split arrival arrangement. The full original file is preserved under before/ada_run/necklace_hand.json; all other hall entries remain.
- Added a separate, runnable desktop coordinate study. It tests positions, local/global reference and two markers at the same position. The in-project pickup exercise borrows Ada's prepared XR player. A portable XR starter is still pending; the download does not claim to supply it.
- Updated the lineage to 204 halls and 68 proposed capabilities. Point One no longer requires XR; Coordinates depends on the point and the prepared hand; Line depends on Coordinates.

Validation: 25 native Point One checks, 18 native Coordinates checks, six standalone study checks, 15 isolated-browser atlas checks, rectangular layers and connected spawn/exit floors. Native captures are from inside the museum. Runtime warnings from unrelated existing museum resources are not treated as proof of a clean whole-project build. No headset, accessibility or learner-success claim.
'''
decision=decision.replace('25 native Point One checks, 18 native Coordinates checks',str(counts['Point_One'])+' native Point One checks, '+str(counts['Point_Coordinates'])+' native Coordinates checks')
decision+='\nThe coordinate frame was subsequently enlarged and made opaque in pink, grey and black. See ../2026-09-29-coordinates-solid-frame/index.html for the before/after view and fresh native checks.\n'
write(OUT/'DECISIONS.md',decision)
before_text=read(OUT/'before/commons/maps/Point_One/final.md')
one=read(ROOT/'commons/maps/Point_One/final.md');coords=read(ROOT/'commons/maps/Point_Coordinates/final.md')
css='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f2efe7;color:#252a27;font:17px/1.75 Georgia,serif}header,main,footer{max-width:1320px;margin:auto;padding:36px}header{padding-top:64px;border-bottom:1px solid #d3d0c6}h1,h2,h3{font-weight:400;line-height:1.13}h1{font-size:clamp(44px,6vw,80px);max-width:900px;margin:14px 0 24px;letter-spacing:-.035em}h2{font-size:38px;margin-top:44px}h3{font-size:27px}.kicker,nav,.tag,figcaption,.small,summary{font-family:system-ui,sans-serif}.kicker{font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:#686e61}.intro{font-size:24px;max-width:870px}a{color:#34604f;text-underline-offset:4px}nav{display:flex;flex-wrap:wrap;gap:12px 25px;font-size:14px;margin-top:30px}.path{display:flex;flex-wrap:wrap;gap:10px;align-items:center;margin:32px 0;font:14px/1.5 system-ui}.tag{padding:9px 16px;border:1px solid #cccdbf;border-radius:3px;background:#faf8f1}.active{border-color:#628374;background:#e0e7dc}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}figure{margin:0 0 26px}img{width:100%;height:auto;display:block;border:1px solid #dbd6cc}figcaption{font-size:13px;line-height:1.5;margin-top:9px;color:#616758}.reading{max-width:760px;margin:60px auto;border-top:1px solid #c8cbbc;padding-top:22px;font-size:21px;line-height:1.8}.reading h1{font-size:46px}.reading h2{font-size:31px}pre{font:14px/1.7 Consolas,monospace;padding:20px;background:#e7e7dd;overflow:auto}code{font-size:.82em}blockquote{font-size:27px;line-height:1.55;border-left:3px solid #5d7c69;margin:36px 0;padding:8px 25px;max-width:820px}.footnote{font-size:15px;line-height:1.7}.small{font-size:14px;color:#5d6359;max-width:900px}details{margin:30px 0;border:1px solid #d0d2c3;padding:20px}summary{cursor:pointer;font-size:16px}section{scroll-margin-top:24px}.tutorial{max-width:800px;margin:auto;font-size:18px}.comparison{max-width:1000px}.comparison .pair{gap:40px}.comparison h1{font-size:28px}.comparison h2{font-size:25px}.comparison pre{white-space:pre-wrap}footer{border-top:1px solid #d3d0c6;font:14px/1.7 system-ui;padding-bottom:65px}@media(max-width:800px){header,main,footer{padding:25px 18px}.pair{grid-template-columns:1fr}.reading{font-size:19px}.reading h1{font-size:36px}.intro{font-size:21px}h2{font-size:30px}}'''
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Point One / Coordinates · Ada Research</title><style>'''+css+'''</style><body><header><div class="kicker">Ada Research · 29 September 2026 · Two consecutive halls</div><h1>A body in the light.<br>A point in your hand.</h1><p class="intro">First learn what has been given to the point. Then pick it up and ask where it is.</p><div class="path"><span class="tag">Point Zero · begin / continue</span><span>→</span><span class="tag active">Point One · appearance / resistance / light</span><span>→</span><span class="tag active">Coordinates · holding / reference</span><span>→</span><span class="tag">Line · connection / distance</span></div><nav><a href="#museum">Inside the museum</a><a href="#reading">Point One</a><a href="#coordinates">Coordinates</a><a href="#making">Tutorials</a><a href="#changes">What moved</a><a href="/tutorial-lineage#node=coordinates">Updated lineage</a></nav></header><main>
<section id="museum"><h2>Turn the switch.</h2><p class="small">Two captures from the same position in the museum. The switch removes the directional light for these spheres; a dim fill lets us keep seeing their bodies.</p><div class="pair">'''+figure('Point_One/sun-on.png','Sun on. The round bodies leave stretched shadows on the existing museum floor.')+figure('Point_One/sun-off.png','Sun off. The long shadows are gone. The spheres and their collision remain.')+'''</div><blockquote>There is a switch on the wall. Turn it.<br>You have removed their sun.</blockquote><div class="pair">'''+figure('Point_One/wall-switch.png','A physical wall switch, with the museum’s existing hand-poke and pointer input routes.')+figure('Point_Coordinates/held-point.png','The next hall begins with the black point. Take it; the name stays behind.')+'''</div>'''+figure('Point_Coordinates/coordinates-basin.png','The existing frame and both cards move together. The L-shaped basin keeps its glass at floor level.')+'''</section>
<section id="reading" class="reading">'''+rendered(one)+'''<p class="small"><a href="/compose/sources?map=Point_One&amp;doc=final">Current source and revision comments</a></p></section>
<section id="coordinates" class="reading">'''+rendered(coords)+'''<p class="small"><a href="/compose/sources?map=Point_Coordinates&amp;doc=final">Current source and revision comments</a></p></section>
<section id="making"><h2>The lessons have different work to do.</h2><p>The first tutorial changes the point’s appearance and physical boundary. The second begins with borrowing a hold, then learns to read and set its position. The guides and target do not become extra programming assignments.</p><details><summary>Point One — give the point a body</summary><div class="tutorial">'''+rendered(read(ROOT/'commons/maps/Point_One/tutorial.md'))+'''</div></details><details><summary>Point Coordinates — carry a position</summary><div class="tutorial">'''+rendered(read(ROOT/'commons/maps/Point_Coordinates/tutorial.md'))+'''</div></details><p><a href="point-coordinates-study.zip">Download the standalone coordinate study</a></p><p class="small">Godot 4.6 desktop study; six checks passed. Pickup runs in Ada’s prepared XR environment. This download contains no XR player; a portable headset starter remains pending.</p></section>
<section id="changes"><h2>What moved, what stayed.</h2><p>Point One keeps the absent point, two white sphere conditions and the large pedestal sphere. Coordinates receives the held point, its two addresses, the coloured frame and target, together with the existing secondary comparisons. Point Zero’s origin and basin were not edited.</p><p>The canonical final.md files and tutorial.md files are updated. The old coordinate passages remain, with new joins. Their historical and critical questions have a room of their own.</p><div class="pair">'''+figure('Point_One/point-corridor.png','The shorter Point One corridor, seen on arrival.')+figure('Point_One/pedestal.png','The larger point closes the first hall.')+'''</div><details class="comparison"><summary>Read the original combined chapter</summary>'''+rendered(before_text)+'''</details><p><a href="Point_One/final.diff">Point One text diff</a> · <a href="Point_Coordinates/final.md">New Coordinates manuscript</a> · <a href="DECISIONS.md">Decisions and scope</a></p></section>
</main><footer><p>25 Point One checks · 18 Coordinates checks · 6 desktop-study checks · 15 isolated-browser atlas checks. These establish native behavior and source consistency; headset experience and independent learner understanding still need human trials.</p><p><a href="verification.json">Verification</a> · <a href="source-manifest.json">Source versions</a> · <a href="/tutorial-lineage#node=coordinates">Tutorial lineage</a></p></footer></body></html>'''
# Resolve repository-relative Markdown links against their real source location.
page=page.replace('../../../doc/book/studies/point-one/README.md','/book-review/doc/book/studies/point-one/README.md').replace('../../../doc/book/studies/point-coordinates/README.md','/book-review/doc/book/studies/point-coordinates/README.md').replace('../Point_Coordinates/tutorial.md','/compose/sources?map=Point_Coordinates&amp;doc=tutorial')
page=page.replace('25 Point One checks · 18 Coordinates checks',str(counts['Point_One'])+' Point One checks · '+str(counts['Point_Coordinates'])+' Coordinates checks')
page=page.replace('The existing frame and both cards move together. The L-shaped basin keeps its glass at floor level.','The enlarged frame now has opaque pink, grey and black axes. The L-shaped basin keeps its glass at floor level.')
write(OUT/'index.html',page)
print(json.dumps(verification))
