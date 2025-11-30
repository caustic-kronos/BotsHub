#CS ===========================================================================
======================================
|  	  Margonite Gemstones Farm bot   |
|			  TonReuf   		     |
======================================
;
; Run this farm bot as Assassin or Mesmer or Ranger or Elementalist
;
; Rewritten for BotsHub: Gahais
; Margonite gemstone farms in City of Torc'qua based on below articles:
https://gwpvx.fandom.com/wiki/Build:Team_-_1_Hero_Margonite_Gemstone_Farm
https://gwpvx.fandom.com/wiki/Build:Team_-_1_Hero_Whirling_Defense_City_Farmer
;
#CE ===========================================================================

#include-once
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', True)

#Region Configuration
; === Build ===
;Global Const $AMeMargoniteSkillBar = 'OwVT4nPHYiHRn5AiVE3hm0DSEAA'
Global Const $AMeMargoniteSkillBar = 'OwVT4nPHYiHRn5AiVE3hm0D6iD'
;Global Const $MeAMargoniteSkillBar = 'OQdTA0A+ZiHRn5AiAC3hm0DSEA'
Global Const $MeAMargoniteSkillBar = 'OQdTAmA/ZiHRn5AiAC3hm0DyiD'
Global Const $EMeMargoniteSkillBar = 'OgVUEQkkYmSSfaDfVug0C0keQiAA'
Global Const $RAMargoniteSkillBar = 'OgcTcZ/8ZiHRn5AKCC3hm8uU4A'
Global Const $MargoniteMonkHeroSkillBar = 'OwITAnHb5Qe/zhxLkpE6+G'
;Global Const $MargoniteMonkHeroSkillBar = 'OwITAnHb5Qe/zhx7jpE6+G'

; You can select which monk hero to use in the farm here, among 3 heroes available. Uncomment below line for hero to use
; party hero ID that is used to add hero to the party team
;Global Const $MargoniteHeroPartyID = $ID_Dunkoro
;Global Const $MargoniteHeroPartyID = $ID_Tahlkora
Global Const $MargoniteHeroPartyID = $ID_Ogden
Global Const $MargoniteHeroIndex = 1 ; index of first hero party member in team, player index is 0
Global $MargoniteHeroAgentID = Null ; agent ID that is randomly assigned to hero in exploration areas
Global $MargonitePlayerProfession = $ID_Mesmer ; global variable to remember player's profession in setup and avoid creating Dll structs over and over during fight

Global Const $Margonite_DeadlyParadox		= 1
Global Const $Margonite_ShadowForm			= 2
Global Const $Margonite_ShroudOfDistress	= 3
Global Const $Margonite_DeathsCharge		= 5
Global Const $Margonite_IAmUnstoppable		= 6
Global Const $Margonite_AncestorsVisage		= 7
Global Const $Margonite_LightbringersGaze	= 8
; Margonites always create Quickening Zephyr spirit which halves recharge time of spells
; Therefore Ancestor's visage recharges after 10 seconds which is basically equal to 9-10 seconds duration with illusion magic attribute equal to 12-14
; So Sympathetic Visage is replaced here with Lightbringer's Gaze, which also should recharge 2x faster, to increase damage rate
; Deadly Paradox skill could also be potentially removed because of Quickening Zephyr spirit

Global Const $Margonite_Assasin_GreatDwarfArmor		= 4

Global Const $Margonite_Mesmer_WayOfPerfection		= 4

Global Const $Margonite_Elementalist_GlyphOfSwiftness	= 1
Global Const $Margonite_Elementalist_ObsidianFlesh		= 2
Global Const $Margonite_Elementalist_StonefleshAura		= 3
Global Const $Margonite_Elementalist_ElementalLord		= 4
Global Const $Margonite_Elementalist_AuraOfRestoration	= 5
Global Const $Margonite_Elementalist_SympatheticVisage	= 8

Global Const $Margonite_Ranger_UnseenFury			= 4
Global Const $Margonite_Ranger_DwarvenStability		= 7
Global Const $Margonite_Ranger_WhirlingDefense		= 8

