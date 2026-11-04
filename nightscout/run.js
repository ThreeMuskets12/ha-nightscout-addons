// reads HA add-on options as root, then drops to the image's node user and starts Nightscout
const fs = require('fs');
const os = require('os');
const o = JSON.parse(fs.readFileSync('/data/options.json', 'utf8'));
if (!o.api_secret || o.api_secret.length < 12) { console.error('api_secret missing or < 12 chars'); process.exit(1); }
if (!o.mongo_password) { console.error('mongo_password not set'); process.exit(1); }
// trust only proxies on the add-on network this container is attached to (i.e. the Caddy add-on)
const net = Object.values(os.networkInterfaces()).flat().find((i) => i.family === 'IPv4' && !i.internal);
Object.assign(process.env, {
  API_SECRET: o.api_secret,
  MONGODB_URI: `mongodb://nsroot:${encodeURIComponent(o.mongo_password)}@${o.mongo_host}:27017/nightscout?authSource=admin`,
  BASE_URL: o.base_url,
  AUTH_DEFAULT_ROLES: o.auth_default_roles,
  DISPLAY_UNITS: o.display_units,
  ENABLE: o.enable,
  SHOW_PLUGINS: o.show_plugins,
  CUSTOM_TITLE: o.custom_title,
  INSECURE_USE_HTTP: 'true',
  SECURE_HSTS_HEADER: 'false',
  TRUST_PROXY: net ? net.cidr : 'false',
  PORT: '1337',
  HOSTNAME: '0.0.0.0',
});
process.chdir('/opt/app');
process.setgid(1000); process.setuid(1000);
require('/opt/app/lib/server/server.js');
