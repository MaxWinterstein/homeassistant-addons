/**
 * Tests for jest.config.js
 *
 * Testing framework/library: Jest
 * These tests validate that the exported Jest configuration has the expected shape and values.
 * They are intentionally resilient to optional keys: if a key exists, we validate it is correct.
 */

const path = require('path');
const fs = require('fs');

const loadConfig = async () => {
  const configPath = path.resolve(process.cwd(), 'jest.config.js');

  // Try requiring as CommonJS first.
  try {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const cjs = require(configPath);
    // module.exports may be either the config or { default: config }
    if (cjs && typeof cjs === 'object' && 'default' in cjs && cjs.default && typeof cjs.default === 'object') {
      return cjs.default;
    }
    return cjs;
  } catch (e) {
    // Fall back to dynamic import for ESM
    try {
      const esm = await import(configPath + (configPath.endsWith('.js') ? '' : '.js'));
      if (esm && typeof esm === 'object') {
        return esm.default ?? esm;
      }
      throw new Error('Invalid ESM export for jest.config.js');
    } catch (inner) {
      // As a last resort, attempt to evaluate the file in a VM-like manner (rarely needed)
      throw new Error('Unable to load jest.config.js as CJS or ESM. Original errors: ' + String(e) + ' | ' + String(inner));
    }
  }
};

const hasKey = (obj, key) => Object.prototype.hasOwnProperty.call(obj, key);
const expectArrayOfStrings = (arr) => {
  expect(Array.isArray(arr)).toBe(true);
  for (const item of arr) {
    expect(typeof item === 'string').toBe(true);
  }
};
const expectObjectOfStringValues = (obj) => {
  expect(obj && typeof obj === 'object').toBe(true);
  for (const [k, v] of Object.entries(obj)) {
    expect(typeof k === 'string').toBe(true);
    if (typeof v !== 'string') {
      // Some mappers may be arrays; allow string or array of strings
      if (Array.isArray(v)) {
        v.forEach((x) => expect(typeof x === 'string').toBe(true));
      } else {
        throw new Error(`Value for key ${k} is not a string or string[]`);
      }
    }
  }
};

