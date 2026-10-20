from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json

HERE = Path(__file__).resolve().parent
def read(name): return json.loads((HERE / name).read_text(encoding='utf-8'))
frozen = read('pre_run_manifest.json')
integrity = {name: hashlib.sha256((HERE / name).read_bytes()).hexdigest() == digest for name, digest in frozen['sha256'].items()}
assert all(integrity.values())
probes = [read('primary_results.json'), read('shear_results.json'), read('continuous_grab_results.json')]
summary = {
    'completed_at_utc': datetime.now(timezone.utc).isoformat(),
    'packet': 'initial_frozen_packet',
    'status': 'qualified_software_result_with_retained_initial_failures_and_runtime_diagnostics',
    'identity': 'Experienced coding AI ghost student, not novice human.',
    'input_sha256': frozen['input_sha256'],
    'pre_run_frozen_file_integrity': integrity,
    'runs': [{'probe': p['probe'], 'passed': p['passed'], 'checks_total': p['checks_total'], 'checks_passed': p['checks_total']-len(p['failures']), 'failures': p['failures']} for p in probes],
    'reconstructed': True,
    'lesson_source_changed': False,
    'canonical_changes_made': False,
    'editor_or_import_repairs': False,
    'independent_variation': {'operation': 'area-preserving shear x_new=x+0.5*y', 'predicted_before_first_engine_run': True, 'executed_separately': True, 'passed': probes[1]['passed'], 'transfer': 'Limited conceptual transfer by experienced agent; independent test design, not invention of copied lesson implementation.'},
    'initial_failures_qualification': 'One-shot synthetic body teleport did not maintain hand pose over physics frames; continuous pose follow-up passed all 12 checks with unchanged lesson source. Actual desktop controller and physical XR remain untested.',
    'runtime_diagnostics': ['Unrecognized UID uid://rwex60pqapc in every run.', 'Jolt custom solver bias unsupported warning in host runs.', 'Initial Python console echo cp1252 error after UTF-8 logs/results saved; later invocation used python -X utf8.'],
    'limits': ['No physical XR claim', 'No render or museum placement claim', 'No actual pointer targeting test', 'No human-learning claim', 'No proof of postulates from measurements'],
    'reading_and_assistance_logs': ['reading_assistance_log.json', 'followup_predictions.json', 'REPORT.md'],
    'artifact_sha256': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(HERE.iterdir()) if p.is_file() and p.name != 'results.json'},
}
(HERE / 'results.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
print(json.dumps({k: summary[k] for k in ('status', 'runs', 'pre_run_frozen_file_integrity')}, indent=2))
