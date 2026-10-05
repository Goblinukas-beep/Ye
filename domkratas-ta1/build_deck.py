"""PBL TA1 pristatymas „Automobilinis domkratas“ – raida žingsnis po žingsnio (4 tipai, 4 pranešėjai).

Paleidimas:  python3 build_deck.py   → domkratas-ta1.pptx
Brėžiniai (brezinai/*.png) – JAV patentų brėžiniai iš Google Patents, perspalvinti „blueprint“ stiliumi.
"""

from pathlib import Path

from PIL import Image
from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.text import MSO_ANCHOR, PP_ALIGN
from pptx.util import Inches, Pt

HERE = Path(__file__).resolve().parent
OUT = HERE / "domkratas-ta1.pptx"
IMG = HERE / "brezinai"

INK = RGBColor(0x22, 0x22, 0x22)
GREY = RGBColor(0x59, 0x59, 0x59)
ACCENT = RGBColor(0x1F, 0x4E, 0x79)
LIGHT = RGBColor(0xDE, 0xEA, 0xF6)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
FONT = "Calibri"

prs = Presentation()
prs.slide_width, prs.slide_height = Inches(13.333), Inches(7.5)
BLANK = prs.slide_layouts[6]
TOTAL = 12


def textbox(slide, x, y, w, h, size=20, color=INK, bold=False, align=PP_ALIGN.LEFT, anchor=MSO_ANCHOR.TOP):
    tf = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h)).text_frame
    tf.word_wrap = True
    tf.vertical_anchor = anchor
    tf.margin_left = tf.margin_right = Inches(0.05)
    tf.paragraphs[0].alignment = align
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


def add(p, txt, size, bold=False, italic=False, color=INK):
    r = p.add_run()
    r.text = txt
    r.font.name, r.font.size, r.font.bold, r.font.italic = FONT, Pt(size), bold, italic
    r.font.color.rgb = color
    return r


def rect(slide, x, y, w, h, color):
    shp = slide.shapes.add_shape(1, Inches(x), Inches(y), Inches(w), Inches(h))
    shp.fill.solid()
    shp.fill.fore_color.rgb = color
    shp.line.fill.background()
    shp.shadow.inherit = False
    return shp


def picture(slide, path, x, y, w, h):
    """Įdeda paveikslėlį į rėmelį, išlaikant proporcijas (centruota)."""
    iw, ih = Image.open(path).size
    scale = min(w / iw, h / ih)
    pw, ph = iw * scale, ih * scale
    return slide.shapes.add_picture(str(path), Inches(x + (w - pw) / 2), Inches(y + (h - ph) / 2), Inches(pw), Inches(ph))


def new_slide(n, title, notes=""):
    s = prs.slides.add_slide(BLANK)
    tf, st = textbox(s, 0.6, 0.35, 12.1, 0.9, 32, ACCENT, True, anchor=MSO_ANCHOR.BOTTOM)
    para(tf, st, title, first=True)
    rect(s, 0.65, 1.32, 12.0, 0.03, ACCENT)
    tf, st = textbox(s, 11.7, 6.95, 1.1, 0.4, 12, GREY, align=PP_ALIGN.RIGHT)
    para(tf, st, f"{n} / {TOTAL}", first=True)
    tf, st = textbox(s, 0.6, 6.95, 8, 0.4, 12, GREY)
    para(tf, st, "PBL · Automobilinis domkratas", first=True)
    if notes:
        s.notes_slide.notes_text_frame.text = notes
    return s


def source_line(slide, txt, x=0.7, y=6.45, w=11.9):
    tf, st = textbox(slide, x, y, w, 0.5, 13, GREY)
    para(tf, st, "Šaltiniai: " + txt, first=True)


def table(slide, x, y, w, col_w, rows, size=15, row_h=0.5, highlight=()):
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
            cell.fill.fore_color.rgb = ACCENT if i == 0 else (LIGHT if i in highlight else WHITE)
            add(cell.text_frame.paragraphs[0], val, size, bold=(i == 0 or j == 0 or i in highlight), color=WHITE if i == 0 else INK)
    return tbl


