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

#include 'GWA2_Headers.au3'
#include 'GWA2.au3'
#include 'Utils.au3'

; Possible improvements :
; - Update movements to be depending on raptors positions to make sure almost all raptors are aggroed (especially boss group)
; - Make rubberbanding function using foes positions (if foes are mostly not around you then you're rubberbanding) or using foes targetting (if foes in aggro range don't target you you are rubberbanding)
; - Add heroes and use Edge of Extinction ? A bit unnecessary, will do if bored
; - Optimise first cast of MoP to be made on first target that enters aggro (might be making farm worse : right now MoP is cast quite late which is good)
; - Use pumpkin pie slices ? Reduce cast time and increase attack speed reducing chances to be interrupted during MoP or Whirlwind
; - Change spiking position


Opt('MustDeclareVars', 1)

Local Const $RaptorBotVersion = '0.4'

; ==== Constantes ====
Local Const $WNRaptorFarmerSkillbar = 'OQQTcYqVXySgmUlJvovYUbHctAA'
Local Const $PRunnerHeroSkillbar = 'OQijEqmMKODbe8O2Efjrx0bWMA'
Local Const $RaptorsFarmInformations = 'For best results, have :' & @CRLF _
	& '- 12 in curses' & @CRLF _
	& '- 12+ in tactics' & @CRLF _
	& '- 9+ in swordsmanship (enough to use your sword)'& @CRLF _
	& '- A Tactics shield with the inscription "Through Thick and Thin" (+10 armor against Piercing damage)' & @CRLF _
	& '- A sword "of Shelter", prefix and inscription do not matter' & @CRLF _
	& '- Knight insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune' & @CRLF _
	& '- A superior Absorption rune' & @CRLF _
	& '- General Morgahn with 16 in Command, 10 in restoration and the rest in Leadership' & @CRLF _
	& '- Golden Eggs'
; Skill numbers declared to make the code WAY more readable (UseSkillEx($Raptors_MarkOfPain)  is better than UseSkillEx(1))
Local Const $Raptors_MarkOfPain = 1
Local Const $Raptors_IAmUnstoppable = 2
Local Const $Raptors_ProtectorsDefense = 3
Local Const $Raptors_WaryStance = 4
Local Const $Raptors_HundredBlades = 5
Local Const $Raptors_SoldiersDefense = 6
Local Const $Raptors_WhirlwindAttack = 7
Local Const $Raptors_ShieldBash = 8

; Hero Build
Local Const $Raptors_VocalWasSogolon = 1
Local Const $Raptors_Incoming = 2
Local Const $Raptors_FallBack = 3
Local Const $Raptors_EnduringHarmony = 4
Local Const $Raptors_MakeHaste = 5
Local Const $Raptors_StandYourGround = 6
Local Const $Raptors_CantTouchThis = 7
Local Const $Raptors_BladeturnRefrain = 8

Local $RAPTORS_FARM_SETUP = False
Local $chatStuckTimer = TimerInit()

;~ Main method to farm Raptors
Func RaptorFarm($STATUS)
	If GetMapID() <> $ID_Rata_Sum Then
		DistrictTravel($ID_Rata_Sum, $ID_EUROPE, $ID_FRENCH)
	EndIf
	
	If Not $RAPTORS_FARM_SETUP Then
		SetupRaptorFarm()
		$RAPTORS_FARM_SETUP = True
	EndIf

	If $STATUS <> 'RUNNING' Then Return 2

	Return RaptorsFarmLoop()
EndFunc


Func SetupRaptorFarm()
	Out('Setting up farm')
	SetDisplayedTitle($ID_Asura_Title)
	SwitchMode($ID_HARD_MODE)
	AddHero($ID_General_Morgahn)
	;DisableHeroSkills()
	GUICtrlSetState($LootGreenItemsCheckbox, $GUI_UNCHECKED)
	MoveTo(19649, 16791)
	Move(20084, 16854)
	RndSleep(1000)
	WaitMapLoading($ID_Riven_Earth, 10000, 2000)
	Move(-26309, -4112)
	RndSleep(1000)
	WaitMapLoading($ID_Rata_Sum, 10000, 2000)
	Out('Resign preparation complete')
EndFunc


Func DisableHeroSkills()
	For $i = 1 to 8
		DisableHeroSkillSlot(1, $i)
	Next
EndFunc


;~ Farm loop
Func RaptorsFarmLoop()
	If Not $RenderingEnabled Then ClearMemory()
	Out('Exiting to Riven Earth')
	Move(20084, 16854)
	RndSleep(1000)
	WaitMapLoading($ID_Riven_Earth, 10000, 2000)

	UseHeroSkill(1, $Raptors_Incoming)
	UseHeroSkill(1, $Raptors_VocalWasSogolon)
	GetBlessing()
	MoveToBaseOfCave()
	MoveHeroAway()
	GetRaptors()
	KillRaptors()

	IF (GUICtrlRead($LootNothingCheckbox) == $GUI_UNCHECKED) Then
		Out('Looting')
		PickUpItems(DefendWhilePickingUpItems)
	EndIf

	Return BackToTown()
EndFunc


