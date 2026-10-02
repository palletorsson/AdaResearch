#!/usr/bin/env python3
"""test_check.py - proves that each rule of check.py BITES, and stays quiet where it should.

A tiny taxonomy and two tiny chapters pass clean. Each test plants one fault
in a copy and asserts the rule that must catch it, at the line it is on.
The tests named for the adversary's report (2 October 2026) reproduce each way it fooled
the checker, and each false alarm it was right about.
The Godot tests run when the Godot executable exists, and are skipped otherwise.
The tests of the real taxonomy read ../taxonomy.json.

    python test_check.py
"""

import copy
import json
import os
import re
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import check  # noqa: E402

GODOT = os.environ.get("GODOT", check.DEFAULT_GODOT)
HAVE_GODOT = os.path.exists(GODOT)
REAL_TAXONOMY = os.path.join(HERE, "..", "taxonomy.json")


def E(eid, kind, text, code, d, at, syn=(), deps=(), opened=None, stub=None, host=None):
    e = {"id": eid, "kind": kind, "forms": {"text": list(text), "code": list(code)},
         "def": d, "introduced_at": at, "synonyms": list(syn), "depends_on": list(deps)}
    if opened:
        e["opened_at"] = opened
    if stub:
        e["stub"] = stub
    if host:
        e["host"] = host
    return e


TAXONOMY = {
    "chapters": 2,
    "entries": [
        E("point", "concept", ["point", "points"], [], "A place.", "1.1", syn=["spot", "spots"]),
        E("node", "concept", ["node", "nodes"], [], "One thing Godot runs.", "1.1"),
        E("Vector3", "godot", [], ["Vector3"], "Three numbers as one value.", "1.1"),
        E("func", "gdscript", [], ["func"], "Starts a block of code.", "supplied:1.1", opened="2.1"),
        E("_ready", "godot", [], ["_ready"], "Runs once.", "supplied:1.1", opened="2.1"),
        E("position", "concept", ["position"], ["position"], "Where a node is: a point.", "1.2",
          syn=["location", "locations"], deps=["node", "point"]),
        E("extends", "gdscript", [], ["extends"], "Names the kind of node the code is for.", "1.2",
          deps=["node"]),
        E("Node3D", "godot", [], ["Node3D"], "A node in 3D.", "1.2", deps=["node"]),
        E("$", "gdscript", [], ["$"], "`$Name` reaches a node.", "1.2", deps=["node"]),
        E("=", "gdscript", [], ["="], "Sets a value.", "1.2"),
        E("print", "gdscript", [], ["print"], "Writes a value to the log.", "1.2"),
        E("stamp()", "supplied", [], ["stamp", "stamp(p)"], "Leaves a dot at a point.",
          "supplied:1.2", deps=["point"], stub="func stamp(p: Vector3) -> void:\n\tpass",
          host="$Supplied"),
        E("frame", "concept", ["frame", "frames"], [], "One picture.", "2.1", syn=["tick", "ticks"]),
        E("_process", "godot", [], ["_process"], "Runs every frame.", "2.1", deps=["frame"]),
        E("shape", "concept", ["shape", "shapes"], ["shape"], "What is touched.", "2.2",
          syn=["collider", "colliders"]),
        E("line_of_code", "plain", ["line of code", "lines of code"], [],
          "What you type on one row.", "everyday"),
    ],
}

CH1 = """<!-- chapter 1 -->
# 1 Points

Points, nodes and a position.

<!-- section 1.1
gives: point, node, Vector3
borrows: func, _ready
-->
## 1.1 A point

*[one point]*

A point is a place.
A node is one thing Godot runs.
`Vector3(1, 2, 3)` holds one point.
Your code goes under `func _ready():`.

<!-- section 1.2
needs: node, point, Vector3, func, _ready
gives: position, extends, Node3D, $, =, print
borrows: stamp()
-->
## 1.2 A position

A position is a point.
`extends Node3D` says the code is for a node.
`$Ball` reaches a node.
`=` sets its position.

<!-- code: nodes=Ball:Node3D prints="(1.0, 2.0, 3.0)" -->
```gdscript
extends Node3D

func _ready():
	$Ball.position = Vector3(1, 2, 3)
	print($Ball.position)
	$Supplied.stamp($Ball.position)
```

`print` writes the position.
`stamp(p)` leaves a dot at a point.

<!-- section 1.x
needs: position, point
-->
## Exercises

1. Move the position to another point.

> **Types** (chapter 1) · *point*: a place · *node*: one thing Godot runs · *position*: where a node is: a point
>
> **Code** · `extends` · `Node3D` · `Vector3` · `$` · `=` · `print`
>
> **Supplied** · `func` · `_ready` · `stamp(p)`
"""

CH2 = """<!-- chapter 2 -->
# 2 Frames

<!-- section 2.1
needs: position, $, =, Vector3, print, extends, Node3D
gives: frame, _process, func, _ready
-->
## 2.1 Every frame

A frame is one picture.
`_ready` runs once.
`_process` runs every frame.
`func` starts each one.

<!-- code: nodes=Ball:Node3D -->
```gdscript
extends Node3D

func _process(_delta):
	$Ball.position = Vector3(0, 1, 0)
	print($Ball.position)
```

<!-- section 2.2
needs: frame, position, node, func, _ready
gives: shape
-->
## 2.2 A shape

A shape is what is touched.
Each frame, the node keeps its position.
Put a shape on it under `func _ready():`.

<!-- section 2.x
needs: shape, frame, _process, print
-->
## Exercises

1. Give the shape a new size each frame in `_process`.
2. Use `print` to show the frame.

> **Types** (chapter 2) · *frame*: one picture · *shape*: what is touched
>
> **Code** · `_process` · `func` · `_ready`
"""

SKETCH = {
    "parts": [{"chapters": [
        {"n": 1,
         "code_new": ["a point and a node; Vector3 holds a point",
                      "a position, reached by $Name and set with =; print; extends Node3D"],
         "sections": [
             {"n": "1.1", "title": "A point", "idea": "A point is a place a node keeps.",
              "figure": "One point.", "builds": ""},
             {"n": "1.2", "title": "A position", "idea": "A position is a point you set from code.",
              "figure": "A ball at its position.", "builds": ""}],
         "examples": ["Example 1.1: one position"],
         "exercises": ["Move the position to another point."],
         "project_step": "Place a point.",
         "borrowed": ["func _ready(): where your code goes", "stamp(p): leaves a dot at a point"]},
        {"n": 2,
         "code_new": ["_process() runs every frame", "a shape is what is touched"],
         "sections": [
             {"n": "2.1", "title": "Every frame", "idea": "_process runs every frame; func _ready runs once.",
              "figure": "A counter.", "builds": ""},
             {"n": "2.2", "title": "A shape", "idea": "A shape is what is touched.",
              "figure": "A shape.", "builds": ""}],
         "examples": [],
         "exercises": ["Print the frame."],
         "project_step": "",
         "borrowed": []},
    ]}]
}

LAST_LINE_1 = "`stamp(p)` leaves a dot at a point."      # the last line of 1.2
EX_LINE_1 = "1. Move the position to another point."     # the exercise of 1.x
FIRST_LINE_2 = "Each frame, the node keeps its position."  # a line of 2.2


def line_no(text, needle):
    """The 1-based line of the first line containing needle."""
    for i, ln in enumerate(text.split("\n")):
        if needle in ln:
            return i + 1
    raise AssertionError("fixture has no line with %r" % needle)


def after(text, anchor, new):
    assert anchor in text, anchor
    return text.replace(anchor, anchor + "\n" + new, 1)


class Base(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp(prefix="ft_test_")

    def write(self, name, text):
        p = os.path.join(self.dir, name)
        with open(p, "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
        return p

    def run_check(self, tax=None, ch1=CH1, ch2=CH2, only_ch1=False, godot=False, sketch=None,
                  chapters=None, workdir=None):
        tp = self.write("taxonomy.json", json.dumps(tax or TAXONOMY, indent=1))
        if sketch is not None:
            sp = self.write("sketch.json", json.dumps(sketch, indent=1))
            return check.check_files(tp, [], sketch=sp, chapters=chapters)
        files = [self.write("ch01.md", ch1)]
        if not only_ch1:
            files.append(self.write("ch02.md", ch2))
        opts = {"timeout": 90}
        if workdir:
            opts["workdir"] = workdir
        return check.check_files(tp, files, godot=GODOT if godot else None, godot_opts=opts)

    def found(self, rep, rule, sev="error", file=None, line=None, contains=None):
        for s, f, ln, r, msg in rep.items:
            if s != sev or r != rule:
                continue
            if file and os.path.basename(f) != file:
                continue
            if line is not None and ln != line:
                continue
            if contains and contains not in msg:
                continue
            return True
        return False

    def assertBites(self, rep, rule, **kw):
        if not self.found(rep, rule, **kw):
            self.fail("expected %s %r %s; got:\n  %s" % (kw.get("sev", "error"), rule, kw,
                                                      "\n  ".join(rep.lines()) or "(nothing)"))

    def assertClean(self, rep):
        errs = [l for l in rep.lines() if ": warning: " not in l and ": note: " not in l]
        self.assertEqual(errs, [], "expected no errors")

    def errors_at(self, rep, line):
        return [i for i in rep.items if i[0] == "error" and i[2] == line]


def tax_with(change):
    t = copy.deepcopy(TAXONOMY)
    change(t)
    return t


def entry(t, eid):
    return next(e for e in t["entries"] if e["id"] == eid)


def add(*entries):
    return tax_with(lambda t: t["entries"].extend(copy.deepcopy(list(entries))))


# ------------------------------------------------------------------ the passing case

class TestPasses(Base):
    def test_fixture_is_clean(self):
        rep = self.run_check()
        self.assertClean(rep)
        self.assertEqual(rep.count("warning"), 0, "\n".join(rep.lines()))

    def test_sketch_fixture_is_clean(self):
        rep = self.run_check(sketch=SKETCH)
        self.assertClean(rep)


# ------------------------------------------------------------------ pass a: taxonomy

class TestTaxonomy(Base):
    def test_cycle_in_depends_on(self):
        def ch(t):
            entry(t, "point")["depends_on"] = ["node"]
            entry(t, "node")["depends_on"] = ["point"]
        rep = self.run_check(tax_with(ch))
        self.assertBites(rep, "taxonomy", contains="cycle")

    def test_dependency_introduced_later(self):
        rep = self.run_check(tax_with(lambda t: entry(t, "point").update(depends_on=["frame"])))
        self.assertBites(rep, "taxonomy", contains="introduced later")

    def test_unknown_dependency(self):
        rep = self.run_check(tax_with(lambda t: entry(t, "point").update(depends_on=["nowhere"])))
        self.assertBites(rep, "taxonomy", contains="unknown 'nowhere'")

    def test_duplicate_id(self):
        rep = self.run_check(tax_with(lambda t: t["entries"].append(copy.deepcopy(entry(t, "node")))))
        self.assertBites(rep, "taxonomy", contains="duplicate id")

    def test_duplicate_form(self):
        rep = self.run_check(tax_with(lambda t: entry(t, "node")["forms"]["text"].append("point")))
        self.assertBites(rep, "taxonomy", contains="already a form")

    def test_synonym_that_is_a_form(self):
        rep = self.run_check(tax_with(lambda t: entry(t, "shape")["synonyms"].append("node")))
        self.assertBites(rep, "taxonomy", contains="is a text form")

    def test_def_uses_term_outside_depends_on(self):
        rep = self.run_check(tax_with(lambda t: entry(t, "frame").update(**{"def": "One picture of a node."})))
        self.assertBites(rep, "taxonomy", contains="not in depends_on")

    def test_bad_introduced_at(self):
        rep = self.run_check(tax_with(lambda t: entry(t, "frame").update(introduced_at="soon")))
        self.assertBites(rep, "taxonomy", contains="is not a section")

    def test_everyday_concept(self):
        rep = self.run_check(tax_with(lambda t: entry(t, "frame").update(introduced_at="everyday")))
        self.assertBites(rep, "taxonomy", contains="only plain words and names are everyday")

    def test_a_stub_needs_a_host(self):
        rep = self.run_check(tax_with(lambda t: entry(t, "stamp()").pop("host")))
        self.assertBites(rep, "taxonomy", contains="a stub needs a host")

    # a supplied scene (chapter 3, 2 October 2026): the host is res://x.tscn, the stub its text
    def test_a_scene_host_takes_the_scene_text(self):
        ok = add(E("orb_scene", "supplied", [], ["orb.tscn"], "A saved orb.", "supplied:1.2",
                   stub='[gd_scene format=3]\n\n[node name="Orb" type="Node3D"]\n',
                   host="res://supplied/orb.tscn"))
        rep = self.run_check(ok)
        self.assertFalse(self.found(rep, "taxonomy", contains="stub"), "\n".join(rep.lines()))
        bad = add(E("orb_scene", "supplied", [], ["orb.tscn"], "A saved orb.", "supplied:1.2",
                    stub="func orb() -> void:\n\tpass", host="res://supplied/orb.tscn"))
        rep = self.run_check(bad)
        self.assertBites(rep, "taxonomy", contains="a scene host's stub is the scene's text")


# ------------------------------------------------------------------ pass b: gives

class TestGives(Base):
    def test_section_gives_what_it_does_not_teach(self):
        ch1 = CH1.replace("`print` writes the position.\n", "").replace("\tprint($Ball.position)\n", "")
        ch1 = ch1.replace('prints="(1.0, 2.0, 3.0)" ', "").replace(' prints="(1.0, 2.0, 3.0)"', "")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "gives", file="ch01.md", line=line_no(ch1, "section 1.2"),
                         contains="no line or code")

    def test_section_gives_what_the_taxonomy_puts_elsewhere(self):
        ch1 = CH1.replace("gives: position, extends", "gives: frame, position, extends")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "gives", line=line_no(ch1, "section 1.2"),
                         contains="the taxonomy introduces it at 2.1")

    def test_section_omits_a_give(self):
        ch1 = CH1.replace("$, =, print\nborrows", "$, =\nborrows")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "gives", contains="does not give it")

    def test_borrow_missing(self):
        ch1 = CH1.replace("borrows: stamp()\n", "")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "gives", contains="does not borrow it")

    def test_introduced_at_names_no_section(self):
        rep = self.run_check(tax_with(lambda t: entry(t, "print").update(introduced_at="1.5")))
        self.assertBites(rep, "gives", file="taxonomy.json", contains="names no section")


