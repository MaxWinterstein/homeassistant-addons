#!/bin/sh

set -e

random_string() {
    tr -dc a-z0-9 </dev/urandom | head -c 8
}

DEFAULT_EMAILS="you@example.com johndoe@example.org"

# Randomize email if default
for defmail in $DEFAULT_EMAILS; do
    if [ "$FR24_EMAIL" = "$defmail" ]; then
        RAND=$(random_string)
        FR24_EMAIL="fr24user-${RAND}@example.com"
        echo "[$(date)] Default email detected, using randomized email: $FR24_EMAIL"
        break
    fi
done

echo "[$(date)] Starting FR24 Sharing Key Generator entrypoint..."

echo "[$(date)] Using environment variables:"
echo "  FR24_EMAIL: $FR24_EMAIL"
echo "  FR24_KEY: $FR24_KEY"
echo "  FR24_MLAT: $FR24_MLAT"
echo "  FR24_LAT: $FR24_LAT"
echo "  FR24_LON: $FR24_LON"
echo "  FR24_ALT: $FR24_ALT"
echo "  FR24_CONFIRM_SETTINGS: $FR24_CONFIRM_SETTINGS"
echo "  FR24_AUTOCONFIG: $FR24_AUTOCONFIG"
echo "  FR24_RECV_TYPE: $FR24_RECV_TYPE"
echo "  FR24_RAW_FEED: $FR24_RAW_FEED"
echo "  FR24_BASE_FEED: $FR24_BASE_FEED"

# Write the entire HTML header and style FIRST
cat <<EOF > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="refresh" content="2">
  <title>FR24 Sharing Key Generator Log</title>
  <style>
    body {
      background: #f6f8fa;
      font-family: 'Segoe UI', 'Liberation Sans', Arial, sans-serif;
      margin: 0;
      padding: 0;
    }
    .header {
      background: #0366d6;
      color: #fff;
      padding: 16px 24px;
      font-size: 1.4em;
      font-weight: bold;
      letter-spacing: 1px;
    }
    .logbox {
      background: #222;
      color: #f6f8fa;
      font-family: 'Fira Mono', 'Consolas', 'Menlo', monospace;
      padding: 24px;
      margin: 32px auto;
      max-width: 900px;
      border-radius: 8px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.06);
      font-size: 1.06em;
      overflow-x: auto;
      white-space: pre-wrap;
    }
    .timestamp {
      float: right;
      font-size: 0.9em;
      color: #cce1ff;
      font-weight: normal;
    }
  </style>
</head>
<body>
  <div class="header">
    FR24 Sharing Key Generator Log
    <span class="timestamp">Last updated: $(date '+%Y-%m-%d %H:%M:%S')</span>
  </div>
  <div class="logbox">
<pre>
EOF

echo "[$(date)] Starting nginx..."
nginx -g 'daemon off;' &
NGINX_PID=$!

# Give nginx a moment to start and verify it's running
sleep 2
if ! kill -0 $NGINX_PID 2>/dev/null; then
    echo "[$(date)] ERROR: nginx failed to start" | tee -a /usr/share/nginx/html/index.html
    exit 1
fi
echo "[$(date)] Running fr24feed signup wizard via expect..."
# Append expect output to log and show in stdout
/signup.exp 2>&1 | tee -a /usr/share/nginx/html/index.html

SIGNUP_EXIT_CODE=${PIPESTATUS:-${?}}
if [ "$SIGNUP_EXIT_CODE" -ne 0 ]; then
    echo "[$(date)] ERROR: fr24feed signup failed with exit code $SIGNUP_EXIT_CODE" | tee -a /usr/share/nginx/html/index.html
else
    echo "[$(date)] fr24feed signup completed." | tee -a /usr/share/nginx/html/index.html
fi

# Append closing tags
cat <<EOF | tee -a /usr/share/nginx/html/index.html
</pre>
  </div>
</body>
</html>
EOF

# Wait for nginx (keeps container running)
wait $NGINX_PID
