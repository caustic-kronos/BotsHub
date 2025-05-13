#CS
#################################
#								#
#	Raptor Bot
#								#
#################################
Author: Rattiev
Based on : Vaettir Bot by gigi
Modified by: Night
#CE

#include-once
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

; Possible improvements :
; - Update movements to be depending on raptors positions to make sure almost all raptors are aggroed (especially boss group)
; - Make rubberbanding function using foes positions (if foes are mostly not around you then you're rubberbanding)
; - Add heroes and use Edge of Extinction ? A bit unnecessary, will do if bored
; - Optimise first cast of MoP to be made on first target that enters aggro (might be making farm worse : right now MoP is cast quite late which is good)
; - Use pumpkin pie slices ? Reduce cast time and increase attack speed reducing chances to be interrupted during MoP or Whirlwind


Opt('MustDeclareVars', 1)

Global Const $RaptorBotVersion = '0.4'

; ==== Constantes ====
Global Const $WNRaptorFarmerSkillbar = 'OQQUc4oQt6SWC0kqM5F9Fja7grFA'
Global Const $DNRaptorFarmerSkillbar = 'OQQTcYqVXySgmUlJvovYUbHctAA'	;Doesn't work, dervish just takes too much damage
Global Const $PRunnerHeroSkillbar = 'OQijEqmMKODbe8O2Efjrx0bWMA'
Global Const $RaptorsFarmInformations = 'For best results, have :' & @CRLF _
	& '- 12 in curses' & @CRLF _
	& '- 12+ in tactics' & @CRLF _
	& '- 9+ in swordsmanship (enough to use your sword)'& @CRLF _
	& '- A Tactics shield with the inscription Through Thick and Thin (+10 armor against Piercing damage)' & @CRLF _
	& '- A sword of Shelter, prefix and inscription do not matter' & @CRLF _
	& '- Knight insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune' & @CRLF _
	& '- A superior Absorption rune' & @CRLF _
	& '- General Morgahn with 16 in Command, 10 in restoration and the rest in Leadership' & @CRLF _
	& '		and all of his skills locked'
; Average duration ~ 1m10s ~ First run is 1m30s with setup
Global Const $RAPTORS_FARM_DURATION = (1 * 60 + 20) * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($Raptors_MarkOfPain) is better than UseSkillEx(1))
Global Const $Raptors_MarkOfPain = 1
Global Const $Raptors_IAmUnstoppable = 2
Global Const $Raptors_ProtectorsDefense = 3
Global Const $Raptors_WaryStance = 4
Global Const $Raptors_HundredBlades = 5
Global Const $Raptors_SoldiersDefense = 6
Global Const $Raptors_WhirlwindAttack = 7
Global Const $Raptors_ShieldBash = 8

Global Const $Raptors_SignetOfMysticSpeed = 2
Global Const $Raptors_MirageCloak = 3
Global Const $Raptors_VowOfStrength = 4
Global Const $Raptors_ArmorOfSanctity = 5
Global Const $Raptors_DustCloak = 6
Global Const $Raptors_PiousFury = 7
Global Const $Raptors_EremitesAttack = 8

; Hero Build
Global Const $Raptors_VocalWasSogolon = 1
Global Const $Raptors_Incoming = 2
Global Const $Raptors_FallBack = 3
Global Const $Raptors_EnduringHarmony = 4
Global Const $Raptors_MakeHaste = 5
Global Const $Raptors_StandYourGround = 6
Global Const $Raptors_CantTouchThis = 7
Global Const $Raptors_BladeturnRefrain = 8

Global $RAPTORS_FARM_SETUP = False
Global $RAPTORS_PROFESSION = 1
Global $chatStuckTimer = TimerInit()

;~ Main method to farm Raptors
Func RaptorFarm($STATUS)
	If GetMapID() <> $ID_Rata_Sum Then DistrictTravel($ID_Rata_Sum, $DISTRICT_NAME)

	$RAPTORS_PROFESSION = GetHeroProfession(0)		;Gets our own profession
	If $RAPTORS_PROFESSION <> 1 And $RAPTORS_PROFESSION <> 10 Then Return 2
	If Not $RAPTORS_FARM_SETUP Then SetupRaptorFarm()
	If $STATUS <> 'RUNNING' Then Return 2

	Return RaptorsFarmLoop()
EndFunc


