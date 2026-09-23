#!/usr/bin/env python3
"""Read-only source census of interface evidence, NOT a runtime widget counter.

Includes scenes, resources, GDScript (including embedded source), C#, shaders and
configuration throughout the checkout. Writes only the requested report folder.
No third-party dependencies. Run: python tools/interface_inventory.py
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict, deque
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import hashlib
import html
import json
import os
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUT = ROOT / "doc/reports/interfaces-2026-09-20/full-inventory"
SOURCE = {".gd", ".tscn", ".tres", ".cs", ".gdshader", ".shader"}
CONFIG = {".json", ".godot", ".cfg", ".gdns"}
SKIP = {".git", ".godot", "node_modules", ".venv", "venv", "__pycache__",
        ".mypy_cache", ".pytest_cache", ".claude", ".codex", ".agents",
        ".gradle", ".cache", "build", "builds", "export", "exports", "dist"}
REPORT_DATA = {"doc", "docs", "ada_run", "outputs", "reports_tmp", "tmp",
               "user_capture_test", "backups", "_archive", ".benchmarks"}
TOKEN = re.compile(r'(?P<comment>\#[^\n]*)|(?P<string>"""[\s\S]*?"""|\x27\x27\x27[\s\S]*?\x27\x27\x27|"(?:\\[\s\S]|[^"\\])*"|\x27(?:\\[\s\S]|[^\x27\\])*\x27)')
RESOURCE = re.compile(r'^(?:res://|uid://)[^\r\n]+$')
ATTR = re.compile(r'(\w+)\s*=\s*"((?:\\.|[^"\\])*)"')
HEAD = re.compile(r'^\[(node|ext_resource|sub_resource|resource|gd_scene|gd_resource)\b([^\n]*)\]\s*$', re.M)
NATIVE = {
    **{x: "button" for x in ("BaseButton", "Button", "CheckButton", "CheckBox", "LinkButton", "MenuButton", "OptionButton", "TextureButton")},
    **{x: "slider" for x in ("Slider", "HSlider", "VSlider")},
    **{x: "text_surface" for x in ("Label", "Label3D", "RichTextLabel", "TextMesh")},
    **{x: "image_surface" for x in ("TextureRect", "TextureProgressBar", "VideoStreamPlayer")},
    **{x: "viewport_surface" for x in ("SubViewport", "ViewportTexture", "SubViewportContainer")},
    **{x: "panel_surface" for x in ("Panel", "PanelContainer", "ProgressBar")},
    **{x: "other_control" for x in ("SpinBox", "LineEdit", "TextEdit", "CodeEdit", "ColorPicker", "ColorPickerButton", "ItemList", "Tree", "TabBar", "HScrollBar", "VScrollBar")},
}
VOCAB = re.compile(r'button|slider|fader|screen|readout|display|monitor|knob|dial|crank|lever|joystick|touch.?pad|touch.?grid|patch.?bay|whiteboard|text.?screen', re.I)
FACTORY = re.compile(r'^(?:_?(?:add|make|create|build|spawn|setup|instantiate)_.*|slider_[hv]|button|knob|dial|readout)$', re.I)


def mask(text):
    """Preserve offsets/newlines while blanking comments and strings separately."""
    code, uncommented, strings = list(text), list(text), []
    for m in TOKEN.finditer(text):
        blank = ['\n' if c == '\n' else ' ' for c in m.group()]
        code[m.start():m.end()] = blank
        if m.lastgroup == "comment":
            uncommented[m.start():m.end()] = blank
        else:
            quote_len = 3 if m.group().startswith(('"""', "'''")) else 1
            strings.append((m.start(), m.group()[quote_len:-quote_len]))
    return ''.join(code), ''.join(uncommented), strings


def category(name):
    if name in NATIVE:
        return NATIVE[name]
    n = name.lower()
    if "button" in n:
        return "button"
    if "slider" in n or "fader" in n:
        return "slider"
    if any(x in n for x in ("screen", "readout", "display", "monitor")):
        return "display_candidate"
    return "other_control"


def scope(path):
    parts = path.lower().split('/')
    if any(p in {"archive", "archives", "backup", "backups", "_archive"} or p.startswith('_backup') for p in parts):
        return "archive"
    if parts[0] == "addons":
        return "addon"
    if parts[0] in {"doc", "docs", "ada_run", "tools", "tests", "test"} or any(p in {"testing", "dev_tools"} for p in parts):
        return "test_or_documentation"
    if parts[0] in {"build", "builds", "export", "exports", "dist"}:
        return "build_output"
    return "project"


