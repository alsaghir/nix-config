// Build-time helper for home/dms.nix: writes settings.json with a bar derived from the installed
// DMS's own default (SettingsSpec.js barConfigs.def[0]) plus our overrides, so the bar tracks
// upstream defaults on every DMS update. Fails the build if the default can't be found.
// Usage: node dms-bar.js <SettingsSpec.js> <settings.json> <bar-overrides.json> <out>
const fs = require("fs");
const [specPath, settingsPath, overridesPath, outPath] = process.argv.slice(2);

const src = fs.readFileSync(specPath, "utf8");
const start = src.indexOf("[", src.indexOf("def:", src.indexOf("barConfigs:")));
let depth = 0;
let end = start;
for (; end < src.length; end++) {
  if (src[end] === "[") depth++;
  else if (src[end] === "]" && --depth === 0) break;
}
const bar = Function(`"use strict"; return ${src.slice(start, end + 1)};`)()[0];
if (!bar || bar.id !== "default" || !Array.isArray(bar.rightWidgets))
  throw new Error(`default bar not found in ${specPath}`);

// Density-driven sizes: omitted so DMS falls back to the density preset, as for its stock bar.
delete bar.innerPadding;
delete bar.widgetPadding;

const settings = JSON.parse(fs.readFileSync(settingsPath, "utf8"));
// replaceDefaults = false: list fields (e.g. rightWidgets) are merged into the stock list;
// true: they replace it. Scalar fields always replace.
// A merged entry is either an id (appended) or { id, before } / { id, after } (placed next to
// that stock id). A missing anchor fails the build instead of misplacing the widget.
function mergeList(key, base, additions) {
  const list = [...base];
  for (const entry of additions) {
    const { id, before, after } = typeof entry === "string" ? { id: entry } : entry;
    if (list.includes(id)) continue;
    const anchor = before ?? after;
    if (anchor === undefined) {
      list.push(id);
      continue;
    }
    const at = list.indexOf(anchor);
    if (at < 0) throw new Error(`${key}: anchor "${anchor}" for "${id}" not in [${list}]`);
    list.splice(before !== undefined ? at : at + 1, 0, id);
  }
  return list;
}
const { replaceDefaults = false, ...overrides } = JSON.parse(fs.readFileSync(overridesPath, "utf8"));
for (const [key, value] of Object.entries(overrides)) {
  const merge = !replaceDefaults && Array.isArray(value) && Array.isArray(bar[key]);
  bar[key] = merge ? mergeList(key, bar[key], value) : value;
}
settings.barConfigs = [bar];
fs.writeFileSync(outPath, JSON.stringify(settings, null, 2));