# ------------------------------------------------------------------ pass c: order and unknowns

class TestOrder(Base):
    def test_term_used_before_introduced(self):
        ch1 = CH1.replace("A node is one thing Godot runs.", "A node is one thing Godot runs at its position.")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "order", line=line_no(ch1, "at its position"),
                         contains="before it is introduced (1.2)")

    def test_code_token_used_before_introduced(self):
        ch1 = CH1.replace("func _ready():\n\t$Ball", "func _process(_delta):\n\t$Ball")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "order", line=line_no(ch1, "func _process"), contains="`_process`")

    def test_unknown_godot_class_in_code(self):
        ch1 = CH1.replace("\t$Supplied.stamp($Ball.position)", "\t$Supplied.stamp(Wobble3D.ZERO)")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "unknown", line=line_no(ch1, "Wobble3D"), contains="unknown class")

    def test_unknown_function_call(self):
        ch1 = CH1.replace("\t$Supplied.stamp($Ball.position)", "\twobble($Ball.position)")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "unknown", line=line_no(ch1, "wobble("), contains="unknown call `wobble()`")

    def test_code_name_outside_code_style(self):
        ch2 = CH2.replace("`_process` runs every frame.", "_process runs every frame.")
        rep = self.run_check(ch2=ch2)
        self.assertBites(rep, "style", file="ch02.md", line=line_no(ch2, "_process runs"))

    def test_unknown_code_shaped_word_in_prose(self):
        ch1 = CH1.replace("A node is one thing Godot runs.", "A node is a MeshInstance3D.")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "unknown", line=line_no(ch1, "MeshInstance3D"), contains="looks like code")

    def test_unknown_technical_word_in_prose(self):
        ch1 = after(CH1, "A point is a place.", "A shader paints it.")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "unknown", line=line_no(ch1, "shader"), contains="technical word")

    def test_a_form_before_its_entry_is_an_order_error(self):
        ch1 = after(CH1, "A point is a place.", "A point has positions.")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "order", line=line_no(ch1, "has positions"), contains="'positions'")

    def test_an_unlisted_form_after_its_entry_warns(self):
        ch1 = CH1.replace("A position is a point.", "Positions are points.")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "form", sev="warning", line=line_no(ch1, "Positions"))
        self.assertFalse(self.errors_at(rep, line_no(ch1, "Positions")))

    def test_use_missing_from_needs(self):
        ch1 = CH1.replace("needs: node, point, Vector3, func, _ready", "needs: node, Vector3, func, _ready")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "signature", line=line_no(ch1, "section 1.2"), contains="needs does not list 'point'")

    def test_needs_a_later_entry(self):
        ch1 = CH1.replace("needs: node, point, Vector3, func, _ready", "needs: node, point, Vector3, func, _ready, frame")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "signature", contains="needs 'frame', which is introduced at 2.1")

    def test_heading_does_not_match_signature(self):
        ch1 = CH1.replace("## 1.2 A position", "## 1.3 A position")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "format", line=line_no(ch1, "## 1.3"))

    def test_sections_out_of_order(self):
        rep = self.run_check(ch1=CH2, ch2=CH1)
        self.assertBites(rep, "format", contains="out of order")


# ------------------------------------------------------------------ pass d: synonyms

class TestSynonyms(Base):
    def test_synonym_in_prose(self):
        ch1 = CH1.replace("A position is a point.", "A position is a location.")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "synonym", line=line_no(ch1, "a location"), contains="write position")

    def test_synonym_in_a_name_the_code_declares(self):
        ch2 = CH2.replace("func _process(_delta):", "func move_collider(_delta):\n\tpass\n\nfunc _process(_delta):")
        rep = self.run_check(ch2=ch2)
        self.assertBites(rep, "synonym", file="ch02.md", contains="move_collider")


# ------------------------------------------------------------------ pass e: unused

class TestUnused(Base):
    def test_entry_never_used_after(self):
        ch2 = CH2.replace("\tprint($Ball.position)\n", "").replace("2. Use `print` to show the frame.\n", "")
        ch2 = ch2.replace("needs: position, $, =, Vector3, print", "needs: position, $, =, Vector3")
        ch2 = ch2.replace("needs: shape, frame, _process, print", "needs: shape, frame, _process")
        rep = self.run_check(ch2=ch2)
        self.assertBites(rep, "unused", contains="`print` is introduced at 1.2 and never used after it")

    def test_partial_book_only_warns(self):
        rep = self.run_check(only_ch1=True)
        self.assertClean(rep)
        self.assertBites(rep, "unused", sev="warning", contains="in the chapters checked")


# ------------------------------------------------------------------ pass f: short-speak

class TestShortSpeak(Base):
    def test_long_line_errors(self):
        ch1 = CH1.replace("A point is a place.",
                          "A point is a place that you can name and keep and move about and find again.")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "length", line=line_no(ch1, "find again"))

    def test_line_over_ten_words_warns(self):
        ch1 = CH1.replace("A point is a place.", "A point is a place that you can name and keep.")
        rep = self.run_check(ch1=ch1)
        self.assertClean(rep)
        self.assertBites(rep, "length", sev="warning", line=line_no(ch1, "name and keep"))

    def test_two_sentences_on_a_line(self):
        ch1 = CH1.replace("A point is a place.", "A point is a place. It has no size.")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "sentence", line=line_no(ch1, "no size"))

    def test_filler_word(self):
        ch1 = CH1.replace("A node is one thing Godot runs.", "A node is just one thing Godot runs.")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "filler", line=line_no(ch1, "just one"), contains="'just'")

    def test_first_person_warns(self):
        ch1 = after(CH1, "A point is a place.", "Our point is a place.")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "voice", sev="warning", line=line_no(ch1, "Our point"))


# ------------------------------------------------------------------ the page's devices

# The markers round one of the compression tests proposed and round two dropped
# (FUNCTIONAL_TEXT 2b): each planted in a prose line of 1.2, the line it must be caught on.
DEVICE_FAULTS = {
    "enters:": "enters: a point, from the section before.",
    "from:": "from: point, node.",
    "State:": "State: the whole position.",
    "Not yet:": "Not yet: the position.",
    "Not here:": "Not here: the node.",
    "→": "→ Move the position to a point.",
    "->": "-> Move the position to a point.",
    "[read]": "The position holds a point [read].",
    "[run]": "The node keeps its position `[run]`.",
    "[derived]": "A point is a place [derived].",
}


class TestDevices(Base):
    """FUNCTIONAL_TEXT 2b: the page uses its declared devices and no others. Each marker round
    two dropped is refused where it stands; 'Restore:' and code that holds an arrow are not."""

    def plant(self, line):
        ch1 = after(CH1, LAST_LINE_1, line)
        return ch1, self.run_check(ch1=ch1)

    def device_at(self, rep, ln):
        return [i for i in rep.items if i[2] == ln and i[3] == "device"]

    def test_each_dropped_marker_is_refused(self):
        for marker, line in DEVICE_FAULTS.items():
            with self.subTest(marker=marker):
                ch1, rep = self.plant(line)
                self.assertBites(rep, "device", file="ch01.md", line=line_no(ch1, line),
                                 contains="the marker is not a device (FUNCTIONAL_TEXT 2b)")
                self.assertTrue(any(marker.lower() in i[4].lower() for i in rep.items
                                    if i[3] == "device"), "the message names %r" % marker)

    def test_each_line_passes_without_its_marker(self):
        """The passing case for each fault: the same claim with the marker taken out."""
        clean = {
            "enters:": "A point comes from the section before.",
            "from:": "It uses a point and a node.",
            "State:": "The whole position is set.",
            "Not yet:": "The position waits.",
            "Not here:": "The node waits.",
            "→": "Move the position to a point.",
            "->": "Move the position to a point.",
            "[read]": "The position holds a point.",
            "[run]": "The node keeps its position.",
            "[derived]": "A point is a place.",
        }
        self.assertEqual(set(clean), set(DEVICE_FAULTS))
        for marker, line in clean.items():
            with self.subTest(marker=marker):
                ch1, rep = self.plant(line)
                self.assertEqual(self.device_at(rep, line_no(ch1, line)), [], "\n".join(rep.lines()))
                self.assertClean(rep)

    def test_restore_is_a_device(self):
        ch1, rep = self.plant("Restore: put the point back.")
        self.assertEqual(self.device_at(rep, line_no(ch1, "Restore:")), [], "\n".join(rep.lines()))

    def test_an_arrow_in_code_is_no_marker(self):
        # an arrow in a code span that opens the line, in a fenced block, and in mid-line
        for line in ("`-> void` says what the func hands back.", "`values[run]` is one value.",
                     "The position goes to a point -> once.", "From the point, the node moves.",
                     "Not yet placed, the node waits.", "[run](#a-position) is a link, not a tag."):
            with self.subTest(line=line):
                ch1, rep = self.plant(line)
                self.assertEqual(self.device_at(rep, line_no(ch1, line)), [], "\n".join(rep.lines()))
        ch1 = CH1.replace("\t$Supplied.stamp($Ball.position)",
                          "\t$Supplied.stamp($Ball.position)\n\nfunc keep() -> void:\n\tpass")
        rep = self.run_check(ch1=ch1)
        self.assertFalse(self.found(rep, "device"), "\n".join(rep.lines()))

    def test_switching_the_rule_off_lets_the_marker_through(self):
        line = DEVICE_FAULTS["enters:"]
        ch1, rep = self.plant(line)
        self.assertTrue(self.found(rep, "device", line=line_no(ch1, line)))
        saved = set(check.OFF)
        check.OFF.add("device")
        try:
            ch1, rep = self.plant(line)
        finally:
            check.OFF.clear()
            check.OFF.update(saved)
        self.assertFalse(self.found(rep, "device"), "device is off, and the marker is still "
                         "caught: the test does not prove the rule")


# ------------------------------------------------------------------ the Types box

class TestTypesBox(Base):
    def test_box_missing_an_entry(self):
        ch1 = CH1.replace("`=` · `print`", "`=`")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "types", contains="missing `print`")

    def test_box_lists_what_the_chapter_does_not_give(self):
        ch1 = CH1.replace("*position*: where a node is: a point", "*position*: where a node is: a point · *frame*: one picture")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "types", contains="does not give")

    def test_box_definition_differs(self):
        ch1 = CH1.replace("*point*: a place", "*point*: a dot in space")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "types", contains="the taxonomy says")

    def test_no_box(self):
        ch1 = CH1.split("> **Types**")[0]
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "types", contains="has no Types box")


