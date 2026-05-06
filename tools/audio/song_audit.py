#!/usr/bin/env python3
"""
Static audio song audit for AdaResearch.

Checks:
1. Soundbank structural integrity:
   - brief.json exists and parses
   - soundbank script files exist
   - section entries reference valid sounds
2. SoundbankGenerator alignment:
   - section names in STRUCTURES exist in brief (or fallback warning)
   - pattern keys that are not in soundbank
3. Call-signature compatibility:
   - compares SoundbankGenerator call styles against generate/generate_sample signatures
4. SongDevTools mapping:
   - JSON song IDs that currently have no audio generation mapping in SongDevTools

Run from repo root:
    python tools/audio/song_audit.py
"""

from __future__ import annotations

import json
import re
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Set, Tuple


REPO_ROOT = Path(__file__).resolve().parents[2]
SOUNDBANK_ROOT = REPO_ROOT / "commons/audio/soundbanks"
SONG_JSON_ROOT = REPO_ROOT / "commons/audio/parameters/songs"
SOUNDBANK_GENERATOR = REPO_ROOT / "commons/audio/generators/SoundbankGenerator.gd"
SONG_DEV_TOOLS = REPO_ROOT / "commons/audio/catalog/SongDevTools.gd"


# Invocation categories from SoundbankGenerator
DRUMS = {"kick", "snare", "clap", "rimshot", "shaker", "fingersnap", "tambourine", "perc"}
CHORD_HIT = {"stab", "piano", "organ", "rhodes", "strings", "pad"}
FREQ_HIT = {"arp", "sequence", "sequencer", "jupiter_arp", "singing_voice", "vocoder", "lead"}
BASS = {"bass", "sub", "hoover"}
CONT_CHORD = {"pad", "atmosphere", "supersaw", "siren", "strings", "choir"}
CONT_DRONE = {"crackle", "texture"}
CONT_FREQ = {"vocal", "vocoder"}


@dataclass
class Finding:
    kind: str
    severity: str
    genre: str
    detail: str


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def extract_const_block(src: str, const_name: str) -> str:
    marker = f"const {const_name} = {{"
    start = src.find(marker)
    if start == -1:
        return ""
    i = start + len(marker)
    depth = 1
    out: List[str] = []
    while i < len(src) and depth > 0:
        ch = src[i]
        out.append(ch)
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
        i += 1
    # drop final closing brace
    return "".join(out[:-1])


def parse_top_map(block: str) -> Dict[str, str]:
    out: Dict[str, str] = {}
    i = 0
    n = len(block)
    while i < n:
        m = re.search(r'"([^"\\]+)"\s*:\s*\{', block[i:])
        if not m:
            break
        key = m.group(1)
        brace_start = i + m.end() - 1
        depth = 1
        j = brace_start + 1
        while j < n and depth > 0:
            ch = block[j]
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
            j += 1
        out[key] = block[brace_start + 1 : j - 1]
        i = j
    return out


def extract_array_keys(body: str) -> Set[str]:
    return set(re.findall(r'^\s*"([^"\\]+)"\s*:\s*\[', body, flags=re.M))


def extract_structure_sections(body: str) -> List[str]:
    m = re.search(r'"sections"\s*:\s*\[([^\]]*)\]', body, flags=re.S)
    if not m:
        return []
    return re.findall(r'"([^"\\]+)"', m.group(1))


def parse_signature(src: str, func_name: str) -> Optional[List[dict]]:
    m = re.search(rf"static\s+func\s+{re.escape(func_name)}\s*\(([^)]*)\)", src)
    if not m:
        return None
    raw = m.group(1).strip()
    if not raw:
        return []
    params: List[dict] = []
    for token in [p.strip() for p in raw.split(",")]:
        has_default = "=" in token
        ptype = None
        if ":" in token:
            ptype = token.split(":", 1)[1].split("=", 1)[0].strip()
        params.append({"raw": token, "type": ptype, "default": has_default})
    return params


def compatible(sig: Optional[List[dict]], call_types: Sequence[str]) -> Tuple[bool, str]:
    if sig is None:
        return False, "missing method"

    total = len(sig)
    required = sum(1 for p in sig if not p["default"])
    n = len(call_types)
    if n < required or n > total:
        return False, f"arg count mismatch (call {n}, sig {required}..{total})"

    def type_ok(param_type: Optional[str], call_type: str) -> bool:
        if param_type is None:
            return True
        p = param_type.lower()
        if call_type == "float":
            return p in {"float", "int", "variant"}
        if call_type == "array":
            return p in {"array", "variant"}
        if call_type == "bool":
            return p in {"bool", "variant", "int"}
        return True

    for idx, ctype in enumerate(call_types):
        ptype = sig[idx]["type"]
        if not type_ok(ptype, ctype):
            return False, f"type mismatch arg{idx + 1} (call {ctype}, sig {ptype})"
    return True, "ok"


