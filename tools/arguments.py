"""arguments.py - the authored cardboard arguments (commons/data/arguments/<hall>.json): check them, and draw one.

An argument file is the thinking for one hall, written in the first person to be laid out with the sticker app: plates
(cardboard walls with marker notes), stickers, red threads with a word each, and the visual arguments to be built
from prefabs. This tool is a reader, not a renderer of record: the sticker app draws the real thing.

  python tools/arguments.py --check                 every file: ids, thread ends, plates near rows that exist, and
                                                    every sticker of kind 'quote' word for word in its hall text
  python tools/arguments.py --sheet=<Hall>          a working drawing: the floor plan with the plates, threads and
                                                    visual arguments round the hero, and the plates' text as cards
                                                    -> ada_run/arguments/<Hall>.png

Exit code of --check = number of findings.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIR = ROOT / 'commons/data/arguments'


def even(text):
    """Emphasis marks, curly quotes and runs of whitespace evened out, as the sticker seed reads a hall text."""
    text = re.sub(r'<!--.*?-->', ' ', text, flags=re.S)
    text = text.replace('\u2019', "'").replace('\u2018', "'").replace('\u201c', '"').replace('\u201d', '"')
    text = re.sub(r'[*_]', '', text)
    return re.sub(r'\s+', ' ', text).strip()


def check(path):
    findings = []
    doc = json.loads(path.read_text(encoding='utf-8'))
    hall = doc.get('hall', '')
    floors = json.loads((ROOT / 'commons/void/rooms.json').read_text(encoding='utf-8'))['floors']
    floor = next((f for f in floors if f.get('map') == hall), None)
    if floor is None:
        return ['%s: no tower floor is called %s' % (path.name, hall)]
    rows = {a['id'] for a in floor.get('artifacts', [])}
    visuals = {'visual:' + v['id'] for v in doc.get('visual_arguments', [])}
    if doc.get('hero', {}).get('row') not in rows:
        findings.append('%s: the hero row %s is not on the floor' % (path.name, doc.get('hero', {}).get('row')))
    plates = {}
    for p in doc.get('plates', []):
        if p['id'] in plates:
            findings.append('%s: plate %s twice' % (path.name, p['id']))
        plates[p['id']] = p
        if p.get('by') not in rows and p.get('by') not in visuals:
            findings.append('%s: plate %s stands by %s, which is neither a row of the floor nor one of its visual arguments' % (path.name, p['id'], p.get('by')))
        if not (abs(p['at'][0]) <= 21 and abs(p['at'][1]) <= 9.5):
            findings.append('%s: plate %s stands off the slab at %s' % (path.name, p['id'], p['at']))
    seen = set()
    for s in doc.get('stickers', []):
        if s['id'] in seen:
            findings.append('%s: sticker %s twice' % (path.name, s['id']))
        seen.add(s['id'])
        if s.get('plate') not in plates:
            findings.append('%s: sticker %s is on no plate (%s)' % (path.name, s['id'], s.get('plate')))
        if s.get('kind') == 'quote':
            file = ROOT / s.get('file', '')
            if not file.is_file():
                findings.append('%s: sticker %s quotes a file that is gone: %s' % (path.name, s['id'], s.get('file')))
                continue
            text = even(file.read_text(encoding='utf-8'))
            if even(s.get('quote', '')) not in text:
                findings.append('%s: sticker %s: its quote is no longer in %s' % (path.name, s['id'], s.get('file')))
            for half in (s.get('a'), s.get('b')):
                if half and even(half) not in even(s.get('quote', '')):
                    findings.append('%s: sticker %s letters more than its quote: %r' % (path.name, s['id'], half))
        elif not s.get('text'):
            findings.append('%s: sticker %s has no words' % (path.name, s['id']))
    for t in doc.get('threads', []):
        for end in (t.get('a'), t.get('b')):
            if end not in plates:
                findings.append('%s: a thread ends on no plate (%s)' % (path.name, end))
        if not t.get('word') or not t.get('why'):
            findings.append('%s: the thread %s - %s has no word or no why' % (path.name, t.get('a'), t.get('b')))
    return findings


def sheet(hall):
    from PIL import Image, ImageDraw, ImageFont
    doc = json.loads((DIR / (hall + '.json')).read_text(encoding='utf-8'))
    floors = json.loads((ROOT / 'commons/void/rooms.json').read_text(encoding='utf-8'))['floors']
    floor = next(f for f in floors if f.get('map') == hall)

    def font(size, bold=False):
        for name in (('segoeprb.ttf' if bold else 'segoepr.ttf'), 'Inkfree.ttf', 'comic.ttf', 'arial.ttf'):
            try:
                return ImageFont.truetype('C:/Windows/Fonts/' + name, size)
            except OSError:
                continue
        return ImageFont.load_default()

    def wrap(draw, text, fnt, width):
        out, line = [], ''
        for word in text.split():
            trial = (line + ' ' + word).strip()
            if draw.textlength(trial, font=fnt) <= width:
                line = trial
            else:
                if line:
                    out.append(line)
                line = word
        if line:
            out.append(line)
        return out

    W, PLAN_H, CARD_W, CARD_H = 2600, 1180, 520, 640
    plates = doc['plates']
    rows_of_cards = (len(plates) + 4) // 5
    img = Image.new('RGB', (W, PLAN_H + rows_of_cards * CARD_H + 150), (38, 36, 42))
    d = ImageDraw.Draw(img)
    S = 58.0                                             # pixels a metre
    ox, oz = W / 2, 70 + 9.5 * S

    def px(x, z):
        return (ox + x * S, oz + z * S)

    d.text((30, 14), '%s  /  %s' % (hall.replace('_', ' '), doc['title']), font=font(30, True), fill=(245, 240, 228))
    d.rectangle((px(-21, -9), px(21, 9)), fill=(74, 70, 80), outline=(120, 114, 128), width=2)
    for sx in (-13, 7):
        d.rectangle((px(sx, -3), px(sx + 6, 3)), fill=(48, 45, 54), outline=(110, 104, 118))
        d.text((px(sx + 0.4, -2.8)), 'shaft', font=font(15), fill=(150, 144, 158))
    for cx in (-20, -14, -5, 5, 14, 20):
        for cz in (-7, 7):
            d.rectangle((px(cx - 0.45, cz - 0.45), px(cx + 0.45, cz + 0.45)), fill=(100, 95, 108))
    hero = doc['hero']['row']
    for a in floor.get('artifacts', []):
        x, z = a['position']
        if abs(z) > 9.4:
            z = 9.2 if z > 0 else -9.2
        r = 26 if a['id'] == hero else 13
        colour = (255, 205, 60) if a['id'] == hero else (150, 190, 230)
        d.ellipse((px(x, z)[0] - r, px(x, z)[1] - r, px(x, z)[0] + r, px(x, z)[1] + r), fill=colour, outline=(20, 20, 24), width=2)
        d.text((px(x, z)[0] + r + 4, px(x, z)[1] - 10), ('HERO: ' if a['id'] == hero else '') + a['artifact'], font=font(16, a['id'] == hero), fill=colour)
    d.ellipse((px(0, 7.8)[0] - 6, px(0, 7.8)[1] - 6, px(0, 7.8)[0] + 6, px(0, 7.8)[1] + 6), fill=(255, 255, 255))
    d.text((px(0.2, 8.1)), 'you arrive', font=font(15), fill=(235, 235, 240))
    for v in doc.get('visual_arguments', []):
        x, z = v['at']
        w, h = v['size']
        d.rectangle((px(x - w / 2, z - h / 2), px(x + w / 2, z + h / 2)), outline=(120, 220, 160), width=3)
        d.text((px(x - w / 2 + 0.1, z - h / 2 + 0.05)), 'BUILT: ' + v['title'], font=font(15, True), fill=(120, 220, 160))
    at = {p['id']: px(*p['at']) for p in plates}
    for t in doc.get('threads', []):
        a, b = at[t['a']], at[t['b']]
        d.line((a, b), fill=(200, 30, 44), width=3)
        mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
        f = font(15)
        tw = d.textlength(t['word'], font=f)
        d.rectangle((mid[0] - tw / 2 - 4, mid[1] - 11, mid[0] + tw / 2 + 4, mid[1] + 11), fill=(248, 244, 232))
        d.text((mid[0] - tw / 2, mid[1] - 11), t['word'], font=f, fill=(150, 16, 28))
    for p in plates:
        x, y = at[p['id']]
        d.rectangle((x - 46, y - 20, x + 46, y + 20), fill=(196, 160, 112), outline=(90, 66, 40), width=3)
        d.text((x - 40, y - 15), p['title'].split('  ')[0], font=font(22, True), fill=(40, 28, 18))
        d.text((x - 12, y - 11), p['id'], font=font(13), fill=(60, 44, 28))
    y0 = PLAN_H
    for i, p in enumerate(plates):
        cx, cy = 20 + (i % 5) * CARD_W, y0 + (i // 5) * CARD_H
        d.rectangle((cx, cy, cx + CARD_W - 18, cy + CARD_H - 18), fill=(196, 160, 112), outline=(90, 66, 40), width=4)
        y = cy + 12
        for line in wrap(d, p['title'], font(21, True), CARD_W - 50):
            d.text((cx + 14, y), line, font=font(21, True), fill=(30, 20, 12))
            y += 28
        y += 4
        for note in p['front']:
            for k, line in enumerate(wrap(d, note, font(15), CARD_W - 60)):
                d.text((cx + 14 + (0 if k == 0 else 12), y), line, font=font(15), fill=(24, 18, 12))
                y += 20
            y += 5
        y += 4
        for note in p.get('back', []):
            for line in wrap(d, '(back) ' + note, font(13), CARD_W - 60):
                d.text((cx + 14, y), line, font=font(13), fill=(120, 30, 60))
                y += 17
        sx, sy = cx + 12, cy + CARD_H - 104
        for s in [s for s in doc['stickers'] if s['plate'] == p['id']]:
            words = s.get('text') or ((s.get('a') or '') + ' ' + (s.get('b') or '')).strip()
            paper = {'quote': (244, 240, 230), 'claim': (255, 226, 90), 'not': (255, 150, 150), 'question': (160, 215, 255)}[s['kind']]
            f = font(12, True)
            words = words if len(words) < 44 else words[:42] + '...'
            tw = d.textlength(words, font=f) + 14
            if sx + tw > cx + CARD_W - 26:
                sx, sy = cx + 12, sy + 26
            d.rounded_rectangle((sx, sy, sx + tw, sy + 22), 8, fill=paper, outline=(40, 30, 20))
            d.text((sx + 7, sy + 2), words, font=f, fill=(20, 16, 12))
            sx += tw + 6
    yl = y0 + rows_of_cards * CARD_H + 6
    legend = 'yellow sticker: my claim   red: what it is NOT   blue: a question I still have   white: the hall text, word for word   red thread: its word   green box: a visual argument to build from prefabs'
    d.text((30, yl), legend, font=font(17), fill=(225, 220, 210))
    d.text((30, yl + 30), 'Hero: ' + doc['hero']['why'][:230], font=font(15), fill=(255, 205, 60))
    out = ROOT / 'ada_run/arguments'
    out.mkdir(parents=True, exist_ok=True)
    img.save(out / (hall + '.png'))
    return out / (hall + '.png')


if __name__ == '__main__':
    want = [a for a in sys.argv[1:] if a.startswith('--sheet=')]
    if want:
        print(sheet(want[0].split('=', 1)[1]))
        sys.exit(0)
    found = []
    files = sorted(DIR.glob('*.json'))
    for f in files:
        found += check(f)
    for line in found:
        print('  ' + line)
    print('%d argument file(s), %d finding(s)' % (len(files), len(found)))
    sys.exit(len(found))