def jack_slide(n, step, title, era, image, caption, blocks, sources, notes):
    """Vieno domkrato tipo skaidrė: kairėje brėžinys, dešinėje – tipas, veikimas, privalumai, problemos."""
    s = new_slide(n, title, notes)
    rect(s, 0.7, 1.6, 5.0, 4.75, ACCENT)
    picture(s, IMG / image, 0.8, 1.7, 4.8, 4.55)
    tf, st = textbox(s, 0.7, 6.38, 5.0, 0.4, 12, GREY)
    para(tf, st, "Brėžinys: " + caption, first=True)
    tf, st = textbox(s, 6.1, 1.55, 6.6, 0.45, 15, ACCENT, True)
    para(tf, st, f"{step} žingsnis · {era} · Pristato: [vardas]", first=True)
    tf, st = textbox(s, 6.1, 1.95, 6.6, 4.35, 16)
    for i, (head, body) in enumerate(blocks):
        para(tf, st, head, first=i == 0, size=17, bold=True, color=ACCENT, space=1)
        para(tf, st, body, space=8)
    source_line(s, sources, x=6.1, y=6.38, w=6.6)
    return s


# ── 1. Titulinis ────────────────────────────────────────────────────────
s = prs.slides.add_slide(BLANK)
rect(s, 0, 2.2, 13.333, 2.4, ACCENT)
tf, st = textbox(s, 0.8, 2.35, 11.7, 1.2, 48, WHITE, True, anchor=MSO_ANCHOR.BOTTOM)
para(tf, st, "Automobilinis domkratas", first=True)
tf, st = textbox(s, 0.8, 3.55, 11.7, 0.9, 24, WHITE)
para(tf, st, "Kaip jis keitėsi ir ką galima patobulinti", first=True)
tf, st = textbox(s, 0.8, 5.0, 11.7, 1.8, 18, GREY)
para(tf, st, "PBL užduotis · Tarpinis atsiskaitymas Nr. 1", first=True, space=4)
para(tf, st, "Dalykas: Įvadas į specialybę · Mechanikos inžinerija", space=4)
para(tf, st, "Grupė: [Vardas Pavardė ×4] · Dėstytojas: G. Viselga · 2026 m.", space=4)
s.notes_slide.notes_text_frame.text = (
    "Laba diena. Mūsų tema – automobilinis domkratas. Papasakosime, kodėl jo prireikė, kaip jis keitėsi per keturis "
    "žingsnius – kiekvienas iš mūsų pristatys vieną – ir ką siūlome patobulinti.")

# ── 2. Funkcija ─────────────────────────────────────────────────────────
s = new_slide(2, "Funkcija: kam reikalingas domkratas?",
              "Domkrato funkcija – nedidele žmogaus jėga pakelti sunkų krovinį, pavyzdžiui, automobilio kampą. Tai pavyksta dėl "
              "sverto ir sraigto arba dėl hidraulikos. Domkratai buvo naudojami dar vežimams, o atsiradus automobiliams, "
              "padangos prakiurdavo labai dažnai, todėl domkrato reikėjo kiekviename automobilyje.")
tf, st = textbox(s, 0.7, 1.7, 7.0, 4.6, 20)
items = [
    ("Funkcija", " – nedidele žmogaus jėga pakelti sunkų krovinį, pvz., automobilio kampą, kad būtų galima pakeisti ratą."),
    ("Kaip tai pavyksta", " – sraigtas ar svirtis: maža jėga, bet ilgas kelias; hidraulika: pagal Paskalio dėsnį didesnis stūmoklis duoda didesnę jėgą."),
    ("Prieš automobilius", " – vežimams kelti naudoti svertiniai domkratai (dešinėje – 1882 m. vežimo domkratas)."),
    ("Kodėl prireikė automobiliams", " – keliuose gulėjo daug pasagų vinių, padangos prakiurdavo labai dažnai, todėl domkrato reikėjo kiekviename automobilyje."),
]
for i, (b, rest) in enumerate(items):
    p = para(tf, st, b, first=i == 0, bullet=True, bold=True, space=14)
    add(p, rest, 20)
