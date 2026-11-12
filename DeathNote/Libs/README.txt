Embedded libraries (unmodified release files, loaded by DeathNote.toc before Core.lua)

LibStub              minor 2    Public Domain (see the header of LibStub.lua)
CallbackHandler-1.0  minor 8    Ace3 style BSD license, CallbackHandler-1.0/LICENSE.txt
LibDataBroker-1.1    minor 4    by tekkub, https://github.com/tekkub/libdatabroker-1-1 (no license file upstream)
LibDBIcon-1.0        minor 57   Ace3 style BSD license, LibDBIcon-1.0/LICENSE.txt

The same files run on WoW Forever inside other addons (DBM-Core, BugSack, WhatsTraining).
LibStub loads every library only once per client: the newest minor of all installed addons wins.
Without these files DeathNote falls back to its own minimap button.
