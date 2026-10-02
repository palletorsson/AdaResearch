#!/usr/bin/env python3
"""check.py - the checker for functional text (type-safe text).

A section is a function: it needs entries and gives entries.
A chapter is a module. The book is a program.
It compiles when every section's needs are given before it.
The form is defined in FUNCTIONAL_TEXT.md beside this file.

Usage
  python check.py --taxonomy taxonomy.json ch01.md ch02.md ...
  python check.py --taxonomy taxonomy.json --godot ch01.md
  python check.py --taxonomy taxonomy.json --sketch sketch.json [--chapters 1-3]

Output: one finding per line,
  file:line: rule: message              (an error)
  file:line: rule: warning: message     (a warning)
Exit code: the number of errors, capped at 255.

Passes
  a  taxonomy     the taxonomy is well formed
  b  gives        each section gives exactly what the taxonomy introduces there
  c  order        every technical token is known and introduced before its use
     unknown, style, form, signature belong to this pass
  d  synonym      no forbidden synonym
     admin        an admin procedure (run the project) is described once, in its defining
                  section, as its bold name and its steps; elsewhere it is only called by name
  e  unused       every introduced entry is used after its section
  f  length, sentence, filler, voice: short-speak
     device       no marker the page does not declare (enters:, from:, an arrow, [run] ...)
     list         lines in a tree: numbered steps and bullets, two levels at most, each child
                  at its parent's content offset, one sentence per item, a plain lead and point,
                  each list read as Markdown reads it; a lone numbered step warns
  g  code, run    each gdscript block parses in Godot; a run block runs headless
     top          each run block's script is one the root node, a Node3D, can hold

Python 3.10, standard library only.
"""

import argparse
import html
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import unicodedata

DEFAULT_GODOT = "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"
DEFAULT_FRAMES = 60     # a block runs this many frames unless it says frames=N

KINDS = ("concept", "maths", "gdscript", "godot", "supplied", "name", "plain", "admin")
TERM_KINDS = ("concept", "maths", "name")          # listed under **Types**
CODE_KINDS = ("gdscript", "godot", "supplied")     # listed under **Code** when given
EVERYDAY_KINDS = ("plain", "name")
# An admin procedure: scaffolding around the teaching (run the project, add a node). It is
# described once, in its defining section, as its bold name and its steps; after that the text
# says only its name. It is never listed in the Types box: the page links each call to it.
ADMIN = "admin"
# the slots of an admin call template: "add a {node}" is "Add a `Node3D`"
ADMIN_SLOTS = ("node", "code", "file", "n")
# Rules a test may switch off, to prove its test fails without them: FT_OFF=admin-again,...
OFF = set(x.strip() for x in os.environ.get("FT_OFF", "").split(",") if x.strip())
ADMIN_RULES = ("admin-taxonomy", "admin-order", "admin-again", "admin-define", "admin-signature",
               "admin-calls", "admin-link")
# the other switches: device (a marker that is no device of the page, FUNCTIONAL_TEXT 2b) and
# top-node (a script the root node cannot hold, FUNCTIONAL_TEXT 3)
OTHER_RULES = ("device", "top-node")
# the list rules (SHORT_SPEAK, Lines in a tree), each its own switch: a bullet deeper than two
# levels; an indented line with no list item above it; a child not at its parent's content
# offset; a section that ends on a list item; one that opens on a bullet; an item holding two
# sentences, on its line or by a line that goes on with it; two lists of one kind parted only
# by a blank line, which Markdown joins into one loose list; a numbered list right under a
# plain line that starts past 1, which Markdown reads into the line; and, a warning, a
# numbered list of one step with no children
LIST_RULES = ("list-depth", "list-orphan", "list-indent", "list-point", "list-lead",
              "list-sentence", "list-loose", "list-start", "list-lone")

EX = 999            # the exercises of chapter N sort as (N, 999)
HEAD = 0            # the chapter head sorts as (N, 0)

WARN_WORDS = 10
MAX_WORDS = 14

DEFAULT_FILLER = [
    "just", "simply", "now", "basically", "actually", "note that", "we will",
    "we'll", "let's", "let us", "in order to", "obviously", "clearly",
    "of course", "very", "really", "quite", "perhaps", "maybe", "probably",
    "somewhat",
]
# filler that is a plain word in another use: only a filler where the pattern says
FILLER_ONLY_AT = {
    "note that": r"(?:^|[:;,.]\s*)note\s+that\b",           # 'Note that ...', not 'the note that'
    "clearly": r"(?:^|[:;.]\s*)clearly\b|\bclearly\s*,",     # 'Clearly, ...', not 'label it clearly'
    "obviously": r"(?:^|[:;.]\s*)obviously\b|\bobviously\s*,",
}
# phrases in which a filler word is no filler
FILLER_EXEMPT = ["from now on", "simply connected", "right now"]
VOICE_WORDS = ["we", "our", "us", "i"]
# hedging: the lesson says what is so, not what might be
HEDGES = ["might", "could", "possibly", "seems", "seem", "seemed", "appears to", "appear to",
          "likely", "arguably", "somehow", "sort of", "kind of", "more or less", "tends to",
          "tend to", "presumably", "may be"]
# a thing that is not a person, doing what only a person does: poetry, not a claim
POETIC_VERBS = ["remembers", "remembered", "forgets", "forgot", "dreams", "dreamed", "dreamt",
                "yearns", "longs for", "whispers", "whispered", "sings", "sang", "breathes",
                "weeps", "wept", "mourns", "hopes", "wishes", "loves", "fears", "believes",
                "sighs", "longs", "owns", "knows", "wants"]
# The markers round one of the compression tests proposed and round two dropped (FUNCTIONAL_TEXT
# 2b): they cost words, moved no score, and stalled readers where a page used one undeclared.
# They are no device of the page. 'Restore:' is one, and stays.
# - a label that opens a prose line: 'enters:', 'from:', 'State:', 'Not yet:', 'Not here:'
# - an arrow that opens a prose line: '→ Start in the hall.', '-> ...'
# - a provenance tag anywhere in a prose line, bare or as the whole of a code span: [read] [run]
#   [derived]. A code span that holds more ('values[run]', '-> void') is code, not a marker.
DEVICE_LEAD = re.compile(r"^\s*(?:(?:enters|from|state|not\s+yet|not\s+here)\s*:|→|->)", re.IGNORECASE)
DEVICE_TAG = re.compile(r"(?<![\w\]])\[(?:read|run|derived)\](?![\w(\[:])", re.IGNORECASE)
DEVICE_TAG_SPAN = re.compile(r"\s*\[(?:read|run|derived)\]\s*", re.IGNORECASE)
# the verbs an instruction starts with: numbers before its colon are inputs, not claims
IMPERATIVES = set("""add attach build carve change close count cut double drag draw drop find
give grow halve hold join keep let look lower make move name open pick press put raise read
replace run select set show split start swap try turn type walk watch write""".split())
NUMBER_WORDS = {
    "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15,
    "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19, "twenty": 20, "thirty": 30,
    "forty": 40, "fifty": 50, "sixty": 60, "seventy": 70, "eighty": 80, "ninety": 90,
    "hundred": 100, "thousand": 1000,
}
SMALL_NUMBERS = {"one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7,
                 "eight": 8, "nine": 9}
# characters a reader does not see, or sees as another letter
INVISIBLE = re.compile("[­​-‏  ‪-‮⁠-⁤﻿]")
CONFUSABLE = str.maketrans({
    "а": "a", "е": "e", "о": "o", "р": "p", "с": "c", "у": "y",
    "х": "x", "і": "i", "ѕ": "s", "ј": "j", "ԁ": "d", "ɡ": "g",
    "А": "A", "В": "B", "Е": "E", "К": "K", "М": "M", "Н": "H",
    "О": "O", "Р": "P", "С": "C", "Т": "T", "Х": "X",
    "ο": "o", "α": "a", "ε": "e", "ν": "v", "ρ": "p", "τ": "t",
    "ι": "i", "κ": "k", "Ο": "O", "Α": "A", "Β": "B", "Ε": "E",
})
# derived words: a technical word with an affix is still that word
DERIV_PREFIXES = ("pseudo", "counter", "hyper", "super", "multi", "quasi", "inter", "intra",
                  "micro", "macro", "semi", "anti", "auto", "mega", "poly", "non", "sub",
                  "un", "re")
DERIV_SUFFIXES = sorted("""s es ed ing er ers est ly al ally ial ical ically ic ics ity ities
ive ively ous ously less lessly like ful fully ness ish wise able ably ible ize izes ized izing
ise ises ised ising ation ations ational ion ions ate ates ated ating ism ist ists ment ments
""".split(), key=len, reverse=True)
DERIV_ENDINGS = ("ation", "ition", "ion", "ity", "ence", "ance", "on", "us", "y", "e", "a")
# Godot's virtual methods: a func with one of these names is a Godot element, never your own
GODOT_VIRTUALS = set("""_init _ready _process _physics_process _input _unhandled_input
_unhandled_key_input _shortcut_input _enter_tree _exit_tree _notification _draw _gui_input
_integrate_forces _to_string _get _set _get_property_list _validate_property _static_init
_get_configuration_warnings _initialize _finalize _can_drop_data _drop_data _get_drag_data
_make_custom_tooltip _has_point _get_minimum_size _run _property_can_revert
_property_get_revert""".split())
FENCE_LANGS = ("gdscript", "gd", "gdshader", "text")
CODE_LANGS = ("gdscript", "gd", "gdshader")

# Technical words that must be accounted for by the taxonomy when they appear.
# A word here that is no form of any entry is an unintroduced element.
JARGON_WORDS = """
algorithm algorithms argument arguments array arrays attribute attributes
boolean booleans bool buffer buffers byte bytes callback callbacks class classes
collider colliders collision collisions compile compiler component components
conditional conditionals constant constants constructor constructors coordinate
coordinates debugger delta derivative derivatives dictionary dictionaries enum
enums expression expressions float floats fragment frame frames framerate
function functions gradient gradients hitbox hitboxes index indices inheritance
instance instances instantiate integer integers interpolate interpolation
iterate iteration iterations keyword keywords lerp loop loops material materials
matrix matrices mesh meshes method methods modulo node nodes object objects
operator operators parameter parameters parent parents child children parse
parser physics pixel pixels polygon polygons primitive primitives procedure
procedures property properties quaternion quaternions radian radians recursion
recursive render rendering rigidbody runtime scalar scalars scene scenes script
scripts shader shaders signal signals sprite sprites statement statements string
strings subroutine subroutines syntax texture textures transform transforms
tuple tuples uv variable variables vector vectors vertex vertices viewport
viewports voxel voxels origin axis axes degree degrees velocity acceleration
force forces mass gravity momentum friction random randomness seed noise
probability distribution histogram sine cosine amplitude frequency phase
fractal fractals graph graphs genome fitness mutation crossover entropy neuron
neurons perceptron stack stacks queue queues uniform uniforms thread threads
json rgb hsv input inputs inspector editor
raycast raycasts raycasting ray rays rotation rotations rotate rotates rotated rotating camera
cameras grid grids lattice lattices tween tweens tweening basis normal normals impulse impulses torque inertia stiffness damping elasticity spring
springs lambda lambdas callable callables closure closures null nil iterator iterators hashmap
singleton singletons autoload autoloads mutex semaphore coroutine coroutines await yield emit
emits emitted albedo emission specular roughness metallic occlusion framebuffer rasterize
antialiasing mipmap mipmaps tangent tangents integral integrals determinant logarithm
logarithms exponent exponents exponential polynomial polynomials slerp normalize normalized
magnitude variance deviation gaussian median topology manifold manifolds isosurface
isosurfaces metaball metaballs falloff gyroid gyroids voronoi delaunay perlin simplex octave
octaves lacunarity wavelength neural backpropagation centroid centroids heightmap heightfield
""".split()
JARGON_PHRASES = ["dot product", "cross product", "collision shape", "hit box", "frame rate",
                  "game loop", "floating point", "whole number", "whole numbers", "scene graph"]

# ---------------------------------------------------------------- reporting


class Report:
    def __init__(self):
        self.items = []
        self.seen = set()
        self.file_order = {}

    def add(self, sev, file, line, rule, msg):
        key = (sev, file, int(line or 1), rule, msg)
        if key in self.seen:
            return
        self.seen.add(key)
        self.file_order.setdefault(file, len(self.file_order))
        self.items.append(key)

    def error(self, file, line, rule, msg):
        self.add("error", file, line, rule, msg)

    def warn(self, file, line, rule, msg):
        self.add("warning", file, line, rule, msg)

    def note(self, file, line, rule, msg):
        self.add("note", file, line, rule, msg)

    def count(self, sev):
        return sum(1 for i in self.items if i[0] == sev)

    def errors(self):
        return self.count("error")

    def rules(self, sev="error"):
        return [i[3] for i in self.items if i[0] == sev]

    def lines(self):
        out = []
        for sev, f, ln, rule, msg in sorted(
                self.items, key=lambda i: (self.file_order[i[1]], i[2])):
            name = os.path.basename(f)
            if sev == "error":
                out.append("%s:%d: %s: %s" % (name, ln, rule, msg))
            else:
                out.append("%s:%d: %s: %s: %s" % (name, ln, rule, sev, msg))
        return out


# ---------------------------------------------------------------- sections

SEC_RE = re.compile(r"^(\d+)\.(\d+|x)$")


def sec_key(s):
    if not isinstance(s, str):
        return None
    m = SEC_RE.match(s.strip())
    if not m:
        return None
    return (int(m.group(1)), EX if m.group(2) == "x" else int(m.group(2)))


def sec_name(k):
    if k is None:
        return "?"
    if k == (0, 0):
        return "everyday"
    if k[1] == EX:
        return "%d.x" % k[0]
    if k[1] == HEAD:
        return "chapter %d head" % k[0]
    return "%d.%d" % k


def sec_id(k):
    """The id a taxonomy writes for a section key: 4.2, 4.x, or 4.0 for a chapter head."""
    if k is None:
        return "?"
    if k[1] == EX:
        return "%d.x" % k[0]
    return "%d.%d" % k


def line_of(text, pos):
    return text.count("\n", 0, pos) + 1


# ---------------------------------------------------------------- taxonomy


class Entry:
    def __init__(self, raw, line):
        self.raw = raw
        self.line = line
        self.id = raw.get("id")
        forms = raw.get("forms") or {}
        self.text = list(forms.get("text") or []) if isinstance(forms, dict) else []
        self.code = list(forms.get("code") or []) if isinstance(forms, dict) else []
        self.kind = raw.get("kind")
        self.definition = raw.get("def") or ""
        self.introduced_at = raw.get("introduced_at")
        self.opened_at = raw.get("opened_at")
        self.synonyms = list(raw.get("synonyms") or [])
        self.depends_on = list(raw.get("depends_on") or [])
        self.stub = raw.get("stub")
        self.host = raw.get("host")     # where a supplied stub lives: $Node or res://path.gd
        self.other_senses = raw.get("other_senses") or []
        self.late_deps = list(raw.get("late_deps") or [])   # known order breaks, declared
        # an admin procedure: the phrases that would describe its steps again, each counted
        # alone or only on a line that holds one of its cues; and its call templates
        self.step_phrases = []      # (phrase, cues or None); (None, None) is malformed
        for sp in raw.get("step_phrases") or []:
            if isinstance(sp, str) and sp.strip():
                self.step_phrases.append((sp.strip(), None))
            elif (isinstance(sp, dict) and isinstance(sp.get("phrase"), str) and sp["phrase"].strip()
                  and isinstance(sp.get("cues"), list) and sp["cues"]
                  and all(isinstance(c, str) and c.strip() for c in sp["cues"])):
                self.step_phrases.append((sp["phrase"].strip(), [c.strip() for c in sp["cues"]]))
            else:
                self.step_phrases.append((None, None))
        self.calls = list(raw.get("calls") or [])
        # words that make a line about another Play: 'Press Play in the animation panel'
        self.unless = [u.strip() for u in raw.get("unless") or [] if isinstance(u, str) and u.strip()]
        self.unless_bad = any(not (isinstance(u, str) and u.strip()) for u in raw.get("unless") or [])
        self.intro_key = None       # given at this section
        self.supplied_key = None    # handed out at this section
        self.opened_key = None      # a supplied part taught at this section
        self.own_chapter = None     # N.x: a name chapter N's examples give it; its own, nobody else's
        self.everyday = False
        self.missing = False        # used, and never taught: the checker reports every use
        ia = self.introduced_at
        if ia == "everyday":
            self.everyday = True
        elif ia == "missing":
            self.missing = True
        elif isinstance(ia, str) and ia.startswith("supplied:"):
            self.supplied_key = sec_key(ia[len("supplied:"):])
        else:
            self.intro_key = sec_key(ia)
            if self.intro_key and self.intro_key[1] == EX:
                self.own_chapter = self.intro_key[0]
        if self.opened_at is not None:
            self.opened_key = sec_key(self.opened_at)

    @property
    def avail(self):
        if self.everyday:
            return (0, 0)
        return self.intro_key or self.supplied_key

    def late(self, limit):
        """True when the entry may not be used at limit: introduced later, or never,
        or a chapter's own name used outside that chapter."""
        if self.everyday:
            return False
        if self.own_chapter is not None:
            return limit is None or limit[0] != self.own_chapter
        return self.avail is None or limit is None or self.avail > limit

    def where(self):
        if self.everyday:
            return "everyday"
        if self.missing:
            return "never taught"
        if self.own_chapter is not None:
            return "chapter %d's own name, from its examples" % self.own_chapter
        if self.supplied_key:
            return "supplied at %s" % sec_name(self.supplied_key)
        if self.intro_key and self.intro_key[1] == HEAD:
            return "chapter %d, no section" % self.intro_key[0]
        return sec_name(self.intro_key)

    def sense_at(self, word, key):
        """The other sense declared for this word at this section, or None."""
        w = norm_phrase(word or "")
        sid = sec_id(key)
        for s in self.other_senses:
            if not isinstance(s, dict):
                continue
            words = [norm_phrase(x) for x in s.get("words") or []]
            if w in words and sid in (s.get("at") or []):
                return s.get("sense") or "another sense"
        return None

    def label(self):
        if self.text:
            return self.text[0]
        if self.code:
            return "`%s`" % self.code[0]
        return self.id

    @property
    def is_admin(self):
        return self.kind == ADMIN

    def call_line(self):
        """How the text calls an admin procedure: its name as a step line, 'Run the project.'"""
        n = self.text[0] if self.text else self.id
        return n[:1].upper() + n[1:] + "."

    def slug(self):
        return admin_slug(self.text[0] if self.text else self.id)


def admin_slug(name):
    """The id the page gives an admin's defining line: 'run the project' -> run-the-project."""
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def phrase_regex(phrase, any_case=False):
    """A regex for an admin phrase. A word with a capital is a label and matches as written
    (Play, Select Current, F5); a word in lower case matches in any case. A synonym is a whole
    wording and matches in any case (any_case): 'press play' and 'Hit PLAY' are 'press Play'.
    A function key may be spelt with a space: F5 is also 'F 5'."""
    words = [w for w in re.split(r"[\s-]+", phrase.strip()) if w]
    parts = []
    for w in words:
        fk = re.fullmatch(r"F(\d{1,2})", w)
        if fk:
            part = r"F[\s-]?%s" % fk.group(1)
            parts.append("(?i:%s)" % part if any_case else part)
        elif any_case or not any(c.isupper() for c in w):
            parts.append("(?i:%s)" % re.escape(w))
        else:
            parts.append(re.escape(w))
    return re.compile(r"(?<![\w])" + r"[\s-]+".join(parts) + r"(?![\w])")


def cue_regex(cue):
    """A cue of a step phrase, or a word of an admin's unless: a phrase, or, when it starts or
    ends in a mark ('.gd'), a plain substring in any case, since a file name holds it."""
    c = cue.strip()
    if re.match(r"\W", c) or re.search(r"\W$", c):
        return re.compile(re.escape(c), re.IGNORECASE)
    return phrase_regex(c)


SENTENCE_START = re.compile(r"(?:^|[.!?:]\s+|^\W+)$")
# A label that opens a sentence is the button only when what follows makes it a noun: 'Play.',
# 'Play, at the top right', 'Play is the button'. 'Play a sound', 'Play around' are the verb.
LABEL_AS_NOUN = re.compile(r"\s*(?:[.,:;!?)]|$|button\b|buttons\b|is\b|runs?\b|starts?\b|sits?\b)",
                           re.IGNORECASE)
# A call is an instruction to the student: it opens its clause, or follows 'then', 'and',
# 'you'... 'Set it in the Inspector, then run the project.' 'Code in `_ready` runs once, when you
# run the project.' 'how code can add a node' is no call: code does it, not the student.
CALL_BEFORE = re.compile(r"(?:^|[,(]|\b(?:then|and|or|next|first|now|also|again|you|to|before|"
                         r"after|when|while|until|once)|\byou\s+(?:can|will|must|should|may))\s*$",
                         re.IGNORECASE)
# a sentence about what code does: adding a node by code is the lesson of add_child, no call
CODE_SENTENCE = re.compile(r"add_child|\.new\(|\b(?:by|in|from|with|through)\s+code\b",
                           re.IGNORECASE)
# a pronoun wording ('run it') is the procedure only where it ends its clause or goes on to
# 'again': 'Run it: the dots follow.' 'then run it once from `_ready`' runs a function
PRONOUN_AFTER = re.compile(r"\s*(?:[.:,;!?(]|$|again\b|and\b|now\b|with\b)", re.IGNORECASE)


def call_position(view, start, line=None):
    """True when the words at view[start:] stand where a call stands: at the head of their
    clause, or after 'then', 'and', 'you', ..., and in no sentence about code."""
    head = view[:start]
    cut = max(head.rfind(c) for c in ".!?;:")
    head = head[cut + 1:]
    if not CALL_BEFORE.search(head.rstrip()):
        return False
    return not CODE_SENTENCE.search(line if line is not None else view)


def split_sentences(text):
    return [s for s in re.split(r"(?<=[.!?])\s+", (text or "").strip()) if s]


def norm_step(s):
    s = re.sub(r"\s+", " ", (s or "").strip())
    return s[:1].lower() + s[1:]


def is_plain_word(form):
    return bool(re.fullmatch(r"[a-z]+", form))


def is_symbol(form):
    return bool(re.fullmatch(r"[-+*/%=<>!&|^~:$@\[\]{}.]+", form))


def form_regex(forms, flags=re.IGNORECASE):
    """One regex over many forms; longest first so the longest phrase wins.
    The words of a phrase may be joined by spaces or hyphens: dot-product is dot product."""
    alts = sorted(set(f for f in forms if f), key=len, reverse=True)
    if not alts:
        return None
    pat = "|".join(r"[\s-]+".join(re.escape(w) for w in re.split(r"[\s-]+", f.strip()) if w)
                   for f in alts)
    return re.compile(r"(?<![\w])(?:" + pat + r")(?![\w])", flags)


def norm_phrase(s):
    return re.sub(r"[\s-]+", " ", s.strip().lower())


def case_exact(form):
    """A form with a capital letter is a proper name or a label (Play, Inspector, P1): it
    matches only as written, so the verb 'play' and 'p1' in a formula are not it."""
    return any(c.isupper() for c in form)


def is_acronym(form):
    return bool(re.fullmatch(r"[A-Z][A-Z0-9]{0,3}", form))