# ------------------------------------------------------------------ sketch mode

class TestSketch(Base):
    def sketch_with(self, change):
        s = copy.deepcopy(SKETCH)
        change(s)
        return s

    def ch(self, s, n):
        return s["parts"][0]["chapters"][n - 1]

    def test_idea_uses_a_later_term(self):
        s = self.sketch_with(lambda s: self.ch(s, 1)["sections"][0].update(
            idea="A point is a place a node keeps each frame."))
        rep = self.run_check(sketch=s)
        self.assertBites(rep, "order", file="sketch.json", contains="[1.1] frame")

    def test_code_new_item_the_taxonomy_does_not_cover(self):
        s = self.sketch_with(lambda s: self.ch(s, 2)["code_new"].append("weather and tides"))
        rep = self.run_check(sketch=s)
        self.assertBites(rep, "gives", contains="names nothing the taxonomy introduces in chapter 2")

    def test_code_new_names_a_later_term(self):
        s = self.sketch_with(lambda s: self.ch(s, 1)["code_new"].append("a point that moves every frame"))
        rep = self.run_check(sketch=s)
        self.assertBites(rep, "order", contains="code_new of chapter 1 names frame")

    def test_borrowed_item_with_no_supplied_entry(self):
        s = self.sketch_with(lambda s: self.ch(s, 1)["borrowed"].append("a lamp you can carry"))
        rep = self.run_check(sketch=s)
        self.assertBites(rep, "gives", contains="borrowed item names no part")

    def test_supplied_entry_missing_from_borrowed(self):
        s = self.sketch_with(lambda s: self.ch(s, 1).update(borrowed=["func _ready(): where your code goes"]))
        rep = self.run_check(sketch=s)
        self.assertBites(rep, "gives", file="taxonomy.json", contains="'stamp()' is supplied at 1.2")

    def test_sketch_synonym_is_a_warning(self):
        s = self.sketch_with(lambda s: self.ch(s, 2)["sections"][1].update(idea="A collider is what is touched."))
        rep = self.run_check(sketch=s)
        self.assertBites(rep, "synonym", sev="warning", contains="collider")

    def test_chapter_filter(self):
        s = self.sketch_with(lambda s: self.ch(s, 2)["sections"][0].update(idea="A Wobble3D runs every frame."))
        rep = self.run_check(sketch=s, chapters={1})
        self.assertClean(rep)
        rep = self.run_check(sketch=s, chapters={2})
        self.assertBites(rep, "unknown", contains="Wobble3D")


# ------------------------------------------------------------------ the order of the whole plan

class TestPlanOrder(Base):
    """missing, N.0, N.x, other senses, late_deps, twice, back-references, the report."""

    def sketch_with(self, change):
        sk = copy.deepcopy(SKETCH)
        change(sk)
        return sk

    def ch(self, sk, n):
        return sk["parts"][0]["chapters"][n - 1]

    def test_missing_is_a_valid_introduced_at(self):
        tax = add(E("halo", "concept", ["halo"], [], "A ring of light.", "missing"))
        rep = self.run_check(tax=tax)
        self.assertFalse(self.found(rep, "taxonomy"), "\n".join(rep.lines()))

    def test_a_missing_element_used_in_the_sketch_is_never_taught(self):
        tax = add(E("halo", "concept", ["halo"], [], "A ring of light.", "missing"))
        sk = self.sketch_with(lambda sk: self.ch(sk, 2)["exercises"].append("Draw a halo."))
        rep = self.run_check(tax=tax, sketch=sk)
        self.assertBites(rep, "never", contains="halo")
        self.assertFalse(self.found(rep, "order", contains="halo"))

    def test_a_missing_element_used_in_a_chapter_is_never_taught(self):
        tax = add(E("halo", "concept", ["halo"], [], "A ring of light.", "missing"))
        ch2 = CH2.replace("A shape is what is touched.", "A shape is what is touched, like a halo.")
        rep = self.run_check(tax=tax, ch2=ch2)
        self.assertBites(rep, "never", file="ch02.md", line=line_no(ch2, "like a halo"))

    def test_depending_on_a_missing_element_is_an_error(self):
        tax = add(E("halo", "concept", ["halo"], [], "A ring of light.", "missing"),
                  E("glow", "concept", ["glow"], [], "What a halo gives.", "2.2", deps=["halo"]))
        rep = self.run_check(tax=tax, sketch=SKETCH)
        self.assertBites(rep, "taxonomy", contains="never taught")

    def test_chapter_level_placement(self):
        tax = add(E("bounce", "concept", ["bounce"], [], "A turn back from a shape.", "2.0",
                    deps=["shape"]))
        sk = self.sketch_with(lambda sk: (self.ch(sk, 2)["code_new"].append("bounce off a wall"),
                                          self.ch(sk, 2)["exercises"].append("Make it bounce.")))
        rep = self.run_check(tax=tax, sketch=sk)
        self.assertBites(rep, "unplaced", sev="warning", contains="'bounce'")
        self.assertFalse(self.found(rep, "taxonomy", contains="bounce"), "\n".join(rep.lines()))
        self.assertFalse(self.found(rep, "order", contains="bounce"))
        sk2 = self.sketch_with(lambda sk: self.ch(sk, 1)["exercises"].append("Make it bounce."))
        rep = self.run_check(tax=tax, sketch=sk2)
        self.assertBites(rep, "order", contains="bounce")

    def test_a_declared_other_sense_is_not_an_order_break(self):
        def change(t):
            entry(t, "frame")["other_senses"] = [{"words": ["frame"], "at": ["1.1"],
                                                  "sense": "a picture frame"}]
        sk = self.sketch_with(lambda sk: self.ch(sk, 1)["sections"][0].update(
            idea="A point is a place a node keeps in a frame."))
        rep = self.run_check(tax=tax_with(change), sketch=sk)
        self.assertBites(rep, "sense", sev="warning", contains="picture frame")
        self.assertFalse(self.found(rep, "order", contains="frame"))
        rep = self.run_check(sketch=sk)
        self.assertBites(rep, "order", contains="frame")

    def test_an_other_sense_word_must_be_a_form(self):
        def change(t):
            entry(t, "frame")["other_senses"] = [{"words": ["frameset"], "at": ["1.1"], "sense": "x"}]
        rep = self.run_check(tax=tax_with(change))
        self.assertBites(rep, "taxonomy", contains="no text form")

    def test_late_deps_turns_a_known_break_into_a_warning(self):
        def late(t):
            entry(t, "position")["depends_on"].append("frame")
        rep = self.run_check(tax=tax_with(late))
        self.assertBites(rep, "taxonomy", contains="introduced later")

        def declared(t):
            late(t)
            entry(t, "position")["late_deps"] = ["frame"]
        rep = self.run_check(tax=tax_with(declared))
        self.assertFalse(self.found(rep, "taxonomy", contains="introduced later"))
        self.assertBites(rep, "taxonomy", sev="warning", contains="late_deps")

    def test_an_element_listed_again_in_a_later_code_new_is_taught_twice(self):
        sk = self.sketch_with(lambda sk: self.ch(sk, 2)["code_new"].append("point, the place a shape touches"))
        rep = self.run_check(sketch=sk)
        self.assertBites(rep, "twice", sev="warning", contains="names point again")

    def test_an_element_used_in_a_later_code_new_is_not_taught_twice(self):
        sk = self.sketch_with(lambda sk: self.ch(sk, 2)["code_new"].append("a shape touches a point"))
        rep = self.run_check(sketch=sk)
        self.assertFalse(self.found(rep, "twice", sev="warning"), "\n".join(rep.lines()))

    def test_a_back_reference_declares_a_return(self):
        sk = self.sketch_with(lambda sk: self.ch(sk, 2)["code_new"].append(
            "point (met in ch1), the place a shape touches"))
        rep = self.run_check(sketch=sk)
        self.assertFalse(self.found(rep, "twice", sev="warning"), "\n".join(rep.lines()))

    def test_an_idea_that_defines_an_earlier_element_teaches_it_twice(self):
        sk = self.sketch_with(lambda sk: self.ch(sk, 2)["sections"][1].update(
            idea="A point is what a shape touches."))
        rep = self.run_check(sketch=sk)
        self.assertBites(rep, "twice", sev="warning", contains="defines point again")

    def test_a_formula_variable_is_not_unknown(self):
        sk = self.sketch_with(lambda sk: self.ch(sk, 2)["sections"][0].update(
            idea="_process runs every frame; m1 * m2 grows."))
        rep = self.run_check(sketch=sk)
        self.assertFalse(self.found(rep, "unknown"), "\n".join(rep.lines()))
        sk = self.sketch_with(lambda sk: self.ch(sk, 2)["sections"][0].update(
            idea="_process runs every frame; m1 grows."))
        rep = self.run_check(sketch=sk)
        self.assertBites(rep, "unknown", contains="m1")

    def test_a_chapter_reference_or_a_hall_name_is_not_code(self):
        sk = self.sketch_with(lambda sk: self.ch(sk, 2)["sections"][0].update(
            idea="_process runs every frame, as in ch1 and in Point_Zero."))
        rep = self.run_check(sketch=sk)
        self.assertFalse(self.found(rep, "unknown"), "\n".join(rep.lines()))

    def test_a_dotted_code_name_is_read_before_its_words(self):
        tax = add(E("orb", "concept", ["orb"], [], "A round body.", "2.2"),
                  E("roll", "godot", [], ["roll", "Orb.roll"], "Rolls it along.", "1.1"))
        sk = self.sketch_with(lambda sk: self.ch(sk, 1)["sections"][0].update(
            idea="A point is a place a node keeps; Orb.roll() moves it."))
        rep = self.run_check(tax=tax, sketch=sk)
        self.assertFalse(self.found(rep, "order", contains="orb"), "\n".join(rep.lines()))
        self.assertTrue(self.found(rep, "unused", sev="warning", contains="`roll`"))

    def test_a_declared_name_that_is_an_introduced_element_is_that_element(self):
        ch2 = CH2.replace("2. Use `print` to show the frame.",
                          "2. Use `print` to show the frame.\n\n```gdscript\nfunc show(position):\n"
                          "\tprint(position)\n```")
        rep = self.run_check(ch2=ch2)
        self.assertFalse(self.found(rep, "order", contains="position"), "\n".join(rep.lines()))

    def test_the_report_lists_order_breaks_by_chapter(self):
        sk = self.sketch_with(lambda sk: self.ch(sk, 1)["sections"][0].update(
            idea="A point is a place a node keeps each frame."))
        tp = self.write("taxonomy.json", json.dumps(TAXONOMY, indent=1))
        sp = self.write("sketch.json", json.dumps(sk, indent=1))
        out = os.path.join(self.dir, "report.md")
        r = subprocess.run([sys.executable, os.path.join(HERE, "check.py"), "--taxonomy", tp,
                            "--sketch", sp, "--report", out], capture_output=True, text=True,
                           encoding="utf-8")
        with open(out, encoding="utf-8") as f:
            text = f.read()
        self.assertIn("| used before it is taught | 1 | 1 |", text)
        self.assertIn("### Chapter 1", text)
        self.assertRegex(text, r"\| frame \| 1\.1 \| 2\.1 \|")
        self.assertEqual(r.returncode, check_errors(r.stdout))


def check_errors(stdout):
    m = re.search(r"^(\d+) errors?,", stdout, re.M)
    return int(m.group(1)) if m else -1


# ------------------------------------------------------------------ the command line

class TestCommandLine(Base):
    def test_exit_code_is_the_error_count_and_lines_are_file_line_rule(self):
        tp = self.write("taxonomy.json", json.dumps(TAXONOMY))
        ch1 = CH1.replace("A node is one thing Godot runs.", "A node is just one thing at its position.")
        p1 = self.write("ch01.md", ch1)
        p2 = self.write("ch02.md", CH2)
        r = subprocess.run([sys.executable, os.path.join(HERE, "check.py"), "--taxonomy", tp, p1, p2],
                           capture_output=True, text=True, encoding="utf-8")
        lines = [l for l in r.stdout.splitlines() if l.strip()]
        findings = lines[:-1]
        errors = [l for l in findings if not re.match(r"^\S+:\d+: [a-z]+: (warning|note): ", l)]
        self.assertTrue(errors)
        for l in findings:
            self.assertRegex(l, r"^[\w.-]+:\d+: [a-z]+: ")
        self.assertEqual(r.returncode, len(errors))
        self.assertIn("pass g skipped (run with --godot)", lines[-1])


