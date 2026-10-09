"""Freeze the tested tool pilot and publish actual museum captures."""
from pathlib import Path
import difflib, hashlib, html, json, shutil
import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
run = ROOT/'ada_run/encounter_pilot/Point_Lines'
report = json.loads((run/'report.json').read_text(encoding='utf-8-sig'))
assert report['passed'] and report['observations']['tool_paths_completed'], report['failures']
for name in ['report.json', 'source_manifest.json']:
    shutil.copy2(run/name, OUT/name)
for name in ['entrance-line', 'catalyst-colour', 'line-broken', 'line-restored']:
    shutil.copy2(run/(name+'.png'), OUT/(name+'.png'))
sources = [
    'commons/interactables/artifact_reactions/router.gd',
    'commons/interactables/artifact_reactions/reaction.gd',
    'commons/interactables/artifact_reactions/README.md',
    'commons/grid/GridInteractablesComponent.gd',
    'commons/scenes/endless_museum.gd',
    'commons/hazards/becoming_catalyst/catalyst_projectile.gd',
    'commons/primitives/laser_measure/laser_measure.gd',
    'commons/artifacts/line_sledgehammer/line_sledgehammer.gd',
    'commons/artifacts/do_not_cross_barrier/do_not_cross_barrier.gd',
    'commons/artifacts/line_relations_gallery/line_relations_gallery.gd',
    'commons/maps/Point_Lines/map_data.json',
    'commons/maps/Point_Lines/final.md',
]
versions={}
text_diff=''
for rel in sources:
    src=ROOT/rel
    versions[rel]=hashlib.sha256(src.read_bytes()).hexdigest()
    dst=OUT/'sources'/rel
    dst.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(src,dst)
    before=OUT/'before'/rel
    if before.exists():
        diff=''.join(difflib.unified_diff(before.read_text(encoding='utf-8-sig').splitlines(True),src.read_text(encoding='utf-8-sig').splitlines(True),fromfile='before/'+rel,tofile='after/'+rel))
        dst.with_suffix(dst.suffix+'.diff').write_text(diff,encoding='utf-8')
        if rel.endswith('final.md'):text_diff=diff
(OUT/'source-versions.json').write_text(json.dumps(versions,indent=2)+'\n',encoding='utf-8')
before=json.loads((OUT/'before/commons/maps/Point_Lines/map_data.json').read_text(encoding='utf-8-sig'))
after=json.loads((ROOT/'commons/maps/Point_Lines/map_data.json').read_text(encoding='utf-8-sig'))
assert before['layers']['structure']==after['layers']['structure']
assert before['layers']['utilities']==after['layers']['utilities']
for oldrow,newrow in zip(before['layers']['interactables'],after['layers']['interactables']):
    for a,b in zip(oldrow,newrow):
        assert b.split('#reactive:')[0]==a
