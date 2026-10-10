// Shared by slots.html and header.html: reads storeart.config.json (the developer's market list,
// one level up from the page kit) and returns the market for a store locale, its clock and date
// line, and a promise that settles once the market's script font has loaded at every weight.
// Chrome needs --allow-file-access-from-files to fetch the config from a file:// page; the tools
// pass it.
window.STOREART_CONFIG_URL = window.STOREART_CONFIG_URL || '../storeart.config.json';

async function loadMarket(storeLocale) {
  const config = await (await fetch(STOREART_CONFIG_URL)).json();
  const markets = config.markets || [];
  const fallback = markets.find(m => m.code === config.default) || markets[0];
  const L = storeLocale || fallback.storeLocale;
  const market = markets.find(m => m.storeLocale === L);
  if (!market) throw new Error(`no market for store locale ${L} in storeart.config.json`);

  // The frozen moment is local wall-clock time, the same in every market. Android's status bar
  // shows no AM/PM: "9:41" on a 12 hour market, "21:41" on a 24 hour one.
  const [, hh, mm] = config.moment.match(/T(\d\d):(\d\d)/);
  const h = +hh, clock = market.clock24h ? `${hh}:${mm}` : `${(h % 12) || 12}:${mm}`;
  // Date line in the market's own language. "-u-nu-latn" (config digits) keeps Western digits
  // where the language would default to others.
  const tag = market.languageTag + (market.digits ? `-u-nu-${market.digits}` : '');
  const [y, mo, d] = config.moment.slice(0, 10).split('-').map(Number);
  const date = new Intl.DateTimeFormat(tag, { weekday: 'long', month: 'long', day: 'numeric', timeZone: 'UTC' })
    .format(new Date(Date.UTC(y, mo - 1, d, 12)));
  const number = n => new Intl.NumberFormat(tag).format(n);

  document.documentElement.lang = market.storeLocale;
  const fontsReady = loadScriptFont(market).then(() => document.fonts.ready);
  // The surfaces the app has. Phone screens always; widgets, notification, wear and tablet only
  // when the config lists them. No "surfaces" key means screens only.
  const surfaces = new Set(['screens', ...(config.surfaces || [])]);
  const has = s => surfaces.has(s);
  return { config, market, L, clock, date, number, fontsReady, has };
}

// Loads the market's script face (fontFamily, fontWeights "500;700") from Google Fonts and waits
// for every weight explicitly. A weight that is not loaded gets synthesised by the browser: a
// smeared fake bold that also measures differently in the width test.
async function loadScriptFont(market) {
  if (!market.fontFamily) return;
  const weights = (market.fontWeights || '700').split(';').filter(Boolean);
  const link = document.createElement('link');
  link.rel = 'stylesheet';
  link.href = `https://fonts.googleapis.com/css2?family=${market.fontFamily.replace(/ /g, '+')}:wght@${weights.join(';')}&display=block`;
  await new Promise(resolve => { link.onload = link.onerror = resolve; document.head.appendChild(link); });
  document.documentElement.style.setProperty('--script-font', `'${market.fontFamily}'`);
  await Promise.all(weights.map(w => document.fonts.load(`${w} 40px '${market.fontFamily}'`)));
}
