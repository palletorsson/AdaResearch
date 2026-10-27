"""Inspect gameplay dependencies and compare APK payload with authoring content.

Read-only by default. Does not run Godot or walk ada_run runtime junctions.
"""
import argparse, json, os, re, subprocess, zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TRIAL = 'commons/void/trials/'
TEXT = {'.gd', '.tscn', '.tres', '.json', '.gdshader', '.gdshaderinc'}
REF = re.compile(r'''res://([^\s"'<>\)\],;]+)''')
AUTHOR_DIRS = {'evidence', 'screenshots', 'captures', '__pycache__'}
TRIAL_METADATA = {'trial.tscn', 'rooms.json', 'layout.json', 'playable.json',
                  'briefs.json', 'reviews.json', 'STATUS.json', 'status.json'}

def files_under(path):
    for directory, dirs, files in os.walk(path, followlinks=False):
        dirs[:] = [d for d in dirs if not (Path(directory)/d).is_symlink()
                   and d not in {'.git', '.godot', 'node_modules'}]
        for name in files:
            yield Path(directory)/name

def authoring(rel):
    p = Path(rel)
    return bool(set(p.parts) & AUTHOR_DIRS) or p.suffix.lower() in {
        '.md', '.html', '.log', '.py', '.ps1', '.bat', '.sh', '.glb', '.import'
    } or (p.name in TRIAL_METADATA and rel != TRIAL+'session.gd')

def runtime_trial_files():
    roots, dynamic = set(), set()
    found=subprocess.run(['rg','-l','-F','res://commons/void/trials/',
        'commons','algorithms','addons','-g','*.gd','-g','*.tscn','-g','*.tres',
        '-g','*.json','-g','!**/trials/**','-g','!**/testing/**',
        '-g','!**/dev_tools/**'],cwd=ROOT,capture_output=True,text=True,check=False)
    if found.returncode not in (0,1): raise RuntimeError(found.stderr)
    for name in found.stdout.splitlines():
        p=ROOT/name
        if p.is_file():
            rel = p.relative_to(ROOT).as_posix()
            if rel.startswith(TRIAL) or '/testing/' in rel or '/dev_tools/' in rel:
                continue
            if p.suffix not in TEXT:
                continue
            text = p.read_text(encoding='utf-8', errors='replace')
            for ref in REF.findall(text):
                if not ref.startswith(TRIAL):
                    continue
                target = ROOT/ref
                if target.is_file() and not authoring(ref):
                    roots.add(ref)
                elif target.is_dir():
                    dynamic.add(ref)
    # floor_content's two adapter dictionaries load scripts by concatenation.
    # Keep candidates in these bounded directories; never add trial rooms/evidence.
    for directory in dynamic:
        for p in (ROOT/directory).glob('*.gd'):
            if not any(word in p.stem for word in ('probe', 'test', 'export', 'capture')):
                roots.add(p.relative_to(ROOT).as_posix())
    roots.add(TRIAL+'session.gd')  # game.gd's relative preload
    needed, pending, missing = set(), list(roots), []
    while pending:
        rel = pending.pop()
        if rel in needed:
            continue
        p = ROOT/rel
        if not p.is_file():
            missing.append(rel)
            continue
        needed.add(rel)
        if p.suffix not in TEXT:
            continue
        text = p.read_text(encoding='utf-8', errors='replace')
        refs = REF.findall(text)
        refs += [((p.parent/v).relative_to(ROOT).as_posix())
                 for v in re.findall(r'''(?:preload|load)\(["']([^:"']+)["']\)''',text)]
        refs += [((p.parent/v).relative_to(ROOT).as_posix())
                 for v in re.findall(r'''^extends\s+["']([^:"']+)["']''',text,re.M)]
        for ref in refs:
            if ref.startswith(TRIAL) and (ROOT/ref).is_file() and ref not in needed:
                pending.append(ref)
    all_trial = {p.relative_to(ROOT).as_posix() for p in files_under(ROOT/TRIAL)
                 if p.suffix != '.uid'}
    return {'runtime': sorted(needed), 'excluded': sorted(all_trial-needed),
            'missing': sorted(set(missing)), 'dynamic_directories': sorted(dynamic)}

def inspect_apk(path):
    with zipfile.ZipFile(path) as z:
        assets = [i for i in z.infolist() if i.filename.startswith('assets/')]
        groups = {}
        for prefix in ('ada_run/', TRIAL, 'commons/testing/', 'tools/', 'doc/'):
            selected = [i for i in assets if i.filename[7:].startswith(prefix)]
            groups[prefix] = {'files': len(selected), 'compressed_bytes': sum(i.compress_size for i in selected)}
        return {'apk': str(path), 'bytes': path.stat().st_size,
                'asset_entries': len(assets), 'groups': groups}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--apk', type=Path)
    args=parser.parse_args()
    result={'trial_dependencies': runtime_trial_files()}
    if args.apk: result['existing_apk']=inspect_apk(args.apk)
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    deps=result['trial_dependencies']
    print(json.dumps({'runtime_trial_files':len(deps['runtime']), 'excluded_trial_files':len(deps['excluded']), 'missing':deps['missing'], 'dynamic':deps['dynamic_directories'], 'existing_apk':result.get('existing_apk')},indent=2))

if __name__=='__main__': main()
