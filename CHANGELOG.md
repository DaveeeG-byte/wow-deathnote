# Changelog

## 1.3.1 (2026-11-13)

### Fixed
- Kills made with your group were not booked when a group member landed the killing blow. Now they count when you took part (the game counts the kill for you or gives you honour within a few seconds), with half honour and hunt; infamy and protection count in full. Chat line, latest kills and the victim sheet show them as group kills ("With your group."). The same player killed by you and a group member within 10 seconds is one kill. The biggest level gap and the fastest payback stay for your own killing blows.

### Changed
- The Rap Sheet tab is there from the start, with an empty file.
- An empty rap sheet says on the left page what will stand there.

## 1.3.0 (2026-11-12)

### Added
- Rap sheet: the book now also keeps your own killing blows on players (yours or your pet's), in the open world only. Players of your own faction, the opponent of a duel to the death and the same player twice within 10 seconds are not booked. Each kill gets a line in the chat ("Rap sheet: Name, Level 34 (yellow). +3 Honour."), which can be switched off.
- Score "you : them" for every killer in the book: open (they lead, or nothing settled yet), settled (even) or overpaid (you lead). It shows in the list, on the poster (stamps SETTLED and OVERPAID), in the game tooltip, in the alarm line and in the revenge notice.
- Fifth tab "Rap Sheet", from your first own kill on: your file with rank, path, rank bar, needle (ruthless to honourable), kills, awards and bests; your latest 60 kills; a sheet per victim with your kills, the points they earned and the scene (zone and time). Victims can be struck one by one; "Clear rap sheet" removes victims and the kill list but keeps rank, points and awards. The game tooltip over a player you killed shows "RAP SHEET: killed by you 3×, last …".
- Repute with four accounts: Infamy (greys and greens), Honour (about your level, payback), Hunt (higher levels, hit list targets, bounties posted by others) and Protection (players who killed guildmates or friends). The level colour of the victim sets the base points; payback, protection, hit list and bounty add to them; group kills give half honour and hunt; a second kill of the same player within 10 minutes gives no honour, hunt or protection; the same player gives less with every kill within 24 hours and nothing from the sixth. Ten ranks, a path from rank 3 or 10 counted kills, and rank names per path and cover (German and English; the other languages show "Rank 6 · Path: Honour"). Notices for a new rank and for an award come after combat, at most two per kill (several awards share one notice, the chat names them all); a new path without a new rank is one chat line (while own kills are reported in the chat).
- Six awards (two of them hidden until earned; names and conditions in German and English) and three bests: the biggest level gap, the longest streak without dying, the fastest payback.
- Victim alarm, off by default: when a player you killed more often than they killed you shows up within 14 days of your last kill, a quiet popup ("HOLDS A GRUDGE?") with the score and a soft sound, at most once per 10 minutes per player and never in front of the book's own alarm.
- "Alarm when the score is settled": as usual, quiet (soft sound, no flashing edge) or never, for killers whose score is settled or overpaid. Open cases always alarm as before.
- Every switch of the rap sheet is on the new fourth sheet "Rap Sheet" of the House Rules: keep a rap sheet, report own kills in the chat, the victim alarm, the alarm for settled scores, clear rap sheet. With "Keep a rap sheet" off nothing is booked, tab and score disappear and the book ranks as in 1.2.2; the data stays.
- Covers: The Black Book (as before, the default), Privateer's Ledger and The Workshop. A cover changes colours, textures, stamps, the book title, tabs, page heads, alarm titles and the top title (PUBLIC ENEMY No. 1, HIGHEST BOUNTY, BEST CUSTOMER), never a button or a switch. Choose it in the House Rules (sheet Book, row "Cover" under "Language") or with `/dn theme <name>` (also `/dn cover`, `/dn einband`); without a name it lists the covers. Takes effect after `/reload`. On a new installation a cover may bring its own alarm sound; a sound you chose, or had before, stays.
- First start of a new installation: one small window asks for the language and the cover, 3 seconds after you enter the open world, never in combat or in an instance. The choice works at once, without `/reload`; Esc or the cross keeps the game's language and The Black Book. `/dn start` shows it again.
- All new texts in all 21 languages, also the words of the covers; rank names and awards in German and English only.

### Changed
- Wanted is ranked by open debt (their kills minus yours), the biggest first. Settled and overpaid killers stand faded at the end without a rank number. Rank 1 and the top title are always an open case; when every score is settled, nobody is No. 1, also not in the alarm.
- Players who had the book before get no window, only one chat line: the book now comes in other covers, where to change it.
- The notice in the middle of the screen is a smaller slip torn from the book instead of the black strip.
- Poster: "Last seen: zone, 2 hrs ago" (without the zone when it does not fit; then the whole line is in the tooltip).
- The book's own bounty counts your own killing blows on a killer like revenge, so it can sink further; it is never higher than in 1.2.2.
- Revenge that came in by "Import book" no longer counts as yours in the score and the alarm line (the book's bounty reads it as before).
- How it works has a ninth paragraph, RAP SHEET; `/dn help` lists `/dn theme` and `/dn start`.

### Fixed
- A duel to the death no longer counts as a death, a revenge, a kill or a "taken down" (only the opponent; anyone else in the fight still counts).
- A player seen without surname who shares a first name with a listed killer no longer sets off that killer's alarm, overwrites his last sighting, level or class, or has his kills booked on that killer; the GUID decides.
- Hungarian: the "pardoned" stamp says "pardoned" again (it said "mercy").

### Internal
- Theme core (`Theme.lua`): the look of the book is data, one file per cover in `Themes/`, its words in `Locales/Themes/`; the textures come from `tests/ui/make_media.sh`. New files `Ledger.lua` (kills, score, repute), `Ranks.lua` (rank thresholds and names) and `Start.lua` (first-start window).
- DB version 4 adds the empty rap sheet (`DeathNoteDB.ledger`) and books nothing from old data. Going back to 1.2.2 and up again is safe.
- `/dn debug` writes what the client sends at your own kills to `DeathNoteDB.probe.kills` (no names), for the check in the game.
- Tests: rap sheet formula, detection, score, migration, random runs and a differential run against 1.2.2 (the book stays the same, the bounty is never higher), ranks and debt order, themes against their schema, the theme guard (a test theme replaces every value; nothing of the black book may show through), contrast for every cover, the first-start window, the victim alarm, the rap sheet tab with the sheet switched on and off, the notice slip.
- The release pipeline no longer fails its zip check on a branch push whose commit already carries the release tag.

### Known open
- Kill detection is not yet checked in the game. Kills by totems, guardians or traps are probably not booked: the honour line that could catch them is switched off until the probe has shown that it comes only for your own killing blow.
- Repute starts at zero. Revenge from before 1.3.0 counts in the score, but earns no points.
- The translations of 1.3.0 are made by machine and not yet read by native speakers. Rank names and awards exist in German and English only.
- Text widths for Morpheus, Skurri, Nimrod, Cyrillic handwriting and Chinese/Korean are estimated in the tests, not measured with the game's fonts.
- Not yet checked in the game: the first own kill (chat line, the fifth tab, notices after combat), the notice slip in the real world, the first-start window on a fresh installation, the covers after `/reload`, the sound of the victim alarm, "quiet" and "never" for settled scores, a duel to the death from both sides.

## 1.2.2 (2026-11-12)

### Changed
- Nothing overlaps any more, in all 21 languages, with long names and with full books:
  - "How it works" scrolls with the mouse wheel; the imprint and the back button stand in a foot of their own and no longer lie over a paragraph. The House Rules sheets, the "Put on hit list" sheet and the case file of a death scroll the same way when their content is taller than the room. While more text follows below, the bottom edge fades softly into the paper.
  - Long names, counts, stamp words and labels get smaller or wrap instead of being cut. Where a text still has to be shortened, a tooltip shows it whole.
  - The alarm shows the level at the start of its text line, so a long name keeps the whole width (smaller rather than cut). Its text line shrinks down to 9 pt before anything is cut.
  - Stamps on the kill message may take a third line; the Hungarian "pardoned" stamp got a shorter word.
  - The bottom row of the poster shares its width: "Strike" no longer runs into the second button.
  - The row and sort menu takes its width from its longest entry, stays on the screen and opens away from the nearer edges.
  - The book checks its size again when the game's resolution or UI scale changes.
- The status line "Enemy nameplates are off" follows the nameplates at once, also when you switch them with a key while the book is open. `/dn probe` shows which event switched them.
- The minimap button now runs through LibDBIcon-1.0 and LibDataBroker-1.1, so minimap button collectors recognise it. Its position and "Show minimap button" carry over from 1.2.1. Without the libraries DeathNote falls back to its own button.

### Added
- Embedded libraries in `DeathNote/Libs/`: LibStub, CallbackHandler-1.0, LibDataBroker-1.1 and LibDBIcon-1.0, unmodified release files (versions and licenses in `DeathNote/Libs/README.txt`).

### Internal
- Layout guard test (`tests/ui/layout_guard.lua`): builds every view in all 21 languages with the longest data and turns red on overlapping or cut text, text that leaves its view, and menus off the screen.
- The zip check of the release pipeline now really fails on forbidden or missing files and requires the embedded libraries.
- README, translator guide (now `TRANSLATING.md`), pipeline, test scripts and code comments are in English.

### Known open
- Text widths for Morpheus, Skurri, Nimrod, Cyrillic handwriting and Chinese/Korean are estimated in the tests, not measured with the game's fonts.
- Not yet checked in the game: the new layout (scrolling, fitted texts, menus at the screen edge), the nameplate status and the new minimap button.

## 1.2.1

### Added
- Bounty of your own: click the bounty on a poster (or use the row menu, a right-click on the poster, or `/dn bounty Name [Surname] <gold>`) and type a whole number of gold, 1 to 99999. Empty or 0 takes it back.
- Your bounty is shared with guild and friends who run DeathNote, whether or not the killer is on the hit list. Posters show "500g, posted by Anna"; several: the sum and the biggest one ("Bounty 700g: Anna +2"), the tooltip shows every amount. A small coin marks such killers in the lists. No window, no sound when one arrives.
- A bounty is a promise only: the addon pays nothing and checks nothing; you settle it among yourselves.
- "Avenged for you": when someone with DeathNote kills, with their own killing blow, a killer who killed others in your guild or among your friends, those who were hit by that killer get one chat line with the short revenge sound. Everybody sees "Avenged by Anna 2×" (several: "Avenged by Anna +2", all in the tooltip) on the poster and the total in the guild and friends' book rows.
- Undo for "Note revenge": the same button turns into "Undo" for a few seconds; later, "Take back one revenge" in the row menu. Only revenge you noted by hand can be taken back, revenge the book recognised stays.
- `/dn probe` notes the result of the first send attempt in an instance and the first refusal (`probe.guild.instanceSend`).
- `/dn bounty` without anything lists your own bounties.

### Changed
- Dungeons and raids: the guild and friends' book now send there as well when you are out of combat. If the client refuses, sending waits for that instance and goes on after you leave; waiting messages no longer expire while they wait. The send queue stays capped at 140, and the receiver still takes "taken down" and "avenged" only up to ten minutes old; the rest comes with the next answer where it can. Battlegrounds, arenas, combat and the chat lockdown still wait.
- Answers to a hello wait while you are in a battleground, instead of filling the send queue.
- The status line and `/dn guild` tell what sending waits for.
- A killer that is also on the hit list still gives exactly one message ("taken down"), but both counters count.
- How it works: one more half sentence about bounties (all 21 languages).
- New messages (bounty, end of bounties, avenged) are ignored by 1.2.0 and 1.1.0 without touching their data; mixed guilds keep working.

### Fixed
- A friend listed without surname who was first bound to a stranger with the same first name: the GUID of the bound name's hello is kept. Once the friend list shows your friend's GUID, the same GUID proves the binding, and so does the guild roster when it shows the bound full name with that GUID; otherwise nothing is deleted on suspicion, the bound name gets nothing new until a hello settles it, and your friend is asked (at most three times per session, and as usual when he comes online). When your friend proves himself under another name (his hello, or the guild roster), the stranger's data goes and he is named once in the status line.
- A binding you chose yourself, as long as no hello has proved it: a hello with the listed GUID under another name becomes a conflict for you to resolve, and the data of both stays, also at the next clean-up. In 1.2.0 the chosen name lost its data at the next clean-up. The chosen name's own hello with that GUID settles it. Alerts for the data in question stay silent while the conflict is open.
- The same for a Battle.net friend known by first name only: when the same Battle.net account shows up on the friend list as a char with surname and GUID, a name bound by character whisper with another surname is undone with its data.
- A guildmate with the first name of a friend listed without surname: his releases for friends alone are refused when the guild roster shows another GUID for him, and taken as in 1.2.0 when it shows none.
- Waiting messages were dropped after ten minutes in an instance or in a long fight, or when the computer's clock was changed; they now wait and go out afterwards (the send queue stays capped).
- "Taken down" and "avenged for you" no longer count a namesake: when the tracker or your own book knows the killed player by full name, no other killer with the same first name is credited.
- In a dungeon, a refused send now holds only its own way (the guild, or one friend's whisper); the rest goes on. `/dn probe` shows the first refusal, not only the first attempt.
- A chat lockdown that ends without an event no longer leaves the queue waiting for the next message: a slow timer keeps checking for about an hour, and starts again after something was sent. After a longer lockdown, what waits goes out with the next event or message.
- Bounties in a long answer under the client's throttle, or after a hello that had to wait (login in combat), fell out of the answer window and were cut to five; the window now opens when the hello is really sent and stays open while the answer comes in. Releases benefit the same way.
- The bounty of a member who left the guild now goes like his releases.
- A bounty taken back by a friend who has become a guildmate is now also removed from the friends' book.
- A bounty on yourself, your own chars, or guildmates and friends you heard with DeathNote under their full name, sent by someone else, is no longer stored. A bounty repeated unchanged in an answer is no longer checked again (costs as before the check).
- "Avenged for you" stays silent no longer when its "taken down" message was dropped.
- Taking back a revenge set "last revenge" to the wrong time; it now shows the newest revenge that is left, also when 1.2.0 recognised a revenge in between.
- The poster can be dragged again to move the book.
- A double click on "Note revenge" no longer takes the revenge back at once ("Undo" waits half a second).
- `/dn bounty` with a typo in the name no longer posts an invisible bounty: only names from a book are taken. Without anything it lists your own bounties. Amounts with a unit ("50g") get the rule line. Striking a killer from your book takes back your bounty when no other book shows him.
- The bounty and "avenged by" lines no longer run over the poster in any language: the first name and "+2", all names in the tooltip; "last seen" always stays on the poster.
- The coin in the lists goes when a bounty expires; one rule for pardoned killers in menu and poster; the bounty field no longer lies over the input; the tooltip names how many more there are; fewer tables when the book is redrawn.
- "Set a bounty" is called "ausloben" throughout in German; Slavic languages no longer use male verb forms in the new lines.
- The "avenged by" tooltip in Chinese no longer ends its title with a colon.
- Reading the guild roster makes less garbage than in 1.2.0 (it had grown with the GUID).

### Known open
- A stranger bound to a friend listed without surname before the friend list showed the friend's GUID stays bound when that friend does not have you on his list (his hello never comes). Nothing new is taken from the stranger, but what he sent stays until you unlink him ("Unlink name").
- The GUID in a hello can be read off a player in the game. A namesake who sends your friend's GUID still ends a binding that was only provisional (its data goes, as in 1.2.0), and a binding the GUID proved switches to him; the friend's data goes at the next clean-up and comes back with the friend's next hello (as in 1.2.0). Only a binding you chose that no hello has proved yet is safe from it. If the friend is also a guildmate, the forger stays bound until you unlink him by hand, and until then the friend's releases for friends alone are refused.
- A Battle.net friend known by first name only, bound to a char by character whisper: when the same Battle.net account shows up on the friend list with another char of the same first name, the bound char's data goes, even when it was the friend's own alt. The addon cannot tell an alt from a namesake there.
- If you chose the wrong name and your friend proves himself by GUID later, you are asked again (conflict) instead of the binding switching by itself.

## 1.2.0

### Added
- Friends' book: friends from your friend list who run DeathNote share deaths, hand entries and hit list calls by hidden whisper, just like the guild.
- The same person on your friend list and on Battle.net counts as one friend.
- Hit List: put a killer on the list for guild, friends or both, with a short reason (`/dn hunt Name`, poster, row menu).
- Hit List: "taken down by ..." when someone with DeathNote kills a target with their own killing blow; counter per target.
- Hit List: targets raise the alarm; new targets of others arrive as one chat line, a target in sight gets the alarm right away.
- Hit List: call off your own call (`/dn calloff Name`), call off all of your own from the row menu, hide a target just for you.
- Hit List: calls can expire after 30, 90 or 180 days (default: never).
- 21 languages: English, German, French, Spanish, Italian, Portuguese (Brazil), Russian, Korean, Chinese (Simplified and Traditional), Swedish, Norwegian, Danish, Finnish, Dutch, Polish, Czech, Hungarian, Croatian, Ukrainian, Turkish.
- Language follows the game client by default; choose another in House Rules (Book sheet) or with `/dn lang <code>`, back with `/dn lang auto`.
- English subcommands in every language: help, quiet, guild, friends, test, sync, add, del, hunt, calloff, lang. The German ones keep working.
- Alarm shows the target's level next to the name; higher than yours in warning colour with the gap ("Level 63 (+3)", skull: "Level ??").
- Dry remarks under some messages and a few milestones, English and German only; switch: House Rules, Book sheet.
- `/dn friends`: state of the friends' book.

### Changed
- Fourth tab is now "Guild & Friends" with the views Hit List, By killer and By guildmate, and a source switch (All, Guild, Friends) once both exist.
- Death Log lists deaths by players only. Deaths to monsters and the environment are still counted, but no longer listed; old entries stay in the saved file.
- House Rules, Guild sheet: two groups, Sharing and Alerts; the rarely used switches moved behind "More".
- Welcome line ends with the current language and how to change it.
- Saved data stays language-neutral; a 1.1.0 book loads without loss, and 1.1.0 can still read a 1.2.0 book.
- Mixed guilds work: 1.1.0 clients keep reading the guild channel and ignore the new messages.

### Fixed
- Guild book poster showed the "Victims" label twice.
- The note on entries taken over from the guild book was stored as finished text; it is now built when shown, so it follows the language. Old notes are converted on load.
