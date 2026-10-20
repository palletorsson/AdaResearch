"""Bake two walkable cellular studies and derive their museum plan from the maps.

Requires numpy, scipy and scikit-image. No existing spine maps are rewritten.
"""
from pathlib import Path
import json
import numpy as np
from scipy.spatial import HalfspaceIntersection
from skimage.measure import marching_cubes
from em_map_halls import derive_row

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'commons/artifacts/cellular_spaces'
SEED = 731

def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, separators=(',', ':'))+'\n', encoding='utf-8')

def smooth_min(a, b, k):
    h = np.clip(0.5+0.5*(b-a)/k, 0, 1)
    return b*(1-h)+a*h-k*h*(1-h)

def womb():
    step = .14
    axes = [np.arange(-6.8, 6.801, step), np.arange(0, 6.441, step), np.arange(-8.4, 8.401, step)]
    p = np.stack(np.meshgrid(*axes, indexing='ij'), axis=-1)
    def ellipsoid(center, radii):
        return (np.linalg.norm((p-center)/radii, axis=-1)-1)*min(radii)
    field = ellipsoid(np.array([0,1.8,0]), np.array([5.2,3.9,6.3]))
    for center, radii in [([-2.7,2.3,.5],[3.0,3.0,3.9]), ([2.6,2.1,1.5],[3.2,3.3,3.8])]:
        field = smooth_min(field, ellipsoid(np.array(center),np.array(radii)), .75)
    # 3D feature-point distances gently mould the enclosing geometry.
    rng = np.random.default_rng(SEED)
    nearest = np.full(field.shape, 100.0)
    for x in range(-2,3):
        for y in range(0,3):
            for z in range(-3,4):
                site = (np.array([x,y,z])+rng.uniform(-.3,.3,3))*3.0
                nearest = np.minimum(nearest,np.linalg.norm(p-site,axis=-1))
    field -= .12*(nearest-1.4)
    # Two genuinely open, rounded entrance throats meet the flat museum floor.
    tunnel = np.sqrt(p[...,0]**2+(p[...,1]-1.25)**2)-1.72
    field = smooth_min(field,tunnel,.4)
    verts,faces,normals,_ = marching_cubes(field.astype(np.float32),0,spacing=(step,step,step))
    verts += np.array([axes[0][0],0,axes[2][0]])
    data={'variant':'womb','seed':SEED,'vertices':np.round(verts,5).tolist(),
          'normals':np.round(-normals,5).tolist(),'indices':faces[:,::-1].reshape(-1).tolist(),
          'floor_size':[13.6,16.8], 'entry':[0,0,-8.4],'exit':[0,0,8.4],
          'centres':[[0,1.8,0],[-2.7,2.3,.5],[2.6,2.1,1.5]],
          'routes':[[[0,0,-9],[0,0,-6],[0,0,-3],[0,0,0],[0,0,3],[0,0,6],[0,0,9]],
                    [[0,0,0],[-2,0,.5],[-3.5,0,.5]],[[0,0,0],[2,0,1.5],[3.5,0,1.5]]],
          'recipe':'Smooth union of three ellipsoidal cavities, perturbed by a 3D nearest-feature distance; two through-throats; sampled at 0.14 m.'}
    write(OUT/'womb_mesh.json',data)
    print('womb',len(verts),'vertices',len(faces),'triangles')

def clip(poly, function, inside=True):
    result=[]
    if not len(poly):return result
    for a,b in zip(poly,poly[1:]+poly[:1]):
        da,db=function(a),function(b)
        if not inside: da,db=-da,-db
        if da<=1e-7: result.append(a)
        if (da<-1e-7 and db>1e-7) or (db<-1e-7 and da>1e-7):
            result.append(a+(b-a)*da/(da-db))
    return result

def cut_arch(poly, origin, across, radius=.95, spring=1.6):
    # Subtract a convex arch opening by successively keeping its outside pieces.
    outline=[[-radius,-2],[radius,-2]]+[[radius*np.cos(t),spring+radius*np.sin(t)] for t in np.linspace(0,np.pi,17)]
    remainder=poly
    pieces=[]
    for a,b in zip(outline,outline[1:]+outline[:1]):
        d=np.array(b)-a
        def f(p,a=a,d=d):
            q=np.array([np.dot(p-origin,across),p[1]])
            return d[1]*(q[0]-a[0])-d[0]*(q[1]-a[1])
        outside=clip(remainder,f,False)
        if len(outside)>=3:pieces.append(outside)
        remainder=clip(remainder,f,True)
        if len(remainder)<3:break
    return pieces

