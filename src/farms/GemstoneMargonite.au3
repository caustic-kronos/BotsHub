#CS ===========================================================================
=====================================
|	Margonite Gemstones Farm bot	|
|			TonReuf					|
=====================================
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

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

#Region Configuration
; === Build ===
;Global Const $AME_MARGONITE_SKILLBAR = 'OwVT4nPHYiHRn5AiVE3hm0DSEAA'
Global Const $AME_MARGONITE_SKILLBAR = 'OwVT4nPHYiHRn5AiVE3hm0D6iD'
;Global Const $MEA_MARGONITE_SKILLBAR = 'OQdTA0A+ZiHRn5AiAC3hm0DSEA'
Global Const $MEA_MARGONITE_SKILLBAR = 'OQdTAmA/ZiHRn5AiAC3hm0DyiD'
Global Const $EME_MARGONITE_SKILLBAR = 'OgVUEQkkYmSSfaDfVug0C0keQiAA'
Global Const $RA_MARGONITE_SKILLBAR = 'OgcTcZ/8ZiHRn5AKCC3hm8uU4A'
Global Const $MARGONITE_MONK_HERO_SKILLBAR = 'OwITAnHb5Qe/zhxLkpE6+G'
;Global Const $MARGONITE_MONK_HERO_SKILLBAR = 'OwITAnHb5Qe/zhx7jpE6+G'

; You can select which monk hero to use in the farm here, among 3 heroes available. Uncomment below line for hero to use
; party hero ID that is used to add hero to the party team
;Global Const $MARGONITE_HERO_PARTY_ID = $ID_DUNKORO
;Global Const $MARGONITE_HERO_PARTY_ID = $ID_TAHLKORA
Global Const $MARGONITE_HERO_PARTY_ID = $ID_OGDEN
Global Const $MARGONITE_HERO_INDEX = 1

Global Const $MARGONITE_DEADLY_PARADOX		= 1
Global Const $MARGONITE_SHADOWFORM			= 2
Global Const $MARGONITE_SHROUD_OF_DISTRESS	= 3
Global Const $MARGONITE_DEATHS_CHARGE		= 5
Global Const $MARGONITE_I_AM_UNSTOPPABLE	= 6
Global Const $MARGONITE_ANCESTORS_VISAGE	= 7
Global Const $MARGONITE_LIGHTBRINGERS_GAZE	= 8
; Margonites always create Quickening Zephyr spirit which halves recharge time of spells
; Therefore Ancestor's visage recharges after 10 seconds which is basically equal to 9-10 seconds duration with illusion magic attribute equal to 12-14
; So Sympathetic Visage is replaced here with Lightbringer's Gaze, which also should recharge 2x faster, to increase damage rate
; Deadly Paradox skill could also be potentially removed because of Quickening Zephyr spirit

Global Const $MARGONITE_ASSASSIN_GREAT_DWARF_ARMOR			= 4

Global Const $MARGONITE_MESMER_WAY_OF_PERFECTION			= 4

Global Const $MARGONITE_ELEMENTALIST_GLYPH_OF_SWIFTNESS		= 1
Global Const $MARGONITE_ELEMENTALIST_OBSIDIAN_FLESH			= 2
Global Const $MARGONITE_ELEMENTALIST_STONEFLESH_AURA		= 3
Global Const $MARGONITE_ELEMENTALIST_ELEMENTAL_LORD			= 4
Global Const $MARGONITE_ELEMENTALIST_AURA_OF_RESTORATION	= 5
Global Const $MARGONITE_ELEMENTALIST_SYMPATHETICVISAGE		= 8

Global Const $MARGONITE_RANGER_UNSEEN_FURY			= 4
Global Const $MARGONITE_RANGER_DWARVEN_STABILITY	= 7
Global Const $MARGONITE_RANGER_WHIRLING_DEFENSE		= 8

; Monk protector hero
Global Const $MARGONITE_HERO_BALTHAZAR_SPIRIT	= 1
Global Const $MARGONITE_HERO_WATCHFUL_SPIRIT	= 2
Global Const $MARGONITE_HERO_LIFE_BARRIER		= 3
Global Const $MARGONITE_HERO_LIFE_BOND			= 4
Global Const $MARGONITE_HERO_VITAL_BLESSING		= 5
Global Const $MARGONITE_HERO_BLESSED_SIGNET		= 6
Global Const $MARGONITE_HERO_EDGE_OF_EXTINCTION	= 7
Global Const $MARGONITE_HERO_TROLL_UNGUENT		= 8
#EndRegion Configuration

