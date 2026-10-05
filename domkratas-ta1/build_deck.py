"""Paprastas PBL TA1 pristatymas „Domkratas“ (9 skaidrės, be piešinių).

Paleidimas:  python3 build_deck.py   → domkratas-ta1.pptx
"""

from pathlib import Path

from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.text import MSO_ANCHOR, PP_ALIGN
from pptx.util import Inches, Pt

OUT = Path(__file__).resolve().parent / "domkratas-ta1.pptx"

INK = RGBColor(0x22, 0x22, 0x22)
GREY = RGBColor(0x59, 0x59, 0x59)
ACCENT = RGBColor(0x1F, 0x4E, 0x79)
LIGHT = RGBColor(0xDE, 0xEA, 0xF6)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
FONT = "Calibri"

prs = Presentation()
prs.slide_width, prs.slide_height = Inches(13.333), Inches(7.5)
BLANK = prs.slide_layouts[6]
TOTAL = 9


def textbox(slide, x, y, w, h, size=20, color=INK, bold=False, align=PP_ALIGN.LEFT, anchor=MSO_ANCHOR.TOP):
    tf = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h)).text_frame
    tf.word_wrap = True
    tf.vertical_anchor = anchor
    tf.margin_left = tf.margin_right = Inches(0.05)
    p = tf.paragraphs[0]
    p.alignment = align
    return tf, (size, color, bold)


def para(tf, style, txt, first=False, bullet=False, space=6, size=None, bold=None, color=None):
    s, c, b = style
    p = tf.paragraphs[0] if first else tf.add_paragraph()
    p.space_after = Pt(space)
    run = p.add_run()
    run.text = ("• " if bullet else "") + txt
    run.font.name, run.font.size = FONT, Pt(size or s)
    run.font.bold = b if bold is None else bold
    run.font.color.rgb = color or c
    return p


def bullets(slide, x, y, w, h, items, size=20, space=10):
    tf, st = textbox(slide, x, y, w, h, size)
    for i, it in enumerate(items):
        if isinstance(it, tuple):  # (paryškinta dalis, likęs tekstas)
            p = para(tf, st, it[0], first=i == 0, bullet=True, space=space, bold=True)
            r = p.add_run()
            r.text = it[1]
            r.font.name, r.font.size, r.font.color.rgb = FONT, Pt(size), INK
        else:
            para(tf, st, it, first=i == 0, bullet=True, space=space)
    return tf


def new_slide(n, title, notes=""):
    s = prs.slides.add_slide(BLANK)
    tf, st = textbox(s, 0.6, 0.35, 12.1, 0.9, 32, ACCENT, True, anchor=MSO_ANCHOR.BOTTOM)
    para(tf, st, title, first=True)
    line = s.shapes.add_shape(1, Inches(0.65), Inches(1.32), Inches(12.0), Inches(0.03))
    line.fill.solid()
    line.fill.fore_color.rgb = ACCENT
    line.line.fill.background()
    tf, st = textbox(s, 11.7, 6.95, 1.1, 0.4, 12, GREY, align=PP_ALIGN.RIGHT)
    para(tf, st, f"{n} / {TOTAL}", first=True)
    tf, st = textbox(s, 0.6, 6.95, 8, 0.4, 12, GREY)
    para(tf, st, "PBL TA1 · Domkratas", first=True)
    if notes:
        s.notes_slide.notes_text_frame.text = notes
    return s


