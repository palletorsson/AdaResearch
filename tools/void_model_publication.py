"""Validate, version and atomically publish native previews; never overwrite live meshes."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import uuid

from generated_storage import PROJECT, public_directory
from void_native_slot import acquire_native_slot


def require_export_space(directory):
    if shutil.disk_usage(directory).free < 128*1024**2:
        raise RuntimeError('Not enough space to generate previews safely; previous models are unchanged')


def editor_directory(relative='void-models'):
    """Require the editor mount and exporters to agree on one external store."""
    relative_path = Path(relative)
    if relative_path.is_absolute() or '..' in relative_path.parts:
        raise ValueError('Invalid public model family')
    target = public_directory(relative)
    web = Path(os.environ.get('ADA_ENCYCLOPEDIA_ROOT', PROJECT.parent/'ada_encyclopedia'))
    # Mount the whole family, including newly created trials, on the local store.
    mount = web/'public'/relative_path.parts[0]
    family = public_directory(relative_path.parts[0])
    if os.path.lexists(mount) and not mount.exists() and mount.resolve()!=family:
        # Preserve the disconnected-drive junction; never traverse/delete its data.
        mount.rename(mount.with_name(mount.name+'.offline-'+uuid.uuid4().hex[:10]))
    if os.path.lexists(mount):
        if mount.resolve() != family:
            raise RuntimeError(f'Editor model mount {mount} points to {mount.resolve()}, expected {family}. '
                               'No published files were changed; repair the mount before exporting.')
    else:
        family.mkdir(parents=True, exist_ok=True)
        mount.parent.mkdir(parents=True, exist_ok=True)
        if os.name == 'nt':
            subprocess.run(['cmd', '/c', 'mklink', '/J', str(mount), str(family)], check=True, capture_output=True)
        else:
            mount.symlink_to(family, target_is_directory=True)
    target.mkdir(parents=True, exist_ok=True)
    return target


def atomic_json(file, data):
    temp = file.with_name(file.name+'.'+uuid.uuid4().hex+'.tmp')
    try:
        with temp.open('w', encoding='utf8') as stream:
            json.dump(data, stream, ensure_ascii=False, indent=2)
            stream.write('\n')
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temp, file)
    finally:
        temp.unlink(missing_ok=True)


def merge_models(old, new):
    for key in ('floors', 'props', 'workbench', 'source_files'):
        old.setdefault(key, {}).update(new.get(key, {}))
    for key in ('lighting', 'environment', 'sky', 'export_shutdown_diagnostics'):
        if key in new: old[key] = new[key]


def publish_models(staged, new, public, public_base='/void-models', merge=merge_models):
    """New assets have content-addressed URLs. Manifest is the last, atomic commit.

    Called with only the newly exported records, never an already merged manifest.
    Old URLs and manifest.previous.json remain usable if generation/publication fails.
    Unreferenced versioned files are deliberately not garbage-collected here.
    """
    if new.get('failures'):
        raise ValueError('Refusing an export with failures: '+str(new['failures']))
    staged, public = Path(staged).resolve(), Path(public).resolve()
    public.mkdir(parents=True, exist_ok=True)
    prefix = public_base.rstrip('/')+'/'
    assets = {}

    def version(value):
        if isinstance(value, dict): return {k: version(v) for k, v in value.items()}
        if isinstance(value, list): return [version(v) for v in value]
        if not isinstance(value, str) or not value.startswith(prefix): return value
        name = value[len(prefix):]
        if Path(name).name != name or name in ('', '.', '..') or '\\' in name:
            raise ValueError('Unsafe or nested preview asset: '+value)
        if name not in assets:
            source = staged/name
            if not source.is_file() or not source.resolve().is_relative_to(staged):
                raise ValueError('Missing staged preview: '+str(source))
            blob = source.read_bytes()
            if not blob: raise ValueError('Empty preview: '+name)
            if source.suffix == '.glb' and (len(blob)<12 or blob[:4]!=b'glTF' or
                    int.from_bytes(blob[4:8], 'little')!=2 or int.from_bytes(blob[8:12], 'little')!=len(blob)):
                raise ValueError('Invalid GLB: '+name)
            digest = hashlib.sha256(blob).hexdigest()
            filename = source.stem+'-'+digest[:20]+source.suffix
            assets[name] = (source, filename, digest, len(blob))
        return prefix+assets[name][1]

    # Validate every newly referenced file BEFORE touching the published manifest.
    replacement = version(new)
    with acquire_native_slot('publish verified Void models', timeout=120, lock_name='void-model-publication.lock'):
        manifest = public/'manifest.json'
        old = json.loads(manifest.read_text(encoding='utf8')) if manifest.exists() else {'version':1,'floors':{},'props':{}}
        required = sum(size for _, name, _, size in assets.values() if not (public/name).exists())
        if shutil.disk_usage(public).free < required + 128*1024**2:
            raise RuntimeError('Not enough space to publish safely; the previous export is unchanged')
        for source, name, digest, _ in assets.values():
            target = public/name
            if target.exists():
                if hashlib.sha256(target.read_bytes()).hexdigest()!=digest:
                    raise ValueError('Published asset checksum mismatch: '+name)
                continue
            temp = target.with_name(name+'.'+uuid.uuid4().hex+'.tmp')
            try:
                shutil.copy2(source, temp)
                if hashlib.sha256(temp.read_bytes()).hexdigest()!=digest:
                    raise ValueError('Export changed during publication: '+source.name)
                os.replace(temp, target)
            finally:
                temp.unlink(missing_ok=True)
        updated = json.loads(json.dumps(old))
        merge(updated, replacement)
        updated['revision'] = hashlib.sha256(json.dumps(updated, sort_keys=True).encode()).hexdigest()[:16]
        if manifest.exists(): atomic_json(public/'manifest.previous.json', old)
        atomic_json(manifest, updated)
        return updated
