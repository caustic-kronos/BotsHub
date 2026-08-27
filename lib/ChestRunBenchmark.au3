#include-once
#include <FileConstants.au3>

Global Const $CHEST_BENCHMARK_CSV_PATH = @ScriptDir & '\logs\benchmarks\chest-runs.csv'
Global Const $CHEST_BENCHMARK_SESSION_GAP = 10 * 60 * 1000

Global $chest_benchmark_route = ''
Global $chest_benchmark_session_id = ''
Global $chest_benchmark_mode = ''
Global $chest_benchmark_session_timer = Null
Global $chest_benchmark_run_timer = Null
Global $chest_benchmark_last_finish_timer = Null
Global $chest_benchmark_run = 0
Global $chest_benchmark_successes = 0
Global $chest_benchmark_failures = 0
Global $chest_benchmark_pauses = 0
Global $chest_benchmark_chests = 0
Global $chest_benchmark_elapsed_seconds = 0
Global $chest_benchmark_net_lockpicks_used = 0
Global $chest_benchmark_lockpicks_before = 0
Global $chest_benchmark_lucky_before = 0
Global $chest_benchmark_unlucky_before = 0
Global $chest_benchmark_treasure_before = 0
Global $chest_benchmark_initial_lucky = 0
Global $chest_benchmark_initial_unlucky = 0
Global $chest_benchmark_initial_treasure = 0
Global $chest_benchmark_lucky_gained = 0
Global $chest_benchmark_unlucky_gained = 0
Global $chest_benchmark_treasure_gained = 0


;~ Start timing a chest run and leave a readable marker if it stalls
Func StartChestRunBenchmark($route)
	Local $currentMode = GetIsHardMode() ? 'HM' : 'NM'
	Local $sessionExpired = False
	If $chest_benchmark_last_finish_timer <> Null Then $sessionExpired = TimerDiff($chest_benchmark_last_finish_timer) > $CHEST_BENCHMARK_SESSION_GAP
	If $chest_benchmark_session_id == '' Or $chest_benchmark_route <> $route Or $chest_benchmark_mode <> $currentMode Or $sessionExpired Then InitializeChestRunBenchmarkSession($route, $currentMode)

	$chest_benchmark_run += 1
	$chest_benchmark_lockpicks_before = GetInventoryItemCount($ID_LOCKPICK)
	$chest_benchmark_lucky_before = GetLuckyTitle()
	$chest_benchmark_unlucky_before = GetUnluckyTitle()
	$chest_benchmark_treasure_before = GetTreasureTitle()
	ClearChestsMap()
	$chest_benchmark_run_timer = TimerInit()
	WriteChestRunBenchmarkSummary('RUNNING', '', 0, 0, False)
EndFunc


;~ Record one completed chest run and refresh the route summary
Func FinishChestRunBenchmark($result, $openedChests, $playerDied)
	Local $elapsedSeconds = Round(TimerDiff($chest_benchmark_run_timer) / 1000, 2)
	Local $lockpicksAfter = GetInventoryItemCount($ID_LOCKPICK)
	Local $luckyAfter = GetLuckyTitle()
	Local $unluckyAfter = GetUnluckyTitle()
	Local $treasureAfter = GetTreasureTitle()
	Local $netLockpicksUsed = $chest_benchmark_lockpicks_before - $lockpicksAfter
	Local $luckyGained = GetSafeChestRunTitleDelta($chest_benchmark_lucky_before, $luckyAfter)
	Local $unluckyGained = GetSafeChestRunTitleDelta($chest_benchmark_unlucky_before, $unluckyAfter)
	Local $treasureGained = GetSafeChestRunTitleDelta($chest_benchmark_treasure_before, $treasureAfter)
	Local $resultName = GetChestRunBenchmarkResultName($result)

	$chest_benchmark_chests += $openedChests
	$chest_benchmark_elapsed_seconds += $elapsedSeconds
	$chest_benchmark_net_lockpicks_used += $netLockpicksUsed
	$chest_benchmark_lucky_gained += $luckyGained
	$chest_benchmark_unlucky_gained += $unluckyGained
	$chest_benchmark_treasure_gained += $treasureGained
	Switch $result
		Case $SUCCESS
			$chest_benchmark_successes += 1
		Case $FAIL
			$chest_benchmark_failures += 1
		Case $PAUSE
			$chest_benchmark_pauses += 1
	EndSwitch

	Local $sessionWallSeconds = GetChestRunBenchmarkWallSeconds()
	Local $chestsPerHour = GetChestRunBenchmarkChestsPerHour($sessionWallSeconds)
	Local $averageCycleSeconds = Round($chest_benchmark_elapsed_seconds / $chest_benchmark_run, 2)
	Local $averageChestsPerRun = Round($chest_benchmark_chests / $chest_benchmark_run, 3)
	Local $csvLine = CsvChestRunBenchmarkValue(GetChestRunBenchmarkTimestamp()) & ',' _
		& CsvChestRunBenchmarkValue($chest_benchmark_session_id) & ',' _
		& CsvChestRunBenchmarkValue($chest_benchmark_route) & ',' _
		& CsvChestRunBenchmarkValue(GetCharacterName()) & ',' _
		& CsvChestRunBenchmarkValue($chest_benchmark_mode) & ',' _
		& $chest_benchmark_run & ',' & CsvChestRunBenchmarkValue($resultName) & ',' _
		& $elapsedSeconds & ',' & $openedChests & ',' & ($playerDied ? 1 : 0) & ',' _
		& $chest_benchmark_lockpicks_before & ',' & $lockpicksAfter & ',' & $netLockpicksUsed & ',' _
		& $chest_benchmark_lucky_before & ',' & $luckyAfter & ',' & $luckyGained & ',' _
		& $chest_benchmark_unlucky_before & ',' & $unluckyAfter & ',' & $unluckyGained & ',' _
		& $chest_benchmark_treasure_before & ',' & $treasureAfter & ',' & $treasureGained & ',' _
		& $chest_benchmark_chests & ',' & $chest_benchmark_elapsed_seconds & ',' & $sessionWallSeconds & ',' & $chestsPerHour & ',' _
		& $averageCycleSeconds & ',' & $averageChestsPerRun
	AppendChestRunBenchmarkCsv($csvLine)
	WriteChestRunBenchmarkSummary('COMPLETED', $resultName, $elapsedSeconds, $openedChests, $playerDied)
	$chest_benchmark_last_finish_timer = TimerInit()
