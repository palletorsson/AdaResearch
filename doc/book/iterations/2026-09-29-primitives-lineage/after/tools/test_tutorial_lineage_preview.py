"""Isolated headless preview tests; no connection to the user's browser profile."""
import base64,json,os,subprocess,tempfile,time
from pathlib import Path
from urllib.request import urlopen
import websocket
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-09-29-tutorial-lineage'
EXPECTED_CAPABILITIES=len(json.loads((ROOT/'doc/book/tutorial-lineage/curriculum.json').read_text(encoding='utf-8-sig'))['nodes'])
profile=Path(tempfile.mkdtemp(prefix='ada-lineage-preview-')).resolve()
assert profile.is_relative_to(Path(tempfile.gettempdir()).resolve())
proc=subprocess.Popen(['C:/Program Files/Google/Chrome/Application/chrome.exe','--headless=new','--disable-gpu','--no-first-run','--no-default-browser-check','--disable-background-networking','--disable-sync','--remote-debugging-port=0','--user-data-dir='+str(profile),'about:blank'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,creationflags=subprocess.CREATE_NO_WINDOW)
checks=[];ws=None;counter=0
try:
    for _ in range(120):
        f=profile/'DevToolsActivePort'
        if f.exists():break
        time.sleep(.1)
    port=int(f.read_text().splitlines()[0])
    tabs=json.load(urlopen('http://127.0.0.1:'+str(port)+'/json/list'))
    tab=next(t for t in tabs if t['type']=='page')
    ws=websocket.create_connection(tab['webSocketDebuggerUrl'],timeout=20,suppress_origin=True)
    def call(method,params=None):
        global counter
        counter+=1;id=counter;ws.send(json.dumps(dict(id=id,method=method,params=params or {})))
        while True:
            msg=json.loads(ws.recv())
            if msg.get('id')==id:
                if 'error' in msg:raise RuntimeError(msg['error'])
                return msg.get('result',{})
    def evaluate(code):
        r=call('Runtime.evaluate',dict(expression=code,returnByValue=True,awaitPromise=True))
        if 'exceptionDetails' in r:raise RuntimeError(r['exceptionDetails'])
        return r.get('result',{}).get('value')
    def check(name,code):
        result=evaluate(code)
        if result is not True: print(json.dumps(evaluate('({title:document.title,body:document.body.innerText.slice(0,2400),data:typeof DATA})')))
        assert result is True,(name,result)
        checks.append(dict(name=name,passed=True))
    call('Page.enable');call('Runtime.enable')
    call('Emulation.setDeviceMetricsOverride',dict(width=1500,height=1050,deviceScaleFactor=1,mobile=False))
    url='http://127.0.0.1:3003/tutorial-lineage'
    call('Page.navigate',dict(url=url))
    for _ in range(100):
        if evaluate('Boolean(document.querySelector("#stats")?.textContent.includes("204"))'):break
        time.sleep(.1)
    check('Counts and default selection',f'document.querySelector("#stats").textContent.includes("{EXPECTED_CAPABILITIES}") && document.querySelector("#detail h2").textContent === "Give a position a body"')
    check('All configured tree targets render',f'document.querySelectorAll("#outline .node").length === {EXPECTED_CAPABILITIES}')
    check('Select a dependency','document.querySelector("#detail [data-node=loop]").click(); document.querySelector("#detail h2").textContent === "Begin once, continue"')
    check('Coordinates owns the held point','document.querySelector("#outline [data-node=coordinates]").click(); document.querySelector("#detail h2").textContent === "Hold a point, name its reference" && document.querySelector("#detail [data-hall=Point_Coordinates]") !== null')
    check('Narrow to the selected branch',f'document.querySelector("#focus").click(); document.querySelectorAll("#outline .tree-row:not(.ancestor)").length < {EXPECTED_CAPABILITIES} && document.querySelector("#outline [data-node=line]") !== null')
    check('Reset restores all capabilities',f'document.querySelector("#reset").click(); document.querySelectorAll("#outline .node").length === {EXPECTED_CAPABILITIES}')
    check('Walk includes all halls','document.querySelector("[data-view=walk]").click(); document.querySelectorAll("#outline .hall").length === 204')
    check('Sequence filter contains eight CA halls','document.querySelector("#sequence").value="cellularautomata"; document.querySelector("#sequence").dispatchEvent(new Event("change")); document.querySelectorAll("#outline .hall").length === 8')
    check('Hall source links resolve to captured files','document.querySelector("#outline [data-hall=CA_BeyondBinary]").click(); Array.from(document.querySelectorAll("#detail a")).some(a=>a.getAttribute("href")==="sources/CA_BeyondBinary.html#tutorial")')
    check('Search can locate a single hall','document.querySelector("#reset").click(); document.querySelector("#search").value="Point_One"; document.querySelector("#search").dispatchEvent(new Event("input")); document.querySelectorAll("#outline .hall").length === 1')
    check('Gaps include source-conflict evidence','document.querySelector("#reset").click(); document.querySelector("[data-view=gaps]").click(); document.querySelector("#outline").textContent.includes("ln(N)") && document.querySelectorAll("#outline .issue").length===11')
    check('Missing lessons are explicitly an inventory','document.querySelector("#outline").textContent.includes("12 active halls")')
    evaluate('document.querySelector("[data-view=tree]").click(); document.querySelector("#outline [data-node=point]").click(); document.querySelector("#outline").scrollTop=0; window.scrollTo(0,0)')
    check('Desktop has no page-width overflow','document.documentElement.scrollWidth <= innerWidth')
    image=call('Page.captureScreenshot',dict(format='png'))
    (OUT/'atlas-desktop.png').write_bytes(base64.b64decode(image['data']))
    call('Emulation.setDeviceMetricsOverride',dict(width=390,height=844,deviceScaleFactor=1,mobile=True))
    evaluate('window.scrollTo(0,0)')
    check('Mobile has no page-width overflow','document.documentElement.scrollWidth <= innerWidth')
    image=call('Page.captureScreenshot',dict(format='png'))
    (OUT/'atlas-mobile.png').write_bytes(base64.b64decode(image['data']))
    call('Page.navigate',dict(url=url+'#hall=Point_One'))
    for _ in range(100):
        if evaluate('document.querySelector("#detail h2")?.textContent === "Point One"'):break
        time.sleep(.1)
    check('Direct hall link opens the correct detail','document.querySelector("#detail h2").textContent === "Point One"')
    (OUT/'browser-verification.json').write_text(json.dumps(dict(passed=True,checks=checks,scope='Isolated headless Chromium UI verification; not the in-app browser, no museum runtime or headset test.'),indent=2),encoding='utf-8')
    print(json.dumps(dict(passed=True,checks=len(checks))))
finally:
    if ws:
        try:call('Browser.close')
        except Exception:pass
        ws.close()
    try:proc.wait(timeout=5)
    except subprocess.TimeoutExpired:proc.terminate()