class Taxonomy:
    def __init__(self, path, rep):
        self.path = path
        self.rep = rep
        self.entries = {}
        self.order = []
        self.text_index = {}     # lower text form -> id
        self.code_index = {}     # code form (incl. signatures) -> id
        self.syn_index = {}      # lower synonym -> id
        self.chapters = None
        self.filler = list(DEFAULT_FILLER)
        self.jargon = set()
        self.raw_text = ""
        self.dep_facts = []      # (entry, dependency introduced later or never)
        self.ok = self._load()

    def _load(self):
        rep, path = self.rep, self.path
        try:
            with open(path, encoding="utf-8") as f:
                self.raw_text = f.read()
            data = json.loads(self.raw_text)
        except (OSError, ValueError) as e:
            rep.error(path, 1, "taxonomy", "cannot read taxonomy: %s" % e)
            return False
        if isinstance(data, dict):
            raw_entries = data.get("entries", [])
            self.chapters = data.get("chapters")
            if isinstance(data.get("filler"), list):
                self.filler = list(data["filler"])
            extra = data.get("jargon") or []
        else:
            raw_entries, extra = data, []
        self.jargon = set(norm_phrase(w) for w in JARGON_WORDS + JARGON_PHRASES + list(extra))
        for raw in raw_entries:
            eid = raw.get("id") if isinstance(raw, dict) else None
            ln = 1
            if isinstance(eid, str):
                m = re.search(r'"id"\s*:\s*' + re.escape(json.dumps(eid, ensure_ascii=False)),
                              self.raw_text)
                if not m:
                    m = re.search(r'"id"\s*:\s*' + re.escape(json.dumps(eid)), self.raw_text)
                if m:
                    ln = line_of(self.raw_text, m.start())
            if not isinstance(raw, dict):
                rep.error(path, ln, "taxonomy", "an entry is not an object")
                continue
            e = Entry(raw, ln)
            if not isinstance(e.id, str) or not e.id:
                rep.error(path, ln, "taxonomy", "an entry has no id")
                continue
            if e.id in self.entries:
                rep.error(path, ln, "taxonomy", "duplicate id %r (first at line %d)"
                          % (e.id, self.entries[e.id].line))
                continue
            self.entries[e.id] = e
            self.order.append(e)
        for e in self.order:
            for f in e.text:
                k = norm_phrase(f)
                if k in self.text_index and self.text_index[k] != e.id:
                    rep.error(path, e.line, "taxonomy", "text form %r of %r is already a form of %r"
                              % (f, e.id, self.text_index[k]))
                else:
                    self.text_index[k] = e.id
            for f in e.code:
                if f in self.code_index and self.code_index[f] != e.id:
                    rep.error(path, e.line, "taxonomy", "code form %r of %r is already a form of %r"
                              % (f, e.id, self.code_index[f]))
                else:
                    self.code_index[f] = e.id
        for e in self.order:
            for s in e.synonyms:
                k = norm_phrase(s)
                if k in self.text_index:
                    rep.error(path, e.line, "taxonomy",
                              "synonym %r of %r is a text form of %r"
                              % (s, e.id, self.text_index[k]))
                    continue
                if e.is_admin:
                    continue        # an admin's synonyms are read by the admin rule, not here
                if k in self.syn_index and self.syn_index[k] != e.id:
                    rep.warn(path, e.line, "taxonomy", "synonym %r is listed by %r and %r"
                             % (s, self.syn_index[k], e.id))
                self.syn_index[k] = e.id
        # matchers: a form with a capital matches as written; the rest in any case
        tagged, exact = {}, {}
        for e in self.order:
            for f in e.text:
                k = norm_phrase(f)
                if self.text_index.get(k) != e.id:
                    continue
                if case_exact(f):
                    exact[re.sub(r"[\s-]+", " ", f.strip())] = ("text", e.id)
                    if e.is_admin:      # an admin's name opens a line with a capital too
                        g = re.sub(r"[\s-]+", " ", f.strip())
                        exact.setdefault(g[:1].upper() + g[1:], ("text", e.id))
                else:
                    tagged[k] = ("text", e.id)
        for e in self.order:
            for s in e.synonyms:
                k = norm_phrase(s)
                if e.is_admin or self.syn_index.get(k) != e.id or k in self.text_index:
                    continue
                if case_exact(s):
                    exact.setdefault(re.sub(r"[\s-]+", " ", s.strip()), ("syn", e.id))
                else:
                    tagged.setdefault(k, ("syn", e.id))
        self.tagged = tagged
        self.exact = exact
        self.known_lower = set(self.text_index) | set(self.syn_index)
        self.prose_re = form_regex(tagged.keys())
        self.exact_re = form_regex(exact.keys(), flags=0)
        self.sig_forms = sorted((f for f in self.code_index if "(" in f), key=len, reverse=True)
        jar = [j for j in self.jargon if j not in self.known_lower]
        self.jargon_re = form_regex(jar)
        # inflections and derivations of technical text forms
        self.inflect = {}
        self.derive = {}         # first four letters -> [(stem, entry id)]
        for e in self.order:
            if e.kind in EVERYDAY_KINDS:
                continue
            for f in e.text:
                if case_exact(f) or " " in f or "-" in f or len(f) < 3:
                    continue
                for v in inflections(f):
                    if v in self.known_lower or v in self.inflect or v in self.code_index:
                        continue    # a code word (sin beside sines) is no inflection
                    self.inflect[v] = e.id
                if len(f) < 4:
                    continue
                for st in stems_of(f):
                    self.derive.setdefault(st[:4], []).append((st, e.id))
        self._load_admin()
        return True

    def _load_admin(self):
        """The admin procedures: the phrases that describe their steps again, the synonym
        templates ('create a {node}'), the classes a {node} slot accepts, and the call
        templates."""
        self.admins = [e for e in self.order if e.is_admin]
        self.admin_phrases = []      # (regex, entry, phrase, "syn" or "step", cue regexes)
        self.admin_syn_templates = []    # (entry, template, regex)
        for e in self.admins:
            for s in e.synonyms:
                if "{" in s:
                    rx = self.template_regex(s)
                    if rx is not None:
                        self.admin_syn_templates.append((e, s, rx))
                    continue
                self.admin_phrases.append((phrase_regex(s, any_case=True), e, s, "syn", None))
            for p, cues in e.step_phrases:
                if p:
                    self.admin_phrases.append((phrase_regex(p), e, p, "step",
                                               [cue_regex(c) for c in cues] if cues else None))
        self.admin_unless = {e.id: [cue_regex(u) for u in e.unless] for e in self.admins}
        self.admin_names = {}        # normalised name -> entry
        self.admin_name_keys = {}    # a name without its little words -> entry: 'run project'
        for e in self.admins:
            for f in e.text:
                self.admin_names[norm_phrase(f)] = e
                self.admin_name_keys.setdefault(name_key(f), e)
        self.admin_name_res = [(e, form_regex(e.text)) for e in self.admins if e.text]
        # a node class: an entry of Godot whose depends_on reaches the concept node
        reach = {}

        def reaches_node(eid, seen=()):
            if eid in reach:
                return reach[eid]
            if eid == "node":
                return True
            e = self.entries.get(eid)
            if e is None or eid in seen:
                return False
            r = any(reaches_node(d, seen + (eid,)) for d in e.depends_on)
            reach[eid] = r
            return r

        self.node_classes = set()
        for e in self.order:
            if e.kind == "godot" and e.depends_on and reaches_node(e.id):
                self.node_classes.update(c for c in e.code if re.fullmatch(r"[A-Z]\w*", c))
        self.admin_calls = []        # (entry, template, regex)
        for e in self.admins:
            for t in e.calls:
                rx = self.template_regex(t)
                if rx is not None:
                    self.admin_calls.append((e, t, rx))

    @staticmethod
    def template_regex(t):
        """'add a {node}' -> a regex over a line with its code spans: 'Add a `Node3D`'.
        {node}, {code}, {file}: one code span; {n}: a number, in digits or words."""
        if not isinstance(t, str) or not t.strip():
            return None
        parts = []
        for w in t.split():
            m = re.fullmatch(r"\{(\w+)\}", w)
            if m:
                if m.group(1) not in ADMIN_SLOTS:
                    return None
                if m.group(1) == "n":
                    parts.append(r"(?:\d+|%s)" % "|".join(list(SMALL_NUMBERS) + list(NUMBER_WORDS)))
                else:
                    parts.append(r"`(?P<%s%d>[^`]+)`" % (m.group(1), len(parts)))
            elif "{" in w or "}" in w:
                return None
            else:
                parts.append(re.escape(w))
        return re.compile(r"(?<![\w`])" + r"\s+".join(parts), re.IGNORECASE)

    def admin_view(self, line):
        """The line as the admin rule reads it, at the same length: each code span blanked, but
        a span that holds a key or a label (`F5`, `Play`, `Ctrl+S`) read as its words."""
        def sub(m):
            body = m.group(1).strip()
            if body not in self.code_index and KEY_SPAN.fullmatch(body):
                return " " + m.group(1) + " "
            return " " * len(m.group(0))
        return CODE_SPAN.sub(sub, line)

    def _slots_ok(self, m):
        """A template's slots hold what they say: {node} a node class, {file} a file name."""
        for k, v in m.groupdict().items():
            slot = re.sub(r"\d+$", "", k)
            v = (v or "").strip()
            if slot == "node" and v not in self.node_classes:
                return False
            if slot == "file" and not FILE_NAME.fullmatch(v):
                return False
        return True

    def call_advice(self, e, m=None):
        """What to say instead: the call by name, or, for a template wording, the call template
        with the same argument: 'Create a `Node3D`' -> 'Add a `Node3D`.'"""
        if m is None or not e.calls:
            return e.call_line()
        groups = sorted(m.groupdict().items(), key=lambda kv: int(re.sub(r"\D", "", kv[0]) or 0))
        args = [v for k, v in groups if v]
        out = e.calls[0]
        for slot in re.findall(r"\{(\w+)\}", e.calls[0]):
            out = out.replace("{%s}" % slot, ("`%s`" % args.pop(0)) if args else "...", 1)
        return out[:1].upper() + out[1:] + "."

    def admin_hits(self, line):
        """Every wording of an admin procedure in a line, other than its name: a synonym, a step
        phrase, a synonym template ('Create a `Node3D`'). (start, end, word, entry, tag, advice),
        left to right, the longest where two overlap. The line keeps its code spans; a span that
        holds a key (`F5`) is read as words.
        - A step phrase with cues counts only on a line that holds one of them; cues and an
          admin's unless words are read with the code spans, so '.gd' finds `bell.gd`.
        - A synonym that opens with a verb ('run it', 'press Play') counts only as a call: at the
          head of its clause, or after 'then', 'you', ...; never in a sentence about code. One
          that ends in 'it' counts only where it ends its clause or goes on to 'again'.
        - A label that opens a sentence is the button only as a noun: 'Play, at the top right';
          'Play a sound' and 'Play around' are the verb."""
        view = self.admin_view(line)
        plain = line.replace("`", " ")
        hits = []
        for rx, e, phrase, tag, cues in self.admin_phrases:
            for m in rx.finditer(view):
                if cues and not any(c.search(plain) for c in cues):
                    continue
                if any(u.search(plain) for u in self.admin_unless.get(e.id, ())):
                    continue
                if tag == "syn" and phrase[:1].islower():
                    if not call_position(view, m.start(), plain):
                        continue
                    if (re.search(r"\b(?:it|them)$", phrase, re.IGNORECASE)
                            and not PRONOUN_AFTER.match(view, m.end())):
                        continue
                if (tag == "step" and re.fullmatch(r"[A-Z][a-z]+", phrase)
                        and SENTENCE_START.search(view[:m.start()])
                        and not LABEL_AS_NOUN.match(view, m.end())):
                    continue
                hits.append((m.start(), m.end(), m.group(0), e, tag, e.call_line()))
        for e, t, rx in self.admin_syn_templates:
            for m in rx.finditer(line):
                if not self._slots_ok(m) or not call_position(view, m.start(), plain):
                    continue
                if any(u.search(plain) for u in self.admin_unless.get(e.id, ())):
                    continue
                hits.append((m.start(), m.end(), m.group(0), e, "syn", self.call_advice(e, m)))
        hits.sort(key=lambda h: (h[0], -(h[1] - h[0])))
        out, end = [], -1
        for h in hits:
            if h[0] >= end:
                out.append(h)
                end = h[1]
        return out

    def calls_in(self, line, positional=True):
        """The admin calls a template finds in a line with its code spans: (entry, match).
        A {node} slot holds a node class: 'Add a `Vector3`' is no call of add a node. A call is
        an instruction: 'code can add a `Node3D`' and 'add twelve nodes by code' are none."""
        view = self.admin_view(line)
        plain = line.replace("`", " ")
        out = []
        for e, t, rx in self.admin_calls:
            for m in rx.finditer(line):
                if self._slots_ok(m) and (not positional or call_position(view, m.start(), plain)):
                    out.append((e, m))
        return out

    def admin_calls_of(self, line, positional=True):
        """Every call of an admin procedure in a line, by a name or by a template:
        (entry, start, end), left to right."""
        view = self.admin_view(line)
        plain = line.replace("`", " ")
        out = []
        for e, rx in self.admin_name_res:
            if rx is None:
                continue
            for m in rx.finditer(view):
                if not positional or call_position(view, m.start(), plain):
                    out.append((e, m.start(), m.end()))
        for e, m in self.calls_in(line, positional):
            out.append((e, m.start(), m.end()))
        return sorted(out, key=lambda x: x[1])

    def iter_forms(self, text):
        """Every text form or synonym in text: (start, end, word, tag, id), left to right,
        the longest first where two overlap. An acronym form right after a number (3 PM) is
        a unit, not the form."""
        hits = []
        for rx in (self.prose_re, self.exact_re):
            if rx is None:
                continue
            for m in rx.finditer(text):
                tv = self.lookup(m.group(0))
                if tv is None:
                    continue
                if is_acronym(m.group(0)) and re.search(r"\d\s*$", text[:m.start()]):
                    continue
                hits.append((m.start(), m.end(), m.group(0), tv[0], tv[1]))
        hits.sort(key=lambda h: (h[0], -(h[1] - h[0])))
        out, end = [], -1
        for h in hits:
            if h[0] >= end:
                out.append(h)
                end = h[1]
        return out

    def is_form(self, word):
        """Is this word (or phrase) a text form or synonym, in the case it is written?"""
        return (norm_phrase(word) in self.tagged
                or re.sub(r"[\s-]+", " ", word.strip()) in self.exact)

    def lookup(self, text):
        """(tag, id) for a match of prose_re or exact_re."""
        k = re.sub(r"[\s-]+", " ", text.strip())
        if k in self.exact:
            return self.exact[k]
        return self.tagged.get(norm_phrase(text))

    def derived(self, word):
        """The entry a word is derived from (accelerates, frictionless, pseudorandom,
        signalling), or None. The word itself is no form of anything."""
        w = word.lower()
        if len(w) < 5 or w in self.known_lower or w in self.code_index:
            return None
        if w in self.inflect:
            return self.inflect[w]
        cands = [w] + [w[len(p):] for p in DERIV_PREFIXES
                       if w.startswith(p) and len(w) - len(p) >= 4]
        for c in cands[1:]:
            if c in self.inflect:
                return self.inflect[c]          # re-shaped
            if c in self.tagged and self.tagged[c][0] == "text" and \
                    self.entries[self.tagged[c][1]].kind not in EVERYDAY_KINDS:
                return self.tagged[c][1]        # pseudo-random
        best = None
        for c in cands:
            for st, eid in self.derive.get(c[:4], ()):
                if not c.startswith(st):
                    continue
                rest = c[len(st):]
                ok = (rest == "" and c != w) or (rest and suffix_chain(rest))
                if not ok and rest and rest[0] == st[-1] and st[-1] not in "aeiouy":
                    ok = suffix_chain(rest[1:])      # signal-l-ing
                if ok and (best is None or len(st) > len(best[0])):
                    best = (st, eid)
        return best[1] if best else None

    def get(self, eid):
        return self.entries.get(eid)

    # --- pass a
    def validate(self):
        rep, path = self.rep, self.path
        for e in self.order:
            if e.kind not in KINDS:
                rep.error(path, e.line, "taxonomy", "%r: kind %r is not one of %s"
                          % (e.id, e.kind, ", ".join(KINDS)))
            if not isinstance(e.raw.get("forms"), dict):
                rep.error(path, e.line, "taxonomy", "%r: forms must be {\"text\": [...], \"code\": [...]}"
                          % e.id)
            elif not e.text and not e.code:
                rep.error(path, e.line, "taxonomy", "%r has no forms" % e.id)
            if not e.definition.strip():
                rep.error(path, e.line, "taxonomy", "%r has no def" % e.id)
            ia = e.introduced_at
            if not (e.everyday or e.missing or e.intro_key or e.supplied_key):
                rep.error(path, e.line, "taxonomy",
                          "%r: introduced_at %r is not a section (1.2), N.0, supplied:<section>, "
                          "everyday or missing" % (e.id, ia))
            if e.missing and e.kind == "plain":
                rep.error(path, e.line, "taxonomy", "%r: a plain word is everyday, never missing" % e.id)
            for s in e.other_senses:
                words = s.get("words") if isinstance(s, dict) else None
                at = s.get("at") if isinstance(s, dict) else None
                if not isinstance(words, list) or not isinstance(at, list) or not words:
                    rep.error(path, e.line, "taxonomy", "%r: other_senses items are "
                              "{\"words\": [...], \"at\": [sections], \"sense\": \"...\"}" % e.id)
                    continue
                forms = {norm_phrase(f) for f in e.text + e.synonyms}
                for w in words:
                    if norm_phrase(w) not in forms:
                        rep.error(path, e.line, "taxonomy", "%r: other sense word %r is no text form "
                                  "or synonym of it" % (e.id, w))
                for a in at:
                    if sec_key(a) is None:
                        rep.error(path, e.line, "taxonomy", "%r: other sense at %r is not a section"
                                  % (e.id, a))
            if e.everyday and e.kind not in EVERYDAY_KINDS:
                rep.error(path, e.line, "taxonomy",
                          "%r: only plain words and names are everyday; a %s is introduced"
                          % (e.id, e.kind))
            if e.kind == "plain" and not e.everyday:
                rep.error(path, e.line, "taxonomy", "%r: a plain word is everyday" % e.id)
            if e.kind == "supplied" and not e.supplied_key:
                rep.error(path, e.line, "taxonomy",
                          "%r: a supplied part needs introduced_at supplied:<section>" % e.id)
            if e.supplied_key and e.kind in EVERYDAY_KINDS:
                rep.error(path, e.line, "taxonomy", "%r: a %s cannot be supplied" % (e.id, e.kind))
            if e.opened_at is not None:
                if not e.supplied_key:
                    rep.error(path, e.line, "taxonomy",
                              "%r: opened_at is only for supplied parts" % e.id)
                elif not e.opened_key:
                    rep.error(path, e.line, "taxonomy", "%r: opened_at %r is not a section"
                              % (e.id, e.opened_at))
                elif e.opened_key <= e.supplied_key:
                    rep.error(path, e.line, "taxonomy",
                              "%r: opened at %s, not after it is supplied at %s"
                              % (e.id, sec_name(e.opened_key), sec_name(e.supplied_key)))
            if e.stub is not None and not e.supplied_key:
                rep.error(path, e.line, "taxonomy", "%r: only a supplied entry has a stub" % e.id)
            if e.stub is not None and not (isinstance(e.host, str) and
                                           re.fullmatch(r"\$[A-Za-z_]\w*|res://[\w/.-]+\.(?:gd|tscn)",
                                                        e.host)):
                rep.error(path, e.line, "taxonomy", "%r: a stub needs a host the student's code can "
                          "reach: \"$Node\" (a node in the scene), \"res://path.gd\" (a preloaded "
                          "script) or \"res://path.tscn\" (a preloaded scene)" % e.id)
            if (e.stub is not None and isinstance(e.host, str) and e.host.endswith(".tscn")
                    and not e.stub.startswith("[gd_scene")):
                rep.error(path, e.line, "taxonomy", "%r: a scene host's stub is the scene's text: "
                          "it starts with [gd_scene" % e.id)
            if e.own_chapter is not None and e.kind != "name":
                rep.error(path, e.line, "taxonomy", "%r: N.x is for a name a chapter's examples give "
                          "(a class of your own); a %s is introduced in a section" % (e.id, e.kind))
            for d in e.depends_on:
                dep = self.entries.get(d)
                if dep is None:
                    rep.error(path, e.line, "taxonomy", "%r depends on unknown %r" % (e.id, d))
                    continue
                if dep.missing and not e.missing:
                    rep.error(path, e.line, "taxonomy", "%r (%s) depends on %r, which is never taught"
                              % (e.id, e.where(), d))
                    self.dep_facts.append((e, dep))
                    continue
                if (e.intro_key and e.intro_key[1] == HEAD and dep.avail
                        and dep.avail[0] == e.intro_key[0]):
                    continue    # placed at chapter level: somewhere in the same chapter
                if e.avail and dep.avail and dep.avail > e.avail:
                    if d in e.late_deps:
                        # declared: the order is wrong in the plan, and the entry says so
                        rep.warn(path, e.line, "taxonomy",
                                 "%r (%s) depends on %r, introduced later (%s): declared in late_deps"
                                 % (e.id, e.where(), d, dep.where()))
                    else:
                        rep.error(path, e.line, "taxonomy",
                                  "%r (%s) depends on %r, introduced later (%s)"
                                  % (e.id, e.where(), d, dep.where()))
                    self.dep_facts.append((e, dep))
            for d in e.late_deps:
                if d not in e.depends_on:
                    rep.error(path, e.line, "taxonomy", "%r: late_deps names %r, which is not in "
                              "depends_on" % (e.id, d))
            self._check_def(e)
            if "admin-taxonomy" not in OFF:
                self._check_admin(e)
        self._cycles()
        self._number_split()

    def _check_admin(self, e):
        """An admin entry: a name in text, steps for a def, a defining section; its synonyms and
        step phrases are no form of anything (one word, one entry). Only it has steps or calls."""
        rep, path = self.rep, self.path
        if not e.is_admin:
            if e.raw.get("step_phrases") or e.raw.get("calls") or e.raw.get("unless"):
                rep.error(path, e.line, "taxonomy", "%r: only an admin procedure has step_phrases, "
                          "calls or unless; a %s is never described as steps" % (e.id, e.kind))
            return
        if e.unless_bad:
            rep.error(path, e.line, "taxonomy", "%r: unless lists words, each a string" % e.id)
        for s in e.synonyms:
            if "{" in s and (self.template_regex(s) is None or not re.search(r"\{\w+\}", s)):
                rep.error(path, e.line, "taxonomy", "%r: the synonym template %r needs a slot, one "
                          "of %s" % (e.id, s, ", ".join("{%s}" % x for x in ADMIN_SLOTS)))
        if e.code:
            rep.error(path, e.line, "taxonomy", "%r: an admin procedure has no code form; its "
                      "name is text, 'run the project'" % e.id)
        if not e.text:
            rep.error(path, e.line, "taxonomy", "%r: an admin procedure needs its name as a text "
                      "form" % e.id)
        if not (e.missing or (e.intro_key and e.intro_key[1] not in (HEAD, EX))):
            rep.error(path, e.line, "taxonomy", "%r: an admin procedure is defined in one section "
                      "(introduced_at 1.1), or is missing; not %r" % (e.id, e.introduced_at))
        for s in split_sentences(e.definition):
            if not re.search(r"[.!?]$", s):
                rep.error(path, e.line, "taxonomy", "%r: each step of the def ends its sentence: %r"
                          % (e.id, s))
        for p, cues in e.step_phrases:
            if p is None:
                rep.error(path, e.line, "taxonomy", "%r: a step phrase is a string, or "
                          "{\"phrase\": \"...\", \"cues\": [\"...\"]}" % e.id)
        for p in [s for s in e.synonyms if "{" not in s] + [p for p, c in e.step_phrases if p]:
            other = self.text_index.get(norm_phrase(p))
            if other:
                rep.error(path, e.line, "taxonomy", "%r: %r would describe it again, and is a text "
                          "form of %r: one word, one entry" % (e.id, p, other))
        for t in e.calls:
            if self.template_regex(t) is None or not re.search(r"\{\w+\}", t or ""):
                rep.error(path, e.line, "taxonomy", "%r: the call template %r needs a slot, one of "
                          "%s" % (e.id, t, ", ".join("{%s}" % s for s in ADMIN_SLOTS)))

    def _number_split(self):
        """One word, one entry: a singular in one entry and its plural in another is a word
        split by meaning (degree for a graph, degrees for an angle), which the text cannot see."""
        rep, path = self.rep, self.path
        seen = set()
        for k, eid in list(self.text_index.items()):
            if " " in k:
                continue
            plurals = {k + "s", k + "es"}
            if k.endswith("y") and len(k) > 2 and k[-2] not in "aeiou":
                plurals.add(k[:-1] + "ies")
            for p in plurals:
                other = self.text_index.get(p)
                if other and other != eid and (k, p) not in seen:
                    seen.add((k, p))
                    e = self.entries[eid]
                    rep.error(path, e.line, "taxonomy", "%r is a form of %r and %r of %r: one word "
                              "split by meaning; give one entry both, and the other sense its own "
                              "word" % (k, eid, p, other))

    def _check_def(self, e):
        """The def is text too: every technical term in it is the entry or a dependency."""
        rep, path = self.rep, self.path
        allowed = set(e.depends_on) | {e.id}
        used = set()
        spans = re.findall(r"`([^`]+)`", e.definition)
        prose = re.sub(r"`[^`]+`", " ", e.definition)
        for a, b, word, tag, eid in self.iter_forms(prose):
            if tag == "syn":
                rep.error(path, e.line, "taxonomy", "%r: def uses %r, a synonym of %r"
                          % (e.id, word, eid))
            else:
                used.add(eid)
        if self.jargon_re:
            for m in self.jargon_re.finditer(prose):
                rep.error(path, e.line, "taxonomy", "%r: def uses %r, a technical word that is "
                          "no form of any entry" % (e.id, m.group(0)))
        for sp in spans:
            sig = self.code_index.get(sp.strip())
            if sig:
                used.add(sig)
                continue
            toks, _ = tokenize_code(sp)
            nodes = set()
            for t in toks:
                if t[0] == "node":
                    nodes.update(t[1])
            for t in toks:
                if t[0] in ("id", "op"):
                    eid = self.code_index.get(t[1])
                    if eid:
                        used.add(eid)
                    elif t[1] not in nodes:
                        rep.error(path, e.line, "taxonomy", "%r: def names `%s`, which is no entry"
                                  % (e.id, t[1]))
        for u in sorted(used - allowed):
            dep = self.entries[u]
            if dep.kind in EVERYDAY_KINDS:
                continue
            rep.error(path, e.line, "taxonomy",
                      "%r: def uses %r, which is not in depends_on" % (e.id, u))
        # a def is text the Types box repeats: it never says an admin procedure's steps
        if not e.is_admin and "admin-again" not in OFF:
            for a, b, word, adm, tag, advice in self.admin_hits(e.definition):
                rep.error(path, e.line, "taxonomy", "%r: def says %r, which describes %s: a def "
                          "never says an admin procedure's steps" % (e.id, word, adm.text[0]))
        # an admin's def is its steps, one line each: each step is measured as a line
        for part in (split_sentences(e.definition) if e.is_admin else [e.definition]):
            n = count_words(part)
            what = "a step of the def" if e.is_admin else "def"
            if n > MAX_WORDS:
                rep.error(path, e.line, "taxonomy", "%r: %s is %d words (at most %d)"
                          % (e.id, what, n, MAX_WORDS))
            elif n > WARN_WORDS:
                rep.warn(path, e.line, "taxonomy", "%r: %s is %d words (aim for %d)"
                         % (e.id, what, n, WARN_WORDS))

    def _cycles(self):
        color = {}
        stack = []
        reported = set()

        def visit(eid):
            color[eid] = 1
            stack.append(eid)
            for d in self.entries[eid].depends_on:
                if d not in self.entries:
                    continue
                if color.get(d) == 1:
                    cyc = stack[stack.index(d):] + [d]
                    key = frozenset(cyc)
                    if key not in reported:
                        reported.add(key)
                        self.rep.error(self.path, self.entries[d].line, "taxonomy",
                                       "depends_on cycle: %s" % " -> ".join(cyc))
                elif color.get(d) is None:
                    visit(d)
            stack.pop()
            color[eid] = 2

        for e in self.order:
            if color.get(e.id) is None:
                visit(e.id)


