"""Check a focused lesson's declared build, printed code and evidence freshness.

Does not assess prose quality, teaching choice or learner understanding.
Usage: python reconstruction.py path/to/contract.json [--output path.json]
"""
from pathlib import Path
from hashlib import sha256
import argparse
import json
import re
from textwrap import dedent

ROOT = Path(__file__).resolve().parents[4]
BRIEF = ('make', 'bring', 'given', 'build', 'check', 'later')


def digest(path):
    return sha256(path.read_bytes()).hexdigest() if path.is_file() else None


def edit_parts(operation):
    """Return exact replacement and the fragments the lesson must print."""
    if operation.get('kind') == 'replace':
        before, after = operation['before'], operation['after']
        fragments = [before, after]
    elif operation.get('kind') == 'insert_after':
        before = operation['anchor']
        after = before + operation['text']
        fragments = [after]
    else:
        raise ValueError('unknown edit kind')
    if not isinstance(before, str) or not before or not isinstance(after, str):
        raise ValueError('edits require nonempty anchors and replacement text')
    return before, after, fragments


def compose(incoming, operations):
    """Apply only declared edits. Missing/ambiguous anchors fail, never guess."""
    if not operations:
        raise ValueError('no continuation edits')
    result = incoming
    for operation in operations:
        before, after, _ = edit_parts(operation)
        count = result.count(before)
        if count != 1:
            raise ValueError(f'{operation.get("id", "edit")}: anchor occurs {count} times; expected 1')
        result = result.replace(before, after, 1)
    return result


def validate(contract, root=ROOT):
    errors = []
    brief = contract.get('brief', {})
    for field in BRIEF:
        if not isinstance(brief.get(field), str) or not brief[field].strip():
            errors.append(f'brief.{field}: missing')
    for key in ('lesson', 'example', 'host'):
        if not isinstance(contract.get(key), str) or not contract[key].strip():
            errors.append(f'{key}: missing')
    for key in ('lesson', 'example'):
        if contract.get(key) and not (root/contract[key]).is_file():
            errors.append(f'{key}: file missing')
    for source in contract.get('sources', []):
        if not (root/source['path']).is_file():
            errors.append(f'source: missing {source["path"]}')
        elif digest(root/source['path']) != source['sha256']:
            errors.append(f'source: changed {source["path"]}')
    if not contract.get('sources'):
        errors.append('sources: none declared')
    checks = contract.get('checks', [])
    if not checks:
        errors.append('checks: no observable test')
    for check in checks:
        if not all(check.get(k) for k in ('id', 'action', 'expect', 'kind')):
            errors.append('check: missing action, result, kind or id')
        if check.get('kind') not in ('native', 'learner', 'headset', 'museum'):
            errors.append('check: unknown evidence kind')
    ids = [c.get('id') for c in checks]
    if len(ids) != len(set(ids)):
        errors.append('checks: duplicate ids')
    lesson = root/contract.get('lesson', '__missing__')
    example = root/contract.get('example', '__missing__')
    if lesson.is_file() and example.is_file():
        blocks = re.findall(r'^```gdscript\s*\n(.*?)^```\s*$', lesson.read_text(encoding='utf-8-sig'), re.M|re.S)
        code = example.read_text(encoding='utf-8-sig').strip()
        if contract.get('mode') == 'continuation':
            incoming = contract.get('incoming', {})
            path = root/incoming.get('path', '__missing__')
            if not path.is_file() or digest(path) != incoming.get('sha256'):
                errors.append('incoming: missing or changed state')
            if not incoming.get('provenance'):
                errors.append('incoming: provenance not declared')
            try:
                operations = contract.get('operations', [])
                actual = compose(path.read_text(encoding='utf-8-sig'), operations)
                if actual != example.read_text(encoding='utf-8-sig'):
                    errors.append('assembly: example is not incoming plus declared edits')
                printed = [dedent(block).strip() for block in blocks]
                for operation in operations:
                    for fragment in edit_parts(operation)[2]:
                        if dedent(fragment).strip() not in printed:
                            errors.append('printed-edit: missing '+operation.get('id', 'edit'))
            except (ValueError, KeyError, OSError, TypeError) as exc:
                errors.append('assembly: '+str(exc))
        elif not any(block.strip() == code for block in blocks):
            errors.append('printed-code: no complete block matches the executable example')
    native = dict(status='not tested')
    if contract.get('native_report'):
        report_path = root/contract['native_report']
        if report_path.is_file():
            report = json.loads(report_path.read_text(encoding='utf-8'))
            fresh = report.get('learner_source_sha256') == digest(example)
            fresh = fresh and all(digest(root/p) == h for p,h in report.get('dependencies', {}).items())
            complete = True
            if contract.get('mode') == 'continuation':
                required = contract.get('evidence_inputs', [])
                bindings = report.get('inputs', {})
                fresh = fresh and bool(required) and all(
                    bindings.get(p) == digest(root/p) and bindings.get(p) is not None for p in required)
                if not report.get('dependencies') or not report.get('checks'):
                    errors.append('native-evidence: empty dependencies or checks')
                    complete = False
                recorded = {c.get('id'): c for c in report.get('checks', [])}
                for check in checks:
                    if check.get('kind') == 'native' and recorded.get(check['id'], {}).get('passed') is not True:
                        errors.append('native-evidence: missing passing check '+check['id'])
                        complete = False
            native = dict(status=('pass' if report.get('passed') and complete else 'fail') if fresh else 'stale',
                          checks=len(report.get('checks', [])), scope=report.get('scope'))
            if native['status'] in ('fail', 'stale'):
                errors.append('native-evidence: '+native['status'])
        elif contract.get('mode') == 'continuation':
            errors.append('native-evidence: declared report missing')
            native = dict(status='missing')
    return dict(structure='pass' if not errors else 'fail', errors=errors, native=native,
                learner_understanding='not tested', learner_transfer='not tested',
                museum_integration='not tested', physical_headset='not tested',
                scope='Declared structure, printed construction or continuation edits, and evidence freshness only; no automatic judgment of teaching quality.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('contract', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = validate(json.loads(args.contract.read_text(encoding='utf-8')))
    output = json.dumps(result, indent=2, ensure_ascii=False)+'\n'
    if args.output:
        args.output.write_text(output, encoding='utf-8')
    print(output)
    raise SystemExit(0 if result['structure']=='pass' else 1)