def gd_evidence(text):
    """Extract construction evidence and weaker hints without counting comments."""
    code, uncommented, strings = mask(text)
    lines = text.splitlines()
    rows = []

    def add(pos, kind, family, symbol):
        line = text.count('\n', 0, pos) + 1
        rows.append(dict(line=line, kind=kind, family=family, symbol=symbol,
                         excerpt=lines[line - 1].strip()[:230]))

    for m in re.finditer(r'^\s*(extends|class_name)\s+([A-Za-z_]\w*)', code, re.M):
        if m[2] in NATIVE:
            add(m.start(), "native_base_definition", NATIVE[m[2]], m[2])
        elif m[1] == 'class_name' and VOCAB.search(m[2]):
            add(m.start(), "named_class_definition_candidate", category(m[2]), m[2])
    for m in re.finditer(r'\b([A-Za-z_]\w*)\s*\.\s*new\s*\(', code):
        cls = m[1]
        if cls in NATIVE:
            add(m.start(), "native_constructor", NATIVE[cls], cls)
        elif VOCAB.search(cls):
            add(m.start(), "named_constructor_candidate", category(cls), cls)
    for m in re.finditer(r'\b([A-Za-z_]\w*)\s*\(', code):
        name = m[1]
        if FACTORY.match(name) and VOCAB.search(name):
            prefix = code[max(0, code.rfind('\n', 0, m.start()) + 1):m.start()]
            kind = "factory_definition" if re.search(r'\bfunc\s*$', prefix) else "factory_call_candidate"
            add(m.start(), kind, category(name), name)
    for m in re.finditer(r'\b(button_pressed|pressed|toggled|value_changed|drag_started|drag_ended)\s*\.\s*connect\s*\(', code):
        add(m.start(), "signal_connection", "wiring_only", m[1])
    for m in re.finditer(r'\b(draw_string|draw_multiline_string|draw_char)\s*\(', code):
        add(m.start(), "text_drawing_candidate", "text_surface", m[1])
    for m in re.finditer(r'\bInput\s*\.\s*(\w+)\s*\(|\b(?:is_action_pressed|is_action_just_pressed|is_button_pressed)\s*\(', code):
        add(m.start(), "input_poll", "input_only", m.group().strip())
    for pos, string in strings:
        if RESOURCE.match(string) and VOCAB.search(Path(string).stem):
            add(pos, "resource_reference_candidate", category(Path(string).stem), string)
        # RackTemplates and other data-driven builders describe widgets in dictionaries.
        if string in {"button", "slider_h", "slider_v", "knob", "dial", "readout", "screen", "fader", "touch_grid", "joystick"}:
            prefix = uncommented[max(0, pos - 25):pos]
            if re.search(r'["\x27]type["\x27]\s*:\s*$', prefix):
                add(pos, "config_widget_candidate", category(string), string)
    # Keep unresolved naming evidence separate; passive meshes can have these names.
    if not any(r['family'] not in {"wiring_only", "input_only"} for r in rows):
        match = VOCAB.search(code)
        if match:
            add(match.start(), "identifier_hint_only", category(match.group()), match.group())
    return rows, code, strings


def config_evidence(text):
    rows = []
    for m in re.finditer(r'"(?:type|control_type|widget)"\s*:\s*"([A-Za-z_]+)"', text):
        if VOCAB.search(m[1]):
            rows.append(dict(line=text.count('\n', 0, m.start()) + 1, kind="config_widget_candidate",
                             family=category(m[1]), symbol=m[1], excerpt=m.group()))
    return rows