# ------------------------------------------------------------------ the adversary: fooled
# Each test is one way the adversary's report found to pass a fault; each must now bite.

SIZE = E("size", "godot", [], ["size"], "How big a mesh is.", "2.2")
STRING = E("String", "gdscript", ["string", "strings"], ["String", '""'], "Text as a value.", "2.2")
DOT_PRODUCT = E("dot_product", "maths", ["dot product"], [], "How much two directions agree.", "2.2")


class TestFooled(Base):
    def one_line(self, line, tax=None, anchor="A point is a place."):
        ch1 = after(CH1, anchor, line)
        return ch1, self.run_check(tax=tax, ch1=ch1)

    def test_01_image_alt_text_is_read(self):
        ch1, rep = self.one_line("![a frame of the point](p.png)")
        self.assertBites(rep, "order", line=line_no(ch1, "p.png"), contains="frame")

    def test_01_link_title_is_read(self):
        ch1, rep = self.one_line('Follow [the dot](d.md "one frame") to the point.')
        self.assertBites(rep, "order", line=line_no(ch1, "d.md"), contains="frame")

    def test_02_derived_word_with_a_suffix(self):
        ch1, rep = self.one_line("A node is frameless.")
        self.assertBites(rep, "order", line=line_no(ch1, "frameless"), contains="frameless")

    def test_02_derived_word_with_a_prefix(self):
        ch1, rep = self.one_line("A point can be reshaped.")
        self.assertBites(rep, "order", line=line_no(ch1, "reshaped"), contains="shape")

    def test_02_derived_word_from_a_stem(self):
        ch1, rep = self.one_line("Its positional sense is fixed.")
        self.assertBites(rep, "order", line=line_no(ch1, "positional"), contains="position")

    def test_03_hyphen_joins_a_phrase(self):
        ch1, rep = self.one_line("The dot-product of two points is one number.", tax=add(DOT_PRODUCT))
        self.assertBites(rep, "order", line=line_no(ch1, "dot-product"), contains="dot product")

    def test_04_look_alike_letter(self):
        ch1, rep = self.one_line("The pоsition moves.")
        ln = line_no(ch1, "sition moves")
        self.assertBites(rep, "chars", line=ln, contains="CYRILLIC")
        self.assertBites(rep, "order", line=ln, contains="position")

    def test_04_zero_width_space(self):
        ch1, rep = self.one_line("The posi​tion moves.")
        ln = line_no(ch1, "tion moves")
        self.assertBites(rep, "chars", line=ln, contains="U+200B")
        self.assertBites(rep, "order", line=ln, contains="position")

    def test_04_soft_hyphen_entity(self):
        ch1, rep = self.one_line("The posi&shy;tion moves.")
        ln = line_no(ch1, "&shy;")
        self.assertBites(rep, "chars", line=ln, contains="U+00AD")
        self.assertBites(rep, "order", line=ln, contains="position")

    def test_05_watch_list_words(self):
        for line in ("A raycast finds the floor.", "Turn the ring by its rotation.",
                     "The camera looks down.", "Lay the points out on a grid.",
                     "A tween slides the point.", "A lattice holds the points."):
            ch1, rep = self.one_line(line)
            self.assertBites(rep, "unknown", line=line_no(ch1, line), contains="technical word")

    def test_06_a_plain_code_name_set_as_a_setting(self):
        ch1, rep = self.one_line("Set the size of the node to 2.", tax=add(SIZE))
        ln = line_no(ch1, "Set the size")
        self.assertBites(rep, "style", line=ln, contains="`size`")
        self.assertBites(rep, "order", line=ln, contains="`size`")

    def test_07_08_real_taxonomy_lists_the_synonyms_and_keeps_one_word_one_entry(self):
        with open(REAL_TAXONOMY, encoding="utf-8") as f:
            entries = {e["id"]: e for e in json.load(f)["entries"]}
        syn = {s.lower(): e["id"] for e in entries.values() for s in e.get("synonyms", [])}
        text = {t.lower(): e["id"] for e in entries.values() for t in e["forms"].get("text", [])}
        self.assertEqual(syn.get("hull"), "shape")
        self.assertEqual(syn.get("replica"), "copy")
        self.assertEqual(syn.get("spot"), "position")
        self.assertEqual(syn.get("update"), "frame")
        self.assertEqual(syn.get("whole number"), "integer")
        self.assertIn("item", text)
        self.assertEqual(text.get("degree"), text.get("degrees"))
        self.assertEqual(text.get("floating point"), "float")
        self.assertEqual(text.get("grid"), "grid")
        self.assertEqual(text.get("lattice"), "lattice")

    def test_08_a_word_split_by_number_is_a_taxonomy_error(self):
        tax = tax_with(lambda t: (entry(t, "point")["forms"].update(text=["point"]),
                                  t["entries"].append(E("pts", "plain", ["points"], [], "Many places.",
                                                        "everyday"))))
        rep = self.run_check(tax=tax)
        self.assertBites(rep, "taxonomy", contains="split by meaning")

    def test_09_a_types_box_definition_is_order_checked(self):
        ch1 = CH1.replace("*point*: a place", "*point*: a place, each frame")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "order", line=line_no(ch1, "**Types**"), contains="frame")

    def test_10_every_fence_is_read(self):
        ch1, rep = self.one_line("```text\nthe node waits a frame\n```", anchor=LAST_LINE_1)
        self.assertBites(rep, "order", line=line_no(ch1, "waits a frame"), contains="frame")
        for lang in ("python", "", "gdscript4"):
            ch1, rep = self.one_line("```%s\nfunc _process(_delta):\n\tpass\n```" % lang,
                                     anchor=LAST_LINE_1)
            self.assertBites(rep, "format", line=line_no(ch1, LAST_LINE_1) + 1, contains="code fence must say")
            self.assertBites(rep, "order", line=line_no(ch1, "func _process"), contains="_process")

    def test_11_a_godot_callback_must_be_an_entry(self):
        ch1 = CH1.replace("\t$Supplied.stamp($Ball.position)\n```",
                          "\t$Supplied.stamp($Ball.position)\n\nfunc _unhandled_input(event):\n\tpass\n```")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "unknown", line=line_no(ch1, "_unhandled_input"), contains="Godot callback")

    def test_12_a_later_term_cannot_be_declared_as_a_name(self):
        ch1 = CH1.replace("func _ready():\n\t$Ball", "var frame := 1\n\nfunc _ready():\n\t$Ball")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "order", line=line_no(ch1, "var frame"), contains="declares `frame`")

    def test_12_a_parameter_named_like_a_later_element(self):
        ch1 = CH1.replace("`print` writes the position.",
                          "```gdscript\nfunc place(_process):\n\tprint(_process)\n```\n\n"
                          "`print` writes the position.")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "order", contains="declares `_process`")

    def test_13_a_string_literal_is_an_element(self):
        ch1 = CH1.replace("\tprint($Ball.position)", '\tprint("hello")')
        rep = self.run_check(ch1=ch1, tax=add(STRING))
        self.assertBites(rep, "order", line=line_no(ch1, '"hello"'), contains="string literal")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "unknown", line=line_no(ch1, '"hello"'), contains="string literal")

    def test_13_what_a_string_spells_is_read(self):
        tax = add(dict(STRING, introduced_at="1.1"))
        ch2 = CH2.replace("\tprint($Ball.position)", '\tprint("a tick")\n\tprint("rotation_degrees")')
        rep = self.run_check(ch2=ch2, tax=tax)
        self.assertBites(rep, "synonym", line=line_no(ch2, '"a tick"'), contains="tick")
        self.assertBites(rep, "unknown", line=line_no(ch2, "rotation_degrees"), contains="names `rotation_degrees`")

    def test_14_a_node_path_is_its_own_element(self):
        ch1 = CH1.replace("\t$Ball.position = Vector3(1, 2, 3)", "\t$Ball/Child.position = Vector3(1, 2, 3)")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "unknown", line=line_no(ch1, "$Ball/Child"), contains="`$/`")

    def test_15_a_given_term_needs_a_declaring_line(self):
        ch2 = CH2.replace("A frame is one picture.\n", "")
        rep = self.run_check(ch2=ch2)
        self.assertBites(rep, "gives", file="ch02.md", contains="no line declares it")

    def test_15_a_code_element_given_in_code_only_is_an_error(self):
        ch1 = CH1.replace("`print` writes the position.\n", "")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "gives", contains="given in code only")

    def test_16_two_sentences_hidden_on_one_line(self):
        for line in ("Add a node, a point etc. The point grows.", "It shows nothing, no. Add a node.",
                     "Press it!It rises.", "The node moves — the point stays — it stops.",
                     "The node moves; the point stays.", "The node moves. it stops."):
            ch1, rep = self.one_line(line)
            self.assertBites(rep, "sentence", line=line_no(ch1, line))

    def test_17_a_soft_break_does_not_hide_a_long_sentence(self):
        long = ("Every point in the room, from the floor up to the sky,\n"
                "is counted from one place in metres along the three ways,\n"
                "and each of those counts is a number that your code can set.")
        ch1, rep = self.one_line(long)
        first = line_no(ch1, "Every point in the room")
        self.assertBites(rep, "sentence", line=first, contains="does not end its sentence")
        self.assertBites(rep, "length", line=first, contains="over 3 lines")

    def test_18_figures_and_code_spans_have_a_length(self):
        fig = "*[" + " ".join(["a white point"] * 12) + "]*"
        ch1, rep = self.one_line(fig, anchor="*[one point]*")
        self.assertBites(rep, "length", line=line_no(ch1, "a white point a white"))
        ch1, rep = self.one_line("`Vector3(1, 2, 3) + Vector3(4, 5, 6) * Vector3(7, 8, 9)` is far.")
        self.assertBites(rep, "length", line=line_no(ch1, "is far."), contains="code block")

    def test_19_hedging_and_poetry(self):
        ch1, rep = self.one_line("The node might move, or it could stay.")
        self.assertBites(rep, "hedge", line=line_no(ch1, "might move"))
        ch1, rep = self.one_line("The node remembers every hand that placed it.")
        self.assertBites(rep, "poetic", line=line_no(ch1, "remembers"))

    def test_20b_a_number_after_a_run_must_be_shown(self):
        ch1, rep = self.one_line("The ball stands 6 metres up.", anchor="`print` writes the position.")
        self.assertBites(rep, "number", line=line_no(ch1, "6 metres"))
        ch1, rep = self.one_line("The ball stands 2 metres up.", anchor="`print` writes the position.")
        self.assertFalse(self.found(rep, "number"), "\n".join(rep.lines()))

    def test_20b_an_instructions_number_before_its_colon_is_an_input(self):
        ch1, rep = self.one_line("Set it to 7: the ball moves.", anchor="`print` writes the position.")
        self.assertFalse(self.found(rep, "number"), "\n".join(rep.lines()))

    def test_20c_a_parse_only_block_warns(self):
        ch1 = CH1.replace('<!-- code: nodes=Ball:Node3D prints="(1.0, 2.0, 3.0)" -->', "<!-- code: parse -->")
        rep = self.run_check(ch1=ch1)
        self.assertBites(rep, "code", sev="warning", contains="never run")


# ------------------------------------------------------------------ the adversary: false alarms
# Each test is a line the checker flagged and should not have; each must stay quiet.

