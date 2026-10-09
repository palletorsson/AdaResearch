"""Repeat the focused native check through the project runner."""
from pathlib import Path
import subprocess,sys
ROOT=Path(__file__).resolve().parents[4]
raise SystemExit(subprocess.call([sys.executable,str(ROOT/'tools/run_encounter_probe.py'),'Color_Pillar','--sequence','color','--render','--probe',str(Path(__file__).with_name('probe.gd'))],cwd=ROOT))
