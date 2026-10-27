"""Cross-process lock for the shared rendered Godot/input test machine.

Keep the returned file alive until the runner exits. OS locks are released even
after a crash; the persistent one-byte file is not a stale ownership sentinel.
"""
import os
from pathlib import Path
import time


def acquire_native_slot(label: str, timeout: float = 1200):
    path = Path(__file__).resolve().parents[1] / 'ada_run' / 'void-native.lock'
    path.parent.mkdir(parents=True, exist_ok=True)
    handle = path.open('a+b')
    if path.stat().st_size == 0:
        handle.write(b'0')
        handle.flush()
    started = time.monotonic()
    waiting = False
    while True:
        handle.seek(0)
        try:
            if os.name == 'nt':
                import msvcrt
                msvcrt.locking(handle.fileno(), msvcrt.LK_NBLCK, 1)
            else:
                import fcntl
                fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            print(f'Native slot acquired: {label}', flush=True)
            return handle
        except OSError:
            if time.monotonic() - started >= timeout:
                handle.close()
                raise TimeoutError(f'Native test slot remained busy for {timeout}s')
            if not waiting:
                print(f'Waiting for native slot: {label}', flush=True)
                waiting = True
            time.sleep(1)