;~ Setup the Raptor farm for faster farm
Func SetupRaptorFarm()
	Info('Setting up farm')
	SetDisplayedTitle($ID_Asura_Title)
	SwitchMode($ID_HARD_MODE)
	AddHero($ID_General_Morgahn)
	LoadSkillTemplate($WNRaptorFarmerSkillbar)
	LoadSkillTemplate($PRunnerHeroSkillbar, 1)
	DisableAllHeroSkills(1)
	MoveTo(19649, 16791)
	Move(20084, 16854)
	RndSleep(1000)
	WaitMapLoading($ID_Riven_Earth, 10000, 2000)
	Move(-26309, -4112)
	RndSleep(1000)
	WaitMapLoading($ID_Rata_Sum, 10000, 2000)
	$RAPTORS_FARM_SETUP = True
	Info('Resign preparation complete')
EndFunc


;~ Farm loop
Func RaptorsFarmLoop()
	Info('Exiting to Riven Earth')
	Move(20084, 16854)
	RndSleep(1000)
	WaitMapLoading($ID_Riven_Earth, 10000, 2000)
	UseHeroSkill(1, $Raptors_VocalWasSogolon)
	RndSleep(1200)
	UseHeroSkill(1, $Raptors_Incoming)
	GetBlessing()
	MoveToBaseOfCave()
	Info('Moving Hero away')
	CommandAll(-25309, -4212)
	GetRaptors()
	KillRaptors()
	RndSleep(1000)

	Info('Looting')
	PickUpItems(DefendWhilePickingUpItems)
	RndSleep(1000)
	PickUpItems(DefendWhilePickingUpItems)

	Return BackToTown()
EndFunc


;~ Defend skills to use while looting in case some mobs are still alive
Func DefendWhilePickingUpItems()
	If $RAPTORS_PROFESSION == 1 Then
		If GetEnergy() > 5 And IsRecharged($Raptors_IAmUnstoppable) Then UseSkillEx($Raptors_IAmUnstoppable)
		If GetEnergy() > 5 And IsRecharged($Raptors_ShieldBash) Then UseSkillEx($Raptors_ShieldBash)
		If GetEnergy() > 5 And IsRecharged($Raptors_SoldiersDefense) Then
			UseSkillEx($Raptors_SoldiersDefense)
		ElseIf GetEnergy() > 10 And IsRecharged($Raptors_WaryStance) Then
			UseSkillEx($Raptors_WaryStance)
		EndIf
	Else
		If GetEnergy() > 6 And IsRecharged($Raptors_MirageCloak) Then UseSkillEx($Raptors_MirageCloak)
		If GetEnergy() > 3 And IsRecharged($Raptors_ArmorOfSanctity) Then UseSkillEx($Raptors_ArmorOfSanctity)
	EndIf
EndFunc


;~ Get Asura blessing only if title is not maxed yet
Func GetBlessing()
	Local $Asura = GetAsuraTitle()
	If $Asura < 160000 Then
		Info('Getting asura title blessing')
		GoNearestNPCToCoords(-20000, 3000)
		RndSleep(300)
		Dialog(132)
	EndIf
	RndSleep(350)
EndFunc


;~ Move to the entrance of the raptors cave
Func MoveToBaseOfCave()
	If GetIsDead(-2) Then Return
	Info('Moving to Cave')
	Move(-22015, -7502)
	RndSleep(7000)
	UseHeroSkill(1, $Raptors_FallBack)
	RndSleep(500)
	If ($RAPTORS_PROFESSION == 1) Then UseSkillEx($Raptors_IAmUnstoppable)
	Moveto(-21333, -8384)
	UseHeroSkill(1, $Raptors_EnduringHarmony, GetMyAgent())
	If ($RAPTORS_PROFESSION == 10) Then UseSkill($Raptors_SignetOfMysticSpeed, GetMyAgent())
	RndSleep(1800)
	UseHeroSkill(1, $Raptors_MakeHaste, GetMyAgent())
	RndSleep(20)
	UseHeroSkill(1, $Raptors_StandYourGround)
	RndSleep(20)
	UseHeroSkill(1, $Raptors_CantTouchThis)
	RndSleep(20)
	UseHeroSkill(1, $Raptors_BladeturnRefrain, GetMyAgent())
	Move(-20930, -9480, 40)
EndFunc


