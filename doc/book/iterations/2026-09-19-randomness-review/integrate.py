"""Integrate exact editorial/source proposals after bounded runtime checks."""
from pathlib import Path
import hashlib,json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,d):p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
texts={}
for proposed in (HERE/'proposed').glob('*.md'):
 path=ROOT/f'commons/maps/{proposed.stem}/final.md'
 original=(HERE/'before'/path.relative_to(ROOT)).read_text(encoding='utf-8');target=proposed.read_text(encoding='utf-8')
 assert path.read_text(encoding='utf-8') in [original,target],path
 texts[path]=target
proposals=(read(HERE/'opening/metadata-proposals.json')
 +read(HERE/'middle/proposed/root-metadata.json')
 +read(HERE/'middle/proposed/root-registry.json')
 +read(HERE/'ending/metadata-proposals.json')
 +read(HERE/'root-book-proposals.json'))
documents={}
for p in proposals:
 path=ROOT/p['path'];d=documents.setdefault(path,read(path));c=d
 for k in p['keys'][:-1]:c=c[k]
 k=p['keys'][-1]
 assert c[k] in [p['old'],p['new']],(p['path'],p['keys'])
 c[k]=p['new']
role_path=ROOT/'commons/data/artifact_roles.json';roles=read(role_path)
order=['mushrooms','silhouette_arrivals','couture_comparison']
for token in order:roles['roles']['Random_Mushrooms'][token]='primary'
roles['order']['Random_Mushrooms']['primary']=order
roles['order']['Random_Mushrooms']['secondary']=[x for x in roles['order']['Random_Mushrooms']['secondary'] if x not in order]
for p,t in texts.items():
 if p.read_text(encoding='utf-8')!=t:p.write_text(t,encoding='utf-8')
for p,d in documents.items():write(p,d)
write(role_path,roles)
sequence_path=ROOT/'commons/maps/sequences/randomness.json';seqdoc=read(sequence_path);seq=seqdoc['sequences']['randomness']
for group in seq['artifact_groups']:
 if group['map']=='Random_Mushrooms':
  group['artifacts']=order+['bubbles_random']
  group['rationale']='Follow three existing encounters: sampled specimens, an arrival wardrobe and altered garment constructions. The bubble dish remains a supporting population.'
 if group['map']=='Random_Space':
  group['artifacts']=['noise_mixer','worley_noise','random_space','dark_sphere','shannon_entropy_meter']
  group['rationale']='Compare a finite sine-based field mixer with retained cellular, spatial and statistical representations. No claim that the mixer simulates geology.'
write(sequence_path,seqdoc)
core_path=ROOT/'commons/data/museum_core_encounters.json';core=read(core_path)
reasons={
 'Random_Definition':'Replay a seeded procedure, then discard one draw and notice what assigning it to a colour changes.',
 'Random_Entropy':'Sort a sample without changing its shares or marginal entropy; retain the spatial counterexamples.',
 'Random_Remove':'Inspect eligibility before drawing, then compare hidden geometry with withdrawn support.',
 'Randomness_10_PRINT_Algorithm':'Follow binary marks into contours, then distinguish and repair their separate ant-navigation model.',
 'Random_Cubes':'Compare one settled physical-looking throw with a retained empirical record and its throwing conditions.',
 'Random_Rotate_Random_XYZ':'Inspect drift, rotation and darkening separately; pause and resume two complete stacks inside their hall.',
 'Random_Walk':'Compare direction sets, a capped long-step law and boundaries; distinguish a retained trail from a next-step rule.',
 'Random_Gaussian':'Hold a stored sample while changing its bins; distinguish procedure, clipping and empirical distribution.',
 'Random_Mushrooms':'Move from sampled specimens to an arrival wardrobe to changed garment construction; all three existing works carry the book.',
 'Random_Space_Geometry':'Compare independently assigned heights with correlated neighbours without turning resemblance into a geological explanation.',
 'Randomness_Examples_of_Randomness':'Give chance distinct jobs in a brush, a tally, a bounded pipe and a fixed particle population.',
 'Random_Pheromone':'Step the same seeded starts under attraction and avoidance; follow current markers and distinguish scent from accumulated height.',
 'Random_Space':'Read a finite layered sine-based field and its normalization, then compare retained alternative representations.',
 'Random_Game':'Separate already sampled deadlines from undrawn waits and connect random events to bodily support.'
}
scopes={
 'Random_Definition':'Fresh focused draw-stream/offset checks plus source and qualified historical evidence; no new full-hall or headset validation.',
 'Random_Entropy':'Fresh exact categorical contrast-sample and sorting checks; retained spatial works source-reviewed. Secondary Jar display overclaims remain a development task.',
 'Random_Remove':'Current source and historical bench/arena evidence; no new full removal-floor crossing or headset validation.',
 'Randomness_10_PRINT_Algorithm':'Fresh 34-check source/scene regression including rendered diagonal/raster agreement, replacement refresh and unchanged ant position. Original fails21 checks. Standalone Nature token remains deliberately ineligible.',
 'Random_Cubes':'Source and restored route checked; no new empirical fairness, throwing, settlement or headset validation.',
 'Random_Rotate_Random_XYZ':'Fresh focused clock/fit checks and bounded actual-museum before/after placement. Older source-layer dimension mismatch remains. This does not certify later extreme perturbations or headset comfort.',
 'Random_Walk':'Fresh unchanged-sampler and accumulated-position comparisons; actual-museum label capture. Headset controls not tested.',
 'Random_Gaussian':'Fresh focused rebinning of a retained sample; no complete museum or headset visit.',
 'Random_Mushrooms':'Fresh wardrobe/replay/construction checks and bounded actual-museum staging/approach checks. No eating effect or headset validation.',
 'Random_Space_Geometry':'Current source and restored navigation contract. Five companions lie beyond the source structure rectangle; museum derivation retains them, but their support and approaches need a dedicated physical check.',
 'Randomness_Examples_of_Randomness':'Source audit of retained procedures and narrow display correction; no new full gallery learning or listening validation.',
 'Random_Pheromone':'Fresh deterministic-step/reset/law comparison and actual-museum display/controls tests; rendered display scale differs from simulation-domain coordinates. No headset or full terrain traversal claim.',
 'Random_Space':'Current source and restored route. The adjacent Pheromone capture emitted a 77-cell route warning in this streamed hall; investigate it in a dedicated physical traversal. No complete museum interaction or headset claim.',
 'Random_Game':'Current source including previously omitted projectile dependency, plus qualified historical evidence. No new bodily crossing, headset or safety-performance validation.'
}
desktop={'Random_Definition','Random_Entropy','Randomness_10_PRINT_Algorithm','Random_Rotate_Random_XYZ','Random_Walk','Random_Gaussian','Random_Mushrooms','Random_Pheromone'}
for name,reason in reasons.items():
 r=core['rooms'][name]
 r.update(reason=reason,primary_tokens=roles['order'][name]['primary'],learner_verified=False,
  status='desktop_checked_headset_pending' if name in desktop else 'source_checked_draft',
  verification_scope=scopes[name],local_review='doc/book/iterations/2026-09-19-randomness-review/SUMMARY.md',
  map_sha256=sha(ROOT/f'commons/maps/{name}/map_data.json'),text_sha256=sha(ROOT/f'commons/maps/{name}/final.md'))
write(core_path,core);write(HERE/'applied-metadata.json',proposals)
print(len(texts),'manuscripts,',len(proposals),'guarded metadata fields, two existing Mushroom comparisons promoted.')
