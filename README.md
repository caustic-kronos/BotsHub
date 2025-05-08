# [BotsHub]
A bot for GuildWars, written in AutoIt.
It needs AutoIt version 3.3.16.0 or higher to run.

> ⚠️ This bot operates autonomously and can perform actions such as selling or modifying items without direct user intervention. ​Please ensure that any valuable or important items are securely stored or protected before activating the bot. The developers are not responsible for any unintended consequences resulting from the bot's actions.

> ⚠️ Disclaimer: This project is not affiliated with or endorsed by ArenaNet - GuildWars. Use at your own risk.

## Features
- Shared interface for all bots
- Centralized farm tracking
- Title tracking system
- Run & Loot automation
- Customizable consumable usage
- Detailed farm info (builds, equipment, etc.)
- Easy plug-and-play support for new bots
- Automatic loot data storage: tracks looted items and their details (IDs, prices, modstruct, etc.) in a SQLite database

## Repository Structure
- `BotsHub.au3`: Main launcher script that acts as a hub for all bots.
- `/lib/`: Common shared utility files and GWA2 interfacing logic.
- `/src/`: Plug-and-play bots. Each one is modular and can be independently added or removed.
- `CREDITS.md`: Acknowledgments and attributions for external code.
- `LICENSE`: Apache 2.0 License for original work.
- `README.md`: This file.

## Usage
To use it:
1. Install AutoIt.
2. Run `BotsHub.au3` with AutoIt.
3. (Optional) To make the data collection functional, AutoIT needs the SQLite library:
	1. You can find the lib folder the files SQLite.au3 and SQLite.dll.au3
	2. Copy those files to your Program Files/AutoIt3/Include folder.

## Adding Your Own Bots
To add a new bot, drop your script into the `/src/` folder and follow these steps:
1. Name the script like `Farm-<Name>.au3`.
2. Add an include line in `BotsHub.au3`:
	```autoit
	#include 'src/Farm-<Name>.au3'
	```
3. Add the farm to the `$AVAILABLE_FARMS` list with its name <Name> (use | as a separator).
4. Add two lines in BotsHub - RunFarmLoop :
	```autoit
	Case '<Name>'
		Return <Name>Farm($STATUS)
	```
And that's it !

## FAQ
Before submitting any bug report or asking questions, make sure you have the most recent version of AutoIt and the most recent version of the bot.

<details> <summary><strong>Q: The bot is stuck, it doesn't continue the farm nor return to the city. What should I do?</strong></summary>
There are several possible causes for this issue. To help diagnose it, please provide as much information as possible:
- Which bot are you using?
- When did it stop? (During the farm itself, while managing inventory, etc.)
- What were the last logs shown in the bot’s console?
- Did it happen more than once?
</details>

<details> <summary><strong>Q: How can I change what items the bot sells?</strong></summary>
Some loot options are directly configurable through the interface.
For more advanced customization, you will need to edit the files manually:
- For mods : in GWA2-Items_Modstructs.au3, at the end of the file, there is a function: Func CreateValuableModsByTypeMap(). Adding mods to the lists inside this function will make the bot keep items with those mods.
- For weapons : in Utils-Storage-Bot.au3, near the end of the file, you will find an array called Local Static $shouldKeepWeaponsArray. Adding item ModelIDs to this array will tell the bot not to sell those items.
Note: A more practical looting configuration system is planned for a future update.
</details>

<details> <summary><strong>Q: Why is the bot not adding heroes or setting their skill bars for farm 'XXX'?</strong></summary>
Not all farms automatically load heroes and their builds.
When builds vary a lot, it is up to the player to add the necessary heroes and set their skill bars manually.
</details>

<details> <summary><strong>Q: The bot fails with 'Variable subscript badly formatted' on `Local $map[]`. What’s wrong?</strong></summary>
This bot uses maps, a feature introduced in AutoIt v3.3.16.0.
Please check your AutoIt version and update it if necessary.
</details>

<details> <summary><strong>Q: The bot fails with 'not accessible variable' on `Local $maxDamage = $weaponMaxDamages[$requirement]` in /lib/Utils.au3. How to solve that?</strong></summary>
Reinstalling AutoIt solves this issue.
</details>

<details> <summary><strong>Q: The bot sold my super expensive item! What can I do?</strong></summary>
Unfortunately, we cannot recover lost items.
Please ensure that any valuable or important items are safely stored or protected before activating the bot.

The developers are not responsible for any unintended consequences resulting from the bot’s actions.
</details>

<details> <summary><strong>Q: Why isn't the data tracking option working? I get a 'Failed to load sqlite' error.</strong></summary>
You need the SQLite AutoIt library installed:

Copy SQLite.au3 and SQLite.dll.au3 into your AutoIt3\Include\ folder.
</details>

<details> <summary><strong>Q: Do you have a 'YYY' bot?</strong></summary>
No — if a bot isn’t included, I don’t have it.
Feel free to create and add more bots; it’s pretty simple!
</details>

## Dependencies
- [AutoIt JSON UDF](https://github.com/Sylvan86/autoit-json-udf) – For JSON parsing - WTFPL license.
- [SQLite UDF](https://www.autoitscript.com/autoit3/pkgmgr/sqlite/) – For database operations.

## License
This project is licensed under the Apache License 2.0 – see the [LICENSE](LICENSE) file.

## Author
Made by caustic-kronos
Also known as: Kronos, Night, Svarog

Feel free to reach out or contribute!