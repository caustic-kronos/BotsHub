#cs
#################################
#                               #
#           Bot Hub             #
#                               #
#################################
Author: Night
Inspired by: Vaettir from gigi
GUI built with GuiBuilderPlus
#ce

; TODO :
; add option to choose between random travel and specific travel
; display titles automatically, if it does not pose problems
; add option for : running bot once, bot X times, bot until inventory full, or bot loop
; write small bot that : - get item infos (ID, maybe more) -salvage them -get material ID -write in file item infos and related salvaged material
; add green rarity

#RequireAdmin
#NoTrayIcon

#Region Includes
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <ScrollBarsConstants.au3>
#include <WindowsConstants.au3>
#include <ComboConstants.au3>
#include <FileConstants.au3>
#include <Date.au3>
#include <GuiEdit.au3>
#include <GuiTab.au3>

#include "GWA2_Headers.au3"
#include "GWA2.au3"
#include "GWA2_ID.au3"
#include "Utils.au3"
#include "JadeBrotherhood.au3"
#include "MinisterialCommendations.au3"
#include "Raptors.au3"
#include "Vaettir-v0.4.au3"
#include "Storage-Bot.au3"

#EndRegion Includes

#Region Variables
Local Const $GW_BOT_HUB_VERSION = "1.0"
Local Const $GUI_GREY_COLOR = 13158600
Local Const $GUI_BLUE_COLOR = 11192062
Local Const $GUI_RED_COLOR = 16751781
Local Const $GUI_YELLOW_COLOR = 16777192

;STOPPED -> INITIALIZED -> RUNNING -> WILL_PAUSE -> PAUSED -> RUNNING
Global $STATUS = "STOPPED"
;-1 = did not start, 0 = ran fine, 1 = failed, 2 = pause
Local $RUN_MODE = "AUTOLOAD"
Local $PROCESS_ID = ""
Local $CHARACTER_NAME  = ""
#EndRegion Variables

#Region GUI
Opt("GUIOnEventMode", 1)
Opt("GUICloseOnESC", 0)
Opt("MustDeclareVars", 1)

Local $GWBotHubGui, $TabsParent, $MainTab, $RunOptionsTab, $LootOptionsTab, $FarmInfosTab, $LootComponentsTab
Local $CharacterChoiceCombo, $FarmChoiceCombo, $StartButton, $FarmProgress

Global $ConsoleEdit
Global $RunInfosGroup, $RunsLabel, $FailuresLabel, $TimeLabel, $TimePerRunLabel, $GoldLabel, $GoldItemsLabel, $ExperienceLabel

Global $ItemsLootedGroup, $ChunkOfDrakeFleshLabel, $SkaleFinsLabel, $GlacialStonesLabel, $DiessaChalicesLabel, $RinRelicsLabel, $WintersdayGiftsLabel, $MargoniteGemstoneLabel, $StygianGemstoneLabel, $TitanGemstoneLabel, $TormentGemstoneLabel
Global $TitlesGroup, $AsuraTitleLabel, $DeldrimorTitleLabel, $NornTitleLabel, $VanguardTitleLabel, $KurzickTitleLabel, $LuxonTitleLabel, $LightbringerTitleLabel, $SunspearTitleLabel
Global $GlobalOptionsGroup, $LoopRunsCheckbox, $HMCheckbox, $StoreUnidentifiedGoldItemsCheckbox, $IdentifyGoldItemsCheckbox, $SalvageItemsCheckbox, $SellItemsCheckbox, $DynamicExecutionInput, $DynamicExecutionButton
Global $ConsumableOptionsGroup, $ConsumeCupcakeCheckbox, $ConsumeCandyAppleCheckbox, $ConsumePumpkingPieSliceCheckbox, $ConsumeGoldenEggCheckbox, $ConsumeCandyCornCheckbox
Global $BaseLootOptionsGroup, $LootEverythingCheckbox, $LootNothingCheckbox, $LootRareMaterialsCheckbox, $LootBasicMaterialsCheckbox, $LootKeysCheckbox, $LootSalvageItemsCheckbox, $LootTomesCheckbox, $LootDyesCheckbox, $LootScrollsCheckbox
Global $RarityLootOptionsGroup, $LootGoldItemsCheckbox, $LootPurpleItemsCheckbox, $LootBlueItemsCheckbox, $LootWhiteItemsCheckbox
Global $FarmSpecificLootOptionsGroup, $LootGlacialStonesCheckbox, $LootMapPiecesCheckbox, $LootTrophiesCheckbox