; Monk protector hero
Global Const $Margonite_Hero_BalthazarSpirit	= 1
Global Const $Margonite_Hero_WatchfulSpirit		= 2
Global Const $Margonite_Hero_LifeBarrier		= 3
Global Const $Margonite_Hero_LifeBond			= 4
Global Const $Margonite_Hero_VitalBlessing		= 5
Global Const $Margonite_Hero_BlessedSignet		= 6
Global Const $Margonite_Hero_EdgeOfExtinction	= 7
Global Const $Margonite_Hero_TrollUnguent		= 8
#EndRegion Configuration

; ==== Constants ====
Global Const $GemstoneMargoniteFarmInformations = 'For best results, have :' & @CRLF _
	& '- Armor with HP runes and 5 blessed insignias (+50 armor when enchanted)' & @CRLF _
	& '- Spear/Sword/Axe +5 energy of Enchanting (20% longer enchantments duration)' & @CRLF _
	& '- Shield of Fortitude (+30 HP) with +10 vs Demons (like Stygian Aegis)' & @CRLF _
	& '- Monk hero with +4 Protection prayers (+3+1 headgear)' & @CRLF _
	& '- Monk hero armor and weapons with bonus to energy and HP' & @CRLF _
	& ' ' & @CRLF _
	& 'You can run this farm as Assassin or Mesmer or Ranger or Elementalist. Bot will set up build automatically for these professions' & @CRLF _
	& 'This bot farms margonite gemstones (1 of 4 types) in City of Torc''qua location' & @CRLF _
	& 'Player needs to have access to Gate of Anguish outpost which has exit to City of Torc''qua location' & @CRLF _
	& 'This farm reduces energy of margonites to 0 with ancestor''s visage skill which deals damage to margonites because margonites create Famine spirit' & @CRLF _
	& 'Recommended to have maxed out Lightbringer title. If not maxed out then this farm is good for raising lightbringer rank' & @CRLF _
	& 'Can switch to normal mode in case of low success rate but hard mode has better loots' & @CRLF _
	& 'Gemstones can be exchanged into armbrace of truth (15 of each type) or coffer of whisper (1 of each type)' & @CRLF _
	& 'This farm bot is based on below articles:' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:Team_-_1_Hero_Margonite_Gemstone_Farm' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:Team_-_1_Hero_Whirling_Defense_City_Farmer' & @CRLF _
	& 'For Assassin and Mesmer and Elementalist this bot works by casting Visage skills that reduce energy of Margonites to 0 which deals damage to them because they create Famine spirit' & @CRLF
; Average duration ~ 5 minutes
Global Const $GEMSTONE_MARGONITE_FARM_DURATION = 5 * 60 * 1000
Global Const $MAX_GEMSTONE_MARGONITE_FARM_DURATION = 10 * 60 * 1000
Global $GemstoneMargoniteFarmTimer = Null
Global $GEMSTONE_MARGONITE_FARM_SETUP = False
Global Const $Margonites_Range = 800


Global $MargoniteMoveOptions = CloneDictMap($Default_MoveDefend_Options)
$MargoniteMoveOptions.Item('defendFunction')		= MargoniteDefend
$MargoniteMoveOptions.Item('moveTimeOut')			= 100 * 1000 ; 100 seconds max for being stuck
$MargoniteMoveOptions.Item('randomFactor')			= 150
$MargoniteMoveOptions.Item('hosSkillSlot')			= 0
$MargoniteMoveOptions.Item('deathChargeSkillSlot')	= $Margonite_DeathsCharge
$MargoniteMoveOptions.Item('openChests')			= False
Global $MargoniteMoveOptionsElementalist = CloneDictMap($MargoniteMoveOptions)
$MargoniteMoveOptionsElementalist.Item('deathChargeSkillSlot') = 0

Global $MargoniteObsidianFleshTimer = TimerInit()
Global $MargoniteStonefleshAuraTimer = TimerInit()
Global $MargoniteElementalLordTimer = TimerInit()
Global $MargoniteAuraOfRestorationTimer = TimerInit()


