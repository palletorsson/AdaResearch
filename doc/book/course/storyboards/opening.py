"""Preserve the author's opening proposals and add explicit teaching metadata."""
from pathlib import Path
import json
import re

HERE=Path(__file__).resolve().parent
text=(HERE.parent/'TUTORIAL_STORYBOARDS.md').read_text(encoding='utf-8')
paragraphs=re.findall(r'^\*\*([^\n]+?) — ([^\n]+?)\.\*\* (.+)$',text,re.M)
assert len(paragraphs)==13, 'Run only against the original opening brief'
# Each tuple is authored teaching selection, not derived from object quantity.
rows=[
 ('Point_Zero','deepen',['Running museum','A saved change appears'],['_ready runs on arrival','_process repeats'], 'When an instruction runs', ['Existing counter and display','Player and room'], ['frame_counter_display'], ''),
 ('Point_One','make',['Readiness and repeated processing'],['A named position variable','Surface and collision are separate'], 'A represented point with an explicit boundary', ['Existing corridor and lighting','A place for the reduced construction'], ['point_absent','point_visible','point_solid'], 'Agree how the small construction relates to the existing corridor before drafting code.'),
 ('Point_Coordinates','make',['Position variable','Visible body and collision'],['Connect a supplied hold','Read X, Y, Z in one frame'], 'A movable point with a readable address', ['XR player and hold','Coordinate frame and reporting'], ['origin'], 'Approve the grab interface and how much local/world comparison belongs here. Decimal formatting is not the lesson.'),
 ('Point_Lines','make',['Two positions in one frame','A movable point'],['Subtract positions','Direction and distance'], 'Connect and measure two positions', ['Visible segment','Input and handles'], [], ''),
 ('Point_Trace','make',['Positions','A segment between two points'],['An ordered list','Traverse neighbouring entries'], 'The student’s own retained trace', ['Mouse or VR input','Recording policy and storage'], [], 'The recording condition may need a small first introduction to if. Confirm that the same saved trace is available in Grid.'),
 ('Point_Line_Grid','deepen',['Saved trace','List and traversal'],['Round to a grid address','Keep source and result separate'], 'The same trace in a chosen lattice', ['Saving and loading','Comparison display'], [], 'The cross-hall transfer is required teaching work, not certified by these storyboards.'),
 ('Point_Triangle_Context','make',['Three positions','Connected segments'],['Submit a triangular face','Corner order'], 'A face made from chosen positions', ['Small tool and enlarged twin','Material and input'], [], 'Use non-collinear positions. Defer arbitrary polygon filling.'),
 ('Primitives_Polythedra','make',['Position list','Triangle submission'],['A face list references corners'], 'A small connected mesh', ['Rendering wrapper','The wider solid comparisons'], [], ''),
 ('Point_Animatedcube','deepen',['Positions and face connections'],['Shared corners','A diagonal changes connectivity'], 'Edit a mesh without confusing it with object motion', ['Comparison display','Prefab shelf'], [], ''),
 ('Primitives_Ignorance','make',['Position lists','Connected faces','Loop'],['A function generates positions'], 'A reusable geometric generator', ['Face connections','Museum columns and solids'], [], 'One profile-and-rings follow-up can be separate. Resolution, proportion and aesthetic judgement remain different decisions.'),
 ('Primitives_Portals','reflect',['Generated positions','Distance between points'],['Choose finite resolution for a purpose'], 'A stated tolerance or visible purpose', ['Circle sampler','Ring display'], [], 'The sampler is supplied; full trigonometric construction is not assumed here.'),
 ('Primitives_Melencolia','reflect',['Generated forms','Placement and proportion'],['Compose with known elements'], 'A small arrangement that can change', ['Existing Dürer encounter','Prepared materials'], [], 'The critical discussion of geometric desire retains its own room; no new syntax is needed to finish.'),
]
halls=[]
for (label,title,paragraph),row in zip(paragraphs[1:],rows):
    mid,mode,brings,learns,carries,supplied,refs,note=row
    halls.append(dict(id=mid,title=title[0].upper()+title[1:],storyboard=paragraph,mode=mode,brings=brings,learns=learns,carries=carries,supplied=supplied,artifact_refs=refs,review_note=note))
data=[dict(sequence='primitives',arc='From arriving in a running world to making its first elements: a point gains a body, an address, a relation, a record and a face. Connected faces become generated forms; the closing halls ask what an exact construction and a useful approximation permit us to make.',halls=halls)]
(HERE/'opening.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(HERE/'preparation.json').write_text(json.dumps(dict(title=paragraphs[0][1].capitalize(),storyboard=paragraphs[0][2]),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
brief=text.split('## Proposed opening storyboards')[0]
brief=brief.replace('3 October 2026. Working brief and proposed opening route for Palle to correct.', '4 October 2026. Working brief and proposed route through all 25 sequences, for Palle to correct.')
brief=brief.replace('The opening paragraphs below are the first batch for correction. Once the form and teaching choices are right, extend the same document through the remaining sequences.', 'The paragraphs below cover the current spine. They remain proposals: agree each teaching choice before expanding its tutorial.')
(HERE/'BRIEF.md').write_text(brief,encoding='utf-8')