Func DefendWhilePickingUpItems()
	If GetEnergy(-2) > 5 And IsRecharged($Raptors_IAmUnstoppable) Then UseSkillEx($Raptors_IAmUnstoppable)
	If GetEnergy(-2) > 5 And IsRecharged($Raptors_SoldiersDefense) Then UseSkillEx($Raptors_SoldiersDefense)
	If GetEnergy(-2) > 5 And IsRecharged($Raptors_ShieldBash) Then UseSkillEx($Raptors_ShieldBash)
	If GetEnergy(-2) > 10 And IsRecharged($Raptors_WaryStance) Then UseSkillEx($Raptors_WaryStance)
EndFunc


Func GetBlessing()
	Local $Asura = GetAsuraTitle()
	If $Asura < 160000 Then
		Out('Getting asura title blessing')
		GoNearestNPCToCoords(-20000, 3000)
		RndSleep(250)
		Dialog(132)
	EndIf
	RndSleep(300)
EndFunc

Func MoveToBaseOfCave()
	If GetIsDead(-2) Then Return
	Out('Moving to Cave')
	Move(-22015, -7502)
	RndSleep(500)
	UseHeroSkill(1, $Raptors_FallBack)
	RndSleep(7000)
	UseSkillEx($Raptors_IAmUnstoppable)
	Moveto(-21333, -8384)
	UseHeroSkill(1, $Raptors_EnduringHarmony, -2)
	RndSleep(1800)
	UseHeroSkill(1, $Raptors_MakeHaste, -2)
	RndSleep(50)
	UseHeroSkill(1, $Raptors_StandYourGround)
	RndSleep(50)
	UseHeroSkill(1, $Raptors_CantTouchThis)
	RndSleep(50)
	UseHeroSkill(1, $Raptors_BladeturnRefrain, -2)
	Move(-20930, -9480, 40)
EndFunc


Func MoveHeroAway()
	Out('Moving Hero away')
	CommandAll(-25309, -4212)
	RndSleep(500)
EndFunc


Func GetRaptors()
	Out('Gathering Raptors')
	Local $target = GetNearestEnemyToAgent(-2)
	
	Move(-20695, -9900, 20)
	;Using the nearest to agent could result in targeting Angorodon if they are badly placed
	$target = GetNearestEnemyToCoords(-20042, -10251)
	
	UseSkillEx($Raptors_ShieldBash)
	While IsRecharged($Raptors_MarkOfPain)
		If GetIsDead(-2) Then Return
		UseSkillEx($Raptors_MarkOfPain, $target)
		RndSleep(250)
	WEnd

	$target = TargetNearestEnemy()
	MoveAggroingRaptors(-20042, -10251, 50, $target)
	If IsBodyBlocked() Then Return
	MoveTo(-19700, -10650, 50)
	If IsBodyBlocked() Then Return
	MoveTo(-19650, -11500, 50)
	If IsBodyBlocked() Then Return
	MoveTo(-20535, -12000, 50)
	If IsBodyBlocked() Then Return
	MoveAggroingRaptors(-21490, -12175, 50, $target)
	If IsBodyBlocked() Then Return
	MoveTo(-22000, -11927, 50)
	If IsBodyBlocked() Then Return
	TargetNearestEnemy()
	If IsBodyBlocked() Then Return
	MoveTo(-22450, -11820, 20)
	If IsBodyBlocked() Then Return
	MoveTo(-22450, -12460, 20)
EndFunc

Func IsBodyBlocked()
	Local $blocked = 0
	Local Const $PI = 3.141592653589793
	Local $angle = 0
	If DllStructGetData(GetAgentByID(-2), 'HP') < 0.92 Then
		; Dont spam stuck command it's sent to servers
		If TimerDiff($chatStuckTimer) > 3000 Then
			SendChat('stuck', '/')
			$chatStuckTimer = TimerInit()
			RndSleep(GetPing())
		EndIf
	EndIf
	While DllStructGetData(GetAgentByID(-2), 'MoveX') == 0 And DllStructGetData(GetAgentByID(-2), 'MoveY') == 0		
		$blocked += 1
		If $blocked > 1 Then
			$angle += $PI / 4
		EndIf
		If $blocked > 7 Then
			Return True
		EndIf
		Move(DllStructGetData(GetAgentByID(-2), 'X') + 300 * sin($angle), DllStructGetData(GetAgentByID(-2), 'Y') + 300 * cos($angle))
		RndSleep(50)
	WEnd
	Return False
EndFunc

