"""Source-only family census. Writes reports; never launches Godot or edits content.

The primary population is the current main Void rooms, artifacts plus copies.
Original grid-map references and modular terms are separate coverage annexes.
Routes describe proposed integration work, not runtime or headset acceptance.
"""
from __future__ import annotations
from pathlib import Path
from collections import Counter,defaultdict
from functools import lru_cache
from datetime import datetime,timezone
import csv,hashlib,html,json,re,sys
from validate_void_rooms import available_artifacts
from check_dna_declarations import registry
from build_void_spawnlists import NOT_AN_ARTIFACT

ROOT=Path(__file__).resolve().parents[1]
WEB=ROOT.parent/'ada_encyclopedia'
OUT=ROOT/'doc/book/iterations/2026-10-27-spine-family-census'
HASHES={}
PRESENTATION={'footprint','size_group','label','title','description','show_label','label_text','caption','demo_hand','editor_label'}
BUCKETS={'reuse':'Reuse existing controls / driver','custom_adapter':'Custom adapter / lifecycle bridge','fixed_source':'Keep authored source fixed'}
# A work family is not a claim that every member runs the same algorithm.
FAMILIES=[
 ('modular','Modular recipes and editable assemblages',r'commons/modular/',1),
 ('grid2d','2D cells and rule cartridges',r'commons/substrates/grid2d/',2),
 ('grid3d','3D lattices and graph cartridges',r'commons/substrates/grid3d/',3),
 ('bar_array','Bar arrays and sorting cartridges',r'commons/substrates/bar',2),
 ('profile','Profiles, sampling and curves',r'commons/substrates/profile/',2),
 ('living_paper','Living-paper algorithm cartridges',r'commons/substrates/living_paper/',2),
 ('walkgrids','Walkable function surfaces',r'commons/(?:walkgrids|substrates/walk)',3),
 ('mesh_grammar','Mesh grammar and boundary assemblies',r'commons/mesh_grammar/',2),
 ('patterns','Symmetry, pattern grammars and textile machines',r'algorithms/(?:symmetry|patterngeneration)/|commons/artifacts/(?:pattern_|regularity/|jacquard_|thread_loom|garment_|mamma_monster|fabric_shader|rd_artifact)|commons/ui/panel_bridge/',3),
 ('topology','Alternative geometries and walkable topology',r'algorithms/alternativegeometries/|commons/artifacts/(?:hyperbolic_|elliptic_|riemann_|poincare_|curvature_|rhizom|radial_inside|descent_landscape)',3),
 ('emergence','Growth, biological forms and self-organisation',r'algorithms/(?:computationalbiology|emergentsystems/selforganizingpatterns|nature_system)/|commons/artifacts/(?:petri_dish|queer_morphology|turing_pattern)',3),
 ('props','Reusable environmental props and handmade construction',r'commons/artifacts/(?:crate/|station/station_crates|wooden_pallet/|do_not_cross_barrier/|concrete_barrier/|hangar_supply|glove_box/|street_sign/|kaleidoscope/)|commons/scenes/mapobjects/pick_up_cube',1),
 ('transform_relations','Transformation, timing and composition relations',r'algorithms/transformation/|commons/artifacts/(?:sun_feather/|barrier_scale_line/|movable_pivot/|transform_composition|axis_translation|uniform_scale|approach_|axial_sweep|carve_grid|fuzzy_doorway|timing_machines/phase_rod)',1),
 ('body_studies','Situated bodies, identity and embodied instruments',r'commons/artifacts/(?:drag_catwalk/|nail_salon/|super_drag_mirror/|situated_readout/|wiki_fragment/|markov_blanket_room/)',4),
 ('matter_logic','Matter logic and physical assemblies',r'commons/artifacts/(?:matter_|pallet_|almost_|leaning_)',3),
 ('transform_machines','Mechanical transformation studies',r'commons/artifacts/(?:transformation_|wave_mechan|rotation_studies|hand_crank|belt_)',3),
 ('instruments','Screens and measurement instruments',r'commons/(?:artifacts/(?:science_screen|measurement|telemetry|meter|instrument|oscilloscope)|interfaces/|instruments/|visualaid/frame_counter/)',2),
 ('reference','Reference images, films and historical studies',r'commons/artifacts/(?:spine_film|reference_|durer|melencolia|melancolia)|commons/context/',4),
 ('physics','Physics, forces and constrained bodies',r'algorithms/(?:physicssimulation|forces|force|chaos)|commons/artifacts/(?:forces_|force_|noc_|spring|pendulum|rope|chain|basin_water)',3),
 ('softbodies','Soft bodies, cloth and form finding',r'algorithms/(?:softbodies|formfinding)|commons/artifacts/(?:softbody|soft_body|form_finding|cloth)',4),
 ('waves','Waves, oscillators and wave fields',r'algorithms/wavefunctions/|commons/artifacts/(?:wave|oscillat|sine|fourier)',2),
 ('randomness','Randomness and stochastic studies',r'algorithms/randomness/|commons/artifacts/(?:random|stochastic|probability|distribution)',2),
 ('noise','Noise fields and sampling',r'algorithms/noise/|commons/artifacts/(?:noise|perlin|simplex)',2),
 ('color','Colour, light and material studies',r'algorithms/(?:color/|postprocessing/flashlight_demo/)|commons/artifacts/(?:color|colour|light_|spectrum)',2),
 ('arrays','Repetition, arrays and index spaces',r'algorithms/arrays/|commons/artifacts/(?:array|grid_|lattice|index_)',2),
 ('ca','Cellular automata and local-rule worlds',r'algorithms/cellularautomata/|commons/artifacts/(?:cellular|ca_|game_of_life)',3),
 ('fractals','Fractals and recursive geometry',r'algorithms/fractals/|commons/artifacts/(?:fractal|sierpinski|mandelbrot|julia_|recursive)',3),
 ('lsystems','L-systems, rewriting and growing structures',r'algorithms/lsystems/|commons/artifacts/(?:lsystem|l_system|turtle)',3),
 ('procedural','Procedural generation and spatial rules',r'algorithms/proceduralgeneration/|commons/artifacts/(?:procedural|wfc_|voronoi|delaunay|poisson)',3),
 ('fields','Isosurfaces, scalar fields and Boolean forms',r'algorithms/(?:isosurfaces|boolean_surfaces|spacetopology)|commons/artifacts/(?:isosurface|metaball|gyroid|sdf_|implicit|boolean)',3),
 ('shaders','Shaders and GPU-dependent appearances',r'algorithms/shaders/|commons/artifacts/(?:shader|raymarch)',4),
 ('swarms','Swarms, agents and collective dynamics',r'algorithms/(?:swarmintelligence|flocking|boids|emergentsystems/boidflocking)|commons/artifacts/(?:boid|flock|swarm|pso_|ant_|stigmer)',3),
 ('graphs','Graphs, paths and network algorithms',r'algorithms/graphtheory/|commons/artifacts/(?:graph|network|dijkstra|astar|a_star)',3),
 ('learning','Learning systems, optimisation and models',r'algorithms/(?:machinelearning|optimization|numericalmethods)/|commons/artifacts/(?:neural|perceptron|learning|gradient|classifier)',4),
 ('foundations','Foundations, QFEP and interpretive studies',r'algorithms/(?:foundations|qfep|postfoundations)|commons/artifacts/(?:qfep|foundations|crisis|bias_|ordinary_entrop)',4),
 ('geometry','Primitives, lines and geometric construction',r'algorithms/(?:primitives|vectors)|commons/(?:primitives/|scenes/mapobjects/configurable_portal|artifacts/(?:primitive|line_|point_|triangle|quad_|polyhedr|platonic|profile_|column|solid_|cube_|circle_|sphere|torus|tetra|pyramid|wedge|cylinder|trace_paint|wall_drawing))',1),
 ('audio','Audio, rhythm and sequencers',r'commons/audio/|algorithms/speech/|commons/artifacts/(?:sound|audio|sequencer|drum|beat_)',4),
 ('hazards','Hazards, actors and game interactions',r'commons/hazards/|commons/artifacts/(?:enemy|hazard|turret|sentry|creature|catapult)',4),
 ('void_context','Void architecture and floor-specific integrations',r'commons/void/',3),
 ('lab_context','Lab fixtures and contextual installations',r'commons/lab/',3),
]

