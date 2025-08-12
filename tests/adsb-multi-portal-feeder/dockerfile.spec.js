/* 
  Test framework: Jest
  These tests validate the Dockerfile for adsb-multi-portal-feeder by checking for critical lines,
  commands, and configurations introduced/changed in the PR diff.
*/

const fs = require('fs');
const path = require('path');

function findDockerfileCandidates() {
  // Strategy: search a few common locations for a Dockerfile. If none found or content mismatch,
  // we fallback to scanning repository tree heuristically.
  const candidates = [
    'Dockerfile',
    'adsb-multi-portal-feeder/Dockerfile',
    'containers/adsb-multi-portal-feeder/Dockerfile',
    'docker/adsb-multi-portal-feeder/Dockerfile',
    'services/adsb-multi-portal-feeder/Dockerfile'
  ].filter(p => fs.existsSync(p));

  // Also scan for any Dockerfile in tree if none of the common paths matched.
  if (candidates.length === 0) {
    const walk = (dir, acc) => {
      for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = path.join(dir, entry.name);
        if (
          entry.isDirectory() &&
          entry.name !== 'node_modules' &&
          entry.name !== '.git' &&
          entry.name !== 'dist' &&
          entry.name !== 'build'
        ) {
          walk(full, acc);
        } else if (entry.isFile() && entry.name === 'Dockerfile') {
          acc.push(full);
        }
      }
      return acc;
    };
    return walk('.', []);
  }

  return candidates;
}

function readDockerfileContent() {
  const files = findDockerfileCandidates();

  // We look for the Dockerfile that contains the unique line introduced by the change:
  // ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=30000
  for (const file of files) {
    try {
      const content = fs.readFileSync(file, 'utf8');
      if (content.includes('ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=30000')) {
        return { file, content };
      }
    } catch {
      // ignore file read errors
    }
  }

  // Fallback: if a single candidate exists, use it (still useful to surface failures)
  if (files.length === 1) {
    return { file: files[0], content: fs.readFileSync(files[0], 'utf8') };
  }

  // If multiple exist but none with the marker, throw to help contributors point tests to the right file.
  throw new Error(
    'Could not locate Dockerfile for adsb-multi-portal-feeder with expected markers.'
  );
}

