// Store copy per store locale (the storeLocale of a market in storeart.config.json) and slot.
// Headline lines are strings: {tile} marks where the slot's glyph tile sits, and a line part
// wrapped in [ ] gets the glass pill. Body is two lines, broken by hand.
//
// The two locales below are EXAMPLES to replace, one left to right and one right to left, so both
// paths stay testable. They are not a recommendation of languages. Add one entry per market you
// add to the config, transcreated (references/style-and-copy.md), with its back-translation in
// COPY_NOTES.md and the mark "not native-reviewed" until a native speaker has read it. No em dashes.
window.COPY = {
  "en-US": {
    1: { h: ["all of it,", "[live{tile}]"], tile: "spark",
         body: ["lists, totals and widgets that", "update while it happens."] },
    2: { h: ["on your", "[home{tile}]"], tile: "home",
         body: ["your totals on the home screen,", "without opening the app."] },
  },
  // RTL example. Western digits come from the market's "digits": "latn". Not native-reviewed.
  "ar": {
    1: { h: ["كل شيء،", "[مباشر{tile}]"], tile: "spark",
         body: ["القوائم والمجاميع والأدوات", "تتحدث لحظة بلحظة."] },
    2: { h: ["على شاشتك", "[الرئيسية{tile}]"], tile: "home",
         body: ["مجاميعك على الشاشة الرئيسية", "دون فتح التطبيق."] },
  },
};

// Feature graphic headline per store locale (header.html). One or two short lines.
window.HEADER = {
  "en-US": ["everything,", "on your screen."],
  "ar": ["كل شيء،", "على شاشتك."],
};
