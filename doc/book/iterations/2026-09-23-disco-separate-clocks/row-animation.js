
const rowView = document.getElementById('row-frame');
const rowLabel = document.getElementById('row-label');
const rowPlay = document.getElementById('row-play');
let rowIndex = 0, rowTimer = null;
function stopRows() { clearInterval(rowTimer); rowTimer = null; rowPlay.textContent = 'Play the twelve states'; }
rowPlay.addEventListener('click', () => {
  if (rowTimer !== null) { stopRows(); return; }
  for (let i = 0; i < 12; i++) { const im = new Image(); im.src = 'rows-' + String(i).padStart(2, '0') + '.png'; }
  rowPlay.textContent = 'Pause';
  rowTimer = setInterval(() => {
    rowIndex = (rowIndex + 1) % 12;
    rowView.src = 'rows-' + String(rowIndex).padStart(2, '0') + '.png';
    rowView.alt = 'Native floor, held ROWS phase ' + rowIndex;
    rowLabel.textContent = 'ROWS / phase ' + rowIndex + ' / row index ' + rowIndex;
  }, 750);
});
document.getElementById('row-animation').addEventListener('toggle', event => { if (!event.target.open) stopRows(); });
document.addEventListener('visibilitychange', () => { if (document.hidden) stopRows(); });