def scene_evidence(text):
    rows, embedded = [], []
    # Strip string contents to avoid interpreting bracket lines inside embedded code.
    code, _, _ = mask(text)
    headers = []
    for m in HEAD.finditer(text):
        if code[m.start():m.start() + len(m[1]) + 1].startswith('[' + m[1]):
            headers.append(m)
    for i, m in enumerate(headers):
        attrs = dict(ATTR.findall(m[2]))
        line = text.count('\n', 0, m.start()) + 1
        typ = attrs.get('type', '')
        name = attrs.get('name', attrs.get('id', ''))
        body = text[m.end():headers[i + 1].start() if i + 1 < len(headers) else len(text)]
        if m[1] == 'ext_resource' and VOCAB.search(Path(attrs.get('path', '')).stem):
            ref = attrs['path']
            rows.append(dict(line=line, kind="resource_reference_candidate", family=category(Path(ref).stem), symbol=ref, excerpt=m.group()[:230]))
        if typ in NATIVE and m[1] in {"node", "sub_resource", "resource"}:
            rows.append(dict(line=line, kind="scene_node" if m[1] == "node" else "scene_resource",
                             family=NATIVE[typ], symbol=typ, node=name, parent=attrs.get('parent'), excerpt=m.group()[:230]))
        elif m[1] == "node" and VOCAB.search(name):
            rows.append(dict(line=line, kind="node_name_hint_only", family=category(name),
                             symbol=typ or "instance", node=name, parent=attrs.get('parent'), excerpt=m.group()[:230]))
        if m[1] == "sub_resource" and typ == "GDScript":
            sm = re.search(r'script/source\s*=\s*("(?:\\[\s\S]|[^"\\])*")', body)
            if sm:
                # Godot strings allow literal newlines. JSON decodes its common escapes.
                source = json.loads(sm[1], strict=False)
                embedded.append((attrs.get('id', ''), line, source))
    return rows, embedded


def resolve_ref(value, path, available, uids):
    if value.startswith('uid://'):
        return uids.get(value)
    if value.startswith('res://'):
        return value[6:].replace('\\', '/')
    if Path(value).suffix.lower() in SOURCE | CONFIG and not re.search(r'[\n\r:*?]', value):
        candidate = os.path.normpath(str(Path(path).parent / value)).replace('\\', '/')
        if candidate in available:
            return candidate
    return None


def descendants(start, graph):
    """Cycle-safe transitive closure with NO depth limit; counts source, not instances."""
    seen, queue = set(), deque([start])
    while queue:
        current = queue.popleft()
        if current in seen:
            continue
        seen.add(current)
        queue.extend(graph.get(current, ()))
    return seen


def token_key(token):
    return re.split(r'[:#]', token.strip(), maxsplit=1)[0]


