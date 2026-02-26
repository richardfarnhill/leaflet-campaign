#!/usr/bin/env node
/**
 * Leaflet Campaign - Automated Test Runner
 * Run with: node tests/runner.js
 */

const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

const APP_URL = 'file://' + path.resolve(__dirname, '../index.html');
const RESULTS = [];

function log(msg) {
  console.log(`[${new Date().toISOString().slice(11,19)}] ${msg}`);
}

function report(test, status, message) {
  RESULTS.push({ test, status, message });
  const icon = status === 'pass' ? '✓' : status === 'fail' ? '✗' : '○';
  const color = status === 'pass' ? '\x1b[32m' : status === 'fail' ? '\x1b[31m' : '\x1b[33m';
  console.log(`${color}${icon}\x1b[0m ${test}: ${message}`);
}

async function runTests() {
  log('Starting test suite...');
  
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  
  const page = await browser.newPage();
  
  // Capture console logs from the app
  page.on('console', msg => {
    if (msg.type() === 'error') {
      log(`APP ERROR: ${msg.text()}`);
    }
  });
  
  try {
    // Load the app
    log('Loading app...');
    await page.goto(APP_URL, { waitUntil: 'networkidle0', timeout: 30000 });
    log('App loaded');
    
    // Wait for app to initialize
    await page.waitForFunction(() => {
      return document.getElementById('campaignSelect') !== null;
    }, { timeout: 10000 });
    
    // ============================================================
    // TEST CASES
    // ============================================================
    
    // Test 1: App loads
    report('App Loads', 'pass', 'index.html loaded successfully');
    
    // Test 2: No credentials exposed
    const html = await page.evaluate(() => document.documentElement.outerHTML);
    const hasUrl = html.includes('tjebidvgvbpnxgnphcrg.supabase.co');
    const hasKey = html.includes('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9');
    if (!hasUrl && !hasKey) {
      report('No Credentials Exposed', 'pass', 'Supabase URL/key not in source');
    } else {
      report('No Credentials Exposed', 'fail', 'Found hardcoded credentials in source');
    }
    
    // Test 3: Campaign select exists
    const hasCampaignSelect = await page.evaluate(() => {
      return document.getElementById('campaignSelect') !== null;
    });
    if (hasCampaignSelect) {
      report('Campaign Select Exists', 'pass', 'Campaign dropdown found');
    } else {
      report('Campaign Select Exists', 'fail', 'Campaign dropdown not found');
    }
    
    // Test 4: Route cards section exists
    const hasRoutesSection = await page.evaluate(() => {
      return document.getElementById('routesSection') !== null || 
             document.querySelector('.area-card') !== null;
    });
    if (hasRoutesSection) {
      report('Routes Section Exists', 'pass', 'Routes section found');
    } else {
      report('Routes Section Exists', 'fail', 'Routes section not found');
    }
    
    // Test 5: Enquiry modal exists
    const hasEnquiryModal = await page.evaluate(() => {
      return document.getElementById('enquiryModal') !== null;
    });
    if (hasEnquiryModal) {
      report('Enquiry Modal Exists', 'pass', 'Enquiry modal HTML found');
    } else {
      report('Enquiry Modal Exists', 'fail', 'Enquiry modal not found');
    }
    
    // Test 6: Map container exists
    const hasMapContainer = await page.evaluate(() => {
      return document.getElementById('analyticsMap') !== null;
    });
    if (hasMapContainer) {
      report('Map Container Exists', 'pass', 'Map container found');
    } else {
      report('Map Container Exists', 'fail', 'Map container not found');
    }
    
    // Test 7: Summary stats exist
    const hasSummaryStats = await page.evaluate(() => {
      return document.getElementById('sumDelivered') !== null &&
             document.getElementById('sumRemaining') !== null;
    });
    if (hasSummaryStats) {
      report('Summary Stats Exist', 'pass', 'Summary bar elements found');
    } else {
      report('Summary Stats Exist', 'fail', 'Summary elements not found');
    }
    
    // Test 8: Settings section exists
    const hasSettings = await page.evaluate(() => {
      return document.getElementById('settingsSection') !== null ||
             document.body.innerHTML.includes('Settings');
    });
    if (hasSettings) {
      report('Settings Section Exists', 'pass', 'Settings section found');
    } else {
      report('Settings Section Exists', 'fail', 'Settings section not found');
    }
    
    // Test 9: No JavaScript errors on load
    const jsErrors = [];
    page.on('pageerror', err => jsErrors.push(err.message));
    await page.waitForTimeout(2000);
    if (jsErrors.length === 0) {
      report('No JS Errors', 'pass', 'No JavaScript errors detected');
    } else {
      report('No JS Errors', 'fail', `Found ${jsErrors.length} JS error(s): ${jsErrors[0]}`);
    }
    
    // Test 10: config.js is loaded
    const hasConfig = await page.evaluate(() => {
      return typeof CONFIG !== 'undefined' && 
             CONFIG.SUPABASE_URL !== undefined;
    });
    if (hasConfig) {
      report('Config Loaded', 'pass', 'CONFIG object found with SUPABASE_URL');
    } else {
      report('Config Loaded', 'fail', 'CONFIG not loaded from config.js');
    }
    
  } catch (e) {
    log('ERROR: ' + e.message);
    report('Test Suite', 'fail', e.message);
  }
  
  await browser.close();
  
  // Summary
  const passed = RESULTS.filter(r => r.status === 'pass').length;
  const failed = RESULTS.filter(r => r.status === 'fail').length;
  const total = RESULTS.length;
  
  console.log('\n' + '='.repeat(50));
  if (failed === 0) {
    console.log(`\x1b[32m🎉 ALL TESTS PASSED (${passed}/${total})\x1b[0m`);
  } else {
    console.log(`\x1b[31m❌ ${failed} TEST(S) FAILED - ${passed}/${total} passed\x1b[0m`);
  }
  console.log('='.repeat(50));
  
  process.exit(failed > 0 ? 1 : 0);
}

runTests().catch(e => {
  console.error('Test runner failed:', e);
  process.exit(1);
});
