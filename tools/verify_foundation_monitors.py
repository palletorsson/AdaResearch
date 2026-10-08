"""Verify the six browser-study ports and preserve the existing museum work."""
import hashlib
import build_spine_films as build


def main():
    root, out = build.ROOT, build.OUT
    run = root/'ada_run/foundation_monitors'
    baseline = build.read(run/'baseline.json')
    catalog = build.read(build.BASE/'catalog.json')
    added = [e for e in catalog if e.get('collection') == 'foundation']
    assert len(added) == 6
    assert {e['id'] for e in catalog if e.get('collection') != 'foundation'} == set(baseline['previous_ids'])
    altered = [p for p, digest in baseline['protected'].items()
               if hashlib.sha256((root/p).read_bytes()).hexdigest() != digest]
    assert not altered, altered
    tokens = {'film_'+e['id'] for e in added}

    def without_new(value):
        if isinstance(value, dict):
            return {k: without_new(v) for k, v in value.items()}
        if isinstance(value, list):
            return [without_new(v) for v in value if not
                    (isinstance(v, dict) and str(v.get('token','')).split(':')[0] in tokens)]
        return value

    for path, original in baseline['plans'].items():
        assert without_new(build.read(root/path)) == original, path
    for name, original in baseline['maps'].items():
        current = build.read(root/'commons/maps'/name/'map_data.json')
        def items(data):
            return {(x,z):str(value) for z,row in enumerate(data['layers']['interactables'])
                    for x,value in enumerate(row) if str(value).strip() not in ('','0')
                    and str(value).split(':')[0] not in tokens}
        assert items(original) == items(current), name
        for layer in original['layers']:
            if layer != 'interactables':
                assert original['layers'][layer] == current['layers'][layer], (name,layer)
    controls = build.read(run/'controls-report.json')
    assert controls['passed'] and len(controls['monitors']) == 6
    results = []
    for entry in added:
        folder = out/entry['id']
        for report in ['report.json','validation.json','museum-report.json']:
            assert build.read(folder/report)['passed'], (entry['id'],report)
        movie = build.read(folder/'film-report.json')
        assert movie['decode_exit'] == 0 and movie['bytes'] == (folder/'film.mp4').stat().st_size
        assert movie['frames'] == round(build.read(folder/'report.json')['duration']*movie['fps'])
        results.append({'id':entry['id'],'map':entry['map'],'passed':True})
    visual = build.read(run/'visual-review.json')
    assert visual['passed'] and set(visual['films']) == {e['id'] for e in added}
    report = {'passed':True,'added':6,'catalog_total':len(catalog),'films':results,
              'protected_files_unchanged':len(baseline['protected']),
              'prior_films_preserved':len(baseline['previous_ids']),
              'control_checks':sum(len(m['checks']) for m in controls['monitors']),
              'visual_review':visual,'headset_verified':False}
    build.write(out/'foundation-verification.json',report)
    print('Six interactive monitors verified; original exhibits, films and manuscripts preserved.')


if __name__ == '__main__':
    main()
