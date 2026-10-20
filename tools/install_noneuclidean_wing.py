"""Install one entry in the existing NonEuclidean_Spaces map; preserve other exhibits."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
registry = ROOT / 'commons/artifacts/registry/alternative_geometries.json'
data = json.loads(registry.read_text(encoding='utf-8'))
data['artifacts']['noneuclidean_wing'] = {
    'lookup_name': 'noneuclidean_wing',
    'name': 'Seven Spaces — the Non-Euclidean Wing',
    'scene': 'res://commons/artifacts/noneuclidean_wing/noneuclidean_wing.tscn',
    'category': 'geometry', 'complexity': 'advanced', 'map_ready': True,
    'include_in_map_data': True, 'footprint': [2.5,3.8,2.5], 'size_group': 'large',
    'description': 'An installed walk-through portal to seven full-scale chambers. One carried PointBody links topology, spherical transport, H2, H2 x R, H3 and metric aiming.',
    'interactions': ['walk through the door', 'carry the point', 'move the held point to change the experiment', 'hold trigger to navigate metric architecture', 'launch along a geodesic', 'nearby next, previous and museum controls'],
    'capacity': 'Distinguish changed connections, curved surfaces and curved three-dimensional space by walking, carrying and measuring.',
    'spatial_needs': {'placement_type':'floor','min_clearance':0.5},
    'map_sequences':['foundationscrisis'],
}
registry.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
path=ROOT/'commons/maps/NonEuclidean_Spaces/map_data.json'
data=json.loads(path.read_text(encoding='utf-8'))
grid=data['layers']['interactables']
assert grid[4][13].strip() in ('','noneuclidean_wing:0:0#pin:true#plinth:0')
grid[4][13]='noneuclidean_wing:0:0#pin:true#plinth:0'
data['map_info']['description']='Carry the same black point through seven full-size chambers: portal connectivity, a periodic corridor, spherical parallel transport, hyperbolic triangle models, H2 x R galleries, H3 architecture and geodesic target practice. Physical support and metric rendering are explicitly distinguished.'
data['map_info']['metadata']['n_artifacts']=sum(bool(x.strip()) for row in grid for x in row)
data['map_info']['metadata']['estimated_time']='20-35 minutes including the seven-space wing'
data['map_info']['metadata']['learning_objectives']=[
    'Distinguish portal connectivity from intrinsic curvature',
    'Compare planar, spherical and hyperbolic triangle measurements',
    'Transport a direction around a spherical triangle',
    'Navigate finite first-person H2 x R and H3 architecture',
    'Aim and test hits with the hyperbolic metric',
]
data['documentation']={
    'key_elements':['Existing curvature triangle workbench retained','Seven-space wing: entry at hall-local (13,1,7)','One carried black point and nearby navigation controls','Poincare/Klein models and first-person hyperboloid projection','Physical floor and curved metric renderer explicitly separated'],
    'layout':'The existing hall remains. A narrow portal opens into seven full-scale chambers, with return controls in each. Remote rooms are owned by this artifact and unload with the hall.',
    'spatial_pattern':'museum_with_portal_wing',
    'summary':'Changed connections; curved surfaces; curved three-dimensional views. A concave bowl alone is not evidence of negative curvature.',
}
path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Installed seven-space wing entry; existing artifacts retained.')