class TestQuiet(Base):
    def quiet_line(self, line, tax=None, anchor=FIRST_LINE_2, rule=None):
        ch2 = after(CH2, anchor, line)
        rep = self.run_check(tax=tax, ch2=ch2)
        ln = line_no(ch2, line.split("\n")[0])
        errs = [i for i in self.errors_at(rep, ln) if i[1].endswith("ch02.md")
                and (rule is None or i[3] == rule)]
        self.assertEqual(errs, [], "%r should be quiet:\n  %s" % (line, "\n  ".join(rep.lines())))
        return rep

    def test_a_form_of_an_introduced_term_is_no_error(self):
        self.quiet_line("The node is positioned by code.")

    def test_an_acronym_form_matches_only_as_written(self):
        tax = add(E("group_p1", "concept", ["P1"], [], "One way to repeat a tile.", "2.2"))
        # p1 is no wallpaper group: lower case is not the form (it is a name: write `p1`)
        self.quiet_line("Name the two points p1 and p2.", tax=tax, anchor="## 2.1 Every frame",
                        rule="order")
        self.quiet_line("Come back at 3 P1 and look.", tax=tax, anchor="## 2.1 Every frame",
                        rule="order")

    def test_a_capitalised_form_is_not_the_plain_verb(self):
        tax = add(E("play", "concept", ["Play"], [], "The button that runs the scene.", "2.2"))
        self.quiet_line("The nodes play together.", tax=tax, anchor="## 2.1 Every frame")
        self.quiet_line("A player moves the node.", tax=tax, anchor="## 2.1 Every frame")

    def test_names_with_a_capital_inside_are_not_code(self):
        self.quiet_line("Sol LeWitt drew points by rule.")
        self.quiet_line("Godot runs on macOS too.")

    def test_sentences_that_are_one_sentence(self):
        for line in ("Count the points (how many?) and look again.", "See Fig. 3 for the node.",
                     "Mr. Shiffman wrote about points.", "Wait... the node moves.",
                     "A point, e.g. the origin, has no size."):
            self.quiet_line(line, rule="sentence")

    def test_filler_words_in_other_uses(self):
        for line in ("Hum the note that the node sings to you.", "From now on, every point has a name.",
                     "A simply connected shape has no hole.", "Label each point clearly."):
            self.quiet_line(line, rule="filler")

    def test_a_code_name_that_is_a_plain_word_stays_plain(self):
        self.quiet_line("It has no size.", tax=add(SIZE), anchor="## 2.1 Every frame")

    def test_never_taught_is_reported_once_per_use(self):
        tax = add(E("halo", "concept", ["halo"], [], "A ring of light.", "missing"))
        ch2 = CH2.replace("A shape is what is touched.", "A shape is what is touched, like a halo.")
        ch2 = ch2.replace("needs: frame, position, node, func, _ready", "needs: frame, position, node, func, _ready, halo")
        rep = self.run_check(tax=tax, ch2=ch2)
        self.assertBites(rep, "never", contains="halo")
        self.assertFalse(self.found(rep, "signature", contains="halo"), "\n".join(rep.lines()))

    def test_a_chapters_own_name_is_its_own(self):
        tax = add(E("Mover", "name", ["Mover"], ["Mover"], "Your class: a moving body.", "1.x"))
        sk = copy.deepcopy(SKETCH)
        sk["parts"][0]["chapters"][0]["examples"].append("Example 1.2: The Mover")
        sk["parts"][0]["chapters"][0]["exercises"].append("Give the Mover a point.")
        rep = self.run_check(tax=tax, sketch=sk)
        self.assertFalse(self.found(rep, "never", contains="Mover"), "\n".join(rep.lines()))
        self.assertFalse(self.found(rep, "order", contains="Mover"), "\n".join(rep.lines()))
        sk["parts"][0]["chapters"][1]["exercises"].append("Give the Mover a shape.")
        rep = self.run_check(tax=tax, sketch=sk)
        self.assertBites(rep, "order", contains="Mover")

    def test_the_real_taxonomy_places_what_the_sketch_teaches(self):
        with open(REAL_TAXONOMY, encoding="utf-8") as f:
            entries = {e["id"]: e for e in json.load(f)["entries"]}
        self.assertNotIn("triangle_table()", entries)
        # chapter 5 (2 October 2026): 5.1's row of steps holds no grid; the 4 x 4 source of 5.3 does
        self.assertEqual(entries["cell"]["introduced_at"], "5.3")
        self.assertEqual(entries["handle"]["introduced_at"], "23.8")
        self.assertEqual(entries["Mover"]["introduced_at"], "7.x")
        self.assertEqual(entries["russell"]["introduced_at"], "everyday")
        senses = {(w, a) for s in entries["index"].get("other_senses", []) for w in s["words"] for a in s["at"]}
        self.assertIn(("index", "3.4"), senses)
        senses = {(w, a) for s in entries["wave"].get("other_senses", []) for w in s["words"] for a in s["at"]}
        self.assertIn(("wave", "9.4"), senses)


# ------------------------------------------------------------------ admin procedures

# An admin procedure, defined at 1.2 and called at 2.1; and one with a call template, defined
# at 2.2 and called in the exercises of chapter 2.
ADMIN_RUN = {
    "id": "run_the_project", "kind": "admin",
    "forms": {"text": ["run the project", "ran the project"], "code": []},
    "def": "Press Play, at the top right. If Godot asks, choose Select Current.",
    "introduced_at": "1.2", "synonyms": ["press Play", "run it", "play the scene", "start the game"],
    "step_phrases": ["Play", "F5", "Cmd+B", "Select Current", {"phrase": "main scene", "cues": ["asks"]},
                     {"phrase": "top right", "cues": ["Play", "button", "arrow"]}],
    "unless": ["animation"],
    "depends_on": [],
}
ADMIN_ADD = {
    "id": "add_a_node", "kind": "admin",
    "forms": {"text": ["add a node"], "code": []},
    "def": "Press + above the list. Double-click the new node to name it.",
    "introduced_at": "2.2", "synonyms": ["add a child node", "create a {node}"],
    "step_phrases": ["Create New Node", {"phrase": "+", "cues": ["scene tree"]},
                     {"phrase": "double-click", "cues": ["name it", "and type"]}],
    "calls": ["add a {node}"],
    "depends_on": ["node"],
}
# two procedures no section defines yet: running the open scene alone (F6), and saving a script
# under a name; any wording of them is described before any definition
ADMIN_SCENE = {
    "id": "run_the_scene", "kind": "admin",
    "forms": {"text": ["run the scene"], "code": []},
    "def": "Press F6.", "introduced_at": "missing",
    "synonyms": ["press F6", "run only this scene"], "step_phrases": ["F6"],
    "depends_on": [],
}
ADMIN_SAVE = {
    "id": "save_this_script_as", "kind": "admin",
    "forms": {"text": ["save this script as"], "code": []},
    "def": "Choose File, then Save As.", "introduced_at": "missing",
    "synonyms": [], "step_phrases": [{"phrase": "save as", "cues": ["script", "File", ".gd"]}],
    "depends_on": [],
}
RUN_DEF = ("**Run the project**: press Play, at the top right.\n"
           "If Godot asks, choose Select Current.")
ADD_DEF = ("**Add a node**: press + above the list.\n"
           "Double-click the new node to name it.")


def admin_tax(*more):
    return add(ADMIN_RUN, ADMIN_ADD, ADMIN_SCENE, ADMIN_SAVE, *more)


def admin_ch1(def_lines=RUN_DEF, sig="admin: run_the_project"):
    ch = CH1.replace("borrows: stamp()\n-->", "borrows: stamp()\n%s\n-->" % sig if sig else
                     "borrows: stamp()\n-->", 1)
    return after(ch, LAST_LINE_1, def_lines) if def_lines else ch


def admin_ch2(extra_21="", extra_ex="", needs_21=True):
    ch = CH2.replace("needs: position, $, =, Vector3, print, extends, Node3D\n",
                     "needs: position, $, =, Vector3, print, extends, Node3D%s\n"
                     % (", run_the_project" if needs_21 else ""), 1)
    ch = after(ch, "`func` starts each one.", "Run the project." + ("\n" + extra_21 if extra_21 else ""))
    ch = ch.replace("needs: frame, position, node, func, _ready\ngives: shape\n-->",
                    "needs: frame, position, node, func, _ready\ngives: shape\nadmin: add_a_node\n-->", 1)
    ch = after(ch, FIRST_LINE_2, ADD_DEF)
    ch = ch.replace("needs: shape, frame, _process, print\n-->",
                    "needs: shape, frame, _process, print, add_a_node, Node3D\n-->", 1)
    ch = after(ch, "2. Use `print` to show the frame.", "3. Add a `Node3D` named `Ball`." +
               ("\n" + extra_ex if extra_ex else ""))
    return ch


