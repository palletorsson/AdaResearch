"""Extract and run the printed removal lesson, student edits, and known faults."""
from pathlib import Path
import hashlib, json, re, subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-09-randomness-revision/Random_Remove'
ENGINE = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'


def main():
    raw = (ROOT / 'commons/maps/Random_Remove/tutorial.md').read_text(encoding='utf8')
    blocks = dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```', raw, re.S))
    assert set(blocks) == {'03_eligible_addresses.gd', 'point_body.gd'}
    dest = OUT / 'extracted'; dest.mkdir(exist_ok=True)
    for name, code in blocks.items():
        (dest / name).write_text(code + '\n', encoding='utf8')
        assert code == (ROOT / 'doc/book/studies/randomness-lineage' / name).read_text(encoding='utf8').rstrip()
    predictions = OUT / 'predictions.md'
    if not predictions.exists():
        predictions.write_text('''# Predictions before running

Range2..5 ×2..5 gives16 of64 addresses; first candidate18, not0. Checkerboard gives32. Row3 and column3 give8 each with corresponding transposed removal orders at the same seed. Empty predicate gives0; no request, no removal, return−1. Every successful draw shrinks the list once and leaves a visible slot. Exhaustion leaves exactly the excluded cubes visible. Reset restores candidates, cubes and seed. A4×4 transfer gives4 range members,8 checkerboard,4 row/column,0 empty. Faults: confusing list offset and address; retaining selected candidate; forgetting generator reset. None should pass.\n''', encoding='utf8')
    code = blocks['03_eligible_addresses.gd']
    rule = 'return column >= 2 and column <= 5 and row >= 2 and row <= 5'
    versions = [('printed',code,'range',True,'')]
    for name, replacement in [('checker','return (column + row) % 2 == 0'),('row','return row == 3'),('column','return column == 3'),('empty','return false')]:
        versions.append((name,code.replace(rule,replacement),name,True,''))
    versions += [
        ('offset-as-address',code.replace('last_address = candidates[last_offset]','last_address = last_offset'),'range',False,'draw offset maps to the original cube address'),
        ('keep-candidate',code.replace('candidates.remove_at(last_offset)','pass # incorrect: candidate remains'),'range',False,'chosen address leaves candidates and joins ordered history'),
        ('reset-without-seed',code.replace('rng.seed = seed_value','pass # incorrect: generator never reset'),'range',False,'reset makes no random request')]
    results = []
    for name, variant, mode, expected, fault in versions:
        path = dest / (name + '.gd'); path.write_text(variant + '\n',encoding='utf8')
        receipt = OUT / (name + '.json')
        if receipt.exists(): receipt.unlink()
        with (OUT / (name + '.log')).open('w',encoding='utf8') as log:
            result = subprocess.run([ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/random_remove_student.gd','--','--lesson=res://'+path.relative_to(ROOT).as_posix(),'--report=res://'+receipt.relative_to(ROOT).as_posix(),'--mode='+mode],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=45,creationflags=subprocess.CREATE_NO_WINDOW)
        output = (OUT / (name + '.log')).read_text(encoding='utf8')
        assert 'SCRIPT ERROR' not in output and 'Parse Error' not in output, output[-4000:]
        assert receipt.exists(), output[-4000:]
        data = json.loads(receipt.read_text())
        assert data['passed']==expected and (result.returncode==0)==expected, data
        if fault: assert fault in data['failures'],data
        results.append({'version':name,'passed':data['passed'],'expected_pass':expected,'checks':len(data['checks']),'failures':data['failures']})
        print(name, len(data['checks']), data['passed'],flush=True)
    row = json.loads((OUT/'row.json').read_text())['first_order']
    col = json.loads((OUT/'column.json').read_text())['first_order']
    assert [(i%8,i//8) for i in row] == [(i//8,i%8) for i in col]
    (OUT/'tests.json').write_text(json.dumps({'results':results,'row_column_transposition':'passed','printed_sha256':{n:hashlib.sha256((dest/n).read_bytes()).hexdigest() for n in blocks}},indent=2),encoding='utf8')


if __name__ == '__main__': main()
