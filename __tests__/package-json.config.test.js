/* 
  Tests for package.json configuration.
  Test framework: Jest (default assumption).
  If this repo uses another framework (e.g., Mocha+Chai or Vitest), 
  adapt the assertions accordingly.
*/

const fs = require('fs');
const path = require('path');

function readRootPackageJson() {
  const pkgPath = path.resolve(process.cwd(), 'package.json');
  const raw = fs.readFileSync(pkgPath, 'utf8');
  let parsed;
  expect(() => {
    parsed = JSON.parse(raw);
  }).not.toThrow();
  return parsed;
}

describe('package.json configuration integrity', () => {
  let pkg;

  beforeAll(() => {
    pkg = readRootPackageJson();
  });

  test('should be a non-null object', () => {
    expect(pkg).toBeDefined();
    expect(typeof pkg).toBe('object');
    expect(Array.isArray(pkg)).toBe(false);
  });

  describe('required top-level fields', () => {
    test('should contain a non-empty "name" string', () => {
      expect(pkg).toHaveProperty('name');
      expect(typeof pkg.name).toBe('string');
      expect(pkg.name.trim().length).toBeGreaterThan(0);
    });

    test('should contain a non-empty "version" string in semver-like format', () => {
      expect(pkg).toHaveProperty('version');
      expect(typeof pkg.version).toBe('string');
      expect(pkg.version.trim().length).toBeGreaterThan(0);
      // Not enforcing strict semver; basic sanity check
      expect(pkg.version).toMatch(/^\d+\.\d+\.\d+(-[\w\.-]+)?$/);
    });

    test('should contain "scripts" object with a test script', () => {
      expect(pkg).toHaveProperty('scripts');
      expect(typeof pkg.scripts).toBe('object');
      // Not strictly required by npm, but highly conventional
      expect(pkg.scripts).toHaveProperty('test');
      expect(typeof pkg.scripts.test).toBe('string');
      expect(pkg.scripts.test.trim().length).toBeGreaterThan(0);
    });
  });

  describe('scripts shape', () => {
    test('all script values should be non-empty strings', () => {
      if (pkg.scripts && typeof pkg.scripts === 'object') {
        for (const [key, value] of Object.entries(pkg.scripts)) {
          expect(typeof value).toBe('string');
          expect(value.trim().length).toBeGreaterThan(0);
        }
      }
    });

    test('common lifecycle scripts (if present) should be strings', () => {
      const possible = ['build', 'start', 'lint', 'format', 'prepare', 'prepublishOnly'];
      for (const s of possible) {
        if (s in pkg.scripts) {
          expect(typeof pkg.scripts[s]).toBe('string');
        }
      }
    });
  });

  describe('dependencies and devDependencies', () => {
    const checkDeps = (obj, label) => {
      expect(typeof obj).toBe('object');
      for (const [dep, ver] of Object.entries(obj)) {
        expect(typeof dep).toBe('string');
        expect(dep.trim().length).toBeGreaterThan(0);
        expect(typeof ver).toBe('string');
        expect(ver.trim().length).toBeGreaterThan(0);
        // Basic sanity: versions frequently start with ^, ~, or a digit; allow URLs/git too
        expect(ver).toMatch(/^(\^|~)?\d+(\.\d+){0,2}.*|^file:|^git\+|^https?:\/\/|^\*|^link:/);
      }
    };

    test('"dependencies" (if present) should be a map of non-empty string versions', () => {
      if ('dependencies' in pkg) {
        checkDeps(pkg.dependencies, 'dependencies');
      }
    });

    test('"devDependencies" (if present) should be a map of non-empty string versions', () => {
      if ('devDependencies' in pkg) {
        checkDeps(pkg.devDependencies, 'devDependencies');
      }
    });

    test('"peerDependencies" (if present) should be a map of non-empty string versions', () => {
      if ('peerDependencies' in pkg) {
        checkDeps(pkg.peerDependencies, 'peerDependencies');
      }
    });

    test('"optionalDependencies" (if present) should be a map of non-empty string versions', () => {
      if ('optionalDependencies' in pkg) {
        checkDeps(pkg.optionalDependencies, 'optionalDependencies');
      }
    });
  });

  describe('metadata fields (if present)', () => {
    test('"license" should be a non-empty string when present', () => {
      if ('license' in pkg) {
        expect(typeof pkg.license).toBe('string');
        expect(pkg.license.trim().length).toBeGreaterThan(0);
      }
    });

    test('"type" should be "module" or "commonjs" when present', () => {
      if ('type' in pkg) {
        expect(['module', 'commonjs']).toContain(pkg.type);
      }
    });

    test('"repository" should be a valid object/string when present', () => {
      if ('repository' in pkg) {
        const repo = pkg.repository;
        if (typeof repo === 'string') {
          expect(repo.trim().length).toBeGreaterThan(0);
        } else if (typeof repo === 'object' && repo !== null) {
          expect(repo).toHaveProperty('type');
          expect(repo).toHaveProperty('url');
          expect(typeof repo.type).toBe('string');
          expect(typeof repo.url).toBe('string');
          expect(repo.url.trim().length).toBeGreaterThan(0);
        } else {
          throw new Error('repository must be string or object');
        }
      }
    });

    test('"bugs" should be a valid object/string when present', () => {
      if ('bugs' in pkg) {
        const bugs = pkg.bugs;
        if (typeof bugs === 'string') {
          expect(bugs.trim().length).toBeGreaterThan(0);
        } else if (typeof bugs === 'object' && bugs !== null) {
          if ('url' in bugs) {
            expect(typeof bugs.url).toBe('string');
            expect(bugs.url.trim().length).toBeGreaterThan(0);
          }
          if ('email' in bugs) {
            expect(typeof bugs.email).toBe('string');
            expect(bugs.email.trim().length).toBeGreaterThan(0);
          }
        } else {
          throw new Error('bugs must be string or object');
        }
      }
    });

    test('"homepage" should be a non-empty string URL when present', () => {
      if ('homepage' in pkg) {
        expect(typeof pkg.homepage).toBe('string');
        expect(pkg.homepage.trim().length).toBeGreaterThan(0);
      }
    });

    test('"engines" should be a non-empty object if present', () => {
      if ('engines' in pkg) {
        expect(typeof pkg.engines).toBe('object');
        expect(Object.keys(pkg.engines).length).toBeGreaterThan(0);
        for (const [engine, range] of Object.entries(pkg.engines)) {
          expect(typeof engine).toBe('string');
          expect(typeof range).toBe('string');
          expect(range.trim().length).toBeGreaterThan(0);
        }
      }
    });

    test('"packageManager" should be a non-empty string when present', () => {
      if ('packageManager' in pkg) {
        expect(typeof pkg.packageManager).toBe('string');
        expect(pkg.packageManager.trim().length).toBeGreaterThan(0);
      }
    });
  });

  describe('exports / main / module fields (if present)', () => {
    test('"main" should be a non-empty string when present', () => {
      if ('main' in pkg) {
        expect(typeof pkg.main).toBe('string');
        expect(pkg.main.trim().length).toBeGreaterThan(0);
      }
    });

    test('"module" should be a non-empty string when present', () => {
      if ('module' in pkg) {
        expect(typeof pkg.module).toBe('string');
        expect(pkg.module.trim().length).toBeGreaterThan(0);
      }
    });

    test('"types" should be a non-empty string when present', () => {
      if ('types' in pkg) {
        expect(typeof pkg.types).toBe('string');
        expect(pkg.types.trim().length).toBeGreaterThan(0);
      }
    });

    test('"exports" should be string/object with non-empty content when present', () => {
      if ('exports' in pkg) {
        const ex = pkg.exports;
        if (typeof ex === 'string') {
          expect(ex.trim().length).toBeGreaterThan(0);
        } else if (typeof ex === 'object' && ex !== null) {
          expect(Object.keys(ex).length).toBeGreaterThan(0);
        } else {
          throw new Error('exports must be a string or a non-null object');
        }
      }
    });
  });

  describe('funding / author / contributors (if present)', () => {
    test('"funding" may be a string or object; ensure non-empty if present', () => {
      if ('funding' in pkg) {
        const f = pkg.funding;
        if (typeof f === 'string') {
          expect(f.trim().length).toBeGreaterThan(0);
        } else if (typeof f === 'object' && f !== null) {
          // shape not strictly validated, but ensure not empty
          expect(Object.keys(f).length).toBeGreaterThan(0);
        } else {
          throw new Error('funding must be a string or non-null object');
        }
      }
    });

    test('"author" may be string/object; ensure non-empty if present', () => {
      if ('author' in pkg) {
        const a = pkg.author;
        if (typeof a === 'string') {
          expect(a.trim().length).toBeGreaterThan(0);
        } else if (typeof a === 'object' && a !== null) {
          // name recommended
          if ('name' in a) {
            expect(typeof a.name).toBe('string');
            expect(a.name.trim().length).toBeGreaterThan(0);
          }
        } else {
          throw new Error('author must be string or non-null object');
        }
      }
    });

    test('"contributors" should be a non-empty array of strings/objects if present', () => {
      if ('contributors' in pkg) {
        expect(Array.isArray(pkg.contributors)).toBe(true);
        expect(pkg.contributors.length).toBeGreaterThan(0);
        for (const c of pkg.contributors) {
          if (typeof c === 'string') {
            expect(c.trim().length).toBeGreaterThan(0);
          } else if (typeof c === 'object' && c !== null) {
            if ('name' in c) {
              expect(typeof c.name).toBe('string');
              expect(c.name.trim().length).toBeGreaterThan(0);
            }
          } else {
            throw new Error('contributors entries must be strings or non-null objects');
          }
        }
      }
    });
  });
});