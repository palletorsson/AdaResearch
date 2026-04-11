import { NextRequest, NextResponse } from "next/server";
import { readFile } from "fs/promises";
import { join } from "path";

function getResearchPath(): string {
  return (
    process.env.ADA_RESEARCH_PATH ||
    "C:/Users/palle/Documents/GitHub/AdaResearch_46"
  );
}

/** Parse YAML frontmatter between --- delimiters. No external deps. */
function parseFrontmatter(raw: string): {
  meta: Record<string, unknown>;
  content: string;
} {
  const match = raw.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n([\s\S]*)$/);
  if (!match) return { meta: {}, content: raw };

  const yamlBlock = match[1];
  const content = match[2];
  const meta: Record<string, unknown> = {};

  for (const line of yamlBlock.split(/\r?\n/)) {
    if (!line.trim()) continue;
    const colonIdx = line.indexOf(":");
    if (colonIdx === -1) continue;

    const key = line.slice(0, colonIdx).trim();
    let value: unknown = line.slice(colonIdx + 1).trim();

    // Remove surrounding quotes
    if (
      typeof value === "string" &&
      value.startsWith('"') &&
      value.endsWith('"')
    ) {
      value = (value as string).slice(1, -1);
    }

    // Parse arrays: [a, b, c]
    if (
      typeof value === "string" &&
      value.startsWith("[") &&
      value.endsWith("]")
    ) {
      value = (value as string)
        .slice(1, -1)
        .split(",")
        .map((s) => s.trim().replace(/^["']|["']$/g, ""))
        .filter(Boolean);
    }

    // Parse null
    if (value === "null" || value === "") {
      value = null;
    }

    meta[key] = value;
  }

  return { meta, content };
}

/** Extract a specific ## section from markdown content */
function extractSection(content: string, heading: string): string {
  // Split by ## headings, find the one we want
  const sections = content.split(/^## /m);
  for (const section of sections) {
    if (section.startsWith(heading)) {
      // Remove the heading line itself
      const lines = section.split("\n");
      return lines.slice(1).join("\n").trim();
    }
  }
  return "";
}

// ─── LOD Levels ──────────────────────────────────────────────
// 0 = glance:  primitive, lens, question (one line per entry)
// 1 = card:    + insight, qfep, tags, connections list
// 2 = full:    + discussion, open questions, QFEP section
// 3 = deep:    + connections prose, raw markdown, everything

interface OntologyEntryLOD0 {
  primitive: string;
  title: string;
  sequence: string;
  phase: string;
  lens: string;
  question: string;
  web_editor: string | null;
}

interface OntologyEntryLOD1 extends OntologyEntryLOD0 {
  insight: string;
  qfep: string;
  tags: string[];
  connections: string[];
  status?: string;
  godot_infoboard?: string | null;
}

interface OntologyEntryLOD2 extends OntologyEntryLOD1 {
  discussion: string;
  open_questions: string;
  qfep_section: string;
}

interface OntologyEntryLOD3 extends OntologyEntryLOD2 {
  connections_prose: string;
  content: string; // full raw markdown
}

// GET /api/ontology
// Query params:
//   ?lod=0|1|2|3      Level of detail (default: 2)
//   ?primitive=point   Filter by primitive name
//   ?sequence=primitives  Filter by sequence
//   ?phase=F_order     Filter by QFEP phase
//   ?search=text       Full-text search across title, lens, question, insight, tags
export async function GET(request: NextRequest) {
  const researchPath = getResearchPath();
  const ontologyDir = join(researchPath, "doc", "ontology");

  // Read index
  let indexData: {
    phases: Record<string, { name: string; description: string }>;
    entries: Array<Record<string, unknown>>;
  };
  try {
    const indexRaw = await readFile(join(ontologyDir, "index.json"), "utf-8");
    indexData = JSON.parse(indexRaw);
  } catch {
    return NextResponse.json(
      { error: "Could not read ontology index.json" },
      { status: 500 }
    );
  }

  const { searchParams } = new URL(request.url);
  const lod = Math.min(3, Math.max(0, parseInt(searchParams.get("lod") || "2", 10)));
  const filterPrimitive = searchParams.get("primitive");
  const filterSequence = searchParams.get("sequence");
  const filterPhase = searchParams.get("phase");
  const searchQuery = searchParams.get("search")?.toLowerCase();

  // Filter entries from index
  let entries = indexData.entries;
  if (filterPrimitive) {
    entries = entries.filter((e) => e.primitive === filterPrimitive);
  }
  if (filterSequence) {
    entries = entries.filter((e) => e.sequence === filterSequence);
  }
  if (filterPhase) {
    entries = entries.filter((e) => e.phase === filterPhase);
  }

  const results: Record<string, unknown>[] = [];

  for (const entry of entries) {
    // LOD 0: just index data, no file read needed
    const base: OntologyEntryLOD0 = {
      primitive: (entry.primitive as string) || "",
      title: (entry.title as string) || "",
      sequence: (entry.sequence as string) || "",
      phase: (entry.phase as string) || "",
      lens: (entry.lens as string) || "",
      question: (entry.question as string) || "",
      web_editor: (entry.web_editor as string | null) ?? null,
    };

    if (lod === 0) {
      // Search filter for LOD 0
      if (searchQuery) {
        const haystack = `${base.title} ${base.lens} ${base.question} ${base.primitive}`.toLowerCase();
        if (!haystack.includes(searchQuery)) continue;
      }
      results.push(base);
      continue;
    }

    // LOD 1+: need to read the file for insight, qfep, connections
    const filePath = join(ontologyDir, entry.file as string);
    let fileContent = "";
    let meta: Record<string, unknown> = {};
    let content = "";

    try {
      fileContent = await readFile(filePath, "utf-8");
      const parsed = parseFrontmatter(fileContent);
      meta = parsed.meta;
      content = parsed.content;
    } catch {
      // File missing — use index metadata only
    }

    const lod1: OntologyEntryLOD1 = {
      ...base,
      insight: (meta.insight as string) || "",
      qfep: (meta.qfep as string) || "",
      tags: (entry.tags as string[]) || (meta.tags as string[]) || [],
      connections: (meta.connections as string[]) || [],
      status: (entry.status as string) || (meta.status as string) || undefined,
      godot_infoboard: (entry.godot_infoboard as string | null) ?? (meta.godot_infoboard as string | null) ?? undefined,
    };

    // Search filter
    if (searchQuery) {
      const haystack = `${lod1.title} ${lod1.lens} ${lod1.question} ${lod1.insight} ${lod1.tags.join(" ")} ${lod1.primitive}`.toLowerCase();
      if (!haystack.includes(searchQuery)) continue;
    }

    if (lod === 1) {
      results.push(lod1);
      continue;
    }

    // LOD 2: extract structured sections
    const lod2: OntologyEntryLOD2 = {
      ...lod1,
      discussion: extractSection(content, "Discussion"),
      open_questions: extractSection(content, "Open Questions"),
      qfep_section: extractSection(content, "QFEP Connection"),
    };

    if (lod === 2) {
      results.push(lod2);
      continue;
    }

    // LOD 3: everything
    const lod3: OntologyEntryLOD3 = {
      ...lod2,
      connections_prose: extractSection(content, "Connections"),
      content,
    };
    results.push(lod3);
  }

  return NextResponse.json({
    lod,
    count: results.length,
    phases: indexData.phases,
    entries: results,
  });
}
