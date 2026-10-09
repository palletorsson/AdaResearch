"""Commit the requested Rotation chapter and dependencies, preserving other work."""
import hashlib
import json
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
assert ROOT.name == 'AdaResearch_46' and (ROOT / '.git').exists()
GIT = ['git', '-c', 'safe.directory=' + ROOT.as_posix()]

def git(args, env=None):
    return subprocess.check_output(GIT + args, cwd=ROOT, env=env).decode('utf-8').strip()

files = json.loads((BASE / 'rotation-commit-files.json').read_text())
parser = 'commons/grid/GridInteractablesComponent.gd'
targets = files + [parser]
original_head = git(['rev-parse', 'HEAD'])
assert not git(['diff', '--cached', '--name-only', '--'] + targets), 'Target already staged by another task'
hashes = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in targets}
env = os.environ.copy()
env['GIT_INDEX_FILE'] = str(BASE / 'rotation-commit.index')
git(['read-tree', original_head], env)
git(['add', '--'] + files, env)
parser_text = git(['show', original_head + ':' + parser]) + '\n'
anchor = '\t"rot_x", "rot_y", "rot_z", "pos_x", "pos_y", "pos_z",\n'
addition = ('\t# Rotation studies and gallery staging use numeric values, not tutorial yaw.\n'
            '\t"band_spacing", "row_angle_step", "num_segments", "rotation_per_segment",\n'
            '\t"segment_vertical_offset", "plinth",\n')
if '"band_spacing"' not in parser_text:
    assert anchor in parser_text
    parser_text = parser_text.replace(anchor, anchor + addition, 1)
blob = subprocess.check_output(GIT + ['hash-object', '-w', '--stdin'],
                               cwd=ROOT, input=parser_text.encode('utf-8')).decode().strip()
git(['update-index', '--add', '--cacheinfo', '100644,' + blob + ',' + parser], env)
git(['diff', '--cached', '--check'], env)
print(git(['diff', '--cached', '--stat'], env), flush=True)
assert git(['rev-parse', 'HEAD']) == original_head, 'HEAD changed concurrently'
assert hashes == {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in targets}, 'Target changed concurrently'
assert not git(['diff', '--cached', '--name-only', '--'] + targets), 'Target staged concurrently'
git(['commit', '-m', 'Align Rotation chapter with crossings and include ride dependencies'], env)
commit = git(['rev-parse', 'HEAD'])
# Align only our entries in the ordinary index with the new commit. This never
# changes worktree files or any unrelated staged entry (including other tasks).
git(['reset', commit, '--'] + targets)
assert hashes == {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in targets}
(BASE / 'rotation-commit.json').write_text(json.dumps({'commit':commit,'parent':original_head,'files':targets,'worktree_preserved':True},indent=2)+'\n')
print(commit)
