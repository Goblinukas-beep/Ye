// Naudojimas:
//   node render.js svg <svg_dir> <png_dir>        – kiekvieną schemą paverčia PNG (PPTX versijai)
//   node render.js deck <html> <png_dir> [w] [h]   – nufotografuoja kiekvieną skaidrę
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
(async () => {
  const [mode, src, out, W = '1920', H = '1080'] = process.argv.slice(2);
  fs.mkdirSync(out, { recursive: true });
  const proxy = process.env.HTTPS_PROXY ? { server: process.env.HTTPS_PROXY } : undefined;
  const browser = await chromium.launch({ proxy, args: ['--ignore-certificate-errors'] });
  if (mode === 'svg') {
    const page = await browser.newPage({ deviceScaleFactor: 3, ignoreHTTPSErrors: true });
    for (const f of fs.readdirSync(src).filter(f => f.endsWith('.svg'))) {
      const svg = fs.readFileSync(path.join(src, f), 'utf8');
      await page.setContent(`<html><head><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;700&display=swap" rel="stylesheet"><style>body{margin:0;background:transparent}</style></head><body>${svg}</body></html>`, { waitUntil: 'networkidle' });
      await page.evaluate(() => document.fonts.ready);
      await (await page.$('svg')).screenshot({ path: path.join(out, f.replace('.svg', '.png')), omitBackground: true });
    }
  } else {
    const page = await browser.newPage({ viewport: { width: +W, height: +H }, ignoreHTTPSErrors: true });
    await page.goto('file://' + path.resolve(src), { waitUntil: 'networkidle' });
    await page.evaluate(() => document.fonts.ready);
    const n = await page.evaluate(() => document.querySelectorAll('.slide').length);
    for (let i = 0; i < n; i++) {
      await page.mouse.move(960, 600);
      await page.evaluate(i => window.deck.showSlide(i), i);
      await page.waitForTimeout(1300);
      await page.screenshot({ path: path.join(out, `s${String(i + 1).padStart(2, '0')}.png`) });
    }
  }
  await browser.close();
})();
