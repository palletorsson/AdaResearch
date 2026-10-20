"""Apply the supplied reading, preserving the prior chapter and selected edition."""
from pathlib import Path
import json
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
source = ROOT / 'commons/maps/Random_Definition/final.md'
before = HERE / 'before'
before.mkdir(exist_ok=True)
for rel in ['commons/maps/Random_Definition/final.md', 'commons/maps/Random_Definition/map_data.json', 'commons/maps/Random_Definition/writing_wall.json', 'commons/maps/Random_Definition/book_images.json']:
    target = before / Path(rel).name
    if not target.exists(): shutil.copyfile(ROOT / rel, target)
old = ROOT / 'doc/book/iterations/2026-10-16-arrival-wall'
if not (before/'illustrated-chapter.pdf').exists():
    shutil.copyfile(old/'illustrated-chapter.pdf', before/'illustrated-chapter.pdf')
shutil.copyfile(Path('C:/Users/palle/.codex/attachments/0d4cfa73-2e37-42be-892f-c10721f9f91c/Pasted text.txt'), HERE/'supplied-reading.md')
text = (before/'final.md').read_text(encoding='utf8')
start = text.index('The instrument records where and how')
end = text.index('The first spheres gave numbers', start)
text = text[:start] + '''The recording keeps positions, turns and times. A fixed calculation condenses those measurements into the displayed number.[^gesture] The window changes; the Geiger begins another sequence of gaps. Keeping the recording lets us derive that seed again. The movement supplies a new input; the numbers that follow are still pseudorandom.

There are only a thousand possible seeds here. Two different gestures can become the same number. We have not yet kept such a pair. Their traces could remain different while the window, given the same seed and settings, repeats its colours.

''' + text[end:]
start = text.index('The larger dark sphere offers a journey.')
end = text.index('<!-- @ -->', start)
text = text[:start] + '''The larger dark sphere is already travelling out from the centre and back. We hold it and travel with it. At the entrance, the bead moved the visible hand; here the floor passes beneath us.

Direction and distance can change between excursions. The centre stays where it was.

We release it. The sphere continues without us.

It returns to the centre.

''' + text[end:]
text += '''
[^gesture]: The sampler stores timed positions and orientations at finite precision. It hashes the stored measurements, using a fixed calculation to produce a compact code, then reduces that code to an integer from 0 to 999. The record retains the measurements as well as the derived seed; the seed alone does not reconstruct the gesture. Desktop mode samples the carried point; VR mode samples the tracked controller. The six traces show changes between accepted samples, not the complete motion. See the [tutorial](tutorial.md) for recording, replay and reconstruction.
'''
text = text.replace('At MOVE / KEEP, a small dark sphere waits beneath six coloured traces.', 'A small dark sphere waits beneath six coloured traces.')
source.write_text(text, encoding='utf8')
(HERE/'final-source.md').write_text(text, encoding='utf8')
map_path = ROOT / 'commons/maps/Random_Definition/map_data.json'
raw = map_path.read_bytes()
assert raw.count(b'#part_movement_sampler_removed:true') == 1
map_path.write_bytes(raw.replace(b'#part_movement_sampler_removed:true', b'#part_movement_sampler_removed:false'))
wall_path = ROOT / 'commons/maps/Random_Definition/writing_wall.json'
wall = json.loads(wall_path.read_text(encoding='utf8'))
for magnet in wall['magnets']:
    if magnet['id'] == 'seed_replay_demo/movement_sampler':
        magnet['final'] = 'Restored in the saved room at (9.5, 18.5), facing 180 degrees. Follow movement into a kept number; explain the reduction briefly. Keep sampling and hashing detail in the research note and tutorial. Two different gestures with the same seed remain a proposed comparison, not a found pair.'
    if magnet['id'] == 'random_return':
        magnet['final'] = 'End with release: the ride ends for the visitor while the sphere continues and returns. Leave that asymmetry available without a closing verdict. A small, explicitly schematic diagram tests whether the separation is clearer.'
wall_path.write_text(json.dumps(wall, ensure_ascii=False, indent=2)+'\n', encoding='utf8')
choices_path = ROOT / 'commons/maps/Random_Definition/book_images.json'
choices = json.loads(choices_path.read_text(encoding='utf8'))
choices['edition'] = HERE.relative_to(ROOT).as_posix()+'/illustrated.html'
choices['trial'] = HERE.relative_to(ROOT).as_posix()
choices['status'] = 'reader-critique revision; arrival captures retained; literary effect awaiting reading'
for item in choices['images']:
    if item['id'] == 'page':
        item['question'] = 'Does the filled numerical field leave room to imagine the act of keeping? This captured state contains no held group.'
choices['publication_principle'] = 'Each image declares what it preserves, what it omits, and whether it records an event or proposes a relation. A meaningful loss can be compared, not silently repaired with invented evidence.'
choices_path.write_text(json.dumps(choices, ensure_ascii=False, indent=2)+'\n', encoding='utf8')
shutil.copyfile(choices_path, HERE/'curation.json')
shutil.copyfile(ROOT/'doc/book/iterations/2026-10-16-book-image-study/seed-values.json', HERE/'seed-values.json')
shutil.copyfile(ROOT/'algorithms/randomness/seed_replay/opening_seed.json', HERE/'opening_seed.json')
print('Preserved prior edition; revised two passages and restored the saved MOVE / KEEP placement.')
