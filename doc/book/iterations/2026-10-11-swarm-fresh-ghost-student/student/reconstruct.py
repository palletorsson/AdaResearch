"""Reconstruct only fenced, named student code from the seven supplied tutorials."""
from pathlib import Path
import re, hashlib, json, datetime
root = Path(__file__).resolve().parent
source = root.parent / 'input'
halls = ['SwarmIntelligence_PhysarumColony', 'SwarmIntelligence_FlowFields', 'SwarmIntelligence_Boids_Algorithm', 'SwarmIntelligence_Agent_Based_Modeling_ABM', 'SwarmIntelligence_Ant_Colony_Optimization', 'SwarmIntelligence_Particle_Swarm_Optimization', 'SwarmIntelligence_Swarm_Intelligence_Algorithms']
shorts = ['physarum','flow','boids','abm','ant','pso','population']
sha = lambda b: hashlib.sha256(b).hexdigest()
manifest = {'created_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'method':'Only named student-code fences; normalize CRLF to LF, retain fenced text and one terminal newline. Minimal scenes independently authored.','inputs':{},'outputs':{}}
for i,(hall,short) in enumerate(zip(halls,shorts),1):
    for name in ['tutorial.md','final.md']:
        p=source/'halls'/hall/name
        manifest['inputs'][str(p.relative_to(source))]=sha(p.read_bytes())
    image=source/'images'/f'{i}.png'
    manifest['inputs'][str(image.relative_to(source))]=sha(image.read_bytes())
    tutorial=(source/'halls'/hall/'tutorial.md').read_text(encoding='utf-8')
    folder=root/'reconstructed'/short
    folder.mkdir(parents=True,exist_ok=True)
    matches=re.findall(r'<!-- student-code:([^ >]+) -->\s*```gdscript\n(.*?)\n```',tutorial,re.S)
    assert len(matches)==(4 if short=='population' else 3), (short,len(matches))
    for name,code in matches:
        p=folder/name
        payload=(code+'\n').encode('utf-8')
        p.write_bytes(payload)
        manifest['outputs'][str(p.relative_to(root))]={'sha256':sha(payload),'source':f'halls/{hall}/tutorial.md','marker':name,'derivation':'exact fence'}
    scene='[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="study.gd" id="1"]\n\n[node name="FreshStudy" type="Node3D"]\nscript = ExtResource("1")\n'
    p=folder/'study.tscn'; p.write_bytes(scene.encode())
    manifest['outputs'][str(p.relative_to(root))]={'sha256':sha(p.read_bytes()),'derivation':'student authored minimal Node3D host attachment'}
manifest['inputs']['START.md']=sha((source/'START.md').read_bytes())
(root/'provenance.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print(f"Reconstructed {len(manifest['outputs'])} files; no prebuilt lesson source read.")