;~ Main loop function for farming margonite gemstones
Func GemstoneMargoniteFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $GEMSTONE_MARGONITE_FARM_SETUP Then
		If SetupGemstoneMargoniteFarm() == $FAIL Then Return $PAUSE
	EndIf
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	If GoToCityOfTorcqua() == $FAIL Then Return $FAIL
	Local $result = GemstoneMargoniteFarmLoop()
	If $result == $SUCCESS Then
		Info('Successfully cleared margonite mobs')
	ElseIf $result == $FAIL Then
		If IsPlayerDead() Then Warn('Player died')
		If $MargoniteHeroAgentID <> Null And GetIsDead(GetAgentByID($MargoniteHeroAgentID)) Then Warn('monk hero died')
		Info('Could not clear margonite mobs')
	EndIf
	Info('Returning back to the outpost')
	Sleep(1000)
	Resign()
	Sleep(4000)
	ReturnToOutpost()
	Sleep(6000)
	Return $result
EndFunc


Func SetupGemstoneMargoniteFarm()
	Info('Setting up farm')
	If GetMapID() <> $ID_Gate_Of_Anguish Then
		TravelToOutpost($ID_Gate_Of_Anguish, $DISTRICT_NAME)
	Else ; resigning to return to outpost in case when player is in one of 4 DoA farm areas that have the same map ID as Gate of Anguish outpost (474)
		Resign()
		Sleep(4000)
		ReturnToOutpost()
		Sleep(6000)
	EndIf
	SwitchToHardModeIfEnabled()
	Sleep(500 + GetPing())
	SetDisplayedTitle($ID_Lightbringer_Title)
	Sleep(500 + GetPing())
	If SetupPlayerMargoniteFarm() == $FAIL Then Return $FAIL
    If SetupTeamMargoniteFarm() == $FAIL Then Return $FAIL
    SetupHeroMargoniteFarm()
	Sleep(500 + GetPing())
	$GEMSTONE_MARGONITE_FARM_SETUP = True
	Info('Preparations complete')
EndFunc


Func SetupPlayerMargoniteFarm()
	Info('Setting up player build skill bar')
	Sleep(500 + GetPing())
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_Assassin Then
		$MargonitePlayerProfession = $ID_Assassin
		LoadSkillTemplate($AMeMargoniteSkillBar)
    ElseIf DllStructGetData(GetMyAgent(), 'Primary') == $ID_Mesmer Then
		$MargonitePlayerProfession = $ID_Mesmer
		LoadSkillTemplate($MeAMargoniteSkillBar)
    ElseIf DllStructGetData(GetMyAgent(), 'Primary') == $ID_Elementalist Then
		$MargonitePlayerProfession = $ID_Elementalist
		LoadSkillTemplate($EMeMargoniteSkillBar)
    ElseIf DllStructGetData(GetMyAgent(), 'Primary') == $ID_Ranger Then
		$MargonitePlayerProfession = $ID_Ranger
		LoadSkillTemplate($RAMargoniteSkillBar)
    Else
		Warn('You need to run this farm bot as Assassin or Mesmer or Elementalist or Ranger')
		Return $FAIL
    EndIf
	;ChangeWeaponSet(4) ; change to other weapon slot or comment this line if necessary
	Sleep(500 + GetPing())
EndFunc


Func SetupTeamMargoniteFarm()
	Info('Setting up team')
	Sleep(500 + GetPing())
	LeaveParty()
	Sleep(500 + GetPing())
	AddHero($MargoniteHeroPartyID)
	Sleep(500 + GetPing())
	If GetPartySize() <> 2 Then
    	Warn('Could not add monk hero to team. Team size different than 2')
		Return $FAIL
	EndIf
EndFunc


Func SetupHeroMargoniteFarm()
	Info('Setting up hero build skill bar')
	Sleep(500 + GetPing())
	LoadSkillTemplate($MargoniteMonkHeroSkillBar, $MargoniteHeroIndex)
	Sleep(500 + GetPing())
	SetHeroAggression($MargoniteHeroIndex, $ID_Hero_avoiding)
    DisableMargoniteHeroSkills() ; disabling 1,2,3,4,5,7 skills for monk hero, leaving 6,8 skills enabled
EndFunc


Func DisableMargoniteHeroSkills()
	Sleep(500)
	For $i = 1 To 5
		DisableHeroSkillSlot($MargoniteHeroIndex, $i)
		Sleep(500)
	Next
	DisableHeroSkillSlot($MargoniteHeroIndex, 7)
	Sleep(500)
EndFunc