Global $ConsumablesLootOptionGroup, $LootCandyCaneShardsCheckbox, $LootLunarTokensCheckbox, $LootToTBagsCheckbox, $LootFestiveItemsCheckbox, $LootAlcoholsCheckbox, $LootSweetsCheckbox

Global $CharacterBuildLabel, $HeroBuildLabel
Global $GUITODO

;------------------------------------------------------
; Title...........:	_guiCreate
; Description.....:	Create the main GUI
;------------------------------------------------------
Func createGUI()
	$GWBotHubGui = GUICreate("GW Bot Hub", 600, 450, 851, 263)
	GUISetBkColor($GUI_GREY_COLOR, $GWBotHubGui)

	$CharacterChoiceCombo = GUICtrlCreateCombo("No character selected", 10, 420, 136, 20)
	$FarmChoiceCombo = GUICtrlCreateCombo("Choose a farm", 155, 420, 136, 20)
	GUICtrlSetData($FarmChoiceCombo, "Jade Brotherhood|Ministerial Commendations|Raptors|Vaettirs|Storage|Tests|Dynamic", "Choose a farm")
	$StartButton = GUICtrlCreateButton("Start", 300, 420, 136, 21)
	GUICtrlSetBkColor($StartButton, $GUI_BLUE_COLOR)
	GUICtrlSetOnEvent($StartButton, "GuiButtonHandler")
	GUISetOnEvent($GUI_EVENT_CLOSE, "GuiButtonHandler")
	$FarmProgress = GUICtrlCreateProgress(445, 420, 141, 21)
	
	$TabsParent = GUICtrlCreateTab(10, 10, 581, 401)
	
	$MainTab = GUICtrlCreateTabItem("Main")
	_GUICtrlTab_SetBkColor($GWBotHubGui, $TabsParent, $GUI_GREY_COLOR)
	$ConsoleEdit = GUICtrlCreateEdit("", 20, 225, 271, 176, BitOR($ES_AUTOVSCROLL, $ES_AUTOHSCROLL, $ES_WANTRETURN, $WS_VSCROLL))
	GUICtrlSetColor($ConsoleEdit, 16777215)
	GUICtrlSetBkColor($ConsoleEdit, 0)
	
	$RunInfosGroup = GUICtrlCreateGroup("Infos", 21, 39, 271, 176)
	$RunsLabel = GUICtrlCreateLabel("Runs: 0", 31, 64, 246, 16)
	$FailuresLabel = GUICtrlCreateLabel("Failures: 0", 31, 84, 246, 16)
	$TimeLabel = GUICtrlCreateLabel("Time: 0", 31, 104, 246, 16)
	$TimePerRunLabel = GUICtrlCreateLabel("Time per run: 0", 31, 124, 246, 16)
	$GoldLabel = GUICtrlCreateLabel("Gold: 0", 31, 144, 246, 16)
	$GoldItemsLabel = GUICtrlCreateLabel("Gold Items: 0", 31, 164, 246, 16)
	$ExperienceLabel = GUICtrlCreateLabel("Experience: 0", 31, 184, 246, 16)
	GUICtrlCreateGroup("", -99, -99, 1, 1)

	$ItemsLootedGroup = GUICtrlCreateGroup("Items", 306, 39, 271, 241)
	$GlacialStonesLabel = GUICtrlCreateLabel("Glacial Stones: 0", 316, 64, 246, 16)
	$ChunkOfDrakeFleshLabel = GUICtrlCreateLabel("Chunk Of Drake Flesh: 0", 316, 84, 246, 16)
	$SkaleFinsLabel = GUICtrlCreateLabel("Skale Fins: 0", 316, 104, 246, 16)
	$WintersdayGiftsLabel = GUICtrlCreateLabel("Wintersday Gifts: 0", 316, 124, 246, 16)
	$DiessaChalicesLabel = GUICtrlCreateLabel("Diessa Chalices: 0", 316, 144, 246, 16)
	$RinRelicsLabel = GUICtrlCreateLabel("Rin Relics: 0", 316, 164, 246, 16)
	$MargoniteGemstoneLabel = GUICtrlCreateLabel("Margonite Gemstone: 0", 316, 184, 246, 16)
	$StygianGemstoneLabel = GUICtrlCreateLabel("Stygian Gemstone: 0", 315, 205, 246, 16)
	$TitanGemstoneLabel = GUICtrlCreateLabel("Titan Gemstone: 0", 314, 229, 246, 16)
	$TormentGemstoneLabel = GUICtrlCreateLabel("Torment Gemstone: 0", 315, 250, 246, 16)
	GUICtrlCreateGroup("", -99, -99, 1, 1)

	$TitlesGroup = GUICtrlCreateGroup("Titles", 306, 289, 271, 111)
	$AsuraTitleLabel = GUICtrlCreateLabel("Asura: 0", 316, 314, 121, 16)
	$DeldrimorTitleLabel = GUICtrlCreateLabel("Deldrimor: 0", 316, 334, 121, 16)
	$NornTitleLabel = GUICtrlCreateLabel("Norn: 0", 316, 354, 121, 16)
	$VanguardTitleLabel = GUICtrlCreateLabel("Vanguard: 0", 316, 374, 121, 16)
	$KurzickTitleLabel = GUICtrlCreateLabel("Kurzick: 0", 446, 314, 116, 16)
	$LuxonTitleLabel = GUICtrlCreateLabel("Luxon: 0", 446, 334, 116, 16)
	$LightbringerTitleLabel = GUICtrlCreateLabel("Lightbringer: 0", 446, 354, 116, 16)
	$SunspearTitleLabel = GUICtrlCreateLabel("Sunspear: 0", 446, 374, 116, 16)
	GUICtrlCreateGroup("", -99, -99, 1, 1)

	$RunOptionsTab = GUICtrlCreateTabItem("Run options")
	_GUICtrlTab_SetBkColor($GWBotHubGui, $TabsParent, $GUI_GREY_COLOR)

	$GlobalOptionsGroup = GUICtrlCreateGroup("Options", 21, 39, 271, 361)
	$LoopRunsCheckbox = GUICtrlCreateCheckbox("Loop Runs", 31, 64, 156, 20)
	$HMCheckbox = GUICtrlCreateCheckbox("HM", 31, 94, 156, 20)
	$StoreUnidentifiedGoldItemsCheckbox = GUICtrlCreateCheckbox("Store Unidentified Gold Items", 31, 124, 156, 20)
	$IdentifyGoldItemsCheckbox = GUICtrlCreateCheckbox("Identify Gold Items", 31, 154, 156, 20)
	$SalvageItemsCheckbox = GUICtrlCreateCheckbox("Salvage items", 31, 184, 156, 20)
	$SellItemsCheckbox = GUICtrlCreateCheckbox("Sell Items", 31, 214, 156, 20)
	
	$DynamicExecutionInput = GUICtrlCreateInput("", 31, 364, 156, 20)
	$DynamicExecutionButton = GUICtrlCreateButton("Run", 205, 364, 75, 20)
	GUICtrlSetBkColor($DynamicExecutionButton, $GUI_BLUE_COLOR)
	GUICtrlSetOnEvent($DynamicExecutionButton, "GuiButtonHandler")
	GUICtrlCreateGroup("", -99, -99, 1, 1)

	$ConsumableOptionsGroup = GUICtrlCreateGroup("Consumables to consume", 305, 40, 271, 361)
	$ConsumeCupcakeCheckbox = GUICtrlCreateCheckbox("Cupcake", 315, 65, 156, 20)
	$ConsumeCandyAppleCheckbox = GUICtrlCreateCheckbox("Candy Apple", 315, 95, 156, 20)
	$ConsumePumpkingPieSliceCheckbox = GUICtrlCreateCheckbox("Pumpking Pie Slice", 315, 125, 156, 20)
	$ConsumeGoldenEggCheckbox = GUICtrlCreateCheckbox("Golden Egg", 315, 155, 156, 20)
	$ConsumeCandyCornCheckbox = GUICtrlCreateCheckbox("Candy Corn", 315, 185, 156, 20)
	GUICtrlCreateGroup("", -99, -99, 1, 1)

	$LootOptionsTab = GUICtrlCreateTabItem("Loot options")
	_GUICtrlTab_SetBkColor($GWBotHubGui, $TabsParent, $GUI_GREY_COLOR)

	$BaseLootOptionsGroup = GUICtrlCreateGroup("Base Loot", 21, 39, 271, 176)
	$LootEverythingCheckbox = GUICtrlCreateCheckbox("Loot everything", 31, 64, 96, 20)
	$LootNothingCheckbox = GUICtrlCreateCheckbox("Loot nothing", 31, 94, 96, 20)
	$LootRareMaterialsCheckbox = GUICtrlCreateCheckbox("Rare materials", 31, 124, 96, 20)
	$LootBasicMaterialsCheckbox = GUICtrlCreateCheckbox("Basic materials", 30, 155, 96, 20)
	$LootSalvageItemsCheckbox = GUICtrlCreateCheckbox("Salvage items", 151, 64, 111, 20)
	$LootTomesCheckbox = GUICtrlCreateCheckbox("Tomes", 151, 94, 111, 20)
	$LootKeysCheckbox = GUICtrlCreateCheckbox("Keys", 151, 154, 96, 20)
	$LootDyesCheckbox = GUICtrlCreateCheckbox("Dyes (all)", 31, 184, 96, 20)
	$LootScrollsCheckbox = GUICtrlCreateCheckbox("Scrolls", 151, 124, 111, 20)
	GUICtrlCreateGroup("", -99, -99, 1, 1)

	$RarityLootOptionsGroup = GUICtrlCreateGroup("Rarity Loot", 166, 224, 126, 176)
	$LootWhiteItemsCheckbox = GUICtrlCreateCheckbox("White items", 176, 249, 106, 20)
	$LootBlueItemsCheckbox = GUICtrlCreateCheckbox("Blue items", 176, 279, 106, 20)
	$LootPurpleItemsCheckbox = GUICtrlCreateCheckbox("Purple items", 176, 309, 106, 20)
	$LootGoldItemsCheckbox = GUICtrlCreateCheckbox("Gold items", 176, 339, 106, 20)
	GUICtrlCreateGroup("", -99, -99, 1, 1)

	$FarmSpecificLootOptionsGroup = GUICtrlCreateGroup("Farm Specific", 23, 224, 136, 176)
	$LootGlacialStonesCheckbox = GUICtrlCreateCheckbox("Glacial Stones", 31, 249, 81, 20)
	$LootMapPiecesCheckbox = GUICtrlCreateCheckbox("Map pieces", 31, 279, 81, 20)
	$LootTrophiesCheckbox = GUICtrlCreateCheckbox("Trophies", 30, 310, 81, 20)
	GUICtrlCreateGroup("", -99, -99, 1, 1)

	$ConsumablesLootOptionGroup = GUICtrlCreateGroup("Consumables loot", 306, 39, 271, 361)
	$LootSweetsCheckbox = GUICtrlCreateCheckbox("Sweets", 316, 64, 121, 20)
	$LootAlcoholsCheckbox = GUICtrlCreateCheckbox("Alcohols", 446, 64, 121, 20)
	$LootFestiveItemsCheckbox = GUICtrlCreateCheckbox("Festive Items", 316, 94, 121, 20)
	$LootToTBagsCheckbox = GUICtrlCreateCheckbox("ToT Bags", 316, 124, 121, 20)
	$LootLunarTokensCheckbox = GUICtrlCreateCheckbox("Lunar Tokens", 446, 124, 121, 20)
	$LootCandyCaneShardsCheckbox = GUICtrlCreateCheckbox("Candy Cane Shards", 446, 94, 121, 20)
	GUICtrlCreateGroup("", -99, -99, 1, 1)

	$FarmInfosTab = GUICtrlCreateTabItem("Farm infos")
	_GUICtrlTab_SetBkColor($GWBotHubGui, $TabsParent, $GUI_GREY_COLOR)
	$CharacterBuildLabel = GUICtrlCreateLabel("Character build:", 30, 55, 531, 26)
	$HeroBuildLabel = GUICtrlCreateLabel("Hero build:", 30, 95, 531, 26)
	$LootComponentsTab = GUICtrlCreateTabItem("Loot components")
	_GUICtrlTab_SetBkColor($GWBotHubGui, $TabsParent, $GUI_GREY_COLOR)
	$GUITODO = GUICtrlCreateLabel("GUI TODO : (farm specific to Secret Lair of the Snowmen)Peppermint Candy Cane, Rainbow Candy Cane, Spiked Eggnog, Wintergreen Candy Cane, Yuletide Tonic (specific to Irontoe's lair) Dwarven Ale, Aged Dwarven Ale", 30, 95, 531, 26)
	GUICtrlCreateTabItem("")
	
	GUICtrlSetState($HMCheckbox, $GUI_CHECKED)
	GUICtrlSetState($StoreUnidentifiedGoldItemsCheckbox, $GUI_CHECKED)
	GUICtrlSetState($LoopRunsCheckbox, $GUI_CHECKED)
	GUICtrlSetState($ConsumeCupcakeCheckbox, $GUI_CHECKED)
	GUICtrlSetState($ConsumeGoldenEggCheckbox, $GUI_CHECKED)
	GUICtrlSetState($ConsumeCandyCornCheckbox, $GUI_CHECKED)
	GUICtrlSetState($LootRareMaterialsCheckbox, $GUI_CHECKED)
	GUICtrlSetState($LootBasicMaterialsCheckbox, $GUI_CHECKED)
	GUICtrlSetState($LootKeysCheckbox, $GUI_CHECKED)
	GUICtrlSetState($LootSalvageItemsCheckbox, $GUI_CHECKED)
	GUICtrlSetState($LootTomesCheckbox, $GUI_CHECKED)
	GUICtrlSetState($LootScrollsCheckbox, $GUI_CHECKED)
	GUICtrlSetState($LootGoldItemsCheckbox, $GUI_CHECKED)
	GUICtrlSetState($LootGlacialStonesCheckbox, $GUI_CHECKED)
	GUICtrlSetState($LootSweetsCheckbox, $GUI_CHECKED)
	GUICtrlSetState($LootAlcoholsCheckbox, $GUI_CHECKED)
	GUICtrlSetState($LootFestiveItemsCheckbox, $GUI_CHECKED)
	GUICtrlSetState($LootToTBagsCheckbox, $GUI_CHECKED)
	GUICtrlSetState($LootLunarTokensCheckbox, $GUI_CHECKED)
	GUICtrlSetState($LootCandyCaneShardsCheckbox, $GUI_CHECKED)
	GUICtrlSetState($LootTrophiesCheckbox, $GUI_CHECKED)
