"""Principinės domkratų schemos (inline SVG), naudojamos HTML ir PPTX versijose.

Visos schemos piešiamos tomis pačiomis spalvomis kaip skaidrės:
grafitas (INK), saugos geltona (YEL), plieno pilka (STEEL), bronza (BRZ).
"""

INK, YEL, STEEL, PAPER, SOFT, BRZ, RUB = "#1A1C1F", "#F6B800", "#C9CBC6", "#F4F2EC", "#6B6F75", "#B5782C", "#3A3D42"
FONT = "'IBM Plex Mono', Consolas, monospace"


def _svg(w, h, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" '
            f'font-family="{FONT}" stroke-linejoin="round" stroke-linecap="round">'
            f'<defs><marker id="ah" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="5" markerHeight="5" '
            f'orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{INK}"/></marker>'
            f'<marker id="ahy" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="5" markerHeight="5" '
            f'orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{SOFT}"/></marker></defs>'
            f'{body}</svg>')


def _ground(x1, x2, y):
    hatch = "".join(f'<line x1="{x}" y1="{y}" x2="{x-10}" y2="{y+10}" stroke="{SOFT}" stroke-width="1.5"/>'
                    for x in range(x1 + 10, x2, 16))
    return f'<line x1="{x1}" y1="{y}" x2="{x2}" y2="{y}" stroke="{INK}" stroke-width="3"/>{hatch}'


def _load(x, y1, y2, label="Q"):
    return (f'<line x1="{x}" y1="{y1}" x2="{x}" y2="{y2}" stroke="{INK}" stroke-width="4" marker-end="url(#ah)"/>'
            f'<text x="{x+12}" y="{y1+20}" font-size="20" font-weight="700" fill="{INK}">{label}</text>')


