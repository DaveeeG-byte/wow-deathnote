# DeathNote 1.2.0

Addon für WoW Forever (Interface 16001). Schreibt im Open-World-PvP mit, wer dich getötet hat, zeigt die Täter als
Buch und warnt, wenn einer wieder in Sicht ist. Teilt sichere Kills unsichtbar mit den Kollegen der Gilde (Gildenbuch)
und mit Freunden von der Freundesliste (Freundesbuch); gemeinsam lassen sich Täter zur Jagd freigeben (Abschussliste).

## Ordner
- `DeathNote/` das Addon (so nach `_forever_/Interface/AddOns/DeathNote/` kopieren)
- `DeathNote/Media/` Texturen (TGA); `DeathNote/Media/Sounds/` Alarmtöne (Ogg Vorbis, mono): `feder`, `glocke`,
  `gong`, `herzschlag`, `sirene`, je in 5 Stufen `_1` bis `_5` (leise bis laut)
- `tests/` Logik-Tests (`bash tests/run.sh`), `tests/ui/` Oberflächen-Tests (`bash tests/ui/run.sh`), beide mit luajit;
  `tests/fixtures/` echte SavedVariables von 1.0.1 als Migrations-Testfall
- `tests/ui/make_media.sh` erzeugt die Texturen neu (ImageMagick), `tests/ui/make_sounds.sh` die Töne

## Befehle
`/dn` Buch auf/zu · `/dn add <Name [Nachname]>` Täter von Hand eintragen · `/dn del <Name>` streichen ·
`/dn still` Alarm aus/an · `/dn test` Probe-Alarm · `/dn gilde` Stand des Gildenbuchs · `/dn freunde` Stand des
Freundesbuchs · `/dn sync` Gilde und Freunde abgleichen · `/dn jagd <Name [Nachname]>` zur Jagd freigeben (ohne Name:
die Abschussliste) · `/dn abblasen <Name>` eigene Freigabe zurücknehmen ·
`/dn sprache <Kennung|auto>` Sprache des Buchs (nach `/reload`) · `/dn probe` Fehlersuche · `/dn debug` Mitschnitt je Tod ·
`/dn hilfe`. Gleichwertig: `/deathnote`, `/todesliste`, `/deathlist`. Englische Unterbefehle gelten in jeder Sprache
(`help quiet guild friends test sync add del hunt calloff lang`), die deutschen bleiben gültig. Beim ersten Login
(einmal je Account) steht 5 s danach eine Begrüßungszeile im Chat, nie im Kampf.

## Sprachen (1.2.0)
21 Sprachen. Standard ist die Sprache des Clients (`enGB` gilt als Englisch, `esMX` als Spanisch, `ptPT` als
Portugiesisch); gibt es sie im Addon nicht, Englisch. Ändern in der Hausordnung (Blatt Buch, erster Eintrag
"Automatisch", danach die 21 Sprachen in eigener Schreibweise) oder mit `/dn lang <Kennung>`, zurück mit `/dn lang auto`;
der Wechsel wirkt nach `/reload`. Kein Dialog beim ersten Start; die Begrüßung nennt am Ende die Sprache und wie man sie
ändert. Wer aus 1.1.0 kommt, behält die Sprache des Clients; eine gespeicherte Wahl gilt weiter. Jede Sprachdatei in `Locales/` baut ihre
Tabelle nur, wenn sie gewählt ist (`Locale.lua`), Englisch füllt Fehlendes auf. Gespeichert, gesendet und exportiert wird
nie Übersetztes. Übersetzen: `tests/sprachen/LIESMICH-uebersetzer.md`, Prüfung `luajit tests/test_locales.lua`.

## Rollen einer Tat (1.1.0)
Jede Tat eines Täters hat eine Rolle:
- `kill` sicherer Todesstoß (Death Recap, Meter oder von Hand festgelegt),
- `assist` beteiligt: im Death Recap als Schadensquelle belegt, aber nicht der Todesstoß,
- `suspect` Verdacht: nur die Heuristik (hatte dich kurz vorher im Ziel) oder nicht belegt.

