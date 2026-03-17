import { NextRequest, NextResponse } from "next/server";
import { readFile, writeFile, mkdir } from "fs/promises";
import { join } from "path";

function getResearchPath(): string | null {
  return process.env.ADA_RESEARCH_PATH || null;
}

export async function GET() {
  const researchPath = getResearchPath();
  if (!researchPath) {
    return NextResponse.json(
      { error: "ADA_RESEARCH_PATH not configured" },
      { status: 500 }
    );
  }

  const reportPath = join(researchPath, "ada_run", "narrations", "narration_report.json");

  try {
    const contents = await readFile(reportPath, "utf-8");
    const data = JSON.parse(contents);
    return NextResponse.json(data);
  } catch (err: unknown) {
    if (err instanceof Error && "code" in err && (err as NodeJS.ErrnoException).code === "ENOENT") {
      return NextResponse.json(
        { error: "No narration report found" },
        { status: 404 }
      );
    }
    return NextResponse.json(
      { error: "Failed to read narration report" },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  const researchPath = getResearchPath();
  if (!researchPath) {
    return NextResponse.json(
      { error: "ADA_RESEARCH_PATH not configured" },
      { status: 500 }
    );
  }

  try {
    const body = await request.json();
    const { proposals } = body;

    if (!Array.isArray(proposals)) {
      return NextResponse.json(
        { error: "Invalid request: proposals must be an array" },
        { status: 400 }
      );
    }

    const narrationDir = join(researchPath, "ada_run", "narrations");
    await mkdir(narrationDir, { recursive: true });

    const outputPath = join(narrationDir, "improvement_proposals.json");
    await writeFile(outputPath, JSON.stringify(proposals, null, 2), "utf-8");

    return NextResponse.json({ success: true, count: proposals.length });
  } catch {
    return NextResponse.json(
      { error: "Failed to save improvement proposals" },
      { status: 500 }
    );
  }
}