def table(slide, x, y, w, col_w, rows, size=15, row_h=0.5, highlight=None):
    shape = slide.shapes.add_table(len(rows), len(rows[0]), Inches(x), Inches(y), Inches(w), Inches(row_h * len(rows)))
    tbl = shape.table
    for j, cw in enumerate(col_w):
        tbl.columns[j].width = Inches(cw)
    for i, row in enumerate(rows):
        tbl.rows[i].height = Inches(row_h)
        for j, val in enumerate(row):
            cell = tbl.cell(i, j)
            cell.margin_left = cell.margin_right = Inches(0.08)
            cell.vertical_anchor = MSO_ANCHOR.MIDDLE
            cell.fill.solid()
            cell.fill.fore_color.rgb = ACCENT if i == 0 else (LIGHT if i == highlight else WHITE)
            p = cell.text_frame.paragraphs[0]
            r = p.add_run()
            r.text = val
            r.font.name, r.font.size = FONT, Pt(size)
            r.font.bold = i == 0 or j == 0
            r.font.color.rgb = WHITE if i == 0 else INK
    return tbl


# ── 1. Titulinis ────────────────────────────────────────────────────────
s = prs.slides.add_slide(BLANK)
band = s.shapes.add_shape(1, 0, Inches(2.2), prs.slide_width, Inches(2.4))
band.fill.solid()
band.fill.fore_color.rgb = ACCENT
band.line.fill.background()
band.shadow.inherit = False
tf, st = textbox(s, 0.8, 2.35, 11.7, 1.2, 48, WHITE, True, anchor=MSO_ANCHOR.BOTTOM)
para(tf, st, "Domkratas", first=True)
tf, st = textbox(s, 0.8, 3.55, 11.7, 0.9, 24, WHITE)
para(tf, st, "Raida, problemos ir patobulinimo kryptis", first=True)
tf, st = textbox(s, 0.8, 5.0, 11.7, 1.8, 18, GREY)
para(tf, st, "PBL užduotis · Tarpinis atsiskaitymas Nr. 1", first=True, space=4)
para(tf, st, "Dalykas: Įvadas į specialybę · Mechanikos inžinerija", space=4)
para(tf, st, "Grupė: [Vardas Pavardė, …] · Dėstytojas: G. Viselga · 2026 m.", space=4)
s.notes_slide.notes_text_frame.text = (
    "Laba diena. Mūsų tema – domkratas. Parodysime, kaip domkratai vystėsi, kokias problemas jie turi šiandien "
    "ir kaip siūlome patobulinti automobilio žirklinį domkratą.")

# ── 2. Srities pasirinkimas ─────────────────────────────────────────────
s = new_slide(2, "Kodėl pasirinkome domkratą?",
              "Domkratą turi beveik kiekvienas automobilis, o jame susitinka pavaros, medžiagos, sauga ir ergonomika.")
bullets(s, 0.7, 1.7, 12, 4.8, [
    ("Kasdienis įrenginys", " – domkratą turi beveik kiekvienas automobilis (ratų keitimas)."),
    ("Platus taikymas", " – autoservisai, statyba, geležinkelis, gelbėjimo tarnybos."),
    ("Daug mechanikos vienoje vietoje", " – sraigtinė, krumpliastiebinė ir hidraulinė pavaros, medžiagos, sauga."),
    ("Svarbi sauga", " – domkratas laiko šimtus kilogramų šalia žmogaus; vienam automobilio kampui tenka apie 0,4–0,5 t."),
    ("Veikimo principas", " – nedidele jėga pakeliamas didelis krovinys: sraigtu (svertu) arba hidraulika (Paskalio dėsnis)."),
], size=22, space=16)

# ── 3. Istorinė raida ───────────────────────────────────────────────────
s = new_slide(3, "Istorinė raida",
              "Raida: nuo sverto ir sraigto per hidrauliką iki elektrinių domkratų. Pagrindinė tendencija – nuo jėgos laimėjimo "
              "link greičio, saugos ir patogumo.")
