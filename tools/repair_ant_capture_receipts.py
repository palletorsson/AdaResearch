"""Recover JSON framing after a stale handle overwrote two receipts' prefix.
No timeline measurement is reconstructed: every entry survives verbatim.
The original malformed files are retained as evidence.
"""
from pathlib import Path
import json, shutil
R=Path(__file__).resolve().parents[1]/'doc/book/iterations/2026-10-11-ants-time-and-scale'
repairs=[]
for token in ['langton_swarm','stigmergy_grid']:
    p=R/'long-run'/f'{token}.json'
    text=p.read_text(encoding='utf-8')
    initial,end=json.JSONDecoder().raw_decode(text)
    if not text[end:].strip():continue
    tail=text[end:]
    assert tail.startswith('"image": ')
    recovered=json.loads('{"timeline":[{'+tail)
    assert [f['seconds'] for f in recovered['timeline']]==[5,30,90]
    log=(R/'evidence'/f'long-{token}.log').read_text(encoding='utf-8')
    for entry in recovered['timeline']:
        assert entry['image']==f'{token}-{entry["seconds"]}.png'
        assert (p.parent/entry['image']).exists() and entry['saved']
        for value in entry['state'].values():
            if isinstance(value,dict) and 'digest' in value:assert value['digest'] in log
    shutil.copy2(p,R/'evidence'/f'{token}-receipt-before-repair.txt')
    initial.update(recovered)
    p.write_text(json.dumps(initial,indent=2)+'\n',encoding='utf-8')
    repairs.append({'file':str(p),'repair':'Restored missing timeline opening around surviving verbatim entries. Stale first FileAccess handle had overwritten final JSON prefix; handle now closes before final write. Original malformed receipt retained; state digests verified against original log.'})
if repairs:(R/'evidence/receipt-repairs.json').write_text(json.dumps(repairs,indent=2)+'\n',encoding='utf-8')
print('Recovered',len(repairs),'receipt envelopes without changing any measured values.')