def parse_songdevtools_mapped_ids(path: Path) -> Tuple[Set[str], Set[str]]:
    txt = read_text(path)
    fn = re.search(
        r"func\s+_generate_and_play\(song_id: String\):\n(?P<body>.*?)(?:\nfunc\s+_toggle_pause\()",
        txt,
        re.S,
    )
    body_all = fn.group("body") if fn else ""

    m = re.search(r"match\s+song_id:\n(?P<body>.*?)\n\s*_:\n\s*# No generator", body_all, re.S)
    match_body = m.group("body") if m else ""

    direct_ids: Set[str] = set()
    for raw in match_body.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        one = re.match(r'"([^"]+)"\s*:', line)
        if one:
            direct_ids.add(one.group(1))
            continue
        many = re.match(r'((?:"[^"]+"\s*,\s*)+"[^"]+")\s*:', line)
        if many:
            direct_ids.update(re.findall(r'"([^"]+)"', many.group(1)))

    sb_map = re.search(r"soundbank_map\s*=\s*\{(?P<body>.*?)\n\s*\}", body_all, re.S)
    sb_ids = set(re.findall(r'"([^"]+)"\s*:', sb_map.group("body") if sb_map else ""))

    return direct_ids, sb_ids


def main() -> int:
    findings: List[Finding] = []

    sg_text = read_text(SOUNDBANK_GENERATOR)
    patterns = {
        g: extract_array_keys(body)
        for g, body in parse_top_map(extract_const_block(sg_text, "PATTERNS")).items()
    }
    structures = {
        g: extract_structure_sections(body)
        for g, body in parse_top_map(extract_const_block(sg_text, "STRUCTURES")).items()
    }

    generator_genres = set(patterns.keys()) | set(structures.keys())

    for sb_dir in sorted([p for p in SOUNDBANK_ROOT.iterdir() if p.is_dir()]):
        genre = sb_dir.name
        brief_path = sb_dir / "brief.json"
        if not brief_path.exists():
            findings.append(Finding("soundbank", "ERROR", genre, "missing brief.json"))
            continue

        try:
            brief = json.loads(read_text(brief_path))
        except Exception as exc:
            findings.append(Finding("soundbank", "ERROR", genre, f"invalid brief.json: {exc}"))
            continue

        soundbank = list(brief.get("soundbank", []))
        sections = brief.get("sections", {})

        # Missing scripts listed in soundbank
        missing_scripts = [s for s in soundbank if not (sb_dir / f"{s}.gd").exists()]
        if missing_scripts:
            findings.append(
                Finding(
                    "soundbank",
                    "ERROR",
                    genre,
                    "missing sound scripts: " + ", ".join(missing_scripts),
                )
            )

        if isinstance(sections, dict):
            for sec, val in sections.items():
                if isinstance(val, list):
                    bad = [s for s in val if s not in soundbank]
                    if bad:
                        findings.append(
                            Finding(
                                "soundbank",
                                "ERROR",
                                genre,
                                f"section '{sec}' references missing sounds: {', '.join(bad)}",
                            )
                        )
                elif isinstance(val, dict):
                    # SoundbankLoader expects section values as Array. Dict sections are currently unsafe.
                    findings.append(
                        Finding(
                            "soundbank",
                            "ERROR",
                            genre,
                            f"section '{sec}' is object-form; expected array of sound IDs",
                        )
                    )
                else:
                    findings.append(
                        Finding(
                            "soundbank",
                            "ERROR",
                            genre,
                            f"section '{sec}' has unsupported type: {type(val).__name__}",
                        )
                    )
        elif sections:
            findings.append(Finding("soundbank", "ERROR", genre, "sections is not an object"))

        if genre not in generator_genres:
            continue

        # Section coverage for generator-managed genres
        struct_sections = structures.get(genre, [])
        if struct_sections and isinstance(sections, dict):
            missing_sec = [s for s in struct_sections if s not in sections]
            if missing_sec:
                findings.append(
                    Finding(
                        "generator",
                        "WARN",
                        genre,
                        "missing brief section definitions (fallback to all sounds): "
                        + ", ".join(missing_sec),
                    )
                )

        pkeys = patterns.get(genre, set())
        stale_patterns = sorted([k for k in pkeys if k not in soundbank])
        if stale_patterns:
            findings.append(
                Finding(
                    "generator",
                    "WARN",
                    genre,
                    "pattern keys not in soundbank: " + ", ".join(stale_patterns),
                )
            )

        # Call-signature compatibility checks
        active_sounds: Set[str] = set(soundbank)
        if isinstance(sections, dict) and sections:
            active_sounds = set()
            for v in sections.values():
                if isinstance(v, list):
                    active_sounds.update(v)
                elif isinstance(v, dict) and isinstance(v.get("elements"), list):
                    active_sounds.update(v["elements"])

        for sound in sorted(active_sounds):
            script = sb_dir / f"{sound}.gd"
            if not script.exists():
                continue
            src = read_text(script)
            gen_sig = parse_signature(src, "generate")
            sample_sig = parse_signature(src, "generate_sample")

            checks: List[Tuple[str, Sequence[str], bool]] = []
            if sound in pkeys:
                if sound in DRUMS:
                    checks.append(("pattern-hit drum", ("float", "float"), False))
                elif sound == "hihat":
                    checks.append(("pattern-hit hihat fallback", ("float", "float", "bool"), False))
                elif sound in CHORD_HIT:
                    checks.append(("pattern-hit chord", ("float", "array", "float"), False))
                elif sound in FREQ_HIT:
                    checks.append(("pattern-hit freq", ("float", "float", "float"), False))
                else:
                    if sample_sig is not None:
                        checks.append(("pattern-hit fallback sample", ("float", "array"), True))
                    else:
                        checks.append(("pattern-hit fallback generate", ("float", "float"), False))
            elif sound in BASS:
                checks.append(("bass pattern", ("float", "float", "float", "float"), False))
            else:
                if sound in CONT_CHORD:
                    checks.append(("continuous chord", ("float", "array", "float", "float"), False))
                elif sound in CONT_DRONE:
                    checks.append(("continuous drone", ("float", "float"), False))
                elif sound in CONT_FREQ:
                    checks.append(("continuous freq", ("float", "float", "float"), False))
                else:
                    if sample_sig is not None:
                        checks.append(("continuous fallback sample", ("float", "array"), True))
                    else:
                        checks.append(("continuous fallback generate", ("float", "float"), False))

            for label, call_types, use_sample in checks:
                ok, reason = compatible(sample_sig if use_sample else gen_sig, call_types)
                if not ok:
                    sev = "ERROR" if "missing method" in reason or "arg count mismatch" in reason else "WARN"
                    findings.append(
                        Finding("signature", sev, genre, f"{sound}: {label} -> {reason}")
                    )

    # SongDevTools mapping coverage
    direct_ids, sb_ids = parse_songdevtools_mapped_ids(SONG_DEV_TOOLS)
    mapped = direct_ids | sb_ids
    song_ids = {p.stem for p in SONG_JSON_ROOT.glob("*.json")}
    unmapped = sorted(song_ids - mapped)
    for sid in unmapped:
        findings.append(
            Finding(
                "mapping",
                "WARN",
                "songdevtools",
                f"song json has no explicit generator mapping: {sid}",
            )
        )

    # Print grouped report
    by_kind: Dict[str, List[Finding]] = defaultdict(list)
    by_genre: Dict[str, List[Finding]] = defaultdict(list)
    for f in findings:
        by_kind[f.kind].append(f)
        by_genre[f.genre].append(f)

    print("=== AUDIO SONG AUDIT ===")
    print(f"repo: {REPO_ROOT}")
    print(f"total_findings: {len(findings)}")
    print()

    sev_counts = defaultdict(int)
    for f in findings:
        sev_counts[f.severity] += 1
    print("severity_counts:")
    for sev in ("ERROR", "WARN", "INFO"):
        if sev_counts[sev]:
            print(f"  {sev}: {sev_counts[sev]}")
    print()

    print("high_priority (ERROR):")
    for f in findings:
        if f.severity == "ERROR":
            print(f"  [{f.kind}] {f.genre}: {f.detail}")
    print()

    print("by_genre:")
    for genre in sorted(by_genre.keys()):
        print(f"  [{genre}]")
        for f in by_genre[genre]:
            print(f"    - {f.severity} [{f.kind}] {f.detail}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
