from pathlib import Path
import difflib,hashlib,html,json
import markdown
H=Path(__file__).resolve().parent;R=H.parents[3]
room='AdvancedLaboratory_Lab_Equipment_Simulation';M=R/'commons/maps'/room
rel=H.relative_to(R).as_posix()
report=json.loads((H/'museum-runtime.json').read_text(encoding='utf-8'))
assert report['passed'] and all(c['ok'] for c in report['checks']) and all(w['passed'] for w in report['walks'])
assert 'SCRIPT ERROR' not in (H/'museum-process.log').read_text(encoding='utf-8',errors='replace')
old=(H/'before/commons/maps'/room/'final.md').read_text(encoding='utf-8');new=(M/'final.md').read_text(encoding='utf-8')
assert old.split('<!-- @ -->')[0] in new
shared='algorithms/computationalbiology/molecular_framework/AssemblyRagdoll.gd'
assert (H/'before'/shared).read_bytes()==(R/shared).read_bytes()
changed=['algorithms/computationalbiology/molecular_framework/'+f for f in ['MolecularDesigner.gd','AssemblyFurnitureStudy.gd']]+['commons/maps/'+room+'/'+f for f in ['map_data.json','final.md','technical.md','critical.md']]+['commons/data/museum_core_encounters.json']
for name in changed:
    p=H/'before'/name;before=p.read_text(encoding='utf-8') if p.exists() else ''
    after=(R/name).read_text(encoding='utf-8')
    diff=''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='before/'+name,tofile=name))
    (H/('final.diff' if name.endswith('/final.md') else name.replace('/','__')+'.diff')).write_text(diff,encoding='utf-8')
