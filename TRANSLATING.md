# Translating DeathNote

1. You only write your own file `DeathNote/Locales/xxXX.lua`, never code. Start from `enUS.lua`: same keys, same order
   and sections, keep the `[max N]` comments. The head of your file (the `Locale.Wants` check, `Locale.Register`) stays
   exactly as it is.
2. Tone: dry, a little grim, a notebook full of enemies. Address the player informally (the "du", "tu", "ты" form).
   Write natural gamer language, not a word-for-word copy of the English.
3. Never changes: `DeathNote`, `WANTED`, all `/dn` commands and their English subcommands (`/dn hunt`, `/dn lang` ...),
   `DEATHNOTE:1`, class, race and zone names (the game supplies those). The reason for a hit list call is the player's
   free text and is never translated.
4. Placeholders in curly braces (`{name}`, `{count}`, `{time}`, `{text}` ...) are copied unchanged; their order in the
   sentence is up to you. Do not add any, do not drop any. `{text}` is an already finished part of a sentence that you
   append to.
5. Plurals: `{count|form1|form2|...}` stands for the word only, the number itself is written as `{count}`. Use exactly
   as many forms as the head of your file says (German 2, Polish 3, Chinese 1). If it sounds natural, prefer a sentence
   without an inflected word ("Kills: 3").
6. `[max N]` is the maximum length in characters (Chinese, Korean: cells, one character = 2). Tabs and word tabs grow
   with their text, but the limit still applies. Stamps and headings in capitals where the English has them. Better
   short and to the point than cut off.
7. Not allowed: control characters, `|` (except colour codes that are already in the English), empty texts, keys that
   do not exist in the English. `\n` is allowed where the English has it. `TIME_FMT_*` are date formats
   (`%d %m %Y %y %H %M`, plus `%%`): only reorder them; with any other `%` code the test turns red and the game
   falls back to the English format. Save the file as UTF-8 without BOM.
8. Whatever you do not translate, leave out: it then shows in English. Never enter an empty text.
9. Client languages (deDE, enUS, frFR, esES, itIT, ptBR, ruRU, koKR, zhCN, zhTW): fill the `-- TOC-Notes:` line in the
   head with the sentence from `enUS.lua` in your language; it also appears as `## Notes-xxXX` in `DeathNote.toc`.
10. Checking: `luajit tests/test_locales.lua` (hints are fine); at the end `STRICT=1 luajit tests/test_locales.lua` must
    be green for your language; then `luajit tests/ui/sprachen.lua xxXX` (builds the book in your language).

Key terms (German / English, binding for the meaning): Buch / book · Gildenbuch / guild book · Freundesbuch / friends'
book · Täter / killer · Kollege / guildmate · Freund / friend · Gesucht / Wanted · Zu klären / Unsolved · Todesjournal /
Death Log · Gilde & Freunde / Guild & Friends · Hausordnung / House Rules · Gebrauchsanweisung / How it works · Plakat /
poster · Stempel / stamp · Kopfgeld / bounty · Notiz / note · Sichtung / sighting · streichen / strike · begnadigen /
pardon · Rache / revenge · Verdacht / suspect · Abschussliste / Hit List · zur Jagd freigeben / put on the hit list ·
Freigabe / call · Jagd abblasen / call off the hunt · erlegt / taken down · Buch sichern / Back up book · Buch einlesen /
Import book.
