"use client";
// The hall editor that opens to the right of the /long-museum strip.
//
// 2026-08-26, Palle: "If I click on a map, it shows a bigger div to the right,
// where I can edit that map, move around and add artifacts and add and remove
// museum walls."
//
// It edits ONE hall's map_data.json through POST /api/maps/cell-edit, and it
// holds every change as a pending operation until Save is pressed. That is not
// caution for its own sake: 42 of the 244 halls are hand-authored, the route
// drops a single fixed-name map_data.json.bak that the SECOND save overwrites,
// and *.bak is gitignored (.gitignore:57) — so an autosaving editor would leave
// a hand-authored hall with no pre-edit copy anywhere, in git or on disk.
//
// The grid is loaded from /api/maps?name=X&raw=1 (~4 KB) and NEVER from the
// strip's own segment. The strip's Art is {x, z, token, rot}; the y-offset and
// the #config tail were dropped by tools/long_museum.py:parse_cell, and 361 of
// the 1,745 hall placements (20.7%) carry one. Rebuilding a cell from the strip
// silently turns `pickup_gate#pickups:6` into `pickup_gate` — the artifact still
// spawns, just with its defaults, and nothing in the chain complains. Every
// write here moves the RAW cell string.

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { resolveLinkedParts, moveLinkedPart, type LinkedPartDefinition, type LinkedPart } from "./linked-parts";
import {
  Art,
  FILL,
  WALL,
  VOID,
  bucket,
  gridArtifacts,
  gridDims,
  hasSlot,
  parseCell,
  parsePlacement,
  formatPlacement,
  type Placement,
} from "./vocab";
import {
  Grids,
  Preview,
  Stamp,
  StampMode,
  mapTileCell,
  previewStamp,
  trimBlocker,
  utilityName,
} from "./stamp";

export type HallPatch = { structure: string[][]; artifacts: Art[] };

type Raw = {
  structure: string[][];
  inter: string[][];
  // The utilities layer is READ but never written here. It is what makes a
  // stamp's hold list honest: 20 codes are live across the halls (t 212, s 185,
  // sub 48, el 38, h: 28, sp 24, an 19, wp 9, tc 9, 3t 6 and six more), and `wp`
  // is the ramp that makes a raised slot reachable — paving over it strands the
  // artifact above it with no gate anywhere noticing.
  util: string[][];
  wallH: number;
  /** map_info.museum.basin.rects, each [x, z, w, d] — 8 halls declare one */
  basin: number[][];
  /** map_info.museum.basin.cells, each [x, z] */
  basinCells: number[][];
  /** map_info.museum.basin exists but named no rects — the pool is the hall */
  basinWhole: boolean;
  /** map_info.museum.simulation — the whole tile is one live GridSystem */
  simulation: boolean;
  declared: { w: number; h: number } | null;
  /** map_info.dimensions.max_height — the grid CLAMPS a stack to it, so a
   *  level above it builds shorter than it reads. Trans_Rotation declares
   *  wall_height 4 against max_height 1. */
  maxH: number | null;
  /** the file's sha256 when this grid was read — the save's compare-and-swap */
  sha: string | null;
  /** newest first: {name, stamp, bytes, mtime_ms} — the route keeps ten */
  backups: { name: string; stamp: string; bytes: number; mtime_ms: number }[];
};

/** The raised floors this hall can express: every level strictly between
 *  plain floor and the hall's own wall_height. A default hall (wall_height 2)
 *  has none, and correctly shows no level buttons — there a 2 IS the wall and
 *  the `wall 2` brush already writes it. */
function levelsFor(wallH: number): number[] {
  const out: number[] = [];
  for (let v = 2; v < wallH; v++) out.push(v);
  return out;
}

type Tool =
  | "move" | "place" | "remove" | "uplace" | "uremove"
  | "wall" | "mwall" | "floor" | "stand" | "hole" | "lvl" | "plat";

type Edit = {
  layer: "structure" | "interactables" | "utilities";
  x: number;
  z: number;
  prev: string;
  next: string;
  note: string;
};

type Found = { lookup_name: string; name: string; registry: string; parts?: string[] };

type Props = {
  name: string;
  sequence: string;
  source: string;
  built?: boolean;
  z0: number;
  z1: number;
  /** the hall's own chapter vocabulary, counted off the strip — see the palette */
  seqTokens: { token: string; n: number }[];
  onClose: () => void;
  onSaved: (name: string, patch: HallPatch) => void;
  /** how many edits are unwritten — the page blocks a hall switch on it */
  onDirty: (n: number) => void;
  /** A STAMP OR A RESIZE MOVED THE HALL'S FOOTPRINT, so the strip patch is not
   * enough. The page refreshes one segment from its own 4 KB map file and never
   * refetches the 421 KB document, because no cell edit could change w/h/z1 —
   * long-museum/page.tsx:651 states that as the invariant. A resize breaks it:
   * every hall downstream of this one is drawn at the wrong z until the whole
   * strip is read again. */
  onResized: (name: string) => void;
};

const ROTS = [0, 90, 180, 270];

function fmt(n: number) {
  return n.toLocaleString("en-GB");
}

function cellKey(layer: string, x: number, z: number) {
  return layer + "|" + x + "|" + z;
}

// --- brushes ----------------------------------------------------------------
// "w" is an explicit wall: GridStructureComponent.gd:219 builds it as a 3-cube
// column, taller than any climb. A bare "2" is a MUSEUM wall too — the museum's
// own deriver emits tile "4" for any numeric >= map_info.museum.wall_height
// (default 2) — but in the grid game the same cell is a climbable 2-cube
// platform. 4,252 cells across 138 halls already sit in that gap, so both are
// offered as separate brushes rather than one guessed "wall".
function brushValue(tool: Tool, prev: string, wallH: number, lvl: number): string | null {
  if (tool === "wall") return "w";
  if (tool === "mwall") return String(wallH);
  // A RAISED FLOOR, NOT A WALL — and until 2026-09-06 there was no such
  // thing, which is why no brush wrote one. The museum now reads structure v
  // with 1 < v < wall_height as floor (v-1) m up and walks it by LEVEL, and
  // 382 cells across the 14 halls with wall_height > 2 already sit at one
  // (236 twos, 146 threes) with nothing on this page able to make another.
  // The suffix survives the stroke for the same reason floor keeps it: 1,098
  // cells are "2s" and 150 are "3s", so a raised deck DOES carry artifact
  // slots, and painting a bare level over one would silently drop the stand.
  if (tool === "lvl") return hasSlot(prev) ? String(lvl) + "s" : String(lvl);
  // Floor keeps the slot suffix. Painting "1" over "1s" removes an artifact
  // stand and changes no geometry at all, so nothing on this page or in any
  // render would show it — 1,289 cells are one careless stroke from that.
  // A PLATFORM, WHICH IS NEVER A WALL (2026-09-08, Palle: "can I paint p:2 or
  // p:1"). No brush wrote one, so the only `p` cells in 2,798 maps were four
  // typed by hand. endless_museum.gd calls it "the letter that ends the double
  // meaning of 2": a climbable block of N metres, floored on top,
  // artifact-bearing, and NOT converted to a wall by the hall's wall_height the
  // way a bare number is. Written as p:N even for 1 — `p` alone parses the same
  // (map_pathfinder.parse_height), but the explicit form says the height out
  // loud in the cell, which is the whole reason this brush exists.
  //
  // No slot suffix: `p:2s` is not in any parser's grammar. A stroke over a
  // stand therefore DOES drop the slot, which is why the hint says so.
  if (tool === "plat") return "p:" + String(Math.max(1, Math.round(lvl)));
  if (tool === "floor") return hasSlot(prev) ? "1s" : "1";
  if (tool === "stand") return "1s";
  // Never op:"clear" on structure. cell-edit writes a single space for clear,
  // which reads as VOID — a hole in the floor, not a removed wall.
  if (tool === "hole") return "0";
  return null;
}

// Artifacts whose whole content is a string. 3t is the museum-visible one:
// registered as BOTH a utility code and an artifact, so it is the one text
// mechanism that reaches a hall — _derive_map_row never reads layers.utilities,
// which is why an: (433 placements) and sub: (123) cannot.
const TEXT_TOKENS = new Set(["3t"]);

// The three head fields a person can actually set, and what each one costs.
// y_offset is the dangerous one: writing it AT ALL opts the cell out of the
// grid's auto-ground, so an empty field and a 0 are different instructions.
const INSPECTOR_FIELDS = [
  { k: "rot" as const, label: "rotation", step: 90, hint: "degrees; any number is legal" },
  {
    k: "yoff" as const,
    label: "y offset m",
    step: 0.1,
    hint: "writing this UN-GROUNDS the artifact: the grid stops seating it on the floor and pins it at exactly this height. Empty is not the same as 0.",
  },
  {
    k: "scale" as const,
    label: "scale",
    step: 0.1,
    hint: "the head's fourth field. NOT the same as a #scale: tail, which the grid consumes itself and clamps to 5.",
  },
];

// Counted off the 19,014 placements in the corpus rather than imagined: kind
// 2499, mount 2191, size 1941, text 784, layout 265, mode 185, scale 62,
// plinth 48, offset 40. An invented key is worse than none — a key outside
// CONFIG_PARAM_NAMES whose value parses as a number is read as tutorial
// shorthand, so the artifact receives `true` and the map silently gains a
// rotation.
const LIVE_CONFIG_KEYS = ["plinth", "offset", "scale", "mount", "kind", "size", "mode", "text"];

// THE UTILITY LAYER (2026-09-05, Palle: "can you give me access to edit the
// utility layer?"). It was read here and never written. The presets are the
// codes the grid's UtilityRegistry knows, with the facts that decide where each
// one goes — measured this week in the transformation halls, not guessed:
//  - a ride is a span: tc:N runs N-1 void cells and ends EMBEDDED in the far
//    bank, flush (Trans_Introduction's ferry template; N = void depth + 1)
//  - a wedge rises onto its neighbour: wp south (+z), 90 east, 180 north,
//    270 west, and its low half lies in the cell opposite, which must be free
//  - a plank (rc) stands at the CENTRE of a 3x3 void; a scale cube (sc) at the
//    LEFT column of its 3x3 (offset 1 puts the centre in the middle)
//  - a lift standing IN a void cell has its plate half a metre down
//  - the museum stamps only rc, sc, tc, br, jp and wp (UTIL_ALLOWED,
//    endless_museum.gd:660); sp, s, t, an, 3t, sub, h:, l, el are the grid's
// `museum` says which of the two engines will honour the cell.
const UTIL_PRESETS: { code: string; hint: string; museum: boolean }[] = [
  { code: "s", hint: "spawn point: where the grid stands the player. The museum ignores it.", museum: false },
  { code: "sp", hint: "the SCORE cube, not a spawn — shows the running pick-up score.", museum: false },
  { code: "t", hint: "teleporter to the next map. The museum refuses it: one endless map.", museum: false },
  { code: "an:-90", hint: "info board showing map_info.description, turned -90. Grid only.", museum: false },
  { code: "3t", hint: "a text display — type the words below. No colons: the cell splits on them. Grid only.", museum: false },
  { code: "sub:map", hint: "subtitle trigger; 'map' shows the description when entered. Grid only.", museum: false },
  { code: "wp", hint: "wedge rising SOUTH onto the cell below it; the cell above must be free floor (its low half lies there). Both engines.", museum: true },
  { code: "wp:90", hint: "wedge rising EAST onto the cell to its right; the cell to its left must be free floor.", museum: true },
  { code: "wp:180", hint: "wedge rising NORTH onto the cell above it; the cell below must be free floor.", museum: true },
  { code: "wp:270", hint: "wedge rising WEST onto the cell to its left; the cell to its right must be free floor.", museum: true },
  { code: "tc:4:z", hint: "transport cube along z: three void cells south, then embedded in the bank (distance = void depth + 1). Both engines.", museum: true },
  { code: "tc:4:x", hint: "transport cube along x, the same rule to the east. -x and -z run the other way.", museum: true },
  { code: "tc:1.5:y:auto", hint: "a lift standing IN a void cell: plate half a metre down, rises flush to a p:2 platform, cycles.", museum: true },
  { code: "tc:4:z#rot:90", hint: "carried and turned a quarter on the way — needs a 3-wide slot for the cube's corners.", museum: true },
  { code: "tc:4:z#scale:1.3", hint: "carried with the space growing a third at the far end, unwound on the return.", museum: true },
  { code: "rc:90:y:4:-0.6", hint: "a plank at the CENTRE of a 3x3 void, turning a quarter and pausing 4 s. Crossed when the corners meet the banks.", museum: true },
  { code: "rc:continuous:y:20:-0.6", hint: "a turntable at 20 degrees a second, crossable on foot; about x or z it rolls and is no way.", museum: true },
  { code: "sc:3:0.5:1:0", hint: "a scale cube at the LEFT column of its 3x3 void, growing to 3 m (offset 1 puts the centre in the middle).", museum: true },
  { code: "br:z:3", hint: "a bridge over three void cells starting at this one, along z.", museum: true },
  { code: "jp:4:8", hint: "jump pad to cell x,z — edit the numbers. Lands at y 0 (an open bug, forum 260905-w2ekt).", museum: true },
  { code: "h:fire", hint: "hazard: fire, 35 damage per 0.3 s. h:death kills outright. Grid only.", museum: false },
  { code: "l:3", hint: "platform lift of 3 cubes. Grid only.", museum: false },
];