;~ Aggro all raptors
Func GetRaptors()
	Info('Gathering Raptors')

	Move(-20695, -9900, 20)
	; Using the nearest to agent could result in targeting Angorodon if they are badly placed
	Local $target = GetNearestEnemyToCoords(-20042, -10251)

	If ($RAPTORS_PROFESSION == 1) Then UseSkillEx($Raptors_ShieldBash)

	Local $count = 0
	While Not GetIsDead() And IsRecharged($Raptors_MarkOfPain) And $count < 200
		UseSkillEx($Raptors_MarkOfPain, $target)
		RndSleep(50)
		$count += 1
	WEnd
	RndSleep(250)

	IsBossAggroed()
	If MoveAggroingRaptors(-20000, -10300) Then Return
	If MoveAggroingRaptors(-19500, -11500) Then Return
	If MoveAggroingRaptors(-20500, -12000) Then Return
	If MoveAggroingRaptors(-21000, -12200) Then Return
	If MoveAggroingRaptors(-21500, -12000) Then Return
	If MoveAggroingRaptors(-22000, -12000) Then Return
	$target = GetNearestEnemyToAgent(GetMyAgent())
	If $RAPTORS_PROFESSION == 10 Then UseSkillEx($Raptors_MirageCloak)
	If Not IsBossAggroed() And MoveAggroingRaptors(-22300, -12000) Then Return
	If Not IsBossAggroed() And MoveAggroingRaptors(-22600, -12000) Then Return
	If IsBossAggroed() Then
		If MoveAggroingRaptors(-22400, -12400) Then Return
	Else
		If MoveAggroingRaptors(-23300, -12050) Then Return
	EndIf
EndFunc


;~ Returns true if the nearest boss is aggroed. Require being called once before the boss is aggroed.
Func IsBossAggroed()
	Local $boss = GetNearestBossFoe()
	Local Static $unaggroedState = DllStructGetData($boss, 'TypeMap')
	Return DllStructGetData($boss, 'TypeMap') <> $unaggroedState
EndFunc


;~ Kill raptors
Func KillRaptors()
	Local $MoPTarget
	If GetIsDead() Then Return
	Info('Clearing Raptors')

	If ($RAPTORS_PROFESSION == 1) Then
		If IsRecharged($Raptors_IAmUnstoppable) Then UseSkillEx($Raptors_IAmUnstoppable)
		RndSleep(20)
		UseSkillEx($Raptors_ProtectorsDefense)
		RndSleep(20)
		UseSkillEx($Raptors_HundredBlades)
		RndSleep(20)
		UseSkillEx($Raptors_WaryStance)
		RndSleep(20)
	Else
		UseSkillEx($Raptors_VowOfStrength)
		RndSleep(20)
		UseSkillEx($Raptors_ArmorOfSanctity)
		RndSleep(20)
	EndIf

	Local $rekoff_boss = GetNearestBossFoe()
	Local $me = GetMyAgent()
	If GetDistance($me, $rekoff_boss) > $RANGE_SPELLCAST Then
		$MoPTarget = GetNearestEnemyToAgent($me)
	Else
		$MoPTarget = GetNearestEnemyToAgent($rekoff_boss)
	EndIf

	If GetHasHex($MoPTarget) Then
		TargetNextEnemy()
		$MoPTarget = GetCurrentTarget()
	EndIf

	If ($RAPTORS_PROFESSION == 10) Then
		UseSkillEx($Raptors_DustCloak)
		RndSleep(20)
		UseSkillEx($Raptors_PiousFury)
		RndSleep(20)
	EndIf

	Debug('Waiting on MoP to be recharged and foes to be in range')
	Local $count = 0
	While Not GetIsDead() And (Not IsRecharged($Raptors_MarkOfPain) Or Not RaptorsAreBalled()) And $count < 40
		Debug('Waiting ' & $count)
		RndSleep(250)
		$count += 1
		If $count > 10 Then
			SendStuckCommand()
		EndIf
	WEnd

	Debug('Using MoP')
	$count = 0
	Local $timer = TimerInit()
	; There is an issue here with infinite loop despite the count (wtf!) so added a timer as well
	While Not GetIsDead() And IsRecharged($Raptors_MarkOfPain) And $count < 200 And TimerDiff($timer) < 10000
		UseSkillEx($Raptors_MarkOfPain, $MoPTarget)
		RndSleep(50)
		$count += 1
	WEnd

	If ($RAPTORS_PROFESSION == 1) Then
		If IsRecharged($Raptors_IAmUnstoppable) Then UseSkillEx($Raptors_IAmUnstoppable)
		UseSkillEx($Raptors_SoldiersDefense)
		RndSleep(50)

		Debug('Using Whirlwind attack')
		$count = 0
		While Not GetIsDead() And GetSkillbarSkillAdrenaline($Raptors_WhirlwindAttack) <> 130 And $count < 200
			RndSleep(50)
			$count += 1
		WEnd

		Local $me = GetMyAgent()
		Info('Spiking ' & CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) & ' raptors')
		UseSkillEx($Raptors_ShieldBash)
		RndSleep(20)
		Debug('Using Whirlwind attack a second time')
		While Not GetIsDead() And CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) > 10 And GetSkillbarSkillAdrenaline($Raptors_WhirlwindAttack) == 130
			UseSkillEx($Raptors_WhirlwindAttack, GetNearestEnemyToAgent($me))
			RndSleep(250)
			$me = GetMyAgent()
		WEnd
	Else
		Info('Spiking ' & CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) & ' raptors')
		While Not GetIsDead() And CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) > 10
			UseSkillEx($Raptors_EremitesAttack, GetNearestEnemyToAgent($me))
			RndSleep(250)
			$me = GetMyAgent()
		WEnd
	EndIf