EndFunc


;~ Initialize a fresh session after a route change, mode change, or long pause
Func InitializeChestRunBenchmarkSession($route, $mode)
	$chest_benchmark_route = $route
	$chest_benchmark_session_id = GetChestRunBenchmarkSessionID()
	$chest_benchmark_mode = $mode
	$chest_benchmark_session_timer = TimerInit()
	$chest_benchmark_last_finish_timer = Null
	$chest_benchmark_run = 0
	$chest_benchmark_successes = 0
	$chest_benchmark_failures = 0
	$chest_benchmark_pauses = 0
	$chest_benchmark_chests = 0
	$chest_benchmark_elapsed_seconds = 0
	$chest_benchmark_net_lockpicks_used = 0
	$chest_benchmark_lucky_gained = 0
	$chest_benchmark_unlucky_gained = 0
	$chest_benchmark_treasure_gained = 0
	$chest_benchmark_initial_lucky = GetLuckyTitle()
	$chest_benchmark_initial_unlucky = GetUnluckyTitle()
	$chest_benchmark_initial_treasure = GetTreasureTitle()
EndFunc


;~ Append a completed run to the shared chest benchmark CSV
Func AppendChestRunBenchmarkCsv($csvLine)
	Local $writeHeader = Not FileExists($CHEST_BENCHMARK_CSV_PATH) Or FileGetSize($CHEST_BENCHMARK_CSV_PATH) == 0
	Local $benchmarkFile = FileOpen($CHEST_BENCHMARK_CSV_PATH, $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)
	If $benchmarkFile == -1 Then
		Warn('Could not open chest benchmark log: ' & $CHEST_BENCHMARK_CSV_PATH)
		Return
	EndIf
	If $writeHeader Then
		FileWriteLine($benchmarkFile, 'timestamp,session_id,route,character,mode,run,result,duration_seconds,chests,player_dead,lockpicks_before,lockpicks_after,lockpicks_net_used,lucky_before,lucky_after,lucky_gained,unlucky_before,unlucky_after,unlucky_gained,treasure_before,treasure_after,treasure_gained,session_chests,session_active_seconds,session_wall_seconds,chests_per_hour,average_cycle_seconds,average_chests_per_run')
	EndIf
	FileWriteLine($benchmarkFile, $csvLine)
	FileClose($benchmarkFile)
EndFunc


