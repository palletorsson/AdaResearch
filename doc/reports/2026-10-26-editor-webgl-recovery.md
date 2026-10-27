# Lab editor / unavailable WebGL recovery

The reported failure occurs while creating the browser graphics context, before a floor is rendered: `GL_VENDOR = Disabled`, `GL_RENDERER = Disabled`, `BindToCurrentSequence failed`. Browser process diagnostics also showed recent GPU-process crashes. The patch treats graphics availability as a recoverable viewport failure rather than an uncaught React effect exception; it does not change driver settings or pretend to enable a disabled browser GPU.

Web application changes in the sibling `ada_encyclopedia` repository:

- `webgl-renderer.ts` creates a WebGL 2 context on the renderer's own canvas, retries without MSAA, reports creation failure before constructing Three's renderer and releases both renderer resources and the context slot on disposal. The unnecessary preserved drawing buffer is disabled.
- `void-scene.ts` pauses rendering and interaction on context loss, handles restoration and resumes rendering. Disposing a view releases its WebGL slot.
- `VoidEditor.tsx` catches startup failure and keeps the object list, coordinate editor, draft, history and save controls alive. Retry reconstructs the viewport and replays the current floor, selection, lighting, overlays and tools without replacing the user's document. Context loss shows the same recovery card.
- `BodyFutures.tsx` uses the same creation/disposal helper and handles its secondary preview failure without losing its archive or controls. Its retry control remains interactive over the preview caption.

`tools/check_editor_webgl.cjs` runs an isolated Chrome browser against the actual editor. It deliberately blocks WebGL, selects a real floor-5 part and edits its coordinate through the normal controls; save requests are intercepted, never sent to the shared layout. It then enables graphics and retries, verifies the same edit and selection survive, exercises actual `WEBGL_lose_context` loss/restoration, tests disposal of a live context and checks the secondary body preview's failure/retry. Eight checks pass, with no uncaught page errors and no shared layout changes. The recovered viewport renders the real floor models. Evidence is copied into `doc/ports/2026-10-26-editor-webgl/`.

The full repository TypeScript check still reports unrelated errors in existing course-progress, fractal and other sources. No diagnostics name the four changed TS/TSX files. The running Next editor compiled and passed the browser tests.

The affected browser process may still need restarting if it continues to report graphics disabled. Automatic approval review rejected launching a separate recovery browser window, including a normal launch, with only `blocked by policy` as its stated reason. No existing browser process was stopped or restarted, and no debug-enabled recovery browser was launched.