; ==== Constants ====
Global Const $GEMSTONE_MARGONITE_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
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
Global Const $MARGONITES_RANGE = 800

Global $margonite_move_options = CloneDictMap($Default_MoveDefend_Options)
$margonite_move_options.Item('defendFunction')		= MargoniteDefend
$margonite_move_options.Item('moveTimeOut')			= 100 * 1000
$margonite_move_options.Item('randomFactor')			= 25
$margonite_move_options.Item('hosSkillSlot')			= 0
$margonite_move_options.Item('deathChargeSkillSlot')	= $MARGONITE_DEATHS_CHARGE
$margonite_move_options.Item('openChests')			= False

Global $margonite_move_options_elementalist = CloneDictMap($margonite_move_options)
$margonite_move_options_elementalist.Item('deathChargeSkillSlot') = 0

Global $margonite_obsidian_flesh_timer		= TimerInit()
Global $margonite_stoneflesh_aura_timer		= TimerInit()
Global $margonite_elemental_lord_timer		= TimerInit()
Global $margonite_aura_of_restoration_timer	= TimerInit()

Global $margonite_player_profession = $ID_MESMER
Global $gemstone_margonite_farm_setup = False

;~ Main loop function for farming margonite gemstones
Func GemstoneMargoniteFarm()
	If Not $gemstone_margonite_farm_setup And SetupGemstoneMargoniteFarm() == $FAIL Then Return $PAUSE

	If GoToCityOfTorcqua() == $FAIL Then Return $FAIL
	Local $result = GemstoneMargoniteFarmLoop()
	If $result == $SUCCESS Then
		Info('Successfully cleared margonite mobs')
	ElseIf $result == $FAIL Then
		If IsPlayerDead() Then Warn('Player died')
		If IsHeroDead($MARGONITE_HERO_INDEX) Then Warn('monk hero died')
		Info('Could not clear margonite mobs')
	EndIf
	Info('Returning back to the outpost')
	ResignAndReturnToOutpost()
	Return $result
EndFunc


Func SetupGemstoneMargoniteFarm()
	Info('Setting up farm')
	; 4 DoA farm areas have the same map ID as Gate of Anguish outpost (474)
	If GetMapID() <> $ID_GATE_OF_ANGUISH Then
		If TravelToOutpost($ID_GATE_OF_ANGUISH, $district_name) == $FAIL Then Return $FAIL
	Else
		ResignAndReturnToOutpost()
	EndIf
	SwitchToHardModeIfEnabled()
	Sleep(500 + GetPing())
	SetDisplayedTitle($ID_LIGHTBRINGER_TITLE)
	Sleep(500 + GetPing())
	If SetupPlayerMargoniteFarm() == $FAIL Then Return $FAIL
	If SetupTeamMargoniteFarm() == $FAIL Then Return $FAIL
	Sleep(500 + GetPing())
	$gemstone_margonite_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerMargoniteFarm()
	Info('Setting up player build skill bar')
	Switch DllStructGetData(GetMyAgent(), 'Primary')
		Case $ID_ASSASSIN
			$margonite_player_profession = $ID_ASSASSIN
			LoadSkillTemplate($AME_MARGONITE_SKILLBAR)
		Case $ID_MESMER
			$margonite_player_profession = $ID_MESMER
			LoadSkillTemplate($MEA_MARGONITE_SKILLBAR)
		Case $ID_ELEMENTALIST
			$margonite_player_profession = $ID_ELEMENTALIST
			LoadSkillTemplate($EME_MARGONITE_SKILLBAR)
		Case $ID_RANGER
			$margonite_player_profession = $ID_RANGER
			LoadSkillTemplate($RA_MARGONITE_SKILLBAR)
		Case Else
			Warn('You need to run this farm bot as Assassin or Mesmer or Elementalist or Ranger')
			Return $FAIL
	EndSwitch
	Sleep(250 + GetPing())
	Return $SUCCESS
EndFunc