;~ Write a stable, human-readable summary for the current route session
Func WriteChestRunBenchmarkSummary($status, $lastResult, $lastDuration, $lastChests, $playerDied)
	Local $summaryPath = GetChestRunBenchmarkSummaryPath()
	Local $summaryFile = FileOpen($summaryPath, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
	If $summaryFile == -1 Then
		Warn('Could not write chest benchmark summary: ' & $summaryPath)
		Return
	EndIf

	Local $completedRuns = $chest_benchmark_successes + $chest_benchmark_failures + $chest_benchmark_pauses
	Local $averageCycleSeconds = $completedRuns > 0 ? Round($chest_benchmark_elapsed_seconds / $completedRuns, 2) : 0
	Local $averageChestsPerRun = $completedRuns > 0 ? Round($chest_benchmark_chests / $completedRuns, 3) : 0
	Local $sessionWallSeconds = GetChestRunBenchmarkWallSeconds()
	FileWriteLine($summaryFile, $chest_benchmark_route & ' chest benchmark')
	FileWriteLine($summaryFile, 'Status: ' & $status)
	FileWriteLine($summaryFile, 'Last updated: ' & GetChestRunBenchmarkTimestamp())
	FileWriteLine($summaryFile, 'Session: ' & $chest_benchmark_session_id)
	FileWriteLine($summaryFile, 'Character: ' & GetCharacterName())
	FileWriteLine($summaryFile, 'Mode: ' & $chest_benchmark_mode)
	FileWriteLine($summaryFile, 'Current run: ' & $chest_benchmark_run)
	FileWriteLine($summaryFile, 'Successful runs: ' & $chest_benchmark_successes)
	FileWriteLine($summaryFile, 'Failed runs: ' & $chest_benchmark_failures)
	FileWriteLine($summaryFile, 'Paused runs: ' & $chest_benchmark_pauses)
	FileWriteLine($summaryFile, 'Total chests: ' & $chest_benchmark_chests)
	FileWriteLine($summaryFile, 'Active run seconds: ' & Round($chest_benchmark_elapsed_seconds, 2))
	FileWriteLine($summaryFile, 'Session wall seconds: ' & $sessionWallSeconds)
	FileWriteLine($summaryFile, 'Chests per hour: ' & GetChestRunBenchmarkChestsPerHour($sessionWallSeconds))
	FileWriteLine($summaryFile, 'Average cycle seconds: ' & $averageCycleSeconds)
	FileWriteLine($summaryFile, 'Average chests per run: ' & $averageChestsPerRun)
	FileWriteLine($summaryFile, 'Net lockpicks used: ' & $chest_benchmark_net_lockpicks_used)
	FileWriteLine($summaryFile, 'Lucky gained: ' & $chest_benchmark_lucky_gained)
	FileWriteLine($summaryFile, 'Unlucky gained: ' & $chest_benchmark_unlucky_gained)
	FileWriteLine($summaryFile, 'Treasure Hunter gained: ' & $chest_benchmark_treasure_gained)
	If $lastResult <> '' Then
		FileWriteLine($summaryFile, 'Last result: ' & $lastResult)
		FileWriteLine($summaryFile, 'Last duration seconds: ' & $lastDuration)
		FileWriteLine($summaryFile, 'Last chests: ' & $lastChests)
		FileWriteLine($summaryFile, 'Player dead after route: ' & ($playerDied ? 'yes' : 'no'))
	EndIf
	FileWriteLine($summaryFile, 'CSV log: ' & $CHEST_BENCHMARK_CSV_PATH)
	FileClose($summaryFile)
EndFunc


;~ Return cumulative chest throughput including all session delays
Func GetChestRunBenchmarkChestsPerHour($sessionWallSeconds)
	If $sessionWallSeconds <= 0 Then Return 0
	Return Round(($chest_benchmark_chests * 3600) / $sessionWallSeconds, 2)
EndFunc


;~ Return wall-clock seconds since the current session started
Func GetChestRunBenchmarkWallSeconds()
	If $chest_benchmark_session_timer == Null Then Return 0
	Return Round(TimerDiff($chest_benchmark_session_timer) / 1000, 2)
EndFunc


;~ Convert a farm result constant to a readable value
Func GetChestRunBenchmarkResultName($result)
	Switch $result
		Case $SUCCESS
			Return 'SUCCESS'
		Case $FAIL
			Return 'FAIL'
		Case $PAUSE
			Return 'PAUSE'
		Case Else
			Return 'UNKNOWN'
	EndSwitch
EndFunc


;~ Title reads can briefly return zero immediately after a map load. Ignore
;~ those transient reads instead of recording an enormous false gain or loss.
Func GetSafeChestRunTitleDelta($before, $after)
	If $before <= 0 Or $after <= 0 Or $after < $before Then Return 0
	Return $after - $before
EndFunc


;~ Quote a value for safe CSV output
Func CsvChestRunBenchmarkValue($value)
	Return '"' & StringReplace(String($value), '"', '""') & '"'
EndFunc


;~ Return a stable summary path for the active route
Func GetChestRunBenchmarkSummaryPath()
	Local $routeFileName = StringRegExpReplace(StringLower($chest_benchmark_route), '[^a-z0-9_-]', '-')
	Return @ScriptDir & '\logs\benchmarks\' & $routeFileName & '-latest.txt'
EndFunc


;~ Return a timestamp suitable for benchmark rows
Func GetChestRunBenchmarkTimestamp()
	Return @YEAR & '-' & @MON & '-' & @MDAY & ' ' & @HOUR & ':' & @MIN & ':' & @SEC
EndFunc


;~ Return a compact identifier for one BotsHub process session
Func GetChestRunBenchmarkSessionID()
	Return @YEAR & @MON & @MDAY & '-' & @HOUR & @MIN & @SEC
EndFunc