rect(s, 8.2, 1.6, 4.4, 4.75, ACCENT)
picture(s, IMG / "0-vezimo-bovey-1882.png", 8.3, 1.7, 4.2, 4.55)
tf, st = textbox(s, 8.2, 6.38, 4.4, 0.4, 12, GREY)
para(tf, st, "Brėžinys: G. O. Bovey, JAV patentas Nr. 260,276 (1882)", first=True)
source_line(s, "Joyce/Dayton (n.d.); LibreTexts (n.d.); Bovey (1882); Wikipedia (n.d.-d); Junkyard Mob (n.d.).", w=7.0)

# ── 3. Raidos kelias (chronologiškai) ───────────────────────────────────
s = new_slide(3, "Istorija: domkratų raida laiko juostoje",
              "Čia visi domkratų tipai surikiuoti pagal atsiradimo laiką. Paryškinti keturi, kuriuos pristatysime išsamiai – "
              "kiekvienas iš mūsų po vieną. Kitų tipų panaudojimą aptarsime skaidrėje „Pritaikymas“.")
table(s, 0.7, 1.6, 11.9, [1.7, 3.0, 3.6, 3.6], [
    ["Laikas", "Tipas", "Ką išsprendė", "Kokia problema liko"],
    ["Iki 1851 m.", "1. Sraigtinis", "Paprastas ir savistabdis", "Lėtas, reikia daug jėgos"],
    ["1851 m.", "2. Hidraulinis (butelinis)", "Mažiau jėgos, kelia daugiau", "Per aukštas žemam automobiliui, varginantis pumpavimas"],
    ["1905 m.", "Krumpliastiebinis", "Kelia labai aukštai", "Pavojinga rankenos atatranka"],
    ["1910 m.", "Vežimėlinis", "Greitas ir stabilus", "Didelis ir sunkus"],
    ["1920 m.", "3. Žirklinis", "Žemas, lengvas, telpa bagažinėje", "Lėtas, siauras pagrindas"],
    ["1966 m.", "4. Pneumohidraulinis", "Nereikia pumpuoti rankomis", "Reikia kompresoriaus"],
    ["2004 m.", "Elektrinis žirklinis", "Nereikia sukti rankos", "Reikia elektros, brangesnis"],
], size=15, row_h=0.58, highlight=(1, 2, 5, 6))
tf, st = textbox(s, 0.7, 6.35, 11.9, 0.5, 15, ACCENT, True)
para(tf, st, "Paryškinti – keturi tipai, kuriuos pristatome išsamiai. Datos – patentų ar pirmųjų gaminių metai.", first=True)

# ── 4–7. Keturi tipai ───────────────────────────────────────────────────
jack_slide(4, 1, "Sraigtinis domkratas", "XIX a.", "1-sraigtinis-stevenson-1898.png",
           "H. M. Stevenson, JAV patentas Nr. 601,451 (1898)",
           [("Tipas", "Mechaninis domkratas."),
            ("Kaip veikia", "Sukant rankeną, sraigtas išsisuka iš korpuso ir stumia krovinį aukštyn."),
            ("Kuo geras", "Paprastas ir savistabdis – paleidus rankeną krovinys nenukrenta."),
            ("Problemos", "Lėtas ir reikalauja daug jėgos: dėl didelės trinties naudingumo koeficientas tik 30–40 %.")],
           "Stevenson (1898); Wikipedia (n.d.-b); Joyce/Dayton (n.d.).",
           "Pirmieji paplitę domkratai buvo sraigtiniai. Sukant rankeną sraigtas kyla ir kelia krovinį. Jie paprasti ir "
           "savistabdžiai, bet lėti ir sunkiai sukami, nes didelė trintis suvalgo daug energijos.")

jack_slide(5, 2, "Hidraulinis (butelinis) domkratas", "1851 m.", "2-hidraulinis-dudgeon-1851.png",
           "R. Dudgeon, JAV patentas Nr. 8,203 (1851)",
           [("Tipas", "Hidraulinis domkratas."),
            ("Kaip veikia", "Svirtimi pumpuojamas skystis iš mažo cilindro po dideliu stūmokliu. Pagal Paskalio dėsnį jėga padidėja. Dudgeon naudojo vandenį."),
            ("Ką išsprendė", "Dudgeon rašė, kad jo presas atliks didžiąją dalį darbo, kurį iki tol atlikdavo sraigtas. Reikia mažiau jėgos, o pakeliami kroviniai iki 50 t."),
            ("Problemos", "Didelis pradinis aukštis – netelpa po žemu automobiliu. Mažas pagrindas, todėl mažiau stabilus. Ilgai pumpuoti rankena varginanti.")],
           "Dudgeon (1851); LibreTexts (n.d.); CJ Pony Parts (n.d.); Redline Stands (n.d.); Juds (1967).",
           "1851 m. Richardas Dudgeonas patentavo nešiojamą hidraulinį presą. Jis pats rašė, kad šis atliks darbą, kurį "
           "iki tol darė sraigtas. Hidraulika leido mažomis pastangomis kelti labai sunkius krovinius, tačiau butelinis "
           "domkratas yra aukštas ir netelpa po žemu automobiliu.")