;~ exit gate of Anguish outpost by moving into portal that leads into farming location - City of Torc'qua
Func GoToCityOfTorcqua()
	Info('Moving to City of Torc''qua')
	; Unfortunately all 4 gemstone farm explorable locations have the same map ID as Gate of Anguish outpost, so it is hard to tell if player left the outpost
	; Therefore below loop checks if player is in close range of coordinates of that start zone where player initially spawns in City of Torc'qua
	Local Static $StartX = -18575
	Local Static $StartY = -8833
	Local $TimerZoning = TimerInit()
	While Not IsAgentInRange(GetMyAgent(), $StartX, $StartY, $RANGE_EARSHOT)
		If TimerDiff($TimerZoning) > 120000 Then ; 120 seconds max time for leaving outpost in case of bot getting stuck
			Info('Could not zone to City of Torc''qua')
			Return $FAIL
		EndIf
		MoveTo(6816, -13634)
		MoveTo(8258, -10419)
		MoveTo(10180, -10714)
		Move(11250, -11350, 0)
		Sleep(12000) ; wait 12 seconds to ensure that player exited outpost
	WEnd
EndFunc


Func GemstoneMargoniteFarmLoop()
	Sleep(2000)
	$MargoniteHeroAgentID = GetHeroID($MargoniteHeroIndex)
	If Not GetAgentExists($MargoniteHeroAgentID) Then Return $FAIL
	If IsPlayerDead() Then Return $FAIL
	Info('Starting Farm')
	$GemstoneMargoniteFarmTimer = TimerInit() ; starting run timer, if run lasts longer than max time then bot must have gotten stuck and fail is returned to restart run

	CommandHero($MargoniteHeroIndex, -18571, -9328)
	Sleep(2000)
	CastBondsMargoniteFarm()
	If GetLightbringerTitle() < 50000 Then
		Info('Taking Blessing')
		GoNearestNPCToCoords(-17623, -9670)
		Sleep(1000)
		Dialog(0x85)
		Sleep(500)
	EndIf
	Info('Taking Quest')
	Local $TimerQuest
	$TimerQuest = TimerInit()
	Do
		GoNearestNPCToCoords(-17710, -8811)
		Sleep(1000)
		Dialog(0x82EF01)
		Sleep(1000)
	Until GetQuestByID(0x2EF) <> Null Or TimerDiff($TimerQuest) > 15000 Or IsPlayerDead()
	If GetQuestByID(0x2EF) == Null Then Return $FAIL
	Info('Moving to spot and aggroing margonites')
	MoveTo(-17541, -9431)
	If MargoniteMoveDefending(-13935, -9850) == $FAIL Then Return $FAIL
	CommandHero($MargoniteHeroIndex, -16878, -9571)
	If MargoniteMoveDefending(-14321, -11803) == $FAIL Then Return $FAIL
	If MargoniteMoveDefending(-12115, -11057) == $FAIL Then Return $FAIL
	CommandHero($MargoniteHeroIndex, -14879, -11729)
	WaitAggroMargonites(7000)
	; below is the furthest location player goes to pull front Margonite mobs but also not let rear margonite mobs leave player and kill monk hero
	If MargoniteMoveDefending(-10277, -10778) == $FAIL Then Return $FAIL
	CommandHero($MargoniteHeroIndex, -12861, -12620)
	WaitAggroMargonites(50000) ; waiting for far margonite group to come into player's range
	If MargoniteMoveDefending(-12065, -10905) == $FAIL Then Return $FAIL
	WaitAggroMargonites(5000)
	If MargoniteMoveDefending(-12246, -10149) == $FAIL Then Return $FAIL
	WaitAggroMargonites(7000)
	If MargoniteMoveDefending(-12303, -10349) == $FAIL Then Return $FAIL
	If MargoniteMoveDefending(-11410, -11359) == $FAIL Then Return $FAIL
	WaitAggroMargonites(3000)
	If MargoniteMoveDefending(-11484, -11034) == $FAIL Then Return $FAIL
	If IsPlayerDead() Or GetIsDead(GetAgentByID($MargoniteHeroAgentID)) Then Return $FAIL
	UseHeroSkill($MargoniteHeroIndex, $Margonite_Hero_EdgeOfExtinction)
	If KillMargonites() == $FAIL Then Return $FAIL
	RandomSleep(1000 + GetPing())
	If IsPlayerAlive() Then
		Info('Picking up loot')
		PickUpItems(MargoniteCheckSFBuffs, DefaultShouldPickItem, $RANGE_EARSHOT)
	EndIf

	Return IsPlayerAlive()? $SUCCESS : $FAIL
