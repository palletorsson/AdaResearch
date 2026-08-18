#!/usr/bin/env python3
"""List the files inside a Godot 4 .pck (what an export actually SHIPS).

    python tools/pck_ls.py <file.pck> [grep]
"""
import struct, sys
from pathlib import Path
def entries(p: Path):
    with open(p, "rb") as f:
        magic = f.read(4)
        assert magic == b"GDPC", magic
        ver, vmaj, vmin, vpat = struct.unpack("<4I", f.read(16))
        if ver >= 3:                      # 4.5+: the directory lives at dir_offset (usually the tail)
            flags, files_base, dir_offset = struct.unpack("<IQQ", f.read(20))
            f.seek(dir_offset)
        elif ver == 2:
            flags, files_base = struct.unpack("<IQ", f.read(12))
            f.read(16 * 4)
        else:
            f.read(16 * 4)
        n = struct.unpack("<I", f.read(4))[0]
        out = []
        for _ in range(n):
            ln = struct.unpack("<I", f.read(4))[0]
            path = f.read(ln).rstrip(b"\0").decode("utf-8", "replace")
            off, size = struct.unpack("<QQ", f.read(16))
            f.read(16)  # md5
            if ver >= 2:
                f.read(4)  # flags
            out.append((path, size))
        return out
if __name__ == "__main__":
    p = Path(sys.argv[1]); needle = sys.argv[2] if len(sys.argv) > 2 else ""
    e = entries(p)
    hits = [x for x in e if needle in x[0]]
    for path, size in hits[:400]:
        print(f"{size:12d}  {path}")
    print(f"{len(hits)} of {len(e)} files" + (f" match '{needle}'" if needle else ""))
