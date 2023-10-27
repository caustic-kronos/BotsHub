#include-once

#include "GWA2.au3"
#include "GWA2_Headers.au3"
#include "GWA2_ID.au3"
#include "Utils.au3"


Global $Miku
Global $Me

Global Const $sp5 = 5
Global Const $sp6 = 6

;Skills
Global $SKILLID_ForGreatJustice = 343
Global $SKILLID_100B = 381
Global $SKILLID_ToTheLimit = 316
Global $SKILLID_WhirlwindAttack = 2107
Global $SKILLID_ShadowRefuge = 814
Global $SKILLID_ShroudOfDistress= 1031
Global $SKILLID_EBSOH = 3172
Global $SKILLID_HealingSignet = 1


Func MinisterialCommendationsFarm()
	Setup()

	Out("Go to quest NPC")
	GoToQuest()

	Out("Entering quest")
	EnterQuest()

	Out("Preparing to fight")
	PrepareToFight()

	If CanContinue() Then
		Out("Fighting")
		Fight()
	EndIf

	If CanContinue() Then
		Out("Running glitch spot")
		RunToStairs()
	EndIf

	If CanContinue() Then
		Out("Waiting for spike")
		WaitForSpike()
	EndIf

	If CanContinue() Then
		Out("Ready to spike")
		Spike()
		Out("Picking up loot")
		CheckForLoot()
		sleep(10)
		CheckForLoot1()
	EndIf

	Out("Travelling back to KC")
	RndTravel($ID_Kaineng_City)
EndFunc


Func Setup()
	Out("Getting map ID" & GetMapID())
	If GetMapID() <> $ID_Kaineng_City Then
		Out("Travelling to KC")
		RndTravel($ID_Kaineng_City)
	EndIf
	LeaveGroup()
	AddHeroes()
EndFunc


Func AddHeroes ()
	AddHero($ID_Tahlkora)
	AddHero($ID_Dunkoro)
	AddHero($ID_Ogden)
	AddHero($ID_Xandra)
	AddHero($ID_Gwen)
	AddHero($ID_Vekk)
	AddHero($ID_Acolyte_Sousuke)
EndFunc


Func EnterQuest()
	RndSleep(1000)
	Local $NPC = GetNearestNPCToCoords(2240, -1264)
	GoToNPC($NPC)
	Sleep(250)
	Dialog(0x00000084)
	Sleep(500)
	WaitMapLoading(861)
EndFunc


Func GoToQuest()
	Local $lMe, $coordsX, $coordsY
	$lMe = GetAgentByID(-2)
	$coordsX = DllStructGetData($lMe, 'X')
	$coordsY = DllStructGetData($lMe, 'Y')

	If - 1400 < $coordsX And $coordsX < -550 And - 2000 < $coordsY And $coordsY < -1100 Then
		Out("Moving")
		MoveTo(1474, -1197, 0)
	EndIf
EndFunc


;~Move party into a good position
Func MoveToStartingPositions()
	Out("Moving party")
	CommandHero(6, -5857, -4471)
	CommandHero(5, -5509, -4471)
	CommandHero(2, -5687, -4209)
	CommandHero(4, -5679, -3705)
	CommandHero(7, -5659, -4641)
	CommandHero(1, -5578, -4786)
	CommandHero(3, -6038, -4611)
	MoveTo( -6311.79, -5241.88)
EndFunc