EndFunc

Func _GUICtrlTab_SetBkColor($gui, $parentTab, $color)
    Local $aTabPos = ControlGetPos($gui, "", $parentTab)
    Local $aTab_Rect = _GUICtrlTab_GetItemRect($parentTab, -1)

    GUICtrlCreateLabel("", $aTabPos[0]+2, $aTabPos[1]+$aTab_Rect[3]+4, $aTabPos[2]-6, $aTabPos[3]-$aTab_Rect[3]-7)
    GUICtrlSetBkColor(-1, $color)
    GUICtrlSetState(-1, $GUI_DISABLE)
EndFunc

;~ Handle start button usage
Func GuiButtonHandler()
    Switch @GUI_CtrlId
        Case $StartButton
			If $STATUS == "STOPPED" Then
				Out("Initializing...")
				If (Authentification() <> 0) Then Return
				$STATUS = "INITIALIZED"
				
				Out("Starting...")
				$STATUS = "RUNNING"
				GUICtrlSetData($StartButton, "Pause")
				GUICtrlSetBkColor($StartButton, $GUI_RED_COLOR)
			ElseIf $STATUS == "INITIALIZED" Then
				Out("Starting...")
				$STATUS = "RUNNING"
			ElseIf $STATUS == "RUNNING" Then
				Out("Pausing...")
				GUICtrlSetData($StartButton, "Will pause after this run")
				GUICtrlSetState($StartButton, $GUI_Disable)
				GUICtrlSetBkColor($StartButton, $GUI_YELLOW_COLOR)
				$STATUS = "WILL_PAUSE"
			ElseIf $STATUS == "WILL_PAUSE" Then
				MsgBox(0, "Error", "You shouldn't be able to press Pause when bot it already pausing.")
			ElseIf $STATUS == "PAUSED" Then
				Out("Restarting...")
				GUICtrlSetData($StartButton, "Pause")
				GUICtrlSetBkColor($StartButton, $GUI_RED_COLOR)
				$STATUS = "RUNNING"
			Else
				MsgBox(0, "Error", "Unknown status '" & $STATUS & "'")
			EndIf
		Case $DynamicExecutionButton
			DynamicExecution(GUICtrlRead($DynamicExecutionInput))
		Case $GUI_EVENT_CLOSE
            Exit
    EndSwitch
