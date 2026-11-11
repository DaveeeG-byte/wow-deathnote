# Changelog

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
