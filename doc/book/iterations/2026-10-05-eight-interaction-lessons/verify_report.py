"""Check this report against captured inputs; does not launch or modify the museum."""
from pathlib import Path
from hashlib import sha256
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.ids = []
        self.images = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.append(attrs['id'])
        for key in ['href', 'src']:
            if key in attrs:
                self.links.append(attrs[key])
        if tag == 'img':
            self.images.append(attrs)


def digest(p):
    return sha256(p.read_bytes()).hexdigest() if p.exists() else None


def main():
    baseline = json.loads((HERE/'baseline.json').read_text())
    report = json.loads((HERE/'report.json').read_text())
    changed_runtime = [p for p,h in baseline['runtime'].items() if digest(ROOT/p) != h]
    changed_final = [m for m,h in baseline['protected_final'].items() if digest(ROOT/'commons/maps'/m/'final.md') != h]
    problems = []
    for hall in report['halls']:
        m = hall['map']
        lesson = ROOT/'commons/maps'/m/'tutorial.md'
        if digest(lesson) != hall['tutorial_sha256'] or digest(HERE/'after'/f'{m}.md') != hall['tutorial_sha256']:
            problems.append(f'Stale lesson snapshot: {m}')
        if digest(HERE/'before'/f'{m}.md') != baseline['tutorials'][m]:
            problems.append(f'Before snapshot changed: {m}')
        for s,h in hall['source_hashes'].items():
            if digest(ROOT/s) != h:
                problems.append(f'Source changed: {s}')
        for img in hall['images']:
            if digest(HERE/img['file']) != img['sha256'] or digest(ROOT/img['source']) != img['sha256']:
                problems.append(f'Image changed: {img["file"]}')
    parser = Links()
    parser.feed((HERE/'index.html').read_text(encoding='utf-8'))
    assert len(parser.ids) == len(set(parser.ids)), 'Duplicate HTML ids'
    for link in parser.links:
        parsed = urlsplit(link)
        if parsed.scheme or parsed.netloc:
            continue
        if not parsed.path:
            if parsed.fragment and parsed.fragment not in parser.ids:
                problems.append(f'Missing anchor: {link}')
        elif parsed.path != 'checks.json' and not (HERE/unquote(parsed.path)).resolve().exists():
            problems.append(f'Missing file: {link}')
    if any(not img.get('alt') for img in parser.images):
        problems.append('Missing image alt')
    result = dict(date='2026-10-05', tutorials=len(report['halls']), topics=len(report['topics']), museum_images=len(parser.images),
                  runtime_files_compared=len(baseline['runtime']), runtime_files_changed=changed_runtime,
                  final_chapters_compared=len(baseline['protected_final']), final_chapters_changed=changed_final,
                  local_links_and_snapshots_match=not problems, problems=problems,
                  browser_render_test=False, new_headset_test=False,
                  method='Source cross-review, baseline byte hashes, image provenance, inspected image pixels and static HTML links. Existing images are archival museum captures.')
    (HERE/'checks.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))
    assert not changed_runtime and not changed_final and not problems, 'Verification failed'


if __name__ == '__main__':
    main()
