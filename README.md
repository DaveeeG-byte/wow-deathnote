# DeathNote 1.2.2

An addon for WoW Forever (Interface 16001). In open-world PvP it writes down who killed you, shows your killers as a
book and warns you when one of them is in sight again. Confirmed kills are shared silently with your guildmates (the
guild book) and with friends from your friend list (the friends' book); together you can put killers on a hit list and
post your own bounties. Changes per version: `CHANGELOG.md`.

## Folders
- `DeathNote/` the addon (copy it as is to `_forever_/Interface/AddOns/DeathNote/`)
- `DeathNote/Media/` textures (TGA); `DeathNote/Media/Sounds/` alarm sounds (Ogg Vorbis, mono): `feder`, `glocke`,
  `gong`, `herzschlag`, `sirene`, each in 5 levels `_1` to `_5` (soft to loud)
- `tests/` logic tests (`bash tests/run.sh`), `tests/ui/` UI tests (`bash tests/ui/run.sh`), both run with luajit;
  `tests/fixtures/` holds real SavedVariables from 1.0.1 as a migration case, and `addon-1.1.0/` and `addon-1.2.0/` as
  old clients for the mixed-version tests
- `DeathNote/Libs/` embedded libraries (see below)
- `tests/ui/layout_guard.lua` checks every view in all 21 languages for overlapping or cut text (1.2.2);
  `tests/test_plates_libs.lua` and `tests/ui/minimap_real_libs.lua` (loader `tests/ui/real_libs.lua`) check the
  nameplate status and the minimap button with the real embedded libraries (1.2.2)
- `tests/ui/make_media.sh` rebuilds the textures (ImageMagick), `tests/ui/make_sounds.sh` the sounds
- `TRANSLATING.md` how to translate the addon

## Commands
`/dn` open/close the book · `/dn add <Name [Surname]>` add a killer by hand · `/dn del <Name [Surname]>` strike them ·
`/dn quiet` alarm off/on · `/dn test` test alarm · `/dn guild` guild book status · `/dn friends` friends' book status ·
`/dn sync` sync guild and friends now · `/dn hunt <Name [Surname]>` put on the hit list (no name: show the hit list) ·
`/dn calloff <Name [Surname]>` call off your own hunt · `/dn bounty <Name [Surname]> <gold>` post your own bounty (no
gold or 0: take it back; nothing at all: list your own) · `/dn lang <code|auto>` language of the book (after `/reload`)
· `/dn probe` troubleshooting (`/dn probe combatlog` also tries the combat log) · `/dn debug` detailed log of every
death · `/dn help`. Same thing: `/deathnote`, `/todesliste`, `/deathlist`. The English subcommands work in every
language (`help quiet guild friends test sync add del hunt calloff bounty lang`, plus the aliases `?`, `mute`, `rm`,
`delete` and `language`); the German ones (`hilfe still ruhe gilde freunde jagd abblasen kopfgeld sprache`) keep
working too. On the first login (once per account) a greeting line shows in chat 5 s later, never in combat.

## Languages (1.2.0)
21 languages. The default is the client's language (`enGB` counts as English, `esMX` as Spanish, `ptPT` as
Portuguese); if the addon does not have it, English. Change it in the House Rules (sheet Book: first entry
"Automatic", then the 21 languages, each in its own spelling) or with `/dn lang <code>`, back with `/dn lang auto`;
the change takes effect after `/reload`. There is no dialog on first start; the greeting ends with the language and how
to change it. Coming from 1.1.0 you keep the client's language; a stored choice stays. Each language file in `Locales/`
builds its table only when it is the chosen one (`Locale.lua`), English fills the gaps. Nothing translated is ever
stored, sent or exported. Translating: `TRANSLATING.md`, check with `luajit tests/test_locales.lua`.

## Roles of a deed (1.1.0)
Every deed of a killer has a role:
- `kill` confirmed killing blow (Death Recap, meter, or set by hand),
- `assist` took part: the Death Recap shows them as a damage source, but not the killing blow,
- `suspect` only the heuristic (had you targeted shortly before) or not proven.

