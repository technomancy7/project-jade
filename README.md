# Project Jade
The project itself is a modular development framework built around Love2D, providing many useful tools to make game development easier, and functioning as a loader to let developers re-use the same engine by splitting logic in to story files. By splitting up the logic, it's easy to create lua scripts, assets, any anything else, that you can drop in to the environment and let the story file decide what's needed.
Some of the tools included include multiple combat and field systems, flexible GUI systems, auto-loading and indexing of assets, a music manager, moddable console command system, map editor, and more.

## Abyssal Odyssey
A work-in-progress roguelike space adventure themed after the old British TV show, Red Dwarf, with some FTL elements.
The official game built with Jade Framework, designed to be a highly moddable roguelike adventure, with unique mechanics, and interesting mysteries.

## Running
Requires Love2d runtime.

## Modding
Modding is supported right from the core.

This is an example mod file, it can be dropped in to the source directory /scripts/ folder, or the save directory /mods/ folder. The modding framework is the same way I'll be writing the core eventing systems, so anything I can do in the base, mods can also do, and since it's pure Lua all the way down, mods can do pretty much anything they want, giving full flexibility.

The file in `scripts/combat.lua` shows an example scripts, the same exact format can be used in the mods directory, and the engine will automatically load any lua files in either.
