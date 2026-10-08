"""Verify the twenty-film addition against its saved pre-edit baseline."""
import hashlib
import build_spine_films as build


def main():
    root, out, run = build.ROOT, build.OUT, build.RUN
    baseline = build.read(run/'more-baseline.json')
    catalog = build.read(build.BASE/'catalog.json')
    added = [e for e in catalog if e.get('collection') == 'more']
    assert len(added) == 20 and len(catalog) == 46
    assert set(baseline['films']) == {e['id'] for e in catalog if e.get('collection') != 'more'}
    altered = [p for p, digest in baseline['protected'].items()
               if hashlib.sha256((root/p).read_bytes()).hexdigest() != digest]
    assert not altered, altered
    new_tokens = {'film_'+e['id'] for e in added}
    def remove_new(value):
        if isinstance(value, dict):
            return {k: remove_new(v) for k, v in value.items()}
        if isinstance(value, list):
            return [remove_new(v) for v in value if not
                    (isinstance(v, dict) and str(v.get('token','')).split(':')[0] in new_tokens)]
        return value
    for rel, prior in baseline['museum_before'].items():
        assert remove_new(build.read(root/rel)) == prior, 'Existing museum data changed: '+rel
    results = []
    preserved_count = 0
    for entry in added:
        folder = out/entry['id']
        stage = build.read(folder/'report.json')
        movie = build.read(folder/'film-report.json')
        museum = build.read(folder/'museum-report.json')
        validation = build.read(folder/'validation.json')
        assert stage['passed'] and museum['passed'] and validation['passed'], entry['id']
        assert len(museum['checks']) >= 17
        assert movie['decode_exit'] == 0 and movie['bytes'] == (folder/'film.mp4').stat().st_size
        assert movie['frames'] == round(movie['fps']*stage['duration'])
        for asset in ['museum.png','poster.png',*[f'phase-{i:02d}.png' for i in range(len(stage['phases']))]]:
            assert (folder/asset).stat().st_size > 0, (entry['id'],asset)
        before = build.read(out/'backups'/entry['map']/'map.json')
        after = build.read(root/'commons/maps'/entry['map']/'map_data.json')
        def items(data):
            return {(x,z):str(v) for z,row in enumerate(data['layers']['interactables'])
                    for x,v in enumerate(row) if str(v).strip() not in ('','0') and
                    str(v).split(':')[0] not in new_tokens}
        assert items(before) == items(after), 'Existing map artifacts moved: '+entry['map']
        assert before['layers']['structure'] == after['layers']['structure'], entry['map']
        preserved_count += len(items(before))
        results.append({'id':entry['id'], 'passed':True, 'seconds':stage['duration'],
                        'phases':len(stage['phases']), 'museum_checks':len(museum['checks'])})
    visual = build.read(run/'more-visual-review.json')
    assert set(visual['stage_films']) == {e['id'] for e in added}
    assert set(visual['museum_films']) == {e['id'] for e in added}
    assert visual['passed']
    summary = {'passed':True,'new_films':20,'total_films':46,'films':results,
               'protected_files_unchanged':len(baseline['protected']),
               'existing_map_artifacts_preserved':preserved_count,
               'new_seconds':sum(r['seconds'] for r in results),
               'museum_checks':sum(r['museum_checks'] for r in results),
               'visual_review':visual,'headset_verified':False}
    build.write(out/'expansion-verification.json',summary)
    print('20 new films verified; 46 total. Original sources, text and museum content preserved.')


if __name__ == '__main__':
    main()