Func SetupTeamMargoniteFarm()
	Info('Setting up team')
	LeaveParty()
	Sleep(500 + GetPing())
	AddHero($MARGONITE_HERO_PARTY_ID)
	Sleep(500 + GetPing())
	If GetPartySize() <> 2 Then
		Warn('Could not add monk hero to team. Team size different than 2')
		Return $FAIL
	EndIf
	Sleep(250 + GetPing())
	Info('Setting up hero build skill bar')
	LoadSkillTemplate($MARGONITE_MONK_HERO_SKILLBAR, $MARGONITE_HERO_INDEX)
	Sleep(250 + GetPing())
	SetHeroBehaviour($MARGONITE_HERO_INDEX, $ID_HERO_AVOIDING)
	Sleep(250 + GetPing())
	DisableAllHeroSkills($MARGONITE_HERO_INDEX)
	Sleep(250 + GetPing())
	Return $SUCCESS
EndFunc


Func EnableMargoniteHeroSkills()
	EnableHeroSkillSlot($MARGONITE_HERO_INDEX, $MARGONITE_HERO_BLESSED_SIGNET)
	Sleep(25 + GetPing())
	EnableHeroSkillSlot($MARGONITE_HERO_INDEX, $MARGONITE_HERO_TROLL_UNGUENT)
	Sleep(25 + GetPing())
EndFunc


;~ Exit gate of Anguish outpost by moving into portal that leads into farming location - City of Torc'qua
Func GoToCityOfTorcqua()
	TravelToOutpost($ID_GATE_OF_ANGUISH, $district_name)
	Info('Moving to City of Torc''qua')
	; Unfortunately all 4 gemstone farm explorable locations have the same map ID as Gate of Anguish outpost, so it is harder to tell if player left the outpost
	; Therefore below loop checks if player is in close range of coordinates of that start zone where player initially spawns in City of Torc'qua
	Local Static $StartX = -18575
	Local Static $StartY = -8833
	Local $TimerZoning = TimerInit()
	While Not IsAgentInRange(GetMyAgent(), $StartX, $StartY, $RANGE_EARSHOT)
		If TimerDiff($TimerZoning) > 120000 Then
			Info('Could not zone to City of Torc''qua')
			Return $FAIL
		EndIf
		MoveTo(6816, -13634)
		MoveTo(8258, -10419)
		MoveTo(10180, -10714)
		Move(11250, -11350, 0)
		Sleep(8000)
	WEnd
EndFunc


Func CastBondsMargoniteFarm()
	Info('Casting hero monk bonds')
	; Below sequence ensures that player have the effect of 5 monk enchantments from monk hero and also monk hero have 1 enchantment - balthazar's spirit
	; Last 2 enchantments are least important so these may deactivate when hero energy drops to 0, which is unlikely
	; Disable blessed signet hero skill so that hero doesn't mess up below sequence with using that skill in wrong moment
	DisableHeroSkillSlot($MARGONITE_HERO_INDEX, $MARGONITE_HERO_BLESSED_SIGNET)
	Sleep(25 + GetPing())

	UseHeroSkillTimed($MARGONITE_HERO_INDEX, $MARGONITE_HERO_BALTHAZAR_SPIRIT, GetMyAgent())	; costs 10 energy
	Sleep(10000)																			; wait until energy is recovered, should recover 10 energy with 3 energy pips
	UseHeroSkillTimed($MARGONITE_HERO_INDEX, $MARGONITE_HERO_WATCHFUL_SPIRIT, GetMyAgent())	; costs 15 energy
	UseHeroSkillTimed($MARGONITE_HERO_INDEX, $MARGONITE_HERO_BLESSED_SIGNET)					; recover 6 hero energy
	Sleep(12000)																			; wait until Blessed signet is recharged, should recover 8 energy with 2 energy pips
	UseHeroSkillTimed($MARGONITE_HERO_INDEX, $MARGONITE_HERO_LIFE_BARRIER, GetMyAgent())		; costs 15 energy, 1 energy should be recovered during casting, energy should be maxed
	UseHeroSkillTimed($MARGONITE_HERO_INDEX, $MARGONITE_HERO_BLESSED_SIGNET)					; recover 9 hero energy
	Sleep(15000)																			; wait until Blessed signet is recharged, should recover 5 energy with 1 energy pip
	UseHeroSkillTimed($MARGONITE_HERO_INDEX, $MARGONITE_HERO_LIFE_BOND, GetMyAgent())			; costs 10 energy
	UseHeroSkillTimed($MARGONITE_HERO_INDEX, $MARGONITE_HERO_BLESSED_SIGNET)					; recover 11 hero energy, energy should be maxed
	Sleep(10000)																			; wait until Blessed signet is recharged, 0 pips
	UseHeroSkillTimed($MARGONITE_HERO_INDEX, $MARGONITE_HERO_VITAL_BLESSING, GetMyAgent())		; costs 10 energy
	UseHeroSkillTimed($MARGONITE_HERO_INDEX, $MARGONITE_HERO_BLESSED_SIGNET)					; recover 11 hero energy
	Sleep(10000)																			; wait until Blessed signet is recharged, around 3 energy lost with -1 pip
	UseHeroSkillTimed($MARGONITE_HERO_INDEX, $MARGONITE_HERO_BALTHAZAR_SPIRIT)					; costs 10 energy
	UseHeroSkillTimed($MARGONITE_HERO_INDEX, $MARGONITE_HERO_BLESSED_SIGNET)					; recover 11 hero energy, -2 pips, but energy will be recovered soon with balthazar's spirit

	; Enable blessed signet skill so that hero uses it whenever it is recharged
	EnableHeroSkillSlot($MARGONITE_HERO_INDEX, $MARGONITE_HERO_BLESSED_SIGNET)
	Sleep(25 + GetPing())

	Return $SUCCESS