def load(path):return json.loads(text(path))
@lru_cache(None)
def text(path):
 p=Path(path)
 if not p.exists():return ''
 raw=p.read_bytes();HASHES[p.relative_to(ROOT).as_posix() if p.is_relative_to(ROOT) else str(p)]=hashlib.sha256(raw).hexdigest()
 return raw.decode('utf-8-sig',errors='replace')
def resource_path(value):
 if not isinstance(value,str) or not value.startswith('res://') or '..' in value:return None
 p=ROOT/value[6:]
 if any(s in value.split('/') for s in ['ada_run','.godot','.git']):return None
 return p
def relative(p):return p.relative_to(ROOT).as_posix()
def line_number(src,at):return src.count('\n',0,at)+1
def code_only(src):return '\n'.join('' if line.lstrip().startswith('#') else line.split(' #',1)[0] for line in src.split('\n'))
def resolve_ref(value,owner):
 if value.startswith('res://'):return value
 if '://' in value or Path(value).is_absolute():return None
 p=resource_path(owner)
 if not p:return None
 target=(p.parent/value).resolve()
 return 'res://'+relative(target) if target.is_relative_to(ROOT) and not any(x in target.parts for x in ['ada_run','.godot','.git']) else None

@lru_cache(None)
def scan(scene):
 """Follow explicit scene/script resources with bounded depth, never runtime dirs."""
 seen=set();scripts={};assets=set();nodes=Counter();simulation_nodes=Counter();queue=[(scene,0)];missing=[];dynamic=set();truncated=False
 while queue:
  res,depth=queue.pop(0)
  if res in seen:continue
  seen.add(res);p=resource_path(res)
  if not p or not p.is_file():missing.append(res);continue
  if len(seen)>90:truncated=True;break
  if p.suffix not in ['.tscn','.gd','.gdshader','.tres']:
   assets.add(res);continue
  src=text(p)
  if p.suffix=='.gd':scripts[res]=src
  if p.suffix=='.tscn':
   kinds=re.findall(r'\[node[^\]]*\btype="([^"]+)"',src);nodes.update(kinds)
   if not re.search(r'/(?:addons/|interactables/|rack_templates/)',res):simulation_nodes.update(kinds)
  if depth<4:
   refs=re.findall(r'(?:path=|preload\(|load\(|extends\s+)"([^"\n]+)"',code_only(src))
   for value in refs:
    ref=resolve_ref(value,res)
    if not ref:continue
    if '%' in ref or '...' in ref:dynamic.add(ref);continue
    suffix=Path(ref).suffix
    if suffix in ['.tscn','.gd','.gdshader','.tres']:queue.append((ref,depth+1))
    elif suffix in ['.glb','.gltf','.obj','.blend','.png','.jpg','.jpeg','.webp','.svg','.ogg','.wav','.mp4','.webm']:assets.add(ref)
 exports=[];methods=set();cfg={}
 for res,src in scripts.items():
  if res.startswith('res://addons/'):continue
  methods.update(re.findall(r'^func\s+(\w+)\(',src,re.M))
  for m in re.finditer(r'@export(?:_\w+(?:\([^\n]*\))?)?\s+(?:\n\s*)?var\s+(\w+)([^\n]*)',src):
   annotation=src[m.start():m.end()].split('var ',1)[0].strip();tail=m.group(2).strip()
   enums=re.findall(r'"([^"\n]*)"',annotation) if '@export_enum' in annotation else []
   exports.append({'key':m.group(1),'declaration':tail[:180],'annotation':annotation,'enum_values':enums,'source':res,'line':line_number(src,m.start())})
  for m in re.finditer(r'\b(?:get|get_meta)\(\s*["\']((?:config_)?[A-Za-z_]\w*)["\']',src):
   key=m.group(1).removeprefix('config_');cfg.setdefault(key,{'source':res,'line':line_number(src,m.start())})
 all_src='\n'.join(scripts.values())
 own='\n'.join(code_only(s) for p,s in scripts.items() if not p.startswith('res://addons/'))
 flags={
  'physics':False,
  'world_context':bool(re.search(r'\b(?:GameManager|MapProgressionManager|GridSystem|grid_context|grid_data|find_world|find_grid|PhysicsServer3D|XRServer)\b',own)),
  'shader':bool(re.search(r'\bShaderMaterial\b|set_shader_parameter|\.gdshader',own)),
  'subviewport':bool('SubViewport' in own or nodes['SubViewport']),
  'procedural_geometry':bool(re.search(r'\b(?:SurfaceTool|ArrayMesh|CSGCombiner3D|CSGBox3D|ImmediateMesh)\b',own)),
  'behaviour':bool(re.search(r'func _(?:physics_)?process\(',own)),
  'hand_interaction':bool(re.search(r'\b(?:XRToolsPickable|picked_up|is_picked_up|XRController3D)\b',own)),
 }
 # Script paths directly declared on the entry scene, plus explicit inheritance.
 primary=[];p=resource_path(scene);src=text(p) if p and p.exists() else ''
 if p and p.suffix=='.gd':primary=[scene]
 elif p and p.suffix=='.tscn':primary=[resolve_ref(v,scene) for v in re.findall(r'\[ext_resource type="Script"[^\]]*path="([^"]+)"',src)]
 primary=[v for v in primary if v]
 for res in list(primary):
  for value in re.findall(r'^extends\s+"([^"\n]+)"',scripts.get(res,''),re.M):
   parent=resolve_ref(value,res)
   if not parent:continue
   if parent not in primary:primary.append(parent)
 primary=[s for s in primary if not s.startswith('res://addons/')]
 direct_exports=[e for e in exports if e['source'] in primary]
 primary_text='\n'.join(code_only(scripts.get(s,'')) for s in primary)
 body_names='RigidBody3D|SoftBody3D|HingeJoint3D|SliderJoint3D|Generic6DOFJoint3D|PinJoint3D'
 # A utility mentioning a body is not evidence that the entry simulates one.
 flags['dependency_physics_candidate']=bool(re.search(r'\b(?:'+body_names+r')\.new\(|extends\s+(?:'+body_names+r')\b',own))
 flags['physics']=bool(re.search(r'\b(?:'+body_names+r')\.new\(|extends\s+(?:'+body_names+r')\b',primary_text) or any(simulation_nodes[n] for n in body_names.split('|')))
 flags['world_context']=bool(re.search(r'\b(?:GameManager|MapProgressionManager|GridSystem|grid_context|grid_data|find_world|find_grid|PhysicsServer3D|XRServer)\b',primary_text))
 return {'scene':scene,'primary_scripts':primary,'script_paths':list(scripts),'exports':exports,'direct_exports':direct_exports,'config_keys':cfg,'methods':sorted(methods),'flags':flags,'assets':sorted(assets),'node_types':dict(nodes),'missing_resources':sorted(set(missing)),'dynamic_resources':sorted(dynamic),'bounded_graph':truncated,'shared_contract':bool(re.search(r'func apply_grid_config\(',primary_text))}

