# [BotsHub]
BotsHub is an **AutoIt-based automation hub for Guild Wars**, written in AutoIt 😎

It provides a **single framework and interface** to run multiple bot scripts, with shared systems, consistent behavior, and easy extensibility.

> ⚠️ This bot operates autonomously (selling, salvaging, storing items, etc.).  
> Make sure valuable items are safely stored before running it.  
> The authors are not responsible for lost items or unintended behavior.

> ⚠️ Disclaimer: This project is not affiliated with or endorsed by ArenaNet - Guild Wars.

---

## Usage
To use it:
1. Install **AutoIt (≥ 3.3.16.0)** 🛠️  
2. Clone or download the repository (`<> Code → Download ZIP`) 📥
3. Extract the archive if needed
4. Run `BotsHub.au3` **using AutoIt** ▶️
5. Select a bot and press **Start** ✅

⚠️ Do **not** run individual bot files from `/src/`.  
⚠️ Make sure the Guild Wars client is running and logged in.

---

## Features
- Unified interface shared by all bots 🖥️
- Shared inventory, loot, farm, and title tracking 🎯
- Configurable item handling (pickup, identify, salvage, sell, buy, store) 📦
- Farm UI with build, equipment, and contextual information 🛡️
- Modular, plug-and-play bot system 🔌

---

## Existing Bots

### Farms

| Farm                                | Purpose / Drops                                         |
| ----------------------------------- | ------------------------------------------------------- |
| Raptors                             | Festive items, golds, materials, Asura points           |
| Vaettirs                            | Festive items, golds, materials, Norn points            |
| Cathedral of Flames (Cryptos)       | Rin Relics, Diessa Chalices, bones                      |
| Jaya Bluffs (Sensali)               | Feathers, bones                                         |
| Drazach Thicket (DragonMoss)        | Fibers, Gothic Defender, Echovald Shield, Ornate Shield |
| Wajjun Bazaar (Mantids)             | Celestial weapons, chitin, dust                         |
| Moddok Crevice (Corsairs)           | Runes, Colossal Scimitar, Q8                            |
| Missing Daughter (Jade Brotherhood) | Q8 items, jade bracelets                                |
| Fish in a Barrel (Kournans)         | Q8 items, runes                                         |
| Spirit Slaves                       | Q8 items, dust, bones                                   |
| Minotaurs                           | Materials                                               |
| Auspicious Beginnings               | War Supplies, festive items, gold, Vanguard points      |
| A Chance Encounter                  | Ministerial Commendations, faction skins                |
| Presearing Iris                     | Iris                                                    |
| Nexus Challenge                     | Mysterious armor hero pieces                            |
| Dajkah Inlet Challenge              | Sunspear armor hero pieces                              |
| Glint’s Challenge                   | Cloth of Brotherhood, hero armor, Destroyer cores       |

### Vanquishes / Titles

| Area                       | Title / Points                       |
| -------------------------- | ------------------------------------ |
| Ferndale                   | Kurzick                              |
| Mount Qinkai               | Luxon                                |
| Sulfurous Wastes           | Sunspear, Lightbringer               |
| Mirror of Lyss             | Lightbringer                         |
| Magus Stones               | Asura                                |
| Varajar Fells              | Norn                                 |
| Dalada Uplands             | Vanguard                             |
| Secret Lair of the Snowmen | Deldrimor                            |
| Pre-Searing                | Legendary Defender of Ascalon (LDOA) |

### Dungeons / Elite Zones

| Area                          | Drops                                          |
| ----------------------------- | ---------------------------------------------- |
| Bogroot                       | Froggy                                         |
| Sepulchre of Dragrimmar (SoO) | Dragon Bone Staff                              |
| Slaver’s Exile                | Voltaic Spears                                 |
| FoW                           | Obsidian Shards, Obsidian Edge, Shadow weapons |
| FoW – Tower of Courage        | Obsidian Shards, dust                          |
| Domain of Anguish             | Gemstones                                      |
| City of Torc'qua              | Margonite Gemstones                            |
| Ravenheart Gloom              | Torment Gemstones                              |
| Stygian Veil                  | Stygian Gemstones                              |
| Underworld                    | Globs of Ectoplasm                             |

### Chest Runs