jack_slide(6, 3, "Žirklinis domkratas", "1920 m.", "3-zirklinis-lafrance-1920.png",
           "J. LaFrance, JAV patentas Nr. 1,362,630 (1920)",
           [("Tipas", "Mechaninis domkratas: sraigtas ir rombo formos svirtys."),
            ("Kaip veikia", "Sukamas horizontalus sraigtas traukia rombo šonines jungtis vieną prie kitos, todėl viršus kyla."),
            ("Ką išsprendė", "Žemas ir lengvas – telpa po automobiliu ir bagažinėje. LaFrance norėjo, kad jis būtų tvirtas, lengvai valdomas, paprastas ir pigus. Todėl jį deda į naujus automobilius."),
            ("Problemos", "Lėtas – reikia daug rankenos apsisukimų. Siauras pagrindas, nestabilus ant minkšto ar nelygaus paviršiaus.")],
           "LaFrance (1920); Brown (1949); CJ Pony Parts (n.d.); CN Trailer Parts (n.d.).",
           "1920 m. Joseph LaFrance patentavo domkratą, skirtą būtent automobiliams. Rombo formos svirtys leidžia jam būti "
           "žemam ir lengvam, todėl jis telpa bagažinėje. 1949 m. W. P. Brown patentavo patobulintą žirklinį domkratą. "
           "Tačiau sukti reikia ilgai, o siauras pagrindas ant minkšto grunto nestabilus.")

jack_slide(7, 4, "Pneumohidraulinis domkratas", "1966 m.", "4-pneumohidraulinis-juds-1967.png",
           "D. H. Juds, JAV patentas Nr. 3,329,403 (1967)",
           [("Tipas", "Pneumohidraulinis domkratas: suslėgtas oras + hidraulika."),
            ("Kaip veikia", "Suslėgtas oras iš kompresoriaus varo siurblio stūmoklį, kuris spaudžia alyvą į pagrindinį cilindrą, ir stūmoklis kyla."),
            ("Ką išsprendė", "Juds rašė, kad rankinis pumpavimas hidrauliniame domkrate tampa varginantis, o pneumatiniai domkratai greiti ir jį pašalina. Dingus orui, krovinys lieka stovėti ant alyvos ir galima pumpuoti rankomis."),
            ("Problemos", "Reikia kompresoriaus su pakankamu slėgiu (dažniausiai apie 8–10 bar), o kelyje jo paprastai nėra. Brangesnis.")],
           "Juds (1967); TMG Industrial (n.d.); VEVOR (n.d.).",
           "Hidraulinis domkratas sumažino reikiamą jėgą, bet pumpuoti rankena ilgai buvo varginanti. 1966 m. Donald Juds "
           "pateikė patentą kombinuotam domkratui: alyvą pumpuoja suslėgtas oras iš kompresoriaus, o dingus orui domkratas "
           "veikia rankiniu būdu. Tai greita ir patogu servise, bet kelyje kompresoriaus paprastai nėra.")

# ── 8. Pritaikymas ──────────────────────────────────────────────────────
s = new_slide(8, "Pritaikymas: kur naudojami domkratai",
              "Kiekvienas domkratų tipas rado savo vietą. Žirklinis – automobilio bagažinėje, vežimėlinis ir pneumohidraulinis – "
              "servisuose, butelinis – sunkiai technikai, krumpliastiebinis – visureigiams ir ūkiams, elektrinis – tiems, kam "
              "sunku sukti rankena.")
