from __future__ import annotations

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / "src" / "runs" / "CoFChest.au3"


class CoFChestLifecycleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = RUNNER.read_text(encoding="utf-8-sig")

    def function(self, name: str, next_name: str) -> str:
        return self.source.split(f"Func {name}", 1)[1].split(f"Func {next_name}", 1)[0]

    def test_start_and_entry_require_map_postconditions(self) -> None:
        entry = self.function("EnterCoFChestInstance()", "TryEnterCoFChestWithGron")
        self.assertIn("TravelToOutpost($ID_DOOMLORE_SHRINE", entry)
        self.assertIn("ResolveReadyCoFGron", entry)
        self.assertIn("TryEnterCoFChestWithGron", entry)
        enter_attempt = self.function("TryEnterCoFChestWithGron($gron)", "ResolveReadyCoFGron")
        self.assertIn("WaitMapLoading($ID_CATHEDRAL_OF_FLAMES", enter_attempt)

    def test_setup_loads_player_and_exact_seven_hero_party(self) -> None:
        setup = self.function("SetupCoFChestFarm()", "SetupCoFChestSupportTeam")
        self.assertIn("TravelToOutpost($ID_DOOMLORE_SHRINE, $district_name)", setup)
        self.assertIn("SwitchMode($ID_NORMAL_MODE)", setup)
        self.assertIn("CoFLoadRequiredTemplate($COF_CHEST_DERVISH_SKILLBAR, 0, 'player')", setup)
        self.assertIn("SetupCoFChestSupportTeam()", setup)
        self.assertLess(setup.index("CoFLoadRequiredTemplate($COF_CHEST_DERVISH_SKILLBAR"), setup.index("EnterCoFChestInstance()"))
        self.assertNotIn("COF_CHEST_USE_LOADED_SETUP", self.source)

        team = self.function("SetupCoFChestSupportTeam()", "CoFStartSupportBattery")
        self.assertIn("LeaveParty()", team)
        for hero in ("$ID_MELONNI", "$ID_MOX", "$ID_KAHMU", "$ID_PYRE_FIERCESHOT", "$ID_OLIAS", "$ID_LIVIA", "$ID_OGDEN"):
            self.assertIn(hero, team)
        self.assertEqual(team.count("If Not CoFLoadRequiredTemplate("), 6)
        self.assertIn("SetupCoFChestMonkBar($COF_CHEST_HERO_OGDEN)", team)

        loader = self.function("CoFLoadRequiredTemplate($template", "CoFStartSupportBattery")
        self.assertIn("LoadSkillTemplateIfNeeded($template, $heroIndex)", loader)
        self.assertIn("HeroHasTemplate($template, $heroIndex)", loader)
        self.assertIn("For $attempt = 1 To 3", loader)

        ogden = self.function("SetupCoFChestMonkBar($heroIndex", "CoFChestFarmLoop")
        self.assertIn("GetHeroProfession($heroIndex, True) <> $ID_PARAGON", ogden)
        self.assertIn("GetSkillbarSkillID($slot, $heroIndex)", ogden)

    def test_per_run_state_is_reset_after_entry(self) -> None:
        farm = self.function("CoFChestFarm()", "CoFStartInstanceWatchdog")
        entry = farm.index("EnterCoFChestInstance()")
        self.assertGreater(farm.index("$cof_chest_loot_blocked = False"), entry)
        self.assertGreater(farm.index("$cof_chest_secured_loot_count = 0"), entry)
        self.assertGreater(farm.index("CoFStartInstanceWatchdog()"), entry)

    def test_chest_open_has_observable_confirmation(self) -> None:
        chest = self.function("CoFOpenChestAgent($chest, $stage)", "CoFSnapshotGroundItemIDs")
        self.assertIn("GetTreasureTitle() > $treasureBefore", chest)
        self.assertIn("GetInventoryItemCount($ID_LOCKPICK) < $lockpicksBefore", chest)
        self.assertIn("If Not $opened Then", chest)

    def test_side_chest_ordering_and_exact_desirable_drop_verification(self) -> None:
        chest = self.function("CoFOpenChestAgent($chest, $stage)", "CoFSnapshotGroundItemIDs")
        ordered = (
            "CoFSnapshotGroundItemIDs()",
            "OpenChest()",
            "CoFWaitForNewChestDrop",
            "CoFHandleExactChestDrop",
            "$stage & '-opened'",
        )
        positions = [chest.index(token) for token in ordered]
        self.assertEqual(positions, sorted(positions))

        pickup = self.function("CoFHandleExactChestDrop($dropAgent, $stage)", "CoFChestSurvivalForChest")
        self.assertIn("DefaultShouldPickItem($item)", pickup)
        self.assertIn("If Not GetAgentExists($agentID) Then", pickup)
        self.assertIn("$cof_chest_loot_blocked = True", pickup)
        self.assertLess(pickup.index("DefaultShouldPickItem($item)"), pickup.index("PickUpItem($item)"))
        self.assertLess(pickup.index("PickUpItem($item)"), pickup.rindex("If Not GetAgentExists($agentID) Then"))

    def test_route_failures_do_not_silently_advance(self) -> None:
        loop = self.function("CoFChestFarmLoop()", "CoFPrepareChestRun")
        self.assertIn("If CoFChestMove(-17000, -8750, 'opening-run') == $FAIL Then Return $FAIL", loop)
        self.assertIn("If $cof_chest_loot_blocked Or $cof_chest_watchdog_expired Then Return $FAIL", loop)
        self.assertIn("If Not $openedZoneOne And Not $openedZoneTwo Then", loop)

    def test_normal_return_occurs_after_route_and_loot_transaction(self) -> None:
        farm = self.function("CoFChestFarm()", "CoFStartInstanceWatchdog")
        self.assertLess(farm.index("CoFChestFarmLoop()"), farm.index("ResignAndReturnToOutpost"))
        self.assertLess(farm.index("CountOpenedChests()"), farm.index("ResignAndReturnToOutpost"))
        self.assertIn("Not $cof_chest_loot_blocked", farm)

    def test_normal_return_stops_async_controllers_first(self) -> None:
        farm = self.function("CoFChestFarm()", "CoFStartInstanceWatchdog")
        resign = farm.index("ResignAndReturnToOutpost")
        self.assertLess(farm.index("CoFStopInstanceWatchdog()"), resign)
        self.assertLess(farm.index("CoFStopSupportBattery()"), resign)

    def test_watchdog_is_bounded_and_marks_failure_before_resign(self) -> None:
        watchdog = self.function("CoFChestInstanceWatchdog()", "SetupCoFChestFarm")
        self.assertIn("$COF_CHEST_INSTANCE_WATCHDOG_MS", watchdog)
        self.assertLess(watchdog.index("$cof_chest_watchdog_expired = True"), watchdog.index("Resign()"))

    def test_all_direct_exits_are_accounted_for(self) -> None:
        self.assertEqual(self.source.count("TravelToOutpost("), 2)
        self.assertEqual(self.source.count("ResignAndReturnToOutpost("), 1)
        self.assertEqual(self.source.count("Resign()"), 1)
        for forbidden_exit in ("Map.Travel", "XYAndExitMap", "\tReturnToOutpost("):
            self.assertNotIn(forbidden_exit, self.source)

    def test_success_requires_productive_run_and_resolved_loot(self) -> None:
        farm = self.function("CoFChestFarm()", "CoFStartInstanceWatchdog")
        self.assertIn("$openedChests > 0", farm)
        self.assertIn("Not $cof_chest_loot_blocked", farm)
        self.assertIn("Not $cof_chest_watchdog_expired", farm)

    def test_non_applicable_full_dungeon_mechanics_are_absent(self) -> None:
        for token in (
            "Murakai",
            "Beacon of Droknar",
            "Dungeon Key",
            "Boss Key",
            "XYAndExitMap",
            "COF:FINAL_CHEST",
        ):
            self.assertNotIn(token, self.source)


if __name__ == "__main__":
    unittest.main()
