from pathlib import Path
import json

H=Path(__file__).resolve().parent
R=H.parents[3]
M='SpeculativeComputation_Rhizome_Network'
C=H.parent/'2026-09-19-review-comparison'
prefix=H.relative_to(R).as_posix()+'/'
before=(H/'before/commons/maps'/M/'final.md').read_text(encoding='utf-8')
after=(R/'commons/maps'/M/'final.md').read_text(encoding='utf-8')
def passage(text,starts):
 return '\n\n'.join(next(p for p in text.split('\n\n') if p.startswith(s)) for s in starts)
def pair(title,description,images,captions,old_starts,new_starts,note,report='final.diff'):
 return dict(title=title,description=description,images=[prefix+n+'.png' for n in images],captions=captions,
  image_note=note,text_kind='book — follow the relation, then test its loss',before=passage(before,old_starts),
  after=passage(after,new_starts),report=prefix+report,report_label='Exact manuscript diff' if report=='final.diff' else 'Findings, decisions and verification')
d=json.loads((C/'postfoundationscrisis.json').read_text(encoding='utf-8'))
d['items']=[v for v in d['items'] if not v.get('report','').startswith(prefix) and v['title']!='Next: no root, but no centre?']
d['status']='First six halls reviewed; Assembly Laboratory and Post-Crisis Synthesis remain'
d['summary']='Post-Crisis moves from distinctions and participation through disagreement, situated claims and a shared object to the pattern of its connections. Rhizome Network now holds the points while the visitor changes links and removes a node. The text keeps unequal influence and repair open as questions.'
d['items'] += [
 pair('The points stay; the relations change',
  'LINKS compares one and three earlier neighbours without drawing another set of points. NODE names the selected arrival and counts its degree. The manuscript keeps no named root separate from equal influence.',
  ['rhizome-one','rhizome-three'],
  ['One link: 24 points, 22 edges, two connected components. Node 3 has degree 3.','Three links: the same 24 points, 65 edges, one component. Node 3 has degree 8.'],
  ['The rule still'],['The rule still','Hold an arrangement'],
  'Actual revised museum states from the same camera and sample sequence. Positions are identical; only the connection rule changes. The surrounding circular frame is not a graph edge.'),
 pair('What survives the same loss?',
  'The previously proposed removal is now a visitor operation. CUT removes a node and its incident links, leaving a small grey ghost. No new connections are created to replace them.',
  ['rhizome-one-cut','rhizome-three-cut'],
  ['Node 3 removed from the one-link graph: four components and 19 surviving edges.','The same node removed under three links: one component and 57 surviving edges.'],
  ['Find a node'],['Find a node','Press CUT again'],
  'Same camera, points and removed node. The denser version survives this removal; the comparison does not claim that any graph withstands any cut.'),
 pair('What was decided before growth began?',
  'REPLAY returns to the same two seed points and holds. Later points stay within the fixed sampling region. The text can now linger at an addition and ask whether the territory itself ever changes.',
  ['rhizome-side','rhizome-replay'],
  ['Restored three-link graph from the side; both table and control approach stand on the floor.','REPLAY: two unconnected seed points, correctly counted before growth resumes.'],
  ['The exhibit starts'],['Press GROW','The exhibit starts','The ring does not'],
  '36 runtime checks, seven selected walks and 81 content checks pass. These images change camera and graph state. Both authored families remain; cave traversal and headset testing are still open.', 'SUMMARY.md'),
 dict(title='Next: which body has the catalogue imagined?',
  description='Assembly Laboratory and Post-Crisis Synthesis are the two remaining halls. Inspect the assembly target and available pieces before revising what the text says about forming a body.',
  report=prefix+'content-checks.json',report_label='Content and preservation checks')
]
(C/'postfoundationscrisis.json').write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Published six reviewed Post-Crisis halls; two remain.')
