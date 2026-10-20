"""Resolve complete printed files and explicitly linked, unchanged lesson files."""
from pathlib import Path
import re

PRINTED = re.compile(r'<!-- student-code:([^\s]+) -->\s*```gdscript\n(.*?)\n```', re.S)
CARRIED = re.compile(r'Carried unchanged from \[[^\]]+\]\(\.\./([A-Za-z0-9_]+)/tutorial\.md\): ((?:`[^`]+`(?:, )?)+)\.')


def lesson_files(source: Path, chain=()):
    """Return filename -> code, without a trailing newline, from tutorial sources.

    Do not fall back to a companion implementation: a missing teaching source
    must fail reconstruction. The standard carried-file sentence is readable
    by the learner and already used by the Primitives starter.
    """
    source = source.resolve()
    if source in chain:
        raise ValueError(f'Cyclic lesson inheritance: {source}')
    text = source.read_text(encoding='utf-8-sig')
    files = {}

    def add(name, code):
        if Path(name).name != name or '/' in name or '\\' in name or not name.endswith('.gd'):
            raise ValueError(f'Expected a local .gd filename: {name}')
        if name in files:
            raise ValueError(f'Duplicate printed/carried file: {source} / {name}')
        files[name] = code

    for name, code in PRINTED.findall(text):
        add(name, code)
    for hall, names in CARRIED.findall(text):
        inherited = lesson_files(source.parent.parent / hall / 'tutorial.md', (*chain, source))
        for name in re.findall(r'`([^`]+)`', names):
            if name not in inherited:
                raise ValueError(f'{source}: {hall} does not supply {name}')
            add(name, inherited[name])
    return files
