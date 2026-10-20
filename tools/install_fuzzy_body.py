"""Add the fuzzy sphere to the existing museum gallery, preserving other work."""
from pathlib import Path
import json, shutil
from em_map_halls import derive_row
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-two-rooms-one-body'
MAP='Shader_05_Patterns'
TOKEN='fuzzy_body:180:0#plinth:0#pin:1'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def backup(p):
    target=O/'before'/p.relative_to(R)
    if not target.exists():target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,target)
def write(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def main():
    p=R/f'commons/maps/{MAP}/map_data.json';backup(p);data=read(p)
    assert data['layers']['interactables'][40][8] in ['',TOKEN]
    data['layers']['interactables'][40][8]=TOKEN
    data['map_info']['metadata']['n_artifacts']=sum(bool(c.strip()) for row in data['layers']['interactables'] for c in row)
    data['map_info']['museum']['fuzzy_body']={'cell':[8,40],'rotation':180,'footprint':[5,36,12,45],'note':'Hand point moves the sample centre of a retained sphere. Independent fuzzy memberships, weighted deformation rules, centroid threshold selection. Native controls; floor and routes unchanged.'}
    write(p,data)
    p=R/'commons/artifacts/registry/fuzzy_body.json'
    entry={'lookup_name':'fuzzy_body','name':'Two rooms claim one body','scene':'res://commons/artifacts/fuzzy_body/fuzzy_body.tscn','preview_scene':'res://commons/artifacts/fuzzy_body/museum.tscn','description':'Move the black hand point. Inspect overlapping memberships on a sphere, blend lift/fold/twist rules, then select faces by an adjustable threshold. Original positions retained. Native Godot installation in the rear gallery of Shaders / Patterns.','category':'transforms','dev_category':'research','dev_themes':['fuzzy sets','rules','threshold','geometry'],'tags':['fuzzy','sphere','glitch','membership','hands'],'complexity':'intermediate','map_ready':True,'include_in_map_data':True,'map_sequences':['shaders'],'interactions':['Grab the black point and move left/right. Desktop can also use LEFT / CENTRE / RIGHT.','FIELDS shows degrees, RULES blends three transformations, CUT selects triangle centres by min(left,right).','Turn WIDTH, STRENGTH, THRESHOLD on the native console.'],'qfep_connection':'Making degrees of membership visible exposes the authored field, aggregation rule and threshold. A softened boundary still depends on decisions; no claim that mathematical membership models social identity.','status':'Installed in Shader_05_Patterns alongside model_disagreement','report':'doc/book/iterations/2026-10-09-two-rooms-one-body/index.html'}
    write(p,{'id':'fuzzy_body','name':entry['name'],'artifacts':{'fuzzy_body':entry}})
    p=R/'commons/data/museum/em_plan.json';backup(p);data=read(p)
    rows=[(i,r) for i,r in enumerate(data['plans']) if r.get('map')==MAP and r.get('sequence')=='shaders'];assert len(rows)==1
    i,r=rows[0];data['plans'][i]=derive_row(r['pearl'],MAP,r['museum'],r['pearl_index'],r['pearls_total'],'shaders')
    p.write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8')
    print('Installed fuzzy_body at [8,40]; previous six artifacts and routes retained.')
if __name__=='__main__':main()
