"""Capture the six supplied launch positions and assert actual museum controls."""
from pathlib import Path
import subprocess,sys,json
from write_foundations_reconstruction import LESSONS
ROOT=Path(__file__).resolve().parents[1]
sys.stdout.reconfigure(encoding='utf-8',errors='replace')
for hall,*_ in LESSONS:
    if len(sys.argv)>1 and hall not in sys.argv[1:]:continue
    command=[sys.executable,'tools/run_encounter_probe.py',hall,'--sequence','foundationscrisis','--render','--no-bridges','--output-tag','foundations_reconstruction','--probe','tools/probes/foundations_reconstruction_museum.gd']
    result=subprocess.run(command,cwd=ROOT)
    folder=ROOT/'ada_run/encounter_pilot'/hall/'foundations_reconstruction'
    assert result.returncode==0,hall
    assert 'SCRIPT ERROR' not in (folder/'stdout.log').read_text(encoding='utf-8'),hall
    assert json.loads((folder/'report.json').read_text())['passed'],hall
