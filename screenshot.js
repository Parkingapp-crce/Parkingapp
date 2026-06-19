const puppeteer = require('puppeteer');
const fs = require('fs');

async function takeScreenshot(url, filename) {
  console.log(`Taking screenshot of ${url}...`);
  const browser = await puppeteer.launch({ headless: 'new' });
  const page = await browser.newPage();
  
  await page.setViewport({ width: 1280, height: 800 });
  
  try {
    await page.goto(url, { waitUntil: 'networkidle0', timeout: 15000 });
    // Wait an additional 5 seconds to ensure flutter canvaskit renders
    await new Promise(r => setTimeout(r, 5000));
    await page.screenshot({ path: filename });
    console.log(`Saved screenshot to ${filename}`);
  } catch (err) {
    console.error(`Error: ${err}`);
  }
  await browser.close();
}

(async () => {
  await takeScreenshot('http://localhost:8101', 'user_app_screenshot.png');
  await takeScreenshot('http://localhost:8105', 'park_owner_screenshot.png');
})();