EndFunc


Func CastBondsMargoniteFarm()
	If IsPlayerDead() Then Return $FAIL
	Info('Casting hero monk bonds')
	; below loops ensure that player have the effect of 5 monk enchantments from monk hero and also monk hero have 1 enchantment - balthazar's spirit
	; last 2 enchantments are least important so these may deactivate when hero energy drops to 0, which is unlikely
	While GetEffect($ID_Balthazars_Spirit) == Null
		CastBondMargoniteFarm($Margonite_Hero_BalthazarSpirit, GetMyAgent())
	Wend
	While GetEffect($ID_Watchful_Spirit) == Null
		CastBondMargoniteFarm($Margonite_Hero_WatchfulSpirit, GetMyAgent())
	Wend
	While GetEffect($ID_Life_Barrier) == Null
		CastBondMargoniteFarm($Margonite_Hero_LifeBarrier, GetMyAgent())
	Wend
	While GetEffect($ID_Life_Bond) == Null
		CastBondMargoniteFarm($Margonite_Hero_LifeBond, GetMyAgent())
	Wend
	While GetEffect($ID_Vital_Blessing) == Null
		CastBondMargoniteFarm($Margonite_Hero_VitalBLessing, GetMyAgent())
	Wend
	While GetEffect($ID_Balthazars_Spirit, $MargoniteHeroIndex) == Null
		CastBondMargoniteFarm($Margonite_Hero_BalthazarSpirit, $MargoniteHeroIndex)
	Wend
EndFunc


Func CastBondMargoniteFarm($bondSkill, $target)
	If IsPlayerDead() Then Return $FAIL

	; Casting new monk bond spell only when monk hero energy level is at least 85%
	While DllStructGetData(GetAgentByID($MargoniteHeroAgentID), 'EnergyPercent') < 0.85
		If TimerDiff($GemstoneMargoniteFarmTimer) > $MAX_GEMSTONE_MARGONITE_FARM_DURATION Then Return $FAIL
		UseHeroSkill($MargoniteHeroIndex, $Margonite_Hero_BlessedSignet) ; recover hero energy
		RandomSleep(5000)
	WEnd
	UseHeroSkill($MargoniteHeroIndex, $bondSkill, $target)
	Sleep(3500) ; 3,5 seconds wait-out to ensure monk enchantment got casted on target
EndFunc


Func WaitAggroMargonites($timeToWait)
	If IsPlayerDead() Then Return $FAIL
	Local $TimerAggro = TimerInit()
	While TimerDiff($TimerAggro) < $timeToWait
		If TimerDiff($GemstoneMargoniteFarmTimer) > $MAX_GEMSTONE_MARGONITE_FARM_DURATION Then Return $FAIL
		If IsPlayerDead() Then Return $FAIL
		MargoniteDefend()
		RandomSleep(50)
	WEnd
	Return $SUCCESS
EndFunc


Func MargoniteMoveDefending($destinationX, $destinationY)
	Local $result = Null
	If $MargonitePlayerProfession == $ID_Elementalist Then
		$result = MoveAvoidingBodyBlock($destinationX, $destinationY, $MargoniteMoveOptionsElementalist)
	Else
		$result = MoveAvoidingBodyBlock($destinationX, $destinationY, $MargoniteMoveOptions)
	EndIf
	If $result == $STUCK Then
		; When playing as Elementalist or other professions that don't have death's charge or heart of shadow skills, then fight Margonites whenever player got surrounded and stuck
		If KillMargonites() == $FAIL Then Return $FAIL
		RandomSleep(1000 + GetPing())
		If IsPlayerAlive() Then
			Info('Picking up loot')
			PickUpItems(MargoniteCheckSFBuffs, DefaultShouldPickItem, $RANGE_EARSHOT)
		EndIf
		If IsPlayerDead() Then Return $FAIL
	Else
		Return $result
	EndIf
EndFunc


Func MargoniteDefend()
	MargoniteCheckSFBuffs()
	MargoniteMonkHeroHeal()
EndFunc


