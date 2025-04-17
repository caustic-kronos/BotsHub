# [BotsHub]
A bot for GuildWars, written in AutoIt.

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

## Usage
> ⚠️ This bot is experimental and provided for educational purposes only.

To use it:
1. Install AutoIt.
2. Run `BotsHub.au3` with AutoIt.

> (Optional) To make the data collection functional, AutoIT needs the SQLite library:
1. You can find the lib folder the files SQLite.au3 and SQLite.dll.au3
2. Copy those files to your Program Files/AutoIt3/Include folder.

## License
This project is licensed under the Apache License 2.0 – see the [LICENSE](LICENSE) file.

## Author
Made by caustic-kronos
Also known as: Kronos, Night, Svarog

Feel free to reach out or contribute!