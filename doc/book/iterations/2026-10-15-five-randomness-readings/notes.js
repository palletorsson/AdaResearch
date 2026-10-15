const storageKey = 'ada-reading-notes:Random_Definition:five-readings-2026-10-15';
const status = document.getElementById('save-status');
let notes = [];
try { notes = JSON.parse(localStorage.getItem(storageKey) || '[]'); if (!Array.isArray(notes)) notes = []; }
catch { status.textContent = 'Saved notes could not be read. Export any new notes before leaving.'; }
const draft = new URLSearchParams(location.search).get('draft');
if (draft && /^[a-e]$/.test(draft)) document.getElementById('origin').value = `Draft ${draft.toUpperCase()}`;
function persist() {
  try { localStorage.setItem(storageKey, JSON.stringify(notes)); status.textContent = 'Saved in this browser. Export to hand over.'; }
  catch { status.textContent = 'Browser storage is unavailable. Export these notes before leaving.'; }
}
function display() {
  const host = document.getElementById('saved-notes'); host.replaceChildren();
  for (const note of notes) {
    const card = document.createElement('article'); card.className = 'saved-note';
    const heading = document.createElement('h3'); heading.textContent = `${note.origin} · ${note.kind}`;
    const quote = document.createElement('blockquote'); quote.textContent = note.detail;
    const meaning = document.createElement('p'); meaning.textContent = note.reason;
    const remove = document.createElement('button'); remove.type = 'button'; remove.textContent = 'Remove this note';
    remove.addEventListener('click', () => { notes = notes.filter(item => item.id !== note.id); persist(); display(); });
    card.append(heading, quote, meaning, remove); host.append(card);
  }
}
document.getElementById('idea-form').addEventListener('submit', event => {
  event.preventDefault();
  const origin = document.getElementById('origin').value.trim();
  const detail = document.getElementById('quote').value.trim();
  const reason = document.getElementById('meaning').value.trim();
  if (!origin || !detail || !reason) { status.textContent = 'Add a source, detail and reason before saving.'; return; }
  notes.push({id:crypto.randomUUID(),created_at:new Date().toISOString(),map:'Random_Definition',status:'unreviewed',origin,kind:document.getElementById('kind').value,detail,reason});
  persist(); display(); document.getElementById('quote').value = ''; document.getElementById('meaning').value = '';
});
document.getElementById('export').addEventListener('click', () => {
  const blob = new Blob([JSON.stringify({schema:'ada-reading-notes/1',map:'Random_Definition',experiment:'2026-10-15-five-randomness-readings',notes},null,2)],{type:'application/json'});
  const url = URL.createObjectURL(blob); const link = document.createElement('a'); link.href = url; link.download = 'Random_Definition-reading-notes.json'; link.click(); setTimeout(() => URL.revokeObjectURL(url),1000);
});
display();
