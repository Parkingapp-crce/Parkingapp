const puppeteer = require('puppeteer');

async function testUrl(url) {
  console.log(`\n\n==== Testing ${url} ====`);
  const browser = await puppeteer.launch({ headless: 'new' });
  const page = await browser.newPage();

  page.on('console', msg => console.log(`[BROWSER CONSOLE] ${msg.type().toUpperCase()}: ${msg.text()}`));
  page.on('pageerror', err => console.log(`[PAGE ERROR]: ${err.toString()}`));
  page.on('requestfailed', request => {
    console.log(`[NETWORK FAIL]: ${request.url()} - ${request.failure().errorText}`);
  });

  try {
    await page.goto(url, { waitUntil: 'networkidle2', timeout: 15000 });
    console.log('Page loaded successfully.');
    // Wait an extra 5 seconds for flutter rendering
    await new Promise(r => setTimeout(r, 5000));
  } catch (err) {
    console.log(`[NAVIGATION ERROR]: ${err.message}`);
  }

  await browser.close();
}

(async () => {
  await testUrl('http://localhost:8101'); // user_app
  await testUrl('http://localhost:8105'); // park_owner
})();