table(s, 0.7, 1.6, 11.9, [3.2, 3.3, 5.4], [
    ["Kur naudojama", "Domkrato tipas", "Kodėl tinka"],
    ["Lengvasis automobilis (ratui keisti)", "Žirklinis", "Lengvas ir pigus – gamintojai deda į naujus automobilius"],
    ["Autoservisai ir garažai", "Vežimėlinis, pneumohidraulinis", "Greitas ir stabilus; servisuose yra suslėgto oro linija"],
    ["Sunkvežimiai ir pramonė", "Hidraulinis butelinis", "Didelė keliamoji galia – nuo 3 iki 50 t"],
    ["Visureigiai ir ūkiai", "Krumpliastiebinis („Hi-Lift“)", "Kelia labai aukštai, tinka ir traukti, spausti"],
    ["Statyba ir sunkūs kroviniai", "Hidraulinės kėlimo sistemos", "Daug domkratų kartu kelia didelius objektus"],
    ["Kas nenori sukti rankenos", "Elektrinis žirklinis", "Kyla paspaudus mygtuką, maitinamas iš 12 V lizdo"],
], size=16, row_h=0.62)
source_line(s, "CJ Pony Parts (n.d.); Juds (1967); Hi-Lift Jack Company (n.d.-a); Richard Dudgeon, Inc. (n.d.); Pro-Lift-Montagetechnik (n.d.).")

# ── 9. Kompanijos ───────────────────────────────────────────────────────
s = new_slide(9, "Kompanijos, kūrusios domkratus",
              "Kelios kompanijos sukūrė svarbiausius domkratus ir kai kurios veikia iki šiol. Dudgeon įmonė įkurta 1849 m. ir tebeveikia, "
              "Hi-Lift domkratai iki šiol gaminami Indianoje, o Blackhawk prekės ženklas dabar priklauso Stanley.")
table(s, 0.7, 1.6, 11.9, [3.0, 1.7, 4.4, 2.8], [
    ["Kompanija", "Įkurta", "Ką sukūrė", "Šiandien"],
    ["Richard Dudgeon, Inc. (Niujorkas)", "1849 m.", "Pirmasis nešiojamas hidraulinis domkratas (1851 m.)", "Tebeveikia (Konektikutas)"],
    ["Hi-Lift Jack Company (Indiana)", "1895 m.", "Krumpliastiebinis „Hi-Lift“ domkratas (1905 m.)", "Gamina iki šiol"],
    ["Weaver Manufacturing", "—", "Vežimėlinis „Auto-Twin“ (1910 m.), pirmasis hidraulinis (1928 m.)", "—"],
    ["Blackhawk (Milvokis)", "1919 m.", "Įrankiai ir vežimėliniai domkratai", "Prekės ženklas priklauso Stanley"],
    ["Milwaukee Hydraulic Products", "—", "Kombinuotas pneumohidraulinis domkratas (1967 m. patentas)", "—"],
], size=16, row_h=0.72)
source_line(s, "Wikipedia (n.d.-c); Richard Dudgeon, Inc. (n.d.); Hi-Lift Jack Company (n.d.-a); Castle Equipment (n.d.); Wikipedia (n.d.-a); Juds (1967).")

# ── 10. Trūkumai ir mūsų patobulinimas ──────────────────────────────────
s = new_slide(10, "Trūkumai ir mūsų patobulinimas",
              "Šiandien automobilyje dažniausiai rasime žirklinį domkratą. Jo trūkumai – lėtas, siauro pagrindo, nestabilus ant "
              "minkšto paviršiaus ir nepatogus sukti. Siūlome platesnį pagrindą su guminiu padu, savistabdį trapecinį sraigtą su "
              "bronzine veržle, stipresnes svirtis ir patogesnę rankeną.")