def family_of(scene,entry):
 # Strong shared-driver matches must come before broader work-family paths.
 for fid,label,pattern,phase in FAMILIES:
  if re.search(pattern,scene):return fid,label,'source_path',phase
 category=str(entry.get('category') or entry.get('dev_category') or '')
 by_category={'vectors_forces':'physics','forces':'physics','physics':'physics','soft_bodies':'softbodies','softbodies':'softbodies','wavefunctions':'waves','waves':'waves','randomness':'randomness','noise':'noise','color':'color','colour':'color','arrays':'arrays','cellular_automata':'ca','cellularautomata':'ca','fractals':'fractals','lsystems':'lsystems','procedural':'procedural','proceduralgeneration':'procedural','isosurfaces':'fields','boolean_surfaces':'fields','shaders':'shaders','swarmintelligence':'swarms','graphtheory':'graphs','machinelearning':'learning','qfep':'foundations','foundations':'foundations','postfoundationscrisis':'foundations','primitives':'geometry','reference_studies':'reference','audio':'audio','hazards':'hazards'}
 by_category.update({'transforms':'transform_relations','transformations':'transform_relations','vectors':'physics','vectors_demos':'physics','philosophy':'foundations','postfoundations':'foundations','concept_architecture':'foundations','limits-of-math':'foundations','limits-of-computing':'foundations','instruments':'instruments','laboratory':'lab_context','geometry':'geometry','synthesis':'modular','lab_prop':'props','station':'props','textile':'patterns','patterns':'patterns','dna_grammar':'patterns','symmetry':'patterns','emergence':'emergence','nature_system':'emergence','quantumalgorithms':'learning'})
 fid=by_category.get(category,'other')
 for ident,label,_,phase in FAMILIES:
  if fid==ident:return fid,label,'registry_category',phase
 return 'other','Specialised scenes requiring source review','unresolved',4

def route(token,entry,sig,family):
 axes=(entry.get('dna') or {}).get('axes') or {};axes=axes if isinstance(axes,dict) else {}
 exp={e['key'] for e in sig['exports']};direct={e['key'] for e in sig['direct_exports']};keys=set(sig['config_keys'])
 matched=sorted(set(axes)&(exp|keys));unmapped=sorted(set(axes)-(exp|keys))
 meaningful=direct-PRESENTATION;flags=sig['flags'];scene=sig['scene'];notes=[]
 image_assets=[a for a in sig['assets'] if Path(a).suffix in ['.png','.jpg','.jpeg','.webp','.svg']]
 mesh_assets=[a for a in sig['assets'] if Path(a).suffix in ['.glb','.gltf','.obj','.blend']]
 nested_meaningful={e['key'] for e in sig['exports']}-PRESENTATION
 frozen_content=(family=='reference' and not nested_meaningful and not flags['physics'] and not flags['procedural_geometry'] and not flags['behaviour'])
 fixed_asset=bool(mesh_assets or image_assets) and not nested_meaningful and not axes and not flags['procedural_geometry'] and not flags['physics'] and not flags['behaviour']
 if sig['missing_resources'] or not resource_path(scene) or not resource_path(scene).exists():
  bucket='custom_adapter';reason='Resolve source/dependency evidence before choosing an adapter.';confidence='low'
 elif token.startswith('film_') and '/spine_films/' in scene:
  bucket='fixed_source';reason='Preserve the authored lesson/film content; expose playback and presentation around it.';confidence='high'
 elif frozen_content or fixed_asset:
  bucket='fixed_source';reason='Preserve authored media/mesh content; reuse staging and presentation controls.';confidence='medium'
 elif re.search(r'commons/(?:modular/|substrates/|mesh_grammar/|walkgrids/)',scene):
  bucket='reuse';reason='An existing recipe or substrate driver supplies the implementation; connect its shared contract.';confidence='high'
 elif flags['physics'] or (flags['world_context'] and not matched):
  bucket='custom_adapter';reason='Parameter application must coordinate native simulation, context and reset/rebuild lifecycle.';confidence='medium'
 elif sig['shared_contract'] or meaningful or matched:
  bucket='reuse';reason='Reuse source-declared properties/configuration through a typed native adapter; curate the exposed controls.';confidence='medium'
 else:
  bucket='custom_adapter';reason='The scene has no evidenced reusable configuration surface; author and validate its binding.';confidence='low'
 if unmapped:notes.append('DNA axes not resolved by this bounded source scan: '+', '.join(unmapped))
 if not sig['direct_exports'] and sig['exports']:notes.append('Candidate exports live in inherited/nested resources; binding addresses need review.')
 if sig['bounded_graph']:notes.append('Dependency scan reached its cap; do not infer absence of controls.')
 if sig.get('dynamic_resources'):notes.append('Generated resource paths require adapter review: '+', '.join(sig['dynamic_resources']))
 if flags.get('dependency_physics_candidate') and not flags['physics']:notes.append('A nested/helper dependency can create bodies; verify whether this configuration uses it before exposing rebuild controls.')
 if flags['physics']:notes.append('Body/collision reset and preserved authored geometry need native checks.')
 if mesh_assets:notes.append('Imported mesh is a fixed component even when its containing study is configurable.')
 if image_assets:notes.append('Images/textures are referenced source assets, not newly invented procedural geometry.')
 if bucket=='fixed_source':preview='asset_or_native_presentation'
 elif family=='modular' and not (flags['physics'] or flags['world_context']):preview='shared_recipe_preview'
 else:preview='native_preview_first'
 return bucket,reason,confidence,preview,matched,unmapped,notes

