"""Capture actual Godot artifacts, or apply the explicitly requested screenshot filters."""
from pathlib import Path
import argparse
import subprocess

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
parser=argparse.ArgumentParser()
parser.add_argument('phase',choices=['capture','filter'])
args=parser.parse_args()
script=(HERE/'capture.gd').relative_to(ROOT).as_posix() if args.phase=='capture' else 'tools/book_image_filter.gd'
command=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--no-window','--rendering-method','gl_compatibility','--script','res://'+script,'--','--no-bridges']
if args.phase=='filter':command+=['--recipe=res://'+(HERE/'filters.json').relative_to(ROOT).as_posix()]
with (HERE/(args.phase+'.log')).open('w',encoding='utf8') as log:
    result=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,timeout=70,creationflags=subprocess.CREATE_NO_WINDOW)
print((HERE/(args.phase+'.log')).read_text(encoding='utf8',errors='replace')[-2600:])
print('Godot process exit:',result.returncode)
raise SystemExit(result.returncode)