def run(root, out):
    files, skipped, skipped_data, errors = [], [], [], []
    for base, dirs, names in os.walk(root):
        for directory in list(dirs):
            p = Path(base) / directory
            if directory in SKIP or p.resolve() == out.resolve():
                skipped.append(p.relative_to(root).as_posix())
                dirs.remove(directory)
        for name in names:
            p = Path(base) / name
            relative = p.relative_to(root)
            if p.suffix.lower() in CONFIG and relative.parts[0] in REPORT_DATA:
                skipped_data.append(relative.as_posix())
                continue
            if p.suffix.lower() in SOURCE | CONFIG or name.endswith('.gd.uid'):
                files.append(p)
    print(f'Enumerated {len(files)} source/config/UID files; reading source.', file=sys.stderr, flush=True)
    texts, manifest, uids, classes = {}, [], {}, defaultdict(list)
    def read_file(p):
        try:
            raw = p.read_bytes()
            return p, raw.decode('utf-8-sig'), len(raw), hashlib.sha256(raw).hexdigest(), None
        except (OSError, UnicodeError) as exc:
            return p, None, None, None, str(exc)

    with ThreadPoolExecutor(max_workers=16) as pool:
        loaded = list(pool.map(read_file, sorted(files)))
    for p, text, size, digest, error in loaded:
        path = p.relative_to(root).as_posix()
        if error:
            errors.append(dict(path=path, error=error))
            continue
        if path.endswith('.gd.uid'):
            uids[text.strip()] = path[:-4]
            continue
        texts[path] = text
        manifest.append(dict(path=path, scope=scope(path), sha256=digest, bytes=size))
        if p.suffix in {'.tscn', '.tres'}:
            uid = re.search(r'^\[gd_\w+[^\n]*\buid="([^"]+)"', text)
            if uid:
                uids[uid[1]] = path
        if p.suffix == '.gd':
            code = mask(text)[0]
            cls = re.search(r'^class_name\s+(\w+)', code, re.M)
            if cls:
                classes[cls[1]].append(path)
    available = set(texts)
    print(f'Read {len(texts)} source/config files; extracting evidence.', file=sys.stderr, flush=True)
    occurrences, graph, unresolved, embedded_manifest = [], defaultdict(set), [], []
    edge_evidence = []

    def edge(source, target, kind, line):
        if target in available:
            if target != source:
                graph[source].add(target)
                edge_evidence.append(dict(source=source, target=target, kind=kind, line=line))
        else:
            unresolved.append(dict(path=source, line=line, kind="missing_or_unscanned_resource", target=target))

    def script(path, text, embedded_id=None, origin_line=1):
        rows, code, strings = gd_evidence(text)
        for row in rows:
            row.update(path=path, scope=scope(path))
            if embedded_id:
                row.update(embedded=embedded_id, embedded_line=row['line'], line=origin_line)
            occurrences.append(row)
        for m in re.finditer(r'\bextends\s+([A-Za-z_]\w*)|\b([A-Za-z_]\w*)\s*\.', code):
            name = m[1] or m[2]
            if name in classes:
                for target in classes[name]:
                    edge(path, target, "class_reference", text.count('\n', 0, m.start()) + 1)
        for m in re.finditer(r'\b(?:load|preload|load_threaded_request)\s*\(([^)\n]*)', code):
            # Constant identifiers, formatted or assembled paths need value-flow analysis.
            argument = m[1].strip()
            original = text[m.start(1):m.end(1)].strip()
            if argument:
                unresolved.append(dict(path=path, kind="dynamic_load_expression", line=text.count('\n', 0, m.start()) + 1, expression=original[:200]))
        return strings

    for path, text in texts.items():
        suffix = Path(path).suffix.lower()
        if suffix == '.gd':
            strings = script(path, text)
        elif suffix in {'.tscn', '.tres'}:
            rows, embeds = scene_evidence(text)
            occurrences.extend(dict(row, path=path, scope=scope(path)) for row in rows)
            for eid, line, source in embeds:
                embedded_manifest.append(dict(path=path, resource=eid, line=line))
                estr = script(path, source, eid, line)
                for _, value in estr:
                    target = resolve_ref(value, path, available, uids)
                    if target:
                        edge(path, target, "embedded_reference", line)
            strings = mask(text)[2]
        else:
            strings = mask(text)[2] if suffix != '.json' else [(m.start(), m[1]) for m in re.finditer(r'"((?:\\.|[^"\\])*)"', text)]
            if suffix == '.json':
                occurrences.extend(dict(row, path=path, scope=scope(path)) for row in config_evidence(text))
            if suffix == '.cs':
                # C# is rare here. Constructor evidence only, not a C# semantic parser.
                clean = re.sub(r'//[^\n]*|/\*[\s\S]*?\*/', '', text)
                for m in re.finditer(r'\bnew\s+(\w+)\s*\(', clean):
                    if m[1] in NATIVE:
                        occurrences.append(dict(path=path, scope=scope(path), line=clean.count('\n', 0, m.start()) + 1,
                            kind="csharp_constructor_candidate", family=NATIVE[m[1]], symbol=m[1], excerpt=m.group()))
        for pos, value in strings:
            target = resolve_ref(value, path, available, uids)
            if target and Path(target).suffix.lower() in SOURCE | CONFIG:
                edge(path, target, "literal_resource_reference", text.count('\n', 0, pos) + 1)
            elif value.startswith('uid://') and value not in uids:
                unresolved.append(dict(path=path, line=text.count('\n', 0, pos) + 1, kind="unresolved_uid", target=value))
        if suffix == '.gd' and ('source_code' in text or '.reload(' in text):
            unresolved.append(dict(path=path, kind="runtime_generated_source_candidate"))

    strong = {"native_constructor", "native_base_definition", "named_class_definition_candidate", "scene_node", "scene_resource", "named_constructor_candidate",
              "factory_call_candidate", "config_widget_candidate", "resource_reference_candidate", "csharp_constructor_candidate", "text_drawing_candidate"}
    by_file = defaultdict(list)
    for row in occurrences:
        by_file[row['path']].append(row)
    for row in manifest:
        rs = by_file[row['path']]
        row['evidence_count'] = len(rs)
        row['families'] = sorted({r['family'] for r in rs if r['kind'] in strong})

    registries, duplicates = defaultdict(list), []
    print(f'Extracted {len(occurrences)} evidence sites; tracing registries.', file=sys.stderr, flush=True)
    for path, text in texts.items():
        if not path.startswith('commons/artifacts/registry/') or not path.endswith('.json'):
            continue
        try:
            data = json.loads(text)
            for key, item in data.get('artifacts', {}).items():
                if isinstance(item, dict):
                    registries[key].append(dict(registry=path, scene=item.get('scene', '')))
        except (ValueError, AttributeError) as exc:
            errors.append(dict(path=path, error=str(exc)))
    artifacts = []
    for key, entries in sorted(registries.items()):
        if len(entries) > 1:
            duplicates.append(dict(key=key, definitions=entries))
        roots = {e['scene'].removeprefix('res://') for e in entries if e['scene']}
        reached = set()
        for start in roots:
            reached.update(descendants(start, graph))
        evidence_files = sorted(p for p in reached if any(r['kind'] in strong for r in by_file.get(p, [])))
        families = sorted({r['family'] for p in evidence_files for r in by_file[p] if r['kind'] in strong})
        artifacts.append(dict(key=key, definitions=entries, families=families, evidence_files=evidence_files,
                              reached_files=len(reached), interpretation="possible dependency use, not live instances"))
    artifact_index = {a['key']: a for a in artifacts}
    active = set()
    spine_path = 'commons/maps/curriculum_spine.json'
    try:
        spine = json.loads(texts[spine_path])
        for sequence in spine['spine']['sequences']:
            data = json.loads(texts['commons/maps/sequences/' + sequence['name'] + '.json'])
            for info in data.get('sequences', {}).values():
                active.update(x for x in info.get('maps', []) if isinstance(x, str))
    except (KeyError, ValueError) as exc:
        errors.append(dict(path=spine_path, error=str(exc)))
    placements, indirect, map_errors = [], [], []
    for path, text in texts.items():
        if not path.startswith('commons/maps/') or not path.endswith('/map_data.json'):
            continue
        try:
            data = json.loads(text)
            map_name = path.split('/')[-2]
            for layer, grid in data.get('layers', {}).items():
                if not isinstance(grid, list):
                    continue
                for z, row in enumerate(grid):
                    if not isinstance(row, list):
                        continue
                    for x, token in enumerate(row):
                        if not isinstance(token, str) or not token.strip():
                            continue
                        key = token_key(token)
                        artifact = artifact_index.get(key)
                        if artifact or layer == 'interactables':
                            placements.append(dict(map=map_name, path=path, layer=layer, x=x, z=z, token=token,
                                key=key, registered=artifact is not None, families=artifact['families'] if artifact else [],
                                in_spine=map_name in active, interpretation="configured cell, runtime layer/curation may differ"))
                        if '#' in token:
                            for nested in sorted(set(re.findall(r'\b[a-z][a-z0-9_]+\b', token.split('#', 1)[1])) & set(registries)):
                                indirect.append(dict(map=map_name, layer=layer, x=x, z=z, key=nested, token=token,
                                                     interpretation="configuration mentions artifact; not a direct placement"))
        except (ValueError, AttributeError) as exc:
            map_errors.append(dict(path=path, error=str(exc)))
    errors.extend(map_errors)
    summary = dict(generated_utc=datetime.now(timezone.utc).isoformat(), root=str(root),
        scanned_files=len(manifest), source_files=sum(Path(r['path']).suffix in SOURCE for r in manifest),
        config_files=sum(Path(r['path']).suffix in CONFIG for r in manifest),
        files_by_scope=dict(Counter(r['scope'] for r in manifest)),
        source_files_by_top_level=dict(Counter(r['path'].split('/')[0] if '/' in r['path'] else '(root)' for r in manifest if Path(r['path']).suffix in SOURCE)),
        evidence_files=sum(bool(rs) for rs in by_file.values()), evidence_sites=len(occurrences),
        evidence_kinds=dict(Counter(r['kind'] for r in occurrences)),
        project_family_files={f: len({r['path'] for r in occurrences if r['scope'] == 'project' and r['kind'] in strong and r['family'] == f}) for f in sorted({r['family'] for r in occurrences})},
        embedded_scripts=len(embedded_manifest), registry_keys=len(artifacts),
        artifact_keys_with_evidence=sum(bool(a['families']) for a in artifacts),
        registry_duplicates=len(duplicates), configured_placements=len(placements),
        spine_placements_with_evidence=sum(p['in_spine'] and bool(p['families']) for p in placements),
        unresolved_by_kind=dict(Counter(r['kind'] for r in unresolved)), errors=errors,
        exclusions=sorted(skipped), excluded_directory_names=sorted(SKIP),
        excluded_report_data_files=len(skipped_data), excluded_report_data_roots=sorted(REPORT_DATA),
        scanner_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        method="Static evidence census; no claim of exhaustive semantic recognition, runtime counts, reachability, wiring correctness or VR usability.")
    out.mkdir(parents=True, exist_ok=True)
    outputs = {'summary': summary, 'files': manifest, 'occurrences': occurrences,
               'dependencies': edge_evidence, 'artifacts': artifacts, 'map-placements': placements,
               'indirect-map-references': indirect, 'unresolved': unresolved,
               'duplicate-registry-keys': duplicates, 'embedded-scripts': embedded_manifest}
    outputs['excluded-report-data'] = sorted(skipped_data)
    for name, value in outputs.items():
        (out / (name + '.json')).write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    render_report(out, summary, manifest, artifacts, placements)
    print(json.dumps(summary, indent=2))