EndFunc

;~ Print to console with timestamp
Func Out($TEXT)
    GUICtrlSetData($ConsoleEdit, GUICtrlRead($ConsoleEdit) & @HOUR & ":" & @MIN & " - " & $TEXT & @CRLF)
    _GUICtrlEdit_Scroll($ConsoleEdit, $SB_SCROLLCARET)
    _GUICtrlEdit_Scroll($ConsoleEdit, $SB_LINEUP)
    UpdateLock()
EndFunc

#EndRegion GUI

main()

;------------------------------------------------------
; Title...........:	_main
; Description.....:	run the main program
;------------------------------------------------------
Func main()
	createGUI()
	GUISetState(@SW_SHOWNORMAL)
	Out("GW Bot Hub " & $GW_BOT_HUB_VERSION)

	If $CmdLine[0] <> 0 Then
		$RUN_MODE = "CMD"
		If 1 > UBound($CmdLine)-1 Then
			MsgBox(0, "Error", "Element is out of the array bounds.")
			exit
		EndIf
		If 2 > UBound($CmdLine)-1 Then exit
	
		$CHARACTER_NAME  = $CmdLine[1]
		$PROCESS_ID = $CmdLine[2]
		LOGIN($CHARACTER_NAME, $PROCESS_ID)
		$STATUS = "INITIALIZED"
	ElseIf $RUN_MODE == "AUTOLOAD" Then
		Local $loggedCharNames = GetLoggedCharNames()
		If ($loggedCharNames <> '') Then GUICtrlSetData($CharacterChoiceCombo, $loggedCharNames)
	Else
		GUICtrlDelete($CharacterChoiceCombo)
		$CharacterChoiceCombo = GUICtrlCreateInput("Character Name Input", 10, 420, 136, 20)
	EndIf

	BotHubLoop()
