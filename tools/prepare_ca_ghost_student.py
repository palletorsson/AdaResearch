"""Freeze the current CA reading and extract code only from printed tutorials."""
from pathlib import Path
import hashlib, json, re, shutil
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-ghost-student'
assert not (O/'packet').exists(), 'Retain the first submission; do not overwrite it.'
files={
 'CA_Introduction':['row.gd','point_body.gd'],
 'CA_ElementaryRules':['volume.gd','point_body.gd'],
 'CA_GameOfLife':['history.gd','point_body.gd'],
 'CA_BeyondBinary':['life.gd','point_body.gd'],
 'CA_ExpandingSpace':['presence.gd','point_body.gd'],
 'CA_SoftRules':['field.gd','exchange.gd','point_body.gd'],
 'CA_AgentsCircuits':['procedures.gd','comparison.gd','point_body.gd'],
 'CA_EdgeOfChaos':['paired.gd','difference.gd','point_body.gd'],
}
def write(p,s):
 p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8',newline='\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
manifest={'canonical':{},'printed':{},'scope':'Author-informed AI ghost-student reconstruction. Not a blind independent reviewer or observed human learner.'}
for hall,names in files.items():
 for track in ['tutorial','final']:
  src=R/'commons/maps'/hall/(track+'.md');dst=O/'packet'/hall/src.name
  dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
  manifest['canonical'][src.relative_to(R).as_posix()]=sha(src)
 text=(O/'packet'/hall/'tutorial.md').read_text(encoding='utf-8-sig')
 blocks=re.findall(r'```gdscript\n(.*?)\n```',text,re.S)
 assert len(blocks)==len(names),hall
 for name,code in zip(names,blocks):
  dst=O/'attempt/reconstructed'/hall/name;write(dst,code+'\n')
  manifest['printed'][dst.relative_to(O).as_posix()]=sha(dst)
 # Retain full local images for the frozen manuscript reading.
 for image in re.findall(r'!\[[^\]]*\]\((images/[^)]+)\)',(O/'packet'/hall/'tutorial.md').read_text(encoding='utf-8-sig')+'\n'+(O/'packet'/hall/'final.md').read_text(encoding='utf-8-sig')):
  dst=O/'packet'/hall/image;dst.parent.mkdir(exist_ok=True);shutil.copy2(R/'commons/maps'/hall/image,dst)
write(O/'manifest-before.json',json.dumps(manifest,indent=2)+'\n')
write(O/'attempt/predictions-before.md','''# Ghost-student predictions before execution

8 October 2026. I have read all eight tutorials and reflections. I am the author-informed AI acting as a student, not a blind second reader. The prior row probe was visible during tool discovery; the checks below are newly written against the frozen printed code. No canonical code is consulted to supply a missing learner function.

Assumed: the stated Day Zero museum project with XRTools, camera, light and player. I supply a test host and test poses, not new lesson logic. Godot APIs for assertions and the test harness are evaluator knowledge, not something the student is asked to learn here. Printed PointBody uses those declared XRTools dependencies. We do not test a physical headset or the complete museum route.

| Hall | Prediction from the lesson | Additional transfer |
| --- | --- | --- |
| Row | Adjacent seeds 15/16 give 14,15,16,17; seed0 gives1/31. Reverse traversal cannot change synchronous results. | Reflect the seed around address0: Rule90 is left/right symmetric, so reflection commutes with an update. |
| States | Centre changes active→fading→empty. Two adjacent seeds fade, then leave an empty whole volume. | A fading cell cannot restart even with26 active neighbours; change only its old state to empty and count7 permits birth. |
| History | Seeds5/9 give4,5,6,8,9,10; flip the upright mapping without changing stored rows or deck. | Select an earlier generation and STEP: the latest row supplies the next one. No branching occurs. |
| Life | A four-step glider is translated(1,1); a blinker alternates while its centre stays lit. An off-centre SITE alternates. | A2x2 block survives across the periodic corner. LINK cannot alter that calculation. |
| Presence | At W,21 near steps leave.16 and remove support. Raising input alone beyond radius prevents decay. .49 reaches.5 in SCAN, which still cannot help the third cell. | An empty field without healthy neighbours stays empty after withdrawal. Reverse SYNC equals forward SYNC. |
| Exchange | W receives(.92,.02) in A and(1,0) in B after one update. Corner planting hits all nine combinations of31,0,1. | An isolated corner seed sends first V to(2,0) only through exchange. Changing palette changes no concentration. |
| Procedures | Seeds14/16/18 give13/19; the216 copies stay fixed. Single central Rule90 seed vanishes at generation16. | Translate the supplied copying recipe's starting position: every result translates equally, while the row rule is unaffected. |
| Difference | Integer one-step removes the intervention; fractional one-step affects27 addresses with peak.75. Corner edit gives8, with differing receiver divisors. | With no intervention, common driving input cannot produce a difference. Slice and display gain cannot alter either field. |

Optional composition: carry Trace's ordered recording into presence. Record22 held updates near W,22 at another overlapping position, then22 absent. Keep repetitions, active input, initial field, tick and schedule. Same-order replay must reproduce every field despite an unrelated live hand. Reversing the inputs is a different intervention: I predict a different final field because decay, thresholded recovery and clamping depend on order. That changes my question from where the hand went to when a place was occupied. This is a prescribed test gesture, not an improvised embodied encounter.
''')
# Actual source edits for the requested transfer exercises, kept separate from originals.
variants={
 'row_reverse':('CA_Introduction','row.gd','for i in range(old.size()):','for i in range(old.size() - 1, -1, -1):'),
 'states_two':('CA_ElementaryRules','volume.gd','for z in range(2, 5):\n\t\tfor x in range(2, 5):\n\t\t\tcurrent[index(Vector3i(x, 3, z))] = 1\n\tfor x in range(2, 5):\n\t\tcurrent[index(Vector3i(x, 4, 3))] = 1','current[index(CENTRE)] = 1\n\tcurrent[index(CENTRE + Vector3i.RIGHT)] = 1'),
 'history_flip':('CA_GameOfLife','history.gd','1.05 + x * 0.055','1.05 + (WIDTH - 1 - x) * 0.055'),
 'life_site':('CA_BeyondBinary','life.gd','const SITE := Vector2i(10, 10)','const SITE := Vector2i(9, 10)'),
 'presence_threshold':('CA_ExpandingSpace','presence.gd','current[W] = 0.495','current[W] = 0.49'),
 'exchange_corner':('CA_SoftRules','exchange.gd','right.reset()\n\tinjections','right.reset()\n\tleft.seed_at(Vector2i(0, 0))\n\tright.seed_at(Vector2i(0, 0))\n\tinjections'),
 'comparison_seed':('CA_AgentsCircuits','comparison.gd','var seed_sites: Array[int] = [16]','var seed_sites: Array[int] = [14, 16, 18]'),
 'difference_corner':('CA_EdgeOfChaos','paired.gd','var site := Vector3i(5, 5, 5)','var site := Vector3i(0, 0, 0)'),
}
for variant,(hall,name,old,new) in variants.items():
 dst=O/'attempt/variants'/variant;shutil.copytree(O/'attempt/reconstructed'/hall,dst)
 text=(dst/name).read_text(encoding='utf-8');assert text.count(old)==1,variant
 write(dst/name,text.replace(old,new))
write(O/'attempt/variants.json',json.dumps(variants,indent=2)+'\n')
print(json.dumps({'printed_files':len(manifest['printed']),'manuscripts':len(manifest['canonical']),'output':str(O)}))
