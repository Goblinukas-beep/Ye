# Domkratas – PBL TA1 pristatymas

| Failas | Paskirtis |
|---|---|
| `domkratas-ta1.pptx` | Redaguojamas PowerPoint (14 skaidrių, su kalbėtojo pastabomis) |
| `domkratas-ta1.html` | Animuota versija naršyklėje (← → klavišai; E – redaguoti tekstą) |
| `domkratas-ta1.pdf` | Statinė PDF kopija |
| `src/` | Schemų (SVG) ir HTML generatoriai |
| `ppt_tasks/domkratas-ta1-pptx/build_deck.py` | PPTX generatorius |

Perkūrimas: `cd src && python3 diagrams.py && node render.js svg diagrams png && python3 build_html.py`,
tada `python3 ppt_tasks/domkratas-ta1-pptx/build_deck.py`.
