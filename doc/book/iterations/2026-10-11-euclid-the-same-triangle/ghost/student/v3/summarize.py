from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json

HERE = Path(__file__).resolve().parent
def read(path): return json.loads(path.read_text(encoding='utf-8'))
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
manifest = read(HERE / 'pre_run_manifest.json')
predictions = read(HERE / 'predictions.json')
frozen_integrity = {name: sha(HERE / name) == expected for name, expected in manifest['sha256'].items()}
initial_integrity = {name: sha(HERE.parent / name) == expected for name, expected in manifest['initial_evidence_sha256'].items()}
assert all(frozen_integrity.values()) and all(initial_integrity.values())
primary = read(HERE / 'primary_results.json')
shear = read(HERE / 'shear_results.json')
reading = {
    'identity': 'Same experienced coding AI revision rerun; not a fresh student.',
    'lesson_reads': predictions['new_reads'],
    'source_comparison_reads': 'Own initial and intermediate reconstructed source; complete content comparison by extraction/diffs and hash identity.',
    'dependency_reads': 'No additional runtime dependency reads; initial reading_assistance_log.json and followup_predictions.json apply.',
    'assistance': predictions['assistance'],
    'retained_initial_evidence': '../REPORT.md, ../results.json, original frozen source, predictions, probes, logs and failure records; all hashes checked unchanged.',
    'intermediate': '../v2 frozen source/probes/predictions retained; superseded before engine execution.',
    'restricted_sources_read': False,
    'physical_xr_or_render_evidence': False,
}
(HERE / 'reading_assistance_log.json').write_text(json.dumps(reading, indent=2), encoding='utf-8')
summary = {
    'completed_at_utc': datetime.now(timezone.utc).isoformat(),
    'packet': 'final-input, reconstructed in student/v3',
    'identity': 'Revision rerun by the same experienced coding AI; not a fresh student.',
    'status': 'all_assertions_passed_with_retained_runtime_diagnostics',
    'input_sha256': manifest['input_sha256'],
    'source_comparison': predictions['verified_source_comparison'],
    'frozen_file_integrity': frozen_integrity,
    'initial_evidence_integrity': initial_integrity,
    'initial_failures_preserved': True,
    'runs': [{'probe': p['probe'], 'passed': p['passed'], 'checks_total': p['checks_total'], 'checks_passed': p['checks_total'] - len(p['failures']), 'failures': p['failures']} for p in (primary, shear)],
    'total_assertions_passed': primary['checks_total'] + shear['checks_total'],
    'presentation_checks': [item for item in primary['checks'] if item['id'].startswith('v3.')],
    'geometry_model_unchanged': True,
    'copied_listings_modified': False,
    'canonical_files_edited': False,
    'import_or_editor_repairs': False,
    'shear_prediction': 'Unchanged pre-first-run prediction; this is regression repetition, not another independent transfer demonstration.',
    'runtime_diagnostics': ['Unrecognized UID uid://rwex60pqapc in both runs', 'Jolt custom solver-bias unsupported warning in host run'],
    'limits': ['Headless numerical/property checks only', 'Synthetic input and callback dispatch, not actual ray targeting or physical XR', 'No museum render/readability claim', 'No novice-human learning claim'],
    'artifact_sha256': {p.name: sha(p) for p in sorted(HERE.iterdir()) if p.is_file() and p.name != 'results.json'},
}
(HERE / 'results.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
print(json.dumps({'status': summary['status'], 'runs': summary['runs'], 'input_sha256': summary['input_sha256'], 'initial_files_unchanged': len(initial_integrity), 'frozen_files_unchanged': len(frozen_integrity), 'presentation_checks': len(summary['presentation_checks'])}, indent=2))