def cells():
    rng=np.random.default_rng(SEED)
    sites=np.array([[x+rng.uniform(-.32,.32),2.1+rng.uniform(-.35,.35),z+rng.uniform(-.32,.32)]
                    for z in [-5.4,-1.8,1.8,5.4] for x in [-5.4,-1.8,1.8,5.4]]+
                   [[-4,7.8,-4],[4,7.3,-4],[-4,7.2,4],[4,8,4]])
    central={5,6,9,10}
    bounds=[([1,0,0],-7.5,'east'),([-1,0,0],-7.5,'west'),([0,1,0],-6.2,'roof'),
            ([0,-1,0],0,'floor'),([0,0,1],-7.5,'exit'),([0,0,-1],-7.5,'entry')]
    vertices=[];normals=[];indices=[];doors=[];removed=[];walls=[];seams=[]
    def triangle(a,b,c,n):
        if np.linalg.norm(np.cross(b-a,c-a))<1e-8:return
        # Godot uses clockwise front faces. The two sides must have opposite
        # winding, including in shadow passes that do not use our shader normals.
        if np.dot(np.cross(b-a,c-a),n)>0: b,c=c,b
        start=len(vertices)
        vertices.extend([a.tolist(),b.tolist(),c.tolist()]);normals.extend([n.tolist()]*3);indices.extend([start,start+1,start+2])
    def plate(poly,n):
        # A 12 cm solid membrane with a visible reveal around every opening.
        for sign in [-1,1]:
            q=[p+n*.06*sign for p in poly]
            for j in range(1,len(q)-1): triangle(q[0],q[j],q[j+1],n*sign)
        for a,b in zip(poly,poly[1:]+poly[:1]):
            normal=np.cross(b-a,n);normal/=max(np.linalg.norm(normal),1e-9)
            triangle(a-n*.06,b-n*.06,b+n*.06,normal)
            triangle(a-n*.06,b+n*.06,a+n*.06,normal)
    for i,site in enumerate(sites[:16]):
        planes=[];tags=[]
        for j,other in enumerate(sites):
            if i==j:continue
            n=other-site;n/=np.linalg.norm(n)
            planes.append([*n,-np.dot(n,(site+other)*.5)]);tags.append(j)
        for n,d,tag in bounds:planes.append([*n,d]);tags.append(tag)
        hs=np.array(planes)
        points=HalfspaceIntersection(hs,site).intersections
        for plane,tag in zip(hs,tags):
            if tag=='floor' or (isinstance(tag,int) and tag<i):continue
            ids=np.where(np.abs(points@plane[:3]+plane[3])<1e-5)[0]
            if len(ids)<3:continue
            n=plane[:3];face=points[ids];mid=face.mean(axis=0)
            u=np.cross(n,[0,1,0])
            if np.linalg.norm(u)<.001:u=np.cross(n,[1,0,0])
            u/=np.linalg.norm(u);v=np.cross(n,u)
            angle=np.arctan2((face-mid)@v,(face-mid)@u)
            poly=list(face[np.argsort(angle)])
            if i in central and tag in central:
                removed.append({'cells':[i,int(tag)],'polygon':np.round(poly,5).tolist()})
                continue
            floor_points=[p for p in poly if abs(p[1])<1e-5]
            opening=None
            if len(floor_points)>=2 and np.linalg.norm(floor_points[0]-floor_points[-1])>2.3:
                origin=(floor_points[0]+floor_points[-1])*.5
                if isinstance(tag,int) and tag<16:opening=origin
                elif tag in ['entry','exit']:
                    desired=-1.8 if tag=='entry' else 1.8
                    lo,hi=sorted([floor_points[0][0],floor_points[-1][0]])
                    if lo+1.05<desired<hi-1.05:
                        opening=np.array([desired,0, -7.5 if tag=='entry' else 7.5])
            pieces=[poly]
            if opening is not None:
                pieces=cut_arch(poly,opening,u)
                doors.append({'cells':[i,tag],'position':np.round(opening,5).tolist(),'normal':n.tolist(),'width':1.9,'height':2.55})
            for part in pieces:plate(part,n)
            for a,b in zip(poly,poly[1:]+poly[:1]):seams.append([a.tolist(),b.tolist()])
            walls.append({'cells':[i,tag],'center':mid.tolist(),'door':opening is not None})
    centres=sites[:16].copy();centres[:,1]=0
    routes=[]
    for door in doors:
        i,j=door['cells'];p=np.array(door['position']);n=np.array(door['normal']);n[1]=0;n/=np.linalg.norm(n)
        if isinstance(j,int):routes.append([centres[i].tolist(),(p-n*.45).tolist(),(p+n*.45).tolist(),centres[j].tolist()])
        else:routes.append([(p+n*1.4).tolist(),(p-n*.6).tolist(),centres[i].tolist()])
    for face in removed:
        i,j=face['cells'];routes.append([centres[i].tolist(),centres[j].tolist()])
    data={'variant':'commons','seed':SEED,'vertices':np.round(vertices,5).tolist(),'normals':np.round(normals,5).tolist(),
          'indices':indices,'floor_size':[15,15],'entry':[-1.8,0,-7.5],'exit':[1.8,0,7.5],
          'sites':np.round(sites,5).tolist(),'centres':np.round(centres,5).tolist(),'doors':doors,'removed':removed,
          'walls':walls,'seams':seams,'routes':routes,
          'recipe':'3D Euclidean Voronoi cells clipped to a room; four central floor cells joined by omitting their shared walls. Arched openings cut in other traversable shared faces.'}
    assert any(d['cells'][1]=='entry' for d in doors)
    assert any(d['cells'][1]=='exit' for d in doors)
    edges={i:set() for i in range(16)}
    for d in doors+removed:
        a,b=d['cells']
        if isinstance(b,int):edges[a].add(b);edges[b].add(a)
    reached={0}
    for _ in range(16):reached|={b for a in list(reached) for b in edges[a]}
    assert len(reached)==16,'Every floor cell must be reachable'
    write(OUT/'commons_mesh.json',data)
    print('commons',len(indices)//3,'triangles;',len(doors),'doors;',len(removed),'removed central walls; 16 reachable cells')

def maps():
    rows=[]
    for idx,(map_id,variant,title) in enumerate([('Noise_Cellular_Womb','womb','Cellular enclosure'),('Noise_Cellular_Commons','commons','A common interior')]):
        w,d=21,25
        layers={k:[[' ']*w for _ in range(d)] for k in ['structure','utilities','interactables']}
        layers['structure']=[['w' if x in [0,w-1] or z in [0,d-1] else '1' for x in range(w)] for z in range(d)]
        for z in [0,d-1]:
            for x in [9,10,11]:layers['structure'][z][x]='1'
        layers['utilities'][1][10]='s'
        layers['utilities'][23][10]='t'
        layers['interactables'][12][10]='cellular_space#form:'+variant+'#plinth:0#pin:true'
        info={'name':title,'title':title,'lookup_name':map_id,'description':'Walk inside cellular geometry. '+('A curved enclosing cavity with two open throats.' if variant=='womb' else 'Sixteen floor cells; four share one central space; arched passages join the rest.'),
              'dimensions':{'width':w,'depth':d,'max_height':7},'metadata':{'category':'noise','difficulty':'intermediate'},
              'museum':{'wall_height':3,'artifact_placement':'map','gate_depth_rows':0,'open_roof':True,'piers':False,'gate':False,'sculpture_clear_rects':[[1,2,19,22]]}}
        write(ROOT/f'commons/maps/{map_id}/map_data.json',{'map_info':info,'settings':{'cube_size':1,'gutter':0,'enable_physics':True},'layers':layers})
        rows.append(derive_row(title.lower(),map_id,'kanazawa-room-matrix',idx,2,'noise'))
    write(OUT/'museum_plan.json',{'schema':'adaresearch.em_plan.v2','plans':rows,'museums':{'kanazawa-room-matrix':rows[0]},'_readme':'Two optional cellular space studies, using the actual museum shell. Derived from the maps; the main spine is unchanged.'})
    write(ROOT/'commons/maps/sequences/cellular_spaces.json',{'sequences':{'cellular_spaces':{'name':'Cellular Spaces','description':'Two walkable studies of cellular enclosure and shared space.','maps':['Noise_Cellular_Womb','Noise_Cellular_Commons'],'prerequisites':['noise'],'return_to':'lab'}}})

if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True)
    womb();cells();maps()
