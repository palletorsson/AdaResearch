"""Show the current curtain installation on the older carousel review page."""
from pathlib import Path
from html.parser import HTMLParser
import hashlib
import json
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
PAGE = ROOT / 'doc/book/iterations/2026-10-09-carousel-the-support-moves'
WALK = ROOT / 'doc/book/iterations/2026-10-09-curtains-a-colour-walk'
RUN = ROOT / 'ada_run/encounter_pilot/SoftBodies_Carusell/curtain-confirmed'


def main():
    result = json.loads((RUN / 'report.json').read_text(encoding='utf-8'))
    assert result['passed']
    assert any(c['name'] == 'All curtain checks completed' and c['passed'] for c in result['checks'])
    log = (RUN / 'engine.log').read_text(encoding='utf-8', errors='replace')
    assert not any(s in log for s in ['SCRIPT ERROR', 'Parse Error', 'without a physics space'])
    n = len(result['checks'])
    evidence = WALK / 'evidence/current'
    evidence.mkdir(parents=True, exist_ok=True)
    for name in ['report.json', 'engine.log', 'source_manifest.json']:
        shutil.copyfile(RUN / name, evidence / name)
    for name in ['above', 'walkway', 'entrance', 'different-hems', 'rear-fit', 'parting']:
        shutil.copyfile(RUN / (name + '.png'), WALK / 'assets' / (name + '.png'))
    for source, target in [('rear-fit', 'current-curtain'), ('walkway', 'current-walkway'), ('above', 'current-curtains-above')]:
        shutil.copyfile(RUN / (source + '.png'), PAGE / 'assets' / (target + '.png'))

    # Preserve the older report and its evidence; clearly date the current view.
    section = f'''<!-- current-curtain-start -->
<section id="curtain-update" aria-label="Current curtain installation">
<p class="eyebrow">CURRENT MUSEUM · CURTAIN UPDATE · 9 OCTOBER 2026</p>
<h2>The strips now fit the doorway.</h2>
<p>The red portal below is the one in your screenshot. Its cloth now hangs from the inner crossbar and fits between the posts, with a small clearance above the floor. Beside the carousel, five coloured curtains make a walk through different attachments and lengths.</p>
<div class="pair"><figure><img src="assets/current-curtain.png" alt="Current red portal with strips inside its inner frame"><figcaption>Current red portal: fitted top and side edges. These are native captures from the running museum.</figcaption></figure><figure><img src="assets/current-walkway.png" alt="Five coloured curtains with different hanging arrangements"><figcaption>Coral: top edge. Rose: two corners. Violet: alternating single corners. Blue: long and short. Mint: an arched opening.</figcaption></figure></div>
<p class="note"><strong>{n} current native checks passed.</strong> The colliding test body passes through all five curtains; the fabric moves and its pinned tops stay attached. Physical headset testing remains open. <a href="../2026-10-09-curtains-a-colour-walk/index.html">Open the full colour walk, overhead view and before/after</a> · <a href="../2026-10-09-curtains-a-colour-walk/evidence/current/report.json">Current checks</a></p>
<hr><p class="eyebrow">EARLIER CAROUSEL LESSON REPORT — HISTORICAL IMAGES FOLLOW</p>
</section>
<!-- current-curtain-end -->'''
    path = PAGE / 'index.html'
    page = path.read_text(encoding='utf-8')
    if '<!-- current-curtain-start -->' in page:
        page = re.sub(r'<!-- current-curtain-start -->.*?<!-- current-curtain-end -->', lambda _: section, page, flags=re.S)
    else:
        assert '<main>' in page
        page = page.replace('<main>', '<main>' + section, 1)
    page = page.replace('The nearby fixed-support strips remain a comparison. They keep their existing implementation.',
                        'Earlier curtain capture, before the frame-fit repair. See the current installation at the top of this page.')
    path.write_bytes(page.encode('utf-8'))

    path = WALK / 'index.html'
    walk = path.read_text(encoding='utf-8')
    note = f'<p id="current-verification"><strong>Rechecked in the current museum: {n}/{n} checks passed.</strong> The photographs on this page are refreshed from that run. <a href="evidence/current/report.json">Current native receipt</a>. The earlier Cloth Physics regression below is retained as prior evidence.</p>'
    if 'id="current-verification"' in walk:
        walk = re.sub(r'<p id="current-verification">.*?</p>', lambda _: note, walk, flags=re.S)
    else:
        walk = walk.replace('</header>', '</header>' + note, 1)
    path.write_bytes(walk.encode('utf-8'))

    class Links(HTMLParser):
        def __init__(self, base):
            super().__init__(); self.base = base; self.count = 0
        def handle_starttag(self, tag, attrs):
            for key, value in attrs:
                if key in ['src', 'href'] and value and not value.startswith(('https:', 'http:', '#')):
                    assert (self.base / value.split('#')[0]).is_file(), value
                    self.count += 1
    counts = []
    for folder in [PAGE, WALK]:
        parser = Links(folder); parser.feed((folder / 'index.html').read_text(encoding='utf-8')); counts.append(parser.count)
    hashes = {}
    for file in ['algorithms/softbodies/cloth_straps/cloth_straps.gd', 'algorithms/softbodies/cloth_straps/cloth_straps.tscn',
                 'commons/maps/SoftBodies_Carusell/map_data.json', 'tools/probes/curtain_walkway.gd']:
        hashes[file] = hashlib.sha256((ROOT / file).read_bytes()).hexdigest()
    receipt = {'passed': True, 'native_checks': n, 'local_link_counts': counts, 'current_sources': hashes,
               'production_changes_this_pass': False, 'browser_layout_checked': False, 'headset_tested': False}
    (evidence / 'publication.json').write_text(json.dumps(receipt, indent=2), encoding='utf-8')
    print(json.dumps(receipt))


if __name__ == '__main__':
    main()