def inflections(form):
    f = form.lower()
    out = {f + "s", f + "es", f + "ed", f + "d", f + "ing", f + "er", f + "ers"}
    if f.endswith("y") and len(f) > 2 and f[-2] not in "aeiou":
        out.update({f[:-1] + "ies", f[:-1] + "ied"})
    if f.endswith("e"):
        out.add(f[:-1] + "ing")
    if f.endswith("is"):
        out.add(f[:-2] + "es")
    if f.endswith("ies"):
        out.add(f[:-3] + "y")
    elif f.endswith("es"):
        out.update({f[:-2], f[:-1]})
    elif f.endswith("s") and not f.endswith("ss"):
        out.add(f[:-1])
    out.discard(f)
    return out


def stems_of(form):
    """The form, and the form without a noun ending: acceleration -> accelerat, acceler;
    gravity -> gravit; neuron -> neur. A stem keeps at least five letters."""
    f = form.lower()
    out = {f}
    for end in DERIV_ENDINGS:
        if f.endswith(end) and len(f) - len(end) >= 5:
            out.add(f[:-len(end)])
    return out


def suffix_chain(rest, depth=0):
    """Is rest one to three suffixes in a row: -ational, -lessly, -ing?"""
    if rest == "":
        return depth > 0
    if depth >= 3:
        return False
    for s in DERIV_SUFFIXES:
        if rest.startswith(s) and suffix_chain(rest[len(s):], depth + 1):
            return True
    return False


# ---------------------------------------------------------------- code tokens

IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
NUM = re.compile(r"0[xX][0-9a-fA-F_]+|0[bB][01_]+|(?:\d[\d_]*)?\.?\d[\d_]*(?:[eE][+-]?\d+)?")
NODEPATH = re.compile(r'\$(?:"([^"]*)"|([A-Za-z_]\w*(?:/[A-Za-z_]\w*)*))')
OPS = sorted(["**=", "<<=", ">>=", ":=", "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=",
              "==", "!=", "<=", ">=", "->", "**", "<<", ">>", "&&", "||",
              "+", "-", "*", "/", "%", "<", ">", "=", "!", "&", "|", "^", "~"],
             key=len, reverse=True)
UNARY_AFTER = {"return", "and", "or", "not", "in", "if", "elif", "while", "else"}


def tokenize_code(src):
    """Tokens of GDScript: (kind, text, line0). Kinds: id, op, num, str, node, punct.
    Comments are returned apart as (line0, text). '[' is the op '[]', '{' the op '{}'.
    A minus or plus that only signs a number is part of the number."""
    toks = []
    comments = []
    i, ln, n = 0, 0, len(src)

    def prev_sig():
        return toks[-1] if toks else None

    while i < n:
        c = src[i]
        if c == "\n":
            ln += 1
            i += 1
            continue
        if c in " \t\r\\":
            i += 1
            continue
        if c == "#":
            j = src.find("\n", i)
            j = n if j < 0 else j
            comments.append((ln, src[i + 1:j]))
            i = j
            continue
        if c in "\"'" or (c in "&^r" and i + 1 < n and src[i + 1] in "\"'"
                            and (i == 0 or not (src[i - 1].isalnum() or src[i - 1] == "_"))):
            start_ln = ln
            if c in "&^r":
                i += 1
            q = src[i]
            triple = src.startswith(q * 3, i)
            end = q * 3 if triple else q
            i += 3 if triple else 1
            s0 = i
            body_end = None
            while i < n:
                if src[i] == "\\":
                    i += 2
                    continue
                if src.startswith(end, i):
                    body_end = i
                    i += len(end)
                    break
                if src[i] == "\n":
                    ln += 1
                    if not triple:
                        body_end = i
                        i += 1
                        break
                i += 1
            toks.append(("str", src[s0:body_end if body_end is not None else i], start_ln))
            continue
        if c == "$":
            m = NODEPATH.match(src, i)
            toks.append(("op", "$", ln))
            if m:
                names = re.findall(r"[A-Za-z_]\w*", m.group(2)) if m.group(2) else []
                toks.append(("node", tuple(names), ln))
                for _ in range(max(0, len(names) - 1)):
                    toks.append(("op", "$/", ln))     # a path into a child: its own element
                i = m.end()
            else:
                i += 1
            continue
        if c == "@":
            m = re.compile(r"@[A-Za-z_]\w*").match(src, i)
            if m:
                toks.append(("id", m.group(0), ln))
                i = m.end()
                continue
        if c.isalpha() or c == "_":
            m = IDENT.match(src, i)
            toks.append(("id", m.group(0), ln))
            i = m.end()
            continue
        if c.isdigit() or (c == "." and i + 1 < n and src[i + 1].isdigit()):
            m = NUM.match(src, i)
            if m and m.end() > i:
                toks.append(("num", m.group(0), ln))
                i = m.end()
                continue
        for op in OPS:
            if src.startswith(op, i):
                if op in "+-":
                    p = prev_sig()
                    j = i + 1
                    while j < n and src[j] in " \t":
                        j += 1
                    unary = (p is None or p[0] == "op" or
                             (p[0] == "punct" and p[1] in "(,:") or
                             (p[0] == "id" and p[1] in UNARY_AFTER))
                    if unary and j < n and (src[j].isdigit() or src[j] == "."):
                        i += 1          # a sign: the number follows
                        break
                toks.append(("op", op, ln))
                i += len(op)
                break
        else:
            if c == "[":
                toks.append(("op", "[]", ln))
            elif c == "{":
                toks.append(("op", "{}", ln))
            else:
                toks.append(("punct", c, ln))
            i += 1
    return toks, comments


DECL_AFTER = {"var", "const", "class_name", "class", "signal", "for"}


def declarations(toks):
    """Names the code itself declares, and the token indexes that declare them."""
    names, idx = set(), set()
    k, n = 0, len(toks)
    while k < n:
        kind, text = toks[k][0], toks[k][1]
        if kind == "node":
            names.update(text)
        elif kind == "id" and text in DECL_AFTER and k + 1 < n and toks[k + 1][0] == "id":
            names.add(toks[k + 1][1])
            idx.add(k + 1)
        elif kind == "id" and text == "func":
            j = k + 1
            if j < n and toks[j][0] == "id":
                names.add(toks[j][1])
                idx.add(j)
                j += 1
            if j < n and toks[j] == ("punct", "(", toks[j][2]):
                depth, j = 1, j + 1
                expect = True
                while j < n and depth > 0:
                    t = toks[j]
                    if t[0] == "punct" and t[1] == "(":
                        depth += 1
                    elif t[0] == "punct" and t[1] == ")":
                        depth -= 1
                    elif depth == 1 and t[0] == "punct" and t[1] == ",":
                        expect = True
                        j += 1
                        continue
                    elif depth == 1 and expect and t[0] == "id":
                        names.add(t[1])
                        idx.add(j)
                    expect = False
                    j += 1
        elif kind == "id" and text == "enum":
            j = k + 1
            if j < n and toks[j][0] == "id":
                names.add(toks[j][1])
                idx.add(j)
                j += 1
            if j < n and toks[j][1] == "{}":
                j += 1
                expect = True
                while j < n and not (toks[j][0] == "punct" and toks[j][1] == "}"):
                    if toks[j][0] == "id" and expect:
                        names.add(toks[j][1])
                        idx.add(j)
                    expect = toks[j][0] == "punct" and toks[j][1] == ","
                    j += 1
        k += 1
    return names, idx


# ---------------------------------------------------------------- prose

CODE_SPAN = re.compile(r"`([^`]+)`")
# an admin procedure's defining line: '**Run the project**: press Play, at the top right.' or,
# with its first argument, '**Make a new script** `field.gd`: click Script, at the top.'
ADMIN_DEF = re.compile(r"^\*\*([^*]+)\*\*(\s+`[^`]+`)?:\s*(.+)$")
# any line that opens with a bold name, however it goes on: a list item, a quote, a dash
DEF_ATTEMPT = re.compile(r"^(?:>\s*)?(?:(?:\d+[.)]|[-*+])\s+)?\*\*([^*]+)\*\*(.*)$")
# a list item, as CommonMark reads one: its indent, its marker ('-' a bullet, '1.' a numbered
# step) and the spaces before its text (SHORT_SPEAK, Lines in a tree)
LIST_ITEM = re.compile(r"^([ \t]*)([-*+]|\d{1,9}[.)])([ \t]+)(\S.*)$")
# a code span that holds a key or a label, not code: `F5`, `Play`, `Ctrl+S`, `Select Current`
KEY_SPAN = re.compile("(?:[A-Z][A-Za-z0-9]*|▶)(?:[+ ](?:[A-Z][A-Za-z0-9]*|[0-9]+))*")
LITTLE_WORDS = {"the", "a", "an", "this", "that", "your", "its", "my", "our"}


def name_key(s):
    """An admin's name without its little words: 'Run project' is still run the project."""
    return " ".join(w for w in norm_phrase(s).split() if w not in LITTLE_WORDS)
CANDIDATE = re.compile(r"(?<![\w$@.])([$@]?[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*(?:\(\))?)")
FILE_NAME = re.compile(r"\b[\w-]+\.(?:gd|tscn|tres|json|cfg|gdshader|png|wav)\b")
ABBREV = ("e.g.", "i.e.", "etc.", "vs.", "cf.", "no.")
# Ada hall names (Point_Zero, Tutorial_3D, Color_Flashlight) are places, not code.
HALL_NAME = re.compile(r"^[A-Z][a-z0-9]+(?:_[A-Z0-9][A-Za-z0-9]*)+$")
# chapter references (ch5, ch22) are not code either
CHAPTER_REF = re.compile(r"^ch\d+$")
SAVE_AS = re.compile(r"(?i)\b(?:save|script)\b[^`]*`([\w./-]+\.(?:gd|tscn|tres|gdshader))`")
SETTER = re.compile(r"\b(?:[Ss]et|[Cc]hange|[Rr]ead|[Hh]alve|[Dd]ouble|[Rr]aise|[Ll]ower|[Rr]eset|"
                    r"[Ii]ncrease|[Dd]ecrease)\s+(?:the|its|their|a|each)\s+([a-z_][a-z0-9_]*)\b")
OPERATOR_AT = re.compile(r"(?:\*\*=|<<=|>>=|\+=|-=|\*=|/=|%=|==|!=|<=|>=|<<|>>|[-+*/%=<>|&^])")


def not_code(word):
    return bool(HALL_NAME.match(word) or CHAPTER_REF.match(word))


def in_formula(text, start, end):
    """True when the word at text[start:end] stands next to an arithmetic operator:
    'position += velocity * delta', 'm1 * d1 = m2 * d2', '(x + z) % 2'."""
    j = end
    # a call or an index belongs to the word: sin(x), steps[i]
    while j < len(text) and text[j] in "([":
        close = ")" if text[j] == "(" else "]"
        depth, k = 0, j
        while k < len(text):
            if text[k] in "([":
                depth += 1
            elif text[k] in ")]":
                depth -= 1
                if depth == 0:
                    break
            k += 1
        j = k + 1
    after = text[j:]
    after = after.lstrip(" )]")
    m = OPERATOR_AT.match(after)
    if m and (m.end() == len(after) or after[m.end()] in " (-0123456789." or len(m.group(0)) > 1):
        return True
    before = text[:start].rstrip(" ([")
    m = re.search(r"(?:\*\*=|<<=|>>=|\+=|-=|\*=|/=|%=|==|!=|<=|>=|<<|>>|[-+*/%=<>|&^])$", before)
    if m:
        op = m.group(0)
        pre = before[:m.start()]
        if len(op) > 1 or not pre or pre[-1] in " (" or op in "*/%=":
            return True
    return False


def code_shaped(word):
    w = word[:-2] if word.endswith("()") else word
    if word.endswith("()") or w.startswith("$") or w.startswith("@"):
        return True
    if "." in w:
        parts = w.split(".")
        return all(len(p) >= 2 for p in parts)
    if "_" in w:
        return True
    if re.search(r"[A-Za-z][0-9]", w):
        return True
    if re.search(r"[a-z][A-Z]", w):
        if re.fullmatch(r"[A-Z][a-z][A-Z][a-z]+", w):
            return False        # a name with a particle: LeWitt, McLuhan, DeLanda
        if re.fullmatch(r"[a-z]{1,5}[A-Z]{2,}", w):
            return False        # a product name: macOS, iOS
        return True
    return False


