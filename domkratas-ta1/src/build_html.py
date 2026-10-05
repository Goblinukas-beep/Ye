"""Surenka galutinį HTML: įstato SVG schemas į deck.template.html → ../domkratas-ta1.html"""
import re
from pathlib import Path
import diagrams as d

HERE = Path(__file__).parent
counter = 0


def inline(svg):
    """Kiekvienai įterptai schemai suteikia unikalius marker id (kad nesikirstų dokumente)."""
    global counter
    counter += 1
    svg = svg.replace('id="ah', f'id="m{counter}ah').replace('url(#ah', f'url(#m{counter}ah')
    return re.sub(r' width="\d+" height="\d+"', '', svg, count=1)


def cover():
    s = d.scissor(theta=False)
    return s.replace(d.INK, "#ECEAE4").replace(d.PAPER, d.INK).replace(d.SOFT, "#8B8F95")


svgs = {k: f for k, f in d.ALL.items()}
svgs["cover"] = cover
html = (HERE / "deck.template.html").read_text(encoding="utf-8")
html = re.sub(r"\{\{svg:(\w+)\}\}", lambda m: inline(svgs[m.group(1)]() if callable(svgs[m.group(1)]) else svgs[m.group(1)]), html)
(HERE.parent / "domkratas-ta1.html").write_text(html, encoding="utf-8")
print("ok", len(html))