describe('adsb-multi-portal-feeder Dockerfile', () => {
  let dockerfilePath;
  let dockerfile;

  beforeAll(() => {
    const { file, content } = readDockerfileContent();
    dockerfilePath = file;
    dockerfile = content;
  });

  test('contains expected base image ARG and FROM reference', () => {
    expect(dockerfile).toMatch(
      /^\s*ARG\s+BUILD_FROM=thomx\/fr24feed-piaware:2\.3\.0\s*$/m
    );
    expect(dockerfile).toMatch(/^\s*FROM\s+\$BUILD_FROM\s*$/m);
  });

  test('sets timezone to UTC', () => {
    expect(dockerfile).toMatch(/^\s*ENV\s+TZ=UTC\s*$/m);
  });

  describe('bashio installation block', () => {
    test('adds bashio v0.15.0 tarball from hassio-addons', () => {
      expect(dockerfile).toMatch(
        /^\s*ADD\s+https:\/\/github\.com\/hassio-addons\/bashio\/archive\/v0\.15\.0\.tar\.gz\s+\/tmp\/bashio\.tar\.gz\s*$/m
      );
    });

    test('installs required packages and sets up bashio lib and symlink', () => {
      // one RUN line may be split across lines; check key parts exist
      expect(dockerfile).toMatch(
        /apt-get update && apt-get install -y\s+curl\s+jq\s+bc/
      );
      expect(dockerfile).toMatch(/mkdir\s+\/tmp\/bashio/);
      expect(dockerfile).toMatch(
        /tar\s+zxvf\s+\\?\s*\/tmp\/bashio\.tar\.gz/
      );
      expect(dockerfile).toMatch(/--strip 1 -C \/tmp\/bashio/);
      expect(dockerfile).toMatch(
        /mv\s+\/tmp\/bashio\/lib\s+\/usr\/lib\/bashio/
      );
      expect(dockerfile).toMatch(
        /ln -s\s+\/usr\/lib\/bashio\/bashio\s+\/usr\/bin\/bashio/
      );
    });
  });

  describe('hassio sensors installation', () => {
    test('defines version and sha256sum args', () => {
      expect(dockerfile).toMatch(/^\s*ARG\s+version=1\.1\.2-1\s*$/m);
      expect(dockerfile).toMatch(
        /^\s*ARG\s+sha256sum=2b8e660c304448972779011c3f15e37ba659403508c632bb498bcb41aeb4f75b\s*$/m
      );
    });

    test('adds sensors archive using version interpolation', () => {
      expect(dockerfile).toMatch(
        /^\s*ADD\s+https:\/\/github\.com\/plo53\/adsb-hassio-sensors\/archive\/refs\/tags\/\$\{version\}\.tar\.gz\s+\/tmp\/\s*$/m
      );
    });

    test('verifies sha256 checksum before extraction', () => {
      expect(dockerfile).toMatch(
        /^\s*RUN\s+echo\s+"\$?\{?sha256sum\}?\s{2}\/tmp\/\$\{version\}\.tar\.gz"\s+\|\s+sha256sum\s+--check\s*$/m
      );
    });

    test('extracts only etc and usr to root with strip-components=1', () => {
      expect(dockerfile).toMatch(
        /^\s*RUN\s+tar\s+xvfz\s+\/tmp\/\$\{version\}\.tar\.gz\s+adsb-hassio-sensors-\$\{version\}\/\{etc,usr\}\s+--strip-components=1\s+-C\s+\/\s*$/m
      );
    });
  });

  describe('export-env-from-config integration', () => {
    test('copies export-env-from-config.sh to root', () => {
      expect(dockerfile).toMatch(
        /^\s*COPY\s+export-env-from-config\.sh\s+\/export-env-from-config\.sh\s*$/m
      );
    });

    test('sources export-env-from-config.sh at top of s6 scripts', () => {
      expect(dockerfile).toMatch(
        /^\s*RUN\s+find\s+\/etc\/s6-overlay\/s6-rc\.d\/\s+-name\s+script\s+\|\s+xargs\s+sed\s+-i\s+'1 a\\source \/export-env-from-config\.sh'\s*$/m
      );
      expect(dockerfile).toMatch(
        /^\s*RUN\s+find\s+\/etc\/s6-overlay\/s6-rc\.d\/\s+-name\s+run\s+\|\s+xargs\s+sed\s+-i\s+'1 a\\source \/export-env-from-config\.sh'\s*$/m
      );
    });
  });

  describe('banner setup', () => {
    test('adds banner script from hassio-addons debian base v5.1.0', () => {
      expect(dockerfile).toMatch(
        /^\s*ADD\s+https:\/\/raw\.githubusercontent\.com\/hassio-addons\/addon-debian-base\/v5\.1\.0\/base\/rootfs\/etc\/cont-init\.d\/00-banner\.sh\s+\/etc\/s6-overlay\/s6-rc\.d\/banner\/\s*$/m
      );
    });

    test('creates banner service with proper type and up scripts and marks user contents', () => {
      expect(dockerfile).toMatch(
        /mkdir -p\s+\/etc\/s6-overlay\/s6-rc\.d\/banner/
      );
      expect(dockerfile).toMatch(
        /echo\s+"oneshot"\s+>\s+\/etc\/s6-overlay\/s6-rc\.d\/banner\/type/
      );
      expect(dockerfile).toMatch(
        /echo\s+"\/etc\/s6-overlay\/s6-rc\.d\/banner\/script"\s+>\s+\/etc\/s6-overlay\/s6-rc\.d\/banner\/up/
      );
      expect(dockerfile).toMatch(
        /touch\s+\/etc\/s6-overlay\/s6-rc\.d\/user\/contents\.d\/banner/
      );
      expect(dockerfile).toMatch(
        /mv\s+\/etc\/s6-overlay\/s6-rc\.d\/banner\/00-banner\.sh\s+\/etc\/s6-overlay\/s6-rc\.d\/banner\/script/
      );
      expect(dockerfile).toMatch(
        /chmod \+x\s+\/etc\/s6-overlay\/s6-rc\.d\/banner\/script/
      );
    });
  });

  test('extends service wait time to 30000', () => {
    expect(dockerfile).toMatch(
      /^\s*ENV\s+S6_CMD_WAIT_FOR_SERVICES_MAXTIME=30000\s*$/m
    );
  });

  describe('defensive checks and failure conditions', () => {
    test('fails if Dockerfile is unexpectedly missing critical markers', () => {
      // This test documents that our identification relies on specific markers.
      // If content drifts, this assertion will help identify that the tests need updating.
      const requiredMarkers = [
        'ARG BUILD_FROM=thomx/fr24feed-piaware:2.3.0',
        'FROM $BUILD_FROM',
        'ENV TZ=UTC',
        'bashio/archive/v0.15.0.tar.gz',
        'apt-get install -y curl jq bc',
        'ARG version=1.1.2-1',
        'ARG sha256sum=2b8e660c304448972779011c3f15e37ba659403508c632bb498bcb41aeb4f75b',
        'echo "${sha256sum}  /tmp/${version}.tar.gz" | sha256sum --check',
        'tar xvfz /tmp/${version}.tar.gz adsb-hassio-sensors-${version}/{etc,usr} --strip-components=1 -C /',
        'COPY export-env-from-config.sh /export-env-from-config.sh',
        "find /etc/s6-overlay/s6-rc.d/ -name script | xargs sed -i '1 a\\source /export-env-from-config.sh'",
        "find /etc/s6-overlay/s6-rc.d/ -name run | xargs sed -i '1 a\\source /export-env-from-config.sh'",
        'addon-debian-base/v5.1.0/base/rootfs/etc/cont-init.d/00-banner.sh',
        'ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=30000'
      ];
      for (const marker of requiredMarkers) {
        expect(dockerfile.includes(marker)).toBe(true);
      }
    });
  });

  test('file path is discoverable and stable (helps maintainability)', () => {
    // Provide visibility in test output to help maintainers adjust if path changes.
    expect(typeof dockerfilePath).toBe('string');
    expect(dockerfilePath).toMatch(/Dockerfile$/);
  });
});