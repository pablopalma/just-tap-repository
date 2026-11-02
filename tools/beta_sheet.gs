/**
 * Just Tap beta: receives the game's play data and writes one row per event in the sheet
 * "events". Paste into the sheet's Extensions → Apps Script and deploy as a web app
 * (docs/beta-datos.md). The game sends {uid, sid, v, plat, lang, ev: [{e, t, n, d, at}]} as text.
 */
const SHEET = 'events';
// 'time' (last, so older rows stay aligned): when the event happened on the player's side, to the
// second; builds before it send no "at" and get the arrival time instead.
const COLUMNS = ['received', 'uid', 'session', 'version', 'platform', 'lang', 't', 'event', 'barrier', 'data', 'time'];
const MAX_EVENTS = 300;

function doPost(e) {
  let body;
  try {
    body = JSON.parse(e.postData.contents);
  } catch (err) {
    return ContentService.createTextOutput('bad json');
  }
  if (!body || typeof body.uid !== 'string' || body.uid.length > 40 || !Array.isArray(body.ev)) {
    return ContentService.createTextOutput('bad body');
  }
  const lock = LockService.getScriptLock();
  lock.waitLock(10000);
  try {
    const book = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = book.getSheetByName(SHEET) || book.insertSheet(SHEET);
    if (sheet.getLastRow() === 0) {
      sheet.appendRow(COLUMNS);
      sheet.setFrozenRows(1);
    } else if (sheet.getRange(1, COLUMNS.length).getValue() === '') {
      sheet.getRange(1, COLUMNS.length).setValue(COLUMNS[COLUMNS.length - 1]);  // a sheet from before 'time'
    }
    const now = new Date();
    const short = (v) => String(v === undefined ? '' : v).slice(0, 40);
    const rows = body.ev.slice(0, MAX_EVENTS).map((x) => [
      now, short(body.uid), short(body.sid), short(body.v), short(body.plat), short(body.lang),
      Number(x.t) || 0, short(x.e), Number(x.n) || 0, JSON.stringify(x.d || {}).slice(0, 500),
      x.at ? new Date(Number(x.at) * 1000) : now,
    ]);
    if (rows.length) {
      sheet.getRange(sheet.getLastRow() + 1, 1, rows.length, COLUMNS.length).setValues(rows);
    }
  } finally {
    lock.releaseLock();
  }
  return ContentService.createTextOutput('ok');
}

/** Opening the URL in a browser shows this: a quick way to check the deployment works. */
function doGet() {
  return ContentService.createTextOutput('Just Tap beta data endpoint: ok');
}
