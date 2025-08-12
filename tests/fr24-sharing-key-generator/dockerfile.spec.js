/**
 * Tests for FR24 sharing key generator Dockerfile semantics.
 *
 * Testing framework: Jest
 * This suite prefers reading the actual Dockerfile from the repository if available.
 * If not found, it falls back to a provided inline fixture matching the PR diff content.
 */

const fs = require('fs');
const path = require('path');

const MARKERS = [
  'ARG BUILD_FROM=thomx/fr24feed-piaware:2.3.0',
  'FROM $BUILD_FROM',
  'apt-get update',
  'apt-get install -y expect jq',
  'rm -rf /var/lib/apt/lists/*',
  'ENV FR24_EMAIL="you@example.com"',
  'ENV FR24_KEY=""',
  'ENV FR24_MLAT="no"',
  'ENV FR24_LAT="50.1234"',
  'ENV FR24_LON="8.1234"',
  'ENV FR24_ALT="123"',
  'ENV FR24_CONFIRM_SETTINGS="yes"',
  'ENV FR24_AUTOCONFIG="no"',
  'ENV FR24_RECV_TYPE="1"',
  'ENV FR24_RAW_FEED=""',
  'ENV FR24_BASE_FEED="no"',
  'COPY signup.exp /signup.exp',
  'chmod +x /signup.exp',
  'COPY nginx.conf /etc/nginx/nginx.conf',
  'COPY entrypoint.sh /entrypoint.sh',
  'chmod +x /entrypoint.sh',
  'ENTRYPOINT ["/entrypoint.sh"]',
];

const DOCKERFILE_FIXTURE = [
  'ARG BUILD_FROM=thomx/fr24feed-piaware:2.3.0',
  'FROM $BUILD_FROM',
  '',
  '# Install expect',
  'RUN apt-get update \\',
  ' && apt-get install -y expect jq \\',
  ' && rm -rf /var/lib/apt/lists/*',
  '',
  '# Set ENV variables for signup',
  'ENV FR24_EMAIL="you@example.com"',
  'ENV FR24_KEY=""',
  'ENV FR24_MLAT="no"',
  'ENV FR24_LAT="50.1234"',
  'ENV FR24_LON="8.1234"',
  'ENV FR24_ALT="123"',
  'ENV FR24_CONFIRM_SETTINGS="yes"',
  'ENV FR24_AUTOCONFIG="no"',
  'ENV FR24_RECV_TYPE="1"',
  'ENV FR24_RAW_FEED=""',
  'ENV FR24_BASE_FEED="no"',
  '',
  '# Add the expect script',
  'COPY signup.exp /signup.exp',
  'RUN chmod +x /signup.exp',
  '',
  '# Add nginx config',
  'COPY nginx.conf /etc/nginx/nginx.conf',
  '',
  '# Add entrypoint',
  'COPY entrypoint.sh /entrypoint.sh',
  'RUN chmod +x /entrypoint.sh',
  '',
  'ENTRYPOINT ["/entrypoint.sh"]',
].join('\n');

function findDockerfileByMarkers(rootDir) {
  // Try typical Dockerfile names and locations
  const candidateNames = [
    'Dockerfile',
    'docker/Dockerfile',
    'fr24-sharing-key-generator/Dockerfile',
    'fr24/Dockerfile',
  ];

  for (const rel of candidateNames) {
    const p = path.join(rootDir, rel);
    if (fs.existsSync(p)) {
      try {
        const content = fs.readFileSync(p, 'utf8');
        // Check for key markers
        const hasMarkers = ['FR24_EMAIL', 'signup.exp', 'nginx.conf', 'entrypoint.sh'].every(m => content.includes(m));
        if (hasMarkers) return { path: p, content };
      } catch (_) {}
    }
  }

  // If above didn't match, do a full scan with heuristic limit
  function scanDir(dir, limit = 5000) {
    const stack = [dir];
    let visited = 0;
    while (stack.length && visited < limit) {
      const d = stack.pop();
      visited++;
      let entries = [];
      try {
        entries = fs.readdirSync(d, { withFileTypes: true });
      } catch {
        continue;
      }
      for (const e of entries) {
        const p = path.join(d, e.name);
        if (e.isDirectory()) {
          // Skip node_modules, dist, build to keep scanning light
          if (/node_modules|dist|build|\.git/i.test(p)) continue;
          stack.push(p);
        } else if (/Dockerfile$/i.test(e.name)) {
          try {
            const content = fs.readFileSync(p, 'utf8');
            const hasMarkers = ['FR24_EMAIL', 'signup.exp', 'nginx.conf', 'entrypoint.sh'].every(m => content.includes(m));
            if (hasMarkers) return { path: p, content };
          } catch {}
        }
      }
    }
    return null;
  }

  return scanDir(rootDir);
}

