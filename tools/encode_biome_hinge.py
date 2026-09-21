"""Encode the unmodified native Godot frames as a local review movie."""
from pathlib import Path
import subprocess
import imageio_ffmpeg
import argparse

parser=argparse.ArgumentParser()
parser.add_argument('--scale',action='store_true')
args=parser.parse_args()
name='scale' if args.scale else 'hinge'
count=576 if args.scale else 240

root=Path(__file__).resolve().parents[1]
out=root/'ada_run/biome_primitives'/name
frames=list((out/'frames').glob('*.png'))
assert len(frames)==count, f'Expected {count} native frames, found {len(frames)}'
subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-hide_banner','-loglevel','error','-y',
    '-framerate','12','-i',str(out/'frames/%04d.png'),'-frames:v',str(count),'-c:v','libx264',
    '-crf','20','-pix_fmt','yuv420p','-movflags','+faststart',str(out/(name+'-cycle.mp4'))],
    check=True,creationflags=subprocess.CREATE_NO_WINDOW)
print(out/(name+'-cycle.mp4'))
