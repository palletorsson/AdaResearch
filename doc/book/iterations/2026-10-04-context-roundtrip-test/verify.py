"""Read-only snapshot checks and an in-memory stale-input experiment."""
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]


def digest(data):
    return hashlib.sha256(data).hexdigest()


manifest = json.loads((HERE / 'manifest.json').read_text(encoding='utf-8'))
files = []
for item in manifest['files']:
    frozen = (HERE / 'snapshot' / item['path']).read_bytes()
    current = (ROOT / item['path']).read_bytes()
    files.append({
        'path': item['path'],
        'snapshot_matches_manifest': digest(frozen) == item['sha256'],
        'working_file_matches_manifest': digest(current) == item['sha256'],
    })

target = 'commons/primitives/line/grid_lines.gd'
original = (HERE / 'snapshot' / target).read_bytes()
# No file is changed. A comment suffices to demonstrate why stale != false.
simulated = original + b'\n# Hypothetical comment for the memory pilot.\n'
result = {
    'scope': 'Thirteen selected files only; no runtime test.',
    'files': files,
    'all_snapshot_hashes_match': all(f['snapshot_matches_manifest'] for f in files),
    'all_selected_working_files_unchanged': all(f['working_file_matches_manifest'] for f in files),
    'packet_words_whitespace_count': len((HERE / 'PACKET.md').read_text(encoding='utf-8').split()),
    'handoff_words_whitespace_count': len((HERE / 'HANDOFF_REPLY.md').read_text(encoding='utf-8').split()),
    'stale_input_simulation': {
        'source': target,
        'original_sha256': digest(original),
        'simulated_sha256': digest(simulated),
        'change_detected': digest(original) != digest(simulated),
        'written_to_disk': False,
        'manually_declared_affected_claims': ['Grid fits before rounding', 'Grid rounding loses position detail'],
        'manually_declared_affected_summaries': ['Point_Line_Grid', 'Array return in subject register'],
        'conclusion': 'Evidence version needs review; a changed fingerprint does not refute the claim.',
        'limit': 'No automatic dependency discovery or semantic invalidation was tested.',
    },
}
(HERE / 'checks.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
print(json.dumps({k: v for k, v in result.items() if k not in ('files', 'stale_input_simulation')}, indent=2))
assert result['all_snapshot_hashes_match']
assert result['all_selected_working_files_unchanged']
assert result['stale_input_simulation']['change_detected']