table(s, 0.7, 1.7, 11.9, [2.6, 9.3], [
    ["Laikotarpis", "Sprendimas"],
    ["III a. pr. Kr.", "Archimedas aprašo sverto principą – jėgos laimėjimo pagrindą"],
    ["XV–XVI a.", "Sraigtiniai kėlikliai (sraigtas su veržle), Leonardo da Vinci eskizai"],
    ["1795 m.", "J. Bramah patentuoja hidraulinį presą (Paskalio dėsnis)"],
    ["1851 m.", "R. Dudgeon – nešiojamas hidraulinis domkratas"],
    ["XX a.", "„Hi-Lift“ krumpliastiebinis (1905 m.), žirklinis – automobilio komplekte, vežimėliniai – servisuose"],
    ["XXI a.", "12 V elektriniai, elektrohidrauliniai domkratai, pneumatinės pagalvės"],
], size=17, row_h=0.62)
tf, st = textbox(s, 0.7, 6.3, 11.9, 0.5, 14, GREY)
para(tf, st, "Šaltiniai: Encyclopaedia Britannica (n.d.); Hi-Lift Jack Company (n.d.).", first=True)

# ── 4. Tipai ir kritinis vertinimas ─────────────────────────────────────
s = new_slide(4, "Domkratų tipai ir jų vertinimas",
              "Palyginome penkis pagrindinius tipus. Pasiteisino savistabdis sriegis ir hidraulika, o silpnybės – lėtumas, "
              "nestabilumas ir sauga. Gilinsimės į žirklinį, nes jis yra kiekvieno automobilio komplekte.")
table(s, 0.7, 1.6, 11.9, [2.2, 3.4, 3.1, 3.2], [
    ["Tipas", "Veikimo principas", "Pasiteisino", "Trūkumai"],
    ["Sraigtinis", "Sukamas sraigtas kelia stūmoklį", "Savistabdis, patikimas", "Lėtas, mažas kėlimo aukštis"],
    ["Krumpliastiebinis", "Svirtis su skląsčiu kopia krumpliastiebiu", "Labai didelis kėlimo aukštis", "Nestabilus, pavojinga rankenos atatranka"],
    ["Žirklinis", "Horizontalus sraigtas suspaudžia rombo formos svirtis", "Kompaktiškas, lengvas, pigus", "Lėtas, sunku sukti, siauras pagrindas"],
    ["Hidraulinis butelinis", "Maža pompa spaudžia alyvą po dideliu stūmokliu", "Didelė jėga mažame tūryje", "Didelis pradinis aukštis, nutekėjimai"],
    ["Hidraulinis vežimėlinis", "Hidrocilindras kelia ilgą svirtį", "Greitas, stabilus", "Sunkus, nenešiojamas, brangus"],
], size=16, row_h=0.78, highlight=3)

# ── 5. Problema ir uždavinys ────────────────────────────────────────────
s = new_slide(5, "Šiuolaikinė problema ir inžinerinis uždavinys",
              "Žirklinis domkratas lėtas ir sunkiai sukamas, ypač pradžioje, nes jėga sraigte F = Q / tg θ. "
              "Todėl formuluojame uždavinį – greitesnis, lengviau valdomas ir stabilesnis domkratas.")
tf, st = textbox(s, 0.7, 1.6, 6.0, 0.5, 22, ACCENT, True)
para(tf, st, "Automobilio žirklinio domkrato problemos", first=True)
bullets(s, 0.7, 2.2, 6.0, 4.3, [
    ("Lėtas", " – reikia apie 60–100 rankenos apsisukimų (2–4 min)."),
    ("Sunku sukti", " – žemoje padėtyje jėga sraigte kelis kartus didesnė už krovinį."),
    ("Nestabilus", " – mažas pagrindas slysta ar smenga į minkštą gruntą."),
    ("Nepatogus", " – žmogus dirba pasilenkęs, ilgai būna prie kelio."),
], size=19, space=12)
box = s.shapes.add_shape(1, Inches(7.1), Inches(1.65), Inches(5.5), Inches(4.7))
box.fill.solid()
box.fill.fore_color.rgb = LIGHT
box.line.fill.background()
box.shadow.inherit = False
tf, st = textbox(s, 7.35, 1.85, 5.0, 4.4, 19)
para(tf, st, "Uždavinys", first=True, size=22, bold=True, color=ACCENT)
para(tf, st, "Patobulinti žirklinį domkratą, kad jis 1,5 t automobilį pakeltų greičiau nei per 60 s, "
             "be didelių fizinių pastangų ir stabiliai, išlaikant kompaktiškumą ir saugumą.", space=14)