Func MargoniteMonkHeroHeal()
	Local $MonkHero = GetAgentByID($MargoniteHeroAgentID)
	If IsRecharged($Margonite_Hero_TrollUnguent, $MargoniteHeroIndex) And _
			GetEnergy($MonkHero) > 10 And DllStructGetData($MonkHero, 'HealthPercent') < 1 And _
			GetEffect($ID_Troll_Unguent, $MargoniteHeroIndex) == Null Then
		UseHeroSkill($MargoniteHeroIndex, $Margonite_Hero_TrollUnguent)
	EndIf
EndFunc


Func MargoniteCheckSFBuffs()
	If IsPlayerDead() Then Return $FAIL

	; Margonites cast quickening zephyr spirit which halves skill recharge time but increases skill energy cost by 30% and
	; famine spirit which deals damage when energy is 0, therefore Shadow Form and buffs skills usage is adjusted accordingly below
	If $MargonitePlayerProfession <> $ID_Elementalist Then
		If IsRecharged($Margonite_ShadowForm) Then
			If GetEffect($ID_Quickening_Zephyr) == Null Then UseSkillEx($Margonite_DeadlyParadox)
			UseSkillEx($Margonite_ShadowForm)
		EndIf
		If IsRecharged($Margonite_ShroudOfDistress) And Not IsRecharged($Margonite_ShadowForm) And GetEnergy() > 14 Then UseSkillEx($Margonite_ShroudOfDistress)
	EndIf

	If $MargonitePlayerProfession == $ID_Assassin Then
		If IsRecharged($Margonite_Assasin_GreatDwarfArmor) And Not IsRecharged($Margonite_ShadowForm) And GetEnergy() > 8 And GetEffect($ID_Great_Dwarf_Armor) == Null Then UseSkillEx($Margonite_Assasin_GreatDwarfArmor)
	ElseIf $MargonitePlayerProfession == $ID_Mesmer Then
		If IsRecharged($Margonite_Mesmer_WayOfPerfection) And Not IsRecharged($Margonite_ShadowForm) And GetEnergy() > 8 And GetEffect($ID_Way_of_Perfection) == Null Then UseSkillEx($Margonite_Mesmer_WayOfPerfection)
	ElseIf $MargonitePlayerProfession == $ID_Elementalist Then
		MargoniteCheckBuffsElementalist()
	ElseIf $MargonitePlayerProfession == $ID_Ranger Then
		If IsRecharged($Margonite_Ranger_UnseenFury) And Not IsRecharged($Margonite_ShadowForm) And GetEffect($ID_Whirling_Defense) == Null Then UseSkillEx($Margonite_Ranger_UnseenFury)
	EndIf

	If IsRecharged($Margonite_IAmUnstoppable) And GetEnergy() > 8 Then UseSkillEx($Margonite_IAmUnstoppable)
	Local $target = GetNearestEnemyToAgent(GetMyAgent())
	ChangeTarget($target)
	If IsRecharged($Margonite_DeathsCharge) And Not IsRecharged($Margonite_ShadowForm) and GetDistance(GetMyAgent(), $target) < $Margonites_Range And DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.3 Then
		UseSkillEx($Margonite_DeathsCharge, $target)
		RandomSleep(1000)
	EndIf
	Return IsPlayerAlive()? $SUCCESS : $FAIL
EndFunc


Func MargoniteCheckBuffsElementalist()
	If TimerDiff($MargoniteElementalLordTimer) > 50000 And GetEnergy() > 8 Then
		UseSkillEx($Margonite_Elementalist_ElementalLord)
		$MargoniteElementalLordTimer = TimerInit()
	EndIf
	If TimerDiff($Margonite_Elementalist_AuraOfRestoration) > 50000 And GetEnergy() > 8 Then
		UseSkillEx($Margonite_Elementalist_AuraOfRestoration)
		$MargoniteAuraOfRestorationTimer = TimerInit()
	EndIf
	If IsRecharged($Margonite_Elementalist_ObsidianFlesh) And TimerDiff($MargoniteObsidianFleshTimer) > 14 Then
		While GetEnergy() < 8
			Sleep(100)
		WEnd
		UseSkillEx($Margonite_Elementalist_GlyphOfSwiftness)
		While GetEnergy() < 32
			Sleep(100)
		WEnd
		UseSkillEx($Margonite_Elementalist_ObsidianFlesh)
		$MargoniteObsidianFleshTimer = TimerInit()
	EndIf
	If IsRecharged($Margonite_Elementalist_StonefleshAura) And TimerDiff($MargoniteStonefleshAuraTimer) > 10000 And Not IsRecharged($Margonite_Elementalist_ObsidianFlesh) Then
		While GetEnergy() < 12
			Sleep(100)
		WEnd
		UseSkillEx($Margonite_Elementalist_StonefleshAura)
		$MargoniteStonefleshAuraTimer = TimerInit()
	EndIf