class TestAdmin(Base):
    """Admin is said once and then called by name: rules (a) order, (b) again, (c) define, the
    signature, call templates, typed links, the taxonomy; each with a planted fault."""

    def run_admin(self, ch1=None, ch2=None, tax=None, **kw):
        return self.run_check(tax=tax or admin_tax(), ch1=ch1 if ch1 is not None else admin_ch1(),
                              ch2=ch2 if ch2 is not None else admin_ch2(), **kw)

    def test_admin_fixture_is_clean(self):
        rep = self.run_admin()
        self.assertClean(rep)
        self.assertEqual(rep.count("warning"), 0, "\n".join(rep.lines()))

    # (a) a call before the definition is an order error
    def test_a_call_before_its_definition_is_an_order_error(self):
        ch1 = admin_ch1().replace("A node is one thing Godot runs.",
                                  "A node is one thing Godot runs.\nRun the project.", 1)
        rep = self.run_admin(ch1=ch1)
        self.assertBites(rep, "order", file="ch01.md", line=line_no(ch1, "Run the project."),
                         contains="run the project is used before it is introduced (1.2)")

    # (b) after the definition, a synonym or a step phrase says its steps again
    def test_a_synonym_after_the_definition_is_an_error(self):
        ch2 = admin_ch2(extra_21="Press Play again.")
        rep = self.run_admin(ch2=ch2)
        self.assertBites(rep, "admin", file="ch02.md", line=line_no(ch2, "Press Play again."),
                         contains='describes run the project again: say "Run the project." (1.2)')

    def test_a_step_phrase_after_the_definition_is_an_error(self):
        ch2 = admin_ch2(extra_21="If asked, choose Select Current.")
        rep = self.run_admin(ch2=ch2)
        self.assertBites(rep, "admin", line=line_no(ch2, "choose Select Current"),
                         contains="'Select Current' describes run the project again")

    def test_play_as_a_verb_is_no_step(self):
        ch2 = admin_ch2(extra_21="Play a sound when it lands.")
        rep = self.run_admin(ch2=ch2)
        self.assertClean(rep)

    def test_a_cued_step_phrase_counts_only_with_its_cue(self):
        rep = self.run_admin(ch2=admin_ch2(extra_21="The ball rolls to the top right."))
        self.assertClean(rep)
        ch2 = admin_ch2(extra_21="The button sits at the top right.")
        rep = self.run_admin(ch2=ch2)
        self.assertBites(rep, "admin", line=line_no(ch2, "The button sits"), contains="'top right'")

    def test_its_steps_are_free_in_its_defining_section(self):
        ch1 = admin_ch1(def_lines=RUN_DEF + "\nPlay is the button that does it.")
        rep = self.run_admin(ch1=ch1)
        self.assertFalse(self.found(rep, "admin"), "\n".join(rep.lines()))

    # (c) the defining section holds the bold name and the steps, as the taxonomy has them
    def test_the_defining_section_holds_the_bold_name(self):
        ch1 = admin_ch1(def_lines=RUN_DEF.replace("**Run the project**: press", "Press"))
        rep = self.run_admin(ch1=ch1)
        self.assertBites(rep, "admin", file="ch01.md", contains="1.2 defines run the project (admin:), "
                         "but no line is '**Run the project**: '")

    def test_the_steps_agree_with_the_def(self):
        ch1 = admin_ch1(def_lines=RUN_DEF.replace("at the top right.", "at the top left."))
        rep = self.run_admin(ch1=ch1)
        self.assertBites(rep, "admin", line=line_no(ch1, "at the top left"),
                         contains="the taxonomy's def says 'Press Play, at the top right.'")

    def test_the_steps_may_not_stop_short(self):
        ch1 = admin_ch1(def_lines=RUN_DEF.split("\n")[0])
        rep = self.run_admin(ch1=ch1)
        self.assertBites(rep, "admin", contains="the steps of run the project stop here")

    def test_a_second_definition_is_an_error(self):
        ch2 = admin_ch2(extra_21=RUN_DEF.split("\n")[0])
        rep = self.run_admin(ch2=ch2)
        self.assertBites(rep, "admin", line=line_no(ch2, "**Run the project**"),
                         contains="this is a second definition")

    # the signature: admin: lists what the section defines, and a call is needed
    def test_the_signature_lists_what_it_defines(self):
        rep = self.run_admin(ch1=admin_ch1(sig=""))
        self.assertBites(rep, "admin", contains="the section's admin: does not list it")
        ch1 = admin_ch1(sig="").replace("gives: position, extends", "gives: run_the_project, position, extends", 1)
        rep = self.run_admin(ch1=ch1)
        self.assertBites(rep, "admin", contains="an admin procedure: it goes in admin:")

    def test_a_call_is_listed_in_needs(self):
        ch2 = admin_ch2(needs_21=False)
        rep = self.run_admin(ch2=ch2)
        self.assertBites(rep, "signature", contains="uses run the project")

    # call templates: 'Add a `Node3D`' calls add a node; 'Add a `Vector3`' does not
    def test_a_template_call_is_a_use_and_is_order_checked(self):
        ch2 = admin_ch2(extra_21="Add a `Node3D` named `Ball` here.")
        rep = self.run_admin(ch2=ch2)
        self.assertBites(rep, "order", line=line_no(ch2, "named `Ball` here"),
                         contains="add a node is used before it is introduced (2.2)")

    def test_a_template_slot_takes_a_node_class_only(self):
        ch2 = admin_ch2(extra_21="Add a `Vector3` to the position.")
        rep = self.run_admin(ch2=ch2)
        self.assertFalse(self.found(rep, "order", contains="add a node"), "\n".join(rep.lines()))

    # the source never types the link: the page derives it
    def test_a_typed_link_to_an_admin_is_an_error(self):
        ch2 = admin_ch2(extra_21="[Run the project](../ch01.md#run-the-project) once more.")
        rep = self.run_admin(ch2=ch2)
        self.assertBites(rep, "admin", line=line_no(ch2, "once more"), contains="a typed link to run the project")

    # the taxonomy: an admin entry is a name, steps and a defining section
    def test_the_taxonomy_checks_an_admin_entry(self):
        bad = dict(ADMIN_RUN, forms={"text": ["run the project"], "code": ["run()"]})
        rep = self.run_admin(tax=add(bad, ADMIN_ADD))
        self.assertBites(rep, "taxonomy", contains="an admin procedure has no code form")
        bad = dict(ADMIN_RUN, step_phrases=["Play", "point"])
        rep = self.run_admin(tax=add(bad, ADMIN_ADD))
        self.assertBites(rep, "taxonomy", contains="'point' would describe it again, and is a text form of 'point'")
        bad = dict(ADMIN_RUN, introduced_at="1.x")
        rep = self.run_admin(tax=add(bad, ADMIN_ADD))
        self.assertBites(rep, "taxonomy", contains="defined in one section")
        bad = dict(ADMIN_RUN, **{"def": "Press Play, the small green triangle up at the very top right "
                                         "of the window. If Godot asks, choose Select Current."})
        rep = self.run_admin(tax=add(bad, ADMIN_ADD))
        self.assertBites(rep, "taxonomy", contains="a step of the def is 15 words")
        bad = dict(ADMIN_ADD, calls=["add a {thing}"])
        rep = self.run_admin(tax=add(ADMIN_RUN, bad))
        self.assertBites(rep, "taxonomy", contains="the call template 'add a {thing}' needs a slot")
        tax = add(ADMIN_RUN, ADMIN_ADD)
        entry(tax, "point")["step_phrases"] = ["Here"]
        rep = self.run_admin(tax=tax)
        self.assertBites(rep, "taxonomy", contains="'point': only an admin procedure has step_phrases")

    # sketch mode: the sketch may describe an admin in its own chapter, and is warned elsewhere
    def test_the_sketch_is_warned_of_an_admin_described_in_another_chapter(self):
        sk = copy.deepcopy(SKETCH)
        sk["parts"][0]["chapters"][0]["sections"][1]["idea"] = "A position is a point you set; press Play."
        rep = self.run_check(tax=admin_tax(), sketch=sk)
        self.assertClean(rep)
        self.assertFalse(self.found(rep, "admin", sev="warning"), "\n".join(rep.lines()))
        sk["parts"][0]["chapters"][1]["exercises"] = ["Print the frame, then run it."]
        rep = self.run_check(tax=admin_tax(), sketch=sk)
        self.assertBites(rep, "admin", sev="warning", contains="[2.x] 'run it' describes run the project")

    # each rule, switched off, lets its planted fault through: so each test bites by that rule
    def test_switching_off_each_rule_silences_its_test(self):
        faults = {
            "admin-taxonomy": (lambda: dict(tax=add(dict(ADMIN_RUN, forms={"text": ["run the project"],
                                                                       "code": ["run()"]}), ADMIN_ADD)),
                               "taxonomy", "no code form"),
            "admin-order": (lambda: dict(ch1=admin_ch1().replace(
                "A node is one thing Godot runs.", "A node is one thing Godot runs.\nRun the project.", 1)),
                            "order", "run the project is used before"),
            "admin-again": (lambda: dict(ch2=admin_ch2(extra_21="Press Play again.")),
                            "admin", "describes run the project again"),
            "admin-define": (lambda: dict(ch1=admin_ch1(def_lines=RUN_DEF.replace("top right", "top left"))),
                             "admin", "the taxonomy's def says"),
            "admin-signature": (lambda: dict(ch1=admin_ch1(sig="")), "admin", "admin: does not list it"),
            "admin-calls": (lambda: dict(ch2=admin_ch2(extra_21="Add a `Node3D` named `Ball` here.")),
                            "order", "add a node is used before"),
            "admin-link": (lambda: dict(ch2=admin_ch2(extra_21="[Run the project](#run-the-project) once more.")),
                           "admin", "a typed link"),
        }
        self.assertEqual(set(faults), set(check.ADMIN_RULES))
        for rule, (make, finding, text) in faults.items():
            with self.subTest(rule=rule):
                rep = self.run_admin(**make())
                self.assertTrue(self.found(rep, finding, contains=text), "%s does not bite" % rule)
                saved = set(check.OFF)
                check.OFF.add(rule)
                try:
                    rep = self.run_admin(**make())
                finally:
                    check.OFF.clear()
                    check.OFF.update(saved)
                self.assertFalse(self.found(rep, finding, contains=text),
                                 "%s is off, and its fault is still caught: the test does not "
                                 "prove the rule" % rule)

    def test_the_real_taxonomy_holds_palles_run_the_project(self):
        with open(REAL_TAXONOMY, encoding="utf-8") as f:
            entries = {e["id"]: e for e in json.load(f)["entries"]}
        run = entries["run_the_project"]
        self.assertEqual((run["kind"], run["forms"]["text"][0], run["introduced_at"]),
                         ("admin", "run the project", "1.1"))
        self.assertIn("Play", run["step_phrases"])
        self.assertIn("press Play", run["synonyms"])
        self.assertNotIn("play", entries, "the Play button is a step of run the project now")
        # F6 runs the open scene, not the project: its wordings belong to run the scene
        scene = entries["run_the_scene"]
        self.assertEqual((scene["kind"], scene["introduced_at"]), ("admin", "missing"))
        self.assertIn("press F6", scene["synonyms"])
        self.assertNotIn("press F6", run["synonyms"])
        self.assertNotIn("F6", run["step_phrases"])
        for e in entries.values():
            if e["kind"] == "admin":
                self.assertTrue(e.get("step_phrases"), e["id"])
                self.assertFalse(e["forms"]["code"], e["id"])

    def test_the_real_taxonomy_holds_the_script_admins(self):
        """2 October 2026: a new script is made new, never saved over another (Save As copied
        the old class_name); a script goes on a node by a drop from the FileSystem, and so does a
        supplied scene. Each is defined where the written chapters first need it, and says its
        steps are unverified. Chapter 4's spray_can.gd (4.7) is the first new script."""
        with open(REAL_TAXONOMY, encoding="utf-8") as f:
            entries = {e["id"]: e for e in json.load(f)["entries"]}
        self.assertNotIn("save_this_script_as", entries)
        make, put = entries["make_a_new_script"], entries["put_a_script_on_a_node"]
        scene = entries["add_a_scene"]
        self.assertEqual((make["kind"], make["forms"]["text"][0], make["introduced_at"]),
                         ("admin", "make a new script", "4.7"))
        self.assertEqual((scene["kind"], scene["forms"]["text"][0], scene["introduced_at"]),
                         ("admin", "add a scene", "1.6"))
        self.assertIn("FileSystem", scene["def"])
        self.assertIn("add {file} to", scene["calls"])
        self.assertEqual((put["kind"], put["forms"]["text"][0], put["introduced_at"]),
                         ("admin", "put a script on a node", "1.3"))
        self.assertIn("New Script", make["def"])
        self.assertIn("FileSystem", put["def"])
        self.assertIn("put {file} on", put["calls"])
        self.assertEqual(entries["FileSystem"]["introduced_at"], "1.1")
        for e in (make, put, scene):
            self.assertIn("NOT verified in a live editor", e["note"], e["id"])
        # drag is the force of 7.6: the drop says no drag
        self.assertNotIn("drag", put["def"].lower())
        self.assertNotIn("drag", scene["def"].lower())


