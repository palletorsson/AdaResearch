# Dismiss the unavailable-graphics notice

The earlier recovery card only disappeared after a successful graphics retry or context restoration. It did not provide a close action, and Show floor objects left the card open. This was confusing while the separate layout request was still loading.

The card now closes with its × button, Continue without 3D, Escape, or Show floor objects. A compact status strip remains above the viewport with Retry and Graphics details. Dismissal does not claim graphics recovery or reset the draft, selection, layout or save queue. Graphics details reopens the card deliberately. The paused viewport also says `3D preview paused`, rather than suggesting that geometry is still downloading. The card distinguishes a pending layout request from a loaded document.

The actual layout API returned HTTP 200 in about three seconds and the model manifest returned HTTP 200. An isolated floor-16 browser test deliberately holds the layout request pending while WebGL is disabled. All four dismissal actions work before layout loading completes. Releasing the request populates the object list; coordinate editing, graphics retry, real context loss/restoration and old-context disposal then pass. Test save requests are intercepted; the shared room file hash remains unchanged. Nine scoped checks pass, without uncaught page errors.

Evidence: `doc/ports/2026-10-26-editor-notice-dismissal/`. Test: `tools/check_editor_webgl.cjs`. The optional `--body` check covers the separate body-archive trial; an initial broad run timed out waiting for that unrelated trial's preview, and this follow-up makes no new acceptance claim for it. No body-archive source was changed in this follow-up.