Anyone with at least one kill or assist is wanted; anyone with only suspicions waits under "Unsolved".
Rank: kills, then assists, then the most recent kill, then the name. The alarm threshold counts kills plus assists.
Confirm turns a suspicion or an assist into a kill, Dismiss only removes suspicions.
DB version 3 converts older books once on the first login (co-attackers from the recap become assists).

## Friends' book (1.2.0)
The same silent messages as in the guild (protocol version 1), but as whispers to character friends on the friend
list who are online. First a hello to the friends online (at login after 22 to 34 s; a friend who comes online later
after 25 to 40 s; at most 30 hellos per 10 minutes, at most one per friend per 5 minutes, in friend list order). Live
messages only go to friends who answered in this session, i.e. who have DeathNote, at most 10 at a time. A friend who is
certainly (by full name) in your own guild gets nothing by whisper (they hear it in the guild; only calls meant for
friends alone also reach them by whisper); if the client only gives first names, it whispers when in doubt (duplicates
are merged). Someone who leaves the guild is served by whisper right away. The same person on the friend list and on
Battle.net is one friend (whisper preferred). Only messages from a name on your own friend list are accepted; anything
else is dropped before it is read.

A friend listed without a surname: the hello to friends carries your own GUID; if the friend list gives the friend's
GUID, only a sender with that GUID is accepted (even when the client names the sender by first name only; if the proof
is missing, the status line says so; a name that is already linked waits quietly for its hello, see protocol item 17).
A guildmate listed without a surname gets calls meant for friends alone by whisper. Otherwise the first contact links
the full name provisionally; if a second full name with the same first name shows up, the book accepts nothing from
either of them, the linked name's data stays without alarm, a chat line and the status line name both, and the player
picks one in the "Guild & Friends" tab, view "By guildmate", by right-click ("My friend: …"). "Unlink name" is there too
(it deletes what the name brought in); removing and re-adding the friend also undoes the link (once they are missing
from three scans in a row); `/dn friends` lists the linked full names.

Shared are the same things as in the guild: your own confirmed deaths, your own entries added by hand, your own hit
list calls. Never: notes, suspicions, assists, pardoned players, imported entries, adopted entries. Everything is stored
account-wide in `DeathNoteDB.friends` (same caps as the guild).

Time limits count your own play days (days on which a character of the account was logged in), never calendar days of
a break you take. A friend removed from the friend list only disappears once they have been missing several times in a
row from the list of every one of your characters that had them, and have not been seen for 14 play days (an empty
list never deletes). A Battle.net friend counts as present as long as they are on the Battle.net list, even offline
(recognized by a checksum of their BattleTag; the tag itself is never stored); otherwise after 60 play days unseen. The
limit for one of your characters only runs on play days on which exactly that character was logged in; a character
that is never logged in loses nothing. The hello asks back per own character and friend (all the way back, as long as
that character has not yet had a complete answer from them). If the server refuses whispers to one friend three times,
only that friend rests; if nothing gets through to several of them, the book stops and says so in the status line.
Switch: House Rules, sheet Guild, "Share with friends" (on by default).