EndFunc

;~ Main loop of the program
Func BotHubLoop()
	While True
		Sleep(1000)
		;Out($STATUS)

		If ($STATUS == "RUNNING") Then
			Local $Farm = GUICtrlRead($FarmChoiceCombo)
			Local $timer = TimerInit()
			$STATS_MAP["success_code"] = -1
			FillStats()

			Switch $Farm
				Case "Choose a farm"
					MsgBox(0, "Error", "No farm chosen.")
					$STATUS = "INITIALIZED"
					GUICtrlSetData($StartButton, "Start")
					GUICtrlSetBkColor($StartButton, $GUI_BLUE_COLOR)
				Case "Jade Brotherhood"
					JadeBrotherhoodFarm($STATUS)
				Case "Ministerial Commendations"
					MinisterialCommendationsFarm($STATUS)
				Case "Raptors"
					RaptorFarm($STATUS)
				Case "Vaettirs"
					VaettirFarm($STATUS)
				Case "Storage"
					ManageInventory($STATUS)
					$STATUS = "WILL_PAUSE"
				Case "Dynamic"
					While $STATUS == "RUNNING"
						Sleep(1000)
					WEnd
				;Case Else
				Case "Tests"
					RunTests($STATUS)
			EndSwitch
			FillStats(TimerDiff($timer))
			UpdateStats()
			
			If ($STATS_MAP["success_code"] == 2) Then $STATUS = "WILL_PAUSE"
		Else
			If Random(1, 10, 1) = 1 Then UpdateLock()
		EndIf
		
		If ($STATUS == "WILL_PAUSE") Then
			Out("Paused.")
			$STATUS = "PAUSED"
			GUICtrlSetData($StartButton, "Start")
			GUICtrlSetState($FarmChoiceCombo, $GUI_Enable)
			GUICtrlSetState($StartButton, $GUI_Enable)
			GUICtrlSetBkColor($StartButton, $GUI_BLUE_COLOR)
		EndIf
	WEnd
