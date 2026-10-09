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
  ".mp3": "audio/mpeg",
  ".wav": "audio/wav",
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
  const figure = relative.startsWith("doc/book/figures/");
  const manuscript = /^commons\/maps\/[^/]+\/final\.md$/.test(relative);
  const type = TYPES[path.extname(relative).toLowerCase()];
  if ((!evidence && !figure && !manuscript) || !type) {
    return new Response("Not found", { status: 404 });
  }
  try {
    const root = await fs.realpath(getRepoPath());
    const file = await fs.realpath(path.join(root, ...parts));
    const inside = path.relative(root, file).replaceAll("\\", "/");
    // Also reject symlinks/junctions that leave the allowed content roots.
    if (path.isAbsolute(inside) || inside.startsWith("../") ||
        (evidence && !inside.startsWith("doc/book/iterations/")) ||
        (figure && !inside.startsWith("doc/book/figures/")) ||
        (manuscript && !/^commons\/maps\/[^/]+\/final\.md$/.test(inside))) {
      return new Response("Not found", { status: 404 });
    }
    const data = await fs.readFile(file);
    const headers: Record<string, string> = {
      "Content-Type": type,
      "Content-Length": String(data.length),
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff",
      "Content-Security-Policy": "default-src 'none'; img-src 'self' data:; media-src 'self'; style-src 'unsafe-inline'; base-uri 'none'; frame-ancestors 'self'",
    };
    if (type.startsWith("audio/")) {
      headers["Accept-Ranges"] = "bytes";
      const range = request.headers.get("range");
      // Native audio players use byte ranges for seeking. Ignore multipart ranges.
      if (range && !range.includes(",")) {
        const match = /^bytes=(\d*)-(\d*)$/.exec(range);
        let start = 0;
        let end = data.length - 1;
        let valid = !!match && !!(match[1] || match[2]);
        if (match && valid) {
          if (!match[1]) {
            const suffix = Number(match[2]);
            valid = Number.isSafeInteger(suffix) && suffix > 0;
            start = Math.max(0, data.length - suffix);
          } else {
            start = Number(match[1]);
            const requestedEnd = match[2] ? Number(match[2]) : end;
            valid = Number.isSafeInteger(start) && Number.isSafeInteger(requestedEnd);
            end = Math.min(requestedEnd, end);
          }
          valid = valid && start <= end && start < data.length;
        }
        if (!valid) {
          return new Response(null, { status: 416, headers: {
            ...headers, "Content-Length": "0", "Content-Range": `bytes */${data.length}`,
          } });
        }
        return new Response(new Uint8Array(data.subarray(start, end + 1)), {
          status: 206,
          headers: { ...headers, "Content-Length": String(end - start + 1),
            "Content-Range": `bytes ${start}-${end}/${data.length}` },
        });
      }
    }
    return new Response(new Uint8Array(data), { headers });
  } catch (error) {
    const code = (error as NodeJS.ErrnoException).code;
    if (code === "ENOENT" || code === "ENOTDIR" || code === "EISDIR") {
      return new Response("Not found", { status: 404 });
    }
    return new Response("Review files are temporarily unavailable", { status: 503 });
  }
}
