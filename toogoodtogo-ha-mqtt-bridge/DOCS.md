# Home Assistant Add-on: TooGoodToGo Home Assistant MQTT Bridge

## Configuration

Example Config:

```yaml
mqtt:
  host: homeassistant
  port: 1883
  username: mqtt
  password: mqtt
tgtg:
  email: me@example.com
  language: en-US
  polling_schedule: "*/10 * * * *"
  intense_fetch_interval: 30
  intense_fetch_period_of_time: 5
timezone: Europe/Berlin
locale: en_us
cleanup: true
```

See https://github.com/MaxWinterstein/toogoodtogo-ha-mqtt-bridge for more configuration options.

## Logging in

Too Good To Go logs you in with a PIN that it sends to the email address in `tgtg.email`.

1. Start the add-on. On the first start it asks Too Good To Go for a login email.
2. Open the add-on's **Web UI**. It shows a form for the PIN.
3. Enter the PIN from the email. The page confirms the login, and the add-on starts publishing.

The add-on keeps the login afterwards. If Too Good To Go ever rejects it, the add-on requests a
new email by itself and waits for the PIN instead of crash-looping. You will see this in three
places:

- a Home Assistant notification titled **Too Good To Go: login needed**, with a link to the login page,
- the **Login required** problem sensor on the Too Good To Go device turning on,
- the add-on log.

If the email does not arrive or the PIN has expired, use **Send me a new login email** on the
login page. The add-on never retries a failed login on its own, so it does not run into Too Good
To Go's rate limit.