rect(s, 0.7, 1.6, 11.9, 1.0, LIGHT)
tf, st = textbox(s, 0.9, 1.65, 11.5, 0.9, 18, INK, anchor=MSO_ANCHOR.MIDDLE)
p = para(tf, st, "Žirklinio domkrato trūkumai: ", first=True, bold=True, color=ACCENT)
add(p, "lėtas (daug apsisukimų), siauras pagrindas – nestabilus ant minkšto ar nelygaus paviršiaus, sukti tenka nepatogioje padėtyje.", 18)
table(s, 0.7, 2.85, 11.9, [2.4, 4.6, 4.9], [
    ["Elementas", "Ką keičiame", "Kodėl"],
    ["Pagrindas", "Platesnis, su guminiu padu", "Neslysta ir nesmenga į minkštą paviršių"],
    ["Sraigtas ir veržlė", "Trapecinis sraigtas iš plieno 42CrMo4, veržlė iš bronzos CuSn12", "Savistabdis, mažiau dyla, maža trintis"],
    ["Svirtys", "Plienas S420MC vietoj S235", "Takumo riba 420 vs 235 MPa – apie 1,8 karto stipresnės"],
    ["Rankena", "Ilgesnė, sulankstoma rankena", "Sukti galima nesilenkiant prie pat rato (mūsų idėja)"],
], size=16, row_h=0.62)
source_line(s, "CN Trailer Parts (n.d.); Roton Products (n.d.); Sider Ticino (n.d.); Hengli Automation (n.d.); Gnee Steel (n.d.); The World Material (n.d.).")

# ── 10. Išvados ─────────────────────────────────────────────────────────
s = new_slide(11, "Išvados",
              "Apibendrinant: domkratas keitėsi nuo sraigtinio iki pneumohidraulinio, ir kiekvienas žingsnis sprendė ankstesniojo problemą. "
              "Mūsų idėja – stabilesnis ir patvaresnis žirklinis domkratas. Ačiū, laukiame klausimų.")
tf, st = textbox(s, 0.7, 1.7, 7.4, 4.6, 21)
for i, (b, rest) in enumerate([
    ("Poreikis", " – automobiliams reikėjo nešiojamo domkrato, nes padangos dažnai prakiurdavo."),
    ("Raida", " – sraigtinis → hidraulinis → žirklinis → pneumohidraulinis."),
    ("Dėsningumas", " – kiekvienas naujas domkratas išsprendė ankstesniojo problemą, bet atnešė naujų."),
    ("Pritaikymas", " – kiekvienas tipas rado savo vietą: nuo automobilio bagažinės iki serviso ir statybų."),
    ("Mūsų idėja", " – žirklinis domkratas su platesniu pagrindu, savistabdžiu sraigtu, bronzine veržle ir patogesne rankena."),
]):
    p = para(tf, st, b, first=i == 0, bullet=True, bold=True, space=18)
    add(p, rest, 21)
rect(s, 8.5, 2.6, 4.1, 2.0, LIGHT)
tf, st = textbox(s, 8.5, 2.6, 4.1, 2.0, 36, ACCENT, True, align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)
para(tf, st, "Klausimai?", first=True)

