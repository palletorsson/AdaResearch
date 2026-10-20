"""Full-project audio integration and source waveform validation."""
from pathlib import Path
import json
import os
import shutil
import subprocess
import sys
import wave
import numpy as np
import imageio_ffmpeg

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-18-void-city-sound'
OUT = Path(next((a.split('=', 1)[1] for a in sys.argv if a.startswith('--out=')), str(OUT))).resolve()
OUT.mkdir(parents=True, exist_ok=True)
renderer = next((a.split('=', 1)[1] for a in sys.argv if a.startswith('--renderer=')), 'forward_plus')
assets = {}
for path in (ROOT / 'commons/void/audio').glob('*.wav'):
    with wave.open(str(path)) as file:
        frames, rate, channels = file.getnframes(), file.getframerate(), file.getnchannels()
        samples = np.frombuffer(file.readframes(frames), dtype='<i2').astype(float)/32768
        assert frames > 0 and np.max(np.abs(samples)) < .99 and np.std(samples) > .001, path
        if path.stem == 'siren':
            assert channels == 1 and 8 <= frames/rate <= 14, path
            edge = int(rate*.5)
            middle = samples[len(samples)//3:len(samples)*2//3]
            assert max(np.std(samples[:edge]), np.std(samples[-edge:])) < np.std(middle)*.1, 'Siren must fade gently at both ends'
        assets[path.name] = {'seconds': frames/rate, 'channels': channels, 'peak': float(np.max(np.abs(samples)))}
(OUT / 'assets.json').write_text(json.dumps(assets, indent=2))
fixture = ROOT / 'tools/probes/fixtures/void_music.mp3'
fixture.parent.mkdir(exist_ok=True)
if not fixture.exists():
    subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), '-v', 'error', '-i', str(ROOT/'commons/void/audio/city.wav'),
                    '-t', '3', '-codec:a', 'libmp3lame', '-b:a', '96k', str(fixture)], check=True)
command = [os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
           '--no-window' if '--capture' in sys.argv else '--headless', '--audio-driver', 'Dummy',
           '--path', str(ROOT), '--rendering-method', renderer, '--xr-mode', 'off', 'res://tools/probes/void_audio_probe.tscn',
           '--', '--out=' + str(OUT)]
if '--capture' in sys.argv: command.append('--capture')
with (OUT/'engine.log').open('w', encoding='utf-8') as stream:
    result = subprocess.run(command, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT, timeout=120,
                            creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
log = (OUT/'engine.log').read_text(encoding='utf-8', errors='replace')
assert result.returncode == 0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log, log[-9000:]
receipt = json.loads((OUT/'checks.json').read_text())
assert receipt['passed'], receipt
shutil.copy2(ROOT/'commons/void/audio/CLAUDE_SOUND_BRIEF.md', OUT/'CLAUDE_SOUND_BRIEF.md')
shutil.copy2(ROOT/'commons/void/audio/manifest.json', OUT/'sound-manifest.json')
print(f"{len(receipt['checks'])} full-project audio checks passed; {receipt['hooked_objects']} objects have feedback hooks.")