para(tf, st, "Tikslai:", bold=True, space=4)
for it in ["keliamoji galia ≥ 1500 kg", "kėlimo aukštis 100–400 mm", "kėlimo laikas ≤ 60 s",
           "maitinimas iš 12 V automobilio lizdo", "masė ≤ 4,5 kg"]:
    para(tf, st, it, bullet=True, space=2, size=18)
tf, st = textbox(s, 0.7, 6.4, 6.0, 0.5, 14, GREY)
para(tf, st, "Apsisukimų skaičius – mūsų įvertinimas.", first=True)

# ── 6. Sprendimas: elementai ir medžiagos ───────────────────────────────
s = new_slide(6, "Sprendimas: keičiami elementai ir medžiagos",
              "Siūlome elektrinį žirklinį domkratą. Svarbiausi pakeitimai: 12 V variklis, trapecinis sraigtas iš grūdinto plieno "
              "su bronzine veržle, stipresnės svirtys ir platesnis pagrindas. Avarinis rankinis sukimas lieka.")
table(s, 0.7, 1.6, 11.9, [1.9, 2.9, 3.6, 3.5], [
    ["Elementas", "Dabar", "Siūloma", "Kodėl"],
    ["Pavara", "Rankinė rankena", "12 V variklis (~100 W) + reduktorius", "Greitai, be fizinių pastangų"],
    ["Sraigtas", "Paprastas plienas, metrinis sriegis", "Trapecinis Tr18×4, plienas 42CrMo4", "Savistabdis, atsparus dilimui"],
    ["Veržlė", "Plieninė", "Bronza CuSn12", "Mažesnė trintis, mažiau dyla"],
    ["Svirtys", "Plienas S235", "Plienas S420MC", "~1,8 karto stipresnės, ta pati masė"],
    ["Pagrindas", "~130×80 mm", "~200×120 mm su guminiu padu", "Stabilesnis, neslysta"],
    ["Sauga", "—", "Galiniai jungikliai, perkrovos apsauga, avarinis rankinis sukimas", "Veikia ir dingus elektrai"],
], size=16, row_h=0.68)

# ── 7. Prieš ir po ──────────────────────────────────────────────────────
s = new_slide(7, "Įprastas ir patobulintas domkratas",
              "Laimime greitį, jėgą ir stabilumą. Kompromisai – didesnė masė ir kaina. Preliminariai variklio galia apie 100 W, "
              "todėl užtenka automobilio 12 V lizdo.")
table(s, 0.7, 1.6, 7.4, [2.6, 2.4, 2.4], [
    ["Parametras", "Įprastas", "Patobulintas"],
    ["Kėlimo laikas", "~2–4 min", "≤ 60 s"],
    ["Rankos jėga", "~100–200 N", "nereikia"],
    ["Pagrindo plotas", "~100 cm²", "~240 cm²"],
    ["Masė", "~3 kg", "~4,5 kg"],
    ["Kaina", "~20–30 €", "~60–80 €"],
], size=17, row_h=0.65)
tf, st = textbox(s, 8.5, 1.6, 4.2, 4.6, 18)
para(tf, st, "Preliminarus skaičiavimas", first=True, size=21, bold=True, color=ACCENT, space=10)
para(tf, st, "Variklio galia:", bold=True, space=2)
para(tf, st, "P ≈ Q·h / (t·η) = 5000·0,25 / (45·0,3) ≈ 93 W", space=12)
para(tf, st, "Srovė iš 12 V lizdo:", bold=True, space=2)
para(tf, st, "≈ 8 A (saugiklis 15 A)", space=12)
para(tf, st, "Savistabdumas:", bold=True, space=2)
para(tf, st, "kėlimo kampas ψ = 4,5° < trinties kampas φ′ ≈ 5,9° – krovinys nenusileidžia savaime.", space=12)
tf, st = textbox(s, 0.7, 6.3, 11.9, 0.5, 14, GREY)
para(tf, st, "Visos vertės apytikslės; tikslūs skaičiavimai bus TA2 etape.", first=True)

