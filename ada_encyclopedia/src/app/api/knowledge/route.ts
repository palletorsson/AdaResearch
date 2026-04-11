import { NextRequest, NextResponse } from "next/server";
import { readFile, readdir, stat } from "fs/promises";
import { join } from "path";

export const dynamic = "force-dynamic";

function getResearchPath(): string {
  return process.env.ADA_RESEARCH_PATH || "C:/Users/palle/Documents/GitHub/AdaResearch_46";
}

// ─── Types ─────────────────────────────────────────────────

interface MapTextEntry {
  map: string;
  sequence: string | null;
  blurb: string | null;
  intent: string | null;
  technical: string | null;
  critical: string | null;
  summary: string | null;
}

interface OntologyGlance {
  primitive: string;
  title: string;
  lens: string;
  question: string;
  insight: string;
  sequence: string;
  phase: string;
}

interface KnowledgeResponse {
  ontology: OntologyGlance[];
  maps: MapTextEntry[];
  sequences: Record<string, string[]>;
}

// ─── Helpers ───────────────────────────────────────────────

function parseFrontmatter(raw: string): { meta: Record<string, unknown>; content: string } {
  const match = raw.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n([\s\S]*)$/);
  if (!match) return { meta: {}, content: raw };
  const meta: Record<string, unknown> = {};
  for (const line of match[1].split(/\r?\n/)) {
    if (!line.trim()) continue;
    const ci = line.indexOf(":");
    if (ci === -1) continue;
    const key = line.slice(0, ci).trim();
    let val: unknown = line.slice(ci + 1).trim();
    if (typeof val === "string" && val.startsWith('"') && val.endsWith('"')) val = (val as string).slice(1, -1);
    if (typeof val === "string" && val.startsWith("[") && val.endsWith("]")) {
      val = (val as string).slice(1, -1).split(",").map(s => s.trim().replace(/^["']|["']$/g, "")).filter(Boolean);
    }
    meta[key] = val;
  }
  return { meta, content: match[2] };
}

async function readTextFile(dir: string, name: string): Promise<string | null> {
  try {
    return await readFile(join(dir, name), "utf-8");
  } catch {
    return null;
  }
}

// ─── Sequence → Map lookup ─────────────────────────────────

async function buildSequenceMap(researchPath: string): Promise<Record<string, string[]>> {
  const seqDir = join(researchPath, "commons", "maps", "sequences");
  const result: Record<string, string[]> = {};
  try {
    const files = await readdir(seqDir);
    for (const f of files) {
      if (!f.endsWith(".json")) continue;
      try {
        const data = JSON.parse(await readFile(join(seqDir, f), "utf-8"));
        const seqs = data.sequences;
        if (seqs && typeof seqs === "object") {
          for (const [seqName, seqData] of Object.entries(seqs)) {
            const sd = seqData as Record<string, unknown>;
            const maps = (sd.maps as string[]) || [];
            if (maps.length > 0) result[seqName] = maps;
          }
        }
      } catch { /* skip bad files */ }
    }
  } catch { /* no sequences dir */ }
  return result;
}

function findSequenceForMap(map: string, seqMap: Record<string, string[]>): string | null {
  for (const [seq, maps] of Object.entries(seqMap)) {
    if (maps.includes(map)) return seq;
  }
  return null;
}

// ─── GET /api/knowledge ────────────────────────────────────
// Unified knowledge endpoint:
//   ?scope=all          Everything (ontology + maps)
//   ?scope=ontology     Just primitive ontology (LOD 1 glance)
//   ?scope=maps         Just map texts
//   ?sequence=primitives Filter maps by sequence
//   ?map=Point_One      Single map's texts
//   ?search=text        Search across everything
//   ?lod=blurb          For maps: just blurbs (fast). Also: intent, full

export async function GET(request: NextRequest) {
  const researchPath = getResearchPath();
  const { searchParams } = new URL(request.url);
  const scope = searchParams.get("scope") || "all";
  const filterSeq = searchParams.get("sequence");
  const filterMap = searchParams.get("map");
  const search = searchParams.get("search")?.toLowerCase();
  const mapLod = searchParams.get("lod") || "blurb"; // blurb | intent | full

  const response: Partial<KnowledgeResponse> = {};

  // ── Ontology ──
  if (scope === "all" || scope === "ontology") {
    const ontologyDir = join(researchPath, "doc", "ontology");
    try {
      const indexRaw = await readFile(join(ontologyDir, "index.json"), "utf-8");
      const indexData = JSON.parse(indexRaw);
      const entries: OntologyGlance[] = [];

      for (const entry of indexData.entries) {
        // Read file for insight field
        let insight = "";
        try {
          const filePath = join(ontologyDir, entry.file as string);
          const raw = await readFile(filePath, "utf-8");
          const { meta } = parseFrontmatter(raw);
          insight = (meta.insight as string) || "";
        } catch { /* skip */ }

        const glance: OntologyGlance = {
          primitive: entry.primitive || "",
          title: entry.title || "",
          lens: entry.lens || "",
          question: entry.question || "",
          insight,
          sequence: entry.sequence || "",
          phase: entry.phase || "",
        };

        if (search) {
          const hay = `${glance.title} ${glance.lens} ${glance.question} ${glance.insight} ${glance.primitive}`.toLowerCase();
          if (!hay.includes(search)) continue;
        }

        entries.push(glance);
      }

      if (filterSeq) {
        response.ontology = entries.filter(e => e.sequence === filterSeq);
      } else {
        response.ontology = entries;
      }
    } catch {
      response.ontology = [];
    }
  }

  // ── Maps ──
  if (scope === "all" || scope === "maps") {
    const mapsDir = join(researchPath, "commons", "maps");
    const seqMap = await buildSequenceMap(researchPath);

    if (filterMap) {
      // Single map
      const dir = join(mapsDir, filterMap);
      const entry: MapTextEntry = {
        map: filterMap,
        sequence: findSequenceForMap(filterMap, seqMap),
        blurb: await readTextFile(dir, "blurb.md"),
        intent: mapLod !== "blurb" ? await readTextFile(dir, "intent.md") : null,
        technical: mapLod === "full" ? await readTextFile(dir, "technical.md") : null,
        critical: mapLod === "full" ? await readTextFile(dir, "critical.md") : null,
        summary: mapLod === "full" ? await readTextFile(dir, "summary.md") : null,
      };
      response.maps = [entry];
    } else {
      // All maps (or filtered by sequence)
      let mapNames: string[] = [];

      if (filterSeq && seqMap[filterSeq]) {
        mapNames = seqMap[filterSeq];
      } else {
        try {
          const dirs = await readdir(mapsDir);
          for (const d of dirs) {
            if (d === "sequences") continue;
            const s = await stat(join(mapsDir, d)).catch(() => null);
            if (s?.isDirectory()) mapNames.push(d);
          }
        } catch { /* skip */ }
      }

      const entries: MapTextEntry[] = [];
      for (const mapName of mapNames) {
        const dir = join(mapsDir, mapName);
        const blurb = await readTextFile(dir, "blurb.md");

        if (search && blurb) {
          if (!blurb.toLowerCase().includes(search) && !mapName.toLowerCase().includes(search)) {
            continue;
          }
        }

        entries.push({
          map: mapName,
          sequence: findSequenceForMap(mapName, seqMap),
          blurb,
          intent: mapLod !== "blurb" ? await readTextFile(dir, "intent.md") : null,
          technical: null,
          critical: null,
          summary: null,
        });
      }
      response.maps = entries;
    }

    if (scope === "all") {
      response.sequences = seqMap;
    }
  }

  return NextResponse.json(response);
}
