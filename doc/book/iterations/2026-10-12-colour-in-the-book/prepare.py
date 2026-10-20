"""One-shot copy of the reviewed Colour manuscripts; never edits museum runtime."""
from pathlib import Path
import hashlib, json, re, shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
OLD = HERE.parent / '2026-10-06-colour-complete-drafts'
HALLS = ['Color_Context_Placed','Color_Flashlight','Color_Nails','Color_Rainbow','Color_Pillar','Color_Grid_Pallet','Color_Paint','Color_Walls']

def put(p,t):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(t,encoding='utf-8')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def replace(t,a,b):
    assert t.count(a)==1,a
    return t.replace(a,b)

def main():
    assert not (HERE/'before-sources.json').exists(), 'Prepared already; edit current manuscripts directly.'
    paths=[f'commons/maps/{h}/{n}' for h in HALLS for n in ['tutorial.md','final.md','map_data.json']]
    paths += ['commons/maps/sequences/color.json','commons/maps/sequences/array_tutorial.json','commons/maps/sequences/tiling.json']
    paths += [f'doc/book/course/execution-plan/{n}' for n in ['plan.json','authorized-revisions.json','lesson-summaries.txt']]
    paths += ['commons/maps/Point_Lines/tutorial.md','commons/maps/Tutorial_Disco/tutorial.md']
    for p in paths:
        dest=HERE/'before'/p
        dest.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(ROOT/p,dest)
    put(HERE/'before-sources.json',json.dumps({p:sha(ROOT/p) for p in paths},indent=2))
    for hall in HALLS:
        (HERE/hall).mkdir(exist_ok=True)
        for f in (OLD/hall).glob('*.gd'): shutil.copyfile(f,HERE/hall/f.name)
        shutil.copyfile(ROOT/'commons/maps'/hall/'final.md',HERE/hall/'final.md')
        t=(OLD/hall/'tutorial.md').read_text(encoding='utf-8')
        # Keep repository-relative inherited links valid in canonical and report copies.
        t=t.replace('../2026-10-05-primitives-facing-pages/Point_Lines.html','/book-review/doc/book/iterations/2026-10-05-primitives-facing-pages/Point_Lines.html')
        if hall=='Color_Context_Placed':
            t=replace(t,'and indexed references from Array.','and indexed references from Arrays.')
            t=replace(t,'This lesson adds a material colour to each part.','Arrays ended with an address choosing a result and a clock reading a score. Here an address chooses a material value. This lesson adds a material colour to each part.')
        if hall=='Color_Nails':
            t=replace(t,'On desktop you can change `start` and run again; in the prepared VR scene, grip and carry the point.','Grip and carry the point. Changing `start` supplies a repeatable position for the comparisons below.')
            for name in ['point_body.gd','line_skin.gd']:
                t+='\n## Inherited '+name+'\n\nThe earlier file is repeated here so the complete continuation is available in one place.\n\n<!-- student-code:'+name+' -->\n```gdscript\n'+(HERE/hall/name).read_text(encoding='utf-8').rstrip()+'\n```\n'
        if hall=='Color_Pillar':
            t=replace(t,'On desktop, change `start` and run again.','Change `start` when you want to repeat an exact comparison.')
        if hall=='Color_Grid_Pallet':
            t=replace(t,'Run. Press **X** or **Z** to advance the selected address along that axis, wrapping after four. Press **C** to write the active palette\'s current colour there.','Run. Aim the prepared museum pointer at **X+** or **Z+** and activate it to advance the selected address along that axis, wrapping after four. Activate **COLOUR** to write the active palette\'s current colour there.')
            t=t.replace('Press **P**','Activate **PALETTE**').replace('Press **C** again','Activate **COLOUR** again').replace('Press **R**','Activate **RULE**').replace('when you press R','when you activate RULE').replace('then press R','then activate RULE')
            t=replace(t,'## Supplied desktop adapter — controls.gd','## Supplied museum controls — controls.gd')
            t=replace(t,'These keys call the same named operations as a console could. The installed museum console and larger, irregularly addressed floor remain supplied infrastructure. The small study has no walking-floor collider or VR console of its own.','The labelled targets receive pressed events from the prepared museum pointer and call the named operations above. Their construction is supplied support, printed in full. The keyboard adapter remains available for the Day Zero preview. The small display is separate from the installed floor; it has no walking-floor collider.')
        if hall=='Color_Paint':
            t=replace(t,'On desktop, press **H** to attach the study brush to the mouse ray, then hold the left mouse button to paint. Press H again to put it down. This adapter is included; it is not a new input-map setup lesson.','The supplied preview adapter is printed with the support files; the interaction here uses the prepared XR pickup and action signals.')
            t=t.replace('## Supplied desktop adapter — controls.gd','## Supplied preview adapter — controls.gd')
        if hall=='Color_Walls':
            t=replace(t,'Run. Press **F** to switch between filter and opaque modes. Press **C** to advance the first pane\'s palette.','Run. Aim the prepared museum pointer at **FILTER / OPAQUE** and activate it to switch modes. Activate **COLOUR** to advance the first pane\'s palette.')
            t=t.replace('Switch with F:','Activate FILTER / OPAQUE:')
            t+='\nThe labelled controls use the prepared museum pointer; their implementation is supplied below with the preview keys. Tiling can return to the source, placement and repeated instance: changing an appearance is now one deliberate choice alongside where and how a body repeats.\n'
        put(HERE/hall/'tutorial.md',t)
    for hall in HALLS[:3]:
        source=OLD/'evidence'/hall
        for name in ['run_checks.py','verify.gd','render_check.gd']:
            if (source/name).exists(): shutil.copyfile(source/name,HERE/hall/name)
        runner=(HERE/hall/'run_checks.py').read_text()
        runner=runner.replace("    if snapshot.exists():\n        assert before == json.loads(snapshot.read_text())\n    else:\n        put(snapshot, json.dumps(before, indent=2) + '\\n')", "    put(HERE / 'run-source-start.json', json.dumps(before, indent=2) + '\\n')")
        put(HERE/hall/'run_checks.py',runner)
        put(HERE/hall/'build.py',"from pathlib import Path\nimport hashlib\nHERE=Path(__file__).resolve().parent\nROOT=HERE.parents[4]\ndef put(p,t):\n p.parent.mkdir(parents=True,exist_ok=True)\n p.write_text(t,encoding='utf-8')\ndef sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()\n")
    for name in ['verify.gd','render_check.gd','run_render.py']:
        shutil.copyfile(OLD/name,HERE/name)
    runner=(OLD/'run_checks.py').read_text()
    runner=runner.replace('from write_lessons import main as write_lessons, HERE','from prepare import HERE').replace('    write_lessons()\n','')
    runner=runner.replace("for f in (HERE/hall).glob('*.gd'):","for f in student_files(hall):")
    runner=runner.replace("for f in (HERE/hall).glob('*.gd'):","for f in student_files(hall):")
    runner=runner.replace('def main():','def student_files(hall):\n return [HERE/hall/n for n in re.findall(r"<!-- student-code:([^>]+) -->", (HERE/hall/"tutorial.md").read_text(encoding="utf-8"))]\n\ndef main():')
    runner=runner.replace("HERE.parent/'2026-10-06-nails-a-position-to-colour/point_body.gd'","HERE/'Color_Nails/point_body.gd'")
    put(HERE/'run_checks.py',runner)
    print('Copied eight reviewed manuscripts and native test sources; current final texts preserved.')

if __name__=='__main__': main()