def render_report(out, summary, manifest, artifacts, placements):
    placed = defaultdict(set)
    for p in placements:
        placed[p['key']].add(p['map'])
    rows = []
    for a in artifacts:
        if a['families']:
            rows.append(dict(artifact=a['key'], families=', '.join(a['families']), maps=', '.join(sorted(placed[a['key']])),
                             files='\n'.join(a['evidence_files'])))
    source_rows = [dict(artifact=r['path'], families=', '.join(r['families']), maps=r['scope'],
                        files=f"{r['evidence_count']} source evidence sites") for r in manifest if r['evidence_count']]
    payload = json.dumps(dict(artifacts=rows, sources=source_rows), ensure_ascii=False).replace('<', '\\u003c')
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>Ada · Interface source inventory</title><style>
body{font:16px/1.5 system-ui;background:#101619;color:#e2ebe8;margin:0;padding:32px;max-width:1500px}h1{font-size:30px}p{max-width:1000px;color:#b7c9c4}input,select{font:inherit;padding:10px;background:#243238;color:white;border:1px solid #56726e;border-radius:6px;margin:0 10px 12px 0}input{width:45%}table{width:100%;border-collapse:collapse;font-size:14px}td,th{text-align:left;vertical-align:top;padding:12px;border-bottom:1px solid #30413e}td:first-child{color:#92e3c6}th{position:sticky;top:0;background:#182225}details{max-width:520px}pre{white-space:pre-wrap;overflow-wrap:anywhere}a{color:#92e3c6}small{color:#a7bbb7}</style>
<h1>Buttons, sliders & screens</h1><p>A project-wide source inventory. The table connects registered artifacts to possible interface dependencies and configured map cells. It does <strong>not</strong> count live widgets or certify working controls. Shared factories, optional branches and inherited resources can broaden an artifact's results.</p>
<p id="stats"></p><input id="search" aria-label="Search inventory" placeholder="Find an artifact, map, family or source path…"><select id="mode" aria-label="View"><option value="artifacts">Registered artifacts</option><option value="sources">All source evidence</option></select><span id="count"></span>
<p><small>Text surfaces include labels; viewport surfaces include render targets. Neither automatically means a user-facing screen. Source view retains passive naming hints, signal connections and input polling separately in the downloadable evidence.</small></p>
<table><thead><tr><th id="nameheading">Artifact</th><th>Families</th><th id="mapheading">Configured maps</th><th>Evidence files</th></tr></thead><tbody id="body"></tbody></table>
<script>const data=PAYLOAD;const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));function draw(){const q=document.getElementById('search').value.toLowerCase(),mode=document.getElementById('mode').value;const rows=data[mode].filter(r=>Object.values(r).join(' ').toLowerCase().includes(q));document.getElementById('count').textContent=rows.length+' results';document.getElementById('nameheading').textContent=mode==='sources'?'Source file':'Artifact';document.getElementById('mapheading').textContent=mode==='sources'?'Scope':'Configured maps';document.getElementById('body').innerHTML=rows.slice(0,250).map(r=>'<tr><td>'+esc(r.artifact)+'</td><td>'+esc(r.families)+'</td><td>'+esc(r.maps)+'</td><td><details><summary>Inspect evidence</summary><pre>'+esc(r.files)+'</pre></details></td></tr>').join('');if(rows.length>250)document.getElementById('count').textContent+=' · first 250 shown; narrow the search'}document.getElementById('search').addEventListener('input',draw);document.getElementById('mode').addEventListener('change',draw);document.getElementById('stats').textContent=STATS;draw();</script></html>'''
    stats = f"{summary['source_files']:,} source files + {summary['config_files']:,} configuration files scanned · {summary['embedded_scripts']} embedded scripts · {summary['artifact_keys_with_evidence']:,} artifact keys with possible interface dependencies."
    (out / 'index.html').write_text(page.replace('PAYLOAD', payload).replace('STATS', json.dumps(stats)), encoding='utf-8')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT)
    parser.add_argument('--out', type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()
    run(args.root.resolve(), args.out.resolve())
