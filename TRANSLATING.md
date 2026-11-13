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
Import book. Since 1.3.0: Strafregister / rap sheet · Stand / score ("ich : er" / "you : them", you first) · offen / open ·
quitt / settled · überzahlt / overpaid · Opfer / victim · Rang / rank · Weg / path · Verruf / Infamy · Ehre / Honour ·
Jagd / Hunt (the path) · Schutz / Protection · Orden / award · Einband / cover.

## New blocks in 1.3.0

`enUS.lua` has four new blocks between `-- >>> NAME` and `-- <<< NAME`: `REPUTE` (path words and the rank line),
`ALARM` (victim alarm and the score in the alarm line), `START` (first-start window, the "Cover" row, the chat line
for players who had the book before) and `RECORD` (the rap sheet in the book: tab, stamps, states, your file, victim
sheet, chat lines, notices, House Rules sheet, help paragraph). Keep the blocks and their order in your file. Next to
them, in the chat section, stand `HELP_THEME`, `CHAT_THEME_*` and the names of the covers `THEME_NOTEBOOK`,
`THEME_HARBOR`, `THEME_TRADE` (every language has its own name for every cover).

- The score is always "you : them", in that order, with the same notation as in English (`{score}` comes filled).
- `STATE_*`, `STAMP_QUITT` and `STAMP_OVERPAID` are one word each where possible: open, settled, overpaid.
- `PATH_*` are the four accounts; use the word your client uses for "Honour" if it has one.
- Rank names and award names are not in the language files: `Ranks.lua` and `Humor.lua` carry them in German and
  English only. Every other language shows `REPUTE_LINE` ("Rank 6 · Path: Honour") and no awards. Do not add them to
  your file.

## New keys in 1.3.1

Three keys in the block `RECORD`: `KILL_WITH_GROUP` (a short sentence added to the chat line after a kill your group
member's killing blow made, and a line in that kill's tooltip; "With your group.") right after `KILL_TAG_GROUP`, and
`EMPTY_RECORD_HEAD` / `EMPTY_RECORD_SUB` (the left page of an empty rap sheet: big line, small line) at the end of the
block.

## Words of a cover (theme)

A cover may change the show words of the book: book title, poster head, tabs, page heads, stamps, alarm titles, the
currency of the book's bounty, the welcome and the empty pages. Buttons, menus, switches and commands never change.
Each cover has its own file `DeathNote/Locales/Themes/<id>.lua` (now `harbor.lua` and `trade.lua`) with one block per
language:

```lua
Locale.RegisterWords("harbor", "frFR", function(T)
  T.BOOK_TITLE = "Corsaire"
  T.STAMP_NR1  = "PLUS GROSSE PRIME"
end)
```

- Only keys of `Locale.THEME_KEYS` (list in `DeathNote/Locale.lua`); any other key turns the test red.
- A word you leave out keeps the base word of your own language from `xxXX.lua`, never the English word of the cover.
  A language without any block for a cover shows that cover with its own base words.
- German and English carry the same keys in every cover; the other languages may leave words out.
- Length: the `[max N]` of the base key in `enUS.lua` applies (`tests/sprachen/_limits.lua`). On top of that: a stamp
  (`STAMP_*`) must break into at most two lines of at most 12 characters each, the words wrapping where the spaces are;
  `BOOK_TITLE` at most 10; the currency word in `BOUNTY_GOLD` and `BOUNTY_SILVER` (the text without `{count}`) at most
  8, longer ones end in an ellipsis on the poster.
- Chinese and Korean count cells: one wide character counts 2, so a stamp line holds 6 characters and the book title 5.
- No names of the game world (zones, factions, persons) and no guild names in the words of a cover.
- Keep the tone of the cover: the Privateer's Ledger speaks like a ship's log, The Workshop like the customer file of
  a trade business.

## Which test checks what

| Test | Checks |
|---|---|
| `luajit tests/test_locales.lua` | keys exist in English, placeholders and plural forms, `[max N]` in `enUS.lua` against `tests/sprachen/_limits.lua`, lengths (CJK in cells), date formats, UTF-8, the TOC; the words of every cover (only show keys, limits of the base key, stamps 2 × 12, currency 8, German and English the same keys), the name of every cover in all 21 languages. Untranslated keys are hints; `STRICT=1` turns them into errors. |
| `luajit tests/test_locale_waechter.lua` | no visible text written into the code outside `Locales/` (also not in `Themes/`), every key the code reads exists in `enUS.lua`. |
| `luajit tests/ui/sprachen.lua xxXX` | builds the whole book once in your language (every tab, poster, House Rules, help, alarm, notices): red on errors, missing keys or keys read too early. |
| `luajit tests/ui/layout_guard.lua . xxXX` | the guard per language: every view with the longest data, red on overlapping or cut text without a tooltip and on text that leaves its view. Run it for your language after every change of long words (tabs, House Rules sheets, rap sheet, stamps). |
| `luajit tests/ui/theme_guard.lua . xxXX` | the same views with a test cover: every show word of the cover reaches the screen, nothing of the black book shows through. |

`bash tests/run.sh` and `bash tests/ui/run.sh` run all of them (the layout guard over all 21 languages).

