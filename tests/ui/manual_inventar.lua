-- 1.7.1 manual: the inventory. Every function a player can see or set off, the version it came with, and the chapter
-- of the manual ("?") that explains it (UI.lua UX.MANUAL, ids). Read by tests/ui/ma171_inventar.lua.
-- Rule: every visible change of the book brings this list and the chapter along in the same update (README, section
-- "How it works"; tests/ui/ma171_stand.lua turns red on a new version until UI.MANUAL_CHECKED follows).
return {
  -- first steps
  { "open the book: /dn, minimap button, key", "1.0", "start" },
  { "minimap button: right click House Rules, middle click alarm off/on, drag", "1.0", "start" },
  { "notice after a death by a player; click opens the book there, right click away", "1.0", "start" },
  { "tabs Wanted, Unsolved, Death Log, Guild (Guild & Friends), Rap Sheet", "1.3.0", "start" },
  { "click a row: poster; right click: menu; shift-click: name into the chat", "1.0", "start" },
  { "entered by itself after a death in the open world", "1.0", "start" },
  -- wanted and the poster
  { "list of killers, worst first (open debt)", "1.0", "wanted" },
  { "sections Settled and Pardoned at the end of the list", "1.4.0", "wanted" },
  { "poster: deeds with time and place, roles assisted, suspect, attacked", "1.1.0", "wanted" },
  { "own note on the poster", "1.0", "wanted" },
  { "search field; Enter enters a name by hand", "1.0", "wanted" },
  { "filter and sort menus", "1.4.0", "wanted" },
  { "row and poster menu: Note revenge, Pardon, Strike, Put on hit list, Post a bounty, Post", "1.2.1", "wanted" },
  { "Undo for a few seconds after Note revenge", "1.2.1", "wanted" },
  { "chronicle of a feud next to DEEDS", "1.5.0", "wanted" },
  { "switch Players | Guilds: enemy guilds", "1.6.0", "wanted" },
  { "declare a feud: members in sight ring quietly", "1.6.0", "wanted" },
  { "stamps on the poster (public enemy No. 1, revenge, pardoned, suspect, grudge, settled, overpaid)", "1.0", "wanted" },
  -- unsolved
  { "unclear deaths and suspicions wait under Unsolved; click on a candidate settles", "1.0", "unsolved" },
  { "Confirm and Dismiss of a suspicion", "1.1.0", "unsolved" },
  { "red number on the tab counts suspicions and open cases", "1.0", "unsolved" },
  { "switch Cases | Claims | Filed away", "1.6.0", "unsolved" },
  { "old suspicions filed away after 30 play days; Take back; Keep", "1.6.3", "unsolved" },
  { "switch File away old suspicions (House Rules, Book)", "1.6.0", "unsolved" },
  -- alarm
  { "alarm on nameplate, target, mouseover, group target; red screen edge", "1.0", "alert" },
  { "click on the alarm targets (after combat), right click closes", "1.0", "alert" },
  { "suspects only when switched on", "1.1.0", "alert" },
  { "alarms of guild and friends' book, hit list, bounty of others, each with its title", "1.7.0", "alert" },
  { "feud member in sight: soft sound and chat line", "1.6.0", "alert" },
  { "alarm settings: sound, volume, cooldown, threshold, size, test alarm", "1.0", "alert" },
  { "Move alarm, /dn move (placing mode)", "1.6.4", "alert" },
  { "silent in dungeons, battlegrounds, arenas; /dn quiet; middle click", "1.0", "alert" },
  { "victim alarm and alarm for settled scores", "1.3.0", "record" },
  { "mark over the nameplate (thumbtack, crosshair)", "1.5.0", "rules" },
  -- grudge and call for help
  { "grudge notice after an attack: tick, cross, running out", "1.4.0", "grudge" },
  { "grudge notice: hover holds, drag moves, right click closes", "1.5.0", "grudge" },
  { "grudge settings: battlegrounds, time, size, test notice (House Rules, Rap Sheet)", "1.4.0", "grudge" },
  { "call for help: button Call on the notice or a key", "1.6.0", "grudge" },
  { "receiving a call: sound, slip, map with a pulsing pin", "1.6.0", "grudge" },
  -- death log
  { "Death Log: every death, views Players, All, Causes", "1.6.0", "log" },
  { "death file: killer, helpers, how, place as a link", "1.2.0", "log" },
  { "causes ranked, NEMESIS stamp, switch for deaths by creatures and the world", "1.6.0", "log" },
  { "awards for dying", "1.6.0", "log" },
  -- map
  { "crime scenes on the world map: pins of deaths, kills, guildmates, friends", "1.5.0", "map" },
  { "pins of a call for help and of a sighting; bundles with a number", "1.6.0", "map" },
  { "pin tooltip, click opens the book; place in the book opens the map", "1.5.0", "map" },
  { "the map's switch (period, open debts, own, guild, friends); crime scenes on/off", "1.5.0", "map" },
  -- guild and friends
  { "guild book and friends' book: what is shared, what never", "1.2.0", "guild" },
  { "tab Guild: By killer, By guildmate; copy to my book, copy all", "1.4.0", "guild" },
  { "guild chronicle behind the red ribbon: who has the book, avengers, week card", "1.6.0", "guild" },
  { "dot on the guild tab", "1.6.0", "guild" },
  { "sightings to guild and friends", "1.6.0", "guild" },
  { "only with guildmates and friends who have the book", "1.2.0", "limits" },
  -- hit list
  { "Put on hit list (poster, menu, /dn hunt), for guild, friends or both, with a reason", "1.2.0", "hunt" },
  { "hit list view in the fourth tab; taken down by", "1.2.0", "hunt" },
  { "Call off the hunt, Hide for me, Calls last", "1.2.0", "hunt" },
  -- bounty
  { "BOOK VALUE and BOUNTY as two words on the poster", "1.7.0", "bounty" },
  { "post a bounty (click the value, menu, /dn bounty), take it back with 0", "1.2.1", "bounty" },
  { "bounty earned: slip, Unsolved > Claims, You owe and Owed to you", "1.7.0", "bounty" },
  { "Mark as paid, Decline; the book moves no gold", "1.6.0", "bounty" },
  -- rap sheet
  { "rap sheet: own kills and group kills, nothing shared", "1.3.0", "record" },
  { "score you : them, open, settled, overpaid; rank 1 always open", "1.3.0", "record" },
  { "points on four paths, rank, needle, awards and bests", "1.3.0", "record" },
  { "tab Rap Sheet: file, latest kills, sheet per victim with his deeds", "1.6.1", "record" },
  { "switches of the sheet Rap Sheet", "1.3.0", "record" },
  -- post and pass on
  { "Post: a line in the chat, channels, every 10 seconds, never in combat", "1.5.0", "post" },
  { "tabs My week and Discord of the window Post", "1.5.0", "post" },
  { "a name in a posted line is a link (guest poster)", "1.5.0", "post" },
  { "Back up book and Import book", "1.0", "post" },
  -- house rules
  { "House Rules: gear, minimap right click, the game's options page", "1.6.0", "rules" },
  { "sheet Book: tooltip line, minimap button, filing, book size, language, cover, back up, map", "1.3.0", "rules" },
  { "sheets Guild (More) and Rap Sheet", "1.2.0", "rules" },
  { "three covers; language and cover after a reload", "1.3.0", "rules" },
  -- limits and commands
  { "limits of the client: no combat log, no stealth, no distance, quiet in instances", "1.0", "limits" },
  { "the book moves no gold", "1.2.1", "limits" },
  { "/dn help lists every command; /dn move", "1.0", "limits" },
  { "key bindings: book, target into book, target on hit list, alarm, call for help", "1.5.0", "limits" },
  { "the manual itself: contents, chapters, ? opens the chapter of the open view", "1.7.1", "start" },
}
