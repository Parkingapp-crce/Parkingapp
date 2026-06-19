const puppeteer = require('puppeteer');

async function testUrl(url, name) {
  const browser = await puppeteer.launch({ headless: 'new' });
  const page = await browser.newPage();
  
  // Emulate dark mode
  await page.emulateMediaFeatures([{ name: 'prefers-color-scheme', value: 'dark' }]);
  await page.setViewport({ width: 1280, height: 800 });

  await page.goto(url, { waitUntil: 'networkidle2' });
  await new Promise(r => setTimeout(r, 2000)); 
  await page.screenshot({ path: name });
  await browser.close();
}

async function run() {
  await testUrl('http://localhost:8101', 'user_app_dark.png');
}

run();