Func PrepareToFight()
	RndSleep (1000)
	sleep(2000)
	sleep(2000)
	Sleep(1000)

	;Make local variables for heroes and Miku
	Global $Me = GetAgentByID(-2)

	;Move party into a good position
	MoveToStartingPositions()
	Usezs()
	EnableHeroSkillSlot(2, 5)
	EnableHeroSkillSlot(3, 5)
	UseHeroSkill(7, 1)
	UseHeroSkill(6, 1)		;Pre-casting Esurge
	UseHeroSkill(5, 1)
	Sleep(2000)
	UseHeroSkill(4, 2)		; hero 4, skill 5
	Sleep(2000)
	Sleep(2000)
	UseHeroSkill(4, 3)		; hero 4, skill 5
	RndSleep(7000)			; Wait until enemies about to turn hostile
	UseHeroSkill(4, 4)
	UseHeroSkill(1, 7, 58)	; hero 2, skill 3 ; Pre-casting Esurge
	sleep(500)
	RndSleep(300)			; Wait a short time
	RndSleep(300)
	RndSleep(300)
	If IsRecharged($sp5) Then UseSkillEx($sp5)
	If IsRecharged($Sp6) Then UseSkillEx($sp6)
	sleep(1500)
	RndSleep(300)
	UseHeroSkill(2, 4, 58)	;hero 4, skill 1, -2 is player
	RndSleep(300)
	RndSleep(2000)			; Waiting a short time for second splinter
	UseHeroSkill(4, 5)
	RndSleep(300)
	UseSkillEx(2)			; Player Fighting
	UseSkillEx(1)			; Player Fighting
	RndSleep (1000)			; Waiting a short time
	UseHeroSkill(2, 7, -2)	;hero 4, skill 1, -2 is player
	RndSleep(300)
	UseSkillEx(7)			; Player Fighting
	If IsRecharged($sp5) Then UseSkillEx($sp5)
	If IsRecharged($Sp6) Then UseSkillEx($sp6)
	RndSleep (2000)			; Waiting a short time
	If IsRecharged($sp5) Then UseSkillEx($sp5)
	If IsRecharged($Sp6) Then UseSkillEx($sp6)
	UseSkillEx(3)			; Player Fighting
	UseSkillEx(4, GetNearestEnemyToAgent(-2))	; Player Fighting
	RndSleep (3500)			; Waiting a short time
	If IsRecharged($sp5) Then UseSkillEx($sp5)
	If IsRecharged($Sp6) Then UseSkillEx($sp6)
	UseSkillEx(4, GetNearestEnemyToAgent(-2))	; Player Fighting
	; Unflag all heroes
	UseSkillEx(8)
	UseSkillEx(6)
	CancelHero(1)
	CancelHero(2)
	CancelHero(3)
	CancelHero(4)
	CancelHero(5)
	CancelHero(6)
	CancelHero(7)
EndFunc

Func HelpMiku()
	If CanContinue() Then
		If DllStructGetData(GetAgentByID(58), 'HP') < 0.50 Then		; Works for some reason (58 = Miku)
			UseHeroSkill(3, 7, 58)									; hero 1, skill 1
			sleep(1500)
			UseHeroSkill(3, 1, 58)									; hero 2, skill 3
			sleep(1500)
			UseHeroSkill(3, 5, 58)									; hero 1, skill 1
			sleep(1500)
			UseHeroSkill(3, 7, 58)									; hero 1, skill 1
		EndIf
	EndIf
EndFunc



Func Fight()
	$lDeadLock = TimerInit()
	$LMovedHeroes = False

	Do
		HelpMiku()
		If ((GetNumberOfFoesInRangeOfAgent(-2, 3000) < 3 Or TimerDiff($lDeadLock) > 60000) And $LMovedHeroes = False) Then
			;Out("Moving heroes to finish fight")
			CommandHero(5,-6554.25, -5207.51)
			CommandHero(6, -6554.25, -5207.51)
			CommandHero(7, -6554.25, -5207.51)
			MoveTo(-6311.79, -5241.88)
			$LMovedHeroes = True
		Else
			If GetNumberOfFoesInRangeOfAgent(-2, 3000) > 2 Then
				UseSkillEx(1)
				UseSkillEx(2)
				UseSkillEx(8)
				UseSkillEx(6)
				Attack(GetNearestEnemyToAgent(-2))
			EndIf
		EndIf
		;Out("Enemies left:" + GetNumberOfFoesInRangeOfAgent(-2, 8000))
	Until GetNumberOfFoesInRangeOfAgent(-2, 3000) = 0 Or TimerDiff($lDeadLock) > 120000 Or CanContinue() = False
	UseSkillEx(8)
	CancelHero(1)
	CancelHero(2)
	CancelHero(3)
	CancelHero(4)
	CancelHero(5)
	CancelHero(6)
	CancelHero(7)
	UseHeroSkill(4, 5)
	sleep(500)
	UseHeroSkill(4, 8)
	;Out("Initial fight is over")
