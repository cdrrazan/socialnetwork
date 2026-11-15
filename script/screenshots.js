// Regenerates the README screenshots in doc/screenshots/.
//
// Usage: start the app with seed data (bin/setup, or bin/rails db:seed and
// bin/dev), then run:
//
//   npm install --no-save playwright && npx playwright install chromium   # first time only
//   node script/screenshots.js   # BASE_URL defaults to http://localhost:3000

const { chromium, devices } = require('playwright');
const path = require('path');
const out = path.join(__dirname, '..', 'doc', 'screenshots') + '/';
const base = process.env.BASE_URL || 'http://localhost:3000';
(async () => {
  const b = await chromium.launch();
  const ctx = await b.newContext({ viewport: { width: 1280, height: 800 }, deviceScaleFactor: 2 });
  const p = await ctx.newPage();
  const shot = async (name, full=false) => { await p.waitForLoadState('networkidle'); await p.screenshot({ path: out + name + '.png', fullPage: full }); console.log(name); };
  await p.goto(base + '/'); await shot('landing');
  await p.goto(base + '/users/sign_up'); await shot('sign-up');
  await p.goto(base + '/users/sign_in');
  await p.fill('#user_email', 'code@example.com'); await p.fill('#user_password', 'password');
  await Promise.all([p.waitForURL(u => !u.toString().includes('sign_in')), p.locator('main').getByRole('button', { name: 'Log in' }).click()]);
  await shot('blog');
  await Promise.all([p.waitForURL(/\/posts\/\d+/), p.getByRole('link', { name: 'Getting started with Ruby on Rails 8' }).first().click()]); await p.waitForSelector('h1:has-text("Getting started")'); await p.evaluate(() => window.scrollTo(0, 0)); await shot('post', true);
  await p.goto(base + '/posts/new'); await p.fill('#post_title', 'Deploying Rails 8 with Kamal');
  await p.locator('trix-editor').click(); await p.keyboard.type('Kamal deploys a Rails app to any server with a single command. ');
  await p.keyboard.press('Control+b'); await p.keyboard.type('No PaaS required.');
  await p.fill('#post_tag_list', 'rails, deployment'); await shot('editor');
  await p.goto(base + '/questions'); await shot('forum');
  await Promise.all([p.waitForURL(/\/questions\/\d+/), p.getByRole('link', { name: /How do I run a single Minitest test/ }).click()]); await p.waitForSelector('h1:has-text("Minitest")'); await shot('question');
  await p.goto(base + '/users'); await shot('people');
  await p.goto(base + '/activities'); await shot('activity');
  await p.goto(base + '/conversations'); await Promise.all([p.waitForURL(/\/conversations\/\d+/), p.locator('.list-group-item').first().click()]); await p.waitForSelector('h1:has-text("Conversation with")'); await shot('conversation');
  await p.goto(base + '/profile'); await shot('profile');
  const m = await b.newContext({ ...devices['iPhone 13'] });
  const mp = await m.newPage(); await mp.goto(base + '/'); await mp.waitForLoadState('networkidle');
  await mp.screenshot({ path: out + 'mobile.png' }); console.log('mobile');
  const a = await b.newPage({ viewport: { width: 1280, height: 800 }, deviceScaleFactor: 2 });
  await a.goto(base + '/admin/login'); await a.fill('#admin_user_email', 'admin@example.com'); await a.fill('#admin_user_password', 'password');
  await Promise.all([a.waitForURL(u => !u.toString().includes('login')), a.click('input[type=submit]')]);
  await a.waitForLoadState('networkidle'); await a.screenshot({ path: out + 'admin.png' }); console.log('admin');
  await b.close();
})();
