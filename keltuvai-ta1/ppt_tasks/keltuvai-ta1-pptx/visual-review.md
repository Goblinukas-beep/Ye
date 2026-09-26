# Visual review (LibreOffice → PDF → PNG, 1280×720)

Runtime: pptx-designer 1.0.0b11 (/usr/local/lib/python3.11/dist-packages/pptx_designer). Resolved theme: resolved-theme-v1.json.
Preview fonts: Gelasio/Carlito stand in for Georgia/Calibri (metric-compatible); Consolas previewed with DejaVu Sans Mono.

## Round 1 — NEEDS_REVISION
- S1 title descenders overlapped the lede → title 68 pt, tighter leading, lede moved down.
- S2 big figures overlapped captions → figures 90 pt, captions moved below.
- S4 verdict tag text wrapped outside its box → wider tags, single-line mono.
- S5 bridge sentence wrapped into the source line → 17 pt, one line.
- S6 equation operators collided → re-spaced, 50 pt figures.
- S7 element name wrapped → wider column.

## Round 2 — PASS
Gate 1: each slide has one anchor (title, stat row, ledger, schematics, split, equation, task statement, selection table, index).
Gate 2: no overflow, overlap or clipping; citations present on every data slide; all text editable.
