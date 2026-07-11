"use strict";

/**
 * Returns the ISO-8601 week identifier for a date, e.g. "2026-W28".
 * ISO weeks start on Monday; the week containing the year's first Thursday is
 * week 1. Uses the ISO week-year, which can differ from the calendar year for
 * dates in late December / early January.
 */
function isoWeek(date = new Date()) {
  const d = new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate())
  );
  // Shift to the Thursday of the current ISO week (Mon=0..Sun=6).
  const dayNum = (d.getUTCDay() + 6) % 7;
  d.setUTCDate(d.getUTCDate() - dayNum + 3);

  const firstThursday = new Date(Date.UTC(d.getUTCFullYear(), 0, 4));
  const firstDayNum = (firstThursday.getUTCDay() + 6) % 7;
  firstThursday.setUTCDate(firstThursday.getUTCDate() - firstDayNum + 3);

  const week =
    1 + Math.round((d - firstThursday) / (7 * 24 * 3600 * 1000));
  return `${d.getUTCFullYear()}-W${String(week).padStart(2, "0")}`;
}

module.exports = { isoWeek };
