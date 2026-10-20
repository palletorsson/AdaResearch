"""Extract the chapter's exact student files and run the saved-state experiment."""
from pathlib import Path
import os
import re
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
CHAPTER = ROOT / 'commons/maps/Random_Definition/abacus-reconstruction.md'
text = CHAPTER.read_text(encoding='utf-8')
blocks = re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)```', text, re.S)
expected = ['motion_record.gd', 'random_touch.gd', 'hand_follower.gd', 'ink_wall.gd', 'experiment_notebook.gd']
assert [name for name, _ in blocks] == expected, 'All five complete files must be printed in order'
folder = HERE / 'reconstructed'
folder.mkdir(exist_ok=True)
for name, code in blocks:
    origin = HERE / name if name == 'experiment_notebook.gd' else ROOT / 'commons/artifacts/random_touch' / name
    assert code.strip() == origin.read_text(encoding='utf-8').strip(), f'Stale printed file: {name}'
    (folder / name).write_text(code, encoding='utf-8')
engine = os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
scripts = [
    ('printed-loop.log', 'res://' + (HERE / 'verify.gd').relative_to(ROOT).as_posix(), 'ABACUS PRINTED EXPERIMENT LOOP: PASS'),
    ('ink.log', 'res://tests/test_random_touch_ink.gd', 'RANDOM TOUCH INK: PASS'),
    ('hand.log', 'res://tests/test_random_touch_hand.gd', 'RANDOM TOUCH HAND: PASS'),
    ('hall-seed.log', 'res://tests/test_random_definition_seed.gd', 'RANDOM DEFINITION SEED: PASS'),
]
for filename, script, marker in scripts:
    with (HERE / filename).open('w', encoding='utf-8') as log:
        result = subprocess.run(
            [engine, '--headless', '--path', str(ROOT), '--xr-mode', 'off', '--audio-driver', 'Dummy', '--script', script, '--', '--no-bridges'],
            cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, timeout=60,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0,
        )
    output = (HERE / filename).read_text(encoding='utf-8')
    assert result.returncode == 0 and marker in output and 'SCRIPT ERROR' not in output, f'Failed: {filename}\n{output}'
    print(filename, 'PASS')