def main():
 sys.stdout.reconfigure(encoding='utf8');OUT.mkdir(parents=True,exist_ok=True)
 rooms_path=ROOT/'commons/void/rooms.json';layout_path=ROOT/'commons/void/layout.json'
 rooms=load(rooms_path);layout=load(layout_path);terms=load(ROOT/'commons/modular/terms.json')['terms'];reg=registry();cat=available_artifacts()
 # Fingerprint exactly the definition stores used by the two existing resolvers.
 for p in sorted((ROOT/'commons/artifacts/registry').glob('*.json')):text(p)
 text(ROOT/'commons/void/catalog.json')
 seqs=load(ROOT/'commons/maps/curriculum_spine.json')['spine']['sequences'];map_seq={}
 for seq in seqs:
  p=ROOT/'commons/maps/sequences'/(seq['name']+'.json')
  if not p.exists():continue
  doc=load(p);entries=doc.get('sequences',{});entries=entries.values() if isinstance(entries,dict) else entries
  for item in entries:
   for m in item.get('maps',[]):
    if isinstance(m,str):map_seq.setdefault(m,[]).append(seq['name'])
 occurrences=[];by_token=defaultdict(list);source_refs=defaultdict(list);source_missing_maps=[];directives=Counter()
 fixtures={'construction_cells':Counter(),'props':Counter(),'walls':0}
 for i,floor in enumerate(rooms['floors']):
  for collection in ['artifacts','copies']:
   for a in floor.get(collection,[]):
    config=a.get('config',{});o={'occurrence_id':f'{i}/{collection}/{a["id"]}','floor':i,'map':floor['map'],'sequence':map_seq.get(floor['map'],[]),'collection':collection,'id':a['id'],'token':a['artifact'],'position':a.get('position'),'height':a.get('height',0),'facing':a.get('facing',0),'scale':a.get('scale',1),'config_keys':sorted(config),'selectors':{k:v for k,v in config.items() if k in ['recipe','recipe_document','term','algorithm','cartridge','profile','study','mode','single_axis']},'source':config.get('editor_source'),'authored_member_edits':len(config.get('parts',{})),'isolated_members':config.get('only_parts',[])}
    occurrences.append(o);by_token[a['artifact']].append(o)
    if config.get('recipe_document'):
     p=resource_path(config['recipe_document'])
     if p and p.exists():text(p)
  fixtures['construction_cells'].update(a['kind'] for a in floor.get('construction',[]));fixtures['props'].update(a['kind'] for a in floor.get('props',[]));fixtures['walls']+=len(floor.get('walls',[]))
  mp=ROOT/'commons/maps'/floor['map']/'map_data.json'
  if not mp.exists():source_missing_maps.append({'floor':i,'map':floor['map']});continue
  rows=(load(mp).get('layers') or {}).get('interactables') or []
  for z,row in enumerate(rows):
   cells=row if isinstance(row,list) else str(row).split(',')
   for x,value in enumerate(cells):
    raw=str(value or '');tok=raw.split('#')[0].split(':')[0].strip()
    if tok in NOT_AN_ARTIFACT:directives[tok]+=1;continue
    source_refs[tok].append({'floor':i,'map':floor['map'],'cell':[x,z],'raw':raw})
 evidence_index=WEB/'public/artifact-dna/index.json';prior={}
 if evidence_index.exists():
  d=load(evidence_index);prior=d.get('artifacts',{})
  if isinstance(prior,list):prior={v if isinstance(v,str) else str(v.get('token','')):{} for v in prior}
 all_rows=[]
 for token in sorted(set(by_token)|set(source_refs)):
  metadata,registry_file=reg.get(token,({},None));entry={**metadata,**cat.get(token,{})};scene=str(entry.get('scene') or entry.get('scene_path') or '')
  sig=scan(scene) if scene else {'scene':'','primary_scripts':[],'script_paths':[],'exports':[],'direct_exports':[],'config_keys':{},'methods':[],'flags':{},'assets':[],'node_types':{},'missing_resources':['unresolved runtime scene'],'bounded_graph':False,'shared_contract':False}
  if not scene:sig['flags']={k:False for k in ['physics','world_context','shader','subviewport','procedural_geometry','behaviour','hand_interaction']}
  family,label,basis,phase=family_of(scene,entry);bucket,reason,confidence,preview,matched,unmapped,notes=route(token,entry,sig,family)
  occ=by_token.get(token,[]);declared=entry.get('parameters') or {};declared=declared if isinstance(declared,dict) else {}
  candidate_keys={e['key'] for e in sig['exports']}|set(sig['config_keys'])
  selectors=defaultdict(set)
  for o in occ:
   for k,v in o['selectors'].items():selectors[k].add(json.dumps(v,sort_keys=True,ensure_ascii=False))
  all_rows.append({'id':'artifact:'+token,'token':token,'label':str(entry.get('name') or entry.get('label') or token),'scope':'placed' if occ else 'source_only','placements':len(occ),'floors':sorted({o['floor'] for o in occ}),'maps':sorted({o['map'] for o in occ}),'sequences':sorted({s for o in occ for s in o['sequence']}),'family':family,'family_label':label,'grouping_basis':basis,'proposed_route':bucket,'reason':reason,'confidence':confidence,'preview_strategy':preview,'wave':phase,'scene':scene,'registry_file':registry_file,'primary_scripts':sig['primary_scripts'],'script_paths':sig['script_paths'],'direct_exports':sig['direct_exports'],'candidate_exports':sig['exports'],'config_keys':sig['config_keys'],'root_config_hook':sig['shared_contract'],'methods':[m for m in sig['methods'] if m in ['apply_grid_config','rebuild','reset','_reset','reset_simulation','prepare_editor_preview','update_parameter','apply_config']],'flags':sig['flags'],'dna_axes':(entry.get('dna') or {}).get('axes',{}),'source_matched_dna_axes':matched,'unresolved_dna_axes':unmapped,'registry_parameter_names':sorted(declared),'metadata_without_source_match':sorted(set(declared)-candidate_keys),'assets':sig['assets'],'fixed_components':[a for a in sig['assets'] if Path(a).suffix in ['.glb','.gltf','.obj','.blend','.png','.jpg','.jpeg','.svg','.webp']],'source_ref_count':len(source_refs.get(token,[])),'selector_variants':{k:sorted(v) for k,v in selectors.items()},'prior_dna_index_entry':token in prior,'verification':'source_inspection_only','review_notes':notes,'missing_resources':sig['missing_resources'],'dynamic_resources':sig.get('dynamic_resources',[]),'source_graph_capped':sig['bounded_graph']})
 placed=[r for r in all_rows if r['scope']=='placed'];annex=[r for r in all_rows if r['scope']=='source_only'];families=[]
 for fid in sorted({r['family'] for r in placed},key=lambda fid:(min(r['wave'] for r in placed if r['family']==fid),fid)):
  members=[r for r in placed if r['family']==fid];drivers=Counter(p for r in members for p in r['primary_scripts'])
  families.append({'id':fid,'label':members[0]['family_label'],'wave':members[0]['wave'],'types':len(members),'placements':sum(r['placements'] for r in members),'routes':dict(Counter(r['proposed_route'] for r in members)),'distinct_scenes':len({r['scene'] for r in members}),'source_matched_dna_types':sum(bool(r['source_matched_dna_axes']) for r in members),'native_config_hook_types':sum(r['root_config_hook'] for r in members),'top_shared_drivers':[{'source':p,'types':n} for p,n in drivers.most_common(8)],'grouping_note':'A work package; shared driver paths are explicit evidence. Family membership alone does not prove identical parameter semantics.','tokens':[r['token'] for r in members]})
 shared=defaultdict(list)
 for row in placed:
  for driver in row['primary_scripts']:shared[driver].append(row['token'])
 shared_drivers=[{'source':source,'types':len(tokens),'tokens':tokens} for source,tokens in sorted(shared.items(),key=lambda kv:(-len(kv[1]),kv[0])) if len(tokens)>1]
 review_queue=[]
 for row in placed:
  issues=[]
  if row['missing_resources']:issues.append('unresolved_literal_resource_path')
  if row['source_graph_capped']:issues.append('bounded_resource_graph')
  if row['unresolved_dna_axes']:issues.append('dna_binding_not_found_by_scan')
  if row['confidence']=='low':issues.append('adapter_contract_requires_source_review')
  if issues:review_queue.append({'token':row['token'],'family':row['family'],'issues':issues,'details':row['missing_resources']+row['unresolved_dna_axes'],'placements':row['placements']})
 manual_review=[
  {'token':'science_screen','decision':'Reuse source-backed support/surface enums; helper mentions of bodies do not make the screen a physics assembly.','evidence':'commons/artifacts/science_screen/science_screen.gd:184; apply_grid_config:1559'},
  {'token':'matter_spring_and','decision':'Custom lifecycle bridge despite exported properties. Keep operator identity separate from safe reset delay and editable pieces.','evidence':'commons/artifacts/matter_logic_spring/matter_logic.gd:19,21,200,223,264'},
  {'token':'spatial_recipe','decision':'Reuse the frozen recipe contract. Preserve occurrence-level recipe_document, stable member IDs and context scale.','evidence':'commons/modular/recipe_area.gd:14; commons/modular/transformation.json'},
  {'token':'sun_feather','decision':'Reuse ingredient and transformation vocabulary; native assembly needs a lifecycle adapter and generated-resource handling.','evidence':'commons/artifacts/sun_feather/sun_feather.gd; commons/void/lines_area.gd'},
  {'token':'film_transformation_order','decision':'Keep authored lesson content fixed; expose presentation around it and link editable subject variants separately.','evidence':'commons/artifacts/spine_films/monitors/film_transformation_order.tscn'},
  {'token':'boolean_eggs','decision':'Wrapper has nested show_ground/museum_mount properties, not a generic fixed image. Source geometry remains authored; adapter target needs review.','evidence':'commons/artifacts/kapoor_void_studies/boolean_eggs_museum.tscn; boolean_eggs.gd:7'},
  {'token':'perlin_noise','decision':'Reuse declared noise controls. Rigid bodies belonging to rack sliders are not evidence of a dynamic terrain simulation.','evidence':'algorithms/randomness/perlinnoise/PerlinNoise.gd; NoiseVisualizer.gd'},
  {'token':'crackpropagation_ca','decision':'Unresolved literal old script path; a same-named source exists in growth_systems. Check UID-aware resolution before reporting a runtime failure or changing it.','evidence':'algorithms/proceduralgeneration/growth_systems/crackpropagation_ca/crackpropagation_ca.tscn:3'},
  {'token':'nakama_metaballs','decision':'Unresolved literal old script path; a same-named source exists under isosurfaces/metaballs. Check UID-aware resolution before migration.','evidence':'algorithms/proceduralgeneration/isosurfaces/metaballs/nakama_metaballs.tscn:3'},
  {'token':'reaction_diffusion','decision':'Unresolved literal old PackedScene path; turing_pattern.tscn exists under growth_systems/reactiondiffusion. This scan does not prove Godot fails to load it.','evidence':'algorithms/proceduralgeneration/growth_systems/reactiondiffusion/2d_in_3d_turing_pattern_reaction_diffusion.tscn:3'},
 ]
 term_rows=[{'id':'term:'+k,'term':k,'chapter':v.get('chapter'),'parents':v.get('from',[]),'named_bindings':v.get('parameters',{}),'handmade':bool(v.get('handmade')),'registered_scene':cat.get('mod_'+k,{}).get('scene'),'in_placed_tokens':('mod_'+k) in by_token} for k,v in terms.items()]
 missing=[r for r in placed if not r['scene'] or r['missing_resources']]
 summary={'floor_records':len(rooms['floors']),'placed_occurrences':len(occurrences),'placed_types':len(placed),'work_families':len(families),'proposed_routes':dict(Counter(r['proposed_route'] for r in placed)),'confidence':dict(Counter(r['confidence'] for r in placed)),'registry_dna_types':sum(bool(r['dna_axes']) for r in placed),'source_matched_dna_types':sum(bool(r['source_matched_dna_axes']) for r in placed),'unresolved_dna_types':sum(bool(r['unresolved_dna_axes']) for r in placed),'direct_export_types':sum(bool(r['direct_exports']) for r in placed),'root_config_hook_types':sum(r['root_config_hook'] for r in placed),'prior_dna_index_types':sum(r['prior_dna_index_entry'] for r in placed),'source_graph_gap_types':len(missing),'source_only_types':len(annex),'original_grid_reference_occurrences':sum(len(v) for v in source_refs.values()),'modular_terms':len(term_rows),'modular_terms_with_named_bindings':sum(bool(t['named_bindings']) for t in term_rows),'modular_terms_not_registered':sum(not t['registered_scene'] for t in term_rows),'construction_cells':sum(fixtures['construction_cells'].values()),'construction_kinds':len(fixtures['construction_cells']),'prop_occurrences':sum(fixtures['props'].values()),'prop_kinds':len(fixtures['props']),'wall_segments':fixtures['walls']}
 report={'schema_version':1,'generated_at':datetime.now(timezone.utc).isoformat(),'scope':'Current saved main spine artifacts + copies. Grid-only references, modular terms and construction/props are separately enumerated; no trial-directory or archive expansion.','method':'Bounded static resource inspection, registry metadata and literal source declarations. Proposed reuse is not proof of working UI controls or runtime behaviour. No native jobs, playtest input or map writes.','classification_policy':{'reuse':'Existing recipe/driver, root exported properties or a source configuration hook; connect and curate a typed adapter. Native preview may still be required.','custom_adapter':'Simulation/context/reset coupling, unresolved binding/source, or absent reusable configuration hook. A shared family adapter may resolve many rows together.','fixed_source':'Preserve authored media/mesh/lesson content while retaining common placement/presentation and explicit editable member poses. This is an authorship decision, not a claim that code can never be extended.'},'summary':summary,'families':families,'artifacts':all_rows,'occurrences':occurrences,'source_grid_references':dict(source_refs),'modular_terms':term_rows,'construction_and_props':{k:dict(v) if isinstance(v,Counter) else v for k,v in fixtures.items()},'missing_source_maps':source_missing_maps,'limitations':['Static scan: no slider response, enum validity, collision, solver stability, Three.js equivalence or headset acceptance was tested.','Nested controls and dynamic resource lookup can escape the bounded scan; unresolved entries require review, not invented parameters.','Source-only grid references do not prove missing imports; replacements, assemblies and intentional removals require the separate occurrence audit.','Preserve existing user layouts, handmade identities, construction cells, intentional removals, source fallback meshes and image/shader proxies.','The source files can change during an active project; source hashes and the coverage gate make this report reproducible.']}
 report.update(shared_declared_drivers=shared_drivers,review_queue=review_queue,manual_review=manual_review)
 for p in [Path(__file__),ROOT/'tools/spine_catalogue_proposal.py',ROOT/'commons/modular/transformation.json',WEB/'src/lib/transformation-lab.ts',WEB/'src/lib/primitive-prefabs.ts',WEB/'src/lib/prefab-workbench-store.ts']:
  if p.exists():text(p)
 changed=[p for p,h in HASHES.items() if not (ROOT/p).exists() or hashlib.sha256((ROOT/p).read_bytes()).hexdigest()!=h]
 report['source_files']=dict(sorted(HASHES.items()));report['source_changes_during_scan']=changed
 ids=[r['token'] for r in placed];assert len(ids)==len(set(ids))==len(by_token)
 assert sum(r['placements'] for r in placed)==len(occurrences)
 assert all(r['proposed_route'] in BUCKETS for r in placed)
 assert sum(f['types'] for f in families)==len(placed)
 assert sum(f['placements'] for f in families)==len(occurrences)
 assert all(o['token'] in ids for o in occurrences)
 report['coverage_gate']={'passed':not changed,'every_placed_token_once':True,'every_placement_accounted_for':True,'family_totals_reconcile':True,'native_testing_performed':False}
 write_outputs(report)
 print(json.dumps(summary,indent=2));print('Coverage gate:',report['coverage_gate'])