EndFunc

Func RunToStairs()
	CheckForLoot3()
	sleep(5)
	CheckForLoot4()
	$lDeadLock = TimerInit()
	CommandAll(-7047, -2651)
	UseSkillEx(5)
	MoveTo(-4790, -3441)
	MoveTo(-4608, -2120)
	MoveTo(-4222, -1545)
	MoveTo(-4664, -672)
	MoveTo(-3825, 134)
	MoveTo(-3067, 633)
	MoveTo(-2663, 644)
	UseSkillEx(5)
	If (GetMapID() = 861) Then
		Do
			Sleep(5)
		Until GetNumberOfFoesInRangeOfAgent(-2, 2850) > 0 Or TimerDiff($lDeadLock) > 60000 Or GetMapID() = $ID_Kaineng_City
	EndIf
	MoveTo(-2214, -334)
	MoveTo(-878, -1877)
	If (GetMapID() = 861) Then
		Do
			Sleep(5)
		Until GetNumberOfFoesInRangeOfAgent(-2, 3500) > 0 Or TimerDiff($lDeadLock) > 60000 Or GetMapID() = $ID_Kaineng_City
	EndIf
	MoveTo(-770, -3052)
	MoveTo(-699, -3773)
	MoveTo(-1070, -4192, 0)
	Useflame()
	CommandHero(1, -5752, -3006)
	CommandHero(2, -5763.44, -2885)
	CommandHero(3, -5709.22, -2685)
	UseSkillEx(6)
	UseSkillEx(5)
	UseHeroSkill(1, 2)
	UseHeroSkill(2, 2)
	UseHeroSkill(3, 2)
	sleep(1000)
EndFunc


Func Useflame()
	Local $aBag
	Local $aItem
	Sleep(200)
	For $i = 1 To 4
		$aBag = GetBag($i)
		For $j = 1 To DllStructGetData($aBag, "Slots")
			$aItem = GetItemBySlot($aBag, $j)
			If DllStructGetData($aItem, "ModelID") == 36664 Then
			UseItem($aItem)
			Return True
			EndIf
		Next
	Next
EndFunc


Func Usezs()
	Local $aBag
	Local $aItem
	Sleep(200)
	For $i = 1 To 4
		$aBag = GetBag($i)
		For $j = 1 To DllStructGetData($aBag, "Slots")
			$aItem = GetItemBySlot($aBag, $j)
			If DllStructGetData($aItem, "ModelID") == 31156 Then
			UseItem($aItem)
			Return True
			EndIf
		Next
	Next
EndFunc