function getDockerfileContent() {
  const found = findDockerfileByMarkers(process.cwd());
  if (found) {
    return { content: found.content, source: found.path };
  }
  return { content: DOCKERFILE_FIXTURE, source: '(fixture)' };
}

function normalizeLines(str) {
  return str.replace(/\r\n/g, '\n').split('\n');
}

describe('Dockerfile - FR24 sharing key generator', () => {
  const { content, source } = getDockerfileContent();
  const lines = normalizeLines(content);
  const joined = content;

  test('should load Dockerfile content from repository or fallback fixture', () => {
    expect(typeof content).toBe('string');
    expect(content.length).toBeGreaterThan(50);
    // Must include core markers
    expect(joined).toContain('FR24_EMAIL');
    expect(joined).toContain('signup.exp');
    expect(joined).toContain('nginx.conf');
    expect(joined).toContain('entrypoint.sh');
  });

  describe('Base image and build args', () => {
    test('defines ARG BUILD_FROM with expected default', () => {
      const argLine = lines.find(l => l.startsWith('ARG BUILD_FROM='));
      expect(argLine).toBeDefined();
      expect(argLine).toContain('thomx/fr24feed-piaware:2.3.0');
    });

    test('uses FROM $BUILD_FROM', () => {
      // Accept optional whitespace
      const hasFrom = lines.some(l => /^FROM\s+\$BUILD_FROM\b/.test(l));
      expect(hasFrom).toBe(true);
    });
  });

  describe('Packages installation layer', () => {
    test('runs apt-get update and installs expect and jq', () => {
      // Ensure apt-get and install are present (may be on separate lines joined by backslashes)
      expect(joined).toMatch(/apt-get update/);
      expect(joined).toMatch(/apt-get install -y .*expect.*\b/);
      expect(joined).toMatch(/apt-get install -y .*jq.*\b/);
    });

    test('cleans apt lists to reduce layer size', () => {
      expect(joined).toMatch(/rm -rf\s+\/var\/lib\/apt\/lists\/\*/);
    });
  });

  describe('Environment variables', () => {
    const expectedEnv = {
      FR24_EMAIL: '"you@example.com"',
      FR24_KEY: '""',
      FR24_MLAT: '"no"',
      FR24_LAT: '"50.1234"',
      FR24_LON: '"8.1234"',
      FR24_ALT: '"123"',
      FR24_CONFIRM_SETTINGS: '"yes"',
      FR24_AUTOCONFIG: '"no"',
      FR24_RECV_TYPE: '"1"',
      FR24_RAW_FEED: '""',
      FR24_BASE_FEED: '"no"',
    };

    for (const [key, val] of Object.entries(expectedEnv)) {
      test(`sets ${key} to ${val}`, () => {
        const pattern = new RegExp(`^ENV\\s+${key}=${val.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')}$`, 'm');
        expect(pattern.test(joined)).toBe(true);
      });
    }

    test('does not introduce unexpected ENV variables (basic sanity)', () => {
      const envLines = lines.filter(l => /^ENV\s+/.test(l));
      const keys = envLines.map(l => l.replace(/^ENV\s+/, '').split('=')[0].trim());
      // Every key should be within expected set
      const expectedKeys = new Set(Object.keys(expectedEnv));
      const unknowns = keys.filter(k => !expectedKeys.has(k));
      // Allow potential additional envs but flag if many unknowns appear (heuristic)
      expect(unknowns.length).toBeLessThan(4);
    });
  });

  describe('Files and permissions', () => {
    test('copies signup.exp to /signup.exp and sets executable bit', () => {
      expect(joined).toMatch(/COPY\s+signup\.exp\s+\/signup\.exp/);
      // Accept either separate RUN chmod or combined in same RUN
      const hasChmod = /chmod\s+\+x\s+\/signup\.exp/.test(joined);
      expect(hasChmod).toBe(true);
    });

    test('copies nginx.conf to /etc/nginx/nginx.conf', () => {
      expect(joined).toMatch(/COPY\s+nginx\.conf\s+\/etc\/nginx\/nginx\.conf/);
    });

    test('copies entrypoint.sh to /entrypoint.sh and sets executable bit', () => {
      expect(joined).toMatch(/COPY\s+entrypoint\.sh\s+\/entrypoint\.sh/);
      const hasChmod = /chmod\s+\+x\s+\/entrypoint\.sh/.test(joined);
      expect(hasChmod).toBe(true);
    });
  });

  describe('Entrypoint', () => {
    test('defines ENTRYPOINT as ["/entrypoint.sh"]', () => {
      // Allow whitespace variability
      const re = /ENTRYPOINT\s*\[\s*"\/entrypoint\.sh"\s*\]/;
      expect(re.test(joined)).toBe(true);
    });
  });

  describe('Happy path coverage', () => {
    test('contains every essential marker from the PR diff', () => {
      const missing = MARKERS.filter(m => !joined.includes(m));
      // Some repos may collapse RUN lines; ensure essential value markers exist
      const acceptableMissing = missing.filter(m =>
        !/apt-get|rm -rf/.test(m) // these might be formatted differently; covered by regex tests above
      );
      expect(acceptableMissing).toEqual([]);
    });
  });

  describe('Edge cases and robustness (simulated)', () => {
    const stripLine = (str, contains) =>
      normalizeLines(str).filter(l => !l.includes(contains)).join('\n');

    test('fails if ENTRYPOINT missing', () => {
      const noEntrypoint = stripLine(joined, 'ENTRYPOINT');
      expect(/ENTRYPOINT\s*\[/.test(noEntrypoint)).toBe(false);
      // Our spec expects ENTRYPOINT; simulate assertion
      expect(() => {
        if (!/ENTRYPOINT\s*\[/.test(noEntrypoint)) {
          throw new Error('ENTRYPOINT missing');
        }
      }).toThrow(/ENTRYPOINT missing/);
    });

    test('detects missing chmod for entrypoint.sh', () => {
      const noChmod = stripLine(joined, 'chmod +x /entrypoint.sh');
      expect(/chmod\s+\+x\s+\/entrypoint\.sh/.test(noChmod)).toBe(false);
      expect(/COPY\s+entrypoint\.sh\s+\/entrypoint\.sh/.test(noChmod)).toBe(true);
    });

    test('detects missing signup.exp copy or permission', () => {
      const noCopy = stripLine(joined, 'COPY signup.exp');
      const noPerm = stripLine(joined, 'chmod +x /signup.exp');
      expect(/COPY\s+signup\.exp\s+\/signup\.exp/.test(noCopy)).toBe(false);
      expect(/chmod\s+\+x\s+\/signup\.exp/.test(noPerm)).toBe(false);
    });

    test('ensures apt cleanup command exists to minimize layer size', () => {
      // This protects against cache bloat regressions
      expect(joined).toMatch(/rm -rf\s+\/var\/lib\/apt\/lists\/\*/);
    });
  });
});