class TestAdminRound2(Base):
    """The second adversary's report on admin (2 October 2026): each way it fooled the rules,
    closed, and each false alarm it found, quiet. Lines go into 2.1 (after run the project's
    definition at 1.2, before add a node's at 2.2) unless a test says otherwise."""

    def run_admin(self, ch1=None, ch2=None, tax=None, **kw):
        return self.run_check(tax=tax or admin_tax(), ch1=ch1 if ch1 is not None else admin_ch1(),
                              ch2=ch2 if ch2 is not None else admin_ch2(), **kw)

    def bites_in_21(self, line, contains, rule="admin"):
        ch2 = admin_ch2(extra_21=line)
        rep = self.run_admin(ch2=ch2)
        self.assertBites(rep, rule, file="ch02.md", line=line_no(ch2, line.split("\n")[0]),
                         contains=contains)
        return rep, ch2

    def no_admin_in_21(self, line):
        ch2 = admin_ch2(extra_21=line)
        rep = self.run_admin(ch2=ch2)
        ln = line_no(ch2, line)
        self.assertFalse([i for i in rep.items if i[2] == ln and i[3] == "admin"],
                         "\n".join(rep.lines()))
        return rep

    # -- wordings the lists did not hold
    def test_a_wording_matches_in_any_case(self):
        for line in ("Press play again.", "PRESS PLAY again."):
            with self.subTest(line=line):
                self.bites_in_21(line, "describes run the project again")

    def test_play_the_scene_is_a_wording_of_running(self):
        self.bites_in_21("Play the scene again.", "'Play the scene' describes run the project")

    def test_an_arrow_at_the_top_right_is_the_button(self):
        self.bites_in_21("Click the arrow at the top right.", "'top right' describes run the project")

    def test_more_wordings_of_running(self):
        self.bites_in_21("Start the game again.", "'Start the game' describes run the project")
        self.bites_in_21("Press Cmd+B again.", "'Cmd+B' describes run the project")

    def test_a_function_key_with_a_space_or_in_code_style(self):
        self.bites_in_21("Press F 5 again.", "describes run the project")
        rep, ch2 = self.bites_in_21("Press `F5` again.", "describes run the project")
        ln = line_no(ch2, "Press `F5` again.")
        self.assertFalse(self.found(rep, "unknown", line=ln), "the key is the admin finding, "
                         "not unknown code:\n" + "\n".join(rep.lines()))

    def test_an_inline_tag_hides_no_word(self):
        self.bites_in_21("Press Pl<span></span>ay again.", "'Press Play' describes run the project")

    def test_add_a_node_said_by_its_button_or_its_naming(self):
        for line in ("4. Click + above the scene tree.", "4. Double-click it and type `Ball`."):
            with self.subTest(line=line):
                ch2 = admin_ch2(extra_ex=line)
                rep = self.run_admin(ch2=ch2)
                self.assertBites(rep, "admin", line=line_no(ch2, line),
                                 contains="describes add a node again")

    def test_save_as_counts_beside_its_cue(self):
        self.bites_in_21("Choose File, then Save as `two.gd`.",
                         "describes save this script as, which no section defines yet")
        self.no_admin_in_21("Choose Save As to keep the old scene.")

    # -- places the rule did not read
    def test_a_text_block_and_a_code_string_are_read(self):
        ch2 = admin_ch2(extra_21="The output reads:\n\n```text\nPress Play to see it.\n```\n")
        rep = self.run_admin(ch2=ch2)
        self.assertBites(rep, "admin", line=line_no(ch2, "Press Play to see it."),
                         contains="'Press Play' describes run the project again")
        ch2 = admin_ch2().replace("\tprint($Ball.position)\n```", '\tprint("Press Play to see it")\n```', 1)
        rep = self.run_admin(ch2=ch2)
        self.assertBites(rep, "admin", line=line_no(ch2, '"Press Play to see it"'),
                         contains="'Press Play' describes run the project again")

    def test_a_def_and_the_types_box_say_no_admin_steps(self):
        tax = admin_tax()
        entry(tax, "frame")["def"] = "One picture, after you press Play."
        ch2 = admin_ch2().replace("*frame*: one picture ·", "*frame*: one picture, after you press Play ·", 1)
        rep = self.run_admin(tax=tax, ch2=ch2)
        self.assertBites(rep, "taxonomy", contains="'frame': def says 'press Play', which describes "
                         "run the project")
        self.assertBites(rep, "admin", file="ch02.md", line=line_no(ch2, "**Types**"),
                         contains="describes run the project again")

    # -- calls before the definition
    def test_a_call_in_the_head_comes_before_its_definition(self):
        ch1 = admin_ch1().replace("Points, nodes and a position.",
                                  "Points, nodes and a position.\nRun the project to see it.", 1)
        rep = self.run_admin(ch1=ch1)
        self.assertBites(rep, "order", line=line_no(ch1, "Run the project to see it."),
                         contains="run the project is used before it is introduced (1.2)")
        ch1 = admin_ch1().replace("Points, nodes and a position.",
                                  "Points, nodes and a position.\nPress Play to see it.", 1)
        rep = self.run_admin(ch1=ch1)
        self.assertBites(rep, "admin", line=line_no(ch1, "Press Play to see it."),
                         contains="describes run the project before its definition (1.2)")

    def test_a_call_before_the_bold_line_of_its_own_section(self):
        ch1 = admin_ch1().replace("A position is a point.", "A position is a point.\nRun the project once.", 1)
        rep = self.run_admin(ch1=ch1)
        self.assertBites(rep, "order", line=line_no(ch1, "Run the project once."),
                         contains="run the project is called before its definition")

    def test_another_verb_for_a_template_call(self):
        self.bites_in_21("Create a `Node3D` named `Ball` first.",
                         "describes add a node before its definition (2.2)")
        ch2 = admin_ch2(extra_ex="4. Create a `Node3D` named `Ball`.")
        rep = self.run_admin(ch2=ch2)
        self.assertBites(rep, "admin", line=line_no(ch2, "4. Create a"),
                         contains='describes add a node again: say "Add a `Node3D`."')

    def test_another_tense_is_still_a_call(self):
        ch1 = admin_ch1().replace("A point is a place.", "A point is a place.\nYou ran the project.", 1)
        rep = self.run_admin(ch1=ch1)
        self.assertBites(rep, "order", line=line_no(ch1, "You ran the project."),
                         contains="run the project is used before it is introduced (1.2)")

    # -- defined twice, or in another shape
    def test_a_second_definition_in_its_own_section(self):
        ch1 = admin_ch1(def_lines=RUN_DEF + "\n**Run the project**: press F5.")
        rep = self.run_admin(ch1=ch1)
        self.assertBites(rep, "admin", line=line_no(ch1, "press F5."),
                         contains="run the project is defined twice in 1.2")

    def test_a_definition_in_another_shape_is_still_a_definition(self):
        for line in ("**Run the project** — click it.", "**Run project**: click it."):
            with self.subTest(line=line):
                self.bites_in_21(line, "this is a second definition")
        ch2 = admin_ch2(extra_ex="4. **Run the project**: click it.")
        rep = self.run_admin(ch2=ch2)
        self.assertBites(rep, "admin", line=line_no(ch2, "4. **Run"), contains="this is a second definition")

    def test_an_or_after_the_steps_is_a_second_way(self):
        ch1 = admin_ch1(def_lines=RUN_DEF + "\nOr click it twice.")
        rep = self.run_admin(ch1=ch1)
        self.assertBites(rep, "admin", line=line_no(ch1, "Or click it twice."),
                         contains="an 'Or' after the steps of run the project offers a second way")

    def test_another_wording_in_its_own_section(self):
        ch1 = admin_ch1(def_lines=RUN_DEF + "\nPress Play once more.")
        rep = self.run_admin(ch1=ch1)
        self.assertBites(rep, "admin", line=line_no(ch1, "Press Play once more."),
                         contains="is another wording of run the project, in its own section")

    # -- run the project versus run the scene
    def test_f6_is_run_the_scene_and_no_advice_to_run_the_project(self):
        rep, ch2 = self.bites_in_21("Press F6 to run only this scene.",
                                    "describes run the scene, which no section defines yet")
        ln = line_no(ch2, "Press F6")
        self.assertFalse(self.found(rep, "admin", line=ln, contains='say "Run the project."'),
                         "\n".join(rep.lines()))

    # -- typed links, in every form
    def test_a_typed_link_in_any_form(self):
        for line in ("[Run the project](ch01.md#run_the_project) again.",
                     "[Run the project](/course/sketch/1#12-a-position) again.",
                     '<a href="/course/sketch/1#run-the-project">Run the project</a> again.'):
            with self.subTest(line=line):
                self.bites_in_21(line, "a typed link to run the project")
        ch2 = admin_ch2(extra_21="[Run the project][rp] again.\n\n[rp]: #run-the-project")
        rep = self.run_admin(ch2=ch2)
        self.assertBites(rep, "admin", line=line_no(ch2, "[Run the project][rp]"), contains="a typed link")
        self.assertBites(rep, "admin", line=line_no(ch2, "[rp]: #run"), contains="a typed link")

    # -- false alarms, quiet
    def test_top_right_without_the_button_is_quiet(self):
        self.no_admin_in_21("The ball runs to the top right corner.")
        self.no_admin_in_21("The dots run off at the top right of the floor.")

    def test_play_as_a_verb_or_a_plain_word_is_quiet(self):
        self.no_admin_in_21("Play around with the position.")
        self.no_admin_in_21("Play matters here.")

    def test_run_it_for_a_function_is_quiet(self):
        self.no_admin_in_21("`print` is a call: Godot will run it.")
        self.no_admin_in_21("Write the call, then run it once from `_ready`.")

    def test_the_main_scene_as_a_word_is_quiet(self):
        self.no_admin_in_21("The main scene is the scene Godot runs first.")
        self.bites_in_21("If Godot asks for a main scene, pick one.",
                         "'main scene' describes run the project")

    def test_another_play_button_is_quiet(self):
        self.no_admin_in_21("Press Play in the animation panel.")

    def test_a_plus_elsewhere_is_quiet(self):
        self.no_admin_in_21("Give the panel a + button.")
        self.no_admin_in_21("Press + to zoom in.")

    def test_double_click_to_open_is_quiet(self):
        self.no_admin_in_21("Double-click the file name to open it.")

    def test_the_real_taxonomy_reads_the_adversarys_lines(self):
        """The adversary's own lines against the real taxonomy: what it fooled the rules with
        bites now, as the procedure it describes; what it found as false alarms is quiet."""
        tax = check.Taxonomy(REAL_TAXONOMY, check.Report())
        bites = {
            "Press play: the dots follow.": "run_the_project",
            "Hit PLAY again.": "run_the_project",
            "Play the scene again.": "run_the_project",
            "Click the arrow at the top right.": "run_the_project",
            "Start the game from the toolbar.": "run_the_project",
            "Launch the project again.": "run_the_project",
            "Run your project again.": "run_the_project",
            "Run the room again.": "run_the_project",
            "Press Cmd+B on a Mac.": "run_the_project",
            "Press F 5 again.": "run_the_project",
            "Press ▶ again.": "run_the_project",
            "Press `F5` again.": "run_the_project",
            "Press F6 to run only this scene.": "run_the_scene",
            "Run only the open scene.": "run_the_scene",
            "Press the + above the scene tree, then pick `MeshInstance3D`.": "add_a_node",
            "Click + above the scene tree.": "add_a_node",
            "Press Ctrl+A over the scene tree.": "add_a_node",
            "Double-click it and type `Dot`.": "add_a_node",
            "Create a `Node3D`.": "add_a_node",
            "Make a `MeshInstance3D` named `Dot` with a small `SphereMesh`.": "add_a_node",
            # Save As was the old way to a new script file: its wordings say make a new script
            "Choose File, then Save as, and type `bell2.gd`.": "make_a_new_script",
            "Save the file as `bell2.gd`.": "make_a_new_script",
            "Save this script as `bell2.gd`.": "make_a_new_script",
            "Create a new script `bell2.gd`.": "make_a_new_script",
            "Choose File, then New Script.": "make_a_new_script",
            "Attach `bell.gd` to the top node.": "put_a_script_on_a_node",
            "Attach the supplied `contact_probe.gd` to it.": "put_a_script_on_a_node",
            "Drop `bell.gd` onto the top node.": "put_a_script_on_a_node",
            # a supplied scene dropped is add a scene (1.6): the walker of 2.5 made it an admin
            "Drop `counter_panel.tscn` from the FileSystem onto the top node.": "add_a_scene",
            "Instance `walker.tscn` under the top node.": "add_a_scene",
        }
        for line, eid in bites.items():
            with self.subTest(line=line):
                self.assertIn(eid, [h[3].id for h in tax.admin_hits(line)])
        quiet = [
            "The feeler runs to the top right corner.",
            "The dots run off at the top right of the floor.",
            "Play around with `gap` until the court looks right.", "Play matters here.",
            "Play a sound when it lands.", "Play the dots back slowly.",
            "`build` is a function: a waiting thread will run it.",
            "Write the function, then run it once from `_ready`.",
            "The main scene is the scene Godot runs first.",
            "Press Play in the animation panel to preview the clip.",
            "Give the panel a + button.", "Press + to zoom in.",
            "Double-click the file name to open it.", "Choose Save As to keep the old scene.",
            "The box stands at the top right of the court.",
            "The top right of the Inspector holds the mesh.",
            "Code can add a `MeshInstance3D` too, with `add_child()`.",
            "Godot fills the new script with some code.",
            "Right-click the top node and choose Attach Script.",
        ]
        for line in quiet:
            with self.subTest(line=line):
                self.assertEqual(tax.admin_hits(line), [])
        # a script dropped is no scene added: the step phrase drop counts beside a .tscn only
        self.assertNotIn("add_a_scene", [h[3].id for h in tax.admin_hits("Drop `bell.gd` onto the top node.")])
        # a call is an instruction; teaching add_child is none
        calls = {
            "Under `Solid`, add a `MeshInstance3D` with a `SphereMesh`.": ["add_a_node"],
            "Add five `MeshInstance3D` nodes, each with a primitive.": ["add_a_node"],
            "Set it in the Inspector, then run the project.": ["run_the_project"],
            "Code in `_ready` runs once, when you run the project.": ["run_the_project"],
            "`add_child()` is how code can add a `MeshInstance3D` to the scene.": [],
            "`add_child()` is how code can add a node.": [],
            "Twelve lines need twelve beads: add twelve `MeshInstance3D` nodes by code.": [],
            "Make a new script `bell.gd`.": ["make_a_new_script"],
            "Put `bell.gd` on the top node.": ["put_a_script_on_a_node"],
            "Put the supplied `contact_probe.gd` on the new `Node3D`.": ["put_a_script_on_a_node"],
            "Put `bell.gd` on the top node, then run the project.": ["put_a_script_on_a_node",
                                                                     "run_the_project"],
            "Add `walker.tscn` to the top node.": ["add_a_scene"],
            "Add the supplied `counter_panel.tscn` to the top node.": ["add_a_scene"],
        }
        for line, want in calls.items():
            with self.subTest(line=line):
                self.assertEqual([c[0].id for c in tax.admin_calls_of(line)], want)

    def test_adding_a_node_by_code_is_no_call(self):
        for line in ("Code can add a `Node3D` too.", "Then add a `Node3D` by code.",
                     "`add_child()` is how code can add a node."):
            with self.subTest(line=line):
                rep = self.run_admin(ch2=admin_ch2(extra_21=line))
                self.assertFalse(self.found(rep, "order", contains="add a node")
                                 or self.found(rep, "signature", contains="add a node"),
                                 "\n".join(rep.lines()))


# ------------------------------------------------------------------ keep= (chapter 5)

# 2.2 keeps 2.1's _process: the page shows it once, and the run still has it
KEEP_22 = """<!-- section 2.2
needs: frame, position, node, func, _ready, $, =, Vector3, _process
gives: shape
-->
## 2.2 A shape

A shape is what is touched.
Each frame, the node keeps its position.
Put a shape on it under `func _ready():`.
Keep `_process`: replace the rest.

<!-- code: nodes=Ball:Node3D keep=_process claim="$Ball.position.y == 1" -->
```gdscript
func _ready():
	$Ball.position = Vector3(0, 5, 0)
```
"""


