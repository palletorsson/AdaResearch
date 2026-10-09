"""Verify this process article, images, links and native blog discovery."""
from pathlib import Path
from urllib.request import urlopen
from hashlib import sha256
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SLUG = '2026-10-06-drawing-the-book-back-into-the-room'
POST = ROOT.parent / 'ada_encyclopedia/src/content/blog' / (SLUG + '.md')
text = POST.read_text(encoding='utf-8')
urls = sorted(set(re.findall(r'\]\((/[^)]+)\)', text)) | {'/blog', '/blog/' + SLUG})
results = []
for url in urls:
    with urlopen('http://localhost:3003' + url, timeout=45) as response:
        assert response.status == 200, url
        results.append({'url': url, 'status': response.status})
        if url == '/blog':
            assert SLUG in response.read().decode('utf-8')
        elif url == '/blog/' + SLUG:
            html = response.read().decode('utf-8')
            assert 'Drawing the book back into the room' in html
            assert html.count('<img ') == 3
            assert 'The picture becomes useful when it makes us look again.' in html

report = {'post': str(POST), 'sha256': sha256(POST.read_bytes()).hexdigest(),
          'urls': results, 'blog_index': True, 'rendered_images': 3,
          'scope': 'Process article and backlink only; no museum logic or source chapters changed.'}
(HERE / 'checks.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(f'Article indexed; three illustrations rendered; {len(results)} URLs return 200.')