Wer mindestens einen Kill oder eine Beteiligung hat, ist gesucht; wer nur Verdacht hat, wartet unter "Zu klären".
Rang: Kills, dann Beteiligungen, dann der letzte Kill, dann der Name. Die Alarm-Schwelle zählt Kills plus
Beteiligungen. Bestätigen macht aus Verdacht oder Beteiligung einen Kill, Verwerfen entfernt nur Verdachtsfälle.
DB-Version 3 stellt ältere Bücher beim ersten Login einmal um (Mittäter aus dem Recap werden Beteiligte).

## Freundesbuch (1.2.0)
Dieselben unsichtbaren Nachrichten wie in der Gilde (Protokoll Version 1), aber als Flüstern an Charakter-Freunde der
Freundesliste, die online sind. Erst ein Hallo an jeden Freund online (beim Login nach 22 bis 34 s, ein Freund, der später
online kommt, nach 25 bis 40 s); Live-Nachrichten gehen nur an Freunde, die in dieser Sitzung geantwortet haben, also
DeathNote haben, höchstens 10 gleichzeitig. Ein Freund, der sicher (mit vollem Namen) in der eigenen Gilde ist, bekommt
nichts per Flüstern (er hört es in der Gilde; nur Freigaben allein für Freunde gehen auch an ihn per Flüstern); nennt der
Client nur Vornamen, wird im Zweifel geflüstert (Doppel werden zusammengelegt). Wer die Gilde verlässt, wird sofort per
Flüstern bedient. Derselbe Mensch auf Freundesliste und Battle.net ist ein Freund (Flüstern bevorzugt). Angenommen wird
nur, was von einem Namen der eigenen Freundesliste kommt, alles andere wird vor dem Lesen verworfen. Steht ein Freund
ohne Nachnamen auf der Liste: Das Hallo an Freunde trägt die eigene GUID; nennt die Freundesliste die GUID des Freundes,
wird nur angenommen, wer sie hat (auch wenn der Client den Absender nur mit Vornamen nennt; fehlt der Beleg, sagt es die
Statuszeile). Ein Kollege, der auf der Liste ohne Nachnamen steht, bekommt Freigaben allein für Freunde per Flüstern. Sonst bindet der erste Kontakt den vollen Namen vorläufig; meldet sich ein zweiter
voller Name mit demselben Vornamen, nimmt das Buch von keinem mehr etwas an, die Daten des Gebundenen bleiben ohne Alarm,
eine Chatzeile und die Statuszeile nennen beide, und der Spieler wählt im Reiter "Gilde & Freunde", Ansicht "Nach
Kollege" per Rechtsklick ("Mein Freund: …"). Dort auch "Bindung lösen" (löscht, was der Name gebracht hat); Entfernen
und neu Hinzufügen löst die Bindung ebenfalls (sobald er in drei Scans hintereinander fehlt); `/dn freunde` nennt die gebundenen vollen Namen. Geteilt werden dieselben
Dinge wie in der Gilde: eigene sichere Tode, eigene Einträge von Hand, eigene Freigaben zur Jagd. Nie: Notizen,
Verdacht, Beteiligungen, Begnadigte, Eingelesenes, Übernommenes. Gespeichert wird accountweit in `DeathNoteDB.friends`
(Deckel wie in der Gilde). Fristen zählen in eigenen Spieltagen (Tage, an denen ein Char des Accounts eingeloggt war),
nie in Kalendertagen der eigenen Pause: wer von der Freundesliste entfernt wird, verschwindet erst, wenn er auf der Liste
jedes eigenen Chars, der ihn hatte, mehrmals hintereinander fehlt und 14 Spieltage nicht gesehen wurde (eine leere Liste
löscht nie). Ein Battle.net-Freund gilt als da, solange er auf der Battle.net-Liste steht, auch offline (erkannt an einer
Prüfsumme seines BattleTags, der Tag selbst wird nie gespeichert); sonst nach 60 Spieltagen ohne Sehen. Die Frist eines
eigenen Chars läuft nur an Spieltagen, an denen genau dieser Char eingeloggt war; ein Char, der nicht eingeloggt wird,
verliert nichts. Das Hallo fragt je eigenem Char und Freund zurück (ganz zurück, solange dieser Char noch keine
vollständige Antwort von ihm bekam). Lehnt der Server das
Flüstern an einen Freund dreimal ab, ruht nur dieser Freund; kommt bei mehreren nichts durch, hört das Buch auf und sagt
es in der Statuszeile. Schalter: Hausordnung, Blatt Gilde, "Mit Freunden teilen" (Standard an).

