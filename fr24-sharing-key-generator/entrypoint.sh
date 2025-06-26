#!/bin/sh

set -e

random_string() {
    tr -dc a-z0-9 </dev/urandom | head -c 8
}

# Read configuration from Home Assistant addon options
if [ -f /data/options.json ]; then
    echo "[$(date)] Reading configuration from /data/options.json"
    
    # Extract values using jq and set environment variables
    FR24_EMAIL=$(jq -r '.email // "johndoe@example.org"' /data/options.json)
    FR24_KEY=$(jq -r '.sharing_key // ""' /data/options.json)
    FR24_MLAT=$(jq -r 'if .mlat then "yes" else "no" end' /data/options.json)
    FR24_LAT=$(jq -r '.latitude // 1.2345' /data/options.json)
    FR24_LON=$(jq -r '.longitude // 1.2345' /data/options.json)
    FR24_ALT=$(jq -r '.altitude // 1' /data/options.json)
    FR24_CONFIRM_SETTINGS=$(jq -r 'if .confirm_settings then "yes" else "no" end' /data/options.json)
    FR24_AUTOCONFIG=$(jq -r 'if .autoconfig then "yes" else "no" end' /data/options.json)
    FR24_RECV_TYPE=$(jq -r '.receiver_type // "1"' /data/options.json)
    FR24_RAW_FEED=$(jq -r 'if .raw_feed then "yes" else "" end' /data/options.json)
    FR24_BASE_FEED=$(jq -r 'if .base_feed then "yes" else "no" end' /data/options.json)
    
    # Export variables so they're available to expect script
    export FR24_EMAIL FR24_KEY FR24_MLAT FR24_LAT FR24_LON FR24_ALT
    export FR24_CONFIRM_SETTINGS FR24_AUTOCONFIG FR24_RECV_TYPE FR24_RAW_FEED FR24_BASE_FEED
    
    echo "[$(date)] Configuration loaded from addon options"
else
    echo "[$(date)] Warning: /data/options.json not found, using default environment variables"
fi
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