# ── 8. Išvados ──────────────────────────────────────────────────────────
s = new_slide(8, "Išvados ir tolesni darbai",
              "Apibendrinant: žirklinį domkratą siūlome elektrifikuoti ir sustiprinti. TA2 etape atliksime skaičiavimus, "
              "patentų analizę ir įvertinsime atitiktį standartams. Ačiū, laukiame klausimų.")
bullets(s, 0.7, 1.7, 7.0, 4.6, [
    "Domkratai vystėsi nuo jėgos laimėjimo (svertas, sraigtas) per hidrauliką iki saugos ir patogumo.",
    "Žirklinis domkratas kompaktiškas ir savistabdis, bet lėtas, sunkiai sukamas ir nestabilus.",
    "Siūlome 12 V elektrinę pavarą, Tr18×4 sraigtą su bronzine veržle, stipresnes svirtis ir platesnį pagrindą.",
    "Kompromisas – šiek tiek didesnė masė ir kaina.",
], size=20, space=16)
box = s.shapes.add_shape(1, Inches(8.1), Inches(1.75), Inches(4.5), Inches(3.4))
box.fill.solid()
box.fill.fore_color.rgb = LIGHT
box.line.fill.background()
box.shadow.inherit = False
tf, st = textbox(s, 8.35, 1.9, 4.0, 3.1, 18)
para(tf, st, "TA2 etape", first=True, size=21, bold=True, color=ACCENT, space=8)
for it in ["naujausių patentų ir straipsnių analizė", "sraigto ir veržlės stiprumo skaičiavimai",
           "variklio ir reduktoriaus parinkimas", "atitiktis standartui EN 1494, sauga"]:
    para(tf, st, it, bullet=True, space=6)
tf, st = textbox(s, 8.1, 5.4, 4.5, 0.8, 32, ACCENT, True, align=PP_ALIGN.CENTER)
para(tf, st, "Klausimai?", first=True)

# ── 9. Šaltiniai ────────────────────────────────────────────────────────
s = new_slide(9, "Šaltiniai")
refs = [
    ("Budynas, R. G., & Nisbett, J. K. (2020). ", "Shigley's mechanical engineering design", " (11th ed.). McGraw-Hill Education."),
    ("Childs, P. R. N. (2014). ", "Mechanical design engineering handbook", ". Butterworth-Heinemann."),
    ("European Committee for Standardization. (2008). ", "Mobile or movable jacks and associated lifting equipment", " (EN 1494:2000+A1:2008)."),
    ("Europos Parlamentas ir Taryba. (2023). ", "Reglamentas (ES) 2023/1230 dėl mašinų", ". Europos Sąjungos oficialusis leidinys."),
    ("Encyclopaedia Britannica. (n.d.). ", "Jack", ". Retrieved [data], from https://www.britannica.com"),
    ("Hi-Lift Jack Company. (n.d.). ", "Our history", ". Retrieved [data], from https://www.hi-lift.com"),
]
tf, st = textbox(s, 0.7, 1.7, 11.9, 4.8, 18)
for i, (a, italic, b) in enumerate(refs):
    p = para(tf, st, a, first=i == 0, space=14)
    for txt, it in ((italic, True), (b, False)):
        r = p.add_run()
        r.text = txt
        r.font.name, r.font.size, r.font.italic, r.font.color.rgb = FONT, Pt(18), it, INK

prs.save(OUT)
print("saved", OUT)
