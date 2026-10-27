"""Record accepted transfers as awaiting curation, using the review API revision."""
import json
from pathlib import Path
import sys
import urllib.request

ROOT=Path(__file__).resolve().parents[1]
URL='http://localhost:3003/api/void-trials'
batch=next((arg.split('=',1)[1] for arg in sys.argv[1:] if arg.startswith('--batch=')),'02')
assert batch in ('01','02','03','04','05','06','07')
review='doc/book/iterations/2026-10-21-void-transfer-batch'+('' if batch=='01' else '-'+batch)+'/index.html#'
for seq in (arg for arg in sys.argv[1:] if not arg.startswith('--batch=')):
    assert seq.isidentifier()
    folder=ROOT/'commons/void/trials'/seq
    status=json.loads((folder/'transfer-status.json').read_text(encoding='utf-8-sig'))
    inventory=json.loads((folder/'source-inventory.json').read_text(encoding='utf-8-sig'))
    counts={}
    for name in ['source-checks','checks','editor-checks']:
        report=json.loads((folder/f'evidence/{name}.json').read_text(encoding='utf-8-sig'))
        assert report['passed'], (seq,name)
        counts[name]=len(report['checks'])
    snapshot=json.load(urllib.request.urlopen(URL))
    row=next(t for t in snapshot['trials'] if t['sequence']==seq)
    payload=dict(sequence=seq,revision=snapshot['revision'],fingerprint=row['fingerprint'],stage='needs-work',
        observation=f"Transfer accepted: {len(inventory['placements'])} original placements across {', '.join(inventory['maps'])}. Native desktop and synthetic XR acceptance plus named focused checks pass. Consult the handoff for untested controls and fit exceptions; physical headset and curation remain pending.",
        capacity='Individually editable original scene snapshots, shared native/VR layout, copy/move/turn, revision-safe autosave and Desktop backup. '+ ' '.join(status.get('adaptations',[])),
        next='Curate the encounter order, circulation, light and fit before integration with the main tower. Resolve dependencies recorded in HANDOFF.md, then physical headset review. Wait with chapter texts.',
        evidence=review+seq+'; '+json.dumps(counts))
    req=urllib.request.Request(URL,data=json.dumps(payload).encode(),headers={'Content-Type':'application/json','Origin':'http://localhost:3003'},method='POST')
    receipt=json.load(urllib.request.urlopen(req))
    print(seq, 'review recorded', receipt.get('saved',receipt.get('revision','')))