Func WaitForSpike()
	; Wait until enemies are in melee range
	UseSkillEx(6)
	UseSkillEx(5)
	$lDeadLock = TimerInit()

	If IsRecharged($sp5) Then UseSkillEx($sp5)
	If IsRecharged($Sp6) Then UseSkillEx($sp6)

	Do
		Sleep(250)
	Until GetNumberOfFoesInRangeOfAgent(-2, 200) <> 0 Or TimerDiff($lDeadLock) > 55000
	
	; Use Shroud
	UseSkillEx(6)
	UseSkillEx(5)

	Do
		; Command heroes to useskill healing party and martyr
		If IsDllStruct(GetEffect(480)) Then UseHeroSkill(2, 6)
		If IsDllStruct(GetEffect(480)) Then UseHeroSkill(3, 6)
		If IsDllStruct(GetEffect(480)) Then UseHeroSkill(1, 6)

		; Use self healing skills
		If DllStructGetData(GetAgentByID(-2), 'HP') < 0.99 Then ; (-2 = Me)
			UseSkillEx(5)
			UseSkillEx(6)
			UseSkillEx(8)
		EndIf

		;Use hero healing if I am getting low
		If DllStructGetData(GetAgentByID(-2), "HP") < 0.98 Then ;(-2 = Me) And
				UseHeroSkill(2, 1)
			UseHeroSkill(3, 1)
			UseHeroSkill(1, 1)
			UseHeroSkill(2, 6)
			UseHeroSkill(3, 6)
			UseHeroSkill(1, 6)
			UseSkillEx(6)
			UseSkillEx(8)
		EndIf

		If DllStructGetData(GetAgentByID(-2), "HP") < 0.85 Then ;(-2 = Me) And
			UseHeroSkill(2, 1)
			UseHeroSkill(3, 1)
			UseHeroSkill(1, 1)
			UseHeroSkill(2, 6)
			UseHeroSkill(3, 6)
			UseHeroSkill(1, 6)
			UseSkillEx(6)
			UseSkillEx(8)
		EndIf
	Until GetisDead(-2) Or ((GetNumberOfFoesInRangeOfAgent(-2, 300) == GetNumberOfFoesInRangeOfAgent(-2, 700) And GetNumberOfFoesInRangeOfAgent(-2, 300) > 45)) Or TimerDiff($lDeadLock) > 50000 Or GetNumberOfFoesInRangeOfCords(352, -1173, 3000) = 0
	sleep(1000)
	UseHeroSkill(2, 1)
	UseHeroSkill(3, 1)
	UseHeroSkill(1, 1)
	UseHeroSkill(2, 6)
	UseHeroSkill(3, 6)
	UseHeroSkill(1, 6)
	;~ UseHeroSkill(4, 6)
	UseSkillEx(8)
	UseSkillEx(6)
	sleep(2000)
	UseHeroSkill(2, 1)
	UseHeroSkill(3, 1)
	UseHeroSkill(1, 1)
	UseHeroSkill(2, 6)
	UseHeroSkill(3, 6)
	UseHeroSkill(1, 6)
	;~ UseHeroSkill(4, 6)
	UseSkillEx(8)
	UseSkillEx(6)
EndFunc



Func CanContinue()
	IF GetIsDead(GetAgentByID(58)) = False And GetIsDead(GetAgentByID(-2)) == False Then
		Return True
	Else
		Out("Miku is:" & GetIsDead(GetAgentByID(-58)))
		Out("Player is:" & GetIsDead(GetAgentByID(-2)))
		Return False
	EndIf
EndFunc

Func Spike()
	UseSkillEx(8)
	UseSkillEx(6)
	CancelAction()
	Sleep(GetPing() + 50)
	CancelHero(1)
	CancelHero(2)
	CancelHero(3)
	CancelHero(7)
	CancelHero(1)
	CancelHero(2)
	CancelHero(3)
	CancelHero(7)
	CommandAll(-7047, -2651)
	sleep(250)
	UseSkillEx(8)
	sleep(250)
	UseSkillEx(7)
	sleep(1000)
	UseSkillEx(1)
	UseSkillEx(2)
	UseSkillEx(3)
	UseSkillEx(4, GetNearestEnemyToAgent(-2))
	Sleep(150)
	UseSkillEx(8)
	;~ 	CancelAction()
	;~  CancelAll()
	UseSkillEx(6)
	CheckForLoot()
	Sleep(100)
	CheckForLoot1()
	Sleep(100)
	CheckForLoot2()
	UseHeroSkill(4, 8)
	UseHeroSkill(5, 8)
	UseHeroSkill(7, 8)
	UseHeroSkill(6, 8)
	Sleep(100)
	UseSkillEx(8)
	CheckForLoot()
	Sleep(100)
	CheckForLoot1()
	Sleep(100)
	CheckForLoot2()
EndFunc


