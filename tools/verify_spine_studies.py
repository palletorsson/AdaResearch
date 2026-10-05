"""Validate installed-study joins and publication; native tests run separately.

Run after publish_spine_studies.py, the book exports and build_tutorial_lineage.py.
--refresh-provenance records a new source snapshot after deliberate changes.
--http verifies local review links against the running book server.
"""
from pathlib import Path
from collections import Counter
from datetime import datetime, timezone
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote, quote
from urllib.request import urlopen
import argparse, hashlib, json, re, sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-02-studies-in-the-spine'
BEFORE = OUT / 'before'
LINEAGE = ROOT / 'doc/book/iterations/2026-09-29-tutorial-lineage/lineage.json'


def read(path):
    return Path(path).read_text(encoding='utf-8-sig')


def data(path):
    return json.loads(read(path))


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def tokens(layer):
    return Counter(str(c).split(':')[0].split('#')[0] for row in layer for c in row if str(c).strip())


class Links(HTMLParser):
    def __init__(self, text):
        super().__init__()
        self.refs, self.ids = [], set()
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        d = dict(attrs)
        if 'id' in d:
            self.ids.add(d['id'])
        for key in ['src', 'href']:
            if key in d:
                self.refs.append(d[key])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--http', action='store_true')
    parser.add_argument('--refresh-provenance', action='store_true')
    args = parser.parse_args()
    checks = []
    sources = set()

    def check(name, passed, detail=None):
        entry = dict(name=name, passed=bool(passed))
        if detail is not None:
            entry['detail'] = detail
        checks.append(entry)

    def record(path):
        path = Path(path)
        if path.is_file():
            sources.add(path)

    manifest = data(ROOT / 'doc/book/recent-studies.json')
    studies = manifest['studies']
    ids = {s['id'] for s in studies}
    halls = {s['map'] for s in studies}
    check('Nineteen installed studies in sixteen halls', len(ids) == 19 and len(halls) == 16)
    registry = {}
    for name in ['reference_studies', 'signal_room']:
        path = ROOT / f'commons/artifacts/registry/{name}.json'
        record(path)
        registry.update(data(path)['artifacts'])
    roles = data(ROOT / 'commons/data/artifact_roles.json')['roles']
    core = data(ROOT / 'commons/data/museum_core_encounters.json')['rooms']
    lineage = data(LINEAGE)
    check('Lineage publishes every installed study', {s['id'] for s in lineage['applications']} == ids)
    check('Sweep adds one later geometry capability', lineage['counts']['capabilities'] == 72)
    atlas = read(ROOT / 'doc/book/tutorial-lineage/atlas.html')
    check('Applications visible by hall and capability', 'applicationList(n.applications)' in atlas and 'applicationList(h.applications)' in atlas)
    native_total = 0

    for hall in sorted(halls):
        rel = Path('commons/maps') / hall / 'map_data.json'
        path = ROOT / rel
        current, old = data(path), data(BEFORE / rel)
        layers = current['layers']
        dimensions = current['map_info']['dimensions']
        check(hall + ': rectangular layers match dimensions', all(len(layer) == dimensions['depth'] and all(len(row) == dimensions['width'] for row in layer) for layer in layers.values()))
        previous = tokens(old['layers']['interactables'])
        installed = tokens(layers['interactables'])
        check(hall + ': existing artifacts retained', not (previous - installed))
        # Old authored cells stay in place; bays may widen the rows and move the exit.
        check(hall + ': old artifact positions retained', all(layers['interactables'][z][x] == c for z, row in enumerate(old['layers']['interactables']) for x, c in enumerate(row) if str(c).strip()))
        report = data(OUT / 'figures' / f'{hall}-report.json')
        native_total += len(report['checks'])
        check(hall + ': native museum checks', report['passed'] and all(c['passed'] for c in report['checks']), len(report['checks']))
        log = read(OUT / 'figures' / f'{hall}-engine.log') + '\n' + read(OUT / 'figures' / f'{hall}-godot.log')
        errors = [line for line in log.splitlines() if re.search(r'(?:SCRIPT ERROR|^ERROR):', line)]
        check(hall + ': native log has no engine/script errors', not errors, errors)
        check(hall + ': current room hashes', core[hall]['map_sha256'] == digest(path) and core[hall]['text_sha256'] == digest(path.with_name('final.md')))
        for p in path.parent.glob('*.md'):
            if p.name in ['final.md','tutorial.md','intent.md','technical.md','summary.md','critical.md','artifacts.md']:
                record(p)
        record(path)

    for study in studies:
        key, hall = study['id'], study['map']
        current = data(ROOT / f'commons/maps/{hall}/map_data.json')
        scene = ROOT / study['scene'].removeprefix('res://')
        reg = registry[key]
        check(key + ': registered production adapter', reg['scene'] == study['scene'] and reg['map_ready'] and reg['include_in_map_data'] and scene.is_file())
        x, z = study['placement']['cell']
        check(key + ': single authored token at declared cell', tokens(current['layers']['interactables'])[key] == 1 and current['layers']['interactables'][z][x].startswith(key + ':'))
        check(key + ': secondary encounter recorded', roles[hall][key] == 'secondary' and key in core[hall]['application_tokens'])
        for name in ['final','tutorial','intent','technical','summary','critical','artifacts']:
            text = read(ROOT / f'commons/maps/{hall}/{name}.md')
            check(key + ': one ' + name + ' passage', text.count('<!-- study-spine:' + key + ' -->') == 1)
        tutorial = read(ROOT / f'commons/maps/{hall}/tutorial.md')
        check(key + ': one concrete source edit', tutorial.count('<!-- study-edit:' + key + ' -->') == 1)
        image = OUT / study['capture']
        check(key + ': native PNG', image.is_file() and image.read_bytes()[:8] == b'\x89PNG\r\n\x1a\n' and image.stat().st_size > 10000)
        record(scene)

    for seq in {s['sequence'] for s in studies}:
        rel = Path(f'commons/maps/sequences/{seq}.json')
        current, old = data(ROOT / rel)['sequences'][seq], data(BEFORE / rel)['sequences'][seq]
        check(seq + ': sequence order retained', current['maps'] == old['maps'])
        subset = [s for s in studies if s['sequence'] == seq]
        check(seq + ': studies declared in their halls', all(s['map'] in current['maps'] and any(g['map'] == s['map'] and s['id'] in g['artifacts'] for g in current['artifact_groups']) for s in subset))
        capture = ROOT / f'doc/book/captures/{seq}/{seq}-book.manifest.json'
        captured = data(capture)
        check(seq + ': book capture current', captured['sequence_sha256'] == digest(ROOT / rel) and all(digest(ROOT / s['path']) == s['sha256'] for s in captured['maps']))
        record(ROOT / rel)

    for existing in manifest['already_installed']:
        current = data(ROOT / f'commons/maps/{existing["map"]}/map_data.json')
        check(existing['id'] + ': prior installation retained', tokens(current['layers']['interactables'])[existing['id']] >= 1)

    # Include adapter dependencies, implementation, maps, text and reproducible tooling.
    for folder in ['spine_studies','reference_studies','bicho_hinge','colour_assembly','colour_wall_studies','conical_sightline','signal_room','kapoor_void_studies']:
        for p in (ROOT / 'commons/artifacts' / folder).rglob('*'):
            if p.suffix in ['.gd','.gdshader','.tscn','.tres']:
                record(p)
    for rel in ['doc/book/recent-studies.json','commons/data/artifact_roles.json','commons/data/museum_core_encounters.json','commons/maps/curriculum_spine.json','doc/book/tutorial-lineage/atlas.html','doc/book/tutorial-lineage/curriculum.json','commons/testing/capture_spine_studies.gd','tools/capture_spine_studies.py','tools/integrate_recent_studies.py','tools/publish_spine_studies.py','tools/build_tutorial_lineage.py','tools/verify_spine_studies.py','tools/relations_studies.py','tools/publish_relations_studies.py']:
        record(ROOT / rel)
    hashes = {p.relative_to(ROOT).as_posix(): digest(p) for p in sorted(sources)}
    for rel in ['commons/testing/tension_checks.gd','tools/tension_study.py','tools/publish_tension_study.py','commons/testing/paired_time_checks.gd','tools/paired_time_study.py','tools/publish_paired_time_study.py']:
        hashes[rel] = digest(ROOT/rel)
    for rel in ['commons/testing/tube_painting_checks.gd','tools/tube_painting_study.py','tools/publish_tube_painting.py']:
        hashes[rel] = digest(ROOT/rel)
    for rel in ['commons/testing/run_network_checks.gd','commons/testing/part_library_checks.gd','algorithms/wavefunctions/line_builder_3d/cable_builder.gd','commons/glass_rack/GlassRackController.gd','commons/glass_rack/GlassPipeSegments.gd']:
        hashes[rel] = digest(ROOT/rel)
    for p in (ROOT/'commons/audio/cables').glob('*.gd'):
        record(p)
    for rel in ['commons/audio/EurorackRack.gd','commons/audio/EurorackModule.gd','commons/audio/UniversalVRAudioController.gd','commons/audio/eurorack_modules/module_library.json','commons/audio/rack_controls/vr_wrappers/ModuleFaceTexture.gd','commons/testing/patch_motion_checks.gd','tools/publish_patch_motion.py']:
        record(ROOT/rel)
    for p in (ROOT/'commons/primitives/pipes').glob('*.gd'):
        hashes[p.relative_to(ROOT).as_posix()] = digest(p)
    for rel in ['commons/testing/pipe_ceiling_checks.gd','tools/publish_pipe_ceiling.py']:
        hashes[rel] = digest(ROOT/rel)
    provenance = OUT / 'provenance.json'
    if args.refresh_provenance or not provenance.exists():
        provenance.write_text(json.dumps(dict(recorded_at=datetime.now(timezone.utc).isoformat(),scope='Current integration source snapshot recorded after the native checks. Companion viewers are included as dependencies, not claimed as museum input handlers.',sources_sha256=hashes,native_reports_sha256={p.name:digest(p) for p in sorted((OUT/'figures').glob('*-report.json'))},images_sha256={p.name:digest(p) for p in sorted((OUT/'figures').glob('*.png'))}),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    saved = data(provenance)
    check('Source snapshot current', saved['sources_sha256'] == hashes)
    check('Native report snapshot current', all(digest(OUT/'figures'/name)==sha for name,sha in saved['native_reports_sha256'].items()))
    check('Native image snapshot current', all(digest(OUT/'figures'/name)==sha for name,sha in saved['images_sha256'].items()))

    # Create the result target before checking its link; rewrite with the completed result below.
    result_path = OUT / 'verification.json'
    if not result_path.exists():
        result_path.write_text('{}\n',encoding='utf-8')
    page = OUT / 'index.html'
    parsed = Links(read(page))
    check('All study sections in review', ids <= parsed.ids)
    targets = {page}
    for ref in sorted(set(parsed.refs)):
        u = urlsplit(ref)
        if u.scheme or ref.startswith('/tutorial-lineage'):
            continue
        p = ROOT / unquote(u.path.removeprefix('/book-review/')) if ref.startswith('/book-review/') else (page.parent / unquote(u.path)).resolve() if u.path else page
        ok = p.is_file()
        if ok and u.fragment and p.suffix == '.html':
            ok = unquote(u.fragment) in Links(read(p)).ids
        check('Review link ' + ref, ok)
        if p.is_file():
            targets.add(p)
    # The current three-study page has its own making links and evidence.
    new_review = ROOT / 'doc/book/iterations/2026-10-02-relations-sentences-and-witnesses/index.html'
    targets.add(new_review)
    for ref in sorted(set(Links(read(new_review)).refs)):
        u = urlsplit(ref)
        if u.scheme or ref.startswith('/tutorial-lineage'):
            continue
        p = ROOT / unquote(u.path.removeprefix('/book-review/')) if ref.startswith('/book-review/') else (new_review.parent / unquote(u.path)).resolve() if u.path else new_review
        ok = p.is_file()
        if ok and u.fragment and p.suffix == '.html':
            ok = unquote(u.fragment) in Links(read(p)).ids
        check('New review link ' + ref, ok)
        if p.is_file(): targets.add(p)
    for key,hall in [('evidence_network','GT_Network_Analysis'),('sentence_authority','Crisis_Synthesis'),('museum_witnesses','SpeculativeComputation_Situated_Computation')]:
        companion = new_review.parent / (key+'-making.html')
        check(key + ': current making snapshot', digest(ROOT / 'commons/maps' / hall / 'tutorial.md') in read(companion))
    tension_review = ROOT/'doc/book/iterations/2026-10-02-nengudi-a-little-give/index.html'
    targets.add(tension_review)
    for ref in sorted(set(Links(read(tension_review)).refs)):
        u = urlsplit(ref)
        if u.scheme or ref.startswith('/tutorial-lineage'): continue
        p = (tension_review.parent/unquote(u.path)).resolve() if u.path else tension_review
        ok = p.is_file()
        if ok and u.fragment and p.suffix == '.html': ok = unquote(u.fragment) in Links(read(p)).ids
        check('Tensile review link '+ref,ok)
        if p.is_file(): targets.add(p)
    check('tension_membrane: current making snapshot', digest(ROOT/'commons/maps/SoftBodies_Cloth_Physics/tutorial.md') in read(tension_review.parent/'making.html'))
    paired_review = ROOT/'doc/book/iterations/2026-10-02-gonzalez-torres-a-second-together/index.html'
    targets.add(paired_review)
    for ref in sorted(set(Links(read(paired_review)).refs)):
        u = urlsplit(ref)
        if u.scheme or ref.startswith('/tutorial-lineage'): continue
        p = (paired_review.parent/unquote(u.path)).resolve() if u.path else paired_review
        ok = p.is_file()
        if ok and u.fragment and p.suffix == '.html': ok = unquote(u.fragment) in Links(read(p)).ids
        check('Paired time review link '+ref,ok)
        if p.is_file(): targets.add(p)
    check('paired_time: current making snapshot', digest(ROOT/'commons/maps/Change_Choreography/tutorial.md') in read(paired_review.parent/'making.html'))
    tube_review = ROOT/'doc/book/iterations/2026-10-02-tube-painting-a-line-takes-room/index.html'
    targets.add(tube_review)
    targets.add(ROOT/'doc/book/iterations/2026-10-02-patch-and-motion/index.html')
    ceiling_review = ROOT/'doc/book/iterations/2026-10-02-glossy-pipe-ceiling/index.html'
    targets.add(ceiling_review)
    for ref in sorted(set(Links(read(ceiling_review)).refs)):
        u = urlsplit(ref)
        if u.scheme or ref.startswith('/tutorial-lineage'): continue
        p = (ceiling_review.parent/unquote(u.path)).resolve() if u.path else ceiling_review
        ok = p.is_file()
        if ok and u.fragment and p.suffix == '.html': ok = unquote(u.fragment) in Links(read(p)).ids
        check('Ceiling review link '+ref,ok)
        if p.is_file(): targets.add(p)
    for name in ['weave','ribs','returns']:
        p = ceiling_review.parent/(name+'.png')
        check('Ceiling capture '+name,p.is_file())
        targets.add(p)
    for ref in sorted(set(Links(read(tube_review)).refs)):
        u = urlsplit(ref)
        if u.scheme or ref.startswith('/tutorial-lineage'): continue
        p = (tube_review.parent/unquote(u.path)).resolve() if u.path else tube_review
        ok = p.is_file()
        if ok and u.fragment and p.suffix == '.html': ok = unquote(u.fragment) in Links(read(p)).ids
        check('Tube review link '+ref,ok)
        if p.is_file(): targets.add(p)
    check('tube_painting: current making snapshot', digest(ROOT/'commons/maps/LSystems_Grammars_And_Curves/tutorial.md') in read(tube_review.parent/'making.html'))
    check('sweep has the intended earlier prerequisites', next(n for n in lineage['nodes'] if n['id']=='sweep')['requires'] == ['trace','mesh','refinement','rotation','array'])
    if args.http:
        # No remote artwork is fetched. These are the local publication's own files.
        for p in sorted(targets):
            route = 'http://localhost:3003/book-review/' + quote(p.relative_to(ROOT).as_posix(),safe='/')
            try:
                body = urlopen(route, timeout=15).read()
                check('Served bytes ' + p.relative_to(ROOT).as_posix(), body == p.read_bytes())
            except Exception as error:
                check('Served bytes ' + p.relative_to(ROOT).as_posix(), False, str(error))
        try:
            body = urlopen('http://localhost:3003/tutorial-lineage',timeout=15).read().decode('utf-8')
            check('Lineage route serves installed applications', 'hinge_release' in body and 'colour_wall_studies' in body and 'applicationList(n.applications)' in body)
        except Exception as error:
            check('Lineage route serves installed applications', False, str(error))
    result = dict(passed=all(c['passed'] for c in checks), checked_at=datetime.now(timezone.utc).isoformat(),studies=len(ids),halls=len(halls),native_checks=native_total,publication_checks=len(checks),http_checked=args.http,scope='Source joins, retained placement/order, book exports, links and native evidence. No rendered-browser, full human traversal, physical XR or learner certification.',checks=checks)
    result_path.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:v for k,v in result.items() if k!='checks'}))
    for check_result in checks:
        if not check_result['passed']:
            print('FAIL',check_result)
    return 0 if result['passed'] else 1


if __name__ == '__main__':
    sys.exit(main())