EndFunc

#Region Authentification and Login
;~ Initialize connection to GW with the character name or process id given
Func Authentification()
    Local $CharacterName = GUICtrlRead($CharacterChoiceCombo)
	If ($CharacterName == "") Then
		MsgBox(0, "Error", "No character name given.")
		Return 1
	ElseIf($CharacterName == "No character selected") Then
		Out("Running without authentification.")
    ElseIf $PROCESS_ID And $RUN_MODE == "CMD" Then
        $proc_id_int = Number($PROCESS_ID, 2)
        Out("Running via pid " & $proc_id_int)
        If Initialize($proc_id_int, True, True, False) = 0 Then
            MsgBox(0, "Error", "Could not Find a ProcessID or somewhat '" & $proc_id_int & "'  " & VarGetType($proc_id_int) & "'")
            Return 1
        EndIf
	Else
		If Initialize($CharacterName, True, True, False) = 0 Then
			MsgBox(0, "Error", "Could not find a GW client with a character named '" & $CharacterName & "'")
			Return 1
		EndIf
	EndIf
	EnsureEnglish(True)
	GUICtrlSetState($CharacterChoiceCombo, $GUI_Disable)
	GUICtrlSetState($FarmChoiceCombo, $GUI_Disable)
	WinSetTitle($GWBotHubGui, "", "GW Bot Hub - " & GetCharname())
	Return 0
