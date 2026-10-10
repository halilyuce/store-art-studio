// Store copy per locale and slot. Headline lines are strings: {tile} marks where the slot's glyph
// tile sits, and a line part wrapped in [ ] gets the glass pill. Body is two lines, broken by hand.
// Transcreate each locale (references/style-and-copy.md); mark it "not native-reviewed" until a
// native speaker has read it. No em dashes anywhere.
window.COPY = {
  "en-US": {
    1: { h: ["your league,", "[live{tile}]"], tile: "stopwatch",
         body: ["scores, tables and widgets that", "update while the game is on."] },
  },
  // ar: Modern Standard Arabic, RTL page, Western digits. Not native-reviewed.
  "ar": {
    1: { h: ["دوريك،", "[مباشر{tile}]"], tile: "stopwatch",
         body: ["النتائج والترتيب والأدوات", "تتحدث أثناء المباراة."] },
  },
};

// Feature graphic headline per locale (header.html). One or two short lines.
window.HEADER = {
  "en-US": ["every game,", "on your screen."],
  "ar": ["كل مباراة،", "على شاشتك."],
};