## Hit list (1.2.0)
"Put on hit list" in the row menu, on the poster (when there is no stamp on the photo) or with `/dn hunt`: for the
guild, friends or both, with a short reason (at most 60 characters, one line, cleaned on sending and on receiving).
Shared are name, class, level, reason and who made the call. Everyone can only take back their own call ("Call off the
hunt"); a target stays as long as any call on it stands. When someone with DeathNote kills a target with their own
killing blow, everyone sees "taken down by …" (a counter on the entry, one message).

Targets trigger the alarm (own switch, on by default); the alarm shows the target's level next to the name; if it is
higher than yours, in warning colour with the gap ("Level 63 (+3)", skull: "Level ??"). In the fourth tab ("Guild &
Friends") the hit list is the first view as soon as there is a call (without calls the view does not exist); the source
(All, Guild, Friends) can be picked as soon as there is a guild and a friend with DeathNote. New targets from others
arrive as one chat line; every new target that is in sight right now gets the alarm (own switch "Warn about hit list
targets", even when the news switch is off). "Hide for me" (row menu) takes a target out of the alarm and moves it,
faded, to the end; nothing is sent. "Call off all mine" in the row menu of one of your own calls (from two on) takes
back all your calls. "Empty guild book" and "Empty friends' book" (House Rules, sheet Guild, More) also remove the other
players' calls on that list; the same call does not come back with the next sync (a new call by the same player does).
Switch "Report hit list news: new, taken down" for the messages about new and taken-down targets. With both sharing
switches off, the hit list and your own calls stay visible and usable in the fourth tab as long as there are targets.

## Bounty (1.2.1)
Click the bounty on the poster (or row menu "Post a bounty", right-click on the poster, `/dn bounty`): a whole number
of gold from 1 to 99999; Enter sets it, empty or 0 takes it back to the book's own value, Esc cancels. Not on pardoned
players (one already posted can be taken back there). `/dn bounty` only takes names from a book (first name and
surname as the game shows them; a typo posts nothing), with no arguments it lists your own. When a killer is struck
from your own book and is in no other book and not on the hit list, your bounty on them goes too.

A posted bounty shows on the killer's poster (own book, guild and friends' book, hit list) as a line
"500g, posted by you" or "… posted by Anna"; several: the total and the biggest poster ("Bounty 700g: Anna +2"), all
amounts in the line's tooltip; if the line is too wide, the name is shortened. When the poster runs out of room, race
and guild give way first, then the bounty line; "Last seen" stays. On your own poster the total is written large in red
ink. In the lists a small coin sits next to the killer (gone once the bounty has expired).

Shared with guild and friends who have DeathNote, independent of the hit list; no window, no sound when one arrives.
Everyone sends only their own, nobody passes anything on, everyone takes back only their own. At most 20 of your own per
character, not on your own characters, guildmates or friends with DeathNote (also on receipt: a bounty on the receiver,
their characters, or guildmates and friends they have heard with DeathNote under their full name is dropped). Bounties
expire like calls ("Calls last"); someone who leaves the guild loses their bounties in the guild book just like their
calls. The addon pays nothing and checks nothing: it is an announcement, you settle it among yourselves. The book's
automatic value (kills, assists, level, revenge) stays as it was and applies as long as nobody has posted a bounty.

## Revenge (1.2.1)
"Note revenge" counts one revenge by hand; for about 8 seconds afterwards the same button reads "Undo" and takes back
exactly that revenge (its message goes too; a double click does not count twice and does not undo right away, "Undo"
only works after half a second). Later: "Take back one revenge" in the row menu or by right-click on the poster, as long
as there are revenges noted by hand. Revenge the book detected itself (own killing blow, honor) stays; it is counted
separately (`revengeHand` on the entry, additive; plus the times `revengeHandAt` and `revengeAutoAt`, so that "last
revenge" shows the newest one left after taking one back). Revenge from books of 1.2.0 and older counts as detected.
Stamp, counter, the book's bounty and rank follow the counter; a milestone already shown ("first revenge") does not come
back.

Avenged for you: when someone with DeathNote kills, with their own killing blow, a killer who stands in the guild or
friends' book for killing others, that goes to the guild, or only to the friends that killer killed. Anyone whom this
killer hurt in their own book (kill or assist) gets a chat line "Anna took down Grimm Bart for you." with the short
revenge sound, no window; everyone else only sees it on the poster ("Avenged by Anna 2×", several: "Avenged by
Anna +2", all with counts in the tooltip) and in the row of the guild and friends' book ("avenged 3×"). If the killer is
also a hit list target, there is only the taken-down message; both counters count (if the taken-down message does not
arrive, "for you" shows once). Only the one actually killed counts: if the tracker or your own book knows them by full
name, the same first name of another killer does not count (this also applies to "taken down"). The stamp REVENGE TAKEN
stays reserved for your own revenge. Switch: "Report hit list news: new, taken down".

## Instances (1.2.1)
In dungeons and raids the book sends outside of combat just as it does outdoors. If the client refuses there, only that
one route waits for this instance (the guild, the whisper to exactly that friend, or Battle.net to them; one attempt, no
retry loop), all other routes keep sending; after leaving, whatever waits goes out; it does not expire with time, and
answers to a hello on that route wait along with it. In battlegrounds and arenas, in combat and while chat is locked the
book waits; whatever waits goes out afterwards, even after a long fight (the queue is capped at 140, a message's age
counts in session time without the waiting time; if a lock ends without an event, a slow timer keeps checking every two
minutes for about an hour and starts again as soon as something went out; after a longer lock, what waits goes out with
the next event or the next own message). Whatever goes out at once after a long wait is taken live by the receiver only
up to their cap (5 new calls or bounties per sender in 10 minutes, "taken down" and "avenged" only up to 10 minutes
old); the next answer brings the rest. Receiving works everywhere. The status line and `/dn guild` say what the guild is
waiting for; `/dn probe` records the result of the first attempt in an instance and overwrites it with the first
refusal (`probe.guild.instanceSend`: kind, ok, throttle or refused, code, route, time). The book itself stays quiet in
instances as before (no alarm, no enemy names).

## Death Log (1.2.0)
The third tab lists your own deaths to players: confirmed PvP deaths and deaths with an unclear killer. Deaths to
monsters and the environment (`pve`) are not in it, do not count on the tab and not in the search; they are only
counted (`DeathNoteDB.tally`, for the dry remarks and `/dn beichte`). Old `pve` rows from 1.1.0 stay in the file (1.1.0
shows them again), they are just not shown.

## Dry remarks (1.2.0, German and English only)
Switch "Dry remarks" (House Rules, sheet Book, on by default): now and then a line under a message, milestones (the same
killer ten times, first revenge, Public Enemy No. 1 taken down, 100 deaths, 30 days without dying) exactly once, at most
one random line per 10 minutes (also across `/reload`). The book has moods: a few hidden commands, a thumbtack on the
poster, a different line on the empty book. Members of the guild "Die Fachkräfte" get their own variants and a stamp on
taken-down targets, plus one line at the foot of "How it works". The other 19 languages get none of this. Only numbers
and times are stored (`DeathNoteDB.humor`).

## House Rules
Sheets Book, Alert, Guild. Sheet Alert: sound (No sound, Raid warning, Bell, Gong, Heartbeat, Quill, Siren; the
addon's own sounds are in `Media/Sounds/`), volume 1 to 5, channel (Master, Effects, Dialog), cooldown per killer,
threshold "Alarm at this many deaths by them" (counts kills plus assists), alarm size, test alarm.
Sheet Guild: two groups, SHARING (with the guild, with friends, sightings) and ALERTS (killers from guild and friends,
hit list targets); everything rarely used sits behind "More" at the bottom right (sharing entries added by hand,
receiving the guild book, "Calls last", warning about entries added by hand, messages, threshold, status, emptying the
books). The state of "More" is remembered. Quick off: `/dn quiet`.

## Layout
| File | Job |
|---|---|
| `Locale.lua` | language choice, text table `ns.L`, formatter with named placeholders, plural rules, fonts per script |
| `Locales/xxXX.lua` | texts per language (`enUS` is the source and fallback, `deDE` keeps the 1.1.0 wording); length limits in `tests/sprachen/_limits.lua` (tests only) |
| `Core.lua` | namespace, event bus, helpers (including the time format `When`/`Ago`), secret guards, slash commands, greeting |
| `Store.lua` | SavedVariables `DeathNoteDB` (account-wide), roles, ranking, open cases, export/import as text |
| `Tracker.lua` | enemy players in sight (nameplate, target, mouseover, focus, group targets) |
| `Attribution.lua` | death → killer: Death Recap, otherwise exactly one player targeting you in the last 6 s (suspect only); revenge |
| `Probe.lua` | diagnostic probe, writes to `DeathNoteDB.probe` |
| `Sync.lua` | guild book via addon messages on the GUILD channel, send queue for both channels, hit list |
| `Friends.lua` | friends' book: friend list, trust, hello to friends, whispers (1.2.0) |
| `Bounty.lua` | own bounties and "avenged for you": sending, receiving, snapshot, expiry (1.2.1) |
| `Alert.lua` | alarm popup with a target button, shared styling helpers |
| `UI.lua` | the book: Wanted, Unsolved, Death Log, Guild, House Rules, How it works |
| `Extras.lua` | tooltip line, messages after a death, revenge and guild deaths, new hit list targets |
| `Humor.lua` | dry remarks, milestones, hidden commands (German and English only) |
| `Libs/` | embedded LibStub, CallbackHandler, LibDataBroker and LibDBIcon for the minimap button (1.2.2) |

## Embedded libraries (1.2.2)
The minimap button is a standard LibDBIcon-1.0 button with a LibDataBroker-1.1 launcher, so minimap button collectors
recognise it. Its position and "Show minimap button" carry over from 1.2.1. The libraries sit unmodified in
`DeathNote/Libs/` and load through `Libs/embeds.xml` before `Core.lua`; LibStub loads each library only once per client,
the newest minor of all installed addons wins. Without them DeathNote falls back to its own button.

| Library | Minor | License |
|---|---|---|
| LibStub | 2 | Public Domain (header of `LibStub.lua`) |
| CallbackHandler-1.0 | 8 | Ace3 style BSD license, `CallbackHandler-1.0/LICENSE.txt` |
| LibDataBroker-1.1 | 4 | by tekkub, https://github.com/tekkub/libdatabroker-1-1 (no license file upstream) |
| LibDBIcon-1.0 | 57 | Ace3 style BSD license, `LibDBIcon-1.0/LICENSE.txt` |

Details: `DeathNote/Libs/README.txt`. The release zip contains the folder with its license files.

## Guild protocol (version 1)
1. Prefix `DeathNote`, GUILD channel only, silent addon messages, no visible chat.
2. At most 255 bytes per message, fields separated by tabs, `%`, `|` and control characters escaped as `%XX`.
3. `K` = a kill that just happened (killer, class, level, zone, time, victim character).
4. `H` = hello 8 to 20 s after login with `since`; `R` = answer, only your OWN confirmed kills, at most 30.
5. `S` = sighting of a guild enemy, only when switched on in the House Rules.
6. Nobody passes on other players' data. Notes, suspicions, pardons and imported entries are never sent.
7. A deed is identified by victim character plus timestamp; the victim must match the sender.
8. Caps: 400 enemies, 20 deeds per enemy, 40 enemies per sender, one list per guild (at most 5).
9. `M` = name added to my list by hand (killer, class, level, time, character), sent right away and in answers to `H`
   (at most 20).
10. `X` = struck again (killer, character); missed `X` come with the next answer (at most 10).
11. Never sent: suspicions, assists, pardoned players, imported entries, entries adopted from the guild list.
    The character in `M` and `X` must match the sender.
12. Caps: 20 entries by hand per sender; they count towards the 40 per sender and the 400 in total.
13. Clients on 1.0.x drop `M` and `X` silently.
14. (1.2.0) The same messages go as WHISPER to friends (see Friends' book); 1.1.0 only reads GUILD.
15. (1.2.0) `J` = put on the hit list (killer, class, level, time, character, reason, book id), sent right away and in
    answers (at most 10); `A` = hunt called off (killer, character), missed `A` come with the next answer (at most 10);
    `E` = target taken down (killer, character, time), only with your own killing blow (`PARTY_KILL`). The character
    must match the sender (with surname where the client provides one). Caps: 10 calls per sender (exactly one per
    target), 100 targets per list (when full, the oldest call by someone else goes, never your own). New targets from
    one sender: in the minute after your OWN hello at most 10 as an answer, otherwise live at most 5 in 10 minutes; the
    rest comes with the next answer, without a message; new targets from others are always announced together (one chat
    line). Calls last forever (default), 30, 90 or 180 days (House Rules, sheet Guild); when your own expires, an `A`
    goes out. `E` counts every kill (character, time) once, only up to 10 minutes old, at most 3 per sender in 10
    minutes, counter at most 99. 1.1.0 drops J, A, E, Z silently.
16. (1.2.0) `Z` = end of an answer (character, count, book id): this many `J` were ALL of the sender's calls (only when
    the answer was not capped). If the count matches on the receiver's side, the answer counts as a snapshot: whatever
    the sender no longer names is called off, but only calls of exactly this character with the same book id and only
    in the book of that channel (guild or friends). The book id is a short random word per SavedVariables
    (`DeathNoteDB.guild.book`, created once); it is an optional last field in `J` and `Z`. That way a second computer, a
    lost file or a namesake deletes nothing. Calls without an id only end by calling off, expiry or leaving the guild.
    As long as your own guild name is not known after login, the book does not answer. An `A` on GUILD also takes back
    the copy of the same call in the friends' book. When a caller leaves the guild (not in the roster, not heard on
    GUILD for 14 days) and is not a friend, their calls drop out of the guild book on the next roster check.
17. (1.2.0) The hello to a friend (never to the guild) has a fifth field: your own GUID. An answer to a friend starts
    with this hello. (1.2.1) The GUID in the hello of a provisionally linked name is remembered on the link (`tie.hg`).
    If the friend list later gives the GUID of a friend without a surname, the same GUID proves the link, and so does the
    guild roster when it names the linked full name with that GUID; otherwise the link stays with its data, the linked
    name's new messages are only accepted after the proof, and the friend is asked (at most three times per session,
    plus as always when they come online). Nothing is deleted on suspicion: a linked name's data only goes when its own
    hello carries a GUID other than the list's, or when the friend with the list's GUID shows up under a different name,
    by hello or in the guild roster (the status line then names the stranger once). Exception: a link the player chose
    themselves, whose own hello said nothing else, is not overruled by any hello; a hello with the list's GUID under a
    different name becomes a conflict, both sides' data stays, and the player picks (or the chosen one's hello with that
    GUID settles it). The GUID in a hello can be read off a player in the game: a namesake with a forged GUID still ends
    a merely provisional link together with its data (as in 1.2.0), and a link proven by GUID switches to them (its data
    goes at the next cleanup and comes back with the friend's next hello, as in 1.2.0; if the friend is also a guildmate,
    the forger stays linked until the link is undone by hand). The same applies when a Battle.net friend with a bare
    first name, to whom a name was linked by character whisper, is on the list with the same Battle.net account as a
    character with surname and GUID, and the linked name has a different surname (even if it was an alt of that friend:
    that cannot be told apart there). A guildmate listed without a surname whispers calls meant for friends alone; if
    the guild roster gives a different GUID for their full name than the list does, the message is dropped; if it gives
    no usable one, it is accepted as in 1.2.0. Known gap: a stranger who was linked before the list gave the GUID, and
    whose friend does not have the player on their own list (so that hello never comes), stays linked; the book accepts
    nothing new from them.
18. (1.2.1) `B` = own bounty (killer, character, gold, time, book id), sent right away to guild and friends and in every
    answer to `H` (all your own, at most 20); gold `0` takes it back (only your own and only one that is not newer).
    `Y` = end of the bounties of an answer (character, count, book id), after the `Z`: like `Z` for calls, whatever the
    sender no longer names is taken back (only this character, only the same book id, only when the number of `B` that
    arrived matches; a `Y` on GUILD also clears the copy in the friends' book). The amount is a whole number from 1 to
    99999, anything else is dropped. Caps: 20 per sender, 200 targets per book, new ones live at most 5 in 10 minutes
    (20 in the answer window). Expiry and leaving the guild work like calls. The answer window (for `J`, `Z`, `B`, `Y`)
    opens when your own hello really went out, and stays open for a sender as long as their answer keeps arriving (40 s
    after each part, at most 10 minutes): a long answer held back by the client's throttle still counts as an answer.
19. (1.2.1) `V` = avenged (killer, character, time, flag `1` when an `E` for the same kill went the same route): only
    with your own killing blow (`PARTY_KILL`), only in the open world, only for a killer who has killed others in the
    guild or friends' book; to the guild, or only to the friends affected. Like `E`: every kill once, only up to 10
    minutes old, at most 3 per sender in 10 minutes, counter per avenger at most 99, 200 killers. Only accepted for a
    killer who is in the book of the channel or who has done something to the receiver themselves.
20. (1.2.1) 1.2.0 and 1.1.0 drop `B`, `Y` and `V` as an unknown kind without changing their data; `E` stays as it was
    (1.2.0 keeps counting "taken down" exactly once). Answers contain one more `Y`; answers to friends wait for room for
    up to 103 messages (queue 140).

## Client limits
No combat log for addons, no detection of stealthed players, no distance or direction. Only players visible as a
nameplate, target or mouseover are detected. In dungeons, battlegrounds and arenas enemy names cannot be read, so the
book stays quiet there. The target button cannot be changed in combat.

## Learned from
Approach and API calls (no code taken): Hitlist (Forever), Spy (Forever), Kill on Sight (MIT).