## Abschussliste (1.2.0)
"Zur Jagd freigeben" im Zeilenmenü, am Plakat (wenn dort kein Stempel auf dem Foto steht) oder mit `/dn jagd`: für Gilde, Freunde
oder beide, mit einem kurzen Grund (höchstens 60 Zeichen, eine Zeile, beim Senden und Empfangen gesäubert). Geteilt
werden Name, Klasse, Stufe, Grund und wer freigegeben hat. Jeder nimmt nur die eigene Freigabe zurück ("Jagd abblasen");
ein Ziel bleibt, solange eine Freigabe besteht. Tötet jemand mit DeathNote ein Ziel mit eigenem Todesstoß, sehen alle
"erlegt von …" (Zähler am Eintrag, eine Meldung). Ziele lösen den Alarm aus (eigener Schalter, Standard an); der Alarm
nennt die Stufe des Ziels neben dem Namen; ist sie höher als die eigene, in Warnfarbe mit dem Abstand ("Stufe 63 (+3)",
Totenkopf: "Stufe ??"). Im vierten Reiter ("Gilde & Freunde") ist die Abschussliste die erste Ansicht, sobald es eine
Freigabe gibt (ohne Freigabe gibt es die Ansicht nicht); die Quelle (Alle, Gilde, Freunde) ist wählbar, sobald es Gilde
und einen Freund mit DeathNote gibt. Neue Ziele anderer kommen als eine Chatzeile; jedes neue Ziel, das gerade in Sicht
ist, bekommt den Alarm (eigener Schalter "warnen", auch wenn "melden" aus ist). "Für mich ausblenden" (Zeilenmenü) nimmt ein Ziel aus dem Alarm, blass ans Ende, es wird nichts gesendet. "Alle
meine abblasen" im Zeilenmenü einer eigenen Freigabe (ab zwei) nimmt alle eigenen Freigaben zurück. "Gildenbuch
leeren" und "Freundesbuch leeren" (Hausordnung, Blatt Gilde, Mehr) entfernen auch die fremden Freigaben der Liste; dieselbe
Freigabe kommt mit dem nächsten Abgleich nicht wieder (eine neue Freigabe desselben Spielers schon). Schalter
"Abschussliste melden: neu und erlegt" für die Meldungen neuer und erlegter Ziele. Sind beide Teilen-Schalter aus,
bleiben Abschussliste und eigene Freigaben im vierten Reiter sichtbar und bedienbar, solange es Ziele gibt.

## Todesjournal (1.2.0)
Der dritte Reiter führt eigene Tode durch Spieler: sichere PvP-Tode und Tode mit unklarem Täter. Tode durch Monster
und Umwelt (`pve`) stehen nicht darin, zählen nicht am Reiter und nicht in der Suche; sie werden nur gezählt
(`DeathNoteDB.tally`, für die trockenen Bemerkungen und `/dn beichte`). Alte `pve`-Zeilen aus 1.1.0 bleiben in der Datei
(1.1.0 zeigt sie wieder), sie werden nur nicht gezeigt.

## Trockene Bemerkungen (1.2.0, nur Deutsch und Englisch)
Schalter "Trockene Bemerkungen" (Hausordnung, Blatt Buch, Standard an): ab und zu ein Satz unter einer Meldung,
Meilensteine (zehnmal derselbe Täter, erste Rache, Staatsfeind Nr. 1 erledigt, 100 Tode, 30 Tage ohne Tod) genau
einmal, höchstens ein Zufallsspruch je 10 Minuten (auch über `/reload`). Das Buch hat Launen: ein paar versteckte
Befehle, eine Reißzwecke am Plakat, ein anderer Satz am leeren Buch. Mitglieder der Gilde "Die Fachkräfte" bekommen
eigene Varianten und einen Stempel bei erlegten Zielen; eine Zeile am Fuß der Gebrauchsanweisung. In den anderen 19
Sprachen gibt es nichts davon. Gespeichert werden nur Zahlen und Zeiten (`DeathNoteDB.humor`).

