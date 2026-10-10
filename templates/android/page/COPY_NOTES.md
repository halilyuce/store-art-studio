# Copy notes

Source: `copy.js`, the default market's locale (approved on <date> by <who>). Every other locale was
transcreated from it, not translated. Back-translations are literal, so the owner can check meaning
without reading the language.

**Every locale below is NOT native-reviewed** until a native speaker signs it off. Mark the date and
the reviewer here when one does.

Checks run (<date>): `tools/widthtest.sh` and `tools/widthtest.sh --negative`, every locale.

## Decisions that apply to more than one locale

| Topic | Decision |
|---|---|
| Casing | Lowercase headlines in scripts that have case, unless the language's rules say otherwise (a language that capitalises nouns keeps them). Scripts without case are unaffected. |
| Figures | Figures in a right to left line ("-12%", "4.8") are isolated left to right (the `.num` class). |
| Open questions | Anything where a ruleset and approved copy disagree (register, a banned word). Listed here as a question for the owner, never decided silently. |

## <store locale> (EXAMPLE: replace)

Register, glossary terms used, and anything that differs from the source structure.

| Slot | Headline | Back-translation | Body | Back-translation |
|---|---|---|---|---|
| 1 | كل شيء، / [مباشر] | everything, / [live] | القوائم والمجاميع والأدوات / تتحدث لحظة بلحظة. | lists, totals and tools / update moment by moment. |
| 2 | على شاشتك / [الرئيسية] | on your / [home] screen | مجاميعك على الشاشة الرئيسية / دون فتح التطبيق. | your totals on the home screen / without opening the app. |
| Header | كل شيء، / على شاشتك. | everything, / on your screen. | | |
