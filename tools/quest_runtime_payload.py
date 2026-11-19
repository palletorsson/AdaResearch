"""Check the generated runtime allowlist against an exported APK."""
from pathlib import Path
import re, subprocess

def runtime_study_files(root):
    """Follow executable study dependencies now used by installed artifacts.

    Documentation stays excluded. Only literal code/scene references seed this
    closure; relative imports and scene resources are then followed recursively.
    """
    root=Path(root)
    found=subprocess.run(['rg','-l','-F','res://doc/book/studies/',
        'commons','algorithms','-g','*.gd','-g','*.tscn','-g','*.tres',
        '-g','!**/testing/**','-g','!**/dev_tools/**'],cwd=root,
        capture_output=True,text=True,check=False)
    if found.returncode not in (0,1):raise RuntimeError(found.stderr)
    allowed={'.gd','.tscn','.tres','.gdshader','.gdshaderinc','.json'}
    quoted=re.compile(r'''["']([^"'\n]+)["']''')
    pending=[]
    for filename in found.stdout.splitlines():
        text=(root/filename).read_text(encoding='utf8')
        pending += [value[6:] for value in quoted.findall(text)
                    if value.startswith('res://doc/book/studies/') and Path(value).suffix in allowed]
    needed=set()
    while pending:
        rel=pending.pop()
        if rel in needed:continue
        path=root/rel
        if not path.is_file():raise FileNotFoundError('Quest runtime study dependency: '+rel)
        needed.add(rel)
        for value in quoted.findall(path.read_text(encoding='utf8')):
            if Path(value).suffix not in allowed or '%' in value or ('://' in value and not value.startswith('res://')):continue
            target=root/value[6:] if value.startswith('res://') else path.parent/value
            try:child=target.resolve().relative_to(root.resolve()).as_posix()
            except ValueError:continue
            if child.startswith('doc/book/studies/'):pending.append(child)
    return sorted(needed)

def allowed_runtime_assets(runtime):
    names={'assets/'+path+suffix for path in runtime for suffix in ['', '.remap']}
    # Godot's script remaps point to bytecode beside the source path.
    names.update('assets/'+path[:-3]+'.gdc' for path in runtime if path.endswith('.gd'))
    return names

def missing_runtime_assets(archive, runtime):
    names=set(archive.namelist())
    return [path for path in runtime if 'assets/'+path not in names
            and 'assets/'+path+'.remap' not in names]
