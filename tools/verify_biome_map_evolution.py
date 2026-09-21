"""Verify native, map-driven states against the live-identity progression probe."""
from pathlib import Path
import hashlib, json

root=Path(__file__).resolve().parents[1]
out=root/'ada_run/biome_inheritance/evolution'
probe=json.loads((out/'probe.json').read_text(encoding='utf-8'))
capture=json.loads((out/'capture.json').read_text(encoding='utf-8'))
review=json.loads((root/'commons/artifacts/biome_inheritance/evolution-review.json').read_text(encoding='utf-8'))
assert probe['failures']==0
assert [r['map'] for r in review['stages']]==[s['evolution']['stage'] for s in capture['states']]
assert len(probe['states'])==len(capture['states'])==9
for expected,actual in zip(probe['states'],capture['states']):
    for key in ['banners','evolution','accepted_ids','excluded_cover']:
        assert expected[key]==actual[key],(actual['evolution']['stage'],key)
    assert expected['habitat']['dna']==actual['habitat']['dna']
    assert (out/(actual['evolution']['stage']+'.png')).is_file()
files=['commons/artifacts/biome_inheritance/biome_inheritance.gd',
       'commons/artifacts/biome_inheritance/rising_banners.gd',
       'commons/artifacts/biome_inheritance/banner_pattern.gdshader',
       'commons/testing/probe_biome_map_evolution.gd','commons/testing/capture_biome_map_evolution.gd']
result={'date':'2026-09-19','checks':probe['checks'],'failures':0,'native_states_match_probe':True,
        'maps':[r['map'] for r in review['stages']],
        'driver':'Explicit hall entry; no automatic evolution within a hall',
        'limits':['Prototype not yet distributed across museum maps','No cross-session save for live specimen',
                  'Existing habitat stage rules reused','No cloth, growth feedback or headset validation'],
        'source_hashes':{p:hashlib.sha256((root/p).read_bytes()).hexdigest() for p in files}}
(out/'verification.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k!='source_hashes'},indent=2))