describe('jest.config.js', () => {
  let cfg;

  beforeAll(async () => {
    const exists = fs.existsSync(path.resolve(process.cwd(), 'jest.config.js'));
    expect(exists).toBe(true);
    cfg = await loadConfig();
  });

  test('exports a plain object configuration', () => {
    expect(cfg).toBeTruthy();
    expect(typeof cfg).toBe('object');
    expect(Array.isArray(cfg)).toBe(false);
  });

  test('has a valid test environment if specified', () => {
    if (hasKey(cfg, 'testEnvironment')) {
      expect(typeof cfg.testEnvironment).toBe('string');
      // Common values: node, jsdom
      expect(['node', 'jsdom', 'jest-environment-node', 'jest-environment-jsdom'].includes(cfg.testEnvironment)).toBe(true);
    }
  });

  test('has valid testMatch/testRegex configuration', () => {
    const hasMatch = hasKey(cfg, 'testMatch');
    const hasRegex = hasKey(cfg, 'testRegex');
    // At least one strategy should be present
    expect(hasMatch || hasRegex).toBe(true);

    if (hasMatch) {
      expectArrayOfStrings(cfg.testMatch);
      // Basic sanity: patterns should include test or spec
      const joined = cfg.testMatch.join(' ');
      expect(/test|spec/.test(joined)).toBe(true);
    }
    if (hasRegex) {
      if (Array.isArray(cfg.testRegex)) {
        cfg.testRegex.forEach((rx) => expect(typeof rx === 'string' || rx instanceof RegExp).toBe(true));
      } else {
        expect(typeof cfg.testRegex === 'string' || cfg.testRegex instanceof RegExp).toBe(true);
      }
    }
  });

  test('transform configuration (if present) uses supported transformers', () => {
    if (hasKey(cfg, 'transform')) {
      expect(cfg.transform && typeof cfg.transform === 'object').toBe(true);
      // Check keys look like file globs or regexes
      Object.keys(cfg.transform).forEach((k) => {
        expect(typeof k).toBe('string');
      });
      // Values should be strings (module names) or arrays [path, options]
      Object.values(cfg.transform).forEach((v) => {
        if (Array.isArray(v)) {
          expect(v.length).toBeGreaterThan(0);
          expect(typeof v[0] === 'string').toBe(true);
        } else {
          expect(typeof v === 'string').toBe(true);
        }
      });
    }
  });

  test('moduleNameMapper (if present) maps strings to strings or arrays', () => {
    if (hasKey(cfg, 'moduleNameMapper')) {
      expectObjectOfStringValues(cfg.moduleNameMapper);
    }
  });

  test('setupFiles and setupFilesAfterEnv (if present) are arrays of strings', () => {
    if (hasKey(cfg, 'setupFiles')) {
      expectArrayOfStrings(cfg.setupFiles);
    }
    if (hasKey(cfg, 'setupFilesAfterEnv')) {
      expectArrayOfStrings(cfg.setupFilesAfterEnv);
    }
  });

  test('collectCoverage and coverage related keys (if present) are consistent', () => {
    if (hasKey(cfg, 'collectCoverage')) {
      expect(typeof cfg.collectCoverage).toBe('boolean');
    }
    if (hasKey(cfg, 'collectCoverageFrom')) {
      expectArrayOfStrings(cfg.collectCoverageFrom);
    }
    if (hasKey(cfg, 'coverageDirectory')) {
      expect(typeof cfg.coverageDirectory).toBe('string');
      expect(cfg.coverageDirectory.length).toBeGreaterThan(0);
    }
    if (hasKey(cfg, 'coverageReporters')) {
      expectArrayOfStrings(cfg.coverageReporters);
      // Basic sanity: common reporters
      const allowed = ['text', 'text-summary', 'lcov', 'json', 'html', 'cobertura', 'clover'];
      cfg.coverageReporters.forEach((r) => expect(allowed.includes(r)).toBe(true));
    }
    if (hasKey(cfg, 'coverageThreshold')) {
      // Should be an object with global/paths keys
      expect(cfg.coverageThreshold && typeof cfg.coverageThreshold === 'object').toBe(true);
    }
  });

  test('roots/rootDir/moduleDirectories/moduleFileExtensions (if present) are valid', () => {
    if (hasKey(cfg, 'roots')) {
      expectArrayOfStrings(cfg.roots);
    }
    if (hasKey(cfg, 'rootDir')) {
      expect(typeof cfg.rootDir).toBe('string');
      expect(cfg.rootDir.length).toBeGreaterThan(0);
    }
    if (hasKey(cfg, 'moduleDirectories')) {
      expectArrayOfStrings(cfg.moduleDirectories);
    }
    if (hasKey(cfg, 'moduleFileExtensions')) {
      expectArrayOfStrings(cfg.moduleFileExtensions);
      // Should include at least one common extension
      const common = ['js', 'jsx', 'ts', 'tsx', 'json', 'node', 'mjs', 'cjs'];
      expect(cfg.moduleFileExtensions.some((x) => common.includes(x))).toBe(true);
    }
  });

  test('bail/verbose/maxWorkers/cacheDirectory (if present) have sensible types', () => {
    if (hasKey(cfg, 'bail')) {
      expect(typeof cfg.bail === 'boolean' || typeof cfg.bail === 'number').toBe(true);
    }
    if (hasKey(cfg, 'verbose')) {
      expect(typeof cfg.verbose).toBe('boolean');
    }
    if (hasKey(cfg, 'maxWorkers')) {
      expect(['string', 'number'].includes(typeof cfg.maxWorkers)).toBe(true);
    }
    if (hasKey(cfg, 'cacheDirectory')) {
      expect(typeof cfg.cacheDirectory).toBe('string');
      expect(cfg.cacheDirectory.length).toBeGreaterThan(0);
    }
  });

  test('projects (if present) is an array of project configs or globs', () => {
    if (hasKey(cfg, 'projects')) {
      expect(Array.isArray(cfg.projects)).toBe(true);
      for (const p of cfg.projects) {
        expect(['string', 'object'].includes(typeof p)).toBe(true);
      }
    }
  });

  test('snapshot select stable properties for regression detection', () => {
    // Snapshot only a subset that is stable and important if present.
    const stable = {};
    ['testEnvironment', 'testMatch', 'testRegex', 'coverageReporters', 'verbose'].forEach((k) => {
      if (hasKey(cfg, k)) stable[k] = cfg[k];
    });
    expect(stable).toMatchSnapshot();
  });
});