def write_outputs(d):
 from spine_catalogue_proposal import write_proposal
 write_proposal(d,ROOT,OUT)
 (OUT/'census.json').write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
 with (OUT/'artifacts.csv').open('w',encoding='utf-8-sig',newline='') as f:
  fields=['token','label','scope','family','proposed_route','confidence','placements','scene','preview_strategy','reason','floors','primary_scripts','registry_parameter_names','unresolved_dna_axes','review_notes'];w=csv.DictWriter(f,fieldnames=fields);w.writeheader()
  for r in d['artifacts']:w.writerow({k:' | '.join(map(str,r[k])) if isinstance(r[k],list) else r[k] for k in fields})
 render_html(d)
 (OUT/'review-queue.json').write_text(json.dumps(d['review_queue'],ensure_ascii=False,indent=2)+'\n',encoding='utf8')

def render_html(d):
 s=d['summary'];esc=lambda x:html.escape(str(x),quote=True)
 cards=''.join(f'<article><b>{s["proposed_routes"].get(k,0)}</b><span>{esc(v)}</span></article>' for k,v in BUCKETS.items())
 family_rows=''.join(f'<tr><td><a href="#inventory" data-family-link="{f["id"]}">{esc(f["label"])}</a></td><td>{f["types"]}</td><td>{f["placements"]}</td>'+''.join(f'<td>{f["routes"].get(k,0)}</td>' for k in BUCKETS)+f'<td>{f["distinct_scenes"]}</td><td>{esc("; ".join(p["source"].split("/")[-1]+" ("+str(p["types"])+")" for p in f["top_shared_drivers"][:2]))}</td></tr>' for f in d['families'])
 options=''.join(f'<option value="{f["id"]}">{esc(f["label"])}</option>' for f in d['families'])
 rows=[]
 for r in d['artifacts']:
  names=sorted({e['key'] for e in r['direct_exports']})[:18];binding=(', '.join(names) or 'No scene-declared export found')+(' · config hook' if r['root_config_hook'] else '')
  details='<br>'.join(esc(n) for n in r['review_notes'])
  rows.append(f'<tr data-scope="{r["scope"]}" data-family="{r["family"]}" data-route="{r["proposed_route"]}" data-confidence="{r["confidence"]}"><td><strong>{esc(r["label"])}</strong><br><code>{esc(r["token"])}</code><br><small>{esc(r["scene"])}</small></td><td>{esc(r["family_label"])}</td><td><span class="tag {r["proposed_route"]}">{esc(BUCKETS[r["proposed_route"]])}</span><br>{esc(r["confidence"])} confidence<br><small>{esc(r["reason"])}</small></td><td>{r["placements"]}<br><small>Floors {esc(", ".join(map(str,r["floors"])))}</small></td><td><small>{esc(binding)}</small><details><summary>Source evidence / review</summary><p>{details or "Source declarations only; runtime validation remains required."}</p>'+''.join(f'<p><code>{esc(e["key"])}</code> — {esc(e["source"])}:{e["line"]}<br>{esc(e["annotation"])} {esc(e["declaration"])}</p>' for e in r['candidate_exports'][:35])+f'<p>Preview strategy: {esc(r["preview_strategy"])}. Source-only: {r["scope"]=="source_only"}.</p></details></td></tr>')
 plan=plan_html(d)
 page=f'''<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Ada / spine family census and catalogue plan</title><style>
body{{margin:0;background:#f4f1eb;color:#27232b;font:15px/1.55 system-ui}}main{{max-width:1480px;margin:auto;padding:38px 30px}}h1{{font-size:39px;max-width:850px;line-height:1.15}}h2{{margin-top:45px}}a{{color:#773e70}}.eyebrow{{font-size:11px;letter-spacing:3px}}.lede{{max-width:980px}}.cards{{display:grid;grid-template-columns:repeat(3,1fr);gap:14px;margin:24px 0}}article,.note{{background:white;border:1px solid #dcd3dc;border-radius:9px;padding:18px}}article b{{display:block;font-size:39px}}article span{{display:block}}table{{width:100%;border-collapse:collapse;background:white;font-size:13px}}th,td{{border-bottom:1px solid #e5dfe3;padding:11px;vertical-align:top;text-align:left}}th{{position:sticky;top:0;background:#e9e3e8;z-index:2}}code,small{{overflow-wrap:anywhere}}small{{font-size:11px;color:#695e69}}td:first-child{{min-width:210px}}.wrap{{overflow:auto;border:1px solid #dfd7de;border-radius:7px}}.filters{{display:flex;gap:9px;flex-wrap:wrap;position:sticky;top:0;background:#f4f1eb;padding:12px 0;z-index:3}}input,select,button{{font:inherit;padding:9px;border:1px solid #c8bdc5;border-radius:4px;background:white}}input{{min-width:230px}}.tag{{display:inline-block;padding:4px 7px;border-radius:4px;font-size:11px}}.reuse{{background:#e2efe4}}.custom_adapter{{background:#f5e3cc}}.fixed_source{{background:#eee4f1}}summary{{cursor:pointer;color:#773e70}}details p{{font-size:11px;max-width:430px}}.plan-grid{{display:grid;grid-template-columns:repeat(2,1fr);gap:16px}}pre{{white-space:pre-wrap;background:#eee7ec;padding:16px;font-size:12px}}@media(max-width:850px){{.cards,.plan-grid{{grid-template-columns:1fr}}main{{padding:20px}}}}
</style></head><body><main><div class="eyebrow">ADA / SPINE / SOURCE CENSUS / 27 OCTOBER 2026</div><h1>One catalogue. Reuse what already has a contract.</h1><p class="lede">{s['placed_types']} distinct placed artifact types, {s['placed_occurrences']} saved occurrences, {s['floor_records']} floor records. Grouped into {s['work_families']} work families. These are proposed integration routes from source inspection; they are not runtime acceptance results.</p><p><a href="#families">Families</a> · <a href="#plan">Shared catalogue plan</a> · <a href="#inventory">Every artifact</a> · <a href="census.json">Machine-readable census</a> · <a href="artifacts.csv">CSV</a> · <a href="catalogue.schema.proposed.json">Proposed schema</a></p><div class="cards">{cards}</div><div class="note"><strong>Coverage gate: {'passed' if d['coverage_gate']['passed'] else 'source changed — rerun'}.</strong> Every saved artifact/copy occurrence is accounted for, each placed token has one primary family and route, and family totals reconcile. {s['registry_dna_types']} types declare DNA axes; {s['source_matched_dna_types']} have at least one axis found by this bounded source scan. A declaration or a lexical match is not proof of a working control.</div>
<h2 id="families">The work families</h2><p>Grouping is by source path or registry category. The driver column shows actual shared script evidence; a shared family name does not make different solvers interchangeable.</p><div class="wrap"><table><thead><tr><th>Family</th><th>Types</th><th>Occurrences</th><th>Reuse</th><th>Custom</th><th>Fixed</th><th>Scenes</th><th>Common declared drivers</th></tr></thead><tbody>{family_rows}</tbody></table></div>{plan}
<h2 id="inventory">Every artifact, with evidence</h2><p>{s['source_only_types']} additional token types occur in the original grid maps but are absent from the current saved placements. They are a separate annex, hidden initially. This does not diagnose missing imports or reverse intentional removals.</p><div class="filters"><input id="q" aria-label="Search census" placeholder="Search token, source, control…"><select id="family" aria-label="Family"><option value="">All families</option>{options}</select><select id="route" aria-label="Integration route"><option value="">All routes</option>{''.join(f'<option value="{k}">{esc(v)}</option>' for k,v in BUCKETS.items())}</select><select id="scope" aria-label="Scope"><option value="placed">Placed in saved spine</option><option value="source_only">Original grid references only</option><option value="">Both scopes</option></select><select id="confidence" aria-label="Confidence"><option value="">All confidence levels</option><option>low</option><option>medium</option><option>high</option></select><button id="clear">Clear filters</button><span id="count"></span></div><div class="wrap"><table id="inventory-table"><thead><tr><th>Artifact and source</th><th>Family</th><th>Proposed route</th><th>Occurrences</th><th>Controls / evidence</th></tr></thead><tbody>{''.join(rows)}</tbody></table></div><h2>Limits and preservation rules</h2><ul>{''.join('<li>'+esc(v)+'</li>' for v in d['limitations'])}</ul><p><small>Generated {esc(d['generated_at'])}. Reproduce with <code>python tools/spine_family_census.py</code>. No Godot jobs, source rewrites or active-playtest input.</small></p></main><script>
const ids=['q','family','route','scope','confidence'];const controls=Object.fromEntries(ids.map(id=>[id,document.getElementById(id)]));const rows=[...document.querySelectorAll('#inventory-table tbody tr')];function filter(){{const q=controls.q.value.toLowerCase();let n=0;for(const row of rows){{const show=(!q||row.textContent.toLowerCase().includes(q))&&['family','route','scope','confidence'].every(k=>!controls[k].value||row.dataset[k]===controls[k].value);row.hidden=!show;if(show)n++}}document.getElementById('count').textContent=n+' types shown'}}function chooseFamily(id){{controls.family.value=id;controls.scope.value='placed';filter()}}for(const link of document.querySelectorAll('[data-family-link]'))link.addEventListener('click',()=>chooseFamily(link.dataset.familyLink));for(const el of Object.values(controls))el.addEventListener('input',filter);document.getElementById('clear').onclick=()=>{{for(const [k,el]of Object.entries(controls))el.value=k==='scope'?'placed':'';filter()}};filter();
</script></body></html>'''
 (OUT/'index.html').write_text(page,encoding='utf8')