## Hausordnung
Blätter Buch, Alarm, Gilde. Blatt Alarm: Ton (Kein Ton, Raid-Warnung, Glocke, Gong, Herzschlag, Feder, Sirene;
die eigenen Töne liegen in `Media/Sounds/`), Lautstärke 1 bis 5, Kanal (Master, Effekte, Dialog), Abklingzeit je Feind,
Schwelle "Alarm ab so vielen Toden durch ihn" (zählt Kills plus Beteiligungen), Größe des Alarms, Probealarm.
Blatt Gilde: zwei Gruppen TEILEN (mit der Gilde, mit Freunden, Sichtungen) und WARNEN (Täter aus Gilde und Freunden,
Ziele der Abschussliste); alles Seltene hinter "Mehr" unten rechts (Hand-Einträge teilen, Gildenbuch empfangen,
Freigaben gelten, Warnung bei Hand-Einträgen, Meldungen, Schwelle, Stand, Leeren). Der Zustand von "Mehr" wird gemerkt.
Schnell aus: `/dn still`.

## Aufbau
| Datei | Aufgabe |
|---|---|
| `Locale.lua` | Sprachwahl, Texttabelle `ns.L`, Formatierer mit benannten Platzhaltern, Mehrzahl-Regeln, Schriften je Schriftsystem |
| `Locales/xxXX.lua` | Texte je Sprache (`enUS` Quelle und Rückfall, `deDE` Wortlaut 1.1.0); Höchstlängen in `tests/sprachen/_limits.lua` (nur Tests) |
| `Core.lua` | Namensraum, Ereignis-Bus, Hilfsfunktionen (auch Zeitformat `When`/`Ago`), Secret-Guards, Slash-Befehle, Begrüßung |
| `Store.lua` | SavedVariables `DeathNoteDB` (accountweit), Rollen, Rangliste, offene Fälle, Export/Import als Text |
| `Tracker.lua` | feindliche Spieler in Sicht (Namensplakette, Ziel, Mouseover, Fokus, Gruppenziele) |
| `Attribution.lua` | Tod → Täter: Death Recap, sonst genau ein Zielender in den letzten 6 s (nur Verdacht); Rache |
| `Probe.lua` | Diagnose-Sonde, schreibt nach `DeathNoteDB.probe` |
| `Sync.lua` | Gildenbuch über Addon-Nachrichten im Kanal GUILD, Sendeschlange für beide Kanäle, Abschussliste |
| `Friends.lua` | Freundesbuch: Freundesliste, Vertrauen, Hallo an Freunde, Flüstern (1.2.0) |
| `Alert.lua` | Alarm-Popup mit Anvisieren-Knopf, gemeinsame Gestaltungs-Helfer |
| `UI.lua` | das Buch: Gesucht, Zu klären, Todesjournal, Gilde, Hausordnung, Gebrauchsanweisung |
| `Extras.lua` | Tooltip-Zeile, Meldungen nach Tod, Rache und Gildentod, neue Ziele der Abschussliste |
| `Humor.lua` | trockene Bemerkungen, Meilensteine, versteckte Befehle (nur Deutsch und Englisch) |

## Gilden-Protokoll (Version 1)
1. Präfix `DeathNote`, nur Kanal GUILD, unsichtbare Addon-Nachrichten, kein sichtbarer Chat.
2. Höchstens 255 Bytes je Nachricht, Felder mit Tab getrennt, `%`, `|` und Steuerzeichen als `%XX`.
3. `K` = gerade passierter Kill (Täter, Klasse, Stufe, Zone, Zeit, Opfer-Char).
4. `H` = Hallo 8 bis 20 s nach dem Login mit `since`; `R` = Antwort, nur EIGENE sichere Kills, höchstens 30.
5. `S` = Sichtung eines Gildenfeinds, nur wenn in der Hausordnung eingeschaltet.
6. Niemand gibt Fremddaten weiter. Notizen, Verdachtsfälle, Begnadigungen und Eingelesenes werden nie gesendet.
7. Eine Tat ist eindeutig durch Opfer-Char plus Zeitstempel; Opfer muss zum Absender passen.
8. Deckel: 400 Feinde, 20 Taten je Feind, 40 Feinde je Absender, eine Liste je Gilde (höchstens 5).
9. `M` = Name von Hand auf meine Liste gesetzt (Täter, Klasse, Stufe, Zeit, Char), sofort und in Antworten auf `H`
   (höchstens 20).