def keep_ch2(block_opts="nodes=Ball:Node3D keep=_process", keep_line="Keep `_process`: replace the rest.\n",
             body="func _ready():\n\t$Ball.position = Vector3(0, 5, 0)\n"):
    sec = KEEP_22.replace("nodes=Ball:Node3D keep=_process", block_opts).replace(
        "Keep `_process`: replace the rest.\n", keep_line).replace(
        "func _ready():\n\t$Ball.position = Vector3(0, 5, 0)\n", body)
    start = CH2.index("<!-- section 2.2")
    end = CH2.index("<!-- section 2.x")
    return CH2[:start] + sec + "\n" + CH2[end:]


class TestKeep(Base):
    def test_a_kept_member_is_named_and_defined_earlier(self):
        rep = self.run_check(ch2=keep_ch2())
        self.assertFalse(self.found(rep, "keep"), "\n".join(rep.lines()))

    def test_keep_without_a_line_that_names_it_bites(self):
        ch2 = keep_ch2(keep_line="")
        rep = self.run_check(ch2=ch2)
        self.assertBites(rep, "keep", file="ch02.md", line=line_no(ch2, "keep=_process") ,
                         contains="never told it stays")

    def test_keep_of_a_name_no_earlier_example_defines_bites(self):
        ch2 = keep_ch2(block_opts="nodes=Ball:Node3D keep=_process,lift",
                       keep_line="Keep `_process` and `lift()`: replace the rest.\n")
        rep = self.run_check(ch2=ch2)
        self.assertBites(rep, "keep", file="ch02.md", contains="no earlier example of chapter 2 "
                         "defines `lift`")

    def test_keep_and_show_again_bites(self):
        ch2 = keep_ch2(body="func _ready():\n\t$Ball.position = Vector3(0, 5, 0)\n\n"
                            "func _process(_delta):\n\tpass\n")
        rep = self.run_check(ch2=ch2)
        self.assertBites(rep, "keep", file="ch02.md", contains="keep it or show it, not both")

    def test_a_member_ends_at_its_closing_bracket(self):
        lines = ["var steps := [", "\t1,", "\t2,", "]", "var beat := 0", "", "func go():",
                 "\tbeat += 1", "", "# a comment", "func stop():", "\tpass"]
        self.assertEqual(check.member_spans(lines),
                         [("steps", 0, 4), ("beat", 4, 5), ("go", 6, 8), ("stop", 10, 12)])
        self.assertEqual(check.member_spans(["@export var colour := Color(1, 0, 0)"]),
                         [("colour", 0, 1)])


# ------------------------------------------------------------------ pass g: Godot

@unittest.skipUnless(HAVE_GODOT, "Godot not found at %s" % GODOT)
class TestGodot(Base):
    # keep= (2 October 2026, chapter 5): the run holds the kept member, from where the page shows it
    def test_a_kept_member_runs(self):
        rep = self.run_check(ch2=keep_ch2(), godot=True)
        self.assertFalse(any(self.found(rep, r) for r in ("code", "run", "claim", "keep")),
                         "\n".join(rep.lines()))
        # without keep, the run has no _process: the ball stays at 5
        ch2 = keep_ch2(block_opts="nodes=Ball:Node3D", keep_line="")
        rep = self.run_check(ch2=ch2, godot=True)
        self.assertBites(rep, "claim", file="ch02.md", contains="does not hold")

    # an array whose last ']' stands at the left edge is a member, not a statement in _ready
    def test_an_array_closed_at_the_left_edge_is_a_member(self):
        ch1 = CH1.replace('<!-- code: nodes=Ball:Node3D prints="(1.0, 2.0, 3.0)" -->',
                          '<!-- code: nodes=Ball:Node3D prints="(1.0, 2.0, 3.0)" claim="steps.size() == 2" -->')
        ch1 = ch1.replace("`print` writes the position.",
                          "```gdscript\nvar steps := [\n\t1,\n\t2,\n]\n```\n\n`print` writes the position.")
        self.assertNotEqual(ch1, CH1)
        rep = self.run_check(ch1=ch1, godot=True)
        self.assertFalse(any(self.found(rep, r) for r in ("code", "run", "claim")),
                         "\n".join(rep.lines()))

    def test_fixture_parses_and_runs(self):
        rep = self.run_check(godot=True)
        self.assertClean(rep)

    def test_parse_error_is_mapped_to_its_line(self):
        ch1 = CH1.replace("\tprint($Ball.position)", "\tprint($Ball.position")
        rep = self.run_check(ch1=ch1, godot=True)
        self.assertBites(rep, "code", file="ch01.md", contains="Godot:")

    def test_runtime_error_in_a_run_block(self):
        ch2 = CH2.replace("<!-- code: nodes=Ball:Node3D -->", "<!-- code: run -->")
        rep = self.run_check(ch2=ch2, godot=True)
        self.assertBites(rep, "run", file="ch02.md", line=line_no(ch2, "\t$Ball.position = Vector3(0, 1, 0)"),
                         contains="Godot:")

    def test_expected_print_missing(self):
        ch1 = CH1.replace('prints="(1.0, 2.0, 3.0)"', 'prints="(9.0, 9.0, 9.0)"')
        rep = self.run_check(ch1=ch1, godot=True)
        self.assertBites(rep, "run", contains="expected the run to print")

    def test_a_fails_block_must_fail(self):
        good = CH1.replace("`print` writes the position.",
                           "<!-- code: fails -->\n```gdscript\nfunc _ready(:\n```\n\n`print` writes the position.")
        rep = self.run_check(ch1=good, godot=True)
        self.assertClean(rep)
        bad = CH1.replace("`print` writes the position.",
                          "<!-- code: fails -->\n```gdscript\nfunc _ready():\n\tprint(1)\n```\n\n`print` writes the position.")
        rep = self.run_check(ch1=bad, godot=True)
        self.assertBites(rep, "code", contains="should fail to parse")

    # the adversary, item 20: the Godot pass checked less than it seemed
    def test_20a_prints_matches_a_whole_line(self):
        ch1 = CH1.replace('prints="(1.0, 2.0, 3.0)"', 'prints="1.0, 2.0"')
        rep = self.run_check(ch1=ch1, godot=True)
        self.assertBites(rep, "run", contains="expected the run to print the line")

    def test_20c_every_block_runs(self):
        ch1 = CH1.replace("\t$Ball.position = Vector3(1, 2, 3)", "\t$Ball.position = Vector3(1, 2, 3)\n\t$Ghost.position = Vector3(1, 2, 3)")
        rep = self.run_check(ch1=ch1, godot=True)
        self.assertBites(rep, "run", line=line_no(ch1, "$Ghost"), contains="Godot:")

    def test_20d_an_error_late_in_the_run_is_caught(self):
        ch2 = CH2.replace("func _process(_delta):\n", "var t := 0\n\nfunc _process(_delta):\n\tt += 1\n"
                          "\tif t > 10:\n\t\t$Ghost.position = Vector3(0, 1, 0)\n")
        rep = self.run_check(ch2=ch2, godot=True)
        self.assertBites(rep, "run", line=line_no(ch2, "$Ghost"), contains="Godot:")

    def test_20e_a_stub_records_its_calls_for_a_claim(self):
        good = CH1.replace('prints="(1.0, 2.0, 3.0)"',
                           'prints="(1.0, 2.0, 3.0)" claim="$Supplied._ft_calls.count(\'stamp\') == 1"')
        rep = self.run_check(ch1=good, godot=True)
        self.assertClean(rep)
        bad = CH1.replace('prints="(1.0, 2.0, 3.0)"',
                          'prints="(1.0, 2.0, 3.0)" claim="$Supplied._ft_calls.count(\'stamp\') == 2"')
        rep = self.run_check(ch1=bad, godot=True)
        self.assertBites(rep, "claim", line=line_no(bad, "claim="), contains="does not hold")

    def test_20e_a_supplied_part_is_reached_where_it_lives(self):
        ch1 = CH1.replace("\t$Supplied.stamp($Ball.position)", "\tstamp($Ball.position)")
        rep = self.run_check(ch1=ch1, godot=True)
        self.assertBites(rep, "code", line=line_no(ch1, "\tstamp($Ball"), contains="Godot:")

    # 2 October 2026, chapter 4: a claim that raises an error in Godot crashed the checker
    # (a format string short of its arguments); it is a claim error, at the claim
    def test_21a_a_claim_that_errs_in_godot_is_a_claim_error(self):
        ch1 = CH1.replace('prints="(1.0, 2.0, 3.0)"',
                          'prints="(1.0, 2.0, 3.0)" claim="$Nowhere.position.y == 3"')
        self.assertNotEqual(ch1, CH1)
        rep = self.run_check(ch1=ch1, godot=True)
        self.assertBites(rep, "claim", line=line_no(ch1, "claim="), contains="Godot: in claim")

    def test_21_a_claim_that_does_not_hold(self):
        ch1 = CH1.replace('prints="(1.0, 2.0, 3.0)"', 'claim="$Ball.position.y == 3"')
        rep = self.run_check(ch1=ch1, godot=True)
        self.assertBites(rep, "claim", contains="does not hold")

    # a supplied scene is written where its host says, so preload() finds it (chapter 3)
    def test_a_supplied_scene_is_preloaded_from_its_host(self):
        scene = '[gd_scene format=3]\n\n[node name="Orb" type="Node3D"]\n'
        ch1 = CH1.replace('prints="(1.0, 2.0, 3.0)"', 'prints="(1.0, 2.0, 3.0)" claim="has_node(\'Orb\')"').replace(
            "extends Node3D\n\nfunc _ready():\n",
            'extends Node3D\n\nvar orb := preload("res://supplied/orb.tscn")\n\nfunc _ready():\n'
            "\tadd_child(orb.instantiate())\n", 1)
        self.assertNotEqual(ch1, CH1)
        godot_rules = ("code", "run", "claim")
        good = add(E("orb_scene", "supplied", [], ["orb.tscn"], "A saved orb.", "supplied:1.2",
                     stub=scene, host="res://supplied/orb.tscn"))
        rep = self.run_check(good, ch1=ch1, godot=True)
        self.assertFalse(any(self.found(rep, r) for r in godot_rules), "\n".join(rep.lines()))
        # written elsewhere, the scene is not found: Godot refuses the preload
        bad = add(E("orb_scene", "supplied", [], ["orb.tscn"], "A saved orb.", "supplied:1.2",
                    stub=scene, host="res://supplied/elsewhere.tscn"))
        rep = self.run_check(bad, ch1=ch1, godot=True)
        self.assertBites(rep, "code", file="ch01.md", contains="Godot:")

    def test_a_nested_scene_node(self):
        ch1 = CH1.replace("nodes=Ball:Node3D", "nodes=Ball:Node3D,Ball/Child:Node3D").replace(
            "\t$Ball.position = Vector3(1, 2, 3)", "\t$Ball.position = Vector3(1, 2, 3)")
        rep = self.run_check(ch1=ch1, godot=True)
        self.assertClean(rep)

    # one convention for scripts: each goes on the top node, a Node3D (FUNCTIONAL_TEXT 3)
    def test_top_node_a_script_the_top_node_can_hold_passes(self):
        rep = self.run_check(godot=True)
        self.assertFalse(self.found(rep, "top"), "\n".join(rep.lines()))

    def test_top_node_a_script_for_another_node_is_refused(self):
        bad = CH1.replace("```gdscript\nextends Node3D\n", "```gdscript\nextends MeshInstance3D\n", 1)
        self.assertNotEqual(bad, CH1)
        rep = self.run_check(ch1=bad, godot=True)
        self.assertBites(rep, "top", file="ch01.md", line=line_no(bad, "```gdscript"),
                         contains="this script is for a MeshInstance3D, and the text puts it on "
                                  "the top node, a Node3D")
        # on= says the script goes on another node: then a MeshInstance3D is right
        ok = bad.replace("<!-- code: nodes=Ball:Node3D", "<!-- code: on=MeshInstance3D nodes=Ball:Node3D", 1)
        rep = self.run_check(ch1=ok, godot=True)
        self.assertFalse(self.found(rep, "top"), "\n".join(rep.lines()))
        # switched off, the fault passes: the test bites by this rule
        saved = set(check.OFF)
        check.OFF.add("top-node")
        try:
            rep = self.run_check(ch1=bad, godot=True)
        finally:
            check.OFF.clear()
            check.OFF.update(saved)
        self.assertFalse(self.found(rep, "top"), "top-node is off, and the fault is still caught")

    def test_a_relative_workdir(self):
        cwd = os.getcwd()
        try:
            os.chdir(self.dir)
            rep = self.run_check(godot=True, workdir="gwrel")
        finally:
            os.chdir(cwd)
        self.assertClean(rep)


if __name__ == "__main__":
    unittest.main(verbosity=1)