def plan_html(d):
 # Detailed catalogue contract/schema is generated separately, not installed.
 esc=lambda value:html.escape(str(value))
 shared=''.join('<tr><td><code>'+esc(v['source'])+'</code></td><td>'+str(v['types'])+'</td></tr>' for v in d['shared_declared_drivers'][:12])
 manual=''.join('<tr><td><code>'+esc(v['token'])+'</code></td><td>'+esc(v['decision'])+'</td></tr>' for v in d['manual_review'][:7])
 s=d['summary'];queue=len(d['review_queue'])
 return '''<h2 id="plan">Plan for the shared parameter catalogue</h2><div class="plan-grid"><article><h3>1. Separate definition, variant and placement</h3><p>A definition owns identity, lineage, source and a family contract. A variant stores chosen parameter values and its parent version. A placement owns floor-local position, orientation, size context and explicit member edits. Moving an exhibit must not mutate its source recipe.</p></article><article><h3>2. Keep one descriptor per control</h3><p>Stable key, type, native binding address, units, defaults, legal range/enum, update lifecycle, coupled constraints and validation evidence. Descriptions and footprint metadata are not automatically controls. Missing ranges and ambiguous bindings stay review tasks.</p></article><article><h3>3. Share the controls across views</h3><p>The tree supplies lineage; Spine Film and the spatial timeline supply order; modular-program supplies composition; DNA supplies comparison; the live editor supplies placement. All consume the same family and artifact descriptors, not copies of slider definitions.</p></article><article><h3>4. Make preview fidelity explicit</h3><p>Use a live shared recipe where supported, a native preview for engine-dependent behaviour, and an authored asset for fixed content. A Three.js pose, image or shader proxy must not be labelled a live physics simulation.</p></article></div>
<h3>Keep the existing source of truth</h3><p>The shared catalogue should join the current native artifact registry and Void catalogue, modular terms, handmade prefab records and spawnlists by stable IDs. It should not become a competing scene registry. Keep existing runtime tokens as aliases. Add family adapters and typed control descriptors around those sources, then make every view read that same resolved index. Geometry remains native or recipe-owned; the tree owns relationships, not duplicate meshes.</p>
<h3>A workshop with ongoing studies</h3><p>The purpose is to conduct spatial research while understanding and improving the maps. Players, Palle, the assistant and Model B can take part in different experiments at the same time. The working unit is a study: its question, source map and revision, parameter variant, editable arrangement, participants, interventions, observations and evidence. Keep an experiment open across sessions; preserve interesting failures and unexpected outcomes as well as successful routes.</p><p>Connect this record to the <a href="/lab-editor?mode=void&amp;floor=16&amp;compare=1&amp;grid=historic">floor 16 historic-grid comparison</a>. Historic source, current arrangement and experimental variant should remain identifiable. A parameter preview helps propose a change; embodied play and native evidence establish what happens. Model B should record its actions and uncertainty alongside player observations. Promotion into the tutorial is a separate reviewed map change, with the previous arrangement recoverable.</p><pre>question → saved variant → contextual map experiment
                         ↓
             players / us / Model B observe
                         ↓
       compare → keep researching or propose a map improvement</pre>
<pre>native registry + Void catalogue + modular terms + handmade records
                  ↓ resolve identity, provenance and bindings
        shared definition → immutable parameter variant
                  ↓
 tree · DNA · Spine Film / timeline · modular-program · lab editor
                  ↓
    floor placement + editable members + native acceptance</pre>
<h3>Delivery sequence</h3><ol><li><strong>Identity and common staging:</strong> give every census row a stable definition ID and provenance, retain legacy tokens and link term IDs. Preserve position, rotation, existing size context, part IDs and explicit edits. Add approach direction, circulation envelope and support references as staging data. These controls also serve fixed-source material. Do not reorder the tutorial as part of the migration.</li><li><strong>Prove the shared contract:</strong> migrate Transformation first, including planks/barriers/portals, four size contexts and old saved variants. Add <code>science_screen</code> as a native-backed control example, <code>matter_spring_and</code> for simulation lifecycle, and <code>film_transformation_order</code> for fixed authored content. Display all four through the same inspector and save/place/reload flow.</li><li><strong>Expand existing drivers:</strong> connect primitives and props, arrays, colour, profiles, waves, and substrate cartridges. Curate a small meaningful control surface per driver. Child artifacts inherit a versioned contract and override only their valid domains; do not expose every implementation variable.</li><li><strong>Context and dynamics:</strong> work through mechanical logic, constrained bodies, walkable fields, agents, CA and procedural systems by actual script clusters. Specify seed, timestep, pause, collision updates, reset and world dependencies before exposing live controls. Partition live-safe changes from rebuilds; never mutate an active playtest.</li><li><strong>Exceptions and authored material:</strong> resolve literal resource references and ambiguous declarations, retain fixed images/meshes/lessons and explicit handmade poses, and link each exception to its source. Never fabricate geometry to make the index look complete.</li></ol>
<h3>Acceptance gate per adapter</h3><p>The native binding exists; default reproduces the original; representative min/default/max or enum values change the intended property; mesh/collision and state/reset rules remain consistent; seeds are recorded where applicable; an immutable variant saves, places, copies and reloads; previews declare their fidelity; source/editor fingerprints remain current. Physics/interaction acceptance still needs the appropriate desktop/Quest checks. Record this evidence on the adapter version rather than copying a passing flag to unrelated members.</p>
<h3>Scheduling</h3><p>The earlier 4–8 week estimate remains provisional. This census identifies source contracts and work packages, not measured implementation effort. First timebox the four pilot definitions above, then estimate remaining driver clusters using their actual effort and exception rate. Separate the milestone “every artifact is findable and placeable with provenance” from “every meaningful behavior has verified parameter controls.” A work family can need several adapters; several families can reuse one driver.</p>
<p><a href="catalogue.schema.proposed.json">Proposed JSON schema</a> · <a href="catalogue.examples.proposed.json">Four source-backed examples, plus variant and unplaced placement</a>. Schema and examples are structurally validated design artifacts; no new runtime catalogue has been installed.</p>'''+f'''
<h3>Where shared code can reduce the work</h3><p>These are script paths declared by multiple placed types, including explicit parent scripts. Types may appear under more than one driver, so this column must not be summed. Shared code is a candidate for a common adapter, not proof of identical controls.</p><div class="wrap"><table><thead><tr><th>Declared driver</th><th>Types using it</th></tr></thead><tbody>{shared}</tbody></table></div>
<h3>Representative source review</h3><div class="wrap"><table><thead><tr><th>Artifact</th><th>Disposition</th></tr></thead><tbody>{manual}</tbody></table></div>
<h3>Review queue and separate coverage</h3><p><a href="review-queue.json">{queue} placed types need additional source/binding review</a>, including {s['source_graph_gap_types']} unresolved literal resource references and {s['unresolved_dna_types']} types with DNA keys not located by the scanner. These are source-resolution tasks; Godot UID fallback and runtime loading were not tested. The census includes {s['modular_terms']} modular terms separately; {s['modular_terms_with_named_bindings']} explicitly declare named bindings. Literal recipe editing and named parameter readiness are different measures.</p><p>Common staging is also recorded separately: {s['construction_cells']} construction cells ({s['construction_kinds']} kinds), {s['prop_occurrences']} props ({s['prop_kinds']} kinds), and {s['wall_segments']} wall segments. Preserve these and reuse their definitions where useful rather than converting them into new artifact occurrences.</p>'''

if __name__=='__main__':main()