coverage=json.loads((OUT/'coverage.json').read_text(encoding='utf-8'))
assert len(coverage)==41
assert sum(c['policy']!='native/protected' for c in coverage)==34
rows=''.join('<tr><td>'+html.escape(c['artifact'])+'</td><td>'+html.escape(str(c['cell']))+'</td><td>'+html.escape(c['policy'])+'</td></tr>' for c in coverage)
reading=markdown.markdown((ROOT/'commons/maps/Point_Lines/final.md').read_text(encoding='utf-8-sig'),extensions=['fenced_code','footnotes'])
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Break / return · Point Lines</title><style>
*{box-sizing:border-box}body{margin:0;background:#f3eee8;color:#27232a;font:19px/1.7 Georgia,serif}main{max-width:1260px;margin:auto;padding:48px 28px}h1{font-size:clamp(46px,7vw,80px);font-weight:400;line-height:1.08;letter-spacing:-.035em}h2{font-weight:400;font-size:33px}nav,.small,figcaption,table,footer{font:14px/1.6 system-ui,sans-serif;color:#655666}nav{display:flex;gap:24px;flex-wrap:wrap}a{color:#794864;text-underline-offset:4px}.intro{max-width:830px;font-size:24px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:22px}figure{margin:30px 0}img{display:block;width:100%}figcaption{margin-top:8px}#reading{max-width:760px;margin:90px auto}#reading h1{font-size:42px}pre{background:#e9e2e6;padding:20px;overflow:auto;font:14px/1.65 monospace}table{border-collapse:collapse;width:100%;text-align:left}td,th{padding:10px;border-bottom:1px solid #d5cbd1}details{margin:32px 0}footer{border-top:1px solid #d5cbd1;margin-top:60px;padding-top:22px}@media(max-width:760px){.pair{grid-template-columns:1fr}main{padding:25px 16px}}
</style><main><p class="small">ADA RESEARCH · POINT LINES · 29 SEPTEMBER 2026</p><h1>Break the line.<br>Take it again.</h1><p class="intro">The same studies can now meet a tool. Colour stays for a while; a broken body returns after eight seconds. Its original grabbing and geometry continue with it.</p><nav><a href="#museum">Inside the museum</a><a href="#response">Tool responses</a><a href="#reading">Updated chapter</a><a href="#diff">Text changes</a><a href="DECISIONS.md">Decisions</a></nav>
<section id="museum"><div class="pair"><figure><a href="entrance-line.png"><img src="entrance-line.png" alt="The pale line between two grabbable points in its black room."></a><figcaption>Before the hit: the existing adjustable line, with its own handles and length readout.</figcaption></figure><figure><a href="catalyst-colour.png"><img src="catalyst-colour.png" alt="The line and its handles coloured pink by a catalyst shot."></a><figcaption>After an actual projectile collision. A temporary overlay colours the study without replacing its material or teaching script.</figcaption></figure><figure><a href="line-broken.png"><img src="line-broken.png" alt="The black room after the line has broken; doorways and reset remain."></a><figcaption>After the fragments fade: the line and its endpoint colliders are absent. The shell, floor, reset and both passages remain.</figcaption></figure><figure><a href="line-restored.png"><img src="line-restored.png" alt="The pale line restored in its black room."></a><figcaption>The same scene returns. Re-grabbing the original endpoint and changing the segment after rebuilding are verified.</figcaption></figure></div></section>
<section id="response"><h2>One component, different tools.</h2><p>The component attaches to an existing study. It preserves the classes and scripts that already make the artifact work. The four-view gallery reacts one rod at a time; the black room targets only its line.</p><table><tr><th>Tool</th><th>Response</th></tr><tr><td>Catalyst / pink gun</td><td>Temporary colour. Mode IDs remain available for further responses.</td></tr><tr><td>Held laser</td><td>Breaks after the existing dwell interval.</td></tr><tr><td>Sledgehammer</td><td>Three strikes break the study.</td></tr><tr><td>Return</td><td>Eight seconds; waits while a visitor occupies a returning collider.</td></tr></table><p>34 study placements are enabled. Seven native tool/service placements retain their behaviour. The walk stripe and street talker accept colour only. The fragments illustrate a break; this pilot does not fracture the source mesh.</p><details><summary>Every placement and its policy</summary><table><tr><th>Artifact</th><th>Cell</th><th>Policy</th></tr>COVERAGE</table></details><p><a href="sources/commons/interactables/artifact_reactions/README.md">Reusable API and implementation notes</a></p></section>
<section id="reading">READING</section><section id="diff"><h2>The opening is temporary.</h2><p>The chapter now notices that the barrier comes back. The framework stays in the implementation notes.</p><pre>DIFF</pre></section><footer><p>73 native checks passed. Real museum renders, inspected after capture. Headset interaction and Quest performance remain untested. <a href="report.json">Full checks</a> · <a href="source_manifest.json">Runtime sources</a> · <a href="source-versions.json">Frozen source versions</a></p><p><a href="/compose/sources?map=Point_Lines&amp;doc=final">Current chapter</a> · <a href="/long-museum/encounters?map=Point_Lines">Hall encounters</a></p></footer></main></html>'''
(OUT/'index.html').write_text(page.replace('COVERAGE',rows).replace('READING',reading).replace('DIFF',html.escape(text_diff)),encoding='utf-8')
print(f'Published {len(report["checks"])} passing checks; 34 reactive placements; map structure preserved.')
