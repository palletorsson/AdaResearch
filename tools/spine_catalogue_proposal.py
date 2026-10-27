"""Emit a design-only catalogue contract beside the source census, never runtime data."""
from pathlib import Path
import json


def write_proposal(report, root, out):
    def obj(properties, required=()):
        return {'type':'object','additionalProperties':False,'properties':properties,'required':list(required)}
    def arr(ref):return {'type':'array','items':{'$ref':'#/$defs/'+ref}}
    string={'type':'string'}
    strings={'type':'array','items':string}
    nullable_string={'type':['string','null']}
    vec={'type':'array','items':{'type':'number'},'minItems':3,'maxItems':3}
    evidence=obj({'source':string,'line':{'type':['integer','null'],'minimum':1},'sha256':nullable_string,'kind':{'enum':['source_declaration','existing_contract','runtime_response','placement_roundtrip','human_review']},'note':string},['source','line','sha256','kind','note'])
    binding=obj({'kind':{'enum':['recipe_setting','property','grid_config','presentation']},'key':string,'target':nullable_string,'method':nullable_string,'adapter_id':string,'update':{'enum':['compile_variant','before_ready','live','rebuild','reset_then_rebuild','presentation_only','unresolved']}},['kind','key','target','method','adapter_id','update'])
    parameter=obj({'key':string,'label':string,'type':{'enum':['number','integer','boolean','enum','color','vector3','string','reference']},'unit':nullable_string,'default':{},'domain':{'type':['object','null'],'properties':{'min':{'type':'number'},'max':{'type':'number'},'step':{'type':'number'},'options':{'type':'array'},'when':{'type':'object'}},'additionalProperties':False},'binding':{'$ref':'#/$defs/binding'},'status':{'enum':['source_candidate','contract_mapped','response_verified']},'evidence':arr('evidence')},['key','label','type','unit','default','domain','binding','status','evidence'])
    family=obj({'id':string,'version':{'type':'integer','minimum':1},'label':string,'adapter_id':string,'semantics':string,'lifecycle':strings,'acceptance':strings},['id','version','label','adapter_id','semantics','lifecycle','acceptance'])
    definition=obj({'id':string,'version':{'type':'integer','minimum':1},'label':string,'family_id':string,'legacy_tokens':strings,'term_ids':strings,'parents':strings,'route':{'enum':['reuse','custom_adapter','fixed_source']},'source':obj({'scene':nullable_string,'recipe_spec':nullable_string,'fingerprint':string,'immutable_components':strings},['scene','recipe_spec','fingerprint','immutable_components']),'preview':obj({'mode':{'enum':['shared_recipe','native','authored_presentation']},'claim':string},['mode','claim']),'parameters':arr('parameter'),'constraints':strings,'readiness':{'enum':['proposed','source_mapped','accepted']},'unresolved':strings},['id','version','label','family_id','legacy_tokens','term_ids','parents','route','source','preview','parameters','constraints','readiness','unresolved'])
    variant=obj({'id':string,'definition_id':string,'definition_version':{'type':'integer'},'parent_variant_id':nullable_string,'values':{'type':'object'},'seed':{'type':['integer','null']},'recipe_document':nullable_string,'source_fingerprint':string,'member_ids':strings,'size_context':{'enum':['hand','table','ground','floor','custom']},'context_scale_baked_into_recipe':{'type':'boolean'},'status':{'enum':['proposed','saved','accepted']}},['id','definition_id','definition_version','parent_variant_id','values','seed','recipe_document','source_fingerprint','member_ids','size_context','context_scale_baked_into_recipe','status'])
    placement=obj({'id':string,'variant_id':string,'map_id':string,'floor_snapshot':{'type':'integer'},'transform':obj({'position_m':vec,'rotation_deg':vec,'rotation_order':{'enum':['YXZ']},'scale':vec},['position_m','rotation_deg','rotation_order','scale']),'source_occurrence_id':nullable_string,'member_overrides':{'type':'object'},'staging_notes':strings,'status':{'enum':['proposed','saved','accepted']}},['id','variant_id','map_id','floor_snapshot','transform','source_occurrence_id','member_overrides','staging_notes','status'])
    schema={'$schema':'https://json-schema.org/draft/2020-12/schema','$id':'urn:ada:proposed:parameter-catalogue:1','title':'Proposed shared parameter catalogue; not installed','type':'object','additionalProperties':False,'properties':{'schema_version':{'const':1},'status':{'const':'design_only'},'families':arr('family'),'definitions':arr('definition'),'variants':arr('variant'),'placements':arr('placement')},'required':['schema_version','status','families','definitions','variants','placements'],'$defs':{'family':family,'definition':definition,'variant':variant,'placement':placement,'parameter':parameter,'binding':binding,'evidence':evidence}}
    rows={r['token']:r for r in report['artifacts']}
    hashes=report['source_files']
    def ev(source,line=None,note='',kind='source_declaration'):
        path=source.removeprefix('res://')
        return {'source':source,'line':line,'sha256':hashes.get(path),'kind':kind,'note':note}
    def definition(token,ident=None):
        row=rows[token]
        return {'id':ident or row['id'],'version':1,'label':row['label'],'family_id':row['family'],'legacy_tokens':[token],'term_ids':[],'parents':[],'route':row['proposed_route'],'source':{'scene':row['scene'],'recipe_spec':None,'fingerprint':hashes.get(row['scene'].removeprefix('res://'),'unresolved'),'immutable_components':row['fixed_components']},'preview':{'mode':'native','claim':'Native preview required. No new runtime acceptance was performed for this proposal.'},'parameters':[],'constraints':[],'readiness':'proposed','unresolved':['Confirm adapter target and lifecycle with a native response and save/reload check.']}
    # Copy legal values from the current shared spec. Never infer a range from an export default.
    spec_path=root/'commons/modular/transformation.json'
    spec=json.loads(spec_path.read_text(encoding='utf-8-sig'))
    tx=definition('spatial_recipe','recipe:transformation_arrangement')
    tx.update(label=spec['title'],family_id='modular',term_ids=sorted({s['term'] for s in spec['sources']}),parents=['term:'+s['term'] for s in spec['sources']])
    tx['source']['recipe_spec']='res://commons/modular/transformation.json'
    tx['preview']={'mode':'shared_recipe','claim':'The same compiled recipe can drive Three.js geometry and native export; this does not certify collision or walkability.'}
    for c in spec['controls']:
        domain={k:c[k] for k in ['min','max','step','options','when'] if k in c}
        tx['parameters'].append({'key':c['key'],'label':c['label'],'type':'enum' if c['type']=='enum' else 'integer' if c.get('integer') else 'number','unit':c.get('unit'),'default':spec['defaults'][c['key']],'domain':domain,'binding':{'kind':'recipe_setting','key':c['key'],'target':'compileTransformation(settings, spec)','method':None,'adapter_id':'proposed:transformation@1','update':'compile_variant'},'status':'contract_mapped','evidence':[ev('res://commons/modular/transformation.json',note='Domain copied verbatim from the current shared control spec.',kind='existing_contract'),ev(str(root.parent/'ada_encyclopedia/src/lib/transformation-lab.ts'),42,'Existing compiler entry point; proposed adapter ID does not yet exist.','existing_contract')]})
    tx['parameters'].insert(0,{'key':'source','label':'Ingredient','type':'enum','unit':None,'default':spec['defaults']['source'],'domain':{'options':[s['id'] for s in spec['sources']]},'binding':{'kind':'recipe_setting','key':'source','target':'compileTransformation(settings, spec)','method':None,'adapter_id':'proposed:transformation@1','update':'compile_variant'},'status':'contract_mapped','evidence':[ev('res://commons/modular/transformation.json',note='Each ingredient retains its catalogue/term identity.',kind='existing_contract')]})
    tx['constraints']=['Validate against the current shared spec; reject unknown keys.','Size presets compute one uniform context scale from authored bounds. Preserve CopyNN member IDs.','World scale is already baked into compiled copy positions and sizes; do not apply it again as placement scale.','Table support remains a separate authored member, not a scaled ingredient.']
    tx['unresolved']=['Descriptor migration and backward-compatible variant reader are proposed, not installed.','Representative shared-preview/native parity and placement roundtrip must be rerun after the migration.']
    screen=definition('science_screen')
    for key in ['support','surface']:
        declaration=next(e for e in rows['science_screen']['direct_exports'] if e['key']==key)
        options=declaration['enum_values']
        screen['parameters'].append({'key':key,'label':key.title(),'type':'enum','unit':None,'default':options[0],'domain':{'options':options},'binding':{'kind':'grid_config','key':key,'target':'.','method':'apply_grid_config','adapter_id':'proposed:science_screen@1','update':'unresolved'},'status':'source_candidate','evidence':[ev(declaration['source'],declaration['line'],'Enum found in source; lifecycle and visible response remain unverified here.')]})
    screen['constraints']=['Retain screen content and nearest-artifact context.','Confirm support/surface changes rebuild their intended geometry; metadata aliases are not accepted automatically.']
    logic=definition('matter_spring_and')
    declaration=next(e for e in rows['matter_spring_and']['direct_exports'] if e['key']=='reset_after_rest')
    logic['parameters']=[{'key':'reset_after_rest','label':'Reset after ball rests','type':'number','unit':'s','default':10,'domain':{'min':0,'max':60,'step':.5},'binding':{'kind':'grid_config','key':'reset_after_rest','target':'.','method':'apply_grid_config','adapter_id':'proposed:matter_logic@1','update':'live'},'status':'source_candidate','evidence':[ev(declaration['source'],declaration['line'],'Range/default declared in source; apply_grid_config forwards to rest_reset.wait_seconds at lines 264–267.')]}]
    logic['constraints']=['Never change operator midway through a ball run. Operator is an assembly identity unless a validated rebuild adapter is supplied.','Rebuild/reset preserves editable part identities, support states, receiving target and gravity paths.','Native Jolt behavior and hand controls require native acceptance; a Three.js trajectory is not equivalent physics.']
    film=definition('film_transformation_order')
    film['preview']={'mode':'authored_presentation','claim':'Preserve the authored order-of-operations lesson and timing; parameter variants should be separate studies.'}
    film['constraints']=['Allow placement and presentation controls around the film; do not silently rewrite the authored demonstration.','Follow the embedded subject definition for a parameter experiment rather than treating every lesson beat as a slider.']
    film['unresolved']=['Confirm which playback/presentation controls are actually supported before exposing them.']
    defs=[tx,screen,logic,film]
    families=[]
    for fid in dict.fromkeys(d['family_id'] for d in defs):
        fam=next(f for f in report['families'] if f['id']==fid)
        families.append({'id':fid,'version':1,'label':fam['label'],'adapter_id':'proposed:'+fid+'@1','semantics':'Work-family identifier only. Split adapter contracts by actual native driver and parameter meaning.','lifecycle':['validate','apply or compile','preview','save immutable variant','place','reload','verify'],'acceptance':['Default preserves original source','Controls visibly affect intended properties','Collision/state/reset are coherent','Variant and editable members roundtrip','Preview fidelity is explicit']})
    values=dict(spec['defaults'])
    variant={'id':'proposed:variant:transformation-default','definition_id':tx['id'],'definition_version':1,'parent_variant_id':None,'values':values,'seed':None,'recipe_document':None,'source_fingerprint':hashes.get('commons/modular/transformation.json','unresolved'),'member_ids':['Board','Support1','Support2','Support3','Support4']+['Copy'+str(i+1).zfill(2) for i in range(values['count'])],'size_context':values['sizePreset'],'context_scale_baked_into_recipe':True,'status':'proposed'}
    # Explicitly unplaced example, not a claim to alter or occupy this floor.
    placement={'id':'proposed:placement:unplaced-example','variant_id':variant['id'],'map_id':'Trans_Rotation','floor_snapshot':16,'transform':{'position_m':[0,0,0],'rotation_deg':[0,0,0],'rotation_order':'YXZ','scale':[1,1,1]},'source_occurrence_id':None,'member_overrides':{},'staging_notes':['Unplaced example only; do not write these coordinates to rooms.json.','Resolve floor-local origin and circulation envelope before placement.','Keep approach space, walk-around clearance and explicit part edits separate from source geometry.'],'status':'proposed'}
    examples={'schema_version':1,'status':'design_only','families':families,'definitions':defs,'variants':[variant],'placements':[placement]}
    for name,value in [('catalogue.schema.proposed.json',schema),('catalogue.examples.proposed.json',examples)]:
        (out/name).write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    # Schema validity is a structural check, not a claim that proposed adapters exist.
    from jsonschema import Draft202012Validator
    Draft202012Validator.check_schema(schema)
    Draft202012Validator(schema).validate(examples)