Func KillRaptors()
	Local $MoPTarget
	Local $lRekoff

	If GetIsDead(-2) Then Return
	Out('Clearing Raptors')
	If IsRecharged($Raptors_IAmUnstoppable) Then UseSkillEx($Raptors_IAmUnstoppable)
	RndSleep(50)
	UseSkillEx($Raptors_ProtectorsDefense)
	RndSleep(50)
	UseSkillEx($Raptors_HundredBlades)
	RndSleep(1500)
	UseSkillEx($Raptors_WaryStance)
	RndSleep(500)

	$lRekoff = GetAgentByName('Rekoff Broodmother')

	If GetDistance(-2, $lRekoff) > $RANGE_SPELLCAST Then
		$MoPTarget = GetNearestEnemyToAgent(-2)
	Else
		$MoPTarget = GetNearestEnemyToAgent($lRekoff)
	EndIf

	If GetHasHex($MoPTarget) Then
		TargetNextEnemy()
		$MoPTarget = GetCurrentTarget()
	EndIf

	Local $lDistance
	Local $lSpellCastCount
	Local $lAgentArray

	$lAgentArray = GetAgentArray(0xDB)

	For $i = 1 To $lAgentArray[0]
	$lDistance = GetPseudoDistance(GetAgentByID(-2), $lAgentArray[$i])
		If $lDistance < $RANGE_SPELLCAST_2 Then
			$lSpellCastCount += 1
		EndIf
	Next

	If $lSpellCastCount	> 20 Then
		RndSleep(2000)
	Elseif $lSpellCastCount < 21 Then
		RndSleep(4000)
	EndIf

	While IsRecharged($Raptors_MarkOfPain)
		If GetIsDead(-2) Then Return
		UseSkillEx($Raptors_MarkOfPain, $MoPTarget)
		RndSleep(250)
	WEnd
	If IsRecharged($Raptors_IAmUnstoppable) Then UseSkillEx($Raptors_IAmUnstoppable)
	UseSkillEx($Raptors_SoldiersDefense)
	RndSleep(50)
	Local $whirlwind_deadlock = TimerInit()
	While GetSkillbarSkillAdrenaline($Raptors_WhirlwindAttack) <> 130
		If GetIsDead(-2) Then Return
		RndSleep(50)
	WEnd
	
	Local $raptorsCount = CountFoesInRangeOfAgent(-2, $RANGE_SPELLCAST)
	Out('Spiking ' & $raptorsCount & ' raptors')
	
	UseSkillEx($Raptors_ShieldBash)
	RndSleep(20)
	While CountFoesInRangeOfAgent(-2, $RANGE_SPELLCAST) > 10
		If GetIsDead(-2) Then Return
		While GetSkillbarSkillAdrenaline($Raptors_WhirlwindAttack) == 130 And TimerDiff($whirlwind_deadlock) < 6000
			If GetIsDead(-2) Then Return
			UseSkillEx($Raptors_WhirlwindAttack, GetNearestEnemyToAgent(-2))
			RndSleep(250)
		WEnd
		RndSleep(1100)
	WEnd
EndFunc


Func BackToTown()
	Local $result = AssertFarmResult()
	Out('Porting to Rata Sum')
	Resign()
	RndSleep(3500)
	ReturnToOutpost()
	WaitMapLoading($ID_Rata_Sum, 10000, 2000)
	Return $result
EndFunc


Func AssertFarmResult()
	If GetIsDead(-2) Then
		Out('Character died')
		Return 1
	EndIf

	Local $survivors = CountFoesInRangeOfAgent(-2, $RANGE_SPELLCAST)
	If $survivors > 1 Then
		Out($survivors & ' raptors survived')
		Return 1
	Else
		Return 0
	EndIf
EndFunc


;~ Move to destX, destY, while staying alive vs raptors
Func MoveAggroingRaptors($lDestX, $lDestY, $lRandom, $CheckTarget)
	If GetIsDead(-2) Then Return

	Local $lAgentArray
	Local $lBlocked
	Local $lAdjacentCount, $lDistance
	Local $timer = TimerInit()
	Local $timerCount

	Move($lDestX, $lDestY, $lRandom)

	$lAgentArray = GetAgentArray(0xDB)

	For $i = 1 To $lAgentArray[0]
		$lDistance = GetPseudoDistance(GetAgentByID(-2), $lAgentArray[$i])
		If $lDistance < $RANGE_ADJACENT_2 Then
			$lAdjacentCount += 1
		EndIf
	Next

	If $lAdjacentCount > 10 Then
		$timerCount += 1
	EndIf

	Do
		RndSleep(50)

		If GetIsDead(-2) Then Return

		If DllStructGetData(GetAgentByID(-2), 'MoveX') == 0 And DllStructGetData(GetAgentByID(-2), 'MoveY') == 0 Then
			$lBlocked += 1
			Move($lDestX, $lDestY, $lRandom)
		EndIf

		If $lBlocked > 3 Then
			If TimerDiff($timer) > 2500 Then	; use a timer to avoid spamming /stuck
				SendChat('stuck', '/')
				$timer = TimerInit()
				$timerCount += 1
			EndIf
		EndIf

		If GetDistance() > 1500 Then ; target is far, we probably got stuck.
			If TimerDiff($timer) > 2500 Then ; dont spam
				SendChat('stuck', '/')
				$timer = TimerInit()
				RndSleep(GetPing())
				Attack($CheckTarget)
				$timerCount += 1
			EndIf
		EndIf

		If $timerCount > 0 Then Return

	Until ComputeDistance(DllStructGetData(GetAgentByID(-2), 'X'), DllStructGetData(GetAgentByID(-2), 'Y'), $lDestX, $lDestY) < $lRandom*1.5
EndFunc