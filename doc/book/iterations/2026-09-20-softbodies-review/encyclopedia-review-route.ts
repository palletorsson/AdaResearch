/** Read-only HTTP access to the book comparison and its local evidence. */
import fs from "node:fs/promises";
import path from "node:path";
import { getRepoPath } from "@/lib/ada-repo/config";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const INDEX = "doc/book/iterations/2026-09-19-review-comparison/index.html";
const TYPES: Record<string, string> = {
  ".html": "text/html; charset=utf-8",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".svg": "image/svg+xml",
  ".md": "text/plain; charset=utf-8",
  ".diff": "text/plain; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".txt": "text/plain; charset=utf-8",
};

export async function GET(
  request: Request,
  context: { params: Promise<{ path?: string[] }> },
) {
  const parts = (await context.params).path || [];
  if (!parts.length) {
    // Browsers retain the incoming section fragment through this redirect.
    return Response.redirect(new URL(`/book-review/${INDEX}`, request.url), 307);
  }
  if (parts.some(p => !p || p === "." || p === ".." || /[\\:\x00-\x1f]/.test(p))) {
    return new Response("Not found", { status: 404 });
  }
  const relative = parts.join("/");
  const evidence = relative.startsWith("doc/book/iterations/");
  const manuscript = /^commons\/maps\/[^/]+\/final\.md$/.test(relative);
  const type = TYPES[path.extname(relative).toLowerCase()];
  if ((!evidence && !manuscript) || !type) {
    return new Response("Not found", { status: 404 });
  }
  try {
    const root = await fs.realpath(getRepoPath());
    const file = await fs.realpath(path.join(root, ...parts));
    const inside = path.relative(root, file).replaceAll("\\", "/");
    // Also reject symlinks/junctions that leave the allowed content roots.
    if (path.isAbsolute(inside) || inside.startsWith("../") ||
        (evidence && !inside.startsWith("doc/book/iterations/")) ||
        (manuscript && !/^commons\/maps\/[^/]+\/final\.md$/.test(inside))) {
      return new Response("Not found", { status: 404 });
    }
    const data = await fs.readFile(file);
    return new Response(new Uint8Array(data), {
      headers: {
        "Content-Type": type,
        "Cache-Control": "no-store",
        "X-Content-Type-Options": "nosniff",
        "Content-Security-Policy": "default-src 'none'; img-src 'self' data:; style-src 'unsafe-inline'; base-uri 'none'; frame-ancestors 'self'",
      },
    });
  } catch (error) {
    const code = (error as NodeJS.ErrnoException).code;
    if (code === "ENOENT" || code === "ENOTDIR" || code === "EISDIR") {
      return new Response("Not found", { status: 404 });
    }
    return new Response("Review files are temporarily unavailable", { status: 503 });
  }
}
