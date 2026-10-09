from pathlib import Path
import os,json,re,shutil,tempfile,subprocess,hashlib,sys
from build_sources import HERE,ROOT,OLD,HALLS,put
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
FAULTS={
'Point_Triangle_Context':('lesson.gd','face.show_faces(points, [Vector3i(0, 1, 2)])','face.show_faces(points, [Vector3i(0, 2, 1)])','triangle/vertices_match_handles'),
'Primitives_Polythedra':('lesson.gd','Vector3i(1, 3, 2), Vector3i(2, 3, 0)','Vector3i(1, 3, 2)','polyhedra/closed_outward_tetrahedron'),
'Point_Animatedcube':('cube_body.gd','faces[0] = Vector3i(4, 6, 5)\n    faces[1] = Vector3i(4, 7, 6)','faces[0] = Vector3i(4, 7, 5)\n    faces[1] = Vector3i(5, 7, 6)','cube/diagonal_only_connectivity'),
'Primitives_Ignorance':('lesson.gd','result.append(-axis * radius)','result.append(axis * radius)','generator/opposite_0.3/0'),
'Primitives_Godot':('resolution_point.gd','if not is_picked_up():','if false:','resolution/released_pauses'),
'Primitives_Columns':('lesson.gd','height * ring / (profile.size() - 1)','height * ring / profile.size()','columns/height_and_profile_4'),
'Primitives_Profiles':('lesson.gd','Sweep.profile(FONT, "O")','Sweep.profile(FONT, "I")','profiles/open_through_centre'),
'Primitives_Portals':('lesson.gd','for i in range(record.size()):','for i in range(record.size() - 1):','limits/hexagon_closing_edge'),
'Primitives_Melencolia':('lesson.gd','cube.position = place','cube.position = Vector3.ZERO','composition/places_used')}

def main():
    work=Path(tempfile.mkdtemp(prefix='ada-primitives-lessons-'))
    shutil.copytree(ROOT/'addons/godot-xr-tools',work/'addons/godot-xr-tools')
    put(work/'project.godot','''config_version=5
[application]
config/name="'''+work.name+'''"
config/features=PackedStringArray("4.6")
[autoload]
XRToolsUserSettings="*res://addons/godot-xr-tools/user_settings/user_settings.gd"
XRToolsRumbleManager="*res://addons/godot-xr-tools/rumble/rumble_manager.gd"
[rendering]
renderer/rendering_method="gl_compatibility"
''')
    for p in (OLD/'trace').glob('*.gd'):
        (work/'trace').mkdir(exist_ok=True);shutil.copyfile(p,work/'trace'/p.name)
    shutil.copyfile(HERE/'verify.gd',work/'verify.gd')
    pins={}
    for hall in HALLS:
        lesson=ROOT/'commons/maps'/hall/'tutorial.md'
        pins[lesson.relative_to(ROOT).as_posix()]=sha(lesson)
        text=lesson.read_text(encoding='utf-8')
        for source in (HERE/hall).glob('*.gd'):
            blocks=re.findall(r'<!-- student-code:'+re.escape(source.name)+r' -->\s*```gdscript\n(.*?)^```',text,re.M|re.S)
            assert len(blocks)==1 and blocks[0]==source.read_text(),(hall,source.name,'printed source differs')
            pins[source.relative_to(ROOT).as_posix()]=sha(source)
        for part in [hall,'fault-'+hall]:
            (work/part).mkdir()
            for p in (HERE/hall).iterdir():
                if p.suffix in ['.gd','.ttf','.txt']:shutil.copyfile(p,work/part/p.name)
        name,before,after,expected=FAULTS[hall]
        p=work/('fault-'+hall)/name
        s=p.read_text();assert s.count(before)==1,(hall,before);put(p,s.replace(before,after))
    put(HERE/'test-project.txt',str(work)+'\n')
    for variant,line in [('rings_only','sphere.radial_segments = maxi(4, sphere.radial_segments - 1)'),('segments_only','sphere.rings = maxi(1, sphere.rings - 1)')]:
        dest=work/'variants'/variant;dest.mkdir(parents=True)
        for name in ['point_body.gd','resolution_point.gd']:
            text=(HERE/'Primitives_Godot'/name).read_text()
            if name=='resolution_point.gd':text=text.replace(line,'pass # Keep this construction parameter fixed.')
            put(dest/name,text)
            put(HERE/'practice-variants'/variant/name,text)
    shared=work/'shared-Primitives_Godot'
    shutil.copytree(work/'Primitives_Godot',shared)
    p=shared/'lesson.gd';s=p.read_text().replace('add_child(comparison)','add_child(comparison)\n    comparison.sphere = point.sphere\n    comparison.get_child(0).mesh = point.sphere');put(p,s)
    common=[ENGINE,'--headless','--path',str(work),'--xr-mode','off','--audio-driver','Dummy']
    def run(label,args,expected):
        r=subprocess.run(common+args,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8',errors='replace',timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
        put(HERE/'logs'/(label+'.log'),r.stdout)
        print(label,r.returncode,'expected',expected,flush=True)
        if r.returncode!=expected or 'SCRIPT ERROR:' in r.stdout or 'ERROR:' in r.stdout:
            print(r.stdout[-6500:]);raise RuntimeError(label+' failed: '+str(work))
        return r
    run('import',['--editor','--import','--quit'],0)
    results=[]
    for hall in HALLS:
        for fault in [False,True]:
            part=('fault-' if fault else '')+hall
            run(part,['--script','res://verify.gd','--',hall,part,str(work/(part+'.json'))],1 if fault else 0)
        result=json.loads((work/(hall+'.json')).read_text())
        negative=json.loads((work/('fault-'+hall+'.json')).read_text())
        assert FAULTS[hall][3] in negative['failure_ids'],(hall,negative)
        result.update({'negative_control':{'mutation':{'file':FAULTS[hall][0],'before':FAULTS[hall][1],'after':FAULTS[hall][2]},'required_failure':FAULTS[hall][3],'result':negative},'inputs':{p:h for p,h in pins.items() if '/'+hall+'/' in p},'engine':'Godot 4.6 stable','scope':'Exact printed programs in native Godot; synthetic recorded movement and real XR Tools library. Variants and deliberate faults. No headset or human-learning claim.'})
        put(HERE/hall/'report-runtime.json',json.dumps(result,indent=2)+'\n')
        results.append(result)
        if hall=='Primitives_Godot':
            run('shared-Primitives_Godot',['--script','res://verify.gd','--',hall,'shared-Primitives_Godot',str(work/'shared.json')],1)
            ownership=json.loads((work/'shared.json').read_text())
            assert 'resolution/neighbour_independent' in ownership['failure_ids']
            result['resource_sharing_fault']=ownership
            put(HERE/hall/'report-runtime.json',json.dumps(result,indent=2)+'\n')
    assert all(sha(ROOT/p)==h for p,h in pins.items())
    deps={p.relative_to(ROOT).as_posix():sha(p) for p in (ROOT/'addons/godot-xr-tools').rglob('*') if p.is_file() and p.suffix in ['.gd','.tscn','.tres']}
    put(HERE/'verification.json',json.dumps({'passed':True,'halls':[{ 'hall':r['hall'],'assertions':len(r['checks']),'fault_rejected':True} for r in results],'inputs':pins,'dependencies':deps,'verifier_sha256':sha(HERE/'verify.gd'),'runner_sha256':sha(HERE/'run_checks.py'),'project':str(work)},indent=2)+'\n')
    print('PASSED',sum(len(r['checks']) for r in results),'native assertions;',len(results)+1,'fault controls',flush=True)

if __name__=='__main__':main()