EndFunc


;~ Mobs are sufficiently balled
Func RaptorsAreBalled()
	; Tolerance 2 : we accept that maximum 2 foes are still out of the ball
	Return CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA) >= CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) - 2
EndFunc

;~ Return to Rata Sum
Func BackToTown()
	Local $result = AssertFarmResult()
	Info('Porting to Rata Sum')
	Resign()
	RndSleep(3500)
	ReturnToOutpost()
	WaitMapLoading($ID_Rata_Sum, 10000, 2000)
	Return $result
EndFunc


;~ Check whether or not the farm was successful
Func AssertFarmResult()
	If GetIsDead() Then
		Info('Character died')
		Return 1
	EndIf

	Local $survivors = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST)
	If $survivors > 1 Then
		Info($survivors & ' raptors survived')
		Return 1
	EndIf
	Return 0
EndFunc


;~ Move to (X,Y) while staying alive vs raptors
Func MoveAggroingRaptors($x, $y)
	Move($x, $y, 0)

	Local $me = GetMyAgent()
	While Not GetIsDead() And ComputeDistance(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $x, $y) > $RANGE_NEARBY
		If IsBodyBlocked() Then Return True
		RndSleep(100)
		Move($x, $y)
		$me = GetMyAgent()
	WEnd
	Return False
EndFunc


;~ Check if bodyblock and if is move randomly until not bodyblocked anymore
Func IsBodyBlocked()
	Local $blocked = 0
	Local Const $PI = 3.14159
	Local $angle = 0

	Local $me = GetMyAgent()
	If DllStructGetData($me, 'HP') < 0.90 Then
		SendStuckCommand()
	EndIf

	While DllStructGetData($me, 'MoveX') == 0 And DllStructGetData($me, 'MoveY') == 0
		$blocked += 1
		Debug('Blocked: ' & $blocked)
		If $blocked > 1 Then
			$angle += $PI / 4
		EndIf

		If ($blocked > 4 Or DllStructGetData($me, 'HP') < 0.90) Then
			SendStuckCommand()
		EndIf

		If $blocked > 7 Then
			Debug('Completely blocked')
			Return True
		EndIf
		Move(DllStructGetData($me, 'X') + 300 * sin($angle), DllStructGetData($me, 'Y') + 300 * cos($angle), 0)
		RndSleep(250)
		$me = GetMyAgent()
	WEnd
	Return False
EndFunc


;~ Send /stuck - don't overuse
Func SendStuckCommand()
	; use a timer to avoid spamming /stuck - /stuck is only useful when rubberbanding - there shouldn't be any enemy around the character then
	If CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY) == 0 And TimerDiff($chatStuckTimer) > 10000 Then
		Warn('Sending /stuck')
		SendChat('stuck', '/')
		$chatStuckTimer = TimerInit()
		RndSleep(GetPing() + 20)
		Return True
	EndIf
	Return False
EndFunc


;~ Detect if player is rubberbanding
Func IsRubberBanding()

EndFunc


;~ Get nearest foe that is a boss - null if no boss
Func GetNearestBossFoe()
	Local $bossFoes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_COMPASS, GetIsBoss)
	Return $bossFoes[0] == 1 ? $bossFoes[1] : null
EndFunc