Func CheckForLoot()
	Local $lMe
	Local $lBlockedTimer
	Local $lBlockedCount = 0
	Local $lItemExists = True

	For $i = 1 To GetMaxAgents()
		$lMe = GetAgentByID(-2)
		$lAgent = GetAgentByID($i)
		If Not GetIsMovable($lAgent) Then ContinueLoop
		If Not ShouldPickItem($lAgent) Then ContinueLoop
		$lItem = GetItemByAgentID($i)
		If ShouldPickItem($lItem) Then
			Do
				UseSkillEx(8)
				If GetIsDead(GetAgentByID(-2)) == True Then
					EnableHeroSkillSlot(4, 8)
					CancelAll()
					CancelHero(1)
					CancelHero(2)
					CancelHero(3)
					CancelHero(4)
					CancelHero(5)
					CancelHero(6)
					CancelHero(7)
					Sleep(20000)
					UseHeroSkill(4, 8)
					UseHeroSkill(5, 8)
					UseHeroSkill(7, 8)
					UseHeroSkill(6, 8)
				EndIf
				UseSkillEx(8)
				UseSkillEx(6)
				PickUpItem($lItem)
				Sleep(GetPing() + 500)
				Do
					Sleep(100)
					$lMe = GetAgentByID(-2)
				Until DllStructGetData($lMe, 'MoveX') == 0 And DllStructGetData($lMe, 'MoveY') == 0
				$lBlockedTimer = TimerInit()
				Do
					Sleep(3)
					$lItemExists = IsDllStruct(GetAgentByID($i))
				Until Not $lItemExists Or TimerDiff($lBlockedTimer) > Random(5000, 7500, 1)
				If $lItemExists Then $lBlockedCount += 1
			Until Not $lItemExists Or $lBlockedCount > 5
			
			Do
				If GetMapLoading() == 2 Then Disconnected()
				If $lBlockedCount > 2 Then UseSkillEx(6,-2)
				PickUpItem($lItem)
				Sleep(GetPing())
				Do
					Sleep(100)
					$lMe = GetAgentByID(-2)
				Until DllStructGetData($lMe, 'MoveX') == 0 And DllStructGetData($lMe, 'MoveY') == 0
				$lBlockedTimer = TimerInit()
				Do
					Sleep(3)
					$lItemExists = IsDllStruct(GetAgentByID($i))
				Until Not $lItemExists Or TimerDiff($lBlockedTimer) > Random(5000, 7500, 1)
				If $lItemExists Then $lBlockedCount += 1
			Until Not $lItemExists Or $lBlockedCount > 5
		EndIf
	Next
EndFunc


Func CheckForLoot1()
	Local $lMe
	Local $lBlockedTimer
	Local $lBlockedCount = 0
	Local $lItemExists = True

	For $i = 1 To GetMaxAgents()
		$lMe = GetAgentByID(-2)
		$lAgent = GetAgentByID($i)
		If Not GetIsMovable($lAgent) Then ContinueLoop
		If Not GetCanPickUp($lAgent) Then ContinueLoop
		$lItem = GetItemByAgentID($i)
		If ShouldPickItem($lItem) Then
			Do
				If GetIsDead(GetAgentByID(-2)) == True Then
				EnableHeroSkillSlot(4, 8)
				CancelAll()
				CancelHero(1)
				CancelHero(2)
				CancelHero(3)
				CancelHero(4)
				CancelHero(5)
				CancelHero(6)
				CancelHero(7)
				Sleep(20000)
				UseHeroSkill(4, 8)
				UseHeroSkill(5, 8)
				UseHeroSkill(7, 8)
				UseHeroSkill(6, 8)
				EndIf
				UseSkillEx(8)
				UseSkillEx(6)
				PickUpItem($lItem)
				Sleep(GetPing() + 500)
				Do
					Sleep(100)
					$lMe = GetAgentByID(-2)
				Until DllStructGetData($lMe, 'MoveX') == 0 And DllStructGetData($lMe, 'MoveY') == 0
				$lBlockedTimer = TimerInit()
				Do
					Sleep(3)
					$lItemExists = IsDllStruct(GetAgentByID($i))
				Until Not $lItemExists Or TimerDiff($lBlockedTimer) > Random(5000, 7500, 1)
				If $lItemExists Then $lBlockedCount += 1
			Until Not $lItemExists Or $lBlockedCount > 5
			Do
				If GetMapLoading() == 2 Then Disconnected()
				If $lBlockedCount > 2 Then UseSkillEx(6,-2)
				PickUpItem($lItem)
				Sleep(GetPing())
				Do
					Sleep(100)
					$lMe = GetAgentByID(-2)
				Until DllStructGetData($lMe, 'MoveX') == 0 And DllStructGetData($lMe, 'MoveY') == 0
				$lBlockedTimer = TimerInit()
				Do
					Sleep(3)
					$lItemExists = IsDllStruct(GetAgentByID($i))
				Until Not $lItemExists Or TimerDiff($lBlockedTimer) > Random(5000, 7500, 1)
				If $lItemExists Then $lBlockedCount += 1
			Until Not $lItemExists Or $lBlockedCount > 5
		EndIf
	Next