inputs=changed+[shared,'algorithms/computationalbiology/molecular_framework/AssemblyRagdollGrip.gd','algorithms/computationalbiology/molecular_framework/assemblies.json']
(H/'current-inputs.json').write_text(json.dumps({p:hashlib.sha256((R/p).read_bytes()).hexdigest() for p in inputs},indent=2)+'\n',encoding='utf-8')
(H/'current-final.md').write_text(new,encoding='utf-8')
style=(R/'doc/book/iterations/2026-09-21-assembly-ragdoll/index.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
style+=' .triptych{display:grid;grid-template-columns:repeat(3,1fr);gap:18px}.object{margin:55px 0}.reading article{min-width:0}.hero{max-width:1100px} @media(max-width:850px){.triptych{grid-template-columns:1fr}}'
sections=''
for kind,description in [('Chair','The back, seat and four legs remain connected. The joints let the familiar use come apart.'),('Table','The tabletop stays flat while its legs cease to keep it level.'),('Lamp','The light follows the bulb. Falling has not broken a circuit here.')]:
    figures=''
    for state,caption in [('held','Held in the authored starting pose by visible supports.'),('pull','A controlled pull removes the supports and moves the connected parts.'),('drop','Released: gravity and contact settle the object.')]:
        name=kind.lower()+'-'+state+'.png'
        assert (H/name).stat().st_size>10000
        figures+='<figure><a href="'+name+'"><img src="'+name+'" loading="lazy" alt="'+kind+': '+caption+'"></a><figcaption>'+caption+'</figcaption></figure>'
    sections+='<section class="object" id="'+kind.lower()+'"><h2>'+kind+'</h2><p>'+description+'</p><div class="triptych">'+figures+'</div></section>'
passage=(H/'new-passage.md').read_text(encoding='utf-8')
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Assembly — a chair has legs too</title><style>'+style+'</style><main><div class="eyebrow">Ada Research · Assembly Laboratory · 21 September 2026</div><h1>A chair has legs too.</h1><p class="intro">The same pulling rule now acts on a chair, a table and a lamp. Take a coral ring. Watch what follows. Let go.</p><p>All three are available together, beside the earlier body experiments. Each stand has its own REASSEMBLE control.</p><nav><a href="#chair">Chair</a><a href="#table">Table</a><a href="#lamp">Lamp</a><a href="#text">New passage</a><a href="final.diff">Exact text diff</a><a href="SUMMARY.md">Build and checks</a><a href="/compose/sources?map='+room+'&doc=final">Read in Compose</a></nav>'+sections+'<p class="note">Actual Godot museum images from controlled starting, pulled and released states of the new implementation. Seventy interaction/physics checks and nine selected continuous walks pass, including the earlier human ragdoll. Synthetic XRTools controller checks are not on-headset experience. Headset reach, comfort and Quest performance remain open.</p><section id="text"><h2>The new encounter</h2><div class="excerpt">'+markdown.markdown(passage)+'</div></section><details><summary>Compare the entire original and current chapter</summary><div class="reading"><article><h3>Before</h3>'+markdown.markdown(old,extensions=['fenced_code','footnotes'])+'</article><article><h3>Current</h3>'+markdown.markdown(new,extensions=['fenced_code','footnotes'])+'</article></div></details><details><summary>See their positions in the hall</summary><figure class="hero"><a href="museum-furniture.png"><img src="museum-furniture.png" alt="Museum overview showing the central passage and multiple assembly studies" loading="lazy"></a><figcaption>The central passage remains clear. Chair and table are near the entrance; the lamp is beside the exit-side gold workshop.</figcaption></figure></details></main></html>'
(H/'index.html').write_text(page,encoding='utf-8')
rows='\n'.join('| '+k+' | '+str(v['parts'])+' | '+str(v['joints'])+' | '+f"{v['neighbour_moved']:.3f} m"+' |' for k,v in report['furniture'].items())
summary=f"""# Assembly: a chair has legs too

Added three independently grabbable physics studies alongside the previous human ragdoll and gold editable body. They use the existing Chair, Table and Lamp names, node positions, masses and connection lists from assemblies.json. Explicitly fitted panel orientation, thickness, leg lengths and colliders make these furniture rather than scaled clusters of catalogue markers. The existing catalogue and assembly source file are unchanged.

AssemblyFurnitureStudy.gd inherits the unchanged ragdoll grab targets, bounded spring force, elastic tether and reset path. Fifteen new rigid parts have twelve structural pin joints. Initial support pins hold each part's centre in an authored pose, shown by thin wires. First grab removes every staging support for that object; structural connections remain free to turn. Release leaves gravity and contacts to settle it. Each REASSEMBLE control acts locally and refuses while held. The lamp's bulb carries its light after collapse. Furniture does not write to the saved gold-body pose.

## Checked in the actual museum

{len(report['checks'])} interaction/physics checks pass, including the human ragdoll regression, source graph counts, desktop ray selection and carry, movement transmitted to a neighbouring part, free physical bodies, bounded joint separation at the sampled drag states, reset refusal, falling/settling, reset recovery, synthetic two-controller XRTools grabs and unchanged gold/save state.

| Object | Physical parts | Structural joints | Neighbour moved during checked pull |
|---|---:|---:|---:|
{rows}

Nine selected continuous walking segments pass: entrance, chair approach, table approach, central passage, lamp approach and exit. The new stations are at map coordinates Chair (3,2.3), Table (8.7,2.3), Lamp (9.2,9.8). The automatic sculpture exclusion covers their work area. No hall expansion or removal of an existing primary was needed.

Godot exits 0 with no script errors. The existing unrelated UID/environment/dressing warnings remain in the log. Nine state captures and a hall overview are saved; the main before/after states were visually inspected. Captures show controlled states of the same new implementation, not a human session. No headset, comfort, haptic or Quest-performance claim is made. These pin-jointed props are not ordinary welded furniture or promised player seating.

The entire preceding manuscript encounter is preserved. A short addition follows the human ragdoll into the chair, table and lamp: the distinction between an outline, a connection and a familiar use. The lamp's continued light makes one omitted consequence visible. Exact diffs, baseline copies, source manifest and current input hashes are saved here. Map description/notes were clarified after capture without changing the tested placement, structure or flags.

No live game restart, live bake replacement, visitor-save write or commit. The frozen full-book packet for Claude remains unchanged. Collective Knowledge is still separately parked; see ../2026-09-21-commons-restoration/PENDING.md.
"""
(H/'SUMMARY.md').write_text(summary,encoding='utf-8')
p=R/'doc/book/iterations/2026-09-19-review-comparison/postfoundationscrisis.json';d=json.loads(p.read_text(encoding='utf-8'));title='Assembly: a chair has legs too'
d['items']=[i for i in d['items'] if i.get('title')!=title]
d['items'].append(dict(title=title,description='The same physics now acts on a chair, table and lamp. Pull their parts, release them, and compare recognition with support and use.',images=[rel+'/chair-held.png',rel+'/chair-drop.png',rel+'/lamp-drop.png'],captions=['Held in a recognisable starting arrangement.','The chair remains connected but loses its support.','The lamp folds down and keeps shining.'],image_note='Actual Godot museum states of the same new implementation. Controlled interactions, not headset observations.',text_kind='Three physical furniture encounters and a short chapter addition — 21 September',before='The same invitation — take a hand, move it, release it — has produced another kind of body.',after='A chair has legs too. The lamp bends and goes on shining. Failure has to be specified too.',report=rel+'/index.html',report_label='See chair, table and lamp before and after pulling'))
p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print('Published three furniture studies, ten museum captures, exact text/source diffs and passing evidence.')
