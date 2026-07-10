"use strict";

const ExcelJS = require("exceljs");

/**
 * Reads every relevant tab of the authoring workbook into plain row objects.
 * Returns { [tabName]: { rows: [{ __row, __sheet, ...cells }], headers: string[] } }
 * `__row` is the 1-indexed spreadsheet row number (for error messages).
 */
async function readWorkbook(filePath, tabNames) {
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.readFile(filePath);

  const result = {};
  for (const tabName of tabNames) {
    const sheet = workbook.getWorksheet(tabName);
    if (!sheet) {
      result[tabName] = { rows: [], headers: [], missing: true };
      continue;
    }

    const headerRow = sheet.getRow(1);
    const headers = [];
    headerRow.eachCell({ includeEmpty: false }, (cell, colNumber) => {
      headers[colNumber] = String(cell.value ?? "").trim();
    });

    const rows = [];
    sheet.eachRow((row, rowNumber) => {
      if (rowNumber === 1) return; // header
      const isEmpty = row.values.every(
        (v) => v === null || v === undefined || String(v).trim() === ""
      );
      if (isEmpty) return;

      const rowObj = { __row: rowNumber, __sheet: tabName };
      row.eachCell({ includeEmpty: true }, (cell, colNumber) => {
        const header = headers[colNumber];
        if (!header) return;
        rowObj[header] = normalizeCellValue(cell.value);
      });
      rows.push(rowObj);
    });

    result[tabName] = { rows, headers: headers.filter(Boolean) };
  }

  return result;
}

function normalizeCellValue(value) {
  if (value === null || value === undefined) return "";
  if (typeof value === "object" && value.text !== undefined) return String(value.text).trim();
  if (typeof value === "object" && value.result !== undefined) return String(value.result).trim();
  return String(value).trim();
}

module.exports = { readWorkbook };