EndFunc


Func CheckForLoot2()
	Local $lMe
	Local $lBlockedTimer
	Local $lBlockedCount = 0
	Local $lItemExists = True

	For $i = 1 To GetMaxAgents()
		$lMe = GetAgentByID(-2)
		$lAgent = GetAgentByID($i)
		If Not GetIsMovable($lAgent) Then ContinueLoop
		If Not GetCanPickUp($lAgent) Then ContinueLoop
		$lItem = GetItemByAgentID($i)
		If ShouldPickItem($lItem) Then
			Do
				If GetIsDead(GetAgentByID(-2)) == True Then
					EnableHeroSkillSlot(4, 8)
					CancelAll()
					CancelHero(1)
					CancelHero(2)
					CancelHero(3)
					CancelHero(4)
					CancelHero(5)
					CancelHero(6)
					CancelHero(7)
					Sleep(20000)
					UseHeroSkill(4, 8)
					UseHeroSkill(5, 8)
					UseHeroSkill(7, 8)
					UseHeroSkill(6, 8)
				EndIf
				UseSkillEx(8)
				UseSkillEx(6)

				PickUpItem($lItem)
				Sleep(GetPing() + 500)
				Do
					Sleep(100)
					$lMe = GetAgentByID(-2)
				Until DllStructGetData($lMe, 'MoveX') == 0 And DllStructGetData($lMe, 'MoveY') == 0
				$lBlockedTimer = TimerInit()
				Do
					Sleep(3)
					$lItemExists = IsDllStruct(GetAgentByID($i))
				Until Not $lItemExists Or TimerDiff($lBlockedTimer) > Random(5000, 7500, 1)
				If $lItemExists Then $lBlockedCount += 1
			Until Not $lItemExists Or $lBlockedCount > 5
			Do
				If GetMapLoading() == 2 Then Disconnected()
				If $lBlockedCount > 2 Then UseSkillEx(6,-2)
				PickUpItem($lItem)
				Sleep(GetPing())
				Do
					Sleep(100)
					$lMe = GetAgentByID(-2)
				Until DllStructGetData($lMe, 'MoveX') == 0 And DllStructGetData($lMe, 'MoveY') == 0
				$lBlockedTimer = TimerInit()
				Do
					Sleep(3)
					$lItemExists = IsDllStruct(GetAgentByID($i))
				Until Not $lItemExists Or TimerDiff($lBlockedTimer) > Random(5000, 7500, 1)
				If $lItemExists Then $lBlockedCount += 1
			Until Not $lItemExists Or $lBlockedCount > 5
		EndIf
	Next
EndFunc


