# CoF NM Chestrun

This BotsHub run is derived from eleven manual PY4GW recordings named `CoF NM 1` through `CoF NM 10` (`CoF NM 6` was recorded twice). It runs only Cathedral of Flames level one in Normal Mode.

The route and original player bars are based on the community walkthrough [Fastest Chest Run - Cathedral of Flames (COF) - 100+/hr - NM or HM](https://guildwarslegacy.com/forum/thread/17932-fastest-chest-run-cathedral-of-flames-cof-100-hr-nm-or-hm/). The BotsHub implementation is deliberately presented as a slower, unattended NM route; the source player's human 100+/hour result is not claimed for this bot.

## Runtime design

- Runtime agent IDs are used only during the current loaded instance. They are never hard-coded or reused on the next run.
- Each shadow-step target is reacquired from living foes using the current route phase, expected coordinates, model family, allegiance, and distance. The opening approach continuously scans for the recorded Axemaster model `6681`; a nearby substitute is never accepted.
- If the opening Axemaster is already fighting, damaged, or surrounded closely by undead, its teleport is skipped and the runner continues on foot to avoid Ray of Judgment and the clustered fight.
- Viper's Defense and Heart of Shadow use the same live foe selected for the immediately preceding shadow step.
- Jaunts are aligned so the target is behind the desired travel direction. Each command uses the shared one-shot confirmed cast helper, requires real coordinate displacement, and waits for a ping-adjusted position settle before selecting another target.
- The opening Axemaster sequence attempts two confirmed jaunts. The second target is selected only after the first displacement and ping-adjusted position settle, avoiding stale pre-jaunt geometry.
- The hallway-entry Axemaster may provide one proactive jaunt only when its current live position is already safely behind the route direction. The runner never walks around a wall-side target merely to manufacture that angle.
- Phase-bounded opportunistic shadowsteps may use a clearly forward foe after the hallway or during the long second-chest approach. Crypt Slasher model `7077` is strongly deprioritized because it carries Crippling Slash, but remains a legal last-resort target when no better foe is available.
- Destruction/Bloodsong spirit models `4266` and `4278` are excluded from onto-target shadowsteps after a live rejected cast. They remain eligible for Viper's Defense and Heart of Shadow because live displacement logs prove those away-from-target jaunts work.
- Directional jaunts use a preferred behind-left target and then either rear side as a boxed-in fallback. If no jump is available, alternating wide backward-diagonal steps recover bodyblocks during route and chest approaches.
- A detected zone-one chest is approached directly whenever it is within earshot, including after an intermediate branch waypoint passes beside it.
- The party reuses Tasca's positional support package: Melonni, M.O.X., Kahmu, Pyre Fierceshot, Olias, and Livia occupy slots 1–6; Ogden replaces Tasca's seventh Paragon/Dervish.
- After all seven post-zone hero agents are live, support heroes 1–6 are flagged at the player's settled Cathedral entrance position. Ogden initially remains unflagged so he can cast the opening protection; after Spell Breaker is observed, `CommandAll` sends the complete party back to that entrance point. Their two BiPs and local Quickening Zephyr power two alternating groups of unlimited-range Mystic Healing casts every 1.6 seconds while the player is injured.
- After zoning, the runner waits up to eight seconds for all seven hero agents and their alive state to materialize before starting support preparation; transient party-memory loading no longer causes immediate failed loops.
- Cautery Signet rotates across the three stationary Dervishes when the player has a condition, providing unlimited-range removal for Cripple and other conditions.
- Ogden initially remains unflagged so he can apply Blessed Aura, Fall Back, Brace Yourself, and Spell Breaker. The player now advances close to the opening checkpoint before Spell Breaker is requested, preserving more of its duration for the dangerous undead beyond the hallway. Once Spell Breaker is observed on the moving player, Ogden is sent back to the entrance flag.
- Gron's Temple of the Damned dialogue uses bounded retries and requires the Cathedral map load before the route can advance.
- Blessed Aura is verified on the hero before Spell Breaker is cast on the player.
- Pious Haste is cast before movement begins, then the hero applies Spell Breaker to the moving player with no later player cast to cancel that movement. Starting before Blessed Aura was tested and reverted because it could move the player out of reliable Spell Breaker range.
- Fall Back and Brace Yourself are cast before the first shadow step. Dwarven Stability and Zealous Renewal are applied before Pious Haste.
- The long validation session manually displayed the Ebon Vanguard title for its Charr armor benefit. This runner does not change or verify the displayed title.
- Speed refreshes preserve the Zealous Renewal then Pious Haste order and refresh Dwarven Stability only when needed.
- Later Dwarven Stability refreshes are deferred until the Zealous Renewal and Pious Haste pair also needs refreshing.
- Chest selection uses exact gadget ID `8141` within bounded recorded spawn regions. The bot walks to the selected chest before interacting.
- Chest opening uses the native BotsHub command with exact live-chest retargeting, bounded retries, and Treasure Hunter/lockpick confirmation. It attempts reached chests at any positive health and does not require Toolbox prompt automation.
- Benchmark success means at least one chest was opened; player death remains recorded independently.

## Recorded route regions

The first target region is centered near `(-15600, -6800)`, the second near `(-13000, -2700)`, and the hallway-end fight near `(-11600, -700)`. When no hallway chest is immediately visible, the runner follows the expert player's outside curve using proven walkable Cathedral capture points from approximately `(-12273,-1410)` through `(-11163,699)`. Points already passed by a shadowstep or jaunt are skipped, and the curve stops as soon as a chest becomes visible.

The first chest region spans approximately `X -12500..-7500`, `Y -1500..3000`. Recorded opened chest positions ranged from about `(-11947, -834)` to `(-7828, 2449)`.

The second chest region spans approximately `X -11000..-5000`, `Y 2800..6500`. The recordings showed a northern/upper-left branch around `(-8900, 5800)` and an upper-east branch around `(-5800, 3300)`. Those are mutually exclusive positions within the same region: after either chest is opened, the route completes and never searches the opposite side. A visible eastern chest is selected first. If it is absent, the runner continues north through approximately `(-9000,3800)` and `(-10200,4550)` before turning west to the first proven point of the dedicated `CoF Chest Run Left Wall` capture at `(-11188,4829)`. This replaces the former 2,700-unit east-to-west reversal through the post-hall enemy pack. The recorded left-wall path then continues through approximately `(-10332,5363)` and `(-9494,5924)`, checking reachability after every point.

Route diagnostic CSVs include `elapsed_ms` and `spell_breaker_ms` columns. Spell Breaker remaining time is a local countdown started when the effect is confirmed; it does not use GWA2's incompatible effect timestamp clock. `HERO_STATE` rows record the live hero ID, party index, coordinates, and distance from the entrance flag. Chest discovery rows distinguish `lower-east`, `hallway-west`, `hallway-middle`, `upper-east`, and `upper-left` so movement between the two independent regions is not mistaken for checking the opposite spawn after a chest was already opened.

## Required setup

`COF_CHEST_USE_LOADED_SETUP` is enabled because this is the exact mode used for the reported validation. The runner preserves the currently loaded player bar, eight-character party, attributes, and all seven hero bars. It still primes the Doomlore return point at startup and repeats that priming after BotsHub inventory-management travel resets farm setup. Priming occurs before the measured run and before the 96-second Cathedral instance deadline.

1. Select `CoF Chestrun` as the farm, select the desired loot profile, and save a run configuration if it will be reused.
2. Confirm the selected character is a primary Dervish with the player template `Ogej4NfMLTjbHY3lsZ4OBMIQUQA`, lockpicks, and the prepared eight-character party: Melonni, M.O.X., Kahmu, Pyre Fierceshot, Olias, Livia, and Ogden.
3. Use the three Tasca support templates declared at the top of `CoFChest.au3` for hero slots 1–6. Ogden is Monk/Paragon with Blessed Aura, Spell Breaker, "Fall Back!", and "Brace Yourself!" in slots 1–4.
4. Select Normal Mode. The runner forces NM at setup, but the supplied route has not been validated in HM.
5. Run one attended cycle before enabling loop mode. Keep rendering enabled during initial validation.
6. Inspect `logs\benchmarks\cof-route-latest.csv`, the timestamped per-run route CSV, and `logs\benchmarks\cof-nm-latest.txt`.

## NM validation results

The longest completed unattended NM session used the exact loaded-setup path in this contribution:

- 374 completed attempts over 8h 23m 40s wall time
- 354 benchmark successes and 20 failures (94.7% success rate)
- 515 opened chests, or 61.35 chests/hour including all zoning and loop overhead
- 77 seconds average active cycle and 1.377 chests per attempted run
- 189 net lockpicks consumed; +155,500 Lucky, +58,320 Unlucky, and +491 Treasure Hunter progress
- the final 25 recorded attempts all completed successfully

Here, benchmark success means at least one chest was opened and no exact desirable chest drop remained unresolved. A death after productive chest/loot handling is recorded separately and does not automatically turn the attempt into a failure.

The validation character used a +5 Energy / 20% longer-enchantment one-handed weapon and a shield with +9 armor versus lightning and +45 Health while enchanted. The Ebon Vanguard title was selected manually. Those equipment choices are test conditions, not enforced by code.

## Hard Mode status

Hard Mode is not implemented or exposed by this contribution. The source route proposes player template `Ogej4NfMLTjbHY3lUQ4OBM0k6MA`, using "I Am Unstoppable!" during the tunnel sequence and Shadow Form after Spell Breaker expires. Although the geography should be similar, hero timing, the reduced jump count, Shadow Form sequencing, target selection, damage pressure, and loot handling all require separate in-game validation. Do not interpret the NM results above as HM support.

## Known limitations

- Static checks cannot prove walkability of every checkpoint or exact skill timing under latency.
- Hero flagging is timing-sensitive. Verify in an attended run that all six support heroes remain at the entrance and Ogden returns after Spell Breaker.
- Enemy patrol motion may require widening or moving a phase anchor after the first live attempt.
- A run can legitimately open one chest when the other route region has no usable chest.
- The shared BotsHub inventory and merchant system runs between cycles according to the selected loot configuration; it is not reimplemented here.
- After a merchant/storage trip, the next cycle may perform one unmeasured enter-and-exit priming trip before starting the real run. Ordinary cycles already beside Gron skip it.
- BotsHub does not automatically reconnect after a Guild Wars disconnect.
- Monitor-off and disabled-rendering reliability were not established; the reported eight-hour session kept rendering enabled.