def span_words(code):
    """What an inline code span weighs in a line: half a word per name or number in it."""
    toks, _ = tokenize_code(code)
    n = sum(1 for t in toks if t[0] in ("id", "num", "node", "str"))
    return max(1, (n + 1) // 2), n


def count_words(text):
    total = 0
    for m in CODE_SPAN.finditer(text):
        total += span_words(m.group(1))[0]
    t = CODE_SPAN.sub(" ", text)
    return total + len([w for w in t.split() if re.search(r"\w", w)])


def clean_text(raw):
    """The text with HTML entities read, invisible characters removed and look-alike letters
    put back to Latin; and a message for each such character, since the student reads one
    word and the checker would read another."""
    problems = []
    t = html.unescape(raw) if "&" in raw else raw
    hidden = INVISIBLE.findall(t)
    if hidden:
        problems.append("an invisible character (%s) splits a word: the reader sees one word, "
                        "the checker would read two" % ", ".join("U+%04X" % ord(c) for c in sorted(set(hidden))))
        t = INVISIBLE.sub("", t)
    for m in re.finditer(r"[^\W\d_]+", t):
        w = m.group(0)
        scripts = set()
        for ch in w:
            try:
                scripts.add(unicodedata.name(ch).split()[0])
            except ValueError:
                pass
        if len(scripts) > 1:
            problems.append("%r mixes %s letters: a look-alike letter hides the word %r"
                            % (w, " and ".join(sorted(scripts)), w.translate(CONFUSABLE)))
    if problems:
        t = t.translate(CONFUSABLE)
    return t, problems


TAG = re.compile(r"</?([A-Za-z][\w-]*)((?:[^<>\"']|\"[^\"]*\"|'[^']*')*)>")
ATTR_TEXT = re.compile(r"\b(?:title|alt|aria-label)\s*=\s*(\"[^\"]*\"|'[^']*')", re.I)
# elements inside a line of text: the reader sees no gap where they open or close, so
# 'Pl<span></span>ay' reads 'Play'
INLINE_TAGS = set("""a abbr b bdi bdo cite code data dfn em i kbd mark q s samp small span strong
sub sup time u var wbr""".split())


def tag_text(m):
    """What a reader sees of an HTML tag: its title or alt text; an inline tag adds no gap."""
    words = " ".join(v[1:-1] for v in ATTR_TEXT.findall(m.group(2)))
    if m.group(1).lower() in INLINE_TAGS:
        return (" %s " % words) if words else ""
    return " " + words + " "


def strip_markup(line):
    """A prose line as the student reads it: markers gone, code spans kept; an image's alt
    text, a link's title and an HTML title kept, since a reader sees them too."""
    s = line
    s = re.sub(r"^\s*>\s?", "", s)
    s = re.sub(r"^\s*#+\s*", "", s)
    s = re.sub(r"^\s*(?:[-*+]|\d+[.)])\s+", "", s)
    spans = []

    def keep(m):
        spans.append(m.group(0))
        return "\x00%d\x00" % (len(spans) - 1)

    s = CODE_SPAN.sub(keep, s)
    s = re.sub(r'!\[([^\]]*)\]\(\s*[^)\s]*(?:\s+"([^"]*)")?\s*\)',
               lambda m: " %s %s " % (m.group(1), m.group(2) or ""), s)
    s = re.sub(r'\[([^\]]*)\]\(\s*[^)\s]*(?:\s+"([^"]*)")?\s*\)',
               lambda m: m.group(1) + ((" (%s)" % m.group(2)) if m.group(2) else ""), s)
    s = TAG.sub(tag_text, s)
    s = s.replace("*", "")
    s = re.sub(r"(?<![\w])_(?=\S)(.+?)(?<=\S)_(?![\w])", r"\1", s)
    s = re.sub("\x00(\\d+)\x00", lambda m: spans[int(m.group(1))], s)
    return s


def visible(raw):
    return strip_markup(clean_text(raw)[0])


TITLE_ABBR = ("mr", "mrs", "ms", "dr", "prof", "st", "sr", "jr")
NUM_ABBR = ("no", "nos", "fig", "figs", "p", "pp", "vol", "ch", "sec", "eq", "eqs", "ex")
MID_ABBR = ("e.g", "i.e", "cf", "vs", "viz", "approx", "ca")


def sentence_breaks(prose):
    """How many sentences end inside the line, before its last one."""
    count = 0
    for m in re.finditer(r"(\.{3}|…|[.!?]+)([\"')\]]*)(\s*)(?=(\S))", prose):
        punct, closers, ws, nxt = m.group(1), m.group(2), m.group(3), m.group(4)
        before = prose[:m.start()]
        wm = re.search(r"([A-Za-z][A-Za-z.]*)$", before)
        w = wm.group(1).lower() if wm else ""
        if punct == ".":
            if w in MID_ABBR:
                continue
            if w in TITLE_ABBR and nxt.isupper():
                continue
            if w in NUM_ABBR and nxt.isdigit():
                continue
        if not ws and not closers and not nxt.isupper():
            continue        # 3.5, a.gd, x.y
        if punct in ("...", "…") and nxt.islower():
            continue        # Wait... the number climbs.
        if closers and closers[-1] in ")]" and not nxt.isupper():
            continue        # (how many?) and press Play
        if nxt in ",;:)]":
            continue
        count += 1
    return count


def defines(text, forms):
    """Does this line declare the term: 'A frame is ...', '... is a frame', 'frame: ...',
    '...: primitives.'? Code spans count as words here, so '`x` is a coordinate' declares
    coordinate."""
    t = CODE_SPAN.sub(" X ", text).strip()
    det = r"(?i:an?|the|one|each|every|this|that|its|their)"
    for f in forms:
        fp = r"[\s-]+".join(re.escape(w) for w in re.split(r"[\s-]+", f.strip()) if w)
        flags = 0 if case_exact(f) else re.IGNORECASE
        pats = [
            r"(?:^|[:;]\s*)(?:%s\s+)?(?:%s)\s+(?:is|are|means|names)\b" % (det, fp),
            r"\b(?:is|are|called|named)\s+(?:%s\s+)?(?:%s)(?![\w])" % (det, fp),
            r"(?:^|\s)(?:%s\s+)?(?:%s)\s*:" % (det, fp),
            r":\s*(?:%s\s+)?(?:%s)\s*[.!?]?$" % (det, fp),
        ]
        if len(f) == 1:
            pats.append(r"(?:^|[,;:]\s*|\band\s+)(?:%s)\s+[a-z]+s\b" % fp)    # x runs right
        for p in pats:
            if re.search(p, t, flags):
                return True
    return False


def num_value(s):
    s = s.replace("_", "")
    try:
        if s[:2].lower() == "0x":
            v = int(s, 16)
        elif s[:2].lower() == "0b":
            v = int(s, 2)
        else:
            v = float(s)
    except ValueError:
        return None
    return round(float(v), 6)


NUM_IN_TEXT = re.compile(r"(?<![\w.])(-?\d+(?:\.\d+)?)(?![\w]|\.\d)")


def numbers_in(text):
    return {num_value(m.group(1)) for m in NUM_IN_TEXT.finditer(text)} | \
           {abs(num_value(m.group(1))) for m in NUM_IN_TEXT.finditer(text)}


def numbers_with_words(line):
    """(value, as written) for each number in a line: digits, and number words from ten up.
    A reference (Example 1.2, chapter 13) is no number."""
    out = []
    for m in NUM_IN_TEXT.finditer(line):
        if re.search(r"(?:Example|Exercise|section|chapter|ch|Part|Figure|step)\s*$", line[:m.start()],
                     re.IGNORECASE):
            continue
        v = num_value(m.group(1))
        if v is not None:
            out.append((abs(v), m.group(1)))
    small = "|".join(SMALL_NUMBERS)
    for m in re.finditer(r"\b(%s)(?:-(%s))?\b" % ("|".join(NUMBER_WORDS), small), line, re.IGNORECASE):
        v = NUMBER_WORDS[m.group(1).lower()] + (SMALL_NUMBERS[m.group(2).lower()] if m.group(2) else 0)
        out.append((float(v), m.group(0)))
    return out


def ends_sentence(text):
    t = re.sub(r"[\s*_)\]\"'”’]+$", "", text)
    return bool(t) and t[-1] in ".!?:"


# ---------------------------------------------------------------- chapters


class Block:
    def __init__(self, lang, fence_line, opts):
        self.lang = lang
        self.fence_line = fence_line   # line number of the opening fence
        self.lines = []
        self.opts = opts or {}

    @property
    def text(self):
        return "\n".join(self.lines)


class Section:
    def __init__(self, sid, key, file, line):
        self.id = sid
        self.key = key
        self.file = file
        self.line = line
        self.needs, self.gives, self.borrows = [], [], []
        self.admin = []      # the admin procedures this section defines
        self.prose = []      # (lineno, raw line, kind)
        self.items = {}      # lineno -> ListLine, for each prose line that stands in a list
        self.lists = []      # each list as Markdown reads it: first line, numbered, items by level
        self.blocks = []
        self.uses = {}       # entry id -> [first line, in lines, in code]
        self.locals = set()
        self.head = False
        self.title_seen = False

    def use(self, eid, ln, where):
        u = self.uses.setdefault(eid, [ln, False, False])
        u[0] = min(u[0], ln)
        if where == "code":
            u[2] = True
        else:
            u[1] = True


class ListLine:
    """Where a prose line stands in a list (SHORT_SPEAK, Lines in a tree): an item, with its
    depth (1 a parent, 2 its child) and whether it is a numbered step; or, with cont_of, a line
    that goes on with the item at that line, which Markdown joins into the item."""

    def __init__(self, depth=0, step=False, cont_of=None):
        self.depth = depth
        self.step = step
        self.cont_of = cont_of

    @property
    def item(self):
        return self.cont_of is None


class Chapter:
    def __init__(self, file):
        self.file = file
        self.n = None
        self.sections = []
        self.types = []        # (lineno, raw)
        self.types_line = None


def parse_sig(content):
    """'section 1.2 / needs: a, b / gives: c / borrows: d / admin: e' -> (id, {key: [ids]}) or
    error. admin: lists the admin procedures the section defines."""
    parts = [p.strip() for p in re.split(r"[\n;]", content) if p.strip()]
    first = parts[0]
    m = re.match(r"section\s*:?\s*(\S+)\s*(.*)$", first)
    if not m:
        return None, None, "not a section signature"
    sid = m.group(1)
    rest = [m.group(2)] if m.group(2).strip() else []
    fields = {"needs": [], "gives": [], "borrows": [], "admin": []}
    for p in rest + parts[1:]:
        km = re.match(r"(needs|gives|borrows|admin)\s*:\s*(.*)$", p)
        if not km:
            return sid, fields, "cannot read %r (use needs:, gives:, borrows:, admin:)" % p
        fields[km.group(1)].extend(x.strip() for x in km.group(2).split(",") if x.strip())
    return sid, fields, None


def parse_code_opts(content):
    body = re.sub(r"^code\s*:?", "", content.strip()).strip()
    opts = {}
    try:
        words = shlex.split(body)
    except ValueError:
        words = body.split()
    for w in words:
        if "=" in w:
            k, v = w.split("=", 1)
            k = k.strip()
            if k in ("claim", "prints"):
                opts.setdefault(k, []).append(v)     # may repeat: every one must hold
            else:
                opts[k] = v
        else:
            opts[w.strip()] = True
    return opts


def parse_chapter(path, rep):
    ch = Chapter(path)
    try:
        with open(path, encoding="utf-8") as f:
            lines = f.read().split("\n")
    except OSError as e:
        rep.error(path, 1, "format", "cannot read: %s" % e)
        return ch
    head = Section("head", None, path, 1)
    head.head = True
    cur = head
    sections = [head]
    in_fence, fence, block = False, None, None
    comment, comment_start = None, 0
    pending_opts = None
    in_types = False
    # the list items open above the current line: (indent, content offset, line, marker); the
    # last prose line and its kind; the last line that stood in a list, with its list's first
    # marker; the list being read, as a record of its section's lists
    lst = {"stack": [], "last": 0, "kind": None, "open": None, "rec": None}

    def same_list(a, b):
        """Two markers CommonMark reads as one list: the same bullet, or numbers with the same
        delimiter ('1.' and '4.', never '1.' and '4)')."""
        if a[0].isdigit() != b[0].isdigit():
            return False
        return a[-1] == b[-1] if a[0].isdigit() else a == b

    def list_line(ln, raw, kind):
        """SHORT_SPEAK, Lines in a tree: where a prose line stands in a list, read as CommonMark
        reads it. A list goes on only over prose lines with no gap: a blank line, a fence, a
        comment or a heading ends it. A child of '- ' is indented 2 spaces, a child of '1. '
        3: its parent's content offset. A line that is no item, right under an item, goes on
        with that item: Markdown joins the two, whatever the indent. Two lists of one kind
        with only a blank line between are one loose list to Markdown, and a numbered list
        that starts past 1 right under a plain line is read into that line."""
        stack = lst["stack"]
        prev, prev_kind, prev_open = lst["last"], lst["kind"], lst["open"]
        broken = prev != ln - 1
        if broken or kind in ("h1", "heading", "html"):
            del stack[:]
        lst["last"], lst["kind"] = ln, kind
        if kind in ("h1", "heading", "html"):
            return
        ws = re.match(r"[ \t]*", raw).group(0)
        indent = len(ws.expandtabs(4))
        m = LIST_ITEM.match(raw) if kind == "line" else None
        if m and not indent and broken and prev_open and prev_open[0] == prev \
                and all(not x.strip() for x in lines[prev:ln - 1]) \
                and same_list(prev_open[1], m.group(2)) and "list-loose" not in OFF:
            rep.error(path, ln, "list", "only a blank line parts this list from the one ending at "
                      "line %d: Markdown reads the two as one loose list, so the break does not "
                      "show. Join them into one tree, or put a plain line between" % prev)
        if m and m.group(2)[0].isdigit() and not indent and not broken and not stack \
                and prev_kind in ("line", "label", "figure", "equation", "image") \
                and int(m.group(2)[:-1]) != 1 and "list-start" not in OFF:
            rep.error(path, ln, "list", "a numbered list right under a plain line starts at 1, or "
                      "Markdown reads '%s' into that line: put a blank line before it"
                      % m.group(2))
        if "\t" in ws and (m or stack or indent) and "list-indent" not in OFF:
            rep.error(path, ln, "list", "a tab indents this line: indent with spaces, a child 2 "
                      "under `- ` and 3 under `1. `")
        if m is None:
            if stack:
                cur.items[ln] = ListLine(cont_of=stack[-1][2])
                lst["open"] = (ln, stack[0][3])
                if "list-sentence" not in OFF:
                    rep.error(path, ln, "list", "this line goes on with the item at line %d: "
                              "Markdown joins them, so the item holds two sentences. One sentence "
                              "per item: make the line an item, or put a blank line before it"
                              % stack[-1][2])
            elif indent and "list-orphan" not in OFF:
                rep.error(path, ln, "list", "an indented line with no list item above it: indent "
                          "only a child, right under its parent, with no blank line between")
            return
        had = bool(stack)
        while stack and stack[-1][1] > indent:
            stack.pop()
        depth = len(stack) + 1
        if not had and indent:
            if "list-orphan" not in OFF:
                rep.error(path, ln, "list", "an indented item with no list item above it: a list "
                          "starts at the margin, and a child sits right under its parent")
        elif "list-indent" not in OFF:
            want = stack[-1][1] if stack else 0
            if indent != want and stack:
                rep.error(path, ln, "list", "indented %d spaces under the item at line %d: a child "
                          "sits at its parent's content offset, %d under `%s ` (2 under `- `, 3 "
                          "under `1. `)" % (indent, stack[-1][2], want, stack[-1][3]))
            elif indent != want:
                rep.error(path, ln, "list", "indented %d spaces, under no item: a parent starts at "
                          "the margin, and a child sits at its parent's content offset (2 under "
                          "`- `, 3 under `1. `)" % indent)
        if depth > 2 and "list-depth" not in OFF:
            rep.error(path, ln, "list", "a list item %d levels deep: at most two, a bullet and its "
                      "children; indentation never means emphasis" % depth)
        marker, gap = m.group(2), len(m.group(3).expandtabs(4))
        stack.append((indent, indent + len(marker) + (gap if gap <= 4 else 1), ln, marker))
        cur.items[ln] = ListLine(depth=depth, step=marker[0].isdigit())
        lst["open"] = (ln, stack[0][3])
        if not had:
            lst["rec"] = {"line": ln, "step": marker[0].isdigit(), "top": 0, "kids": 0}
            cur.lists.append(lst["rec"])
        lst["rec"]["top" if depth == 1 else "kids"] += 1

    for i, raw in enumerate(lines):
        ln = i + 1
        if in_fence:
            if raw.strip().startswith(fence) and raw.strip().strip(fence[0]) == "":
                in_fence = False
                cur.blocks.append(block)
                block = None
            else:
                block.lines.append(raw)
            continue
        if comment is not None:
            comment.append(raw)
            if "-->" in raw:
                text = "\n".join(comment)
                comment = None
                cur, pending_opts = _on_comment(text, comment_start, path, rep, cur,
                                                sections, pending_opts)
            continue
        s = raw.strip()
        fm = re.match(r"^(```+|~~~+)\s*(\S*)", s)
        if fm:
            in_fence, fence = True, fm.group(1)
            lang = fm.group(2).lower()
            block = Block(lang, ln, pending_opts)
            if lang not in FENCE_LANGS:
                rep.error(path, ln, "format", "a code fence must say gdscript, gdshader or text, not "
                          "%r: every block is checked, and its language says how" % (lang or "nothing"))
            pending_opts = None
            in_types = False
            continue
        if s.startswith("<!--"):
            in_types = False
            if "-->" in s:
                cur, pending_opts = _on_comment(s, ln, path, rep, cur, sections, pending_opts)
            else:
                comment, comment_start = [raw], ln
            continue
        if re.match(r"^>\s*\*\*(Types|Code|Supplied)\*\*", s):
            in_types = True
            if ch.types_line is None:
                ch.types_line = ln
            ch.types.append((ln, s))
            continue
        if in_types and s.startswith(">"):
            ch.types.append((ln, s))
            continue
        in_types = False
        if not s:
            continue
        if re.match(r"^#\s", s):
            kind = "h1"
        elif s.startswith("#"):
            kind = "heading"
            hm = re.match(r"^#+\s+(\d+\.\d+)\b", s)
            if not cur.head and not cur.title_seen:
                cur.title_seen = True
                if cur.key and cur.key[1] != EX and (not hm or hm.group(1) != cur.id):
                    rep.error(path, ln, "format", "heading should start with %s" % cur.id)
        elif re.match(r"^\*\[.*\]\*$", s):
            kind = "figure"
        elif re.fullmatch(r"!\[[^\]]*\]\([^)]*\)", s):
            kind = "image"
        elif re.fullmatch(r"\*\*[^*]+\*\*", s):
            kind = "label"
        elif s.startswith("<"):
            kind = "html"
        elif re.fullmatch(r"`[^`]+`", s):
            kind = "equation"
        else:
            kind = "line"
        cur.prose.append((ln, raw, kind))
        list_line(ln, raw, kind)
    if in_fence:
        rep.error(path, block.fence_line, "format", "code fence never closed")
    if comment is not None:
        rep.error(path, comment_start, "format", "comment never closed")
    ch.sections = sections
    real = [x for x in sections if not x.head]
    if not real:
        rep.error(path, 1, "format", "no section signature (<!-- section N.M ... -->)")
        return ch
    ch.n = real[0].key[0]
    head.key = (ch.n, HEAD)
    head.id = "%d.0" % ch.n
    for x in real:
        if x.key[0] != ch.n:
            rep.error(path, x.line, "format", "section %s is not in chapter %d" % (x.id, ch.n))
    return ch


def _on_comment(text, ln, path, rep, cur, sections, pending_opts):
    content = text.strip()
    content = content[4:] if content.startswith("<!--") else content
    content = content[:-3] if content.endswith("-->") else content
    content = content.strip()
    if re.match(r"^section\b", content):
        sid, fields, err = parse_sig(content)
        if err:
            rep.error(path, ln, "signature", err)
        key = sec_key(sid or "")
        if key is None:
            rep.error(path, ln, "signature", "section id %r is not N.M or N.x" % sid)
            return cur, pending_opts
        sec = Section(sid, key, path, ln)
        if fields:
            sec.needs, sec.gives, sec.borrows = fields["needs"], fields["gives"], fields["borrows"]
            sec.admin = fields["admin"]
        sections.append(sec)
        return sec, None
    if re.match(r"^code\b", content):
        return cur, parse_code_opts(content)
    return cur, pending_opts


# ---------------------------------------------------------------- the checker


DETERMINERS = set("""a an the its their your his her our this that these those each every
own new""".split())


def head_entries(text, found, label_is_new, found_first=None):
    """Entries that stand at the head of a clause segment in a code_new item: what the item
    lists or defines, not what it uses. Segments are cut at ; : , ( ) [ ]. A word is at the
    head when only determiners stand before it in its segment, or when 'and'/'or' joins it to
    a word at the head. The body after a label that names a new entry defines that entry, so
    nothing in it stands at the head; nor does an appositive after a new entry ('bool, a
    variable that ...'). label_is_new(span_text) says whether a stretch names a new entry."""
    occ = sorted((a, b, eid) for eid, lst in found.items() for a, b, w in lst)
    found_first = found_first or {}
    status = {}

    def seg_start_of(a, lo):
        return max([text.rfind(d, lo, a) for d in ",:()[]"] + [lo - 1]) + 1

    for a, b, eid in occ:
        cs = text.rfind(";", 0, a) + 1
        colon = text.find(":", cs, a)
        if colon != -1 and label_is_new(text[cs:colon]):
            status[(a, eid)] = False
            continue
        ss = seg_start_of(a, cs)
        if ss > 0 and text[ss - 1] == "[":
            status[(a, eid)] = False        # an index: source[y][x]
            continue
        prefix = text[ss:a]
        words = re.findall(r"[\w@$'-]+", prefix.lower())
        head = all(w in DETERMINERS for w in words)
        if not head:
            m = re.search(r"\b(?:and|or)\s+((?:[\w'-]+\s+)*)$", prefix)
            if m and all(w in DETERMINERS for w in m.group(1).lower().split()):
                cut = ss + m.start()
                before = [(a2, e2) for a2, b2, e2 in occ if ss <= a2 < cut]
                if before and status.get(before[-1]):
                    head = True
        word = text[a:b]
        rest = text[b:]
        if head and (re.match(r"'s\b", rest) or re.match(r"\s+as\s", rest)):
            head = False                    # a possessive or a role: the walker's place, x as y
        if head and re.search(r"[^s]s$", word.lower()) and not re.search(r"s$", (found_first.get(eid) or "")):
            head = False                    # a plural names things in use: bodies on links
        if head and word.lower().endswith("ed") and len(rest) - len(rest.lstrip()) > 0:
            head = False                    # a participle describes: a seeded replay
        if head and any(b < a2 <= b + 1 for a2, b2, e2 in occ):
            head = False                    # a modifier of the entry after it: a random digger
        if head and words and words[0] in ("a", "an", "the") and ss > cs and text[ss - 1] == ",":
            ps = seg_start_of(ss - 1, cs)
            if label_is_new(text[ps:ss - 1]):
                head = False                # an appositive: it defines the new entry before it
        status[(a, eid)] = head
    return {eid for (a, eid), h in status.items() if h}


DEFINES = r"(?:^|[.;:]\s+)(?:an?\s+|the\s+)?(%s)\s+is\b|\bthat\s+is\s+(?:an?\s+|the\s+)?(%s)\b"


def e_late(e, limit):
    return e.avail is None or e.avail > limit


def back_refs(item):
    """Chapters an item points back to in parentheses: (met in ch13), (opened in 11.7),
    (the field of 6.5), (from ch3)."""
    out = set()
    for grp in re.findall(r"\(([^()]*)\)", item):
        for m in re.finditer(r"\bch(?:apter)?\s*(\d+)\b|\b(\d+)\.(\d+)\b", grp):
            out.add(int(m.group(1) or m.group(2)))
    return out


class Checker:
    def __init__(self, tax, rep, sketch_mode=False):
        self.tax = tax
        self.rep = rep
        self.sketch = sketch_mode
        self.program = []        # sections in order
        self.facts = []          # structured findings for --report: dicts, see fact()
        self.last_syn = {}

    # -- structured findings
    def fact(self, kind, e, key, ln, word, **more):
        d = {"kind": kind, "entry": e.id, "label": e.label(), "key": key, "line": ln,
             "word": word, "taught": e.where(), "avail": e.avail}
        d.update(more)
        if any(f["kind"] == kind and f["entry"] == e.id and f["key"] == key and f["line"] == ln
               for f in self.facts):
            return      # one fact per element per line, as the report counts uses
        self.facts.append(d)

    def use_finding(self, e, file, ln, key, word, prefix="", label=None):
        """An entry used at key before it is available, or never taught at all.
        In sketch mode a declared other sense of the word is a warning, not an order break."""
        label = label or e.label()
        if self.sketch:
            sense = e.sense_at(word, key)
            if sense:
                self.rep.warn(file, ln, "sense", "%s%r is another sense here (%s); the type %s is "
                              "%s" % (prefix, word, sense, e.label(), e.where()))
                self.fact("sense", e, key, ln, word, sense=sense)
                return
        if e.missing:
            self.rep.error(file, ln, "never", "%s%s is used, but no section teaches it "
                           "(introduced_at: missing)" % (prefix, label))
            self.fact("never", e, key, ln, word)
            return
        self.rep.error(file, ln, "order", "%s%s is used before it is introduced (%s)"
                       % (prefix, label, e.where() if e.avail else "never, in no section"))
        self.fact("order", e, key, ln, word)

    # -- admin procedures
    def admin_again(self, sec, file, ln, limit, e, word, tag, advice, kind="line"):
        """A wording of an admin procedure other than its name says its steps again: the text
        says only its name. In its defining section the steps are free, but another wording of
        the whole procedure on a line apart from the definition is a second description."""
        name = e.text[0] if e.text else e.id
        if not sec.head and sec.key is not None and e.intro_key == sec.key:
            if tag == "syn" and kind == "line" and ln not in self.def_block(sec, e)[0]:
                self.rep.error(file, ln, "admin", "%r is another wording of %s, in its own section: "
                               "its definition says it once; say \"%s\"" % (word, name, advice))
            return
        if e.missing:
            msg = "%r describes %s, which no section defines yet (introduced_at: missing)" % (
                word, name)
        elif e.late(limit):
            msg = ("%r describes %s before its definition (%s): define it here, or say nothing "
                   "of its steps" % (word, name, sec_name(e.intro_key)))
        else:
            msg = '%r describes %s again: say "%s" (%s)' % (word, name, advice,
                                                           sec_name(e.intro_key))
        self.rep.error(file, ln, "admin", msg)

    def def_attempts(self, s):
        """The lines of a section that open with an admin's name in bold, however they go on:
        (prose index, line, entry, the exact defining line's match or None). 'Run project' is
        still run the project; a list item, a quote or a dash after the name is no definition."""
        tax = self.tax
        out = []
        for i, (ln, raw, kind) in enumerate(s.prose):
            if kind not in ("line", "label"):
                continue
            m = DEF_ATTEMPT.match(raw.strip())
            if not m:
                continue
            e = tax.admin_names.get(norm_phrase(m.group(1))) or \
                tax.admin_name_keys.get(name_key(m.group(1)))
            if e is None:
                continue
            exact = ADMIN_DEF.match(raw.strip()) if kind == "line" else None
            if exact and norm_phrase(exact.group(1)) not in {norm_phrase(f) for f in e.text}:
                exact = None
            out.append((i, ln, e, exact))
        return out

    def def_block(self, s, e):
        """The lines of an admin's definition in its defining section: the bold line and the
        lines that follow it, as many as the def has steps. (set of lines, prose index or None)."""
        cache = self.__dict__.setdefault("_def_blocks", {})
        key = (s.file, s.line, e.id)
        if key in cache:
            return cache[key]
        lines, at = set(), None
        want = len(split_sentences(e.definition))
        for i, ln, e2, exact in self.def_attempts(s):
            if e2 is not e or not exact:
                continue
            at = i
            lines.add(ln)
            last, j = ln, i + 1
            while len(lines) < want and j < len(s.prose):
                ln2, raw2, kind2 = s.prose[j]
                if kind2 != "line" or ln2 != last + 1:
                    break
                lines.add(ln2)
                last, j = ln2, j + 1
            break
        cache[key] = (lines, at)
        return cache[key]

    def check_admin(self, s):
        """Its defining section writes an admin procedure once: '**Run the project**: press
        Play, at the top right.' and its other steps, line by line, as the taxonomy's def has
        them; no call of it comes before that line, and no 'Or ...' line offers a second way.
        No other section defines it again, and no source types the link to it."""
        tax, rep = self.tax, self.rep
        lines = [(i, ln, raw, kind) for i, (ln, raw, kind) in enumerate(s.prose)]
        if "admin-define" not in OFF:
            seen = {}
            for i, ln, e, exact in self.def_attempts(s):
                if s.head or e.intro_key != s.key:
                    rep.error(s.file, ln, "admin", "%s is defined at %s; this is a second "
                              "definition: say \"%s\"" % (e.text[0], e.where(), e.call_line()))
                    continue
                if e.id in seen:
                    rep.error(s.file, ln, "admin", "%s is defined twice in %s (first at line %d): "
                              "one procedure, one description" % (e.text[0], s.id, seen[e.id][1]))
                    continue
                seen[e.id] = (i, ln, exact)
                if exact is None:
                    rep.error(s.file, ln, "admin", "the definition of %s is written '**%s**: ' and "
                              "its first step, on a line of its own" % (e.text[0],
                                                                      e.call_line()[:-1]))
            for eid in list(dict.fromkeys(list(s.admin) + list(seen))):
                e = tax.get(eid)
                if e is None or not e.is_admin:
                    continue
                if eid not in seen:
                    if eid in s.admin:
                        rep.error(s.file, s.line, "admin", "%s defines %s (admin:), but no line is "
                                  "'**%s**: ' and its steps" % (s.id, e.text[0],
                                                                e.call_line()[:-1]))
                    continue
                i, ln, m = seen[eid]
                if m is None:
                    continue        # reported: not the defining form
                want = split_sentences(e.definition)
                got = [(s.prose[i][0], m.group(3))]
                j = i + 1
                while len(got) < len(want) and j < len(s.prose):
                    ln2, raw2, kind2 = s.prose[j]
                    if kind2 != "line" or ln2 != got[-1][0] + 1:
                        break
                    got.append((ln2, raw2.strip()))
                    j += 1
                for k, w in enumerate(want):
                    if k >= len(got):
                        rep.error(s.file, got[-1][0], "admin", "the steps of %s stop here; the "
                                  "taxonomy's def goes on: %r" % (e.text[0], " ".join(want[k:])))
                        break
                    if norm_step(got[k][1]) != norm_step(w):
                        rep.error(s.file, got[k][0], "admin", "the steps of %s say %r; the "
                                  "taxonomy's def says %r: one procedure, one description"
                                  % (e.text[0], got[k][1], w))
                # 'Or press F6.' right after the steps: a second way to do it
                if len(got) == len(want) and j < len(s.prose):
                    ln2, raw2, kind2 = s.prose[j]
                    if (kind2 == "line" and ln2 == got[-1][0] + 1
                            and re.match(r"^or\b", visible(raw2).strip(), re.IGNORECASE)):
                        rep.error(s.file, ln2, "admin", "an 'Or' after the steps of %s offers a "
                                  "second way: the taxonomy's def is the one description" % e.text[0])
                # a call of it before its definition, in its own section
                if "admin-order" not in OFF:
                    for ln0, raw0, kind0 in s.prose[:i]:
                        if kind0 not in ("line", "label", "figure"):
                            continue
                        for e2, a, b in tax.admin_calls_of(visible(raw0)):
                            if e2 is e:
                                rep.error(s.file, ln0, "order", "%s is called before its "
                                          "definition (line %d): define it first" % (e.text[0], ln))
                                break
        if "admin-link" not in OFF:
            slugs = {}
            for e in tax.admins:
                for f in e.text + [e.id]:
                    slugs[admin_slug(f)] = e
            for i, ln, raw, kind in lines:
                hit = None
                targets = (re.findall(r"\]\(\s*<?([^)\s>]+)", raw)
                           + re.findall(r"\bhref\s*=\s*[\"']([^\"']+)", raw)
                           + re.findall(r"^\s*\[[^\]]+\]:\s*<?([^\s>]+)", raw))
                for target in targets:
                    frag = target.split("#", 1)[1] if "#" in target else ""
                    if frag and admin_slug(frag) in slugs:
                        hit = slugs[admin_slug(frag)]
                # a link whose words call an admin, wherever it points: the page makes that link
                for label in re.findall(r"(?<!!)\[([^\]]+)\]\s*[(\[]", raw):
                    calls = tax.admin_calls_of(label, positional=False)
                    if calls and hit is None:
                        hit = calls[0][0]
                if hit is not None:
                    rep.error(s.file, ln, "admin", "a typed link to %s: the page links every "
                              "call to its definition; write \"%s\" and no link"
                              % (hit.text[0], hit.call_line()))

    # -- shared: one prose line
    def scan_prose(self, sec, ln, text, kind, preview_limit=None, count_use=True,
                   order=True, file=None):
        """Pass c and d over a line of prose. kind: line, heading, figure, h1, types, comment."""
        tax, rep = self.tax, self.rep
        file = file or sec.file
        limit = preview_limit or sec.key
        cleaned, problems = clean_text(text)
        for p in problems:
            rep.error(file, ln, "chars", p)
        line = strip_markup(cleaned) if kind not in ("comment", "string") else cleaned
        spans = [(m.start(), m.end(), m.group(1)) for m in CODE_SPAN.finditer(line)]
        blank = CODE_SPAN.sub(lambda m: " " * len(m.group(0)), line)
        taken = []

        def free(a):
            return not any(x <= a < y for x, y in taken)

        # an admin procedure may not be called in a chapter's head before its definition: the
        # head previews the chapter's terms, never its steps
        admin_limit = sec.key if sec.head else limit

        def record(eid, where="lines"):
            e = tax.get(eid)
            if e is None:
                return
            if count_use:
                sec.use(eid, ln, where)
            lim = admin_limit if e.is_admin else limit
            if order and e.late(lim) and not (e.is_admin and "admin-order" in OFF):
                self.use_finding(e, file, ln, lim, word_at[0])

        word_at = [""]
        view = tax.admin_view(line)
        plain = line.replace("`", " ")
        admin_spans = []
        # an admin procedure's synonym or step phrase describes it again: read first, so F5 is
        # this, not unknown code. Every text is read: lines, figures, strings, text blocks, the
        # Types box.
        if "admin-again" not in OFF:
            for a, b, word, e, tag, advice in tax.admin_hits(line):
                taken.append((a, b))
                admin_spans.append((a, b))
                self.admin_again(sec, file, ln, admin_limit, e, word, tag, advice, kind)
        # an admin call by its template: 'Add a `Node3D`' calls add a node
        if kind not in ("types", "string") and "admin-calls" not in OFF:
            for e, m in tax.calls_in(line):
                word_at[0] = m.group(0)
                record(e.id)
        # code-shaped words outside code style; read first, so Input.is_action_pressed is code
        for m in CANDIDATE.finditer(blank):
            w = m.group(1)
            if not code_shaped(w) or not free(m.start()):
                continue
            base = w[:-2] if w.endswith("()") else w
            if not_code(base) or (tax.is_form(base) and not w.endswith("()")
                                  and "." not in base and "_" not in base):
                continue
            taken.append((m.start(), m.end()))
            word_at[0] = w
            if base.startswith("$"):
                rep.error(file, ln, "style", "write `%s` in code style" % w)
                record(tax.code_index.get("$")) if "$" in tax.code_index else None
                continue
            whole = tax.code_index.get(base)
            ids = [whole] if whole else [tax.code_index.get(p) for p in base.split(".")]
            if all(ids):
                if kind != "string":
                    rep.error(file, ln, "style", "write `%s` in code style" % w)
                for eid in ids:
                    record(eid, "code" if kind == "string" else "lines")
            elif kind == "string" and FILE_NAME.fullmatch(base):
                taken.pop()     # a file name in a string: the file-name rule reads it
            else:
                rep.error(file, ln, "unknown", "%r looks like code and is not in the taxonomy" % w)
        for a, b, word, tag, eid in tax.iter_forms(blank):
            if not free(a):
                continue
            taken.append((a, b))
            if tag == "syn":
                rep.error(file, ln, "synonym", "%r is a forbidden synonym of %s: write %s"
                          % (word, tax.get(eid).label(), tax.get(eid).label()))
            else:
                e0 = tax.get(eid)
                if (e0 is not None and e0.is_admin and kind not in ("types",)
                        and not call_position(view, a, plain)):
                    continue    # 'how code can add a node': the words, and no call
                word_at[0] = word
                record(eid)
        # a code name that is a plain word, named as a setting: 'Set the size of the box to 2'
        for m in SETTER.finditer(blank):
            w = m.group(1)
            if not free(m.start(1)):
                continue
            eid = tax.code_index.get(w)
            if eid and tax.get(eid).kind in CODE_KINDS and not tax.is_form(w):
                taken.append((m.start(1), m.end(1)))
                rep.error(file, ln, "style", "write `%s` in code style: the line sets the code's "
                          "`%s`" % (w, w))
                word_at[0] = w
                record(eid)
        for m in FILE_NAME.finditer(blank):
            if not free(m.start()):
                continue
            eid = tax.code_index.get(m.group(0))
            if kind == "string" and eid:
                word_at[0] = m.group(0)
                record(eid, "code")
                continue
            rep.error(file, ln, "style" if eid else "unknown",
                      ("write `%s` in code style" if eid else "%r is a file name not in the taxonomy")
                      % m.group(0))
            taken.append((m.start(), m.end()))
        # jargon nobody declared
        if tax.jargon_re:
            for m in tax.jargon_re.finditer(blank):
                if not free(m.start()):
                    continue
                rep.error(file, ln, "unknown", "%r is a technical word not in the taxonomy"
                          % m.group(0))
                taken.append((m.start(), m.end()))
        # inflected and derived words: still the technical word they come from
        for m in re.finditer(r"(?<![\w'])[A-Za-z]+(?![\w])", blank):
            if not free(m.start()):
                continue
            eid = tax.derived(m.group(0))
            if not eid:
                continue
            e = tax.get(eid)
            if e.late(limit):
                if order:
                    self.use_finding(e, file, ln, limit, m.group(0),
                                     label="%r (a form of %s)" % (m.group(0), e.label()))
            elif kind not in ("types", "string"):
                rep.warn(file, ln, "form", "%r is a form of %s that the taxonomy does not list: add "
                         "it to forms, or pin it as a plain word" % (m.group(0), e.label()))
        # inline code spans are always technical; a key in code style (`F5`) that an admin
        # finding took is that finding, not unknown code
        for a, b, sp in spans:
            if any(a < y and x < b for x, y in admin_spans):
                continue
            self.scan_code(sec, sp, ln, where="lines", limit=limit, count_use=count_use,
                           order=order, file=file, span=True)

    # -- shared: code (a fenced block or an inline span)
    def scan_code(self, sec, src, ln0, where="code", limit=None, count_use=True, order=True,
                  file=None, span=False):
        tax, rep = self.tax, self.rep
        file = file or sec.file
        limit = limit or sec.key
        cleaned, problems = clean_text(src)
        for p in problems:
            rep.error(file, ln0, "chars", p)
        src = cleaned
        if span and FILE_NAME.fullmatch(src.strip()) and src.strip() not in tax.code_index:
            # a file of the chapter's own: field_body.gd holds the class FieldBody
            stem = src.strip().rsplit(".", 1)[0].replace("_", "").lower()
            own = {n.replace("_", "").lower() for n in sec.locals}
            if stem not in own and src.strip() not in sec.locals:
                rep.error(file, ln0, "unknown", "the file `%s` is no entry and holds no class or "
                          "function this chapter declares" % src.strip())
            return
        if span and src.strip() in tax.code_index:
            eid = tax.code_index[src.strip()]
            e = tax.get(eid)
            if count_use:
                sec.use(eid, ln0, where)
            if order and e.late(limit):
                self.use_finding(e, file, ln0, limit, src.strip())
            return
        toks, comments = tokenize_code(src)
        decl_names, decl_idx = declarations(toks)
        lit = tax.code_index.get('""')
        for k, t in enumerate(toks):
            ln = ln0 + (t[2] if not span else 0)
            if t[0] == "str":
                # a string literal is an element; what it spells is text or code
                if lit:
                    if count_use:
                        sec.use(lit, ln, where)
                    if order and tax.get(lit).late(limit):
                        self.use_finding(tax.get(lit), file, ln, limit, '""',
                                         label="a string literal (%s)" % tax.get(lit).label())
                else:
                    rep.error(file, ln, "unknown", "a string literal: no entry has the code form \"\"")
                body = t[1]
                if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", body):
                    eid = tax.code_index.get(body)
                    if eid:
                        if count_use:
                            sec.use(eid, ln, where)
                        if order and tax.get(eid).late(limit):
                            self.use_finding(tax.get(eid), file, ln, limit, body,
                                             label='`"%s"`' % body)
                    elif body not in sec.locals and body not in decl_names:
                        rep.error(file, ln, "unknown", "the string \"%s\" names `%s`, which is no "
                                  "entry and not declared here" % (body, body))
                elif body.strip():
                    self.scan_prose(sec, ln, body, "string", preview_limit=limit,
                                    count_use=count_use, order=order, file=file)
                continue
            if t[0] not in ("id", "op"):
                continue
            text = t[1]
            eid = tax.code_index.get(text)
            if k in decl_idx:
                is_func = k > 0 and toks[k - 1][0] == "id" and toks[k - 1][1] == "func"
                if is_func and text.startswith("_") and not eid:
                    rep.error(file, ln, "unknown", "func %s: a name that starts with _ is a Godot "
                              "callback%s; it must be in the taxonomy" %
                              (text, " (one of Godot's virtual methods)" if text in GODOT_VIRTUALS
                               else ""))
                    continue
                if eid:
                    e = tax.get(eid)
                    if is_func or not e.late(limit):
                        # func _process() declares a Godot element; var value_at after its
                        # section is that element
                        if count_use:
                            sec.use(eid, ln, where)
                        if order and e.late(limit):
                            self.use_finding(e, file, ln, limit, text, label="`%s`" % text)
                        continue
                self.check_declared_name(text, ln, limit, file)
                continue
            local = text in sec.locals or text in decl_names
            if eid:
                e = tax.get(eid)
                late = e.late(limit)
                if late and local:
                    continue        # the declaration was reported where it stands
                if count_use:
                    sec.use(eid, ln, where)
                if order and late:
                    self.use_finding(e, file, ln, limit, text, label="`%s`" % text)
                continue
            if local:
                continue
            nxt = toks[k + 1] if k + 1 < len(toks) else None
            prv = toks[k - 1] if k > 0 else None
            if t[0] == "op":
                msg = "operator `%s` is not in the taxonomy" % text
            elif prv and prv[0] == "punct" and prv[1] == ".":
                msg = "unknown member `.%s`" % text
            elif nxt and nxt[0] == "punct" and nxt[1] == "(":
                msg = "unknown call `%s()`: not in the taxonomy, not declared here" % text
            elif text[:1].isupper():
                msg = "unknown class or constant `%s`" % text
            else:
                msg = "unknown name `%s`: not in the taxonomy, not declared here" % text
            rep.error(file, ln, "unknown", msg)
        # names the code declares are text too: no synonyms
        for name in decl_names:
            for part in re.split(r"_+|(?<=[a-z])(?=[A-Z])", name):
                k = part.lower()
                if k in tax.syn_index:
                    eid = tax.syn_index[k]
                    rep.error(file, ln0, "synonym", "the name `%s` uses %r, a forbidden synonym of %s"
                              % (name, part, tax.get(eid).label()))
        for cl, ctext in comments:
            self.scan_prose(sec, ln0 + cl, ctext, "comment", preview_limit=limit,
                            count_use=count_use, order=order, file=file)

    def check_declared_name(self, name, ln, limit, file):
        """A name the code declares may not spell an element that is not introduced yet:
        `var velocity` in chapter 1 would make velocity mean something before 6.1 says what."""
        tax = self.tax
        eids = []
        if name in tax.code_index:
            eids.append(tax.code_index[name])
        phrase = norm_phrase(name.replace("_", " "))
        if phrase in tax.text_index and not name.startswith("_"):
            # _delta: Godot's mark for a parameter left unused; its spelling is no term
            eids.append(tax.text_index[phrase])
        for eid in dict.fromkeys(eids):
            e = tax.get(eid)
            if e and not e.everyday and e.kind not in EVERYDAY_KINDS and e.late(limit):
                self.rep.error(file, ln, "order", "the code declares `%s`, the name of %s, which is "
                               "introduced %s: choose another name" %
                               (name, e.label(), e.where() if e.avail or e.missing else "nowhere"))
                return

    # -- chapters
    def check_chapters(self, chapters, godot=None, godot_opts=None):
        tax, rep = self.tax, self.rep
        seen_ch = {}
        last_key = None
        for ch in chapters:
            if ch.n is None:
                continue
            if ch.n in seen_ch:
                rep.error(ch.file, 1, "format", "chapter %d again (first in %s)"
                          % (ch.n, os.path.basename(seen_ch[ch.n])))
            seen_ch[ch.n] = ch.file
            for s in ch.sections:
                if last_key and s.key <= last_key:
                    rep.error(s.file, s.line, "format", "section %s comes after %s: out of order"
                              % (s.id if not s.head else "head of chapter %d" % ch.n,
                                 sec_name(last_key)))
                last_key = max(last_key, s.key) if last_key else s.key
                s.chapter = ch
                self.program.append(s)
        present = set(seen_ch)
        complete = bool(tax.chapters) and present == set(range(1, int(tax.chapters) + 1))
        by_key = {s.key: s for s in self.program}
        # locals: a chapter is a module; names its code declares are visible to its later sections
        for ch in chapters:
            acc = set()
            for s in ch.sections:
                for b in s.blocks:
                    if b.lang in ("gdscript", "gd", "gdshader"):
                        names, _ = declarations(tokenize_code(b.text)[0])
                        acc |= names
                for ln, raw, kind in s.prose:
                    # 'Make a new script `cup.gd`' names a file of the chapter's own
                    acc |= set(SAVE_AS.findall(raw))
                s.locals = set(acc)
        # pass c, d over every section
        for ch in chapters:
            for s in ch.sections:
                lim = (ch.n, EX) if s.head else s.key
                for ln, raw, kind in s.prose:
                    self.scan_prose(s, ln, raw, kind, preview_limit=lim)
                for b in s.blocks:
                    if b.lang in CODE_LANGS:
                        self.scan_code(s, b.text, b.fence_line + 1, where="code", limit=lim)
                    elif b.lang == "text":
                        # output or plain text: what the student reads, line by line
                        for i, tl in enumerate(b.lines):
                            if tl.strip():
                                self.scan_prose(s, b.fence_line + 1 + i, tl, "string",
                                                preview_limit=lim)
                    else:
                        # a fence in another language is still read: as code
                        self.scan_code(s, b.text, b.fence_line + 1, where="code", limit=lim)
            self.check_types_box(ch)
        # pass b and the signatures
        for s in self.program:
            if s.head:
                continue
            self.check_signature(s)
        # admin procedures: defined once, in their defining section, as the taxonomy has them
        for s in self.program:
            self.check_admin(s)
        for e in tax.order:
            for key, what in ((e.intro_key, "introduced_at"), (e.supplied_key, "introduced_at"),
                              (e.opened_key, "opened_at")):
                if key and key[0] in present and key not in by_key and e.own_chapter is None:
                    rep.error(tax.path, e.line, "gives", "%r: %s %s names no section in %s"
                              % (e.id, what, sec_name(key), os.path.basename(seen_ch[key[0]])))
        # pass e
        self.check_unused(present, complete)
        # pass f
        for s in self.program:
            self.short_speak_section(s)
        # numbers in the lines are tied to the code
        for s in self.program:
            self.check_numbers(s)
            for b in s.blocks:
                if b.lang in ("gdscript", "gd") and b.opts.get("parse"):
                    rep.warn(s.file, b.fence_line, "code", "parse: this block is parsed, never "
                             "run, so nothing it shows is checked")
                elif b.lang in ("gdscript", "gd") and b.opts.get("skip"):
                    rep.warn(s.file, b.fence_line, "code", "skip: Godot never sees this block")
        for ch in chapters:
            for s in ch.sections:
                for b in s.blocks:
                    if b.lang in ("gdscript", "gd") and keep_names(b):
                        self.check_keep(ch, s, b)
        # pass g
        if godot is not None:
            run_godot(self, chapters, godot, godot_opts or {})

    def check_keep(self, ch, s, b):
        """keep=a,b: the section's script keeps members an earlier example of the chapter shows.
        Each is defined there and not again here, and a line of the section names it: the student
        is told what stays in the file (FUNCTIONAL_TEXT 3)."""
        names = keep_names(b)
        _, missing = kept_members(ch, s, names)
        own = {nm for bb in s.blocks if bb.lang in ("gdscript", "gd")
               for nm, _, _ in member_spans(bb.lines)}
        said = set()
        for ln, raw, kind in s.prose:
            for sp in CODE_SPAN.findall(visible(raw)):
                said.add(sp.strip())
        for name in names:
            if name in missing:
                self.rep.error(s.file, b.fence_line - 1, "keep", "keep=%s: no earlier example of "
                               "chapter %s defines `%s`" % (name, ch.n, name))
            elif name in own:
                self.rep.error(s.file, b.fence_line - 1, "keep", "keep=%s, and this section "
                               "defines `%s` again: keep it or show it, not both" % (name, name))
            if name not in said and name + "()" not in said:
                self.rep.error(s.file, b.fence_line - 1, "keep", "keep=%s: no line of %s names "
                               "`%s`, so the student is never told it stays" % (name, s.id, name))

    def check_signature(self, s):
        tax, rep = self.tax, self.rep
        for field in ("needs", "gives", "borrows", "admin"):
            for eid in getattr(s, field):
                if eid not in tax.entries:
                    rep.error(s.file, s.line, "signature", "%s: unknown entry id %r" % (field, eid))
        gives, borrows, needs = set(s.gives), set(s.borrows), set(s.needs)
        admin = set(s.admin)
        if s.key[1] == EX and (gives or borrows or admin):
            rep.error(s.file, s.line, "signature", "exercises give and borrow nothing")
        expect_gives = {e.id for e in tax.order if ((e.intro_key == s.key and e.own_chapter is None)
                        or e.opened_key == s.key) and not e.is_admin}
        if "admin-signature" not in OFF:
            expect_admin = {e.id for e in tax.order if e.is_admin and e.intro_key == s.key}
            for eid in sorted(gives):
                e = tax.get(eid)
                if e and e.is_admin:
                    rep.error(s.file, s.line, "admin", "gives %r, an admin procedure: it goes in "
                              "admin:, the procedures a section defines" % eid)
            gives = {g for g in gives if not (tax.get(g) and tax.get(g).is_admin)}
            for eid in sorted(admin - expect_admin):
                e = tax.get(eid)
                if e is None:
                    continue
                if not e.is_admin:
                    rep.error(s.file, s.line, "admin", "admin: lists %r, a %s; admin: is for admin "
                              "procedures only" % (eid, e.kind))
                else:
                    rep.error(s.file, s.line, "admin", "admin: lists %s, but the taxonomy defines it "
                              "at %s" % (e.text[0], e.where()))
            for eid in sorted(expect_admin - admin):
                rep.error(s.file, s.line, "admin", "the taxonomy defines %s at %s; the section's "
                          "admin: does not list it" % (tax.get(eid).text[0], s.id))
        expect_borrows = {e.id for e in tax.order if e.supplied_key == s.key}
        for eid in sorted(gives - expect_gives):
            e = tax.get(eid)
            if e:
                rep.error(s.file, s.line, "gives", "gives %r, but the taxonomy introduces it at %s"
                          % (eid, e.where()))
        for eid in sorted(expect_gives - gives):
            rep.error(s.file, s.line, "gives", "the taxonomy introduces %r at %s; the section does "
                      "not give it" % (eid, s.id))
        for eid in sorted(borrows - expect_borrows):
            e = tax.get(eid)
            if e:
                rep.error(s.file, s.line, "gives", "borrows %r, but the taxonomy hands it out at %s"
                          % (eid, e.where()))
        for eid in sorted(expect_borrows - borrows):
            rep.error(s.file, s.line, "gives", "the taxonomy hands out %r at %s; the section does "
                      "not borrow it" % (eid, s.id))
        for eid in sorted(gives & expect_gives):
            e = tax.get(eid)
            u = s.uses.get(eid)
            if not u:
                rep.error(s.file, s.line, "gives", "gives %s, but no line or code of %s uses it"
                          % (e.label(), s.id))
            elif not u[1]:
                rep.error(s.file, u[0], "gives", "%s is given in code only: no line names it"
                          % e.label())
            elif e.kind in TERM_KINDS and e.text and not any(
                    kind in ("line", "label") and defines(visible(raw), e.text)
                    for ln, raw, kind in s.prose):
                rep.error(s.file, u[0], "gives", "%s is given here, but no line declares it: write "
                          "'A %s is ...', '... is a %s' or '%s: ...'" % (e.label(), e.text[0],
                                                                        e.text[0], e.text[0]))
        for eid in sorted(borrows & expect_borrows):
            if eid not in s.uses:
                rep.warn(s.file, s.line, "gives", "borrows %s but does not use it here"
                         % tax.get(eid).label())
        for eid, u in sorted(s.uses.items(), key=lambda kv: kv[1][0]):
            e = tax.get(eid)
            if e is None or e.everyday or eid in gives or eid in borrows or e.own_chapter:
                continue
            if eid in admin and e.is_admin and e.intro_key == s.key:
                continue        # its defining section names it
            if eid not in needs:
                rep.error(s.file, s.line, "signature", "uses %s (line %d) but needs does not list %r"
                          % (e.label(), u[0], eid))
        for eid in sorted(needs):
            e = tax.get(eid)
            if e is None:
                continue
            if e.everyday:
                rep.warn(s.file, s.line, "signature", "%r is everyday: it needs no listing" % eid)
                continue
            if e.missing:
                continue        # every use is reported as never taught; once is enough
            if e.own_chapter is not None:
                if e.own_chapter != s.key[0]:
                    rep.error(s.file, s.line, "signature", "needs %r, chapter %d's own name"
                              % (eid, e.own_chapter))
                continue
            if e.avail is None or e.avail >= s.key:
                if eid not in gives and eid not in borrows and eid not in admin:
                    rep.error(s.file, s.line, "signature", "needs %r, which is introduced at %s, "
                              "not before %s" % (eid, e.where() if e.avail else "no section", s.id))
            elif eid not in s.uses:
                rep.warn(s.file, s.line, "signature", "needs %r but never uses it" % eid)
            if eid in gives or eid in borrows or eid in admin:
                rep.warn(s.file, s.line, "signature", "%r is both needed and given" % eid)

    def check_unused(self, present, complete):
        tax, rep = self.tax, self.rep
        for e in tax.order:
            if e.own_chapter is not None:
                continue        # a chapter's own name: nobody after it may use it
            if self.sketch and e.is_admin:
                continue        # the sketch plans the teaching; the chapters call the admin
            for key, kind in ((e.intro_key, "intro"), (e.opened_key, "opened"),
                              (e.supplied_key, "supplied")):
                if not key or key[0] not in present:
                    continue
                later = [s for s in self.program if e.id in s.uses and
                         (s.key > key if kind != "supplied" else s.key >= key)]
                if later:
                    continue
                if kind == "supplied":
                    msg = "%s is supplied at %s and never used" % (e.label(), sec_name(key))
                else:
                    msg = "%s is introduced at %s and never used after it" % (e.label(), sec_name(key))
                sec = next((s for s in self.program if s.key == key), None)
                where = (sec.file, sec.line) if sec else (tax.path, e.line)
                if complete:
                    rep.error(where[0], where[1], "unused", msg)
                elif self.sketch:
                    rep.warn(where[0], where[1], "unused", msg + " (in the sketch's text)")
                else:
                    rep.warn(where[0], where[1], "unused", msg + " (in the chapters checked)")

    def check_types_box(self, ch):
        tax, rep = self.tax, self.rep
        if ch.n is None:
            return
        gives = set()
        borrows = set()
        for s in ch.sections:
            gives |= set(s.gives)
            borrows |= set(s.borrows)
        want = {
            "Types": {g for g in gives if tax.get(g) and tax.get(g).kind in TERM_KINDS},
            "Code": {g for g in gives if tax.get(g) and tax.get(g).kind in CODE_KINDS},
            "Supplied": {b for b in borrows if tax.get(b)},
        }
        got = {"Types": {}, "Code": {}, "Supplied": {}}
        current = None
        for ln, raw in ch.types:
            body = re.sub(r"^>\s?", "", raw).strip()
            m = re.match(r"^\*\*(Types|Code|Supplied)\*\*(?:\s*\([^)]*\))?", body)
            if m:
                current = m.group(1)
                body = body[m.end():]
            if current is None:
                continue
            for item in [x.strip() for x in body.split("·") if x.strip()]:
                im = re.match(r"^(\*([^*]+)\*|`([^`]+)`)\s*(?::\s*(.*))?$", item)
                if not im:
                    rep.error(ch.file, ln, "types", "cannot read the item %r (*term*: def or `code`)"
                              % item)
                    continue
                form = im.group(2) or im.group(3)
                eid = (tax.text_index.get(norm_phrase(form)) if im.group(2)
                       else tax.code_index.get(form.strip()))
                if eid is None:
                    rep.error(ch.file, ln, "types", "%r is no form of any entry" % form)
                    continue
                got[current][eid] = (ln, im.group(4))
                d = im.group(4)
                if d is not None:
                    canon = tax.get(eid).definition
                    if norm_def(d) != norm_def(canon):
                        rep.error(ch.file, ln, "types", "%s: the box says %r, the taxonomy says %r: "
                                  "a type has one definition" % (form, d.strip(), canon))
                # the box is text too: no synonyms, unknown words or later terms in a definition
                if d:
                    tmp = Section("types", (ch.n, EX), ch.file, ln)
                    self.scan_prose(tmp, ln, d, "types", count_use=False, order=True,
                                    preview_limit=(ch.n, EX))
        if not ch.types and any(want.values()):
            rep.error(ch.file, ch.sections[-1].line, "types",
                      "chapter %d has no Types box" % ch.n)
            return
        line = ch.types_line or 1
        for part in ("Types", "Code", "Supplied"):
            for eid in sorted(want[part] - set(got[part])):
                rep.error(ch.file, line, "types", "**%s** is missing %s" % (part, tax.get(eid).label()))
            for eid in sorted(set(got[part]) - want[part]):
                rep.error(ch.file, got[part][eid][0], "types",
                          "**%s** lists %s, which chapter %d does not %s"
                          % (part, tax.get(eid).label(), ch.n,
                             "borrow" if part == "Supplied" else "give"))

    # -- pass f
    def short_speak_section(self, s):
        """Pass f over one section: each line alone, then each sentence that runs on over
        several lines, since Markdown joins them and the student reads one sentence."""
        rep = self.rep
        pending = []        # the lines of the sentence being read
        self.check_lists(s)
        for ln, raw, kind in s.prose:
            if kind == "h1":
                continue
            li = s.items.get(ln)
            self.short_speak(s.file, ln, raw, kind, item=bool(li and li.item))
            if kind != "line":
                pending = []
                continue
            text = visible(raw)
            if pending and pending[-1][0] != ln - 1:
                pending = []
            pending.append((ln, text))
            if not ends_sentence(text):
                rep.error(s.file, ln, "sentence", "the line does not end its sentence: end it with "
                          ". ! ? or :, so the next line starts a new one")
                continue
            if len(pending) > 1:
                n = count_words(" ".join(t for l2, t in pending))
                if n > MAX_WORDS:
                    rep.error(s.file, pending[0][0], "length", "%d words in one sentence over %d "
                              "lines (at most %d)" % (n, len(pending), MAX_WORDS))
            pending = []

    def check_lists(self, s):
        """SHORT_SPEAK, Lines in a tree: a section reads lead, steps, code, tree, point. Its
        first line is plain or a numbered step, never a bullet: the lead is a claim, and a
        section that opens with setup opens with its steps. Its last prose is a plain line, the
        point, never a list item. A section with no list passes; the chapter head and the
        exercises keep their own form."""
        if s.head or s.key is None or s.key[1] == EX or not s.items:
            return
        rep = self.rep
        lines = [ln for ln, raw, kind in s.prose if kind == "line"]
        if lines and "list-lead" not in OFF:
            li = s.items.get(lines[0])
            if li is not None and li.item and not li.step:
                rep.error(s.file, lines[0], "list", "%s opens on a bullet: its lead is a plain "
                          "line, and a bullet comes after it (a section may open on its numbered "
                          "steps)" % s.id)
        if s.prose and "list-point" not in OFF:
            ln = s.prose[-1][0]
            if ln in s.items:
                rep.error(s.file, ln, "list", "%s ends on a list item: its point is a plain line "
                          "after the tree, with a blank line before it" % s.id)
        # a lone doing line stays plain: '1.' promises a '2.' (a step with children may stay)
        if "list-lone" not in OFF:
            for rec in s.lists:
                if rec["step"] and rec["top"] == 1 and not rec["kids"]:
                    rep.warn(s.file, rec["line"], "list", "a numbered list of one step: '1.' "
                             "promises a '2.'. A lone doing line stays a plain line, unless it "
                             "has children")

    def short_speak(self, file, ln, raw, kind, item=False):
        rep = self.rep
        line = visible(raw)
        if kind == "heading":
            line = re.sub(r"^\d+\.(\d+|x)\s+", "", line)
        if kind in ("line", "label", "heading") and "device" not in OFF:
            self.check_devices(file, ln, line, kind)
        if kind == "equation":
            return          # a displayed formula: code, read as code
        n = count_words(line)
        warn_at, max_at = (20, 30) if kind in ("figure", "image") else (WARN_WORDS, MAX_WORDS)
        if n > max_at:
            rep.error(file, ln, "length", "%d words (at most %d)" % (n, max_at))
        elif n > warn_at:
            rep.warn(file, ln, "length", "%d words (aim for %d or fewer)" % (n, warn_at))
        for m in CODE_SPAN.finditer(line):
            w, toks = span_words(m.group(1))
            if toks > 8:
                rep.error(file, ln, "length", "inline code `%s` holds %d names and numbers: put "
                          "it in a code block" % (m.group(1)[:40], toks))
        if kind in ("figure", "image"):
            return
        prose = CODE_SPAN.sub(" X ", line)
        if kind == "line":
            if sentence_breaks(prose):
                if item and "list-sentence" not in OFF:
                    rep.error(file, ln, "list", "the item holds two sentences: one sentence per "
                              "item, so make the second an item of its own")
                else:
                    rep.error(file, ln, "sentence", "more than one sentence on the line")
            if ";" in prose:
                rep.error(file, ln, "sentence", "a semicolon joins two claims: one claim per line")
            if re.search(r"\s[—–]\s|\s--\s|\w—\w|\s-\s", prose):
                rep.error(file, ln, "sentence", "a dash joins two claims: one claim per line")
            if len(re.findall(r"(?<!\d):|:(?!\d)", prose)) > 1:
                rep.error(file, ln, "sentence", "two colons: one claim per line, one colon at most")
        low = prose.lower()
        for ex in FILLER_EXEMPT:
            low = low.replace(ex, " ")
        for f in self.tax.filler:
            pat = FILLER_ONLY_AT.get(f) or (r"(?<![\w'])" + r"\s+".join(re.escape(w) for w in f.split())
                                            + r"(?![\w'])")
            if re.search(pat, low):
                rep.error(file, ln, "filler", "filler %r" % f)
        for h in HEDGES:
            if re.search(r"(?<![\w'])" + r"\s+".join(re.escape(w) for w in h.split()) + r"(?![\w'])",
                         low):
                rep.error(file, ln, "hedge", "%r hedges: say what is so" % h)
        for p in POETIC_VERBS:
            m = re.search(r"(?<![\w'])" + r"\s+".join(re.escape(w) for w in p.split()) + r"(?![\w'])",
                          low)
            if m and not re.search(r"\b(?:you|i|we|they)\s+$", low[:m.start()]):
                rep.error(file, ln, "poetic", "%r: a thing does not %s; say what the code does"
                          % (p, p.split()[0].rstrip("s") if not p.endswith("ed") else p))
        for v in VOICE_WORDS:
            if v == "i":
                hit = re.search(r"(?<![\w'])I(?![\w'])", prose)
            else:
                hit = re.search(r"(?<![\w'])" + re.escape(v) + r"(?![\w'])", prose, re.IGNORECASE)
            if hit:
                rep.warn(file, ln, "voice", "%r: write in the second person" % hit.group(0))

    def check_devices(self, file, ln, line, kind):
        """FUNCTIONAL_TEXT 2b: the page uses its declared devices and no others. A marker that
        round one proposed and round two dropped is refused: a label or an arrow that opens the
        line, and a provenance tag anywhere in it. 'Restore:' is a device and passes."""
        hits = []
        if kind != "heading":
            m = DEVICE_LEAD.match(line)
            if m:
                hits.append(m.group(0).strip())
        # a code span is code, unless it holds nothing but a tag: `[run]` is the marker
        bare = CODE_SPAN.sub(lambda m: m.group(1).strip() if DEVICE_TAG_SPAN.fullmatch(m.group(1))
                             else " " * len(m.group(0)), line)
        hits.extend(t.group(0) for t in DEVICE_TAG.finditer(bare))
        for h in hits:
            self.rep.error(file, ln, "device", "%r: the marker is not a device (FUNCTIONAL_TEXT 2b)"
                           % h)

    # -- numbers in the lines, tied to the code
    def check_numbers(self, s):
        """A number the lines of a section with a run state must be one the run can show: a
        literal in the section's code, a printed line, or a claim. An instruction's numbers,
        before its colon, are inputs and stay free."""
        if s.head or s.key[1] == EX:
            return
        runs = [b for b in s.blocks if b.lang in ("gdscript", "gd") and not (
            b.opts.get("parse") or b.opts.get("skip") or b.opts.get("fails"))]
        if not runs:
            return
        known = set()
        # keep=: the members a section's script keeps are its code too
        kept = []
        if getattr(s, "chapter", None) is not None:
            kept = kept_members(s.chapter, s, [n for b in runs for n in keep_names(b)])[0]
        for b in s.blocks + kept:
            if b.lang not in CODE_LANGS:
                continue
            for t in tokenize_code(b.text)[0]:
                if t[0] == "num":
                    known.add(num_value(t[1]))
            for k in ("prints", "claim"):
                for v in b.opts.get(k) or []:
                    known.update(numbers_in(v))
        for ln, raw, kind in s.prose:
            if kind != "line":
                continue
            line = CODE_SPAN.sub(" ", visible(raw))
            words = line.strip().split()
            if words and words[0].lower().strip(",:") in IMPERATIVES and ":" in line:
                line = line[line.index(":") + 1:]       # 'Set tall to 5: the spire grows'
            elif words and words[0].lower() in IMPERATIVES:
                continue
            for value, word in numbers_with_words(line):
                if value not in known:
                    self.rep.error(s.file, ln, "number", "%s is stated, but neither the code, a "
                                   "printed line nor a claim of %s shows it: add a claim" % (word, s.id))

    # -- sketch mode
    def check_sketch(self, path, chapters_filter=None):
        tax, rep = self.tax, self.rep
        with open(path, encoding="utf-8") as f:
            raw_text = f.read()
        data = json.loads(raw_text)
        chapters = [c for p in data.get("parts", []) for c in p.get("chapters", [])]

        def lineno(s):
            for cand in (json.dumps(s, ensure_ascii=False)[1:-1], json.dumps(s)[1:-1]):
                pos = raw_text.find(cand)
                if pos >= 0:
                    return line_of(raw_text, pos)
            return 1

        checked = {c["n"] for c in chapters
                   if chapters_filter is None or c["n"] in chapters_filter}
        by_key = {}
        for c in chapters:
            n = c["n"]
            head = Section("%d.0" % n, (n, HEAD), path, lineno(c.get("title", "")))
            head.head = True
            secs = []
            for sd in c.get("sections", []):
                k = sec_key(sd.get("n", ""))
                s = Section(sd.get("n"), k, path, lineno(sd.get("idea", "")))
                s.sk = sd
                secs.append(s)
                by_key[k] = s
            ex = Section("%d.x" % n, (n, EX), path, lineno((c.get("exercises") or [""])[0]))
            c["_head"], c["_secs"], c["_ex"] = head, secs, ex
            self.program.extend([head] + secs + [ex])
        for c in chapters:
            n = c["n"]
            head, secs, ex = c["_head"], c["_secs"], c["_ex"]
            on = n in checked
            # gives: code_new
            chapter_new = [e for e in tax.order if (e.intro_key and e.intro_key[0] == n) or
                           (e.opened_key and e.opened_key[0] == n)]
            for item in c.get("code_new", []):
                ln = lineno(item)
                found = self.sketch_scan(head, ln, item, inventory=True, order=False, report=on)
                syn = self.last_syn
                here = {e.id for e in chapter_new
                        if e.id in found or e.id in syn or self.mentions(item, e)}
                refs = back_refs(item)
                if not on:
                    continue
                heads = head_entries(item, found, lambda t: any(self.mentions(t, e)
                                                                for e in chapter_new),
                                     {eid: (tax.get(eid).text or [""])[0] for eid in found})
                again = []
                for eid, occ in found.items():
                    e = tax.get(eid)
                    if e.everyday:
                        continue
                    sense = e.sense_at(occ[0][2], (n, HEAD))
                    if sense:
                        rep.warn(path, ln, "sense", "[%s] %r is another sense here (%s); the type "
                                 "%s is %s" % (sec_name((n, HEAD)), occ[0][2], sense, e.label(),
                                                e.where()))
                        self.fact("sense", e, (n, HEAD), ln, occ[0][2], sense=sense)
                        continue
                    if e.missing:
                        rep.warn(path, ln, "never", "code_new of chapter %d names %s, which no "
                                 "section teaches" % (n, e.label()))
                        self.fact("never", e, (n, HEAD), ln, occ[0][2], where="code_new")
                    elif e.avail and e.avail[0] > n:
                        rep.error(path, ln, "order", "code_new of chapter %d names %s, introduced "
                                  "later (%s)" % (n, e.label(), e.where()))
                        self.fact("order", e, (n, HEAD), ln, occ[0][2], where="code_new")
                    elif e.avail and e.avail[0] < n and eid not in here:
                        if e.avail[0] in refs:
                            continue        # a return the item declares: (met in ch13)
                        if e.code and not e.text and all(is_symbol(f) for f in e.code):
                            continue        # an operator: + and - turn, & and ^ tilt
                        if eid not in heads:
                            continue        # used, not listed: 'a step along the body's axes'
                        if all(in_formula(item, a, b) for a, b, w in occ):
                            continue        # a part of a formula: position += velocity * delta
                        again.append((e, occ[0][2]))
                for e, word in again:
                    rep.warn(path, ln, "twice", "code_new of chapter %d names %s again, outside a "
                             "formula; the taxonomy introduces it at %s" % (n, e.label(), e.where()))
                    self.fact("twice", e, (n, HEAD), ln, word, item=item)
                if refs and found and not any(tax.get(x).avail and tax.get(x).avail[0] in refs
                                              for x in found):
                    rep.warn(path, ln, "gives", "code_new item points back to chapter %s, but the "
                             "taxonomy introduces none of %s there"
                             % (", ".join(str(r) for r in sorted(refs)), ", ".join(sorted(found))))
                if not here and tax.order:
                    known = [x for x in found if not tax.get(x).missing]
                    if known:
                        rep.warn(path, ln, "gives", "code_new item teaches nothing new in chapter %d: "
                                 "it names only %s" % (n, ", ".join(tax.get(x).label() for x in known)))
                    else:
                        rep.error(path, ln, "gives", "code_new item names nothing the taxonomy "
                                  "introduces in chapter %d: %r" % (n, item[:60]))
            for item in c.get("code_returns", []):
                ln = lineno(item)
                found = self.sketch_scan(head, ln, item, inventory=True, order=False, report=on)
                for eid in found:
                    e = tax.get(eid)
                    if on and not e.everyday and (e.avail is None or e.avail >= (n, 0)):
                        rep.error(path, ln, "order", "code_returns of chapter %d names %s, which "
                                  "has not been introduced before (%s)" % (n, e.label(), e.where()))
                refs = re.findall(r"\((\d+\.\d+)\)\s*$", item)
                if on and refs and found:
                    k = sec_key(refs[0])
                    if not any(tax.get(x).intro_key == k or tax.get(x).supplied_key == k
                               for x in found):
                        rep.warn(path, ln, "gives", "code_returns says (%s), but the taxonomy "
                                 "introduces none of %s there" % (refs[0], ", ".join(sorted(found))))
            # borrowed as supplied
            supplied_here = [e for e in tax.order if e.supplied_key and e.supplied_key[0] == n]
            borrowed = c.get("borrowed", [])
            for item in borrowed:
                ln = lineno(item)
                found = self.sketch_scan(head, ln, item, inventory=True, order=False, report=on,
                                         count_use=False)
                names = set(found) | set(self.last_syn) | {e.id for e in supplied_here
                                                           if self.mentions(item, e)}
                if on and not any(tax.get(x).supplied_key and tax.get(x).supplied_key[0] == n
                                  for x in names):
                    earlier = [x for x in names if not tax.get(x).missing and tax.get(x).avail
                               and not tax.get(x).everyday and tax.get(x).avail < (n, 0)]
                    if earlier:
                        rep.note(path, ln, "gives", "borrowed item supplies nothing new in chapter "
                                 "%d: it brings back %s" % (n, ", ".join(sorted(earlier))))
                    else:
                        rep.error(path, ln, "gives", "borrowed item names no part the taxonomy "
                                  "supplies in chapter %d: %r" % (n, item[:60]))
            for e in supplied_here:
                if on and not any(self.mentions(item, e) for item in borrowed):
                    rep.error(tax.path, e.line, "gives", "%r is supplied at %s, but chapter %d's "
                              "borrowed list does not name it" % (e.id, sec_name(e.supplied_key), n))
            # uses: titles, ideas, figures; examples, exercises, the project step
            for s in secs:
                sd = s.sk
                for fld in ("title", "idea", "figure"):
                    if sd.get(fld):
                        found = self.sketch_scan(s, lineno(sd[fld]), sd[fld], order=True, report=on)
                        if on and fld in ("title", "idea"):
                            self.check_defines(s, lineno(sd[fld]), sd[fld], found, n)
            for fld in ("examples", "exercises"):
                for item in c.get(fld, []) or []:
                    self.sketch_scan(ex, lineno(item), item, order=True, report=on)
            if c.get("project_step"):
                self.sketch_scan(ex, lineno(c["project_step"]), c["project_step"], order=True,
                                 report=on)
            # gives: each entry introduced in this chapter is named where it is introduced
            new_text = " \n ".join(c.get("code_new", []))
            for e in tax.order:
                for key in (e.intro_key, e.opened_key):
                    if not key or key[0] != n or not on or e.own_chapter is not None:
                        continue
                    if e.is_admin:
                        continue    # admin is no teaching: the sketch need not name it
                    if key[1] == HEAD:
                        # placed at chapter level: code_new names it, no section does
                        if self.mentions(new_text, e):
                            rep.warn(tax.path, e.line, "unplaced", "%r is taught in chapter %d: its "
                                     "code_new names it, no section does" % (e.id, n))
                        else:
                            rep.warn(tax.path, e.line, "gives", "%r is placed in chapter %d, but "
                                     "chapter %d's code_new does not name it" % (e.id, n, n))
                        self.fact("unplaced", e, key, e.line, "")
                        continue
                    s = by_key.get(key)
                    if s is None:
                        rep.error(tax.path, e.line, "gives", "%r: %s names no section of the sketch"
                                  % (e.id, sec_name(key)))
                        continue
                    if (key == e.intro_key and e.kind in ("gdscript", "godot")
                            and not self.mentions(new_text, e)):
                        rep.warn(tax.path, e.line, "listing", "%r is taught at %s, but chapter %d's "
                                 "code_new does not list it" % (e.id, sec_name(key), n))
                        self.fact("listing", e, key, e.line, "")
                    texts = [new_text] + [s.sk.get(f, "") or "" for f in
                                          ("title", "idea", "figure", "builds")]
                    if not any(self.mentions(t, e) for t in texts):
                        # the sketch is planning prose: a term it never names is a finding,
                        # not a break in the order
                        rep.warn(tax.path, e.line, "gives", "%r is introduced at %s, but neither "
                                 "chapter %d's code_new nor %s's text names it"
                                 % (e.id, sec_name(key), n, sec_name(key)))
        # pass e over the sketch: a warning, since the sketch names few of the code elements
        # the book will reuse; in chapter files it is an error once the book is complete
        self.check_unused(checked, False)

    def check_defines(self, sec, ln, text, found, n):
        """'A pin is a point that may not move' (17.2): a title or idea that defines an entry
        the taxonomy introduces in an earlier chapter teaches it a second time."""
        for eid, occ in found.items():
            e = self.tax.get(eid)
            if e.everyday or e.missing or not e.avail or e.avail[0] >= n or not e.text:
                continue
            for a, b, w in occ:
                pat = re.escape(w)
                for m in re.finditer(DEFINES % (pat, pat), text, re.IGNORECASE):
                    if (m.start(1) == a) or (m.start(2) == a):
                        self.rep.warn(sec.file, ln, "twice", "[%s] defines %s again; the taxonomy "
                                      "introduces it at %s" % (sec_name(sec.key), e.label(), e.where()))
                        self.fact("twice", e, sec.key, ln, w, item=text)
                        break
                else:
                    continue
                break

    def mentions(self, text, e):
        """Liberal presence: any form of e in text; an admin procedure also by its steps."""
        if e.is_admin and any(phrase_regex(p, any_case=True).search(text)
                              for p in [s for s in e.synonyms if "{" not in s]):
            return True
        if e.is_admin and any(phrase_regex(p).search(text) for p, c in e.step_phrases if p):
            return True
        for f in e.text:
            if re.search(r"(?<![\w])" + r"\s+".join(re.escape(w) for w in f.split()) + r"(?![\w])",
                         text, re.IGNORECASE):
                return True
        for f in e.code:
            if is_symbol(f):
                if re.search(r"(?<![-+*/%=<>!&|^~:])" + re.escape(f) + r"(?![-+*/%=<>!&|^~])", text):
                    return True
            elif re.search(r"(?<![\w])" + re.escape(f) + r"(?![\w])", text):
                return True
        return False

    def sketch_scan(self, sec, ln, text, inventory=False, order=True, report=True, count_use=True):
        """Scan sketch prose. Returns {entry id: [(start, end, word), ...]} for the entries found;
        synonym hits are left in self.last_syn. Code forms that are plain English words (if, for,
        var, mesh) are not read in sketch prose; their concept words carry the order.
        Code-shaped words are read first, so Input.is_action_pressed() is code, not 'input'."""
        tax, rep = self.tax, self.rep
        found = {}
        syn = {}
        taken = []

        def free(a):
            return not any(x <= a < y for x, y in taken)

        def hit(eid, a, b):
            taken.append((a, b))
            if eid is None:
                return
            found.setdefault(eid, []).append((a, b, text[a:b]))
            if count_use:
                sec.use(eid, ln, "lines")
            e = tax.get(eid)
            if report and order and e.late(sec.key):
                self.use_finding(e, sec.file, ln, sec.key, text[a:b],
                                 prefix="[%s] " % sec_name(sec.key))

        # an admin procedure described in another chapter than its own: the chapters will say
        # only its name there
        for a, b, word, e, tag, advice in tax.admin_hits(text):
            taken.append((a, b))
            own = e.intro_key and sec.key and e.intro_key[0] == sec.key[0]
            if report and not own and "admin-again" not in OFF:
                where = ("%s defines" % e.where()) if e.intro_key else "no section defines yet"
                rep.warn(sec.file, ln, "admin", "[%s] %r describes %s, which %s: the chapters "
                         "say \"%s\"" % (sec_name(sec.key), word, e.text[0], where, advice))
        for f in tax.sig_forms:
            for m in re.finditer(re.escape(f), text):
                if free(m.start()):
                    hit(tax.code_index[f], m.start(), m.end())
        for m in CANDIDATE.finditer(text):
            w = m.group(1)
            if not free(m.start()) or not code_shaped(w):
                continue
            base = w[:-2] if w.endswith("()") else w
            if not_code(base) or (tax.is_form(base) and not w.endswith("()")
                                  and "." not in base and "_" not in base):
                continue        # a text form (fBm, P1) is read below; a hall or chapter is no code
            if base.startswith("$"):
                hit(tax.code_index.get("$"), m.start(), m.end())
                continue
            whole = tax.code_index.get(base)
            parts = [base] if whole else base.split(".")
            ids = [whole] if whole else [tax.code_index.get(p) for p in parts]
            if all(ids):
                for eid in ids:
                    hit(eid, m.start(), m.end())
            elif in_formula(text, m.start(), m.end()):
                taken.append((m.start(), m.end()))     # a formula's own variable: m1, dE
            elif report:
                missing = [p for p, i in zip(parts, ids) if not i]
                rep.error(sec.file, ln, "unknown", "[%s] %r looks like code and is not in the "
                          "taxonomy" % (sec_name(sec.key), ".".join(missing)))
                taken.append((m.start(), m.end()))
        for m in re.finditer(r"(?<![\w$@.])[A-Z][A-Z0-9_]+(?![\w(])", text):
            eid = tax.code_index.get(m.group(0))
            if eid and free(m.start()) and not tax.get(eid).text:
                hit(eid, m.start(), m.end())        # NORMAL, UNION, TIME: the code constant
        for a, b, word, tag, eid in tax.iter_forms(text):
            if not free(a):
                continue
            if tag == "syn":
                taken.append((a, b))
                syn.setdefault(eid, []).append((a, b, word))
                if report:
                    e = tax.get(eid)
                    sense = e.sense_at(word, sec.key)
                    if sense:
                        rep.warn(sec.file, ln, "sense", "[%s] %r is another sense here (%s), "
                                 "not the synonym of %s" % (sec_name(sec.key), word, sense,
                                                            e.label()))
                        self.fact("sense", e, sec.key, ln, word, sense=sense)
                    else:
                        rep.warn(sec.file, ln, "synonym", "[%s] %r is a forbidden synonym of %s"
                                 % (sec_name(sec.key), word, e.label()))
            else:
                hit(eid, a, b)
        for m in FILE_NAME.finditer(text):
            if not free(m.start()):
                continue
            eid = tax.code_index.get(m.group(0))
            if eid:
                hit(eid, m.start(), m.end())
            elif report:
                rep.error(sec.file, ln, "unknown", "[%s] %r is a file name not in the taxonomy"
                          % (sec_name(sec.key), m.group(0)))
        if inventory:
            for f, eid in tax.code_index.items():
                if is_symbol(f):
                    for m in re.finditer(r"(?:(?<=\s)|^)" + re.escape(f) + r"(?=\s|$|[,;)])", text):
                        if free(m.start()):
                            hit(eid, m.start(), m.end())
        if tax.jargon_re and report:
            for m in tax.jargon_re.finditer(text):
                if not free(m.start()):
                    continue
                rep.error(sec.file, ln, "unknown", "[%s] %r is a technical word not in the "
                          "taxonomy" % (sec_name(sec.key), m.group(0)))
        if report:
            for m in re.finditer(r"(?<![\w'])[A-Za-z]+(?![\w])", text):
                if not free(m.start()):
                    continue
                eid = tax.derived(m.group(0))
                if eid:
                    e = tax.get(eid)
                    late = " before it is introduced (%s)" % e.where() if order and e.late(sec.key) else ""
                    rep.warn(sec.file, ln, "form", "[%s] %r is a form of %s that the taxonomy does "
                             "not list%s" % (sec_name(sec.key), m.group(0), e.label(), late))
        self.last_syn = syn
        return found


def norm_def(s):
    s = re.sub(r"\s+", " ", s.strip()).rstrip(".")
    return s[:1].lower() + s[1:]


# ---------------------------------------------------------------- pass g: Godot

RUNNER = r'''extends SceneTree
## Written by check.py. Parses every unit in one boot, runs the run units in turn, and at the
## end of each run asks its claims. Each run unit's script stands in for the node the text puts
## it on, the root node (a Node3D) unless on= says another: FT_BASE says whether it may go there.
var runs := []
var cur = null
var cur_id := ""
var cur_claims := 0
var cur_until := false
var frames_left := 0
var t0 := 0

func _initialize() -> void:
	var f := FileAccess.open("res://units.txt", FileAccess.READ)
	var units := []
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line != "":
			units.append(line.split("|"))
	for u in units:
		var gd := ResourceLoader.load(u[1], "GDScript", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		var ok := gd != null and gd.can_instantiate()
		print("FT_PARSE ", u[0], " ", "ok" if ok else "fail")
		if ok and int(u[2]) > 0:
			runs.append([u[0], gd, int(u[2]), int(u[3]), u[4] == "1", u[5] if u.size() > 5 else "Node3D"])

func _process(_delta: float) -> bool:
	if cur == null:
		if runs.is_empty():
			print("FT_DONE")
			quit(0)
			return true
		var r = runs.pop_front()
		cur_id = r[0]
		cur_claims = r[3]
		cur_until = r[4]
		t0 = Time.get_ticks_msec()
		print("FT_RUN_BEGIN ", cur_id)
		cur = r[1].new()
		var base: String = cur.get_class()
		print("FT_BASE ", cur_id, " ", base, " ", "yes" if ClassDB.is_parent_class(r[5], base) else "no")
		if cur.has_method("_ft_scene"):
			cur._ft_scene()
		root.add_child(cur)
		frames_left = r[2]
		return false
	frames_left -= 1
	if frames_left <= 0 and cur_until and Time.get_ticks_msec() - t0 < 30000:
		var w = cur.call("_ft_until")
		if not (typeof(w) == TYPE_BOOL and w):
			return false
	if frames_left <= 0:
		if cur_until:
			var w = cur.call("_ft_until")
			print("FT_UNTIL ", cur_id, " ", "yes" if typeof(w) == TYPE_BOOL and w else "no")
		for i in cur_claims:
			var v = cur.call("_ft_claim_%d" % i)
			print("FT_CLAIM ", cur_id, " ", i, " ", "yes" if typeof(v) == TYPE_BOOL and v else "no")
		print("FT_RUN_END ", cur_id)
		cur.queue_free()
		cur = null
	return false
'''

CLASS_LINE = re.compile(r"^(func|var|const|signal|enum|static|class|@\w+)\b")
SCRIPT_LINE = re.compile(r"^(extends|class_name)\b")
# One convention for scripts (2 October 2026): every chapter script goes on the base scene's top
# node, a Node3D, where $Supplied resolves. A script for a MeshInstance3D cannot go there: Godot
# refuses it. A block whose script goes on another node says so: on=CharacterBody3D.
TOP_NODE = "Node3D"
EXTENDS_LINE = re.compile(r"^extends\s+\S")
# keep= (2 October 2026, chapter 5): a section's script keeps members an earlier example of the
# chapter defined, so the page shows them once. A member as a script holds it:
MEMBER_HEAD = re.compile(r"^(?:@\w+(?:\([^)]*\))?\s+)*(?:static\s+)?(?:var|const|func)\s+(\w+)")
CLOSER = re.compile(r"^[\]\)\}]+,?\s*$")


class Unit:
    def __init__(self, uid, sec, blocks):
        self.id = uid
        self.sec = sec
        self.blocks = blocks
        self.map = []          # generated line (1-based index - 1) -> source, or None
        self.text = ""
        self.frames = 0
        self.prints = []
        self.claims = []
        self.fails = any(b.opts.get("fails") for b in blocks)
        self.classname = None
        self.no_extends = False
        self.bad_nodes = []
        self.until = None
        # the node the text puts the script on: the root node, a Node3D, unless a block says on=
        self.on = next((b.opts["on"] for b in blocks if isinstance(b.opts.get("on"), str)), TOP_NODE)


def runs_block(b):
    return not (b.opts.get("parse") or b.opts.get("skip") or b.opts.get("fails")
                or b.opts.get("kept"))


def block_kinds(blocks):
    kinds = []
    for b in blocks:
        ls = b.lines
        top = [x for x in ls if x.strip() and not x[0].isspace() and not x.startswith("#")
               and not CLOSER.match(x)]     # an array's last ']' at the left edge
        if any(SCRIPT_LINE.match(x) for x in ls):
            kinds.append("script")
        elif any(CLASS_LINE.match(x) and not re.match(r"^(var|const)\b", x) for x in top):
            kinds.append("class")       # it declares a func, signal, enum, annotation ...
        elif top and all(re.match(r"^(var|const)\b", x) for x in top):
            kinds.append("class")       # only declarations: members of the script
        else:
            kinds.append("stmt")        # lines that run: they go into _ready()
    return kinds


def scene_hosts(tax, key):
    """The $Node hosts of the supplied parts handed out by section key: nodes the supplied
    base scene has, which the student's code reaches with $."""
    return sorted({e.host for e in tax.order if e.stub and isinstance(e.host, str)
                   and e.host.startswith("$") and e.supplied_key and e.supplied_key <= key})


def build_unit(unit, tax, inherited):
    """One script for Godot from a section's blocks. Statements go into _ready(); a block
    without an extends line takes the last one the book showed before it (inherited)."""
    blocks = unit.blocks
    gen, gmap = [], []

    def emit(text, src=None):
        gen.append(text)
        gmap.append(src)

    kinds = block_kinds(blocks)
    declared_funcs = set()
    for b in blocks:
        for x in b.lines:
            m = re.match(r"^(?:static\s+)?func\s+(\w+)", x)
            if m:
                declared_funcs.add(m.group(1))
    script_blocks = [b for b, k in zip(blocks, kinds) if k == "script"]
    body_start = 0
    if script_blocks:
        sb = script_blocks[0]
        header = [i for i, x in enumerate(sb.lines) if SCRIPT_LINE.match(x)]
        last = max(header)
        for i in range(last + 1):
            emit(sb.lines[i], (sb, i))
            m = re.match(r"^class_name\s+(\w+)", sb.lines[i])
            if m:
                unit.classname = m.group(1)
        body_start = last + 1
        if not any(EXTENDS_LINE.match(x) for x in sb.lines):
            if inherited:
                emit(inherited, ("extends", sb))
            else:
                unit.no_extends = True
                emit("extends Node3D", ("extends", sb))
    elif inherited:
        emit(inherited, ("extends", blocks[0]))
    else:
        unit.no_extends = True
        emit("extends Node3D", ("extends", blocks[0]))
    emit("")
    # the scene: nodes= stands in for what the text has the student build in the editor;
    # a $host stands in for a node of the supplied base scene
    nodes = []
    for b in blocks:
        spec = b.opts.get("nodes")
        if isinstance(spec, str):
            for part in spec.split(","):
                bits = part.strip().split(":")
                if bits and bits[0]:
                    nodes.append((b, bits))
    hosts = scene_hosts(tax, unit.sec.key)
    if nodes or hosts:
        emit("func _ft_scene() -> void:")
        made = {}
        for i, (b, bits) in enumerate(nodes):
            path = bits[0].strip("/")
            typ = bits[1] if len(bits) > 1 and bits[1] else "Node3D"
            var = "_ft_n%d" % i
            emit("\tvar %s := %s.new()" % (var, typ), ("nodes", b))
            emit("\t%s.name = \"%s\"" % (var, path.split("/")[-1]), ("nodes", b))
            if len(bits) > 2 and bits[2]:
                prop = "shape" if typ == "CollisionShape3D" else "mesh"
                emit("\t%s.%s = %s.new()" % (var, prop, bits[2]), ("nodes", b))
            parent = "/".join(path.split("/")[:-1])
            if parent and parent not in made:
                unit.bad_nodes.append((b, path))
                parent = ""
            emit("\t%sadd_child(%s)" % (made[parent] + "." if parent else "", var), ("nodes", b))
            made[path] = var
        for j, h in enumerate(hosts):
            emit("\tvar _ft_h%d := Node.new()" % j)
            emit("\t_ft_h%d.name = \"%s\"" % (j, h[1:]))
            emit("\t_ft_h%d.set_script(load(\"res://hosts/%s.gd\"))" % (j, h[1:]))
            emit("\tadd_child(_ft_h%d)" % j)
        emit("")
    stmts = []
    for b, k in zip(blocks, kinds):
        if k == "script":
            start = body_start if b is script_blocks[0] else 0
            for i in range(start, len(b.lines)):
                if b is not script_blocks[0] and SCRIPT_LINE.match(b.lines[i]):
                    continue
                emit(b.lines[i], (b, i))
            emit("")
        elif k == "class":
            for i, x in enumerate(b.lines):
                emit(x, (b, i))
            emit("")
        else:
            stmts.append(b)
    # claims: expressions that must be true once the run's frames are done
    claims = []
    for b in blocks:
        for c in b.opts.get("claim") or []:
            claims.append((b, c))
    for i, (b, c) in enumerate(claims):
        emit("func _ft_claim_%d():" % i, ("claim", b, i))
        emit("\treturn (%s)" % c, ("claim", b, i))
        emit("")
    unit.claims = claims
    untils = [(b, b.opts["until"]) for b in blocks if isinstance(b.opts.get("until"), str)]
    if untils:
        b, expr = untils[0]
        emit("func _ft_until():", ("claim", b, -1))
        emit("	return (%s)" % expr, ("claim", b, -1))
        emit("")
        unit.until = expr
    if stmts:
        fname = "_ft_fragment" if "_ready" in declared_funcs else "_ready"
        emit("func %s() -> void:" % fname)
        wrote = False
        for b in stmts:
            unit_indent = "\t"
            for x in b.lines:
                if x.startswith(" "):
                    unit_indent = "    "
                    break
            for i, x in enumerate(b.lines):
                if x.strip():
                    emit(unit_indent + x, (b, i))
                    wrote = True
        if not wrote:
            emit("\tpass")
    unit.text = "\n".join(gen) + "\n"
    unit.map = gmap
    running = [b for b in blocks if runs_block(b)]
    if running and not unit.fails:
        unit.frames = max(int(b.opts.get("frames", DEFAULT_FRAMES)) for b in running)
    for b in blocks:
        for want in b.opts.get("prints") or []:
            unit.prints.append((b, want))


def member_spans(lines):
    """The members a block of script defines, as (name, first, end): a var, const or func at
    the left edge, and the lines that belong to it: indented, blank, or a closing bracket at the
    left edge, as an array's last ']' stands. Trailing blank lines are not its own."""
    spans = []
    i = 0
    while i < len(lines):
        m = MEMBER_HEAD.match(lines[i])
        if not m:
            i += 1
            continue
        j = i + 1
        while j < len(lines) and (not lines[j].strip() or lines[j][0].isspace()
                                  or CLOSER.match(lines[j])):
            j += 1
        end = j
        while end > i + 1 and not lines[end - 1].strip():
            end -= 1
        spans.append((m.group(1), i, end))
        i = j
    return spans


def keep_names(b):
    """keep=palette,source,square: the members a block's script keeps from earlier examples."""
    v = b.opts.get("keep")
    if not isinstance(v, str):
        return []
    names = [n.strip().rstrip("()").strip() for n in v.split(",")]
    return [n for n in names if n]


def kept_members(ch, s, names):
    """For each kept name, its last definition in an earlier section of the chapter, as a block
    whose lines point at the lines the page shows there. Answers (blocks, names not found)."""
    earlier = []
    for t in ch.sections:
        if t is s:
            break
        earlier.append(t)
    blocks, missing = [], []
    for name in names:
        hit = None
        for t in reversed(earlier):
            for b in reversed(t.blocks):
                if (b.lang not in ("gdscript", "gd") or b.opts.get("skip") or b.opts.get("fails")
                        or b.opts.get("kept")):
                    continue
                for nm, i, j in reversed(member_spans(b.lines)):
                    if nm == name:
                        hit = (b, i, j)
                        break
                if hit:
                    break
            if hit:
                break
        if not hit:
            missing.append(name)
            continue
        b, i, j = hit
        kb = Block(b.lang, b.fence_line + i, {"kept": True})
        kb.lines = b.lines[i:j]
        blocks.append(kb)
    return blocks, missing


def collect_units(chapters):
    units = []
    for ch in chapters:
        for s in ch.sections:
            group = []
            for b in s.blocks:
                if b.lang not in ("gdscript", "gd"):
                    continue
                if b.opts.get("skip"):
                    continue
                if b.opts.get("alone") or b.opts.get("fails"):
                    kept = kept_members(ch, s, keep_names(b))[0]
                    units.append(Unit("u%d" % (len(units) + 1), s, [b] + kept))
                else:
                    group.append(b)
            if group:
                # kept members go last: a unit's first block is one the page shows
                kept = kept_members(ch, s, [n for b in group for n in keep_names(b)])[0]
                units.append(Unit("u%d" % (len(units) + 1), s, group + kept))
    return units


def record_calls(stub):
    """The stub, with each function noting its own name in _ft_calls when it is called,
    so a claim can count the calls: $Supplied._ft_calls.count("line") == 2."""
    out = []
    for line in stub.split("\n"):
        out.append(line)
        m = re.match(r"^(?:static\s+)?func\s+(\w+)\s*\(.*\)\s*(?:->\s*[\w\[\]]+\s*)?:\s*$", line)
        if m:
            out.append("\t_ft_calls.append(\"%s\")" % m.group(1))
    return "\n".join(out)


def write_hosts(project, tax):
    """Each host of supplied stubs as a script in the scratch project."""
    by_host = {}
    for e in tax.order:
        if e.stub and isinstance(e.host, str):
            by_host.setdefault(e.host, []).append(e)
    files = {}
    for host, es in by_host.items():
        if host.endswith(".tscn"):
            # a supplied scene: its stub is the scene's text, written as it is, so that
            # preload("res://supplied/x.tscn") finds a PackedScene
            path = os.path.join(project, *host[len("res://"):].split("/"))
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w", encoding="utf-8", newline="\n") as f:
                f.write(es[0].stub.rstrip("\n") + "\n")
            files[host] = es
            continue
        if host.startswith("$"):
            rel = "hosts/%s.gd" % host[1:]
            head = ("extends Node\n## Written by check.py: the supplied parts on the base scene's "
                    "node %s.\n\nvar _ft_calls := []\n\n" % host[1:])
        else:
            rel = host[len("res://"):]
            head = ("extends RefCounted\n## Written by check.py: the supplied script %s.\n\n"
                    "static var _ft_calls := []\n\n" % host)
        path = os.path.join(project, *rel.split("/"))
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(head + "\n\n".join(record_calls(e.stub) for e in es) + "\n")
        files["res://" + rel] = es
    return files


def kill_tree(proc):
    try:
        if os.name == "nt":
            subprocess.run(["taskkill", "/T", "/F", "/PID", str(proc.pid)],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            proc.kill()
    except OSError:
        pass


def run_boot(exe, project, args, log, timeout):
    cmd = [exe, "--headless", "--xr-mode", "off", "--path", project] + args + ["--log-file", log]
    proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        proc.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        kill_tree(proc)
        return False
    return True


def run_godot(checker, chapters, exe, opts):
    tax, rep = checker.tax, checker.rep
    units = collect_units(chapters)
    if not units:
        rep.note(chapters[0].file if chapters else tax.path, 1, "code", "no gdscript blocks")
        return
    if not exe or not os.path.exists(exe):
        rep.error(chapters[0].file, 1, "code", "Godot not found at %r (--godot-exe)" % exe)
        return
    keep = opts.get("keep")
    project = os.path.abspath(opts.get("workdir") or tempfile.mkdtemp(prefix="ft_godot_"))
    os.makedirs(os.path.join(project, "blocks"), exist_ok=True)
    with open(os.path.join(project, "project.godot"), "w", encoding="utf-8") as f:
        f.write('config_version=5\n\n[application]\n\nconfig/name="functional_text_check"\n')
    with open(os.path.join(project, "runner.gd"), "w", encoding="utf-8") as f:
        f.write(RUNNER)
    host_files = write_hosts(project, tax)
    rows = []
    classnames = {}
    # the extends line in force before each block, in the order the book shows them
    before, cur = {}, None
    for ch in chapters:
        for s in ch.sections:
            for b in s.blocks:
                if b.lang not in ("gdscript", "gd"):
                    continue
                before[id(b)] = cur
                for x in b.lines:
                    if EXTENDS_LINE.match(x):
                        cur = x.strip()
    for u in units:
        build_unit(u, tax, before.get(id(u.blocks[0])))
        b0 = u.blocks[0]
        if u.no_extends:
            rep.error(u.sec.file, b0.fence_line, "code", "no extends line in this block or before "
                      "it: say what kind of node the script is for")
        for b, path in u.bad_nodes:
            rep.error(u.sec.file, b.fence_line - 1, "code", "nodes=: %s comes before its parent: "
                      "list the parent first" % path)
        if u.classname:
            if u.classname in classnames:
                rep.error(u.sec.file, b0.fence_line, "code", "class_name %s is declared again "
                          "(also in section %s); one unit per class" % (u.classname,
                                                                       classnames[u.classname].sec.id))
            classnames[u.classname] = u
        with open(os.path.join(project, "blocks", "%s.gd" % u.id), "w", encoding="utf-8",
                  newline="\n") as f:
            f.write(u.text)
        rows.append("%s|res://blocks/%s.gd|%d|%d|%d|%s" % (u.id, u.id, 0 if u.fails else u.frames,
                                                           len(u.claims), 1 if u.until else 0,
                                                           u.on))
    with open(os.path.join(project, "units.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(rows) + "\n")
    log = os.path.join(project, "log.txt")
    timeout = float(opts.get("timeout", 120))
    if classnames or host_files:
        run_boot(exe, project, ["--import"], os.path.join(project, "import_log.txt"), timeout)
    if os.path.exists(log):
        os.remove(log)
    finished = run_boot(exe, project, ["--script", "res://runner.gd"], log, timeout)
    try:
        with open(log, encoding="utf-8", errors="replace") as f:
            text = f.read()
    except OSError:
        text = ""
    if not finished:
        rep.error(chapters[0].file, 1, "code", "Godot did not finish within %ds; killed" % timeout)
    by_id = {u.id: u for u in units}
    parse_ok = dict(re.findall(r"^FT_PARSE (u\d+) (ok|fail)", text, re.M))
    # errors, attributed by the generated file they point into
    lines = text.split("\n")
    i = 0
    found = {}
    for_hosts = []
    while i < len(lines):
        L = lines[i]
        m = re.match(r"^(SCRIPT ERROR|ERROR|USER ERROR):\s*(.*)$", L)
        if not m or "Failed to load script" in L:
            i += 1
            continue
        msg = re.sub(r"^Parse Error:\s*", "", m.group(2)).strip()
        loc = None
        host_loc = None
        j = i + 1
        while j < len(lines) and not re.match(r"^(SCRIPT ERROR|ERROR|WARNING|USER ERROR|FT_)", lines[j]):
            mm = re.search(r"res://blocks/(u\d+)\.gd:(\d+)", lines[j])
            if mm and loc is None:
                loc = (mm.group(1), int(mm.group(2)))
            hm = re.search(r"(res://[\w/.-]+\.gd):(\d+)", lines[j])
            if hm and host_loc is None and hm.group(1) in host_files:
                host_loc = hm.group(1)
            j += 1
        i = j
        if loc is None or loc[0] not in by_id:
            if host_loc is not None:
                for_hosts.append((host_loc, msg))
            continue
        u = by_id[loc[0]]
        kind = "code" if "Parse Error" in m.group(2) or parse_ok.get(u.id) == "fail" else "run"
        found.setdefault(u.id, []).append((kind, msg, loc[1]))
    for host, msg in dict.fromkeys(for_hosts):
        e = host_files[host][0]
        rep.error(tax.path, e.line, "code", "Godot, in the supplied stubs at %s: %s" % (host, msg))
    claims_said = {(a, int(b)): c for a, b, c in re.findall(r"^FT_CLAIM (u\d+) (\d+) (yes|no)", text, re.M)}
    bases = {a: (b, c) for a, b, c in re.findall(r"^FT_BASE (u\d+) (\w+) (yes|no)", text, re.M)}
    for u in units:
        b0 = u.blocks[0]
        status = parse_ok.get(u.id)
        errs = found.get(u.id, [])
        # the top-node rule: the script must be one the node it goes on can hold
        base = bases.get(u.id)
        if base and base[1] == "no" and "top-node" not in OFF:
            where = ("the root node, a %s" % u.on) if u.on == TOP_NODE else ("a %s (on=)" % u.on)
            rep.error(u.sec.file, b0.fence_line, "top", "this script is for a %s, and the text puts "
                      "it on %s: Godot refuses it there. Extend %s, and make the body in code, a "
                      "child (FUNCTIONAL_TEXT 3)" % (base[0], where, u.on))
        if u.fails:
            if status == "ok":
                rep.error(u.sec.file, b0.fence_line, "code", "this block should fail to parse, "
                          "and it parses")
            continue
        if status is None and finished:
            rep.error(u.sec.file, b0.fence_line, "code", "Godot never reported this block")
        for kind, msg, gl in errs:
            src = u.map[gl - 1] if 0 < gl <= len(u.map) else None
            if src and isinstance(src[0], Block):
                where = (u.sec.file, src[0].fence_line + 1 + src[1])
            elif src and src[0] == "claim":
                where = (u.sec.file, src[1].fence_line - 1)
                # the tuple is whole before %: "%" binds tighter than "+"
                msg = "in %s %r: %s" % ((("claim", u.claims[src[2]][1]) if src[2] >= 0
                                         else ("until", u.until)) + (msg,))
                kind = "claim"
            elif src and src[0] in ("nodes", "extends"):
                where = (u.sec.file, src[1].fence_line - (1 if src[0] == "nodes" else 0))
                msg = "in the %s the checker builds: %s" % (
                    "scene" if src[0] == "nodes" else "extends line", msg)
            else:
                where = (u.sec.file, b0.fence_line)
                msg = "in the wrapper: %s" % msg
            rep.error(where[0], where[1], kind, "Godot: %s" % msg)
        if status == "fail" and not errs:
            rep.error(u.sec.file, b0.fence_line, "code", "Godot could not load this block")
        if not u.frames and (u.claims or u.prints) and status == "ok":
            rep.error(u.sec.file, b0.fence_line - 1, "claim", "a claim or prints= on a block that "
                      "does not run: it is never checked")
        if u.frames and status == "ok":
            mrun = re.search(r"^FT_RUN_BEGIN %s\n(.*?)^FT_RUN_END %s" % (u.id, u.id), text,
                             re.M | re.S)
            if not mrun:
                rep.error(u.sec.file, b0.fence_line, "run", "the run did not complete")
            else:
                out = [l.strip() for l in mrun.group(1).split("\n")]
                for b, want in u.prints:
                    if want.strip() not in out:
                        rep.error(u.sec.file, b.fence_line - 1, "run", "expected the run to print "
                                  "the line %r" % want)
                if u.until and not re.search(r"^FT_UNTIL %s yes" % u.id, text, re.M):
                    rep.error(u.sec.file, b0.fence_line - 1, "claim", "until %r never came true "
                              "within 30 seconds" % u.until)
                for k, (b, c) in enumerate(u.claims):
                    if claims_said.get((u.id, k)) != "yes":
                        rep.error(u.sec.file, b.fence_line - 1, "claim", "the claim %r does not hold "
                                  "after %d frames" % (c, u.frames))
    if keep:
        rep.note(chapters[0].file, 1, "code", "Godot project kept at %s" % project)
    elif not opts.get("workdir"):
        shutil.rmtree(project, ignore_errors=True)


# ---------------------------------------------------------------- the order report


def where_name(key, fact=None):
    if fact and fact.get("where") == "code_new":
        return "ch%d code_new" % key[0]
    if key is None:
        return "?"
    if key[1] == HEAD:
        return "ch%d code_new" % key[0]
    return sec_id(key)


def md_cell(text):
    return str(text).replace("|", "\\|").replace("\n", " ")


def write_report(rep, path, sketch_path, taxonomy_path):
    """The mechanical answer to 'is the order right': every element used before it is
    taught, never taught, taught twice; by chapter, with a count at the top."""
    checker, tax = rep.checker, rep.tax
    facts = checker.facts
    try:
        with open(sketch_path, encoding="utf-8") as f:
            sk = json.load(f)
    except (OSError, ValueError):
        sk = {}
    titles = {c.get("n"): c.get("title", "") for p in sk.get("parts", []) for c in p.get("chapters", [])}
    by_kind = {}
    for fa in facts:
        by_kind.setdefault(fa["kind"], []).append(fa)

    def elements(kind):
        return len({fa["entry"] for fa in by_kind.get(kind, [])})

    def uses(kind):
        return len(by_kind.get(kind, []))

    dep_facts = tax.dep_facts
    # an admin is no teaching: the sketch plans what is taught, and a missing admin (run the
    # scene) waits for the section that first needs it
    missing = [e for e in tax.order if e.missing and not e.is_admin]
    never_used = {fa["entry"] for fa in by_kind.get("never", [])}
    quiet_missing = [e for e in missing if e.id not in never_used]
    out = []
    w = out.append
    w("# Is the order right? The sketch, checked")
    w("")
    w("The mechanical answer, by `check.py`, from `sketch/sketch.json` and `taxonomy.json`.")
    w("Regenerate from `doc/book/course/`:")
    w("")
    w("```")
    w("python functional_text/check.py --taxonomy taxonomy.json --sketch sketch/sketch.json \\")
    w("    --report functional_text/sketch_report.md")
    w("```")
    w("")
    w("Sketch: %s, %s. Taxonomy: %d entries. Run: %d errors, %d warnings."
      % (sk.get("title", "?"), sk.get("date", "?"), len(tax.order), rep.errors(), rep.count("warning")))
    w("")
    w("## Counts")
    w("")
    w("| finding | elements | uses |")
    w("|---|---:|---:|")
    w("| used before it is taught | %d | %d |" % (elements("order"), uses("order")))
    w("| used, never taught (`introduced_at: missing`) | %d | %d |" % (elements("never"), uses("never")))
    w("| never taught, named only inside a supplied part or a code_new | %d | - |" % len(quiet_missing))
    w("| taught twice | %d | %d |" % (elements("twice"), uses("twice")))
    w("| explained by an element taught later (the taxonomy's depends_on) | %d | %d |"
      % (len({e.id for e, d in dep_facts}), len(dep_facts)))
    w("| the same word in another sense, declared (not an order break) | %d | %d |"
      % (elements("sense"), uses("sense")))
    w("| taught in a chapter's code_new, but no section names it | %d | - |" % elements("unplaced"))
    w("| taught in a section, missing from the chapter's code_new | %d | - |" % elements("listing"))
    w("")
    w("A use is one line of the sketch that names the element: a section title, idea or figure,")
    w("an example, an exercise, a project step, or a code_new item. A section `N.x` is chapter N's")
    w("examples, exercises and project step. `chN code_new` is chapter N's list of new code.")
    w("")
    # the largest gaps
    gaps = {}
    for fa in by_kind.get("order", []):
        e = tax.get(fa["entry"])
        if not e.avail or e.own_chapter is not None:
            continue        # an own name used outside its chapter is listed by chapter below
        g = e.avail[0] - fa["key"][0]
        cur = gaps.get(e.id)
        if cur is None or fa["key"] < cur[1]["key"]:
            gaps[e.id] = (g, fa)
    if gaps:
        w("## The largest gaps")
        w("")
        w("First use of each element against where it is taught, the widest first.")
        w("")
        w("| element | first used | taught at | chapters early |")
        w("|---|---|---|---:|")
        for eid, (g, fa) in sorted(gaps.items(), key=lambda kv: (-kv[1][0], kv[1][1]["key"])):
            e = tax.get(eid)
            w("| %s | %s | %s | %d |" % (md_cell(e.label()), where_name(fa["key"], fa), e.where(), g))
        w("")
    # by chapter
    chapters = sorted({fa["key"][0] for fa in facts if fa["kind"] in ("order", "never", "twice", "sense")}
                      | {e.avail[0] for e, d in dep_facts if e.avail})
    w("## By chapter")
    w("")
    for n in chapters:
        rows_o, rows_n, rows_t, rows_s = {}, {}, [], {}
        for fa in facts:
            if fa["key"][0] != n:
                continue
            k = fa["kind"]
            if k == "order":
                rows_o.setdefault(fa["entry"], []).append(fa)
            elif k == "never":
                rows_n.setdefault(fa["entry"], []).append(fa)
            elif k == "twice":
                rows_t.append(fa)
            elif k == "sense":
                rows_s.setdefault((fa["word"].lower(), fa["entry"]), []).append(fa)
        deps = [(e, d) for e, d in dep_facts if e.avail and e.avail[0] == n]
        if not (rows_o or rows_n or rows_t or rows_s or deps):
            continue
        w("### Chapter %d: %s" % (n, titles.get(n, "")))
        w("")
        if rows_o:
            w("**Used before it is taught**")
            w("")
            w("| element | used at | taught at |")
            w("|---|---|---|")
            for eid, lst in sorted(rows_o.items(), key=lambda kv: min(f["key"] for f in kv[1])):
                e = tax.get(eid)
                at = []
                for f in sorted(lst, key=lambda f: f["key"]):
                    nm = where_name(f["key"], f)
                    if nm not in at:
                        at.append(nm)
                w("| %s | %s | %s |" % (md_cell(e.label()), ", ".join(at), e.where()))
            w("")
        if rows_n:
            w("**Used, never taught**")
            w("")
            w("| element | used at | note |")
            w("|---|---|---|")
            for eid, lst in sorted(rows_n.items(), key=lambda kv: min(f["key"] for f in kv[1])):
                e = tax.get(eid)
                at = []
                for f in sorted(lst, key=lambda f: f["key"]):
                    nm = where_name(f["key"], f)
                    if nm not in at:
                        at.append(nm)
                w("| %s | %s | %s |" % (md_cell(e.label()), ", ".join(at), md_cell(e.raw.get("note", ""))))
            w("")
        if rows_t:
            w("**Taught twice**")
            w("")
            w("| element | first taught | taught again | the sketch says |")
            w("|---|---|---|---|")
            seen = set()
            for f in sorted(rows_t, key=lambda f: f["key"]):
                e = tax.get(f["entry"])
                key = (f["entry"], f["key"])
                if key in seen:
                    continue
                seen.add(key)
                item = f.get("item", "")
                if len(item) > 110:
                    item = item[:107] + "..."
                w("| %s | %s | %s | %s |" % (md_cell(e.label()), e.where(), where_name(f["key"], f),
                                             md_cell(item)))
            w("")
        if deps:
            w("**Explained by an element taught later** (the taxonomy's depends_on)")
            w("")
            w("| element | taught at | depends on | which is taught at |")
            w("|---|---|---|---|")
            for e, d in deps:
                w("| %s | %s | %s | %s |" % (md_cell(e.label()), e.where(), md_cell(d.label()), d.where()))
            w("")
        if rows_s:
            w("**The same word in another sense** (declared in the taxonomy; not an order break)")
            w("")
            w("| word | at | sense here | the type | taught at |")
            w("|---|---|---|---|---|")
            for (word, eid), lst in sorted(rows_s.items(), key=lambda kv: min(f["key"] for f in kv[1])):
                e = tax.get(eid)
                at = []
                for f in sorted(lst, key=lambda f: f["key"]):
                    nm = where_name(f["key"], f)
                    if nm not in at:
                        at.append(nm)
                w("| %s | %s | %s | %s | %s |" % (md_cell(word), ", ".join(at), md_cell(lst[0].get("sense", "")),
                                                  md_cell(e.label()), e.where()))
            w("")
    if quiet_missing:
        w("## Never taught, named only inside a supplied part or a code_new")
        w("")
        w("These are marked `missing` in the taxonomy, but no title, idea, figure, example or")
        w("exercise uses them, so they raise no error.")
        w("")
        w("| element | note |")
        w("|---|---|")
        for e in quiet_missing:
            w("| %s | %s |" % (md_cell(e.label()), md_cell(e.raw.get("note", ""))))
        w("")
    unplaced = [tax.get(eid) for eid in dict.fromkeys(fa["entry"] for fa in by_kind.get("unplaced", []))]
    if unplaced:
        w("## Taught in a chapter, no section named")
        w("")
        w("The chapter's code_new names these; no section's title, idea or figure does, so the")
        w("taxonomy places them at `N.0`, the chapter's start.")
        w("")
        w("| element | chapter | note |")
        w("|---|---|---|")
        for e in unplaced:
            w("| %s | %d | %s |" % (md_cell(e.label()), e.intro_key[0], md_cell(e.raw.get("note", ""))))
        w("")
    listing = [tax.get(eid) for eid in dict.fromkeys(fa["entry"] for fa in by_kind.get("listing", []))]
    if listing:
        w("## Taught in a section, missing from code_new")
        w("")
        w("Code a section teaches that the chapter's code_new list leaves out.")
        w("")
        w("| element | taught at | note |")
        w("|---|---|---|")
        for e in listing:
            w("| %s | %s | %s |" % (md_cell(e.label()), e.where(), md_cell(e.raw.get("note", ""))))
        w("")
    # other findings of the run
    counts = {}
    for sev, f, ln, rule, msg in rep.items:
        counts[(rule, sev)] = counts.get((rule, sev), 0) + 1
    w("## Every finding of the run, by rule")
    w("")
    w("| rule | errors | warnings | notes |")
    w("|---|---:|---:|---:|")
    for rule in sorted({r for r, s_ in counts}):
        w("| %s | %d | %d | %d |" % (rule, counts.get((rule, "error"), 0), counts.get((rule, "warning"), 0),
                                     counts.get((rule, "note"), 0)))
    w("")
    others = [i for i in rep.items if i[0] == "error" and i[3] not in ("order", "never")]
    if others:
        w("Errors outside the order lists:")
        w("")
        for sev, f, ln, rule, msg in others:
            w("- `%s:%d` %s: %s" % (os.path.basename(f), ln, rule, msg))
        w("")
    w("`unused` warnings say an element is taught and the sketch's own text never uses it")
    w("again; the chapters will. `gives` and `listing` warnings are about the sketch's lists,")
    w("not its order. Run the command with `--quiet-warnings` to see errors only.")
    w("")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out))


# ---------------------------------------------------------------- main


def parse_chapter_filter(s):
    out = set()
    for part in s.split(","):
        part = part.strip()
        if "-" in part:
            a, b = part.split("-", 1)
            out.update(range(int(a), int(b) + 1))
        elif part:
            out.add(int(part))
    return out


def check_files(taxonomy, files, godot=None, godot_opts=None, sketch=None, chapters=None):
    rep = Report()
    tax = Taxonomy(taxonomy, rep)
    if not tax.ok:
        return rep
    tax.validate()
    checker = Checker(tax, rep, sketch_mode=bool(sketch))
    rep.checker, rep.tax = checker, tax
    if sketch:
        checker.check_sketch(sketch, chapters)
        if godot is not None:
            rep.note(sketch, 1, "code", "pass g does not apply to the sketch")
        return rep
    chs = [parse_chapter(f, rep) for f in files]
    checker.check_chapters(chs, godot=godot, godot_opts=godot_opts)
    return rep


def main(argv=None):
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except AttributeError:
        pass
    ap = argparse.ArgumentParser(description="Check functional text against its taxonomy.")
    ap.add_argument("--taxonomy", required=True, help="the taxonomy JSON")
    ap.add_argument("--sketch", help="check a course sketch JSON instead of chapter files")
    ap.add_argument("--chapters", help="with --sketch: the chapters to check, like 1-3 or 1,4")
    ap.add_argument("--godot", action="store_true", help="run pass g: parse and run code in Godot")
    ap.add_argument("--godot-exe", default=os.environ.get("GODOT", DEFAULT_GODOT))
    ap.add_argument("--keep", action="store_true", help="keep the scratch Godot project")
    ap.add_argument("--workdir", help="put the scratch Godot project here")
    ap.add_argument("--timeout", type=float, default=120)
    ap.add_argument("--quiet-warnings", action="store_true", help="print errors only")
    ap.add_argument("--report", help="with --sketch: write the order report (Markdown) here")
    ap.add_argument("files", nargs="*", help="chapter files, in book order")
    a = ap.parse_args(argv)
    if not a.sketch and not a.files:
        ap.error("give chapter files, or --sketch")
    chapters = parse_chapter_filter(a.chapters) if a.chapters else None
    godot = a.godot_exe if a.godot else None
    rep = check_files(a.taxonomy, a.files, godot=godot,
                      godot_opts={"keep": a.keep, "workdir": a.workdir, "timeout": a.timeout},
                      sketch=a.sketch, chapters=chapters)
    for line in rep.lines():
        if a.quiet_warnings and (": warning: " in line or ": note: " in line):
            continue
        print(line)
    if a.report and getattr(rep, "checker", None) is not None:
        write_report(rep, a.report, a.sketch or "", a.taxonomy)
    e, w = rep.errors(), rep.count("warning")
    if a.sketch:
        tail = "pass g does not apply to the sketch"
    elif a.godot:
        tail = "pass g ran in Godot"
    else:
        tail = "pass g skipped (run with --godot)"
    print("%d error%s, %d warning%s; %s" % (e, "" if e == 1 else "s", w, "" if w == 1 else "s", tail))
    return min(e, 255)


if __name__ == "__main__":
    sys.exit(main())