def _arm(x1, y1, x2, y2, w=14, fill=YEL):
    return (f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{INK}" stroke-width="{w+5}"/>'
            f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{fill}" stroke-width="{w}"/>')


def _pin(x, y, r=7):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{PAPER}" stroke="{INK}" stroke-width="3"/>'


# ── 1. Sraigtinis ──────────────────────────────────────────────────────────
def screw():
    threads = "".join(f'<line x1="165" y1="{y}" x2="195" y2="{y-9}" stroke="{INK}" stroke-width="2"/>'
                      for y in range(78, 156, 11))
    b = (_ground(20, 340, 282)
         + f'<polygon points="105,280 255,280 232,236 128,236" fill="{STEEL}" stroke="{INK}" stroke-width="3"/>'
         + f'<rect x="143" y="150" width="74" height="88" fill="{PAPER}" stroke="{INK}" stroke-width="3"/>'
         + f'<rect x="165" y="64" width="30" height="94" fill="{YEL}" stroke="{INK}" stroke-width="3"/>' + threads
         + f'<rect x="150" y="48" width="60" height="18" fill="{INK}"/>'
         + f'<rect x="158" y="32" width="44" height="12" fill="{INK}"/>'
         + f'<line x1="208" y1="57" x2="328" y2="57" stroke="{INK}" stroke-width="7"/>'
         + f'<circle cx="330" cy="57" r="8" fill="{YEL}" stroke="{INK}" stroke-width="3"/>'
         + f'<path d="M 300 86 A 52 15 0 0 1 248 92" fill="none" stroke="{SOFT}" stroke-width="3" marker-end="url(#ahy)"/>'
         + f'<text x="262" y="44" font-size="17" fill="{INK}">R</text>'
         + f'<line x1="200" y1="36" x2="328" y2="36" stroke="{SOFT}" stroke-width="1.5" marker-start="url(#ahy)" marker-end="url(#ahy)"/>'
         + f'<text x="226" y="128" font-size="17" fill="{INK}">p</text>'
         + f'<line x1="200" y1="111" x2="220" y2="122" stroke="{SOFT}" stroke-width="1.5"/>'
         + _load(180, 0, 28))
    return _svg(360, 300, b)


# ── 2. Krumpliastiebinis ───────────────────────────────────────────────────
def rack():
    teeth = "".join(f'<polygon points="192,{y} 204,{y+7} 192,{y+14}" fill="{STEEL}" stroke="{INK}" stroke-width="2"/>'
                    for y in range(30, 250, 14))
    b = (_ground(20, 340, 282)
         + f'<rect x="125" y="266" width="110" height="14" fill="{INK}"/>'
         + f'<rect x="170" y="22" width="22" height="246" fill="{STEEL}" stroke="{INK}" stroke-width="3"/>' + teeth
         + f'<rect x="158" y="140" width="56" height="64" fill="{YEL}" stroke="{INK}" stroke-width="3"/>'
         + f'<rect x="96" y="150" width="64" height="14" fill="{INK}"/>'
         + f'<line x1="206" y1="158" x2="330" y2="70" stroke="{INK}" stroke-width="8"/>'
         + f'<circle cx="206" cy="158" r="6" fill="{PAPER}" stroke="{INK}" stroke-width="3"/>'
         + f'<path d="M 318 112 A 40 40 0 0 0 340 80" fill="none" stroke="{SOFT}" stroke-width="3" marker-start="url(#ahy)" marker-end="url(#ahy)"/>'
         + f'<line x1="208" y1="186" x2="196" y2="176" stroke="{INK}" stroke-width="4"/>'
         + _load(120, 92, 146))
    return _svg(360, 300, b)


# ── 3. Žirklinis ───────────────────────────────────────────────────────────
def scissor(theta=True):
    ticks = "".join(f'<line x1="{x}" y1="152" x2="{x+6}" y2="168" stroke="{INK}" stroke-width="1.6"/>'
                    for x in range(104, 256, 9))
    b = (_ground(20, 340, 282)
         + f'<rect x="92" y="262" width="176" height="18" fill="{STEEL}" stroke="{INK}" stroke-width="3"/>'
         + _arm(180, 258, 92, 160) + _arm(180, 258, 268, 160) + _arm(92, 160, 180, 62) + _arm(268, 160, 180, 62)
         + f'<line x1="56" y1="160" x2="300" y2="160" stroke="{INK}" stroke-width="5"/>' + ticks
         + _pin(180, 258) + _pin(92, 160) + _pin(268, 160) + _pin(180, 62)
         + f'<circle cx="52" cy="160" r="7" fill="none" stroke="{INK}" stroke-width="3"/>'
         + f'<polyline points="45,160 26,160 26,200 12,200" fill="none" stroke="{SOFT}" stroke-width="5"/>'
         + f'<rect x="148" y="40" width="64" height="18" fill="{INK}"/>'
         + f'<line x1="112" y1="132" x2="142" y2="132" stroke="{SOFT}" stroke-width="2.5" marker-end="url(#ahy)"/>'
         + f'<line x1="248" y1="132" x2="218" y2="132" stroke="{SOFT}" stroke-width="2.5" marker-end="url(#ahy)"/>'
         + (f'<path d="M 152 230 A 40 40 0 0 1 208 230" fill="none" stroke="{INK}" stroke-width="2"/>'
            f'<text x="172" y="222" font-size="17" fill="{INK}">θ</text>' if theta else '')
         + _load(180, 0, 36))
    return _svg(360, 300, b)


# ── 4. Hidraulinis butelinis ───────────────────────────────────────────────
def bottle():
    b = (_ground(20, 340, 282)
         + f'<rect x="56" y="262" width="250" height="18" fill="{STEEL}" stroke="{INK}" stroke-width="3"/>'
         + f'<rect x="160" y="112" width="104" height="150" fill="{STEEL}" stroke="{INK}" stroke-width="3"/>'
         + f'<rect x="170" y="164" width="84" height="92" fill="{YEL}"/>'
         + f'<rect x="182" y="44" width="60" height="122" fill="{PAPER}" stroke="{INK}" stroke-width="3"/>'
         + f'<rect x="176" y="32" width="72" height="12" fill="{INK}"/>'
         + f'<rect x="82" y="190" width="40" height="72" fill="{STEEL}" stroke="{INK}" stroke-width="3"/>'
         + f'<rect x="88" y="214" width="28" height="44" fill="{YEL}"/>'
         + f'<rect x="92" y="150" width="20" height="66" fill="{PAPER}" stroke="{INK}" stroke-width="3"/>'
         + f'<rect x="122" y="240" width="38" height="10" fill="{YEL}" stroke="{INK}" stroke-width="2"/>'
         + f'<circle cx="141" cy="245" r="4" fill="{INK}"/>'
         + f'<line x1="150" y1="150" x2="28" y2="104" stroke="{INK}" stroke-width="7"/>'
         + f'<circle cx="150" cy="150" r="6" fill="{PAPER}" stroke="{INK}" stroke-width="3"/>'
         + f'<line x1="36" y1="64" x2="36" y2="98" stroke="{INK}" stroke-width="4" marker-end="url(#ah)"/>'
         + f'<text x="46" y="78" font-size="18" font-weight="700" fill="{INK}">F₁</text>'
         + f'<text x="66" y="186" font-size="16" fill="{INK}">D₁</text>'
         + f'<text x="272" y="140" font-size="16" fill="{INK}">D₂</text>'
         + _load(212, 0, 28))
    return _svg(360, 300, b)


# ── 5. Vežimėlinis (garažinis) ─────────────────────────────────────────────
def trolley():
    b = (_ground(10, 350, 282)
         + f'<polygon points="36,236 300,236 300,258 36,258" fill="{STEEL}" stroke="{INK}" stroke-width="3"/>'
         + f'<circle cx="64" cy="266" r="15" fill="{INK}"/><circle cx="64" cy="266" r="5" fill="{PAPER}"/>'
         + f'<circle cx="276" cy="266" r="15" fill="{INK}"/><circle cx="276" cy="266" r="5" fill="{PAPER}"/>'
         + _arm(250, 230, 80, 150, 14)
         + f'<line x1="214" y1="232" x2="158" y2="186" stroke="{INK}" stroke-width="16"/>'
         + f'<line x1="214" y1="232" x2="182" y2="206" stroke="{SOFT}" stroke-width="9"/>'
         + _pin(250, 230) + _pin(80, 150)
         + f'<rect x="52" y="126" width="56" height="16" fill="{INK}"/>'
         + f'<line x1="290" y1="232" x2="340" y2="60" stroke="{INK}" stroke-width="7"/>'
         + f'<path d="M 316 100 A 40 40 0 0 1 346 122" fill="none" stroke="{SOFT}" stroke-width="3" marker-start="url(#ahy)" marker-end="url(#ahy)"/>'
         + _load(80, 60, 120))
    return _svg(360, 300, b)


# ── Principai: sriegis = nuožulni plokštuma; Paskalio dėsnis ───────────────
def incline():
    b = (f'<polygon points="40,250 420,250 420,120" fill="{YEL}" stroke="{INK}" stroke-width="3"/>'
         + f'<rect x="230" y="166" width="54" height="40" fill="{INK}" transform="rotate(-18.9 257 186)"/>'
         + f'<line x1="40" y1="276" x2="420" y2="276" stroke="{SOFT}" stroke-width="2" marker-start="url(#ahy)" marker-end="url(#ahy)"/>'
         + f'<text x="190" y="300" font-size="20" fill="{INK}">2πR</text>'
         + f'<line x1="446" y1="250" x2="446" y2="120" stroke="{SOFT}" stroke-width="2" marker-start="url(#ahy)" marker-end="url(#ahy)"/>'
         + f'<text x="458" y="192" font-size="20" fill="{INK}">p</text>'
         + f'<path d="M 120 250 A 80 80 0 0 0 116 224" fill="none" stroke="{INK}" stroke-width="2"/>'
         + f'<text x="128" y="238" font-size="18" fill="{INK}">ψ</text>'
         + f'<line x1="257" y1="120" x2="257" y2="166" stroke="{INK}" stroke-width="4" marker-end="url(#ah)"/>'
         + f'<text x="266" y="134" font-size="20" font-weight="700" fill="{INK}">Q</text>'
         + f'<line x1="150" y1="212" x2="220" y2="188" stroke="{INK}" stroke-width="4" marker-end="url(#ah)"/>'
         + f'<text x="150" y="196" font-size="20" font-weight="700" fill="{INK}">F</text>')
    return _svg(500, 310, b)


def pascal():
    b = (f'<path d="M 60 90 L 60 250 L 380 250 L 380 60 L 470 60 L 470 280 L 30 280 L 30 90" fill="none" stroke="{INK}" stroke-width="0"/>'
         + f'<rect x="40" y="250" width="440" height="30" fill="{YEL}" stroke="{INK}" stroke-width="3"/>'
         + f'<rect x="60" y="120" width="44" height="132" fill="{YEL}" stroke="{INK}" stroke-width="3"/>'
         + f'<rect x="300" y="160" width="160" height="92" fill="{YEL}" stroke="{INK}" stroke-width="3"/>'
         + f'<rect x="56" y="104" width="52" height="16" fill="{INK}"/>'
         + f'<rect x="296" y="144" width="168" height="16" fill="{INK}"/>'
         + f'<line x1="82" y1="40" x2="82" y2="98" stroke="{INK}" stroke-width="4" marker-end="url(#ah)"/>'
         + f'<text x="94" y="62" font-size="22" font-weight="700" fill="{INK}">F₁</text>'
         + f'<line x1="380" y1="138" x2="380" y2="60" stroke="{INK}" stroke-width="5" marker-end="url(#ah)"/>'
         + f'<text x="392" y="96" font-size="22" font-weight="700" fill="{INK}">F₂</text>'
         + f'<text x="60" y="306" font-size="18" fill="{INK}">A₁</text>'
         + f'<text x="364" y="306" font-size="18" fill="{INK}">A₂</text>'
         + f'<text x="180" y="230" font-size="18" fill="{INK}">p = const</text>')
    return _svg(500, 320, b)


# ── Patobulintas žirklinis domkratas (koncepcija) ──────────────────────────
def callout(n, x, y, tx, ty):
    return (f'<line x1="{x}" y1="{y}" x2="{tx}" y2="{ty}" stroke="{INK}" stroke-width="2"/>'
            f'<circle cx="{x}" cy="{y}" r="5" fill="{INK}"/>'
            f'<circle cx="{tx}" cy="{ty}" r="22" fill="{YEL}" stroke="{INK}" stroke-width="3"/>'
            f'<text x="{tx}" y="{ty+8}" font-size="22" font-weight="700" text-anchor="middle" fill="{INK}">{n}</text>')


def modern():
    cx, top, bot, lx, rx, my = 430, 110, 420, 270, 590, 265
    ticks = "".join(f'<line x1="{x}" y1="{my-10}" x2="{x+8}" y2="{my+10}" stroke="{INK}" stroke-width="2"/>'
                    for x in range(lx + 26, rx - 10, 12))
    b = (_ground(40, 860, 470)
         + f'<rect x="210" y="444" width="440" height="24" rx="4" fill="{RUB}"/>'
         + f'<rect x="230" y="418" width="400" height="28" fill="{STEEL}" stroke="{INK}" stroke-width="3"/>'
         + _arm(cx, bot, lx, my, 22) + _arm(cx, bot, rx, my, 22) + _arm(lx, my, cx, top, 22) + _arm(rx, my, cx, top, 22)
         + f'<line x1="{lx-40}" y1="{my}" x2="{rx+10}" y2="{my}" stroke="{INK}" stroke-width="8"/>' + ticks
         + f'<rect x="{lx-22}" y="{my-22}" width="44" height="44" rx="6" fill="{BRZ}" stroke="{INK}" stroke-width="3"/>'
         + _pin(cx, bot, 10) + _pin(rx, my, 10) + _pin(cx, top, 10)
         + f'<polygon points="{lx-62},{my-12} {lx-50},{my-20} {lx-38},{my-12} {lx-38},{my+12} {lx-50},{my+20} {lx-62},{my+12}" fill="{INK}"/>'
         + f'<rect x="{rx+10}" y="{my-38}" width="70" height="76" rx="8" fill="{SOFT}" stroke="{INK}" stroke-width="3"/>'
         + f'<rect x="{rx+80}" y="{my-50}" width="140" height="100" rx="14" fill="{INK}"/>'
         + f'<text x="{rx+150}" y="{my+12}" font-size="34" font-weight="700" text-anchor="middle" fill="{YEL}">M</text>'
         + f'<path d="M {rx+220} {my+20} C {rx+260} {my+40}, {rx+250} {my+120}, {rx+232} {my+170}" fill="none" stroke="{INK}" stroke-width="5"/>'
         + f'<rect x="{rx+214}" y="{my+168}" width="36" height="22" rx="4" fill="{YEL}" stroke="{INK}" stroke-width="3"/>'
         + f'<text x="{rx+258}" y="{my+186}" font-size="18" fill="{INK}">12 V</text>'
         + f'<rect x="{cx-48}" y="{top-34}" width="96" height="24" fill="{INK}"/>'
         + f'<rect x="{cx-18}" y="{top-12}" width="36" height="8" fill="{YEL}"/>'
         + _load(cx, 6, top - 40)
         + callout(1, rx + 150, my - 50, rx + 150, 120)
         + callout(2, rx + 45, my + 38, rx + 45, 350)
         + callout(3, 480, my + 4, 470, 330)
         + callout(4, lx, my + 22, 200, 345)
         + callout(5, 360, 342, 300, 380)
         + callout(6, 250, 456, 150, 456)
         + callout(7, lx - 50, my - 20, 180, 175)
         + callout(8, cx + 18, top - 8, 520, 62))
    return _svg(900, 500, b)


ALL = {"screw": screw, "rack": rack, "scissor": scissor, "bottle": bottle, "trolley": trolley,
       "incline": incline, "pascal": pascal, "modern": modern}

if __name__ == "__main__":
    from pathlib import Path
    out = Path(__file__).parent / "diagrams"
    out.mkdir(exist_ok=True)
    for k, f in ALL.items():
        (out / f"{k}.svg").write_text(f(), encoding="utf-8")
    print("ok", list(ALL))