10. `X` = wieder gestrichen (Täter, Char); verpasste `X` kommen mit der nächsten Antwort (höchstens 10).
11. Nie gesendet: Verdachtsfälle, Beteiligungen, Begnadigte, Eingelesenes, aus der Gildenliste Übernommenes.
    Der Char in `M` und `X` muss zum Absender passen.
12. Deckel: 20 Hand-Einträge je Absender; sie zählen in die 40 je Absender und die 400 gesamt.
13. Clients mit 1.0.x verwerfen `M` und `X` still.
14. (1.2.0) Dieselben Nachrichten gehen als WHISPER an Freunde (siehe Freundesbuch); 1.1.0 wertet nur GUILD aus.
15. (1.2.0) `J` = zur Jagd freigegeben (Täter, Klasse, Stufe, Zeit, Char, Grund, Buchkennung), sofort und in Antworten (höchstens
    10); `A` = Jagd abgeblasen (Täter, Char), verpasste `A` kommen mit der nächsten Antwort (höchstens 10); `E` = Ziel
    erlegt (Täter, Char, Zeit), nur mit eigenem Todesstoß (`PARTY_KILL`). Der Char muss zum Absender passen (mit
    Nachnamen, wo der Client ihn mitliefert). Deckel: 10 Freigaben je Absender (je Ziel genau eine), 100 Ziele je Liste
    (voll: die älteste fremde fliegt, nie eine eigene). Neue Ziele eines Absenders: in der Minute nach dem EIGENEN Hallo
    höchstens 10 als Antwort, sonst live höchstens 5 in 10 Minuten; der Rest kommt mit der nächsten Antwort, ohne
    Meldung; neue Ziele anderer melden sich immer gesammelt (eine Chatzeile). Freigaben gelten immer (Voreinstellung), 30, 90 oder 180 Tage
    (Hausordnung, Blatt Gilde); verfällt die eigene, geht ein `A` hinaus. `E` zählt jede Tötung (Char, Zeit) einmal, nur
    bis 10 Minuten alt, höchstens 3 je Absender in 10 Minuten, Zähler höchstens 99. 1.1.0 verwirft J, A, E, Z still.
16. (1.2.0) `Z` = Ende einer Antwort (Char, Zahl, Buchkennung): diese Zahl `J` waren ALLE Freigaben des Absenders
    (nur, wenn die Antwort nicht gedeckelt war). Stimmt die Zahl beim Empfänger, gilt die Antwort als Momentaufnahme: was
    der Absender nicht mehr nennt, ist abgeblasen, aber nur Freigaben genau dieses Chars mit derselben Buchkennung und nur
    im Buch des Kanals (Gilde bzw. Freunde). Die Buchkennung ist ein kurzes Zufallswort je SavedVariables
    (`DeathNoteDB.guild.book`, einmal erzeugt); sie steht als optionales letztes Feld in `J` und `Z`. So löscht ein
    zweiter Rechner, eine verlorene Datei oder ein Namensvetter nichts. Freigaben ohne Kennung laufen nur über Abblasen,
    Verfall oder Austritt aus. Solange der eigene Gildenname nach dem Login nicht feststeht, antwortet das Buch nicht.
    Ein `A` auf GUILD nimmt auch die Kopie derselben Freigabe im Freundesbuch zurück. Verlässt ein Freigebender die Gilde (nicht im Roster, 14 Tage nicht auf GUILD zu
    hören) und ist kein Freund, fallen seine Freigaben beim nächsten Roster-Abgleich aus dem Gildenbuch.
17. (1.2.0) Das Hallo an einen Freund (nie an die Gilde) hat ein fünftes Feld: die eigene GUID. Eine Antwort an einen
    Freund beginnt mit diesem Hallo.

## Grenzen des Clients
Kein Combat-Log für Addons, keine Erkennung getarnter Spieler, keine Entfernung oder Richtung. Erkannt wird nur, wer als
Namensplakette, Ziel oder Mouseover sichtbar ist. In Dungeons, Schlachtfeldern und Arenen sind feindliche Namen nicht lesbar,
dort schweigt das Buch. Der Anvisieren-Knopf lässt sich im Kampf nicht umstellen.

## Abgeschaut bei
Vorgehen und API-Aufrufe (kein Code übernommen): Hitlist (Forever), Spy (Forever), Kill on Sight (MIT).
