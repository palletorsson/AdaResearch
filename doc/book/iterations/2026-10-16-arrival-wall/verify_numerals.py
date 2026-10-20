"""Regression: keep faint recorded digits without printing into blank rows."""
from pathlib import Path
from hashlib import sha256
import json
from PIL import Image

HERE = Path(__file__).resolve().parent
original = HERE/'captures/2026-10-16T12-02-42-13492554'
before = Image.open(HERE/'numeral-before.png').convert('RGB')
after = Image.open(HERE/'numeral-page-ink.png').convert('RGB')
assert before.tobytes() == Image.open(original/'page.png').convert('RGB').tobytes(), 'Default preset changed'
groups = ['49811','52985','14221','32851','99985','42826','29628','90639','90948','55830']
spans = [(268,347),(359,441),(494,575),(585,666),(719,799),(808,891),(944,1024),(1034,1119),(1170,1251),(1262,1344)]
def dark_count(image, box):
    return sum(max(rgb) < 120 for rgb in image.crop(box).getdata())
results = []
for group, (left,right) in zip(groups,spans):
    box=(left,475,right,510)
    lost=dark_count(before,box); kept=dark_count(after,box)
    assert kept > 150 and kept > lost*10, (group,lost,kept)
    results.append({'group':group,'before_dark_pixels':lost,'after_dark_pixels':kept})
assert dark_count(after,(250,540,1400,1100)) == 0, 'Filter invented marks in empty rows'
receipt = {'source':(original/'page-source.png').name,'source_sha256':sha256((original/'page-source.png').read_bytes()).hexdigest(),
    'same_source_for_comparison':True,'original_preset_unchanged':True,'empty_rows_remain_empty':True,'groups':results,
    'qualification':'Pixel counts measure retained ink, not digit recognition. All ten groups also inspected visually against the recorded sequence.'}
(HERE/'numeral-verification.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf8')
print('PASS: ten recorded groups retain ink; blank rows stay blank; previous default is pixel-identical.')
