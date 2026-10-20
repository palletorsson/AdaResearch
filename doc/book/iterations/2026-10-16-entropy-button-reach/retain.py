"""Keep native evidence and exact source hashes for the button audit."""
from pathlib import Path
import hashlib
import json
import shutil

here = Path(__file__).resolve().parent
root = here.parents[3]
record = {'scope': 'Supplied physics contacts and pointer dispatch; no headset or discoverability result', 'runs': {}, 'sources': {}, 'finals_unchanged': {}}
for label, name in [('types', 'Random_Entropies'), ('workshop', 'Random_Entropy')]:
    run = root / 'ada_run/encounter_pilot' / name / 'entropy-button-reach'
    report = json.loads((run / 'report.json').read_text(encoding='utf-8'))
    assert report['passed'] and not report['failures'], name
    target = here / label
    target.mkdir(exist_ok=True)
    for source in list(run.glob('*.png')) + [run / 'report.json', run / 'source_manifest.json']:
        shutil.copy2(source, target / source.name)
    record['runs'][label] = {'checks': len(report['checks']), 'report': f'{label}/report.json'}
    current = root / 'commons/maps' / name / 'final.md'
    previous = here.parent / '2026-10-16-entropy-transition-check/baseline' / name / 'final.md'
    record['finals_unchanged'][name] = current.read_text(encoding='utf-8') == previous.read_text(encoding='utf-8')
    assert record['finals_unchanged'][name], name
paths = ['commons/artifacts/ordinary_entropies/' + n for n in ['study_controls.gd', 'door_study.gd', 'guess_table.gd']]
paths += ['commons/artifacts/entropy_compartments/entropy_compartments.gd', 'commons/interactables/push_button.tscn', 'commons/interactables/push_button.gd', 'commons/interactables/interactable_area_button_pointer.gd']
for relative in paths:
    source = root / relative
    dest = here / 'sources' / relative
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, dest)
    record['sources'][relative] = hashlib.sha256(source.read_bytes()).hexdigest()
(here / 'verification.json').write_text(json.dumps(record, indent=2), encoding='utf-8')
print(json.dumps({'runs': record['runs'], 'finals_unchanged': record['finals_unchanged']}))