EndFunc

;~ Lock an account for multiboxing
Func UpdateLock()
    Local $cn = GetCharname()
    If $cn Then
        Local $sFileName   = @ScriptDir & "\lock\" & $cn & ".lock"
        Local $hFilehandle = FileOpen($sFileName, $FO_OVERWRITE)
        FileWrite($hFilehandle,  @HOUR & ":" & @MIN)
        FileClose($hFilehandle)
    EndIf
EndFunc

; Function to login from cmd, not tested
; TODO: test it
Func LOGIN($char_name = "fail", $ProcessID = false)
	If $char_name = "" Then
		MsgBox(0, "Error", "char_name" & $char_name)
		Exit
	EndIf

	If $ProcessID = False Then
		MsgBox(0, "Error", "ProcessID" & $ProcessID)
		Exit
	EndIf

	Sleep(Random(1000,1500))

	Local $WindowList=WinList("Guild Wars")
	Local $WinHandle = False;

	For $i = 1 to $WindowList[0][0]
		If WinGetProcess($WindowList[$i][1])= $ProcessID Then
			$WinHandle=$WindowList[$i][1]
		EndIf
	Next

	If $WinHandle = False Then
		MsgBox(0, "Error", "WinHandle" & $WinHandle)
		Exit
	EndIf

	Local $lCheck    = False
	Local $lDeadLock = Timerinit()

	ControlSend($WinHandle, "", "", "{enter}")
	Sleep(Random(500,1500))
	WinSetTitle($WinHandle, "", $char_name & " - Guild Wars")
	Do
		Sleep(50)
		$lCheck = GetMapLoading() <> 2
	Until $lCheck Or TimerDiff($lDeadLock)>15000

	If $lCheck = False Then
		ControlSend($WinHandle, "", "", "{enter}")
		$lDeadLock = Timerinit()
		Do
			Sleep(50)
			$lCheck = GetMapLoading() <> 2
		Until $lCheck Or TimerDiff($lDeadLock)>15000
	EndIf

	If $lCheck = False Then
		ControlSend($WinHandle, "", "", "{enter}")
		$lDeadLock = Timerinit()
		Do
			Sleep(50)
			$lCheck = GetMapLoading() <> 2
		Until $lCheck Or TimerDiff($lDeadLock)>15000
	EndIf

	If $lCheck = False Then
		ControlSend($WinHandle, "", "", "{enter}")
		$lDeadLock = Timerinit()
		Do
			Sleep(50)
			$lCheck = GetMapLoading() <> 2
		Until $lCheck Or TimerDiff($lDeadLock)>15000
	EndIf

	If $lCheck = False Then
		MsgBox(0, "Error", "lcheck")

		ProcessClose($ProcessID)
		Exit
	Else
		Sleep(Random(2500,3500))
	EndIf
EndFunc

#EndRegion Authentification and Login