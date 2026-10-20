"""Place a body-responsive threshold behind the sphere in the same live gallery."""
from pathlib import Path
import json,shutil
from em_map_halls import derive_row
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-a-doorway-reads-your-approach'
MAP='Shader_05_Patterns';TOKEN='fuzzy_doorway:180:0#plinth:0#pin:1'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,d,compact=False):p.write_text(json.dumps(d,ensure_ascii=False,**({'separators':(',',':')} if compact else {'indent':2}))+'\n',encoding='utf-8')
def backup(p):
    q=O/'before'/p.relative_to(R)
    if not q.exists():q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,q)
def main():
    p=R/f'commons/maps/{MAP}/map_data.json';backup(p);d=read(p)
    assert d['layers']['interactables'][53][8] in ['',TOKEN]
    d['layers']['interactables'][53][8]=TOKEN
    d['map_info']['metadata']['n_artifacts']=sum(bool(c.strip()) for row in d['layers']['interactables'] for c in row)
    d['map_info']['museum']['fuzzy_doorway']={'cell':[8,53],'rotation':180,'footprint':[3,49,14,57],'note':'Fourteen ribs respond to actual visitor distance and approach speed. Walkable central lane, nearby reach/pace dials and explicitly labelled demonstration inputs.'}
    write(p,d)
    entry={'lookup_name':'fuzzy_doorway','name':'A doorway reads your approach','scene':'res://commons/artifacts/fuzzy_doorway/fuzzy_doorway.tscn','preview_scene':'res://commons/artifacts/fuzzy_doorway/museum.tscn','description':'Walk slowly or quickly toward a fourteen-rib arch. Fuzzy near/slow/fast rules open, curl or rest its geometry. Live museum body/XR-head input; visible rule weights, native reach/pace controls and separately labelled demonstrations.','category':'transforms','dev_category':'research','dev_themes':['fuzzy rules','embodied input','architecture'],'tags':['fuzzy','doorway','approach','speed'],'complexity':'intermediate','map_ready':True,'include_in_map_data':True,'map_sequences':['shaders'],'interactions':['Walk toward and through the opening; retreat and return.','Turn REACH and PACE to change the definitions of near and fast.','LIVE reads the visitor; DEMO SLOW/FAST supplies declared distance/speed; RESET restores defaults.','SWAP RULES reverses which approach opens the ribs; the displayed rule labels change with it.'],'qfep_connection':'A responsive doorway classifies an approach according to authored distances and paces. Graded rules make its terms adjustable; they do not infer the visitor\'s intent or identity.','status':'Installed after fuzzy_body in rear Shader_05_Patterns gallery','report':'doc/book/iterations/2026-10-09-a-doorway-reads-your-approach/index.html'}
    write(R/'commons/artifacts/registry/fuzzy_doorway.json',{'id':'fuzzy_doorway','name':entry['name'],'artifacts':{'fuzzy_doorway':entry}})
    p=R/'commons/data/museum/em_plan.json';backup(p);d=read(p)
    rows=[(i,r) for i,r in enumerate(d['plans']) if r.get('map')==MAP and r.get('sequence')=='shaders'];assert len(rows)==1
    i,r=rows[0];d['plans'][i]=derive_row(r['pearl'],MAP,r['museum'],r['pearl_index'],r['pearls_total'],'shaders');write(p,d,True)
    print('Installed at [8,53]; seven prior artifacts and existing passages retained.')
if __name__=='__main__':main()
