# [FAQ]

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

<details> <summary><strong>Q: The bot sold my super expensive item! What can I do?</strong></summary>
Unfortunately, we cannot recover lost items.
Please ensure that any valuable or important items are safely stored or protected before activating the bot.

The developers are not responsible for any unintended consequences resulting from the bot’s actions.
</details>

<details> <summary><strong>Q: Why isn't the data tracking option working? I get a "Failed to load sqlite" error.</strong></summary>
You need the SQLite AutoIt library installed:

Copy SQLite.au3 and SQLite.dll.au3 into your AutoIt3\Include\ folder.
</details>

<details> <summary><strong>Q: Do you have a 'YYY' bot?</strong></summary>
No — if a bot isn’t included, I don’t have it.
Feel free to create and add more bots; it’s pretty simple!
</details>