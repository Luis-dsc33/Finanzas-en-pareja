const puppeteer = require('puppeteer');
const path = require('path');

async function run() {
  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();
  
  // Set viewport for a mobile-like size
  await page.setViewport({ width: 375, height: 812 });
  
  console.log('Navigating to app...');
  await page.goto('http://127.0.0.1:8080', { waitUntil: 'networkidle0', timeout: 60000 });
  
  // Wait for flutter canvas to load
  await page.waitForSelector('flt-glass-pane', { timeout: 60000 }).catch(() => console.log('flt-glass-pane not found, continuing...'));
  await new Promise(r => setTimeout(r, 5000)); // extra wait for flutter to render

  console.log('Taking login screenshot...');
  await page.screenshot({ path: path.join(__dirname, 'docs', 'capturas', 'login.png') });
  
  console.log('Taking screenshots done.');
  await browser.close();
}

run().catch(console.error);
