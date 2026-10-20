"""Preserve the current Tiling revision and make the bounded Colour handoff edit."""
from pathlib import Path
import hashlib, json, re, shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
HALLS = ['Pattern_Disco','Pattern_Foundry','Tutorial_Pattern','Array_Patterns','Symmetry_Seventeen','Pattern_Temple','Ribbon_Patterns_01','Ribbon_Patterns_02','Ribbon_Patterns_03']
BLOCKS = r'<!-- student-code:([^ ]+) -->\s*```(?:gdscript|glsl|ini)\n(.*?)\n```'

def put(p,t):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(t,encoding='utf-8')

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

def replace(t,a,b):
    assert t.count(a)==1, a
    return t.replace(a,b)

def blocks(p): return dict(re.findall(BLOCKS,p.read_text(encoding='utf-8-sig'),re.S))

def main():
    assert not (HERE/'before-sources.json').exists(), 'Preserve the first snapshot.'
    paths=[f'commons/maps/{h}/{n}' for h in HALLS for n in ['tutorial.md','final.md','map_data.json','em_plan.json'] if (ROOT/f'commons/maps/{h}/{n}').exists()]
    paths += ['commons/maps/sequences/tiling.json','commons/maps/sequences/color.json','commons/maps/sequences/change.json']
    paths += [f'commons/maps/{h}/tutorial.md' for h in ['Color_Grid_Pallet','Color_Nails','Color_Walls']]
    paths += [f'doc/book/course/execution-plan/{n}' for n in ['plan.json','authorized-revisions.json','lesson-summaries.txt']]
    for h in HALLS:
        paths += [p.relative_to(ROOT).as_posix() for p in (ROOT/'commons/maps'/h).glob('*.gd')]
    for p in paths:
        dest=HERE/'before'/p; dest.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(ROOT/p,dest)
    put(HERE/'before-sources.json',json.dumps({p:sha(ROOT/p) for p in paths},indent=2)+'\n')
    palette=blocks(ROOT/'commons/maps/Color_Grid_Pallet/tutorial.md')
    point=blocks(ROOT/'commons/maps/Color_Nails/tutorial.md')['point_body.gd']
    changed=[]
    for h in HALLS:
        p=ROOT/'commons/maps'/h/'tutorial.md'; text=p.read_text(encoding='utf-8-sig'); old=blocks(p)
        if h != 'Ribbon_Patterns_03':
            assert old['palette.gd']==palette['palette.gd']
            assert old['point_body.gd']==point
            expected=old['grid_surface.gd'].replace('X / Z: select   C: colour   P: palette   R: rule','X+ / Z+: select   COLOUR: leave a colour')
            assert expected==palette['grid_surface.gd']
            text=replace(text,old['grid_surface.gd'],palette['grid_surface.gd'])
        if h=='Pattern_Disco':
            text=replace(text,'Arrays gave us addresses. Colour gave us an assigned colour and the small `Palette` class. We keep that class and the same 5 × 5 cube-tile receiver from the Colour review draft. The new work is the separation between a calculated zero or one and the colour used to display it.',
                'Arrays gave us addresses. In Colour, Grid Palette kept a colour at an address; Walls let two panes own different palette choices. Here we bring back the same `Palette`, `GridSurface` and `PointBody` classes. The new work is the separation between a calculated zero or one and the colour used to display it. We reuse the code; the lesson starts with the palette and phase declared below, rather than importing a saved choice from Colour.')
            text=replace(text,'The point is the familiar grabbable sphere. Hold it',
                'The point is the familiar grabbable sphere. This study uses its existing pickup and trigger signals to call three operations; Colour\'s separate pointer console is not needed here. Hold it')
        if h=='Ribbon_Patterns_03':
            text=replace(text,'The full program is printed; this is your independent edit of its operation.',
                'This guided change checks the address calculation. Then choose another positive vertical repeat count yourself. Predict the spacing on the wall and the colour at a UV address away from a texel boundary before running. Explain which values changed and which stayed fixed.')
        put(p,text)
        new=blocks(p)
        for n in old:
            if n!='grid_surface.gd': assert old[n]==new[n],(h,n)
        changed.append({'hall':h,'changed_printed_files':[n for n in old if old[n]!=new[n]],'entry_program_unchanged':True})
        put(HERE/h/'tutorial.md',text)
        shutil.copyfile(ROOT/'commons/maps'/h/'final.md',HERE/h/'final.md')
    p=ROOT/'commons/maps/sequences/tiling.json';t=p.read_text(encoding='utf-8')
    t=replace(t,'Revised summary proposals; full Ribbon companions and reduced learner bindings remain pending.',
        'Nine complete tutorials and reduced learner bindings are present. Current loom and garment encounters remain optional. 12 October continuity pass reuses Colour helpers and verifies the printed studies; physical learner review remains open.')
    put(p,t)
    put(HERE/'changes.json',json.dumps({'date':'2026-10-12','basis':'Current canonical drafts, including 9–10 October loom and garment refinements. Older snapshots are not promoted over them.','lessons':changed,'finals_changed':False,'sequence_change':'Stale completion-status wording only; order and membership unchanged.','runtime_changed':False},ensure_ascii=False,indent=2)+'\n')
    print('Preserved current drafts; aligned eight inherited readouts and tightened the Colour handoff. Nine entry programs and current reflections retained.')

if __name__=='__main__':main()