export default function HallEditor(p: Props) {
  const [raw, setRaw] = useState<Raw | null>(null);
  const [loadErr, setLoadErr] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [edits, setEdits] = useState<Edit[]>([]);
  const [tool, setTool] = useState<Tool>("move");
  /** which raised floor the `level` brush writes — see levelsFor */
  const [lvl, setLvl] = useState(2);
  const [token, setToken] = useState<string>("");
  const [rot, setRot] = useState(0);
  /** the utility token the uplace tool writes — any string the grid's registry reads */
  const [utok, setUtok] = useState<string>("");
  // THE WORDS FOR A TEXT ARTIFACT. Without this the palette can place 3t and
  // the hall renders the scene's own baked default — "A point is entropy that
  // has cooled into memory." — because the panel could only ever write
  // `token` or `token:rot`, and in interactables the second colon field is the
  // ROTATION. That is the exact reason ForcesComposition's `3t:Superposition`
  // has never shown the word Superposition.
  const [words, setWords] = useState("");
  // THE INSPECTOR'S WORKING COPY. Palle, 2026-08-27: "when we click on an
  // artifact ... a window for setting detail inspector div like offset, scale,
  // plinth, etc that is in the string of the artifact placement." Held apart
  // from the cell so nothing is written until Apply — the placement string is
  // the artifact's whole configuration and a keystroke is not a decision.
  const [insp, setInsp] = useState<Placement | null>(null);
  const [query, setQuery] = useState("");
  const [found, setFound] = useState<Found[] | null>(null);
  const [partDefinitions, setPartDefinitions] = useState<LinkedPartDefinition[]>([]);
  const [partPick, setPartPick] = useState<string | null>(null);
  const [partPose, setPartPose] = useState({ x: "", z: "", yaw: "" });
  const [partsError, setPartsError] = useState<string | null>(null);
  const [pick, setPick] = useState<{ x: number; z: number } | null>(null);
  /** the utility being carried by the move tool — a cell that has no artifact
   *  picks its utility instead, so one gesture moves either layer */
  const [upick, setUpick] = useState<{ x: number; z: number } | null>(null);
  /** the picked utility's text, as edited in the utility inspector */
  const [utext, setUtext] = useState("");
  const [over, setOver] = useState<{ x: number; z: number } | null>(null);
  const [bump, setBump] = useState(0);
  const [fitPx, setFitPx] = useState(18);
  // APPLY AS YOU EDIT. Palle, 2026-08-26: "better if we apply change right
  // away". The panel was built to hold every change pending until Save, which
  // is the safe default for a tool pointed at hand-authored maps — but it is
  // not the tool Palle asked for. Auto is on, the toggle turns it off for
  // risky work, and the choice is remembered because re-arming it every time
  // a hall is opened is how a person ends up losing an afternoon.
  const [auto, setAuto] = useState(true);
  // WHAT IS ALREADY ON DISK, newest last. With auto on, "undo" cannot just
  // drop a pending edit — the change is written the moment it is made. So each
  // saved edit is kept with the value it replaced, and undo writes the inverse.
  // Without this the undo button silently stops working the instant auto is on,
  // which is worse than not having one.
  const [applied, setApplied] = useState<Edit[]>([]);
  // APPLY LIVE HAS TO BE ABLE TO STOP. A refused save keeps every pending edit
  // — correct, discarding a person's work to a 409 would be worse — but with
  // auto on that leaves ops non-empty, so the effect fires again, and again:
  // measured 34 POSTs in 22.7 seconds, 687 ms apart, no backoff and no cap.
  // And expect_sha256 only advances on SUCCESS, so the one error that actually
  // happens here — the other session writing the same map — can never
  // self-resolve. So a failure halts the automatic path until the person does
  // something: edits again, reloads the hall, or presses save themselves.
  const [autoHalted, setAutoHalted] = useState(false);
  // THE ONLY GATE THAT CAN SEE A SEALED EXIT. The route walks the hall before
  // and after every write and returns reachability {before, after, broke,
  // verdict}. The panel used to read four fields off that response and this was
  // not one of them, so painting the wall brush across a teleporter reported
  // "saved 3 cells" while the route had already computed
  // verdict "regressed". map_pathfinder cannot catch it either — it has one
  // error rule, and a hall turned into a solid block still passes.
  const [broke, setBroke] = useState<string[]>([]);
  const [saving, setSaving] = useState(false);
  const [note, setNote] = useState<string | null>(null);
  const [saveErr, setSaveErr] = useState<string | null>(null);
  // WHAT WAS PENDING WHEN THE SAVE WAS REFUSED. The halt lifts as soon as the
  // pending set is not that set any more, which is what makes "edit again"
  // a true instruction rather than a hopeful one.
  const haltedSig = useRef("");
  const painting = useRef(false);
  const lastPainted = useRef("");
  const boxRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    try {
      const v = window.localStorage.getItem("lm.autoApply");
      if (v === "0") setAuto(false);
    } catch {
      // a browser with storage blocked still gets an editor, just not a memory
    }
  }, []);

  // ------------------------------------------------------------------ load
  const load = useCallback(
    (keepEdits: boolean) => {
      let dead = false;
      setLoading(true);
      // Two requests: the grid, and the file's sha256. The sha is what the save
      // sends back as expect_sha256 — without it the route accepts the write
      // and warns "unguarded_write", which is the case where the other Claude
      // session's edit to the same hall is overwritten with no error anywhere.
      // It is optional on purpose: if that endpoint is not there, the save
      // still goes through, just unguarded.
      Promise.all([
        fetch("/api/maps?name=" + encodeURIComponent(p.name) + "&raw=1", { cache: "no-store" })
          .then((r) => r.json()),
        fetch("/api/maps/cell-edit?map=" + encodeURIComponent(p.name), { cache: "no-store" })
          .then((r) => r.json())
          .catch(() => ({}) as Record<string, unknown>),
      ])
        .then(([j, g]) => {
          if (dead) return;
          if (j.error) {
            setLoadErr(String(j.error));
            setRaw(null);
          } else {
            const st = (j?.layers?.structure ?? []) as string[][];
            const it = (j?.layers?.interactables ?? []) as string[][];
            const ut = (j?.layers?.utilities ?? []) as string[][];
            const mus = j?.map_info?.museum ?? {};
            const rects = mus?.basin?.rects;
            const bcells = mus?.basin?.cells;
            const dim = j?.map_info?.dimensions;
            setRaw({
              structure: Array.isArray(st) ? st : [],
              inter: Array.isArray(it) ? it : [],
              util: Array.isArray(ut) ? ut : [],
              // Trans_Pit declares 4 and walks on height-3 slabs over fire.
              // A hardcoded 2 would write walls into its floor.
              wallH: Number(j?.map_info?.museum?.wall_height ?? 2) || 2,
              basin: Array.isArray(rects) ? (rects as number[][]) : [],
              basinCells: Array.isArray(bcells) ? (bcells as number[][]) : [],
              basinWhole: !!mus?.basin && !Array.isArray(rects) && !Array.isArray(bcells),
              simulation: !!mus?.simulation,
              declared:
                dim && Number.isFinite(dim.width) && Number.isFinite(dim.depth)
                  ? { w: Number(dim.width), h: Number(dim.depth) }
                  : null,
              maxH: Number.isFinite(Number(dim?.max_height))
                ? Number(dim.max_height)
                : null,
              sha: typeof g?.sha256 === "string" ? g.sha256 : null,
              // THE WAY BACK. The route has written a timestamped backup before
              // every write since it was hardened, and nothing on screen ever
              // said so — a resize returns undo null and clears the cell
              // history, so before this the only recovery from a structural
              // write was a .bak file the panel never mentioned.
              backups: Array.isArray(g?.backups) ? g.backups : [],
            });
            setLoadErr(null);
            if (!keepEdits) {
              setEdits([]);
            } else {
              // Reloading after a refused save keeps the pending edits, but
              // their recorded prev values are from the file as it was BEFORE
              // the other writer touched it — and ops[] drops any edit whose
              // prev equals its next, so a stale prev can silently swallow the
              // very change being retried. Re-base the first edit per cell.
              setEdits((prev) => {
                const seen = new Set<string>();
                return prev.map((e) => {
                  const k = cellKey(e.layer, e.x, e.z);
                  if (seen.has(k)) return e;
                  seen.add(k);
                  const g = e.layer === "structure" ? st : e.layer === "utilities" ? ut : it;
                  const cur = g?.[e.z]?.[e.x];
                  return cur === undefined ? e : { ...e, prev: cur };
                });
              });
            }
          }
          setLoading(false);
        })
        .catch((e) => {
          if (dead) return;
          setLoadErr(String(e));
          setLoading(false);
        });
      return () => {
        dead = true;
      };
    },
    [p.name],
  );

  useEffect(() => {
    setEdits([]);
    setPick(null);
    setPartPick(null);
    setUpick(null);
    setNote(null);
    setSaveErr(null);
    return load(false);
  }, [load]);

  useEffect(() => {
    let dead = false;
    fetch("/api/map-studio/parts", { cache: "no-store" })
      .then(async r => {
        const data = await r.json();
        if (!r.ok || data.error) throw Error(data.error || "Linked instruments could not be loaded");
        if (!dead) { setPartDefinitions(data.definitions ?? []); setPartsError(null); }
      })
      .catch(error => { if (!dead) setPartsError(String(error)); });
    return () => { dead = true; };
  }, [p.name]);

  // A pending edit is the only copy of that change: it is not in the file, not
  // in git, and there is no draft store. So both ways out of this panel have to
  // be guarded — the tab closing, and the page swapping the panel because a
  // stray click landed on another hall in a 4.85 km strip.
  const onDirty = p.onDirty;
  useEffect(() => {
    onDirty(edits.length);
  }, [edits.length, onDirty]);
  useEffect(() => () => onDirty(0), [onDirty]);

  useEffect(() => {
    if (!edits.length) return;
    const h = (e: BeforeUnloadEvent) => {
      e.preventDefault();
      e.returnValue = "";
    };
    window.addEventListener("beforeunload", h);
    return () => window.removeEventListener("beforeunload", h);
  }, [edits.length]);

  // --------------------------------------------------------------- palette
  useEffect(() => {
    const q = query.trim();
    if (q.length < 2) {
      setFound(null);
      return;
    }
    let dead = false;
    // 250 ms: the registry search reads 222 registry files per call and warms
    // to ~20 ms, but the first one measured 1.12 s — a keystroke-per-request
    // palette stalls the panel on the first letter typed.
    const t = setTimeout(() => {
      fetch("/api/map-studio/artifacts?q=" + encodeURIComponent(q), { cache: "no-store" })
        .then((r) => r.json())
        .then((j) => !dead && setFound(Array.isArray(j.artifacts) ? j.artifacts : []))
        .catch(() => !dead && setFound([]));
    }, 250);
    return () => {
      dead = true;
      clearTimeout(t);
    };
  }, [query]);

  const localTokens = useMemo(() => {
    const q = query.trim().toLowerCase();
    const rows = q ? p.seqTokens.filter((t) => t.token.toLowerCase().includes(q)) : p.seqTokens;
    // This list already scrolls. A cutoff hid less frequent chapter artifacts,
    // including seed_replay_demo, slot_machine and trng_vs_prng in randomness.
    return rows;
  }, [p.seqTokens, query]);

  // ------------------------------------------------------------ working copy
  const work = useMemo(() => {
    if (!raw) return null;
    const st = raw.structure.map((r) => (r ?? []).slice());
    const it = raw.inter.map((r) => (r ?? []).slice());
    const ut = raw.util.map((r) => (r ?? []).slice());
    for (const e of edits) {
      const g = e.layer === "structure" ? st : e.layer === "utilities" ? ut : it;
      if (g[e.z] && e.x < g[e.z].length) g[e.z][e.x] = e.next;
    }
    return { st, it, ut };
  }, [raw, edits]);

  const dims = useMemo(() => {
    if (!work) return { sw: 0, sh: 0, iw: 0, ih: 0, cols: 0, rows: 0 };
    const s = gridDims(work.st);
    const i = gridDims(work.it);
    return {
      sw: s.w,
      sh: s.h,
      iw: i.w,
      ih: i.h,
      cols: Math.max(s.w, i.w),
      rows: Math.max(s.h, i.h),
    };
  }, [work]);

  const arts = useMemo(() => (work ? gridArtifacts(work.it) : []), [work]);
  const linkedParts = useMemo(() => work ? resolveLinkedParts(work.it, partDefinitions) : [], [work, partDefinitions]);
  const selectedPart = linkedParts.find(part => part.key === partPick);
  useEffect(() => {
    if (selectedPart) setPartPose({ x: String(Number(selectedPart.x?.toFixed(4))),
      z: String(Number(selectedPart.z?.toFixed(4))), yaw: String(selectedPart.yaw ?? 0) });
  }, [selectedPart]);
  const inspectPart = (part: LinkedPart) => {
    setPartPick(part.key); setPick(null); setUpick(null); setTool("move");
    setNote("Move " + part.label + ": drag its marker, click a floor cell, or edit its position below.");
  };
  const utilN = useMemo(
    () => (work ? work.ut.reduce((n, r) => n + (r ?? []).filter((c) => (c ?? "").trim() !== "").length, 0) : 0),
    [work],
  );

  // Which wall dialect this hall already speaks. 174 of the 244 halls mix "w"
  // and a bare digit; preselecting the minority one would quietly introduce a
  // third dialect into a hall that had two.
  const dialect = useMemo(() => {
    if (!raw) return { w: 0, num: 0 };
    let w = 0;
    let num = 0;
    for (const row of raw.structure) {
      for (const c of row ?? []) {
        const s = (c ?? "").trim();
        if (s === "w") w++;
        else {
          const n = parseInt(s, 10);
          if (!Number.isNaN(n) && n >= raw.wallH) num++;
        }
      }
    }
    return { w, num };
  }, [raw]);

  // ------------------------------------------------- stamps and resizing
  // These two are STRUCTURAL: a stamp rewrites up to 450 cells at once and a
  // resize moves the hall's footprint, which moves every hall downstream of it
  // in a 4,856 m strip. Neither goes through apply-live — that path fires 600 ms
  // after the last keystroke, and a mis-set slider would be on disk before the
  // number stopped moving. Both arm first and write on a second, separate press.
  // "" is closed. Only one of the two can be open, because each paints its own
  // ghost over the same grid and two ghosts at once would show a hall that is
  // neither the stamp's result nor the resize's.
  const [structTab, setStructTab] = useState<"" | "stamp" | "size">("");
  const [stamps, setStamps] = useState<Stamp[] | null>(null);
  const [stampsErr, setStampsErr] = useState<string | null>(null);
  const [stampKey, setStampKey] = useState<string>("");
  const [stampQ, setStampQ] = useState("");
  // 96% of the 5,175 (hall x stamp) pairs have the template DEEPER than the
  // hall, by a median of 15 rows, so this toggle is the common case and not an
  // edge case. Growing is the default: clipping throws away the back half of
  // the architecture, and it strands floor — soane-cabinet-vista clipped to
  // 13x19 leaves 6 of 142 walkable cells unreachable, where the same tile with
  // the hall grown to 13x28 walks 201 of 201.
  const [deep, setDeep] = useState<"grow" | "clip">("grow");
  // The route's own default. "walls" lays an architecture over a hall without
  // touching one floor cell, which is the only mode safe to reach for first on
  // a hall that already holds 27 artifacts.
  const [mode, setMode] = useState<StampMode>("walls");
  const [wantW, setWantW] = useState(0);
  const [wantH, setWantH] = useState(0);
  const [armed, setArmed] = useState<"stamp" | "resize" | null>(null);
  const [structBusy, setStructBusy] = useState(false);
  const [structErr, setStructErr] = useState<string | null>(null);

  useEffect(() => {
    fetch("/api/museum-stamps", { cache: "no-store" })
      .then((r) => r.json())
      .then((j) => {
        if (j?.error) {
          setStampsErr(String(j.error));
          setStamps([]);
          return;
        }
        setStamps(Array.isArray(j.stamps) ? (j.stamps as Stamp[]) : []);
      })
      .catch((e) => {
        setStampsErr(String(e));
        setStamps([]);
      });
  }, []);

  // THE FILE's shape, measured the way the route measures it: rows, and the
  // length of ROW ZERO. Not gridDims, which returns the longest row — on a
  // ragged hall that is a wider number than the route will accept, and a stamp
  // asking for a width greater than the hall's is refused as width_overflows_hall.
  const rawDims = useMemo(
    () => ({
      w: raw?.structure?.[0]?.length ?? 0,
      h: raw?.structure?.length ?? 0,
    }),
    [raw],
  );

  useEffect(() => {
    setWantW(rawDims.w);
    setWantH(rawDims.h);
    setArmed(null);
    setStructErr(null);
  }, [rawDims.w, rawDims.h]);

  const grids: Grids = useMemo(
    () => ({
      structure: raw?.structure ?? [],
      inter: raw?.inter ?? [],
      util: raw?.util ?? [],
      basin: raw?.basin ?? [],
      basinCells: raw?.basinCells ?? [],
    }),
    [raw],
  );

  const stamp = useMemo(
    () => (stamps ?? []).find((s) => s.key === stampKey) ?? null,
    [stamps, stampKey],
  );

  const stampList = useMemo(() => {
    const q = stampQ.trim().toLowerCase();
    const all = stamps ?? [];
    if (!q) return all;
    return all.filter(
      (s) =>
        s.label.toLowerCase().includes(q) ||
        s.museum.toLowerCase().includes(q) ||
        s.key.toLowerCase().includes(q),
    );
  }, [stamps, stampQ]);

  // The tile is always resampled to the hall's CURRENT width — the hall does not
  // move to meet a template, and the route refuses a width wider than the hall
  // outright. 175 of the 207 halls are already exactly 13, 15 or 17 wide, the
  // same band the 25 plans occupy, so the resample is usually one or two
  // columns. Changing the hall itself is the resize control's job; doing both in
  // one press would hide which of them broke the walk.
  const preview: Preview | null = useMemo(() => {
    if (!raw || !stamp || !rawDims.w) return null;
    return previewStamp(stamp, grids, rawDims.w, rawDims.h, mode, deep);
  }, [raw, stamp, mode, deep, rawDims.w, rawDims.h, grids]);

  const blockX = useMemo(
    () =>
      raw && wantW < rawDims.w ? trimBlocker("x", grids, rawDims.w, rawDims.h, wantW) : null,
    [raw, wantW, rawDims.w, rawDims.h, grids],
  );
  const blockZ = useMemo(
    () =>
      raw && wantH < rawDims.h ? trimBlocker("z", grids, rawDims.w, rawDims.h, wantH) : null,
    [raw, wantH, rawDims.w, rawDims.h, grids],
  );

  // ------------------------------------------------------------------ sizing
  useEffect(() => {
    const el = boxRef.current;
    if (!el || !dims.cols) return;
    const measure = () => {
      const w = el.clientWidth;
      // Hall widths run 7 to 34 (median 13). At 34 wide in a 420 px panel that
      // is 11 px per cell, which is too small to hit an artifact reliably — so
      // the fit is a floor, not a ceiling, and the zoom buttons go past it.
      setFitPx(Math.max(10, Math.min(30, Math.floor((w - 4) / dims.cols))));
    };
    measure();
    const ro = new ResizeObserver(measure);
    ro.observe(el);
    return () => ro.disconnect();
  }, [dims.cols]);

  const cellPx = Math.max(8, Math.min(44, fitPx + bump * 4));

  // ------------------------------------------------------------------- edits
  const push = useCallback((e: Edit) => {
    setSaveErr(null);
    setEdits((prev) => {
      // A no-op stroke is not an edit. Drag-painting a wall back over itself
      // otherwise files one pending op per cell entered and the count lies.
      if (e.prev === e.next) return prev;
      return prev.concat([e]);
    });
  }, []);

  const structAt = useCallback(
    (x: number, z: number): string | null => {
      if (!work) return null;
      const row = work.st[z];
      if (!row || x >= row.length) return null;
      return row[x] ?? "";
    },
    [work],
  );

  const interAt = useCallback(
    (x: number, z: number): string | null => {
      if (!work) return null;
      const row = work.it[z];
      if (!row || x >= row.length) return null;
      return row[x] ?? "";
    },
    [work],
  );

  const utilAt = useCallback(
    (x: number, z: number): string | null => {
      if (!work) return null;
      const row = work.ut[z];
      if (!row || x >= row.length) return null;
      return row[x] ?? "";
    },
    [work],
  );

  // THE INSPECTOR FOLLOWS THE PICK. Defined after interAt on purpose: an effect
  // that closes over it has to come later in the body, and `work` changes
  // whenever a pending edit lands, so the panel re-reads rather than holding a
  // copy that silently goes stale behind an unsaved change.
  useEffect(() => {
    if (!pick) {
      setInsp(null);
      return;
    }
    setInsp(parsePlacement(interAt(pick.x, pick.z) ?? ""));
  }, [pick, interAt]);

  /** Why this cell will not take a new artifact, or null when it will. */
  const refuseTarget = useCallback(
    (x: number, z: number): string | null => {
      const it = interAt(x, z);
      if (it === null) return "no interactables cell at (" + x + "," + z + ")";
      if (parseCell(it)) return "that cell already holds an artifact";
      const st = structAt(x, z);
      if (st === null) return "outside the floor grid — the hall has no structure row there";
      if (bucket(st, raw?.wallH ?? 2) === VOID) return "that cell is a hole, not floor";
      return null;
    },
    [interAt, structAt],
  );

  const placeAt = useCallback(
    (x: number, z: number) => {
      if (!token) {
        setNote("pick a token in the palette first");
        return;
      }
      const why = refuseTarget(x, z);
      if (why) {
        setNote(why);
        return;
      }
      let next = rot ? token + ":" + rot : token;
      // Underscores, not spaces: a cell is colon- and hash-delimited and a
      // compact-rows grid line is read by eye. word_is.gd turns them back,
      // matching the choice the utilities path already made.
      if (TEXT_TOKENS.has(token) && words.trim() !== "") {
        next += "#text:" + words.trim().replace(/\s+/g, "_");
      }
      push({
        layer: "interactables",
        x,
        z,
        prev: interAt(x, z) ?? "",
        next,
        note: "add " + next + " at (" + x + "," + z + ")",
      });
      setNote(null);
    },
    [token, rot, words, refuseTarget, interAt, push],
  );

  const removeAt = useCallback(
    (x: number, z: number) => {
      const it = interAt(x, z);
      const a = it === null ? null : parseCell(it);
      if (!a) {
        setNote("no artifact at (" + x + "," + z + ")");
        return;
      }
      // cell-edit's clear writes a single space; the grid reads that as empty.
      push({
        layer: "interactables",
        x,
        z,
        prev: it ?? "",
        next: " ",
        note: "remove " + a.token + " from (" + x + "," + z + ")",
      });
      setNote(null);
    },
    [interAt, push],
  );

  // A utility cell takes any token: a ride stands on floor or in a void cell
  // (a lift in a hole, a plank at the centre of a 3x3), so the floor test that
  // guards artifacts would refuse the cells rides are FOR. The only refusal is
  // a cell the utilities grid does not have.
  const placeUtilAt = useCallback(
    (x: number, z: number) => {
      const t = utok.trim();
      if (!t) {
        // Nothing to write: a click on a cell that HOLDS a utility opens it
        // for editing instead (Palle: "how can I edit the utility text").
        const here = utilAt(x, z);
        if (here !== null && here.trim()) {
          setUpick({ x, z });
          setNote(null);
          return;
        }
        setNote("type or pick a utility token first — or click a cell that holds one to edit its text");
        return;
      }
      const cur = utilAt(x, z);
      if (cur === null) {
        setNote("no utilities cell at (" + x + "," + z + ") — the utilities grid is smaller than the floor there");
        return;
      }
      let next = t;
      // 3t is the words: the cell is colon-delimited, so a colon in the text
      // would end the words early — a comma reads the same on the wall.
      if (/^3t(:|$)/.test(t) && words.trim() !== "") next = "3t:" + words.trim().replace(/:/g, ",");
      push({
        layer: "utilities",
        x,
        z,
        prev: cur,
        next,
        note: (cur.trim() ? "replace " + cur.trim() + " with " : "add ") + next + " at (" + x + "," + z + ")",
      });
      setNote(null);
    },
    [utok, words, utilAt, push],
  );

  // THE UTILITY INSPECTOR follows `upick` the way the artifact inspector
  // follows `pick`: the picked cell's text lands in a field, and apply writes
  // the field back as one ordinary edit. The raw string is what is edited —
  // the code before the first colon is what the grid reads, the fields after it
  // are that code's own grammar, a #tail is config — so nothing is reformatted.
  useEffect(() => {
    if (!upick) return;
    setUtext((utilAt(upick.x, upick.z) ?? "").trim());
  }, [upick, utilAt]);

  const applyUtext = useCallback(() => {
    if (!upick) return;
    const cur = utilAt(upick.x, upick.z);
    if (cur === null) return;
    const next = utext.trim();
    if (!next) {
      setNote("an empty text clears the cell — use clear for that");
      return;
    }
    if (next === cur.trim()) return;
    push({
      layer: "utilities",
      x: upick.x,
      z: upick.z,
      prev: cur,
      next,
      note: "edit " + cur.trim().split("#")[0].split(":")[0] + " at (" + upick.x + "," + upick.z + ") to " + next,
    });
    setNote(null);
  }, [upick, utext, utilAt, push]);

  const removeUtilAt = useCallback(
    (x: number, z: number) => {
      const cur = utilAt(x, z);
      if (cur === null || !cur.trim()) {
        setNote("no utility at (" + x + "," + z + ")");
        return;
      }
      // cell-edit's clear writes a single space; the grid reads that as empty.
      push({
        layer: "utilities",
        x,
        z,
        prev: cur,
        next: " ",
        note: "clear " + cur.trim() + " from (" + x + "," + z + ")",
      });
      setNote(null);
    },
    [utilAt, push],
  );

  // A utility moves the way an artifact does: the RAW string travels, so a
  // ride keeps its tail and a text its words. The target only has to exist in
  // the utilities grid and be empty — a lift stands in a hole, a plank in a
  // void, so no floor test.
  const moveUtilTo = useCallback(
    (from: { x: number; z: number }, x: number, z: number) => {
      if (from.x === x && from.z === z) return;
      const cell = utilAt(from.x, from.z);
      if (cell === null || !cell.trim()) return;
      const at = utilAt(x, z);
      if (at === null) {
        setNote("no utilities cell at (" + x + "," + z + ")");
        return;
      }
      if (at.trim()) {
        setNote("(" + x + "," + z + ") already holds " + at.trim() + " — clear it first, or drop elsewhere");
        return;
      }
      const code = cell.trim().split("#")[0].split(":")[0];
      setEdits((prev) =>
        prev.concat([
          {
            layer: "utilities",
            x: from.x,
            z: from.z,
            prev: cell,
            next: " ",
            note: "move " + code + " from (" + from.x + "," + from.z + ")",
          },
          {
            layer: "utilities",
            x,
            z,
            prev: at,
            next: cell,
            note: "move " + code + " to (" + x + "," + z + ")",
          },
        ]),
      );
      setSaveErr(null);
      setNote(null);
    },
    [utilAt],
  );

  const moveTo = useCallback(
    (from: { x: number; z: number }, x: number, z: number) => {
      if (from.x === x && from.z === z) return;
      const cell = interAt(from.x, from.z);
      if (cell === null) return;
      const why = refuseTarget(x, z);
      if (why) {
        setNote(why);
        return;
      }
      const a = parseCell(cell);
      // The RAW string moves, not token + ":" + rot. 261 hall cells carry a
      // y-offset and 100 a #config tail; rebuilding drops both silently.
      setEdits((prev) =>
        prev.concat([
          {
            layer: "interactables",
            x: from.x,
            z: from.z,
            prev: cell,
            next: " ",
            note: "move " + (a?.token ?? "?") + " from (" + from.x + "," + from.z + ")",
          },
          {
            layer: "interactables",
            x,
            z,
            prev: interAt(x, z) ?? "",
            next: cell,
            note: "move " + (a?.token ?? "?") + " to (" + x + "," + z + ")",
          },
        ]),
      );
      setSaveErr(null);
      setNote(null);
    },
    [interAt, refuseTarget],
  );

  const movePartTo = useCallback((x: number, z: number, yaw?: number) => {
    if (!work || !partPick) return;
    if (![x, z, yaw ?? 0].every(Number.isFinite)) { setNote("Enter valid position numbers."); return; }
    const st = structAt(Math.floor(x), Math.floor(z));
    if (x < 0 || z < 0 || st === null || [VOID, WALL].includes(bucket(st, raw?.wallH ?? 2))) {
      setNote("Place the instrument on floor inside this hall."); return;
    }
    try {
      const change = moveLinkedPart(work.it, partDefinitions, partPick, x, z, yaw);
      push({ layer: "interactables", ...change, note: "move " + (selectedPart?.label ?? "instrument") });
      setNote("Instrument position updated. Other instruments keep their positions.");
    } catch (error) { setNote(error instanceof Error ? error.message : String(error)); }
  }, [work, partPick, structAt, raw?.wallH, partDefinitions, push, selectedPart]);

  const paint = useCallback(
    (x: number, z: number) => {
      if (!raw) return;
      const k = cellKey("structure", x, z);
      if (lastPainted.current === k) return;
      lastPainted.current = k;
      const prev = structAt(x, z);
      if (prev === null) {
        setNote("(" + x + "," + z + ") is outside the structure grid");
        return;
      }
      const next = brushValue(tool, prev, raw.wallH, lvl);
      if (next === null) return;
      push({
        layer: "structure",
        x,
        z,
        prev,
        next,
        note: next + " at (" + x + "," + z + ")" + (hasSlot(prev) && !hasSlot(next) ? " — slot lost" : ""),
      });
    },
    [raw, tool, structAt, push],
  );

  // ------------------------------------------------------------- interaction
  const onDown = useCallback(
    (x: number, z: number) => {
      if (tool === "place") return placeAt(x, z);
      if (tool === "remove") return removeAt(x, z);
      if (tool === "uplace") return placeUtilAt(x, z);
      if (tool === "uremove") return removeUtilAt(x, z);
      if (tool === "move") {
        if (partPick) { movePartTo(x + 0.5, z + 0.5); setPartPick(null); return; }
        if (pick) {
          moveTo(pick, x, z);
          setPick(null);
          return;
        }
        if (upick) {
          moveUtilTo(upick, x, z);
          setUpick(null);
          return;
        }
        const it = interAt(x, z);
        if (it !== null && parseCell(it)) {
          setPick({ x, z });
          return;
        }
        // No artifact here: the utility is what there is to move. The same
        // press-drag or click-click as an artifact, carried as `upick` so the
        // inspector (which follows `pick`) does not open on an empty cell.
        const ut = utilAt(x, z);
        if (ut !== null && ut.trim()) setUpick({ x, z });
        else setNote("nothing to move at (" + x + "," + z + ")");
        return;
      }
      painting.current = true;
      lastPainted.current = "";
      paint(x, z);
    },
    [tool, partPick, movePartTo, pick, upick, placeAt, removeAt, placeUtilAt, removeUtilAt, moveTo, moveUtilTo, interAt, utilAt, paint],
  );

  const onEnter = useCallback(
    (x: number, z: number) => {
      setOver({ x, z });
      if (painting.current) paint(x, z);
    },
    [paint],
  );

  const onUp = useCallback(
    (x: number, z: number) => {
      painting.current = false;
      lastPainted.current = "";
      if (tool === "move" && partPick) { movePartTo(x + 0.5, z + 0.5); setPartPick(null); return; }
      // A real drag: pressed on the artifact, released on another cell. A press
      // and release on the SAME cell keeps the pick, so click-then-click works
      // for anyone whose pointer does not track a 12 px cell.
      if (tool === "move" && pick && !(pick.x === x && pick.z === z)) {
        moveTo(pick, x, z);
        setPick(null);
      }
      if (tool === "move" && upick && !(upick.x === x && upick.z === z)) {
        moveUtilTo(upick, x, z);
        setUpick(null);
      }
    },
    [tool, partPick, movePartTo, pick, upick, moveTo, moveUtilTo],
  );

  // ------------------------------------------------------------------- save
  const ops = useMemo(() => {
    if (!raw) return [] as { op: "set" | "clear"; layer: string; cell: number[]; token?: string }[];
    // Coalesce by cell: moving an artifact three times is one write, and a
    // stroke that ends where the file already was is no write at all.
    const final = new Map<string, Edit>();
    for (const e of edits) {
      const k = cellKey(e.layer, e.x, e.z);
      const first = final.get(k);
      final.set(k, first ? { ...e, prev: first.prev } : e);
    }
    const out: { op: "set" | "clear"; layer: string; cell: number[]; token?: string }[] = [];
    for (const e of final.values()) {
      if (e.prev === e.next) continue;
      const blank = (e.layer === "interactables" || e.layer === "utilities") && !e.next.trim();
      if (blank) out.push({ op: "clear", layer: e.layer, cell: [e.x, 0, e.z] });
      else out.push({ op: "set", layer: e.layer, cell: [e.x, 0, e.z], token: e.next });
    }
    // Clears first, so a hall whose every cell is contested still reads as
    // "empty this one, fill that one" in the route's applied[] log.
    return out.sort((a, b) => (a.op === b.op ? 0 : a.op === "clear" ? -1 : 1));
  }, [raw, edits]);

  const slotsLost = useMemo(
    () => edits.filter((e) => e.layer === "structure" && hasSlot(e.prev) && !hasSlot(e.next)).length,
    [edits],
  );

  const save = useCallback(async () => {
    if (!ops.length) return;
    setSaving(true);
    setSaveErr(null);
    setNote(null);
    try {
      const r = await fetch("/api/maps/cell-edit", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          map: p.name,
          operations: ops,
          // THE STRIP IS THE THING BEING LOOKED AT. Without this every save
          // left commons/data/long_museum.json behind the maps and the hall
          // kept drawing its old walls until somebody ran the python by hand —
          // which is exactly the "can we apply them" that prompted this. It is
          // opt-in in the route because --apply rebuilds from EVERY map on
          // disk, including whatever the other session has half-finished; that
          // is a derived, regenerable document, so the trade is worth it here.
          rebuild_strip: true,
          ...(raw?.sha ? { expect_sha256: raw.sha } : {}),
        }),
      });
      const j = await r.json().catch(() => ({}) as Record<string, unknown>);
      if (!r.ok || j.error) {
        // The save route is being hardened in the same repo and may grow a
        // precondition this panel does not send yet. Keep every pending edit
        // and say what the route said, verbatim — discarding here would lose
        // work to a 409.
        setSaveErr(
          "save refused (" + r.status + "): " + String(j.error ?? "no error text") +
            " — nothing was written, your " + ops.length + " pending edits are still here" +
            (auto ? ". apply live is paused; edit again or reload the hall to resume" : ""),
        );
        setAutoHalted(true);
        haltedSig.current = JSON.stringify(ops);
        setSaving(false);
        return;
      }
      // The route hands back prev_value per op. If it disagrees with what the
      // panel believed, another writer touched that cell between the load and
      // the save — the other Claude session edits maps in this tree.
      let drift = 0;
      const applied = Array.isArray(j.applied) ? j.applied : [];
      for (const a of applied) {
        const k = cellKey(String(a.layer), Number(a.cell?.[0]), Number(a.cell?.[2]));
        const mine = edits.filter((e) => cellKey(e.layer, e.x, e.z) === k)[0];
        if (mine && String(a.prev_value ?? "").trim() !== mine.prev.trim()) drift++;
      }
      const [m, g] = await Promise.all([
        fetch("/api/maps?name=" + encodeURIComponent(p.name) + "&raw=1", { cache: "no-store" })
          .then((x) => x.json()),
        fetch("/api/maps/cell-edit?map=" + encodeURIComponent(p.name), { cache: "no-store" })
          .then((x) => x.json())
          .catch(() => ({}) as Record<string, unknown>),
      ]);
      const st = (m?.layers?.structure ?? []) as string[][];
      const it = (m?.layers?.interactables ?? []) as string[][];
      const ut = (m?.layers?.utilities ?? []) as string[][];
      // The sha has to move on with the file, or the next save in the same
      // sitting sends the pre-save one and is refused as a stale write.
      setRaw((prev) =>
        prev
          ? {
              ...prev,
              structure: st,
              inter: it,
              util: Array.isArray(ut) ? ut : prev.util,
              sha: typeof g?.sha256 === "string" ? g.sha256 : null,
            }
          : prev,
      );
      const reach = (j.reachability ?? {}) as { verdict?: string; broke?: unknown };
      const brokeList = Array.isArray(reach.broke) ? reach.broke.map((b) => String(b)) : [];
      setBroke(brokeList);
      setApplied((prev) => [...prev, ...edits].slice(-60));
      setEdits([]);
      setPick(null);
      setAutoHalted(false);
      haltedSig.current = "";
      p.onSaved(p.name, { structure: st, artifacts: gridArtifacts(it) });
      const warned = Array.isArray(j.warnings)
        ? j.warnings.map((w: { message?: string }) => String(w?.message ?? "")).filter(Boolean)
        : [];
      setNote(
        "saved " + ops.length + " cell" + (ops.length === 1 ? "" : "s") +
          (drift ? " — " + drift + " had been changed by another writer since this hall was loaded" : "") +
          ". strip rebuilt" +
          (warned.length ? "  ·  " + warned.join("  ·  ") : ""),
      );
    } catch (e) {
      setSaveErr("save failed: " + String(e) + " — nothing was written");
    }
    setSaving(false);
  }, [ops, edits, p]);

  // AUTO-APPLY, DEBOUNCED. A drag across nine cells is nine edits; firing a
  // write per cell would be nine file writes, nine backups and nine strip
  // rebuilds for one gesture. 600 ms of quiet is long enough that a stroke
  // lands as one save and short enough that it still reads as "right away".
  useEffect(() => {
    if (autoHalted && JSON.stringify(ops) !== haltedSig.current) {
      setAutoHalted(false);
      return;
    }
    if (!auto || autoHalted || !ops.length || saving || loading) return;
    const t = setTimeout(() => {
      void save();
    }, 600);
    return () => clearTimeout(t);
  }, [auto, autoHalted, ops, saving, loading, save]);

  // UNDO ACROSS THE WRITE. With auto on there is usually nothing pending to
  // drop, so undo has to reach a change that is already in the file: it sends
  // the inverse — set the cell back to the value this edit replaced — as an
  // ordinary edit, which means it is itself saved, backed up and rebuilt like
  // any other. An undo that only worked before the save would be a button that
  // stops working exactly when it is needed.
  const undoLast = useCallback(() => {
    if (edits.length) {
      setEdits((prev) => prev.slice(0, -1));
      setPick(null);
      return;
    }
    const last = applied[applied.length - 1];
    if (!last || saving) return;
    setApplied((prev) => prev.slice(0, -1));
    setEdits([{
      layer: last.layer,
      x: last.x,
      z: last.z,
      prev: last.next,
      next: last.prev,
      note: "undo " + last.note,
    }]);
    setPick(null);
  }, [edits, applied, saving]);

  // ------------------------------------------------- the structural writes
  // Neither of these can be expressed as operations[]: cell-edit's applyOp
  // indexes into the existing arrays and returns out_of_bounds on any
  // out-of-range x/z, so it can neither append a row nor a column. They are
  // separate actions on the same route, and the field names below are its
  // Body interface verbatim — resize takes w/h, stamp takes template/mode/
  // width/depth, and `depth` there is the POLICY, not a number.
  //
  // `width` is deliberately not sent: the route defaults it to the hall's own
  // structure width, which is the same number this panel previews against and
  // one less thing that can disagree.
  // RESTORE. The route has written a timestamped backup before every write
  // since it was hardened and keeps the newest ten, and it backs the CURRENT
  // file up before restoring — so this is itself undoable. Nothing on screen
  // said any of that: a resize returns undo null and clears the cell history,
  // so this was the only recovery path and it was invisible.
  const [restoring, setRestoring] = useState(false);
  const restoreLast = useCallback(
    async (name?: string) => {
      const list = raw?.backups ?? [];
      if (!list.length || restoring) return;
      const pick = name || list[0].name;
      setRestoring(true);
      setStructErr(null);
      try {
        const r = await fetch("/api/maps/cell-edit", {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({
            map: p.name, action: "restore", backup_name: pick, rebuild_strip: true,
          }),
        });
        const j = await r.json().catch(() => ({}) as Record<string, unknown>);
        if (!r.ok || j.error) {
          setStructErr("restore refused (" + r.status + "): " + String(j.error ?? "no error text"));
        } else {
          setEdits([]);
          setApplied([]);
          setArmed(null);
          setStructTab("");
          setNote("restored " + pick.replace(/^map_data\.json\./, "").replace(/\.bak$/, ""));
          load(false);
          // onResized, not onSaved: a restore can undo a RESIZE, so the hall's
          // footprint may have changed and the strip has to re-measure rather
          // than patch cells into the geometry it already drew.
          p.onResized(p.name);
        }
      } catch (e) {
        setStructErr("restore failed: " + String(e));
      }
      setRestoring(false);
    },
    [raw, restoring, p, load],
  );

  const submitStruct = useCallback(
    async (kind: "stamp" | "resize") => {
      if (!raw) return;
      setStructBusy(true);
      setStructErr(null);
      setNote(null);
      const guard = raw.sha ? { expect_sha256: raw.sha } : {};
      const body =
        kind === "stamp"
          ? {
              map: p.name,
              action: "stamp",
              template: stampKey,
              mode,
              depth: deep,
              rebuild_strip: true,
              ...guard,
            }
          : {
              map: p.name,
              action: "resize",
              w: wantW,
              h: wantH,
              // "auto" walls only the border the resize disturbed and leaves
              // the untouched sides as the author left them. A trim reads a
              // wall column as free, so without this a contract opens the hall.
              rewall: "auto",
              rebuild_strip: true,
              ...guard,
            };
      try {
        const r = await fetch("/api/maps/cell-edit", {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify(body),
        });
        const j = (await r.json().catch(() => ({}))) as Record<string, unknown>;
        if (!r.ok || j.error) {
          // The route is growing these two actions in the same repo and may not
          // have them yet. Say what it said, verbatim, and name the action —
          // "invalid JSON body" on its own reads like a bug in this panel.
          setStructErr(
            kind + " refused (" + r.status + "): " + String(j.error ?? "no error text") +
              " — nothing was written. The panel POSTs {action:\"" + kind +
              "\"} to /api/maps/cell-edit; if that action is not implemented yet, this is what " +
              "it looks like from here.",
          );
          setStructBusy(false);
          setArmed(null);
          return;
        }
        const [m, g] = await Promise.all([
          fetch("/api/maps?name=" + encodeURIComponent(p.name) + "&raw=1", { cache: "no-store" })
            .then((x) => x.json()),
          fetch("/api/maps/cell-edit?map=" + encodeURIComponent(p.name), { cache: "no-store" })
            .then((x) => x.json())
            .catch(() => ({}) as Record<string, unknown>),
        ]);
        const st = (m?.layers?.structure ?? []) as string[][];
        const it = (m?.layers?.interactables ?? []) as string[][];
        const ut = (m?.layers?.utilities ?? []) as string[][];
        const rects = m?.map_info?.museum?.basin?.rects;
        const bcells = m?.map_info?.museum?.basin?.cells;
        setRaw((prev) =>
          prev
            ? {
                ...prev,
                structure: Array.isArray(st) ? st : [],
                inter: Array.isArray(it) ? it : [],
                util: Array.isArray(ut) ? ut : [],
                basin: Array.isArray(rects) ? (rects as number[][]) : [],
                basinCells: Array.isArray(bcells) ? (bcells as number[][]) : [],
                sha: typeof g?.sha256 === "string" ? g.sha256 : null,
              }
            : prev,
        );
        // THE UNDO HISTORY IS NOW A LIE. Each entry is "cell (x,z) used to hold
        // this", and after a stamp or a resize that cell may hold something
        // else or not exist. Undo would write a value from the old hall into
        // the new one, one cell at a time, with no warning.
        setApplied([]);
        setEdits([]);
        setPick(null);
        const reach = (j.reachability ?? {}) as { broke?: unknown };
        setBroke(Array.isArray(reach.broke) ? reach.broke.map((b) => String(b)) : []);
        p.onSaved(p.name, { structure: st, artifacts: gridArtifacts(it) });
        p.onResized(p.name);
        setArmed(null);
        const warned = Array.isArray(j.warnings)
          ? (j.warnings as { message?: string }[]).map((w) => String(w?.message ?? "")).filter(Boolean)
          : [];
        const d2 = gridDims(Array.isArray(st) ? st : []);
        setNote(
          (kind === "stamp" ? "stamped " + (stamp?.label ?? stampKey) : "resized") +
            " — the hall is now " + d2.w + "x" + d2.h +
            ". strip rebuilt and reread" +
            (warned.length ? "  ·  " + warned.join("  ·  ") : ""),
        );
      } catch (e) {
        setStructErr(kind + " failed: " + String(e) + " — nothing was written");
        setArmed(null);
      }
      setStructBusy(false);
    },
    [raw, p, stampKey, stamp, mode, deep, wantW, wantH],
  );

  // -------------------------------------------------------------- rendering
  const ragged = raw ? dims.sw !== dims.iw || dims.sh !== dims.ih : false;
  const strays = arts.filter((a) => a.x >= dims.sw || a.z >= dims.sh || bucket(structAt(a.x, a.z) ?? "", raw?.wallH ?? 2) === VOID);

  // The grid draws PAST the hall while a ghost is up. Both of these features
  // add rows the hall does not have yet — the median overflow of a template
  // over a hall is 15 rows — and a far-edge rule that cannot be seen is a
  // sentence someone will read as "it grows around the middle".
  const drawCols = Math.max(
    dims.cols,
    structTab === "stamp" && preview ? preview.w : 0,
    structTab === "size" ? wantW : 0,
  );
  const drawRows = Math.max(
    dims.rows,
    structTab === "stamp" && preview ? preview.h : 0,
    structTab === "size" ? wantH : 0,
  );

  const toolRow: { id: Tool; label: string; hint: string; lvl?: number }[] = [
    { id: "move", label: "move", hint: "drag an artifact — or, on a cell with none, its utility — from cell to cell" },
    { id: "place", label: "add", hint: "place the palette token" },
    { id: "remove", label: "remove", hint: "clear the artifact from a cell" },
    { id: "uplace", label: "util +", hint: "write the utility token from the Utilities section into a cell (a ride, a wedge, a spawn, a text); with the field empty, click a cell that holds one to edit its text" },
    { id: "uremove", label: "util −", hint: "clear the utility from a cell" },
    { id: "wall", label: "wall w", hint: "explicit wall, 3-cube column — " + fmt(dialect.w) + " in this hall" },
    {
      id: "mwall",
      label: "wall " + (raw?.wallH ?? 2),
      hint:
        "museum wall at this hall's wall_height — " + fmt(dialect.num) +
        " in this hall; climbable in the grid game",
    },
    ...levelsFor(raw?.wallH ?? 2).map((v) => ({
      id: "lvl" as Tool,
      lvl: v,
      label: "level " + v,
      hint:
        "raised floor, " + (v - 1) + " m up — walked as its own level, not climbed over" +
        (raw?.maxH != null && raw.maxH < v
          ? ". THIS HALL CLAMPS IT: dimensions.max_height is " + raw.maxH +
            ", and the grid builds no stack taller than that, so this cell will read " +
            "as level " + v + " here and stand at " + raw.maxH + " in the game"
          : ""),
    })),
    ...[1, 2, 3].map((v) => ({
      id: "plat" as Tool,
      lvl: v,
      label: "platform p:" + v,
      hint:
        "a climbable block " + v + " m tall — floored on top, and NEVER turned into a wall by " +
        "this hall's wall_height the way a bare " + v + " is" +
        (v === 1 ? "" : ". Get up on it with a wedge (util + · wp), or leave it as an obstacle") +
        ". Drops an artifact-slot suffix: there is no p:" + v + "s",
    })),
    { id: "floor", label: "floor 1", hint: "floor, keeping any artifact-slot suffix" },
    { id: "stand", label: "stand 1s", hint: "floor that also carries an artifact slot" },
    { id: "hole", label: "hole 0", hint: "no floor at all" },
  ];

  return (
    <div className="flex h-full flex-col">
      <style>{`
        .lm-ed-cell { position: relative; box-sizing: border-box; }
        .lm-ed-nofloor {
          background-image: repeating-linear-gradient(
            45deg, var(--lm-edge) 0px, var(--lm-edge) 1px, transparent 1px, transparent 5px);
        }
        .lm-ed-grid { touch-action: none; user-select: none; }
        .lm-ed-drop::after {
          content: ""; position: absolute; inset: 0;
          background-image: repeating-linear-gradient(
            -45deg, rgba(220,38,38,0.85) 0px, rgba(220,38,38,0.85) 1px, transparent 1px, transparent 4px);
        }
        .lm-ed-hold::after {
          content: ""; position: absolute; left: 50%; top: 50%;
          width: 3px; height: 3px; margin: -1.5px 0 0 -1.5px;
          border-radius: 999px; background: var(--lm-off);
        }
      `}</style>

      {/* ------------------------------------------------------------ head */}
      <div className="flex items-start justify-between gap-2 border-b border-zinc-200 px-3 py-2 dark:border-zinc-800">
        <div className="min-w-0">
          <div className="truncate font-mono text-[12px] font-semibold text-sky-800 dark:text-sky-200">
            {p.name}
          </div>
          <div className="truncate text-[10px] text-zinc-500 dark:text-zinc-400">
            {p.sequence} · {dims.sw}×{dims.sh} m · z {fmt(p.z0)}–{fmt(p.z1)} · {p.source}
            {p.built === false ? " · no engine hall" : ""}
          </div>
        </div>
        <div className="flex shrink-0 items-center gap-1.5">
          {edits.length > 0 && (
            <span className="rounded-[3px] bg-amber-500/20 px-1.5 py-0.5 text-[10px] font-semibold text-amber-800 dark:text-amber-300">
              {edits.length} unsaved
            </span>
          )}
          <button
            onClick={p.onClose}
            className="rounded border border-zinc-300 px-1.5 text-[10px] leading-5 text-zinc-500 hover:bg-zinc-100 dark:border-zinc-700 dark:hover:bg-zinc-800"
          >
            close
          </button>
        </div>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto px-3 pt-2 pb-6">
        {/* --------------------------------------------------- what is wrong */}
        {p.source === "ribbon" && (
          <div className="mb-2 rounded border border-amber-300 bg-amber-50 px-2 py-1.5 text-[10px] leading-snug text-amber-900 dark:border-amber-900/60 dark:bg-amber-950/40 dark:text-amber-200">
            This hall is machine-written. tools/ribbon.py opens it with mode &quot;w&quot; and no
            existence check, and rmtree()s any Ribbon_&lt;seq&gt;_* directory the next shorter run
            does not need — 202 of the 244 halls are in that set. Edits here survive until someone
            re-runs it.
          </div>
        )}
        {ragged && (
          <div className="mb-2 rounded border border-amber-300 bg-amber-50 px-2 py-1.5 text-[10px] leading-snug text-amber-900 dark:border-amber-900/60 dark:bg-amber-950/40 dark:text-amber-200">
            The layers disagree in size: structure {dims.sw}×{dims.sh}, interactables {dims.iw}×
            {dims.ih}. A bounds check against one is not a check against the other, which is how
            artifacts end up standing where the hall has no floor.
          </div>
        )}
        {strays.length > 0 && (
          <div className="mb-2 rounded border border-amber-300 bg-amber-50 px-2 py-1.5 text-[10px] leading-snug text-amber-900 dark:border-amber-900/60 dark:bg-amber-950/40 dark:text-amber-200">
            {strays.length} artifact{strays.length === 1 ? "" : "s"} on no floor:{" "}
            <span className="font-mono">
              {strays.map((a) => a.token + " (" + a.x + "," + a.z + ")").join(", ")}
            </span>
            . Drag them onto floor to repair; the editor will not create new ones.
          </div>
        )}

        {loadErr && (
          <div className="rounded border border-red-300 bg-red-50 px-2 py-1.5 text-[11px] text-red-800 dark:border-red-900/60 dark:bg-red-950/40 dark:text-red-200">
            {loadErr}
          </div>
        )}
        {loading && !raw && (
          <div className="py-6 text-[11px] text-zinc-500 dark:text-zinc-400">reading the hall…</div>
        )}

        {work && (
          <>
            {/* ------------------------------------------------------ tools */}
            <div className="flex flex-wrap gap-1">
              {toolRow.map((t) => (
                <button
                  key={t.id + (t.lvl ?? "")}
                  title={t.hint}
                  onClick={() => {
                    setTool(t.id);
                    if (t.lvl !== undefined) setLvl(t.lvl);
                    setPick(null);
                    setPartPick(null);
                    setUpick(null);
                    setNote(null);
                  }}
                  className={
                    "rounded border px-1.5 py-0.5 text-[10px] leading-4 " +
                    (tool === t.id && (t.lvl === undefined || lvl === t.lvl)
                      ? "border-sky-500 bg-sky-100 font-semibold text-sky-800 dark:border-sky-600 dark:bg-sky-950/70 dark:text-sky-200"
                      : "border-zinc-300 text-zinc-600 hover:bg-zinc-100 dark:border-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-800")
                  }
                >
                  {t.label}
                </button>
              ))}
              <span className="ml-auto flex items-center gap-1 text-[10px] text-zinc-400 dark:text-zinc-500">
                <span className="tabular-nums">{cellPx}px</span>
                <button
                  onClick={() => setBump((b) => b - 1)}
                  className="rounded border border-zinc-300 px-1 leading-4 hover:bg-zinc-100 dark:border-zinc-700 dark:hover:bg-zinc-800"
                >
                  −
                </button>
                <button
                  onClick={() => setBump((b) => b + 1)}
                  className="rounded border border-zinc-300 px-1 leading-4 hover:bg-zinc-100 dark:border-zinc-700 dark:hover:bg-zinc-800"
                >
                  +
                </button>
              </span>
            </div>
            <div className="mt-1 text-[10px] text-zinc-500 dark:text-zinc-400">
              {tool === "move"
                ? pick
                  ? "carrying " + (parseCell(interAt(pick.x, pick.z) ?? "")?.token ?? "?") + " — click a floor cell to drop it"
                  : upick
                    ? "carrying the utility " + (utilAt(upick.x, upick.z) ?? "").trim() + " — click any empty cell to drop it (a hole is fine: rides stand in holes)"
                    : "press an artifact or a utility and drag it to another cell, or click it then click the target"
                : tool === "place"
                  ? token
                    ? "click a floor cell to place " + token + (rot ? " @" + rot : "")
                    : "pick a token below, then click a floor cell"
                  : tool === "remove"
                    ? "click an artifact to clear its cell"
                    : tool === "uplace"
                      ? utok.trim()
                        ? "click any cell to write the utility " + utok.trim() + " (a cell that holds one is replaced)"
                        : "type or pick a utility token in the Utilities section, then click a cell — or click a cell that holds one to edit its text"
                      : tool === "uremove"
                        ? "click a cell to clear its utility"
                        : "drag across cells to paint " +
                          (toolRow.find((t) => t.id === tool && (t.lvl === undefined || t.lvl === lvl))?.label ??
                            "")}
            </div>

            {/* ------------------------------------------------------- grid */}
            <div ref={boxRef} className="mt-2 overflow-x-auto">
              <div
                className="lm-ed-grid relative"
                style={{
                  display: "grid",
                  gridTemplateColumns: "repeat(" + drawCols + ", " + cellPx + "px)",
                  width: drawCols * cellPx,
                }}
                onPointerLeave={() => {
                  painting.current = false;
                  lastPainted.current = "";
                  setOver(null);
                }}
              >
                {Array.from({ length: drawRows }).map((_, z) =>
                  Array.from({ length: drawCols }).map((__, x) => {
                    const st = structAt(x, z);
                    const it = interAt(x, z);
                    const a = it === null ? null : parseCell(it);
                    // the head's FOURTH field, via the careful reader — parseCell
                    // is the byte-twin of the Python strip parser and stops at the
                    // rotation on purpose. null here means the field is absent.
                    const aScale = it === null ? null : (parsePlacement(it)?.scale ?? null);
                    const uRaw = utilAt(x, z);
                    const u = uRaw && uRaw.trim() ? uRaw.trim() : "";
                    const uCode = u ? u.split("#")[0].split(":")[0].slice(0, 3) : "";
                    // this map's OWN wall height: a 2 is a wall at the default
                    // of 2 and a step you climb where the map declares 3 or 4
                    const k = st === null ? -1 : bucket(st, raw?.wallH ?? 2);
                    const isPick = pick?.x === x && pick?.z === z;
                    const isUpick = upick?.x === x && upick?.z === z;
                    const isOver = over?.x === x && over?.z === z;
                    // a carried utility can land on any cell the utilities grid has
                    // that holds no utility; a carried artifact needs floor
                    const uDropBad = tool === "move" && upick && isOver && !isUpick && (uRaw === null || !!u);
                    const uDropOk = tool === "move" && upick && isOver && !isUpick && uRaw !== null && !u;
                    const dropBad = (tool === "move" && pick && isOver && !isPick && refuseTarget(x, z)) || uDropBad;
                    const dropOk = (tool === "move" && pick && isOver && !isPick && !refuseTarget(x, z)) || uDropOk;
                    // THE GHOST. The stamp paints the value it would write. A
                    // cell it holds back keeps its own colour and takes a dot,
                    // so the artifacts and the ramps read as islands in the new
                    // plan — and a cell this MODE simply does not write is left
                    // alone with no mark, because "walls" writing nothing over
                    // 400 floor cells is the normal case, not a warning.
                    const inGhost =
                      structTab === "stamp" && preview && z < preview.h && x < preview.w;
                    const gv = inGhost ? preview.rows[z][x] : null;
                    const ghosted = gv !== null && gv !== "";
                    const gHold = !!inGhost && preview.holdAt.has(x + "," + z);
                    // grow() fills the appended rows with floor before the stamp
                    // runs, so an unwritten cell down there is floor, not a hole.
                    const gNew = !!inGhost && !ghosted && z >= rawDims.h;
                    const resizing = structTab === "size" && (wantW !== rawDims.w || wantH !== rawDims.h);
                    const willDrop = structTab === "size" && (x >= wantW || z >= wantH);
                    const inNew = structTab === "size" && x < wantW && z < wantH;
                    const willAdd = inNew && (x >= rawDims.w || z >= rawDims.h);
                    // The far shell after the move. grow() fills the new strip
                    // with FLOOR and only opens the old border — it does not
                    // build the new wall, and trim() will happily eat the wall
                    // it had. Either way the resulting max-x and max-z lines are
                    // what has to end up wall, so that is what is drawn.
                    const willWall = resizing && inNew && (x === wantW - 1 || z === wantH - 1);
                    const addFill = willWall ? FILL[bucket("w")] : FILL[bucket("1")];
                    return (
                      <div
                        key={z + "-" + x}
                        className={
                          "lm-ed-cell" +
                          (st === null && !ghosted && !willAdd && !gNew ? " lm-ed-nofloor" : "") +
                          (gHold ? " lm-ed-hold" : "") +
                          (willDrop ? " lm-ed-drop" : "")
                        }
                        style={{
                          width: cellPx,
                          height: cellPx,
                          background: ghosted
                            ? FILL[bucket(gv as string, raw?.wallH ?? 2)]
                            : gNew
                              ? FILL[bucket("1")]
                              : willAdd || willWall
                                ? addFill
                                : st === null
                                  ? "transparent"
                                  : FILL[k],
                          opacity: ghosted || gNew || willAdd || willWall ? 0.75 : 1,
                          outline: isPick || isUpick
                            ? "2px solid var(--lm-hi)"
                            : dropOk
                              ? "2px solid var(--lm-art)"
                              : dropBad
                                ? "2px solid var(--lm-off)"
                                : isOver
                                  ? "1px solid var(--lm-hi)"
                                  : "1px solid rgba(120,120,130,0.18)",
                          outlineOffset: -1,
                          cursor: tool === "move" ? (a || u || pick || upick ? "pointer" : "default") : "crosshair",
                        }}
                        title={
                          "(" + x + "," + z + ")  " +
                          (st === null ? "no structure cell" : "structure " + JSON.stringify(st)) +
                          (a ? "  ·  " + it : "") +
                          (u ? "  ·  utility " + u : "")
                        }
                        onPointerDown={(ev) => {
                          ev.preventDefault();
                          onDown(x, z);
                        }}
                        onPointerEnter={() => onEnter(x, z)}
                        onPointerUp={() => onUp(x, z)}
                      >
                        {a && (
                          <span
                            className="pointer-events-none absolute inset-0 flex items-center justify-center font-mono font-semibold"
                            style={{
                              color: "var(--lm-page)",
                              fontSize: Math.max(6, Math.round(cellPx * 0.4)),
                            }}
                          >
                            {/* THE DOT WEARS THE TOKEN'S SCALE (2026-09-08, Palle:
                                "I change from coordinate_readout:90:1.4:4 to
                                coordinate_readout:90:1.4:2 and nothing happened").
                                It did happen — on disk and in the museum — but every
                                web surface drew every body at one cell, so a scale
                                edit had no visible consequence anywhere outside the
                                headset. The DRAWN size is clamped to 2.2 cells so a
                                5x body cannot cover its neighbours; the badge below
                                carries the true number. */}
                            <span
                              className="absolute"
                              style={{
                                width: Math.max(4, cellPx * 0.66 * Math.min(2.2, Math.max(0.35, aScale ?? 1))),
                                height: Math.max(4, cellPx * 0.66 * Math.min(2.2, Math.max(0.35, aScale ?? 1))),
                                borderRadius: 999,
                                background: isPick ? "var(--lm-hi)" : "var(--lm-art)",
                                opacity: isPick ? 0.6 : 1,
                              }}
                            />
                            {cellPx >= 16 && (
                              <span className="relative text-white">
                                {a.token.slice(0, 2).toUpperCase()}
                              </span>
                            )}
                            {aScale !== null && Math.abs(aScale - 1) > 0.01 && cellPx >= 12 && (
                              // bottom-RIGHT: the utility badge owns the top-left
                              <span
                                className="absolute font-mono font-semibold leading-none"
                                style={{
                                  right: 0,
                                  bottom: 0,
                                  fontSize: Math.max(5, Math.round(cellPx * 0.34)),
                                  padding: "0 1px",
                                  borderRadius: 2,
                                  color: "#fff",
                                  background: "rgba(29,78,216,0.92)",
                                }}
                              >
                                {"×" + String(aScale)}
                              </span>
                            )}
                          </span>
                        )}
                        {u && (
                          // THE UTILITY BADGE: the code in the cell's corner, amber, so a
                          // ride, a wedge, a spawn or a text reads at a glance under the
                          // artifact dot it may share the cell with. The whole token is in
                          // the tooltip.
                          <span
                            className="pointer-events-none absolute font-mono font-semibold leading-none"
                            style={{
                              left: 0,
                              top: 0,
                              fontSize: Math.max(5, Math.round(cellPx * 0.34)),
                              padding: "0 1px",
                              borderRadius: 2,
                              color: "#fff",
                              background: isUpick
                                ? "var(--lm-hi)"
                                : tool === "uplace" || tool === "uremove" ? "rgb(180,83,9)" : "rgba(217,119,6,0.9)",
                            }}
                          >
                            {cellPx >= 12 ? uCode : "·"}
                          </span>
                        )}
                      </div>
                    );
                  }),
                )}
                {linkedParts.map((part, i) => part.x !== null && part.z !== null && (
                  <button
                    key={part.key}
                    type="button"
                    aria-label={"Locate " + part.label}
                    title={part.label + " · drag to move independently"}
                    aria-pressed={partPick === part.key}
                    className="absolute z-10 flex h-5 w-5 items-center justify-center rounded-full border border-amber-900 bg-amber-200 text-[10px] font-bold text-amber-950 shadow"
                    style={{ left: part.x * cellPx, top: part.z * cellPx, transform: "translate(-50%, -50%)" }}
                    onPointerDown={e => { e.stopPropagation(); inspectPart(part); }}
                    onPointerUp={e => e.stopPropagation()}
                    onClick={() => inspectPart(part)}
                  >{i + 1}</button>
                ))}
              </div>
            </div>
            <div className="mt-1 flex items-center gap-2 text-[9.5px] text-zinc-400 dark:text-zinc-500">
              <span>
                {arts.length} artifact{arts.length === 1 ? "" : "s"}
                {linkedParts.length > 0 && " + " + linkedParts.length + " linked instruments"}
              </span>
              <span>·</span>
              <span>
                {utilN} utilit{utilN === 1 ? "y" : "ies"}
              </span>
              <span>·</span>
              <span>
                {over ? "(" + over.x + "," + over.z + ")" : "hover a cell"}
              </span>
              <span>·</span>
              <span>
                hatched = outside the structure grid
              </span>
            </div>

            {partsError && <div role="alert" className="mt-2 text-xs text-amber-700">{partsError}</div>}
            {linkedParts.length > 0 && (
              <section aria-label="Linked instruments" className="mt-2 rounded border border-amber-300 p-2 dark:border-amber-900">
                <div className="text-xs font-semibold">Linked instruments</div>
                <p className="my-1 text-[10px] text-zinc-500">Select a numbered instrument, then click a floor cell or drag its marker. Each moves independently; its seed connections stay linked.</p>
                {linkedParts.map((part, i) => (
                  <button key={part.key} type="button" onClick={() => inspectPart(part)}
                    className="block w-full rounded px-1 py-1 text-left text-xs hover:bg-amber-50 dark:hover:bg-amber-950/30">
                    <span className="font-semibold">{i + 1}. {part.label}</span>
                    <span className="block text-[10px] text-zinc-500">
                      {part.issue ?? `Position (${part.x!.toFixed(2)}, ${part.z!.toFixed(2)}) · ${part.independent ? "independent position" : "original placement"}`}
                    </span>
                  </button>
                ))}
                {selectedPart && selectedPart.x !== null && (
                  <div className="mt-2 border-t border-amber-200 pt-2">
                    <div className="text-xs font-semibold">Move {selectedPart.label}</div>
                    <div className="mt-1 flex flex-wrap items-end gap-2">
                      {(["x", "z", "yaw"] as const).map(axis => (
                        <label key={axis} className="text-[10px]">{axis === "yaw" ? "Rotation °" : axis.toUpperCase()}
                          <input aria-label={`${selectedPart.label} ${axis}`} type="number" step={axis === "yaw" ? 1 : 0.1}
                            value={partPose[axis]} onChange={e => setPartPose(prev => ({ ...prev, [axis]: e.target.value }))}
                            className="block w-20 rounded border bg-transparent p-1 text-xs" />
                        </label>
                      ))}
                      <button type="button" disabled={Object.values(partPose).some(v => !v.trim())}
                        onClick={() => movePartTo(Number(partPose.x), Number(partPose.z), Number(partPose.yaw))}
                        className="rounded border border-amber-600 px-2 py-1 text-xs disabled:opacity-40">Apply position</button>
                      <button type="button" onClick={() => setPartPick(null)} className="p-1 text-xs">Done</button>
                    </div>
                  </div>
                )}
              </section>
            )}

            {/* ---------------------------------------- the utility inspector */}
            {upick && utilAt(upick.x, upick.z) !== null && (
              <div className="mt-2 rounded border border-amber-300 bg-amber-50/40 p-2 dark:border-amber-900 dark:bg-amber-950/30">
                <div className="flex items-baseline gap-2">
                  <span className="font-mono text-[11px] font-semibold text-amber-800 dark:text-amber-200">
                    {(utilAt(upick.x, upick.z) ?? "").trim().split("#")[0].split(":")[0] || "utility"}
                  </span>
                  <span className="text-[10px] text-zinc-500 dark:text-zinc-400">
                    utility at ({upick.x},{upick.z})
                  </span>
                  <button
                    onClick={() => setUpick(null)}
                    className="ml-auto rounded border border-zinc-300 px-1.5 text-[10px] leading-5 hover:bg-zinc-100 dark:border-zinc-700 dark:hover:bg-zinc-800"
                  >
                    close
                  </button>
                </div>
                <input
                  value={utext}
                  onChange={(e) => setUtext(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") applyUtext();
                  }}
                  className="mt-1 w-full rounded border border-amber-300 bg-transparent px-1.5 py-0.5 font-mono text-[11px] dark:border-amber-800"
                  title="the whole cell, verbatim: code, then that code's own fields after colons, then #key:value config"
                />
                {/^3t(:|$)/.test(utext.trim()) && (
                  <input
                    value={utext.trim().replace(/^3t:?/, "")}
                    onChange={(e) => setUtext("3t:" + e.target.value.replace(/:/g, ","))}
                    onKeyDown={(e) => {
                      if (e.key === "Enter") applyUtext();
                    }}
                    placeholder="the words"
                    className="mt-1 w-full rounded border border-amber-200 bg-transparent px-1.5 py-0.5 text-[11px] dark:border-amber-900"
                    title="the words alone; a colon is written as a comma because the cell splits on it"
                  />
                )}
                <div className="mt-1 flex items-center gap-1">
                  <button
                    disabled={!utext.trim() || utext.trim() === (utilAt(upick.x, upick.z) ?? "").trim()}
                    onClick={applyUtext}
                    className="rounded border border-amber-600 bg-amber-600 px-2 text-[10px] font-semibold leading-5 text-white disabled:opacity-40 hover:bg-amber-700"
                  >
                    apply
                  </button>
                  <button
                    onClick={() => {
                      removeUtilAt(upick.x, upick.z);
                      setUpick(null);
                    }}
                    className="rounded border border-zinc-300 px-1.5 text-[10px] leading-5 hover:bg-zinc-100 dark:border-zinc-700 dark:hover:bg-zinc-800"
                  >
                    clear
                  </button>
                  <span className="ml-auto text-[9.5px] text-zinc-400 dark:text-zinc-500">
                    {UTIL_PRESETS.find((u) => u.code.split(":")[0] === utext.trim().split("#")[0].split(":")[0])
                      ? "enter applies"
                      : "a code the presets do not list — the grid reads what it knows and ignores the rest"}
                  </span>
                </div>
              </div>
            )}

            {/* ------------------------------------------------- the inspector */}
            {insp && (
              <div className="mt-2 rounded border border-sky-300 bg-sky-50/40 p-2 dark:border-sky-900 dark:bg-sky-950/30">
                <div className="flex items-baseline gap-2">
                  <span className="font-mono text-[11px] font-semibold text-sky-800 dark:text-sky-200">
                    {insp.token}
                  </span>
                  <span className="text-[10px] text-zinc-500 dark:text-zinc-400">
                    ({pick?.x},{pick?.z})
                  </span>
                  <button
                    onClick={() => setPick(null)}
                    className="ml-auto rounded border border-zinc-300 px-1.5 text-[10px] leading-5 hover:bg-zinc-100 dark:border-zinc-700 dark:hover:bg-zinc-800"
                  >
                    close
                  </button>
                </div>

                {insp.prefixed ? (
                  <div className="mt-1 text-[10px] leading-snug text-amber-700 dark:text-amber-400">
                    a prefixed token. Its colon fields are part of the identity, not transform
                    slots: gridagent:90 is tier 90, and reading it as a rotation picks a different
                    scene. Only the config below is editable here.
                  </div>
                ) : (
                  <div className="mt-1.5 grid grid-cols-3 gap-1.5">
                    {INSPECTOR_FIELDS.map((f) => (
                      <label key={f.k} className="block" title={f.hint}>
                        <span className="block text-[9.5px] text-zinc-500 dark:text-zinc-400">
                          {f.label}
                        </span>
                        <input
                          type="number"
                          step={f.step}
                          value={insp[f.k] === null ? "" : String(insp[f.k])}
                          placeholder={f.k === "rot" ? "0" : "unset"}
                          onChange={(e) => {
                            const t = e.target.value.trim();
                            const nv = t === "" ? (f.k === "rot" ? 0 : null) : Number(t);
                            setInsp((prev) => (prev ? { ...prev, [f.k]: nv } : prev));
                          }}
                          className="w-full rounded border border-zinc-300 bg-transparent px-1 py-0.5 text-[11px] tabular-nums dark:border-zinc-700"
                        />
                      </label>
                    ))}
                  </div>
                )}

                <div className="mt-2 text-[9.5px] font-semibold tracking-wide text-zinc-400 uppercase dark:text-zinc-500">
                  config
                </div>
                {insp.tails.map((t, i) => (
                  <div key={i} className="mt-1 flex items-center gap-1">
                    <input
                      value={t.k}
                      onChange={(e) =>
                        setInsp((prev) =>
                          prev
                            ? {
                                ...prev,
                                tails: prev.tails.map((q, j) =>
                                  j === i ? { ...q, k: e.target.value } : q,
                                ),
                              }
                            : prev,
                        )
                      }
                      className="w-24 shrink-0 rounded border border-zinc-300 bg-transparent px-1 py-0.5 font-mono text-[10px] dark:border-zinc-700"
                    />
                    <input
                      value={t.v}
                      onChange={(e) =>
                        setInsp((prev) =>
                          prev
                            ? {
                                ...prev,
                                tails: prev.tails.map((q, j) =>
                                  j === i ? { ...q, v: e.target.value } : q,
                                ),
                              }
                            : prev,
                        )
                      }
                      className="min-w-0 flex-1 rounded border border-zinc-300 bg-transparent px-1 py-0.5 font-mono text-[10px] dark:border-zinc-700"
                    />
                    <button
                      onClick={() =>
                        setInsp((prev) =>
                          prev ? { ...prev, tails: prev.tails.filter((_, j) => j !== i) } : prev,
                        )
                      }
                      className="rounded border border-zinc-300 px-1 text-[10px] leading-5 hover:bg-zinc-100 dark:border-zinc-700 dark:hover:bg-zinc-800"
                    >
                      x
                    </button>
                  </div>
                ))}
                <div className="mt-1 flex flex-wrap gap-1">
                  {LIVE_CONFIG_KEYS.map((k) => (
                    <button
                      key={k}
                      disabled={insp.tails.some((t) => t.k === k)}
                      onClick={() =>
                        setInsp((prev) =>
                          prev ? { ...prev, tails: [...prev.tails, { k, v: "" }] } : prev,
                        )
                      }
                      className="rounded border border-zinc-300 px-1 text-[10px] leading-5 disabled:opacity-30 hover:bg-zinc-100 dark:border-zinc-700 dark:hover:bg-zinc-800"
                    >
                      + {k}
                    </button>
                  ))}
                </div>

                <div className="mt-2 rounded bg-zinc-100 px-1.5 py-1 font-mono text-[10px] break-all dark:bg-zinc-900">
                  {formatPlacement(insp)}
                </div>
                <div className="mt-1 flex items-center gap-1.5">
                  <button
                    disabled={formatPlacement(insp) === insp.raw}
                    onClick={() => {
                      if (!pick) return;
                      const next = formatPlacement(insp);
                      push({
                        layer: "interactables",
                        x: pick.x,
                        z: pick.z,
                        prev: insp.raw,
                        next,
                        note: "set " + next + " at (" + pick.x + "," + pick.z + ")",
                      });
                    }}
                    className="rounded border border-sky-600 bg-sky-600 px-2 text-[10px] font-semibold leading-5 text-white disabled:opacity-40 hover:bg-sky-700"
                  >
                    apply
                  </button>
                  <button
                    disabled={formatPlacement(insp) === insp.raw}
                    onClick={() => setInsp(parsePlacement(insp.raw))}
                    className="rounded border border-zinc-300 px-1.5 text-[10px] leading-5 disabled:opacity-40 hover:bg-zinc-100 dark:border-zinc-700 dark:hover:bg-zinc-800"
                  >
                    revert
                  </button>
                  <span className="truncate text-[9.5px] text-zinc-400 dark:text-zinc-500">
                    {formatPlacement(insp) === insp.raw ? "unchanged" : "was " + insp.raw}
                  </span>
                </div>
              </div>
            )}

            {/* ----------------------------------- architecture: stamp/size */}
            <div className="mt-3 border-t border-zinc-200 pt-2 dark:border-zinc-800">
              <div className="flex flex-wrap items-center gap-1.5">
                <div className="text-[10px] font-semibold tracking-wide text-zinc-400 uppercase dark:text-zinc-500">
                  Architecture
                </div>
                <button
                  disabled={raw?.simulation}
                  title={
                    raw?.simulation
                      ? "this hall declares map_info.museum.simulation — the whole tile is one basin holding a live GridSystem, so a template cannot be laid over it"
                      : "lay one of the museum's researched hall plans over this hall's structure"
                  }
                  onClick={() => {
                    setStructTab((t) => (t === "stamp" ? "" : "stamp"));
                    setArmed(null);
                    setStructErr(null);
                  }}
                  className={
                    "rounded border px-1.5 py-0.5 text-[10px] leading-4 disabled:opacity-40 " +
                    (structTab === "stamp"
                      ? "border-sky-500 bg-sky-100 font-semibold text-sky-800 dark:border-sky-600 dark:bg-sky-950/70 dark:text-sky-200"
                      : "border-zinc-300 text-zinc-600 hover:bg-zinc-100 dark:border-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-800")
                  }
                >
                  stamp a template
                </button>
                <button
                  title="add or drop rows and columns at the far edges"
                  onClick={() => {
                    setStructTab((t) => (t === "size" ? "" : "size"));
                    setWantW(rawDims.w);
                    setWantH(rawDims.h);
                    setArmed(null);
                    setStructErr(null);
                  }}
                  className={
                    "rounded border px-1.5 py-0.5 text-[10px] leading-4 " +
                    (structTab === "size"
                      ? "border-sky-500 bg-sky-100 font-semibold text-sky-800 dark:border-sky-600 dark:bg-sky-950/70 dark:text-sky-200"
                      : "border-zinc-300 text-zinc-600 hover:bg-zinc-100 dark:border-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-800")
                  }
                >
                  resize {rawDims.w}×{rawDims.h}
                </button>
                <button
                  disabled={!raw?.backups?.length || restoring}
                  title={
                    raw?.backups?.length
                      ? "put back the newest of " + raw.backups.length +
                        " timestamped backups — the current file is backed up first, so this is itself undoable"
                      : "no backups yet — one is written before every save"
                  }
                  onClick={() => void restoreLast()}
                  className="ml-auto rounded border border-amber-400 px-1.5 py-0.5 text-[10px] leading-4 text-amber-800 disabled:opacity-40 hover:bg-amber-50 dark:border-amber-700 dark:text-amber-300 dark:hover:bg-amber-950/40"
                >
                  {restoring ? "restoring…" : "restore" + (raw?.backups?.length ? " (" + raw.backups.length + ")" : "")}
                </button>
              </div>

              {structTab !== "" && (
                <div className="mt-1 text-[10px] leading-snug text-zinc-500 dark:text-zinc-400">
                  Both of these are structural, and neither goes through apply live. Nothing is
                  written until confirm is pressed a second time.
                  {edits.length > 0 && (
                    <span className="text-amber-700 dark:text-amber-400">
                      {" "}
                      {edits.length} cell edit{edits.length === 1 ? " is" : "s are"} still pending —
                      save or discard first, or the two writes race for the same file.
                    </span>
                  )}
                </div>
              )}

              {/* -------------------------------------------------- stamp */}
              {structTab === "stamp" && (
                <div className="mt-2">
                  {raw?.basinWhole && (
                    <div className="mb-1 rounded border border-amber-300 bg-amber-50 px-2 py-1 text-[10px] leading-snug text-amber-900 dark:border-amber-900/60 dark:bg-amber-950/40 dark:text-amber-200">
                      This hall declares a basin with no rects, so the pool is derived from the
                      whole floor and no cell can be held out of the way. The sink is gated on the
                      cell not being a wall, so a stamp that walls the pool cancels it.
                    </div>
                  )}
                  <input
                    value={stampQ}
                    onChange={(e) => setStampQ(e.target.value)}
                    placeholder={
                      "filter " + (stamps?.length ?? 0) + " museum plans by name or museum"
                    }
                    className="w-full rounded border border-zinc-300 bg-transparent px-1.5 py-1 text-[11px] dark:border-zinc-700"
                  />
                  {/* /api/museum-stamps returns only the 25 patterns that carry
                      a template_key. They are 13-17 wide and 27-36 DEEP, while
                      halls are 9-54 deep with a median of 17 — so 96% of the
                      5,175 (hall x plan) pairs overflow, and only 7 of the 207
                      halls take any of them as-is. The size is on every row for
                      that reason: it is the number that decides the write. */}
                  <div className="mt-1 max-h-48 space-y-0.5 overflow-y-auto pr-1">
                    {(stampList ?? []).map((s) => (
                      <button
                        key={s.key}
                        onClick={() => {
                          setStampKey(s.key);
                          setArmed(null);
                          setStructErr(null);
                        }}
                        className={
                          "flex w-full items-center gap-2 rounded border px-1.5 py-1 text-left text-[10px] " +
                          (s.key === stampKey
                            ? "border-sky-500 bg-sky-50 dark:border-sky-600 dark:bg-sky-950/60"
                            : "border-zinc-200 hover:bg-zinc-100 dark:border-zinc-800 dark:hover:bg-zinc-800/70")
                        }
                      >
                        <svg
                          width={26}
                          height={Math.min(52, Math.max(12, s.h))}
                          viewBox={"0 0 " + s.w + " " + s.h}
                          preserveAspectRatio="none"
                          className="shrink-0 rounded-[1px]"
                          style={{ background: "var(--lm-void)" }}
                        >
                          {s.tile.map((row, rz) =>
                            row.map((v, rx) => {
                              const t = String(v).trim();
                              if (!t || t === "0") return null;
                              // The tile's own vocabulary, drawn in the map's
                              // colours through the same table the write uses,
                              // so the thumbnail and the ghost cannot disagree.
                              const m = mapTileCell(t);
                              return (
                                <rect
                                  key={rx + "_" + rz}
                                  x={rx}
                                  y={rz}
                                  width={1}
                                  height={1}
                                  fill={m === null ? "var(--lm-off)" : FILL[bucket(m, raw?.wallH ?? 2)]}
                                />
                              );
                            }),
                          )}
                        </svg>
                        <span className="min-w-0 flex-1">
                          <span className="block truncate text-zinc-700 dark:text-zinc-200">
                            {s.label}
                          </span>
                          <span className="block truncate text-[9px] text-zinc-400 dark:text-zinc-500">
                            {s.museum || s.key}
                          </span>
                        </span>
                        <span className="shrink-0 text-right font-mono text-[9px] tabular-nums text-zinc-400 dark:text-zinc-500">
                          <span className="block">
                            {s.w}×{s.h}
                          </span>
                          <span
                            className={
                              "block " +
                              (s.h > rawDims.h ? "text-amber-600 dark:text-amber-400" : "")
                            }
                          >
                            {s.h > rawDims.h
                              ? "+" + (s.h - rawDims.h) + " deep"
                              : s.h < rawDims.h
                                ? (rawDims.h - s.h) + " short"
                                : "fits"}
                          </span>
                        </span>
                      </button>
                    ))}
                    {stamps === null && (
                      <div className="px-1 py-2 text-[10px] text-zinc-400">
                        reading /api/museum-stamps…
                      </div>
                    )}
                    {stamps !== null && !stampList.length && (
                      <div className="px-1 py-2 text-[10px] text-zinc-400">
                        {stampsErr
                          ? "/api/museum-stamps: " + stampsErr
                          : stamps.length
                            ? "no plan matches " + JSON.stringify(stampQ)
                            : "no museum plans — /api/museum-stamps returned none"}
                      </div>
                    )}
                  </div>

                  {stamp && preview && (
                    <div className="mt-2 rounded border border-zinc-200 px-2 py-1.5 dark:border-zinc-800">
                      <div className="flex flex-wrap items-center gap-1.5">
                        <span className="text-[10px] text-zinc-500 dark:text-zinc-400">writes:</span>
                        {(
                          [
                            // MEASURED, NOT ASSUMED: "walls only" means only the cells the PLAN draws as
// wall are written — it does not mean the cells underneath were empty. On a
// 15x9 hall, capuchin-crypt-corridor wrote 33 cells and 23 of them were floor,
// and the write severed a teleporter. The old wording said no floor cell is
// touched, which is the sentence a person reads before pressing.
["walls", "walls only", "writes the plan's wall cells over whatever is under them — usually floor"],
                            ["rooms", "walls + floor", "walls, floor and platforms, but never a hole"],
                            ["full", "everything", "the whole plan including its voids"],
                          ] as const
                        ).map(([id, label, hint]) => (
                          <button
                            key={id}
                            title={hint}
                            onClick={() => {
                              setMode(id);
                              setArmed(null);
                            }}
                            className={
                              "rounded border px-1.5 text-[10px] leading-5 " +
                              (mode === id
                                ? "border-sky-500 bg-sky-100 font-semibold text-sky-800 dark:border-sky-600 dark:bg-sky-950/70 dark:text-sky-200"
                                : "border-zinc-300 text-zinc-600 hover:bg-zinc-100 dark:border-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-800")
                            }
                          >
                            {label}
                          </button>
                        ))}
                      </div>
                      {preview.overflow > 0 && (
                        <div className="mt-1 flex flex-wrap items-center gap-1.5">
                          <span className="text-[10px] text-zinc-500 dark:text-zinc-400">
                            {preview.overflow} row{preview.overflow === 1 ? "" : "s"} deeper than
                            the hall:
                          </span>
                          {(["grow", "clip"] as const).map((d) => (
                            <button
                              key={d}
                              onClick={() => {
                                setDeep(d);
                                setArmed(null);
                              }}
                              title={
                                d === "grow"
                                  ? "append rows at max z until the whole plan fits — the origin does not move"
                                  : "throw away the rows past this hall's depth"
                              }
                              className={
                                "rounded border px-1.5 text-[10px] leading-5 " +
                                (deep === d
                                  ? "border-sky-500 bg-sky-100 font-semibold text-sky-800 dark:border-sky-600 dark:bg-sky-950/70 dark:text-sky-200"
                                  : "border-zinc-300 text-zinc-600 hover:bg-zinc-100 dark:border-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-800")
                              }
                            >
                              {d === "grow" ? "grow the hall" : "clip the plan"}
                            </button>
                          ))}
                        </div>
                      )}

                      <div className="mt-1.5 font-mono text-[10px] leading-relaxed text-zinc-600 dark:text-zinc-300">
                        <div>
                          {rawDims.w}×{rawDims.h} → {preview.w}×{preview.h}
                          {preview.newRows ? "   +" + preview.newRows + " rows at max z" : ""}
                        </div>
                        <div>
                          {fmt(preview.change)} cell{preview.change === 1 ? "" : "s"} change ·{" "}
                          {fmt(preview.unchanged)} already right ·{" "}
                          {fmt(
                            preview.byWhy.artifact +
                              preview.byWhy.utility +
                              preview.byWhy.basin +
                              preview.byWhy.platform,
                          )}{" "}
                          held
                        </div>
                        <div className="text-zinc-400 dark:text-zinc-500">
                          writes {fmt(preview.walls)} w · {fmt(preview.floors)} floor ·{" "}
                          {fmt(preview.plats)} p · {fmt(preview.voids)} hole
                        </div>
                      </div>

                      {/* WHAT SURVIVES IT. 1,583 artifacts, 20 live utility
                          codes and 8 declared basins are in these halls, and a
                          plan laid over them blind would pave 62 artifacts into
                          a wall. Each held cell is named, because "13 skipped"
                          is not something anyone can check. */}
                      <div className="mt-1 text-[10px] leading-snug text-zinc-500 dark:text-zinc-400">
                        {preview.byWhy.artifact > 0 && (
                          <div>
                            {fmt(preview.byWhy.artifact)} cell
                            {preview.byWhy.artifact === 1 ? "" : "s"} held under an artifact
                          </div>
                        )}
                        {preview.byWhy.utility > 0 && (
                          <div>
                            {fmt(preview.byWhy.utility)} held under a utility —{" "}
                            {[
                              ...new Set(
                                preview.held
                                  .filter((h) => h.why === "utility")
                                  .map((h) => utilityName(h.what)),
                              ),
                            ]
                              .slice(0, 6)
                              .join(", ")}
                          </div>
                        )}
                        {preview.byWhy.basin > 0 && (
                          <div>
                            {fmt(preview.byWhy.basin)} held inside a declared basin rect — a wall
                            cell there cancels the pool
                          </div>
                        )}
                        {preview.byWhy.platform > 0 && (
                          <div>
                            {fmt(preview.byWhy.platform)} held on an existing p platform — the
                            corpus has exactly one, so it was declared on purpose
                          </div>
                        )}
                        {preview.untouchedPastTile > 0 && (
                          <div>
                            the plan runs out {preview.untouchedPastTile} row
                            {preview.untouchedPastTile === 1 ? "" : "s"} before the hall does, and
                            those rows are left exactly as they are — never padded with holes
                          </div>
                        )}
                        {deep === "clip" && preview.overflow > 0 && (
                          <div className="text-amber-700 dark:text-amber-400">
                            {preview.overflow} row{preview.overflow === 1 ? "" : "s"} of the plan
                            are thrown away — its back {preview.overflow} m of architecture. A
                            clipped plan has stranded floor before: soane-cabinet-vista cut to
                            13×19 leaves 6 of 142 walkable cells unreachable.
                          </div>
                        )}
                        {preview.unknown && (
                          <div className="text-red-700 dark:text-red-300">
                            the plan uses {JSON.stringify(preview.unknown.raw)} at (
                            {preview.unknown.x},{preview.unknown.z}), which is not in the tile
                            vocabulary. The route refuses the whole stamp on this rather than
                            guessing a height.
                          </div>
                        )}
                      </div>

                      <div className="mt-1.5 flex items-center gap-1.5">
                        {armed === "stamp" ? (
                          <>
                            <button
                              disabled={structBusy}
                              onClick={() => void submitStruct("stamp")}
                              className="rounded border border-red-600 bg-red-600 px-2 text-[10px] font-semibold leading-5 text-white disabled:opacity-40 hover:bg-red-700"
                            >
                              {structBusy
                                ? "writing…"
                                : "confirm: write " + fmt(preview.change) + " cells"}
                            </button>
                            <button
                              disabled={structBusy}
                              onClick={() => setArmed(null)}
                              className="rounded border border-zinc-300 px-1.5 text-[10px] leading-5 disabled:opacity-40 hover:bg-zinc-100 dark:border-zinc-700 dark:hover:bg-zinc-800"
                            >
                              cancel
                            </button>
                            <span className="text-[10px] text-red-700 dark:text-red-300">
                              this rewrites structure and cannot be undone cell by cell — the route
                              keeps a timestamped backup
                            </span>
                          </>
                        ) : (
                          <button
                            disabled={
                              !preview.change || !!edits.length || structBusy || !!preview.unknown
                            }
                            title={
                              edits.length
                                ? "save or discard the pending cell edits first"
                                : preview.unknown
                                  ? "the route refuses this plan: unknown tile character"
                                  : !preview.change
                                    ? "this plan is already what the hall holds"
                                    : "arm the write"
                            }
                            onClick={() => setArmed("stamp")}
                            className="rounded border border-zinc-400 px-2 text-[10px] font-semibold leading-5 text-zinc-700 disabled:opacity-40 hover:bg-zinc-100 dark:border-zinc-600 dark:text-zinc-200 dark:hover:bg-zinc-800"
                          >
                            stamp…
                          </button>
                        )}
                      </div>
                    </div>
                  )}
                </div>
              )}

              {/* ------------------------------------------------- resize */}
              {structTab === "size" && (
                <div className="mt-2 rounded border border-zinc-200 px-2 py-1.5 dark:border-zinc-800">
                  {/* THE ORIGIN DOES NOT MOVE. tools/stamp_ready.py:grow()
                      appends at the far edges only, and that is the whole
                      safety argument: every artifact coordinate, every utility
                      and every saved ruling still addresses the same cell. A
                      symmetric resize would silently re-address the map. */}
                  <div className="text-[10px] leading-snug text-zinc-500 dark:text-zinc-400">
                    Rows and columns are added and dropped at <b>max x</b> and <b>max z</b> only.
                    The origin cell (0,0) never moves, so nothing already placed changes address.
                  </div>
                  {([
                    { axis: "x" as const, label: "width x", cur: rawDims.w, want: wantW, set: setWantW, block: blockX },
                    { axis: "z" as const, label: "depth z", cur: rawDims.h, want: wantH, set: setWantH, block: blockZ },
                  ]).map((r) => (
                    <div key={r.axis} className="mt-1.5">
                      <div className="flex items-center gap-1.5">
                        <span className="w-14 shrink-0 text-[10px] text-zinc-500 dark:text-zinc-400">
                          {r.label}
                        </span>
                        <button
                          disabled={r.want <= 3 || (r.want <= r.cur && !!r.block)}
                          // Functional, not r.want - 1: two presses inside one
                          // React batch both read the same captured value and
                          // the second one is lost, which reads as a stuck
                          // button rather than as a dropped click.
                          onClick={() => {
                            r.set((v) => Math.max(3, v - 1));
                            setArmed(null);
                          }}
                          className="rounded border border-zinc-300 px-1.5 text-[11px] leading-5 disabled:opacity-40 hover:bg-zinc-100 dark:border-zinc-700 dark:hover:bg-zinc-800"
                        >
                          −
                        </button>
                        <span className="font-mono text-[11px] tabular-nums text-zinc-700 dark:text-zinc-200">
                          {r.cur}
                          {r.want !== r.cur ? " → " + r.want : ""}
                        </span>
                        <button
                          // 200 is the route's cap; the deepest hall in the
                          // corpus is 54.
                          disabled={r.want >= 200}
                          onClick={() => {
                            r.set((v) => Math.min(200, v + 1));
                            setArmed(null);
                          }}
                          className="rounded border border-zinc-300 px-1.5 text-[11px] leading-5 disabled:opacity-40 hover:bg-zinc-100 dark:border-zinc-700 dark:hover:bg-zinc-800"
                        >
                          +
                        </button>
                        {/* A SLIDER, because stepping from 20 to 34 is fourteen
                            clicks. Capped at twice the current size or 48,
                            whichever is larger — the route's own ceiling is 200
                            and the deepest hall in the corpus is 54, so a
                            0-to-200 track would make single-cell aim impossible. */}
                        <input
                          type="range"
                          min={3}
                          max={Math.min(200, Math.max(48, r.cur * 2))}
                          value={r.want}
                          onChange={(e) => {
                            r.set(Number(e.target.value));
                            setArmed(null);
                          }}
                          className="h-3 flex-1 accent-sky-600"
                          aria-label={r.label}
                        />
                        <span className="text-[10px] text-zinc-400 dark:text-zinc-500">
                          {r.want > r.cur
                            ? "+" + (r.want - r.cur) + " at max " + r.axis
                            : r.want < r.cur
                              ? "−" + (r.cur - r.want) + " from max " + r.axis
                              : ""}
                        </span>
                      </div>
                      {r.want < r.cur && r.block && (
                        <div className="mt-0.5 text-[10px] leading-snug text-red-700 dark:text-red-300">
                          {r.block.stoppedAt >= r.cur
                            ? "this hall cannot lose a " + (r.axis === "x" ? "column" : "row") + " at all: "
                            : "cannot go below " + r.block.stoppedAt + ": "}
                          {r.block.reason === "artifact"
                            ? "the artifact " + r.block.what
                            : r.block.reason === "utility"
                              ? "the " + utilityName(r.block.what)
                              : "floor " + JSON.stringify(r.block.what)}{" "}
                          stands at ({r.block.x},{r.block.z}), on the{" "}
                          {r.axis === "x" ? "column" : "row"} the trim reached. It drops one line at
                          a time and stops at the first cell of height 1 — or any utility or
                          artifact — so one cell three lines in blocks a contract of four. Move it
                          inward first.
                        </div>
                      )}
                    </div>
                  ))}
                  {(wantW < rawDims.w || wantH < rawDims.h) && !blockX && !blockZ && (
                    <div className="mt-1 text-[10px] leading-snug text-amber-700 dark:text-amber-400">
                      A trim reads a far edge as free unless a cell there has height exactly 1, so
                      a w column (height 3) and a 2 plinth are dropped without objection — this
                      contract will eat the shell wall, and the route re-walls the new border
                      afterwards to close it.
                    </div>
                  )}
                  <div className="mt-1.5 flex items-center gap-1.5">
                    {armed === "resize" ? (
                      <>
                        <button
                          disabled={structBusy}
                          onClick={() => void submitStruct("resize")}
                          className="rounded border border-red-600 bg-red-600 px-2 text-[10px] font-semibold leading-5 text-white disabled:opacity-40 hover:bg-red-700"
                        >
                          {structBusy
                            ? "writing…"
                            : "confirm: " + rawDims.w + "×" + rawDims.h + " → " + wantW + "×" + wantH}
                        </button>
                        <button
                          disabled={structBusy}
                          onClick={() => setArmed(null)}
                          className="rounded border border-zinc-300 px-1.5 text-[10px] leading-5 disabled:opacity-40 hover:bg-zinc-100 dark:border-zinc-700 dark:hover:bg-zinc-800"
                        >
                          cancel
                        </button>
                        <span className="text-[10px] text-red-700 dark:text-red-300">
                          {/* only a DEPTH change shifts the strip. The route raises
                              strip_z_shifted on h changes alone; saying it for a
                              width-only resize is a warning about nothing, which
                              teaches people to ignore the red text. */}
                          {wantH !== rawDims.h
                            ? "this moves every hall after this one along the strip"
                            : "width only — no hall after this one moves"}
                        </span>
                      </>
                    ) : (
                      <button
                        disabled={
                          structBusy ||
                          !!edits.length ||
                          (wantW === rawDims.w && wantH === rawDims.h) ||
                          (wantW < rawDims.w && !!blockX) ||
                          (wantH < rawDims.h && !!blockZ)
                        }
                        title={
                          edits.length
                            ? "save or discard the pending cell edits first"
                            : "arm the resize"
                        }
                        onClick={() => setArmed("resize")}
                        className="rounded border border-zinc-400 px-2 text-[10px] font-semibold leading-5 text-zinc-700 disabled:opacity-40 hover:bg-zinc-100 dark:border-zinc-600 dark:text-zinc-200 dark:hover:bg-zinc-800"
                      >
                        resize…
                      </button>
                    )}
                  </div>
                </div>
              )}

              {structErr && (
                <div className="mt-2 rounded border border-red-300 bg-red-50 px-2 py-1.5 text-[10px] leading-snug text-red-800 dark:border-red-900/60 dark:bg-red-950/40 dark:text-red-200">
                  {structErr}
                </div>
              )}
            </div>

            {/* -------------------------------------------------- utilities */}
            <div className="mt-3 border-t border-zinc-200 pt-2 dark:border-zinc-800">
              <div className="flex items-center gap-2">
                <div className="text-[10px] font-semibold tracking-wide text-zinc-400 uppercase dark:text-zinc-500">
                  Utilities
                </div>
                <span className="text-[9.5px] text-zinc-400 dark:text-zinc-500">
                  {utilN} in this hall · amber badge on the grid
                </span>
                {utok.trim() && (
                  <span className="ml-auto truncate font-mono text-[10px] text-amber-700 dark:text-amber-300">
                    {utok.trim()}
                  </span>
                )}
              </div>
              <input
                value={utok}
                onChange={(e) => {
                  setUtok(e.target.value);
                  if (e.target.value.trim()) setTool("uplace");
                }}
                placeholder="any utility token — tc:4:z, wp:90, rc:90:y:4:-0.6, 3t, sp, t …"
                className="mt-1 w-full rounded border border-amber-300 bg-transparent px-1.5 py-0.5 font-mono text-[11px] dark:border-amber-800"
                title="written verbatim into the utilities layer by the util + tool; the grid's UtilityRegistry reads the code before the first colon, and a #tail is config"
              />
              {/^3t(:|$)/.test(utok.trim()) && (
                <div className="mt-1">
                  <input
                    value={words}
                    onChange={(e) => setWords(e.target.value)}
                    placeholder="the words to stand in the hall"
                    className="w-full rounded border border-amber-300 bg-transparent px-1.5 py-0.5 text-[11px] dark:border-amber-800"
                  />
                  <div className="mt-0.5 text-[9.5px] leading-snug text-zinc-400 dark:text-zinc-500">
                    {words.trim()
                      ? "writes 3t:" + words.trim().replace(/:/g, ",")
                      : "type the words; a colon would end them early, so it is written as a comma"}
                  </div>
                </div>
              )}
              <div className="mt-1 flex flex-wrap gap-1">
                {UTIL_PRESETS.map((u) => (
                  <button
                    key={u.code}
                    title={u.hint + (u.museum ? "" : "  (the endless museum refuses this code)")}
                    onClick={() => {
                      setUtok(u.code);
                      setTool("uplace");
                      setPick(null);
                      setNote(null);
                    }}
                    className={
                      "rounded border px-1 py-[1px] font-mono text-[9.5px] leading-4 " +
                      (utok.trim() === u.code
                        ? "border-amber-500 bg-amber-100 font-semibold text-amber-900 dark:border-amber-600 dark:bg-amber-950/60 dark:text-amber-200"
                        : u.museum
                          ? "border-zinc-300 text-zinc-600 hover:bg-zinc-100 dark:border-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-800"
                          : "border-dashed border-zinc-300 text-zinc-500 hover:bg-zinc-100 dark:border-zinc-700 dark:text-zinc-400 dark:hover:bg-zinc-800")
                    }
                  >
                    {u.code}
                  </button>
                ))}
              </div>
              <div className="mt-1 text-[9.5px] leading-snug text-zinc-400 dark:text-zinc-500">
                {UTIL_PRESETS.find((u) => u.code === utok.trim())?.hint ??
                  "solid border: the endless museum honours the code (rc, sc, tc, br, jp, wp); dashed: the grid only. A ride's distance is the void's depth plus one; a wedge rises onto its neighbour; a plank stands at the centre of its 3x3."}
              </div>
            </div>

            {/* ---------------------------------------------------- palette */}
            <div className="mt-3 border-t border-zinc-200 pt-2 dark:border-zinc-800">
              <div className="flex items-center gap-2">
                <div className="text-[10px] font-semibold tracking-wide text-zinc-400 uppercase dark:text-zinc-500">
                  Palette
                </div>
                <select
                  value={rot}
                  onChange={(e) => setRot(Number(e.target.value))}
                  className="rounded border border-zinc-300 bg-transparent px-1 text-[10px] dark:border-zinc-700"
                  title="rotation written with a newly placed token; a moved artifact keeps its own"
                >
                  {ROTS.map((r) => (
                    <option key={r} value={r}>
                      {r}°
                    </option>
                  ))}
                </select>
                {token && (
                  <span className="truncate font-mono text-[10px] text-sky-700 dark:text-sky-300">
                    {token}
                  </span>
                )}
              </div>
              {TEXT_TOKENS.has(token) && (
                <div className="mt-1">
                  <input
                    value={words}
                    onChange={(e) => setWords(e.target.value)}
                    placeholder="the words to stand in the hall"
                    className="w-full rounded border border-sky-300 bg-transparent px-1.5 py-0.5 text-[11px] dark:border-sky-800"
                  />
                  <div className="mt-0.5 text-[9.5px] leading-snug text-zinc-400 dark:text-zinc-500">
                    {words.trim()
                      ? "writes " + token + "#text:" + words.trim().replace(/\s+/g, "_")
                      : "leave this empty and the hall shows the scene's own default sentence, not yours"}
                  </div>
                </div>
              )}
              <input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder={"filter this chapter's " + p.seqTokens.length + " tokens, or search all registries"}
                className="mt-1 w-full rounded border border-zinc-300 bg-transparent px-1.5 py-1 text-[11px] dark:border-zinc-700"
              />
              {/* The chapter's own vocabulary is the default because it costs
                  zero fetches and it is the right size: 1,295 distinct tokens
                  across the strip, median 68 per sequence. The 2,820-row
                  registry dump is 1.47 MB and 4.4 s. */}
              <div className="mt-1 max-h-40 overflow-y-auto">
                {localTokens.map((t) => (
                  <button
                    key={t.token}
                    onClick={() => {
                      setToken(t.token);
                      setTool("place");
                      setNote(null);
                    }}
                    className={
                      "flex w-full items-baseline gap-1.5 rounded px-1 py-[2px] text-left font-mono text-[10px] hover:bg-zinc-100 dark:hover:bg-zinc-800/70 " +
                      (token === t.token
                        ? "bg-sky-100 font-semibold text-sky-800 dark:bg-sky-950/60 dark:text-sky-200"
                        : "text-zinc-600 dark:text-zinc-300")
                    }
                  >
                    <span className="truncate">{t.token}</span>
                    <span className="ml-auto shrink-0 tabular-nums text-zinc-400 dark:text-zinc-500">
                      {t.n}
                    </span>
                  </button>
                ))}
                {!localTokens.length && (
                  <div className="px-1 text-[10px] text-zinc-400">
                    nothing in {p.sequence} matches
                  </div>
                )}
              </div>
              {found !== null && (
                <div className="mt-1 border-t border-dashed border-zinc-200 pt-1 dark:border-zinc-800">
                  <div className="px-1 text-[9.5px] text-zinc-400 dark:text-zinc-500">
                    all registries · {found.length} shown
                  </div>
                  <div className="max-h-40 overflow-y-auto">
                    {found.map((f) => (
                      <button
                        key={f.registry + "/" + f.lookup_name}
                        onClick={() => {
                          setToken(f.lookup_name);
                          setTool("place");
                          setNote(null);
                        }}
                        className={
                          "flex w-full items-baseline gap-1.5 rounded px-1 py-[2px] text-left font-mono text-[10px] hover:bg-zinc-100 dark:hover:bg-zinc-800/70 " +
                          (token === f.lookup_name
                            ? "bg-sky-100 font-semibold text-sky-800 dark:bg-sky-950/60 dark:text-sky-200"
                            : "text-zinc-600 dark:text-zinc-300")
                        }
                      >
                        <span className="min-w-0">
                          <span className="block truncate">{f.lookup_name}</span>
                          <span className="block text-[9px] text-zinc-500">{f.name}</span>
                          {!!f.parts?.length && <span className="block text-[9px] text-amber-700 dark:text-amber-400">Includes: {f.parts.join(" · ")}</span>}
                        </span>
                        <span className="ml-auto shrink-0 truncate text-[9px] text-zinc-400 dark:text-zinc-500">
                          {f.registry}
                        </span>
                      </button>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* ------------------------------------------------ pending ops */}
            <div className="mt-3 border-t border-zinc-200 pt-2 dark:border-zinc-800">
              <div className="flex items-center gap-2">
                <label
                  className="flex cursor-pointer items-center gap-1 text-[10px] font-semibold tracking-wide text-zinc-400 uppercase dark:text-zinc-500"
                  title="write each change to map_data.json as you make it, and rebuild the strip"
                >
                  <input
                    type="checkbox"
                    checked={auto}
                    onChange={(e) => {
                      setAuto(e.target.checked);
                      try {
                        window.localStorage.setItem("lm.autoApply", e.target.checked ? "1" : "0");
                      } catch {
                        // storage blocked — the toggle still works for this sitting
                      }
                    }}
                    className="h-3 w-3 accent-sky-600"
                  />
                  apply live
                </label>
                <span className="text-[10px] tabular-nums text-zinc-500 dark:text-zinc-400">
                  {saving
                    ? "writing…"
                    : edits.length
                      ? edits.length + " edit" + (edits.length === 1 ? "" : "s") + " · " +
                        ops.length + " cell write" + (ops.length === 1 ? "" : "s")
                      : applied.length
                        ? applied.length + " written this sitting"
                        : "no changes yet"}
                </span>
                <div className="ml-auto flex gap-1">
                  <button
                    disabled={(!edits.length && !applied.length) || saving}
                    onClick={undoLast}
                    title={
                      edits.length
                        ? "drop the last pending edit"
                        : "write back the value the last change replaced"
                    }
                    className="rounded border border-zinc-300 px-1.5 text-[10px] leading-5 disabled:opacity-40 hover:bg-zinc-100 dark:border-zinc-700 dark:hover:bg-zinc-800"
                  >
                    undo
                  </button>
                  <button
                    disabled={!edits.length || saving}
                    onClick={() => {
                      setEdits([]);
                      setPick(null);
                      setNote(null);
                    }}
                    className="rounded border border-zinc-300 px-1.5 text-[10px] leading-5 disabled:opacity-40 hover:bg-zinc-100 dark:border-zinc-700 dark:hover:bg-zinc-800"
                  >
                    discard
                  </button>
                  <button
                    disabled={!ops.length || saving}
                    onClick={save}
                    className="rounded border border-sky-600 bg-sky-600 px-2 text-[10px] font-semibold leading-5 text-white disabled:opacity-40 hover:bg-sky-700"
                  >
                    {saving ? "saving…" : auto ? "save now" : "save"}
                  </button>
                </div>
              </div>
              {slotsLost > 0 && (
                <div className="mt-1 text-[10px] text-amber-700 dark:text-amber-400">
                  {slotsLost} artifact slot{slotsLost === 1 ? "" : "s"} removed — a 1s/2s/3s cell
                  builds the same box as a plain 1, so this change is invisible everywhere except
                  the museum&apos;s dealer.
                </div>
              )}
              <div className="mt-1 max-h-32 overflow-y-auto">
                {edits
                  .slice()
                  .reverse()
                  .map((e, i) => (
                    <div
                      key={edits.length - 1 - i}
                      className="font-mono text-[9.5px] text-zinc-500 dark:text-zinc-400"
                    >
                      {e.layer === "structure" ? "str " : e.layer === "utilities" ? "util " : "art "}
                      {e.note}
                    </div>
                  ))}
                {!edits.length && (
                  <div className="text-[10px] text-zinc-400 dark:text-zinc-500">
                    {auto
                      ? applied.length
                        ? "up to date — every change is in map_data.json"
                        : "apply live is on: each change is written as you make it"
                      : "nothing pending — the map on disk is untouched"}
                  </div>
                )}
              </div>
            </div>

            {broke.length > 0 && (
              <div className="mt-2 rounded border border-red-400 bg-red-50 px-2 py-1.5 text-[10px] leading-snug text-red-900 dark:border-red-800 dark:bg-red-950/50 dark:text-red-200">
                <div className="font-semibold">
                  that write broke the walk — the change IS on disk
                </div>
                <ul className="mt-1 list-disc pl-4">
                  {broke.map((b) => (
                    <li key={b}>{b}</li>
                  ))}
                </ul>
                <div className="mt-1">
                  undo writes back the value it replaced. map_pathfinder will not catch this: it
                  has one error rule, and a hall sealed into a solid block still passes it.
                </div>
              </div>
            )}

            {note && (
              <div className="mt-2 rounded border border-sky-300 bg-sky-50/70 px-2 py-1.5 text-[10px] leading-snug text-sky-900 dark:border-sky-900 dark:bg-sky-950/40 dark:text-sky-200">
                {note}
              </div>
            )}
            {saveErr && (
              <div className="mt-2 rounded border border-red-300 bg-red-50 px-2 py-1.5 text-[10px] leading-snug text-red-800 dark:border-red-900/60 dark:bg-red-950/40 dark:text-red-200">
                {saveErr}
                <button
                  onClick={() => load(true)}
                  className="ml-1 underline"
                >
                  reload this hall from disk
                </button>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}
