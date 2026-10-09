"""Compile the current Primitives manuscripts as facing pages; never edit sources."""
from pathlib import Path
from urllib.parse import urlsplit, unquote, quote
from html import escape
import hashlib
import json
import re
import shutil

import markdown
from markdown.extensions import Extension
from markdown.inlinepatterns import SimpleTagInlineProcessor
from bs4 import BeautifulSoup

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
BASE = 'http://localhost:3003'
SEQUENCE = ROOT / 'commons/maps/sequences/primitives.json'
INTENTS = {'Primitives_Godot', 'Primitives_Columns', 'Primitives_Profiles'}
LABELS = ['Point Zero', 'Point One', 'Coordinates', 'Lines', 'Trace', 'Grid',
          'Triangle', 'Polyhedra', 'Cube', 'Primitives', 'Godot primitives',
          'Columns', 'Borrowed outlines', 'Limits', 'Melencolia']


class Strike(Extension):
    def extendMarkdown(self, md):
        md.inlinePatterns.register(SimpleTagInlineProcessor(r'(~~)(.+?)~~', 'del'), 'strikethrough', 175)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    sequence = json.loads(SEQUENCE.read_text(encoding='utf-8-sig'))['sequences']['primitives']
    maps = sequence['maps']
    assert len(maps) == len(LABELS)
    manifest = {'chapter': sequence['name'], 'compiled': '2026-10-05',
                'sequence_sha256': sha(SEQUENCE), 'sources': [], 'halls': maps}
    broken = []
    paired_paths = {(ROOT / 'commons/maps' / name / file).resolve(): (name, side)
                    for name in maps for file, side in [('tutorial.md', 'tutorial'), ('final.md', 'final')]}
    page_files = {name: 'index.html' if i == 0 else name + '.html' for i, name in enumerate(maps)}
    references = {}

    def link(url, source, prefix, is_image=False):
        if url.startswith('#'):
            return '#' + prefix + url[1:]
        parsed = urlsplit(url)
        if parsed.scheme or parsed.netloc:
            return url
        if parsed.path.startswith('/book-review/'):
            dest = ROOT / unquote(parsed.path.removeprefix('/book-review/'))
        elif parsed.path.startswith('/'):
            return BASE + url
        else:
            dest = (source.parent / unquote(parsed.path)).resolve()
        if not dest.is_relative_to(ROOT) or not dest.is_file():
            broken.append({'source': str(source.relative_to(ROOT)), 'target': url})
            return url
        if dest.resolve() in paired_paths and not is_image:
            name, side = paired_paths[dest.resolve()]
            return page_files[name] + ('#' + name + '--' + side + '--' + parsed.fragment if parsed.fragment else '')
        # The read-only review server serves iteration evidence, figures and canonical
        # manuscripts. Snapshot other local references here without broadening access.
        rel = dest.relative_to(ROOT).as_posix()
        if not rel.startswith(('doc/book/iterations/', 'doc/book/figures/')):
            if dest not in references:
                local = 'references/' + hashlib.sha256(rel.encode()).hexdigest()[:12] + '-' + dest.name
                target = HERE / local
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(dest, target)
                references[dest] = local
            return quote(references[dest], safe='/') + ('#' + parsed.fragment if parsed.fragment else '')
        return (BASE + '/book-review/' + quote(dest.relative_to(ROOT).as_posix(), safe='/')
                + ('?' + parsed.query if parsed.query else '')
                + ('#' + parsed.fragment if parsed.fragment else ''))

    def render(name, side):
        file = 'tutorial.md' if side == 'tutorial' else 'final.md'
        path = ROOT / 'commons/maps' / name / file
        prefix = name + '--' + side + '--'
        content = path.read_text(encoding='utf-8-sig')
        snapshot = HERE / 'sources' / name / file
        snapshot.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, snapshot)
        raw = markdown.markdown(content, extensions=['extra', 'toc', 'sane_lists', Strike()])
        soup = BeautifulSoup(raw, 'html.parser')
        original_text = soup.get_text()
        for node in soup.find_all(True):
            if node.get('id'):
                node['id'] = prefix + node['id']
            for attr in ('href', 'src'):
                if node.get(attr):
                    node[attr] = link(node[attr], path, prefix, node.name == 'img')
            if node.name == 'a' and node.get('href', '').startswith(('http:', 'https:')):
                node['target'] = '_blank'
                node['rel'] = 'noopener'
            if node.name == 'img':
                node['loading'] = 'lazy'
        assert soup.get_text() == original_text, 'Visible source text was changed'
        manifest['sources'].append({'map': name, 'side': side, 'path': path.relative_to(ROOT).as_posix(),
                                    'sha256': sha(path), 'snapshot': snapshot.relative_to(HERE).as_posix(),
                                    'code_blocks': len(soup.select('pre')), 'images': len(soup.select('img'))})
        return str(soup)

    spreads = []
    for i, (name, label) in enumerate(zip(maps, LABELS)):
        pages = []
        for side, description, file in [('tutorial', 'Make / tutorial.md', 'tutorial.md'),
                                         ('final', 'Reflect / final.md', 'final.md')]:
            body = render(name, side)
            status = '<span class="intent">Teaching intent</span>' if side == 'tutorial' and name in INTENTS else ''
            source = BASE + '/book-review/commons/maps/' + name + '/' + file
            pages.append(f'''<article class="page {side}" tabindex="0" aria-label="{escape(label)} — {side}">
              <div class="running-head"><span>{description}</span>{status}<a href="{source}" target="_blank" rel="noopener">Source ↗</a></div>
              <div class="prose">{body}</div>
              <div class="page-end">{escape(label)} <span>{'Tutorial' if side == 'tutorial' else 'Reflection'}</span></div>
            </article>''')
        spreads.append(f'<section class="spread" data-map="{name}" data-label="{escape(label)}" aria-label="{escape(label)} facing pages">{"".join(pages)}</section>')

    template = (HERE / 'template.html').read_text(encoding='utf-8')
    soup = BeautifulSoup(''.join(spreads), 'html.parser')
    ids = [node['id'] for node in soup.select('[id]')]
    assert len(ids) == len(set(ids)), 'Duplicate document IDs'
    missing_fragments = [a['href'] for a in soup.select('a[href^="#"]')
                         if not a['href'].startswith('#map=') and a['href'][1:] not in ids]
    assert not missing_fragments, missing_fragments
    assert not broken, broken
    assert len(soup.select('.spread')) == 15 and len(soup.select('.page')) == 30
    for i, (name, label) in enumerate(zip(maps, LABELS)):
        contents = '\n'.join(f'<li><a href="{page_files[m]}" {"aria-current=page" if n == i else ""}><span>{n+1:02d}</span> {escape(l)}</a></li>' for n, (m, l) in enumerate(zip(maps, LABELS)))
        previous = f'<a class="nav-button" aria-label="Previous hall" href="{page_files[maps[i-1]]}">← Previous</a>' if i else '<span class="nav-button disabled" aria-disabled="true">← Previous</span>'
        following = f'<a class="nav-button" aria-label="Next hall" href="{page_files[maps[i+1]]}">Next →</a>' if i < len(maps)-1 else '<span class="nav-button disabled" aria-disabled="true">Next →</span>'
        result = (template.replace('<!-- CONTENTS -->', contents).replace('<!-- SPREADS -->', spreads[i])
                  .replace('<!-- PREVIOUS -->', previous).replace('<!-- NEXT -->', following)
                  .replace('<!-- HALL -->', f'{i+1:02d} · {escape(label)}')
                  .replace('<!-- POSITION -->', f'{i+1:02d} / {len(maps)} · {escape(label)}')
                  .replace('<!-- TITLE -->', escape(label)))
        (HERE / page_files[name]).write_text(result, encoding='utf-8')
    assert all(sha(ROOT / item['path']) == item['sha256'] for item in manifest['sources'])
    manifest['checks'] = {'pairs': 15, 'texts': 30, 'source_text_preserved': True,
                          'canonical_files_unchanged': True, 'local_references_resolve': True,
                          'unique_fragment_ids': True, 'all_internal_fragments_resolve': True}
    manifest['pages'] = page_files
    (HERE / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(manifest['checks']))


if __name__ == '__main__':
    main()