Func CheckForLoot3()
	Local $lMe
	Local $lBlockedTimer
	Local $lBlockedCount = 0
	Local $lItemExists = True

	For $i = 1 To GetMaxAgents()
		$lMe = GetAgentByID(-2)
		$lAgent = GetAgentByID($i)
		If Not GetIsMovable($lAgent) Then ContinueLoop
		If Not GetCanPickUp($lAgent) Then ContinueLoop
		$lItem = GetItemByAgentID($i)
		If ShouldPickItem($lItem) Then
			Do
				PickUpItem($lItem)
				Sleep(GetPing() + 5)
				Do
					Sleep(5)
					$lMe = GetAgentByID(-2)
				Until DllStructGetData($lMe, 'MoveX') == 0 And DllStructGetData($lMe, 'MoveY') == 0
				$lBlockedTimer = TimerInit()
				Do
					Sleep(3)
					$lItemExists = IsDllStruct(GetAgentByID($i))
				Until Not $lItemExists Or TimerDiff($lBlockedTimer) > Random(5000, 7500, 1)
				If $lItemExists Then $lBlockedCount += 1
			Until Not $lItemExists Or $lBlockedCount > 5
			Do
				If GetMapLoading() == 2 Then Disconnected()
				If $lBlockedCount > 2 Then UseSkillEx(6,-2)
				PickUpItem($lItem)
				Sleep(GetPing())
				Do
					Sleep(1)
					$lMe = GetAgentByID(-2)
				Until DllStructGetData($lMe, 'MoveX') == 0 And DllStructGetData($lMe, 'MoveY') == 0
				$lBlockedTimer = TimerInit()
				Do
					Sleep(3)
					$lItemExists = IsDllStruct(GetAgentByID($i))
				Until Not $lItemExists Or TimerDiff($lBlockedTimer) > Random(5000, 7500, 1)
				If $lItemExists Then $lBlockedCount += 1
			Until Not $lItemExists Or $lBlockedCount > 5
		EndIf
	Next
EndFunc


Func CheckForLoot4()
	Local $lMe
	Local $lBlockedTimer
	Local $lBlockedCount = 0
	Local $lItemExists = True

	For $i = 1 To GetMaxAgents()
		$lMe = GetAgentByID(-2)
		$lAgent = GetAgentByID($i)
		If Not GetIsMovable($lAgent) Then ContinueLoop
		If Not GetCanPickUp($lAgent) Then ContinueLoop
		$lItem = GetItemByAgentID($i)
		If ShouldPickItem($lItem) Then
			Do
				PickUpItem($lItem)
				Sleep(GetPing() + 5)
				Do
					Sleep(5)
					$lMe = GetAgentByID(-2)
				Until DllStructGetData($lMe, 'MoveX') == 0 And DllStructGetData($lMe, 'MoveY') == 0
				$lBlockedTimer = TimerInit()
				Do
					Sleep(3)
					$lItemExists = IsDllStruct(GetAgentByID($i))
				Until Not $lItemExists Or TimerDiff($lBlockedTimer) > Random(5000, 7500, 1)
				If $lItemExists Then $lBlockedCount += 1
			Until Not $lItemExists Or $lBlockedCount > 5
			Do
				If GetMapLoading() == 2 Then Disconnected()
				If $lBlockedCount > 2 Then UseSkillEx(6,-2)
				PickUpItem($lItem)
				Sleep(GetPing())
				Do
					Sleep(1)
					$lMe = GetAgentByID(-2)
				Until DllStructGetData($lMe, 'MoveX') == 0 And DllStructGetData($lMe, 'MoveY') == 0
				$lBlockedTimer = TimerInit()
				Do
					Sleep(3)
					$lItemExists = IsDllStruct(GetAgentByID($i))
				Until Not $lItemExists Or TimerDiff($lBlockedTimer) > Random(5000, 7500, 1)
				If $lItemExists Then $lBlockedCount += 1
			Until Not $lItemExists Or $lBlockedCount > 5
		EndIf
	Next
EndFunc
#EndRegion Functions