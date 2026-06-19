const puppeteer = require('puppeteer');

async function testUrl(url) {
  console.log(`\n\n==== Testing ${url} ====`);
  const browser = await puppeteer.launch({ headless: 'new' });
  const page = await browser.newPage();

  page.on('console', msg => console.log(`[BROWSER CONSOLE] ${msg.type().toUpperCase()}: ${msg.text()}`));
  page.on('pageerror', err => {
    console.log(`[PAGE ERROR]: ${err.message}`);
    console.log(`[STACK]: ${err.stack}`);
  });

  try {
    await page.goto(url, { waitUntil: 'networkidle0', timeout: 15000 });
    await new Promise(r => setTimeout(r, 2000));
  } catch (err) {
    console.log(`[NAVIGATION ERROR]: ${err.message}`);
  }

  await browser.close();
}

(async () => {
  await testUrl('http://localhost:8101'); // user_app
})();
