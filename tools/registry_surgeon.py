#!/usr/bin/env python3
"""registry_surgeon.py — set a key inside a registry entry WITHOUT reformatting the file.

The registry files are token-keyed dicts that CLAUDE.md says to edit surgically; one
json.dumps() round-trip once reformatted 15,121 lines. This session did it again at a
smaller scale: a hint-writer guessed the indent, got it wrong, and rewrote every line of
109 files to change two — and the diff reached the staging area before anyone read it.

Two rules, both measured rather than assumed:

  1. If the file ROUND-TRIPS CLEANLY (json.loads -> json.dumps with its own indent changes
     zero lines), a round-trip is exactly as surgical as a textual edit, and simpler. Use it.
  2. If it does NOT (mixed indentation — a builder pasted a block with tabs and spaces),
     edit the TEXT: find the target object by key, scan to its closing brace with a
     string-aware brace counter, and replace or insert the key there with the file's own
     local indent. Nothing outside that span is touched.

Either way the caller gets back the number of lines that changed and can refuse if it is
more than the edit itself.

    set_entry_key(path, token, ["spatial_needs"], "platform", "table")
    set_entry_key(path, token, [], "measurements", {...})     # a top-level entry key
"""
from __future__ import annotations
import json, re, difflib, pathlib


def _indent_of(raw: str) -> str | int:
    m = re.search(r"^([ \t]+)\S", raw, re.M)
    lead = m.group(1) if m else "\t"
    return "\t" if "\t" in lead else len(lead)


def roundtrip_noise(raw: str) -> int:
    out = json.dumps(json.loads(raw), indent=_indent_of(raw), ensure_ascii=False) + "\n"
    return _changed_lines(raw, out)


def _changed_lines(a: str, b: str) -> int:
    return sum(1 for l in difflib.unified_diff(a.splitlines(), b.splitlines(), n=0, lineterm="")
               if l[:1] in "+-" and not l.startswith(("+++", "---")))


def _find_key_object(raw: str, start: int, key: str) -> tuple[int, int] | None:
    """Span (open_brace_index, close_brace_index) of the object value of `"key": {`
    first occurring at or after `start`. String-aware."""
    m = re.compile(r'"%s"\s*:\s*\{' % re.escape(key)).search(raw, start)
    if not m:
        return None
    i = m.end() - 1          # index of '{'
    depth, in_str, esc = 0, False, False
    j = i
    while j < len(raw):
        c = raw[j]
        if in_str:
            if esc: esc = False
            elif c == "\\": esc = True
            elif c == '"': in_str = False
        else:
            if c == '"': in_str = True
            elif c == "{": depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    return (i, j)
        j += 1
    return None


def _local_indent(raw: str, open_idx: int) -> str:
    """Indent of the first line inside the object after open_idx (or the key's line + one level)."""
    nl = raw.find("\n", open_idx)
    if nl < 0:
        return "\t"
    m = re.match(r"[ \t]*", raw[nl + 1:])
    inner = m.group(0) if m else ""
    if inner.strip() == "" and inner:
        return inner
    # empty object on one line — derive from the key's own line
    ls = raw.rfind("\n", 0, open_idx) + 1
    m2 = re.match(r"[ \t]*", raw[ls:])
    base = m2.group(0) if m2 else ""
    return base + ("\t" if "\t" in base or not base else " " * len(base))


def set_entry_key(path: pathlib.Path, token: str, obj_path: list[str], key: str, value) -> dict:
    """Set `value` at entry[obj_path...][key]. Returns {"mode", "changed_lines", "written"}."""
    raw = path.read_text(encoding="utf-8")
    d = json.loads(raw)
    arts = d.get("artifacts") or {}
    if token not in arts:
        return {"mode": "no-such-token", "changed_lines": 0, "written": False}

    noise = roundtrip_noise(raw)
    if noise == 0:
        node = arts[token]
        for k in obj_path:
            node = node.setdefault(k, {})
        node[key] = value
        out = json.dumps(d, indent=_indent_of(raw), ensure_ascii=False) + "\n"
        path.write_text(out, encoding="utf-8")
        return {"mode": "roundtrip", "changed_lines": _changed_lines(raw, out), "written": True}

    # ── textual edit ─────────────────────────────────────────────────────────
    span = _find_key_object(raw, 0, token)
    if not span:
        return {"mode": "token-object-not-found", "changed_lines": 0, "written": False}
    lo, hi = span
    for k in obj_path:
        sub = _find_key_object(raw, lo, k)
        if not sub or sub[0] > hi:
            # create the sub-object just inside the current object
            ind = _local_indent(raw, lo)
            ins = f'\n{ind}"{k}": {{}},'
            raw = raw[:lo + 1] + ins + raw[lo + 1:]
            hi += len(ins)
            sub = _find_key_object(raw, lo, k)
        lo, hi = sub
    ind = _local_indent(raw, lo)
    body = raw[lo + 1:hi]
    ser = json.dumps(value, ensure_ascii=False, indent=None)
    # an existing key inside this object: replace its whole value (string-aware scan to the
    # next top-level comma or the close brace)
    km = re.compile(r'"%s"\s*:' % re.escape(key)).search(body)
    if km:
        k0 = km.end()
        depth, in_str, esc, j = 0, False, False, k0
        while j < len(body):
            c = body[j]
            if in_str:
                if esc: esc = False
                elif c == "\\": esc = True
                elif c == '"': in_str = False
            else:
                if c == '"': in_str = True
                elif c in "{[": depth += 1
                elif c in "}]": depth -= 1
                elif c == "," and depth == 0: break
            j += 1
        new_body = body[:k0] + " " + ser + body[j:]
    else:
        stripped = body.rstrip()
        if stripped.strip() == "":
            outer = ind[:-1] if ind else ind
            new_body = "\n" + ind + '"' + key + '": ' + ser + "\n" + outer
        else:
            # append after the last member, keeping the closing brace's own line intact
            last_nl = body.rfind("\n")
            tail = body[last_nl:] if last_nl >= 0 else ""
            head = body[:last_nl] if last_nl >= 0 else body
            new_body = head.rstrip() + f',\n{ind}"{key}": {ser}' + tail
    out = raw[:lo + 1] + new_body + raw[hi:]
    json.loads(out)   # must still parse — raise loudly if the textual edit broke it
    path.write_text(out, encoding="utf-8")
    return {"mode": "textual", "changed_lines": _changed_lines(raw, out), "written": True}
