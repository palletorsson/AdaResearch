"""Publish the Noise Columns readings, exact-code checks and real museum captures."""
from pathlib import Path
import difflib, hashlib, html, json, re, shutil, zipfile
import markdown
from publish_noise_opening import page as base_page

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-noise-revision/Noise_Columns'
MAP=ROOT/'commons/maps/Noise_Columns'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def page(title,body,wide=False):return base_page(title,body,wide).replace('noise-opening-review.zip','noise-columns-review.zip')
def md(s):return markdown.markdown(s.replace('/book-images/figures/Noise_Columns/three-columns.png','images/three-columns.png'),extensions=['fenced_code','tables','footnotes'])

def main():
    tests=json.loads((OUT/'tests.json').read_text());faults=json.loads((OUT/'mutations.json').read_text())
    run=ROOT/'ada_run/encounter_pilot/Noise_Columns/noise-columns-student'
    native=json.loads((run/'report.json').read_text())
    assert tests['all_passed'] and faults['all_rejected'] and native['passed']
    dest=OUT/'museum';dest.mkdir(exist_ok=True)
    for n in ['report.json','source_manifest.json','engine.log','encounter.png','matte-revealed.png','readout.png','overhead.png','student.png']:
        shutil.copy2(run/n,dest/n)
    images=OUT/'images';images.mkdir(exist_ok=True)
    shutil.copy2(ROOT.parent/'ada_encyclopedia/public/book-images/figures/Noise_Columns/three-columns.png',images/'three-columns.png')
    tracks={};diffs=[]
    prediction=json.loads((OUT/'prediction.json').read_text())
    assert prediction['source_sha256']==sha(MAP/'tutorial.md')
    for track in ['tutorial','final']:
        text=(MAP/(track+'.md')).read_text(encoding='utf8');tracks[track]=text
        (OUT/(track+'.md')).write_text(text,encoding='utf8')
        (OUT/(track+'.html')).write_text(page('Noise Columns / '+track,md(text)),encoding='utf8')
        before=(OUT/'before'/(track+'.md')).read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(before.splitlines(True),text.splitlines(True),fromfile='before/'+track+'.md',tofile='after/'+track+'.md'))
        (OUT/(track+'.diff')).write_text(diff,encoding='utf8')
        diffs.append(f'<h2>{track}.md</h2><pre class="diff">{html.escape(diff)}</pre>')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tracks['tutorial'],re.S))
    for name,code in blocks.items():
        p=OUT/'learner/printed'/name
        assert p.read_text()==code+'\n' and sha(p)==prediction['files'][name]
    assert (MAP/'map_data.json').read_bytes()==(OUT/'before/map_data.json').read_bytes()
    sources=[MAP/n for n in ['tutorial.md','final.md','map_data.json']]
    sources.extend(ROOT/p for p in ['algorithms/proceduralgeneration/hybrid_complex/berninicolumns/MeltingBerniniColumns.gd','algorithms/proceduralgeneration/hybrid_complex/berninicolumns/shaders/marble_column.gdshader','commons/artifacts/dark_sphere/dark_sphere.gd','doc/book/studies/wavefunctions-lineage/07_twisted_shaft.gd'])
    (OUT/'sources.json').write_text(json.dumps([{'path':p.relative_to(ROOT).as_posix(),'sha256':sha(p)} for p in sources],indent=2)+'\n')
    (OUT/'parallel.html').write_text(page('Noise Columns / tutorial and reflection','<p class="meta kicker">Endless Museum / Noise 02</p><p>The carried shaft learns to receive a value. The installed room keeps its wider encounters.</p><div class="pair"><article class="sheet"><p class="meta">LEFT / TUTORIAL</p>'+md(tracks['tutorial'])+'</article><article class="sheet"><p class="meta">RIGHT / REFLECTION</p>'+md(tracks['final'])+'</article></div>',True),encoding='utf8')
    (OUT/'changes.html').write_text(page('Noise Columns / changes','<h1>Keep the receiver in view</h1><p>A complete reconstruction replaces disconnected passages. The reflection retains all three encounters and its existing image; the code blocks move into the tutorial. Its opening now includes the cloud lesson as well as the optional wall encounter.</p>'+''.join(diffs)),encoding='utf8')
    report=f'''# One body, three drivers

Noise Columns · second hall · 9 October 2026

**The lesson is now a complete, tested construction inside the existing museum.** It carries the twisted shaft from Bernini and the pickable PointBody from the earlier halls. A held value, a sine and a field sample pass through the same height rule. The student then changes that rule's amount and predicts what stays the same.

## What changed

| Track | Before | Now |
| --- | --- | --- |
| tutorial.md | Encounter instructions and three partial code passages. | Three complete printed files: drivers and local clock, carried shaft and receiving function, unchanged PointBody. Explicit setup inside the prepared museum. |
| final.md | Rich encounters with columns, orb and six-orb family, interrupted by four code blocks. | Those encounters and their distinctions remain. Code blocks become prose; the opening acknowledges the cloud lesson. |
| Progression | The subject was correct but reconstruction remained open. | Bernini's form → three scalar sources → one receiving operation → halve the displacement → one sample used twice in Noise One. |

The new work is in the texts and learner reconstruction. The installed artifacts, hall geometry and sequence order were not changed. The learner study in the image below was temporarily added for verification, not permanently installed.

## What the student makes

Three small twisted shafts share rest positions, faces, material and deformation range. The left receives 0.10; the middle receives a remapped sine; the right receives a remapped Simplex sample along a time address. The inherited black point pauses the study through its existing trigger action. The receiver always returns to stored rest positions before changing height, preventing accidental accumulated sinking.

The smaller reconstruction isolates the vertical drop. The installed artwork has further ribs, bulges, capitals and shader effects. The student field explicitly disables fractal layers; the installed resource uses FBM with five octaves, gain 0.5 and lacunarity 2, confirmed in the native run. This difference is stated in the tutorial. It avoids introducing layering before its own hall.

The independent edit halves `top_drop`, not the driver's speed or range. At the sine's quarter-period the top changes from 1.70 to 2.05 metres. Every vertical displacement halves; the field addresses, values, repeat period and face connections remain unchanged. This makes the distinction between driver and receiver something the student can verify.

## Evidence

- **{tests['checks']} passing Godot assertions:** {tests['results'][0]['checks']} on exact printed files and {tests['results'][1]['checks']} on the separately edited half-drop program.
- **Five executable faults caught:** wrong sine rate, ignored field address, ignored pause, lost rest positions and an incorrectly uniform drop. They fail behavior assertions rather than parsing.
- **{len(native['checks'])} passing native museum checks:** installed FREEZE, SPIN, MARBLE and REVEAL through pointer events; the independent orb clock; a supported, clear learner approach; and simulated XR Tools pickup, held action and release.

The prediction was recorded before executing the changed program. Tests include known sine values, repeated field queries, unchanged X/Z, valid face indices, rendered mesh positions, the stationary foot and local clock isolation. The test harness initially had a missing explicit type; it was corrected before the successful runs. No failure in the printed example was found by these checks. This remains an author-informed ghost-student reconstruction, not evidence of human learning or physical headset comfort.

The museum log still reports blocked authored entry and exit markers with safe fallbacks, along with existing project UID, content-registry and Compatibility-renderer warnings. This pass verifies the encounter and temporary learner bay; it does not certify the whole route or Quest performance. Source references and full logs are included.

## What travels onward

**Noise One** can now begin with one retained sample and ask what changes when two different receivers spend it as height and colour. It should reuse the sampling distinction established here, rather than restart with a new definition of noise.

Read the [facing pages](parallel.html), [exact changes](changes.html), [test receipts](tests.json), [fault checks](mutations.json), [museum receipt](museum/report.json), or [review ZIP](noise-columns-review.zip). The [eight-hall route](../plan.html) and [editable lesson plan](http://localhost:3003/tutorial-plan?map=Noise_Columns&view=summaries) retain this as a draft for review.
'''
    (OUT/'REPORT.md').write_text(report,encoding='utf8')
    figures=''.join(f'<figure><img src="museum/{name}.png" alt="{html.escape(caption)}"><figcaption>{caption}</figcaption></figure>' for name,caption in [
        ('encounter','Installed museum encounter before naming the three drivers. These are the existing full artworks.'),
        ('matte-revealed','The same installed shafts with their clock held, drivers revealed and shaft veining removed. The shape stays.'),
        ('student','Exact printed reconstruction, temporarily mounted inside the museum: held, sine and field. The middle shaft is at the predicted quarter-period. The black PointBody controls pause.'),
        ('overhead','Current hall from above. Wider museum exhibits remain outside this one tutorial construction.')])
    (OUT/'index.html').write_text(page('Noise Columns / one body, three drivers','<p class="meta kicker">Endless Museum / Noise 02</p>'+md(report)+'<h2>Inside the museum</h2>'+figures),encoding='utf8')
    (OUT/'README.md').write_text('''# Noise Columns review

Open index.html or parallel.html. Canonical tutorial.md and final.md are copied unchanged. learner/printed contains only files extracted from tutorial fences; learner/half-drop is the one-line transfer. Other learner folders deliberately contain faulty programs. They are not recommended lesson files.

Run tools/test_noise_columns.py from AdaResearch_46 with Godot 4.6 and the existing Day Zero/XR Tools dependencies. Native probe: tools/run_encounter_probe.py Noise_Columns --sequence noise --render --no-bridges --probe tools/probes/noise_columns_room.gd --output-tag noise-columns-student --spec doc/book/iterations/2026-10-09-noise-revision/Noise_Columns/spec-student.json.

This ZIP is a review packet, not a standalone Godot project. The museum provides the player, lighting and input. Reproduction tools are source copies whose paths assume the original repository. Native images use the Compatibility renderer; no physical headset or independent human-student trial is claimed. The reflection's root-relative book image is bundled under images/ for its HTML rendering.
''',encoding='utf8')
    methods=OUT/'reproduce';methods.mkdir(exist_ok=True)
    for name in ['tools/revise_noise_columns.py','tools/test_noise_columns.py','tools/publish_noise_columns.py','tools/publish_noise_opening.py','tools/probes/noise_columns_student.gd','tools/probes/noise_columns_room.gd']:
        shutil.copy2(ROOT/name,methods/Path(name).name)
    route=(OUT.parent/'PLAN.md').read_text(encoding='utf8')
    route_page=page('Noise / eight-hall route',md(route))
    for name in ['index.html','parallel.html','tutorial.html','final.html','changes.html','noise-columns-review.zip']:
        route_page=route_page.replace('href="'+name+'"','href="Noise_Columns/'+name+'"')
    route_page=route_page.replace('href="../plan.html"','href="plan.html"')
    (OUT.parent/'plan.html').write_text(route_page,encoding='utf8')
    with zipfile.ZipFile(OUT/'noise-columns-review.zip','w',zipfile.ZIP_DEFLATED) as z:
        for p in OUT.rglob('*'):
            if p.is_file() and p.suffix not in ['.zip','.uid'] and 'attempts' not in p.relative_to(OUT).parts:z.write(p,'Noise_Columns/'+p.relative_to(OUT).as_posix())
        for name in ['PLAN.md','plan.html']:z.write(OUT.parent/name,name)
    print('Published',OUT/'index.html')
if __name__=='__main__':main()
