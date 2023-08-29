# spiffing
A work-in-progress roguelike space adventure themed after the old British TV show, Red Dwarf, with some FTL elements.

## Running
Requires Love2d runtime.

## Modding
Modding is supported right from the core.

This is an example mod file, it can be dropped in to the source directory /scripts/ folder, or the save directory /mods/ folder. The modding framework is the same way I'll be writing the core eventing systems, so anything I can do in the base, mods can also do, and since it's pure Lua all the way down, mods can do pretty much anything they want, giving full flexibility.

The file in `scripts/combat.lua` shows an example scripts, the same exact format can be used in the mods directory, and the engine will automatically load any lua files in either.