EndFunc


Func KillMargonites()
	If IsPlayerDead() Then Return $FAIL
	Info('Fighting margonites')
	If $MargonitePlayerProfession == $ID_Assassin Or $MargonitePlayerProfession == $ID_Mesmer Or $MargonitePlayerProfession == $ID_Elementalist Then
		KillMargonitesUsingVisageSkills()
	ElseIf $MargonitePlayerProfession == $ID_Ranger Then
		KillMargonitesUsingWhirlingDefense()
	EndIf
	Return IsPlayerAlive()? $SUCCESS : $FAIL
EndFunc


Func KillMargonitesUsingVisageSkills()
	If IsPlayerDead() Then Return $FAIL
	Local $TimerKill = TimerInit()
	Local Static $MaxFightTime = 100000 ; 100 seconds max fight time

	While CountFoesInRangeOfAgent(GetMyAgent(), $Margonites_Range) > 0 And TimerDiff($TimerKill) < $MaxFightTime And IsPlayerAlive() And Not GetIsDead(GetAgentByID($MargoniteHeroAgentID))
		RandomSleep(100)
		MargoniteDefend()

		If IsRecharged($Margonite_AncestorsVisage) And GetEffect($ID_Ancestors_Visage) == Null And GetEffect($ID_Sympathetic_Visage) == Null And GetEnergy() > 14 And _
				(($MargonitePlayerProfession <> $ID_Elementalist And Not IsRecharged($Margonite_ShadowForm)) Or ($MargonitePlayerProfession == $ID_Elementalist And Not IsRecharged($Margonite_Elementalist_ObsidianFlesh))) Then
			UseSkillEx($Margonite_AncestorsVisage)
		EndIf

		If $MargonitePlayerProfession == $ID_Elementalist Then
			If IsRecharged($Margonite_Elementalist_SympatheticVisage) And GetEffect($ID_Ancestors_Visage) == Null And GetEffect($ID_Sympathetic_Visage) == Null And _
					Not IsRecharged($Margonite_Elementalist_ObsidianFlesh) And GetEnergy() > 14 Then
				UseSkillEx($Margonite_Elementalist_SympatheticVisage)
			EndIf
		ElseIf $MargonitePlayerProfession == $ID_Assassin Or $MargonitePlayerProfession == $ID_Mesmer Then
			If IsRecharged($Margonite_LightbringersGaze) And Not IsRecharged($Margonite_ShadowForm) And GetEnergy() > 8 Then
				Local $target = GetNearestEnemyToAgent(GetMyAgent())
				If $target <> Null Then
					ChangeTarget($target)
					UseSkillEx($Margonite_LightbringersGaze, $target)
					RandomSleep(100)
				EndIf
			EndIf
		EndIf
	WEnd
EndFunc


Func KillMargonitesUsingWhirlingDefense()
	If IsPlayerDead() Then Return $FAIL
	Local $TimerKill = TimerInit()
	Local Static $MaxFightTime = 100000 ; 100 seconds max fight time

	While CountFoesInRangeOfAgent(GetMyAgent(), $Margonites_Range) > 0 And TimerDiff($TimerKill) < $MaxFightTime And IsPlayerAlive() And Not GetIsDead(GetAgentByID($MargoniteHeroAgentID))
		RandomSleep(100)
		MargoniteDefend()

		If IsRecharged($Margonite_Ranger_DwarvenStability) And Not IsRecharged($Margonite_ShadowForm) And GetEnergy() > 8 Then
			UseSkillEx($Margonite_Ranger_DwarvenStability)
			RandomSleep(100)
		EndIf
		If IsRecharged($Margonite_Ranger_WhirlingDefense) And Not IsRecharged($Margonite_ShadowForm) And GetEnergy() > 8 Then
			UseSkillEx($Margonite_Ranger_WhirlingDefense)
			RandomSleep(100)
		EndIf
	WEnd
EndFunc