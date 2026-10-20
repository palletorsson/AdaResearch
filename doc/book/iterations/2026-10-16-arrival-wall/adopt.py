"""Keep a hall arrival for publication. Copy its PNGs verbatim, never rerender them."""
from pathlib import Path
from hashlib import sha256
import argparse
import json
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]

def adopt(packet_path: Path) -> Path:
    packet_path = packet_path.resolve()
    packet = json.loads(packet_path.read_text(encoding='utf8'))
    assert packet['schema'] == 'ada-arrival-wall/1'
    assert packet['map'] == 'Random_Definition' and not packet['errors']
    choices_path = ROOT / 'commons/maps/Random_Definition/book_images.json'
    choices = json.loads(choices_path.read_text(encoding='utf8'))
    images = {item['id']: item for item in packet['images']}
    assert set(images) == {item['id'] for item in choices['images']}
    sources = []
    for item in choices['images']:
        entry = images[item['id']]
        assert entry['artifact'] == item['artifact']
        image_path = (packet_path.parent / entry['image']).resolve()
        assert image_path.parent == packet_path.parent
        assert sha256(image_path.read_bytes()).hexdigest() == entry['sha256']
        sources.append(image_path)
        sources.append(image_path.with_name(item['id'] + '-source.png'))
    assert all(path.is_file() for path in sources)
    destination = HERE / 'captures' / packet_path.parent.name
    destination.mkdir(parents=True, exist_ok=True)
    for source in sources + [packet_path]:
        target = destination / source.name
        if target.exists():
            assert target.read_bytes() == source.read_bytes(), 'A kept arrival cannot be replaced'
        else:
            shutil.copyfile(source, target)
    for item in choices['images']:
        entry = images[item['id']]
        item['image'] = (destination / entry['image']).relative_to(ROOT).as_posix()
        item['image_sha256'] = entry['sha256']
        item['capture'] = (destination / 'capture.json').relative_to(ROOT).as_posix()
        if item['id'] == 'abacus':
            marks = sum(len(row) for row in entry['state']['ink'])
            item['caption'] = 'Five paths, before touch.' if marks == 0 else f'Five paths at arrival, with {marks} kept marks.'
            item['alt'] = 'Five horizontal rods and beads, with a second axis at the fifth row; the actual arrival state.'
            item['keep'] = 'Rods, beads and any marks already present at arrival; one axis and two axes.'
            item['limit'] = 'Nothing is touched or advanced to prepare this image. A still cannot show speed.'
        elif item['id'] == 'page':
            held = sum(sum(bool(value) for value in row) for row in entry['state']['frozen'])
            full = entry.get('capture_when') == 'page_full'
            if full: assert entry['state']['full_and_settled']
            moment = 'after filling' if full else 'at arrival'
            item['caption'] = f'Page {entry["state"]["page_number"]}, {moment}. ' + ('No group has been held.' if not held else f'{held} groups held.')
            item['alt'] = f'The top of the generated page {moment}, including its heading, independent folio and current rows.'
            item['keep'] = 'Actual generated groups on the full, settled page.' if full else 'The actual surface at arrival, including empty space and any rows already admitted.'
            item['omit'] = 'Lower page, stand and room; screen-legibility halos around the digits.'
            item['limit'] = ('The page starts with ten seeded rows; the camera waits for every row to fill and settle. ' if full else 'The camera does not wait for the page to fill. ') + 'These generated digits are not a scan of the historical RAND table. Motion and colour are lost in the print.'
            if entry['choice']['filter']['treatment'] == 3:
                item['limit'] += ' Local contrast preserves faint existing strokes; no digits are added.'
        else:
            item['limit'] = 'The needle and simulated event record are kept at arrival. Monochrome removes the coloured output-bit distinctions; the picture cannot convey the sound.'
    choices['edition'] = (HERE / 'illustrated.html').relative_to(ROOT).as_posix()
    choices['trial'] = HERE.relative_to(ROOT).as_posix()
    choices['status'] = 'arrival-state wall/book pilot; selected capture for review'
    choices_path.write_text(json.dumps(choices, indent=2, ensure_ascii=False) + '\n', encoding='utf8')
    print('Kept arrival, with byte-identical wall/book PNGs:', destination)
    return destination

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('capture', type=Path, help='capture.json saved by the hall')
    adopt(parser.parse_args().capture)