EndFunc


Func GemstoneMargoniteFarmLoop()
	Local $me = Null, $target = Null
	Info('Starting Farm')

	CommandHero($MARGONITE_HERO_INDEX, -18571, -9328)
	Sleep(2000)
	CastBondsMargoniteFarm()
	EnableMargoniteHeroSkills()
	If GetLightbringerTitle() < 50000 Then
		Info('Taking Blessing')
		GoNearestNPCToCoords(-17623, -9670)
		Sleep(1000)
		Dialog(0x85)
		Sleep(500)
	EndIf
	Info('Taking Quest')
	Local $TimerQuest = TimerInit()
	While GetQuestByID($ID_QUEST_THE_CITY_OF_TORC_QA) == Null And TimerDiff($TimerQuest) < 10000
		GoNearestNPCToCoords(-17710, -8811)
		Sleep(1000)
		Dialog(0x82EF01)
		Sleep(1000)
	WEnd
	If GetQuestByID($ID_QUEST_THE_CITY_OF_TORC_QA) == Null Then Return $FAIL

	Info('Moving to spot and aggroing margonites')
	MoveTo(-17541, -9431)
	If MargoniteMoveDefending(-13935, -9850) == $FAIL Then Return $FAIL
	CommandHero($MARGONITE_HERO_INDEX, -16878, -9571)
	If MargoniteMoveDefending(-14321, -11803) == $FAIL Then Return $FAIL
	If MargoniteMoveDefending(-12115, -11057) == $FAIL Then Return $FAIL
	CommandHero($MARGONITE_HERO_INDEX, -14879, -11729)
	WaitAggroMargonites(7000)
	; below is the furthest location player goes to pull front Margonite mobs but also not let rear margonite mobs leave player and kill monk hero
	If MargoniteMoveDefending(-10277, -10778) == $FAIL Then Return $FAIL
	CommandHero($MARGONITE_HERO_INDEX, -12861, -12620)
	; waiting for far margonite group to come into player's range
	WaitAggroMargonites(50000)
	If MargoniteMoveDefending(-12065, -10905) == $FAIL Then Return $FAIL
	WaitAggroMargonites(5000)
	If MargoniteMoveDefending(-12246, -10149) == $FAIL Then Return $FAIL
	WaitAggroMargonites(7000)
	If MargoniteMoveDefending(-12303, -10349) == $FAIL Then Return $FAIL
	If MargoniteMoveDefending(-11410, -11359) == $FAIL Then Return $FAIL
	WaitAggroMargonites(3000)
	If MargoniteMoveDefending(-11484, -11034) == $FAIL Then Return $FAIL
	If IsPlayerDead() Or IsHeroDead($MARGONITE_HERO_INDEX) Then Return $FAIL

	; if margonites group is somehow not in the spot then try to get closer to them
	; getting closer to nearest Anur Dabi or Kaya or Ki or Su, not nearest Vu, Ruk, Tuk
	$me = GetMyAgent()
	$target = GetNearestAgentToAgent($me, $ID_AGENT_TYPE_NPC, IsAnurDabiOrKayaOrKiOrSu)
	If $margonite_player_profession <> $ID_ELEMENTALIST Then
		If IsRecharged($MARGONITE_DEATHS_CHARGE)  Then
			UseSkillEx($MARGONITE_DEATHS_CHARGE, $target)
			RandomSleep(GetPing())
		EndIf
	EndIf
	MoveTo(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'))

	If KillMargonites() == $FAIL Then Return $FAIL
	RandomSleep(1000 + GetPing())
	If IsPlayerAlive() Then
		Info('Picking up loot')
		; Tripled to secure the looting of items
		For $i = 1 To 3
			PickUpItems(MargoniteCheckBuffs)
			Sleep(GetPing())
		Next
	EndIf

	Return $SUCCESS
EndFunc


Func IsAnurDabiOrKayaOrKiOrSu($agent)
	Local Static $AnurKaya	= 5166
	Local Static $AnurDabi	= 5167
	Local Static $AnurSu	= 5168
	Local Static $AnurKi	= 5169

	Return EnemyAgentFilter($agent) And _
		(DllStructGetData($agent, 'ModelID') == $AnurKaya Or _
		DllStructGetData($agent, 'ModelID') == $AnurDabi Or _
		DllStructGetData($agent, 'ModelID') == $AnurSu Or _
		DllStructGetData($agent, 'ModelID') == $AnurKi)
EndFunc


Func WaitAggroMargonites($timeToWait)
	Local $TimerAggro = TimerInit()
	While IsPlayerAlive() And TimerDiff($TimerAggro) < $timeToWait
		If CheckStuck('Waiting for margonites aggro', $MAX_GEMSTONE_MARGONITE_FARM_DURATION) == $FAIL Then Return $FAIL
		MargoniteDefend()
		RandomSleep(50)
	WEnd
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func MargoniteMoveDefending($destinationX, $destinationY)
	Local $result = Null
	Switch $margonite_player_profession
		Case $ID_ASSASSIN, $ID_MESMER, $ID_RANGER
			$result = MoveAvoidingBodyBlock($destinationX, $destinationY, $margonite_move_options)
		Case $ID_ELEMENTALIST
			$result = MoveAvoidingBodyBlock($destinationX, $destinationY, $margonite_move_options_elementalist)
	EndSwitch
	If $result == $STUCK Then
		; When playing as Elementalist or other professions that don't have death's charge or heart of shadow skills, then fight Margonites wherever player got surrounded and stuck
		If KillMargonites() == $FAIL Then Return $FAIL
		RandomSleep(1000 + GetPing())
		If IsPlayerAlive() Then
			Info('Picking up loot')
			; Tripled to secure the looting of items
			For $i = 1 To 3
				PickUpItems(MargoniteCheckBuffs)
				Sleep(GetPing())
			Next
			Return $SUCCESS
		Else
			Return $FAIL
		EndIf
	Else
		Return $result
	EndIf
EndFunc


Func MargoniteDefend()
	MargoniteCheckBuffs()
	MargoniteMonkHeroHeal()
EndFunc


Func MargoniteMonkHeroHeal()
	Local $MonkHero = GetAgentByID(GetHeroID($MARGONITE_HERO_INDEX))
	If IsRecharged($MARGONITE_HERO_TROLL_UNGUENT, $MARGONITE_HERO_INDEX) And _
			GetEnergy($MonkHero) > 10 And DllStructGetData($MonkHero, 'HealthPercent') < 1 And _
			GetEffect($ID_TROLL_UNGUENT, $MARGONITE_HERO_INDEX) == Null Then
		UseHeroSkill($MARGONITE_HERO_INDEX, $MARGONITE_HERO_TROLL_UNGUENT)
	EndIf
EndFunc


Func MargoniteCheckBuffs()
	Local $me = Null, $target = Null
	If IsPlayerDead() Then Return $FAIL

	; Margonites cast quickening zephyr spirit which halves skill recharge time but increases skill energy cost by 30% and
	; famine spirit which deals damage when energy is 0, therefore Shadow Form and buffs skills usage is adjusted accordingly below
	If $margonite_player_profession <> $ID_ELEMENTALIST Then
		If IsRecharged($MARGONITE_SHADOWFORM) Then
			If GetEffect($ID_QUICKENING_ZEPHYR) == Null Then UseSkillEx($MARGONITE_DEADLY_PARADOX)
			UseSkillEx($MARGONITE_SHADOWFORM)
		EndIf
		If IsRecharged($MARGONITE_SHROUD_OF_DISTRESS) And Not IsRecharged($MARGONITE_SHADOWFORM) And GetEnergy() > 14 Then UseSkillEx($MARGONITE_SHROUD_OF_DISTRESS)
	EndIf

	Switch $margonite_player_profession
		Case $ID_ASSASSIN
			If IsRecharged($MARGONITE_ASSASSIN_GREAT_DWARF_ARMOR) And Not IsRecharged($MARGONITE_SHADOWFORM) And GetEnergy() > 8 And GetEffect($ID_GREAT_DWARF_ARMOR) == Null Then UseSkillEx($MARGONITE_ASSASSIN_GREAT_DWARF_ARMOR)
		Case $ID_MESMER
			If IsRecharged($MARGONITE_MESMER_WAY_OF_PERFECTION) And Not IsRecharged($MARGONITE_SHADOWFORM) And GetEnergy() > 8 And GetEffect($ID_WAY_OF_PERFECTION) == Null Then UseSkillEx($MARGONITE_MESMER_WAY_OF_PERFECTION)
		Case $ID_ELEMENTALIST
			MargoniteCheckBuffsElementalist()
		Case $ID_RANGER
			If IsRecharged($MARGONITE_RANGER_UNSEEN_FURY) And Not IsRecharged($MARGONITE_SHADOWFORM) And GetEffect($ID_WHIRLING_DEFENSE) == Null Then UseSkillEx($MARGONITE_RANGER_UNSEEN_FURY)
	EndSwitch

	If IsRecharged($MARGONITE_I_AM_UNSTOPPABLE) And GetEnergy() > 8 Then UseSkillEx($MARGONITE_I_AM_UNSTOPPABLE)
	If $margonite_player_profession <> $ID_ELEMENTALIST Then
		$me = GetMyAgent()
		$target = GetNearestEnemyToAgent($me)
		If IsRecharged($MARGONITE_DEATHS_CHARGE) And Not IsRecharged($MARGONITE_SHADOWFORM) And _
				GetDistance($me, $target) < $MARGONITES_RANGE And DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.3 Then
			ChangeTarget($target)
			UseSkillEx($MARGONITE_DEATHS_CHARGE, $target)
			RandomSleep(GetPing())
		EndIf
	EndIf
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func MargoniteCheckBuffsElementalist()
	If TimerDiff($margonite_elemental_lord_timer) > 50000 And GetEnergy() > 8 Then
		UseSkillEx($MARGONITE_ELEMENTALIST_ELEMENTAL_LORD)
		$margonite_elemental_lord_timer = TimerInit()
	EndIf
	If TimerDiff($MARGONITE_ELEMENTALIST_AURA_OF_RESTORATION) > 50000 And GetEnergy() > 8 Then
		UseSkillEx($MARGONITE_ELEMENTALIST_AURA_OF_RESTORATION)
		$margonite_aura_of_restoration_timer = TimerInit()
	EndIf
	If IsRecharged($MARGONITE_ELEMENTALIST_OBSIDIAN_FLESH) And TimerDiff($margonite_obsidian_flesh_timer) > 14 Then
		While GetEnergy() < 8
			Sleep(100)
		WEnd
		UseSkillEx($MARGONITE_ELEMENTALIST_GLYPH_OF_SWIFTNESS)
		While GetEnergy() < 32
			Sleep(100)
		WEnd
		UseSkillEx($MARGONITE_ELEMENTALIST_OBSIDIAN_FLESH)
		$margonite_obsidian_flesh_timer = TimerInit()
	EndIf
	If IsRecharged($MARGONITE_ELEMENTALIST_STONEFLESH_AURA) And TimerDiff($margonite_stoneflesh_aura_timer) > 10000 And Not IsRecharged($MARGONITE_ELEMENTALIST_OBSIDIAN_FLESH) Then
		While GetEnergy() < 12
			Sleep(100)
		WEnd
		UseSkillEx($MARGONITE_ELEMENTALIST_STONEFLESH_AURA)
		$margonite_stoneflesh_aura_timer = TimerInit()
	EndIf
EndFunc


Func KillMargonites()
	Info('Fighting margonites')
	UseHeroSkill($MARGONITE_HERO_INDEX, $MARGONITE_HERO_EDGE_OF_EXTINCTION)
	Switch $margonite_player_profession
		Case $ID_ASSASSIN, $ID_MESMER, $ID_ELEMENTALIST
			KillMargonitesUsingVisageSkills()
		Case $ID_RANGER
			KillMargonitesUsingWhirlingDefense()
	EndSwitch
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func KillMargonitesUsingVisageSkills()
	If IsPlayerDead() Then Return $FAIL
	Local $TimerKill = TimerInit()
	Local Static $MaxFightTime = 100000

	While CountFoesInRangeOfAgent(GetMyAgent(), $MARGONITES_RANGE) > 0 And TimerDiff($TimerKill) < $MaxFightTime And IsPlayerAlive() And Not IsHeroDead($MARGONITE_HERO_INDEX)
		RandomSleep(100)
		MargoniteDefend()

		If IsRecharged($MARGONITE_ANCESTORS_VISAGE) And GetEffect($ID_ANCESTORS_VISAGE) == Null And GetEffect($ID_SYMPATHETIC_VISAGE) == Null And GetEnergy() > 14 And _
				(($margonite_player_profession <> $ID_ELEMENTALIST And Not IsRecharged($MARGONITE_SHADOWFORM)) Or ($margonite_player_profession == $ID_ELEMENTALIST And Not IsRecharged($MARGONITE_ELEMENTALIST_OBSIDIAN_FLESH))) Then
			UseSkillEx($MARGONITE_ANCESTORS_VISAGE)
		EndIf

		Switch $margonite_player_profession
			Case $ID_ELEMENTALIST
				If IsRecharged($MARGONITE_ELEMENTALIST_SYMPATHETICVISAGE) And GetEffect($ID_ANCESTORS_VISAGE) == Null And GetEffect($ID_SYMPATHETIC_VISAGE) == Null And _
						Not IsRecharged($MARGONITE_ELEMENTALIST_OBSIDIAN_FLESH) And GetEnergy() > 14 Then
					UseSkillEx($MARGONITE_ELEMENTALIST_SYMPATHETICVISAGE)
				EndIf
			Case $ID_ASSASSIN, $ID_MESMER
				; Use lightbringer's gaze or other skill for optimization, because quickening zephyr makes Ancestor's Visage duration basically equal to recharge time
				If IsRecharged($MARGONITE_LIGHTBRINGERS_GAZE) And Not IsRecharged($MARGONITE_SHADOWFORM) And GetEnergy() > 8 Then
					Local $target = GetNearestEnemyToAgent(GetMyAgent())
					If $target <> Null Then
						ChangeTarget($target)
						UseSkillEx($MARGONITE_LIGHTBRINGERS_GAZE, $target)
						RandomSleep(100)
					EndIf
				EndIf
		EndSwitch
	WEnd
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func KillMargonitesUsingWhirlingDefense()
	If IsPlayerDead() Then Return $FAIL
	Local $TimerKill = TimerInit()
	Local Static $MaxFightTime = 100000

	While CountFoesInRangeOfAgent(GetMyAgent(), $MARGONITES_RANGE) > 0 And TimerDiff($TimerKill) < $MaxFightTime And IsPlayerAlive() And Not IsHeroDead($MARGONITE_HERO_INDEX)
		RandomSleep(100)
		MargoniteDefend()

		If IsRecharged($MARGONITE_RANGER_DWARVEN_STABILITY) And Not IsRecharged($MARGONITE_SHADOWFORM) And GetEnergy() > 8 Then
			UseSkillEx($MARGONITE_RANGER_DWARVEN_STABILITY)
			RandomSleep(100)
		EndIf
		If IsRecharged($MARGONITE_RANGER_WHIRLING_DEFENSE) And Not IsRecharged($MARGONITE_SHADOWFORM) And GetEnergy() > 8 Then
			UseSkillEx($MARGONITE_RANGER_WHIRLING_DEFENSE)
			RandomSleep(100)
		EndIf
	WEnd
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc