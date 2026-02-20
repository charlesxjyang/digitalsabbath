// Digital Sabbath — Background Service Worker
// Enables site blocking on sabbath days, disables it otherwise.

// Sabbath dates — add new dates here as "YYYY-MM-DD"
const SABBATH_DATES = [
  "2026-06-21", // Summer solstice 2026
];

const RULESET_ID = "sabbath_rules";
const ALARM_NAME = "sabbath-check";

// Check if a given date falls on a sabbath day
function isSabbathDay(date) {
  const dateStr =
    date.getFullYear() +
    "-" +
    String(date.getMonth() + 1).padStart(2, "0") +
    "-" +
    String(date.getDate()).padStart(2, "0");
  return SABBATH_DATES.includes(dateStr);
}

// Check if debug mode is enabled via storage
async function isDebugMode() {
  try {
    const result = await chrome.storage.local.get("debugSabbath");
    return result.debugSabbath === true;
  } catch {
    return false;
  }
}

// Enable or disable the blocking ruleset
async function updateBlockingState() {
  const today = new Date();
  const debug = await isDebugMode();
  const shouldBlock = isSabbathDay(today) || debug;

  const currentRulesets = await chrome.declarativeNetRequest.getEnabledRulesets();
  const isEnabled = currentRulesets.includes(RULESET_ID);

  if (shouldBlock && !isEnabled) {
    await chrome.declarativeNetRequest.updateEnabledRulesets({
      enableRulesetIds: [RULESET_ID],
    });
    console.log("[Digital Sabbath] Blocking enabled — it's sabbath day.");
  } else if (!shouldBlock && isEnabled) {
    await chrome.declarativeNetRequest.updateEnabledRulesets({
      disableRulesetIds: [RULESET_ID],
    });
    console.log("[Digital Sabbath] Blocking disabled — not sabbath day.");
  } else {
    console.log(
      `[Digital Sabbath] No change needed. Blocking: ${isEnabled}, Should block: ${shouldBlock}`
    );
  }
}

// Set up a daily alarm to re-check at midnight
function setupDailyAlarm() {
  chrome.alarms.create(ALARM_NAME, {
    periodInMinutes: 60, // Check every hour (catches midnight reliably)
  });
}

// --- Event listeners ---

// On install or browser startup
chrome.runtime.onInstalled.addListener(() => {
  console.log("[Digital Sabbath] Extension installed.");
  updateBlockingState();
  setupDailyAlarm();
});

chrome.runtime.onStartup.addListener(() => {
  console.log("[Digital Sabbath] Browser started.");
  updateBlockingState();
  setupDailyAlarm();
});

// On alarm (periodic check)
chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === ALARM_NAME) {
    updateBlockingState();
  }
});

// Listen for storage changes (debug mode toggled)
chrome.storage.onChanged.addListener((changes, area) => {
  if (area === "local" && changes.debugSabbath) {
    console.log(
      `[Digital Sabbath] Debug mode ${changes.debugSabbath.newValue ? "enabled" : "disabled"}.`
    );
    updateBlockingState();
  }
});
