"""Narrow driver/resource teardown diagnostics after a successful receipt.
Never use this to suppress runtime, script, shader compilation or startup errors.
"""
import re

def shutdown_diagnostic(line):
    return bool(re.fullmatch(r"ERROR: [0-9]+ RID allocations of type 'N10RendererRD11MeshStorage4MeshE' were leaked at exit\.",line)
        or re.fullmatch(r'ERROR: [0-9]+ resources still in use at exit \(run with --verbose for details\)\.',line)
        or (line.startswith('ERROR: Texture with GL ID of ') and 'leaked' in line))

def split_errors(log, marker, allow_shutdown=False):
    before,found,after=log.rpartition(marker)
    if not found:before,after=log,''
    errors=lambda s:[line for line in s.splitlines() if 'SCRIPT ERROR' in line or line.startswith('ERROR:')]
    runtime=errors(before);shutdown=[]
    for line in errors(after):
        if allow_shutdown and shutdown_diagnostic(line):shutdown.append(line)
        else:runtime.append(line)
    return runtime,shutdown
