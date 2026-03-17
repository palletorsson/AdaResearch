import { NextRequest, NextResponse } from "next/server";
import { readFile } from "fs/promises";
import { join } from "path";

function getResearchPath(): string | null {
  return process.env.ADA_RESEARCH_PATH || null;
}

// GET /api/game/narration?sequence=primitives&map=Point_One
// Returns per-map narration data (spatial + journey + walkthrough)
export async function GET(request: NextRequest) {
  const researchPath = getResearchPath();
  if (!researchPath) {
    return NextResponse.json(
      { error: "ADA_RESEARCH_PATH not configured" },
      { status: 500 }
    );
  }

  const { searchParams } = new URL(request.url);
  const sequence = searchParams.get("sequence");
  const map = searchParams.get("map");

  if (!sequence || !map) {
    return NextResponse.json(
      { error: "Both 'sequence' and 'map' query params required" },
      { status: 400 }
    );
  }

  // Sanitize inputs to prevent path traversal
  const safeSeq = sequence.replace(/[^a-zA-Z0-9_-]/g, "");
  const safeMap = map.replace(/[^a-zA-Z0-9_-]/g, "");

  const narrationPath = join(
    researchPath,
    "ada_run",
    "narrations",
    safeSeq,
    safeMap,
    "narration.json"
  );

  try {
    const contents = await readFile(narrationPath, "utf-8");
    const data = JSON.parse(contents);
    return NextResponse.json(data);
  } catch (err: unknown) {
    if (
      err instanceof Error &&
      "code" in err &&
      (err as NodeJS.ErrnoException).code === "ENOENT"
    ) {
      return NextResponse.json(
        { error: `No narration found for ${safeSeq}/${safeMap}` },
        { status: 404 }
      );
    }
    return NextResponse.json(
      { error: "Failed to read narration data" },
      { status: 500 }
    );
  }
}