# ── 12. Šaltiniai (APA) ──────────────────────────────────────────────
REFS = [
    ("Bovey, G. O. (1882). ", "Carriage-jack", " (U.S. Patent No. 260,276). https://patents.google.com/patent/US260276A/en"),
    ("Brown, W. P. (1949). ", "Scissors jack", " (U.S. Patent No. 2,467,657). https://patents.google.com/patent/US2467657A/en"),
    ("Castle Equipment. (n.d.). ", "Weaver hydraulic & mechanical jacks history", ". http://www.castleequipment.com/Museum/jacks_weaver_history.htm"),
    ("CJ Pony Parts. (n.d.). ", "Types of car jacks", ". https://www.cjponyparts.com/resources/types-of-car-jacks"),
    ("CN Trailer Parts. (n.d.). ", "What are the disadvantages of a scissor jack?", " https://www.cntrailerparts.com/blog/what-are-the-disadvantages-of-a-scissor-jack-372667.html"),
    ("Dudgeon, R. (1851). ", "Portable hydraulic press", " (U.S. Patent No. 8,203). https://patents.google.com/patent/US8203A/en"),
    ("Gnee Steel. (n.d.). ", "EN 10149-2 S420MC hot rolled automotive steel", ". https://www.gneesteel.com/products/automotive-steel/en-10149-2-s420mc-hot-rolled-automotive-steel.html"),
    ("Hengli Automation. (n.d.). ", "What is the material of the nut for a T lead screw?", " https://www.hlt-cnc.com/blog/what-is-the-material-of-the-nut-for-a-t-lead-screw-1318622.html"),
    ("Hi-Lift Jack Company. (n.d.-a). ", "Our history", ". https://hi-lift.com/company/our-history/"),
    ("Hi-Lift Jack Company. (n.d.-b). ", "Hi-Lift jack instructions", " [PDF]. https://hi-lift.com/wp-content/uploads/2016/07/jack_instructions.pdf"),
    ("Joyce/Dayton. (n.d.). ", "Machine screw jacks vs. ball screw jacks", ". https://www.joycedayton.com/blog/machine-screw-jacks-vs-ball-screw-jacks"),
    ("Juds, D. H. (1967). ", "Combination hydraulic and pneumatic jacks", " (U.S. Patent No. 3,329,403). https://patents.google.com/patent/US3329403"),
    ("Junkyard Mob. (n.d.). ", "Car jack history and how to identify antique models", ". https://www.junkyardmob.com/misc/antique-car-jack-identification/"),
    ("LaFrance, J. (1920). ", "Jack", " (U.S. Patent No. 1,362,630). https://patents.google.com/patent/US1362630A/en"),
    ("LibreTexts. (n.d.). ", "10.2: Force multiplication", ". https://eng.libretexts.org/Courses/Northeast_Wisconsin_Technical_College/Fluids_1:_Fluid_Power_and_Pneumatics_(NWTC)/10:_Pascal's_Law/10.02:_Force_Multiplication"),
    ("Mickael, E. (2004). ", "Motor driven scissor jack with limit switches", " (U.S. Patent No. 6,695,289). https://patents.google.com/patent/US6695289B1/en"),
    ("Pro-Lift-Montagetechnik. (n.d.). ", "12V electric scissor jack, car jack, 123 mm – 345 mm", ". https://www.pro-lift-montagetechnik.com/12-volt-electric-scissor-jack-car-jack-123mm-345mm-002"),
    ("Redline Stands. (n.d.). ", "Bottle jack vs. floor jack: Differences, pros, and cons", ". https://www.redlinestands.com/blog/bottle-jack-vs-floor-jack/"),
    ("Richard Dudgeon, Inc. (n.d.). ", "History", ". https://www.dudgeonjacks.com/history.html"),
    ("Roton Products. (n.d.). ", "Trapezoidal lead screws: General information", ". https://www.roton.com/products/trapezoidal-lead-screws-nuts/general-information/"),
    ("Sider Ticino. (n.d.). ", "42CrMo4 technical specifications", ". https://siderticino.it/en/steel-datasheets/42crmo4/"),
    ("Stevenson, H. M. (1898). ", "Lifting-jack", " (U.S. Patent No. 601,451). https://patents.google.com/patent/US601451A/en"),
    ("The World Material. (n.d.). ", "EN 10025-2 S235 steel properties", ". https://www.theworldmaterial.com/en-10025-2-material-s235-steel/"),
    ("TMG Industrial. (n.d.). ", "Air hydraulic bottle jacks: How they work and safety tips for use", ". https://tmgindustrial.ca/blogs/news/air-hydraulic-bottle-jacks-how-they-work-and-safety-tips-for-use"),
    ("VEVOR. (n.d.). ", "Things to know before buying a pneumatic bottle jack", ". https://www.vevor.com/diy-ideas/things-to-know-before-buying-a-pneumatic-bottle-jack/"),
    ("Wikipedia. (n.d.-a). ", "Blackhawk (tools)", ". https://en.wikipedia.org/wiki/Blackhawk_(tools)"),
    ("Wikipedia. (n.d.-b). ", "Jackscrew", ". https://en.wikipedia.org/wiki/Jackscrew"),
    ("Wikipedia. (n.d.-c). ", "Richard Dudgeon", ". https://en.wikipedia.org/wiki/Richard_Dudgeon"),
    ("Wikipedia. (n.d.-d). ", "Spare tire", ". https://en.wikipedia.org/wiki/Spare_tire"),
]
half = (len(REFS) + 1) // 2
s = new_slide(12, "Šaltiniai")
for k, chunk in enumerate((REFS[:half], REFS[half:])):
    tf, st = textbox(s, 0.6 + k * 6.1, 1.45, 5.95, 5.4, 9)
    for i, (a, title, b) in enumerate(chunk):
        p = para(tf, st, a, first=i == 0, space=2)
        add(p, title, 9, italic=True)
        add(p, b, 9)

prs.save(OUT)
print("saved", OUT)
