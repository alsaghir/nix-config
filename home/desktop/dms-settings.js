// Build-time helper for home/desktop/dms.nix: writes settings.json with the keys DMS loads whole
// (a declared value replaces its default instead of merging with it) derived from the installed
// DMS's own defaults (SettingsSpec.js) plus our changes, so they keep tracking upstream on every
// DMS update. A missing default, bar anchor or patched id fails the build instead of the desktop.
// Usage: node dms-settings.js <SettingsSpec.js> <settings.json> <overrides.json> <out>
//   overrides.json: { bar: <bar overrides>, patches: { <SettingsSpec key>: <patch> } }
const fs = require("fs");
const path = require("path");
const [specPath, settingsPath, overridesPath, outPath] = process.argv.slice(2);

// SettingsSpec.js is a QML ".pragma library" script: drop the pragma, load its ".import"s
// recursively and expose its top-level names. Qt is unused by the defaults; a stub satisfies it.
function loadQmlLibrary(file, loaded = {}) {
  if (loaded[file]) return loaded[file];
  const imports = {};
  const src = fs
    .readFileSync(file, "utf8")
    .replace(/^\.pragma.*$/gm, "")
    .replace(/^\.import\s+"([^"]+)"\s+as\s+(\w+).*$/gm, (_, rel, name) => {
      imports[name] = loadQmlLibrary(path.resolve(path.dirname(file), rel), loaded);
      return "";
    });
  const names = [...src.matchAll(/^(?:var|const|let|function)\s+(\w+)/gm)].map((m) => m[1]);
  const qt = new Proxy({}, { get: () => () => ({}) });
  const body = `"use strict";\n${src}\nreturn { ${names.join(", ")} };`;
  return (loaded[file] = Function(...Object.keys(imports), "Qt", body)(...Object.values(imports), qt));
}
const { SPEC } = loadQmlLibrary(path.resolve(specPath));
function stockDefault(key) {
  if (!SPEC?.[key] || !("def" in SPEC[key])) throw new Error(`no default for "${key}" in ${specPath}`);
  return structuredClone(SPEC[key].def);
}

const isObject = (value) => value !== null && typeof value === "object" && !Array.isArray(value);
// Objects merge recursively; any other value replaces.
function deepMerge(base, patch) {
  if (!isObject(base) || !isObject(patch)) return patch;
  const merged = { ...base };
  for (const [key, value] of Object.entries(patch)) merged[key] = deepMerge(base[key], value);
  return merged;
}
// An object default takes a deep-merged patch; a list of { id, ... } (e.g. lock screen widgets)
// takes a list of { id, ...fields } merged into the entry with that id.
function patchDefault(key, patch) {
  const def = stockDefault(key);
  if (!Array.isArray(def)) return deepMerge(def, patch);
  if (!Array.isArray(patch)) throw new Error(`${key}: default is a list, patch must be one too`);
  for (const { id, ...fields } of patch) {
    const at = def.findIndex((entry) => entry?.id === id);
    if (at < 0) throw new Error(`${key}: no entry "${id}" in [${def.map((entry) => entry?.id)}]`);
    def[at] = deepMerge(def[at], fields);
  }
  return def;
}

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
function buildBar({ replaceDefaults = false, ...overrides }) {
  const bar = stockDefault("barConfigs")[0];
  if (!bar || bar.id !== "default" || !Array.isArray(bar.rightWidgets))
    throw new Error(`default bar not found in ${specPath}`);
  // Density-driven sizes: omitted so DMS falls back to the density preset, as for its stock bar.
  delete bar.innerPadding;
  delete bar.widgetPadding;
  for (const [key, value] of Object.entries(overrides)) {
    const merge = !replaceDefaults && Array.isArray(value) && Array.isArray(bar[key]);
    bar[key] = merge ? mergeList(key, bar[key], value) : value;
  }
  return bar;
}

const settings = JSON.parse(fs.readFileSync(settingsPath, "utf8"));
const { bar, patches = {} } = JSON.parse(fs.readFileSync(overridesPath, "utf8"));
for (const key of ["barConfigs", ...Object.keys(patches)])
  if (key in settings) throw new Error(`"${key}" is generated here; declare it in the patches, not in settings`);
settings.barConfigs = [buildBar(bar)];
for (const [key, patch] of Object.entries(patches)) settings[key] = patchDefault(key, patch);
fs.writeFileSync(outPath, JSON.stringify(settings, null, 2));