| Area    | Possible Drops                                           |
| ------- | -------------------------------------------------------- |
| Boreal  | Glacial Blades                                           |
| Pongmei | Faction skins, Q8                                        |
| Tasca   | Magma Shield, Stone Summit Shield, Summit Warlord Shield |

### Others
- Follower bot
- Inventory management

---

## Repository Structure
- `BotsHub.au3`: Main launcher script that acts as a hub for all bots.
- `/lib/`: Common shared utility files and GWA2 interfacing logic.
- `/src/`: Plug-and-play bots. Each one is modular and can be independently added or removed.
- `CREDITS.md`, `LICENSE`, `README.md`

---

## Adding Your Own Bots
1. Add `<Name of your bot>.au3` to `src/<folder>/` 📂
2. Add an include line in `BotsHub.au3`:
	```autoit
	#include 'src/<folder>/<Name>.au3'
	```
3. Add the farm to the `$AVAILABLE_FARMS` list with its name <Name> (use | as a separator) ✏️
4. Add a line in `FillFarmMap` with your farm function, inventory space, and duration:
	```autoit
	AddFarmToFarmMap('Asuran', AsuranTitleFarm, 5, $ASURAN_FARM_DURATION)
	```
And that’s it! 🎉 No duplicated logic required.

---

## FAQ
Before reporting bugs, make sure you are using the latest version of AutoIt and BotsHub ⚡

<details>
<summary><strong>Q: The bot is stuck and does not continue or return to town.</strong></summary>

Too many possible causes. Please provide:
- Bot name
- When it stopped (during farm, inventory, travel, etc.)
- Last console logs
- Whether it happens consistently
</details>

<details>
<summary><strong>Q: How can I change what items the bot sells?</strong></summary>

Most options are configurable in the interface.  
Advanced customization requires manual file edits ✏️
</details>

<details>
<summary><strong>Q: Heroes are not added or skill bars are not set.</strong></summary>

Not all farms auto-configure heroes.  
Some require manual setup in the **Team** tab or in-game 🛡️
</details>

<details>
<summary><strong>Q: Error: 'Variable subscript badly formatted' (`Local $map[]`).</strong></summary>

Your AutoIt version is too old.  
Update to **AutoIt ≥ 3.3.16.0** 🆙
</details>

<details>
<summary><strong>Q: Error: 'not accessible variable' in `/lib/Utils.au3`.</strong></summary>

Reinstall AutoIt 🔄
</details>

<details>
<summary><strong>Q: The bot sold an expensive item. Can it be recovered?</strong></summary>

No. Items cannot be recovered.  
Always store valuable items before running the bot 💎
</details>

<details>
<summary><strong>Q: Data tracking does not work ('Failed to load sqlite').</strong></summary>

SQLite must be installed and accessible by AutoIt.  
DLL and UDF files are included in the repository
</details>

<details>
<summary><strong>Q: Do you have a 'YYY' bot?</strong></summary>

If it is not listed, it does not exist ❌  
PvP bots will not be added  
You are welcome to create and contribute new bots 👍
</details>

---

## 📌 Planned Features

- 💡🛠️ **Fix Spirit Slaves farm**
- 💡🕓 **Improve the Pongmei chest farm with Tasca chest farm capabilities**
- 🔄💭 **Kilroy bot/Irontoe's lair (q8, survivor title)** - 1 request
- 🧠💭 **Other consumables farms (Drake Kabob, Skalefin Soup and Pahnai Salad)** - 1 request
- 🧠💭 **Nicholas the traveler items (gifties)**
- 🧠💭 **Bandit raid**
- 🧠💭 **Improve crash recovery**

**Legend:**  
Priority → 🔥 High | ⚡ Medium | 💡 Low | 🧠 None  
Status → ✅ Done | 🔄 In progress | 🛠️ Broken | 🕓 Planned | 💭 Wishlist

---

## Dependencies
- [AutoIt JSON UDF](https://github.com/Sylvan86/autoit-json-udf) 📝
- [SQLite UDF](https://www.autoitscript.com/autoit3/pkgmgr/sqlite/) 💾

---

## License
Apache License 2.0 ⚖️ — see the [LICENSE](LICENSE) file

---

## Author

Made by caustic-kronos 😎  
Also known as: Kronos, Night, Svarog

Feel free to reach out or contribute! 💬