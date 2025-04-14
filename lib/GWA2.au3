#CS
Author: gigi
Modified by: MrZambix, Night, and more
#CE

#include-once
; Required for memory access, opening external process handles and injecting code
#RequireAdmin

; Additional directives
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile_type=a3x
#AutoIt3Wrapper_Run_AU3Check=n
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/pe /sf /tl
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

If @AutoItX64 Then
	MsgBox(16, 'Error!', 'Please run all bots in 32-bit (x86) mode.')
	Exit 1
EndIf


#Region Declarations
Global $gwa2Version = '0.0.0'
; Windows and process handles
Global $kernelHandle, $processHandle, $windowHandle

; Memory interaction
Global $baseAddress = 0x00C50000
Global $memoryInterface
Global $asmInjectionString, $asmInjectionSize, $asmCodeOffset
Global $packetlocation

; Flags
Global $disableRendering

; GUI
Global $mainGui = GUICreate('GWA2')

; Game-related variables
; Game memory - queue, targets, skills
Global $queueCounter, $queueSize, $queueBaseAddress
Global $stringLogBaseAddress, $skillBaseAddress
Global $myID

; Language flag
Global $forceEnglishLanguageFlag

; Agent state
Global $currentTargetAgentId

; Agent structures
Global $agentBaseAddress, $baseAddressPtr, $agentArrayAddress

; Regional and account info
Global $regionId, $languageId
Global $currentPing, $characterSlots, $characterName

; Map status
Global $maxAgents, $isLoggedIn, $agentCopyCount, $agentCopyBase

; Trader system
Global $traderQuoteId, $traderCostId, $traderCostValue

; Skill state
Global $skillTimer, $buildNumber

; Temporary values
Global $tempValue

; Zoom levels
Global $zoomWhenStill, $zoomWhenMoving

; Event state
Global $currentStatus, $lastDialogId
Global $skillActivateEvent, $skillCancelEvent, $skillCompleteEvent, $loadFinishedEvent

; Optional systems
Global $useStringLogging, $useEventSystem

; Character info
Global $instanceInfoPtr, $areaInfoPtr
Global $attributeInfoPtr
Global $mapID, $mapLoading, $mapIsLoaded
#EndRegion Declarations


#Region CommandStructs
Global $inviteGuildStruct = DllStructCreate('ptr;dword;dword header;dword counter;wchar name[32];dword type')			;	commandPackSendPtr;-;-;-;characterName;-
Global $inviteGuildStructPtr = DllStructGetPtr($inviteGuildStruct)

Global $useSkillStruct = DllStructCreate('ptr;dword;dword;dword')														;	useSkillCommandPtr;skillSlot,targetID,callTarget
Global $useSkillStructPtr = DllStructGetPtr($useSkillStruct)

Global $moveStruct = DllStructCreate('ptr;float;float;float')															;	commandMovePtr;X;Y;-
Global $moveStructPtr = DllStructGetPtr($moveStruct)

Global $changeTargetStruct = DllStructCreate('ptr;dword')																;	commandChangeTargetPtr;targetID
Global $changeTargetStructPtr = DllStructGetPtr($changeTargetStruct)

Global $packetStruct = DllStructCreate('ptr;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword')	;	commandPackSendPtr;-;-;-;characterName;-
Global $packetStructPtr = DllStructGetPtr($packetStruct)

Global $writeChatStruct = DllStructCreate('ptr')																			;	commandWriteChatPtr
Global $writeChatStructPtr = DllStructGetPtr($writeChatStruct)

Global $sellItemStruct = DllStructCreate('ptr;dword;dword;dword')														;	commandSellItemPtr;totalSoldValue;itemID;ScanBuyItemBase
Global $sellItemStructPtr = DllStructGetPtr($sellItemStruct)

Global $actionStruct = DllStructCreate('ptr;dword;dword;')																;	commandActionPtr;action;flag
Global $actionStructPtr = DllStructGetPtr($actionStruct)

Global $toggleLanguageStruct = DllStructCreate('ptr;dword')																;	commandToggleLanguagePtr;-
Global $toggleLanguageStructPtr = DllStructGetPtr($toggleLanguageStruct)

Global $useHeroSkillStruct = DllStructCreate('ptr;dword;dword;dword')													;	etc...
Global $useHeroSkillStructPtr = DllStructGetPtr($useHeroSkillStruct)

Global $buyItemStruct = DllStructCreate('ptr;dword;dword;dword;dword')
Global $buyItemStructPtr = DllStructGetPtr($buyItemStruct)

Global $craftItemStruct = DllStructCreate('ptr;dword;dword;ptr;dword;dword')
Global $craftItemStructPtr = DllStructGetPtr($craftItemStruct)

Global $sendChatStruct = DllStructCreate('ptr;dword')
Global $sendChatStructPtr = DllStructGetPtr($sendChatStruct)

Global $requestQuoteStruct = DllStructCreate('ptr;dword')
Global $requestQuoteStructPtr = DllStructGetPtr($requestQuoteStruct)

Global $requestQuoteStructSell = DllStructCreate('ptr;dword')
Global $requestQuoteStructSellPtr = DllStructGetPtr($requestQuoteStructSell)

Global $traderBuyStruct = DllStructCreate('ptr')
Global $traderBuyStructPtr = DllStructGetPtr($traderBuyStruct)

Global $traderSellStruct = DllStructCreate('ptr')
Global $traderSellStructPtr = DllStructGetPtr($traderSellStruct)

Global $salvageStruct = DllStructCreate('ptr;dword;dword;dword')
Global $salvageStructPtr = DllStructGetPtr($salvageStruct)

Global $increaseAttributeStruct = DllStructCreate('ptr;dword;dword')
Global $increaseAttributeStructPtr = DllStructGetPtr($increaseAttributeStruct)

Global $decreaseAttributeStruct = DllStructCreate('ptr;dword;dword')
Global $decreaseAttributeStructPtr = DllStructGetPtr($decreaseAttributeStruct)

Global $maxAttributesStruct = DllStructCreate('ptr;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword')
Global $maxAttributesStructPtr = DllStructGetPtr($maxAttributesStruct)

Global $setAttributesStruct = DllStructCreate('ptr;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword')
Global $setAttributesStructPtr = DllStructGetPtr($setAttributesStruct)

Global $makeAgentArrayStruct = DllStructCreate('ptr;dword')
Global $makeAgentArrayStructPtr = DllStructGetPtr($makeAgentArrayStruct)

Global $changeStatusStruct = DllStructCreate('ptr;dword')
Global $changeStatusStructPtr = DllStructGetPtr($changeStatusStruct)

Global $tradeHackAddress
Global $labelsStruct[1][2]
#EndRegion CommandStructs

#Region GWA2 Structs
;Don't create global DllStruct for those (can exist simultaneously in several instances)
Global $agentStructTemplate = 'ptr vtable;dword unknown1[4];dword timer;dword timer2;ptr nextAgent;dword unknown2[3];long Id;float Z;float width1;float height1;float width2;float height2;float width3;float height3;float rotation;float rotation_cos;float rotation_sin;dword NameProperties;dword ground;dword h0060;float terrain_normal_x;float terrain_normal_y;dword terrain_normal_z;byte h0070[4];float X;float Y;dword plane;byte h0080[4];float NameTagX;float NameTagY;float NameTagZ;short visual_effects;short h0092;dword h0094[2];long Type;float MoveX;float MoveY;dword h00A8;float rotation_cos2;float rotation_sin2;dword h00B4[4];long Owner;dword ItemID;dword ExtraType;dword GadgetID;dword h00D4[3];float animation_type;dword h00E4[2];float AttackSpeed;float AttackSpeedModifier;short PlayerNumber;short agent_model_type;dword transmog_npc_id;ptr Equip;dword h0100;ptr tags;short h0108;byte Primary;byte Secondary;byte Level;byte Team;byte h010E[2];dword h0110;float energy_regen;float overcast;float EnergyPercent;dword MaxEnergy;dword h0124;float HPPips;dword h012C;float HP;dword MaxHP;dword Effects;dword h013C;byte Hex;byte h0141[19];dword ModelState;dword TypeMap;dword h015C[4];dword InSpiritRange;dword visible_effects;dword visible_effects_ID;dword visible_effects_has_ended;dword h017C;dword LoginNumber;float animation_speed;dword animation_code;dword animation_id;byte h0190[32];byte LastStrike;byte Allegiance;short WeaponType;short Skill;short h01B6;byte weapon_item_type;byte offhand_item_type;short WeaponItemId;short OffhandItemId'
Global $buffStructTemplate = 'long SkillId;long unknown1;long BuffId;long TargetId'
Global $effectStructTemplate = 'long SkillId;long AttributeLevel;long EffectId;long AgentId;float Duration;long TimeStamp'
Global $skillbarStructTemplate = 'long AgentId;long AdrenalineA1;long AdrenalineB1;dword Recharge1;dword Id1;dword Event1;long AdrenalineA2;long AdrenalineB2;dword Recharge2;dword Id2;dword Event2;long AdrenalineA3;long AdrenalineB3;dword Recharge3;dword Id3;dword Event3;long AdrenalineA4;long AdrenalineB4;dword Recharge4;dword Id4;dword Event4;long AdrenalineA5;long AdrenalineB5;dword Recharge5;dword Id5;dword Event5;long AdrenalineA6;long AdrenalineB6;dword Recharge6;dword Id6;dword Event6;long AdrenalineA7;long AdrenalineB7;dword Recharge7;dword Id7;dword Event7;long AdrenalineA8;long AdrenalineB8;dword Recharge8;dword Id8;dword Event8;dword disabled;long unknown1[2];dword Casting;long unknown2[2]'
Global $skillStructTemplate = 'long ID;long Unknown1;long campaign;long Type;long Special;long ComboReq;long Effect1;long Condition;long Effect2;long WeaponReq;byte Profession;byte Attribute;short Title;long PvPID;byte Combo;byte Target;byte unknown3;byte EquipType;byte Overcast;byte EnergyCost;byte HealthCost;byte unknown4;dword Adrenaline;float Activation;float Aftercast;long Duration0;long Duration15;long Recharge;long Unknown5[4];dword SkillArguments;long Scale0;long Scale15;long BonusScale0;long BonusScale15;float AoERange;float ConstEffect;dword caster_overhead_animation_id;dword caster_body_animation_id;dword target_body_animation_id;dword target_overhead_animation_id;dword projectile_animation_1_id;dword projectile_animation_2_id;dword icon_file_id;dword icon_file_id_2;dword name;dword concise;dword description'
Global $attributeStructTemplate = 'dword profession_id;dword attribute_id;dword name_id;dword desc_id;dword is_pve'
Global $bagStructTemplate = 'long TypeBag;long index;long id;ptr containerItem;long ItemsCount;ptr bagArray;ptr itemArray;long fakeSlots;long slots'
Global $itemStructTemplate = 'long Id;long AgentId;ptr BagEquiped;ptr Bag;ptr ModStruct;long ModStructSize;ptr Customized;long ModelFileID;byte Type;byte unknown1;short ExtraId;short Value;byte unknown2[2];short Interaction;long ModelId;ptr ModString;ptr NameEnc;ptr NameString;ptr SingleItemName;byte unknown3[8];short ItemFormula;byte IsSalvageable;byte unknown4;byte Quantity;byte Equipped;byte Profession;byte Type2;byte Slot'
Global $questStructTemplate = 'long id;long LogState;ptr Location;ptr Name;ptr NPC;long MapFrom;float X;float Y;long Z;long unlnown1;long MapTo;ptr Description;ptr Objective'
;Grey area, unlikely to exist several at the same time
Global $areaInfoStructTemplate = 'dword campaign;dword continent;dword region;dword regiontype;dword flags;dword thumbnail_id;dword min_party_size;dword max_party_size;dword min_player_size;dword max_player_size;dword controlled_outpost_id;dword fraction_mission;dword min_level;dword max_level;dword needed_pq;dword mission_maps_to;dword x;dword y;dword icon_start_x;dword icon_start_y;dword icon_end_x;dword icon_end_y;dword icon_start_x_dupe;dword icon_start_y_dupe;dword icon_end_x_dupe;dword icon_end_y_dupe;dword file_id;dword mission_chronology;dword ha_map_chronology;dword name_id;dword description_id'
;Safe zone, can just create DllStruct globally
Global $worldStruct = DllStructCreate('long MinGridWidth;long MinGridHeight;long MaxGridWidth;long MaxGridHeight;long Flags;long Type;long SubGridWidth;long SubGridHeight;long StartPosX;long StartPosY;long MapWidth;long MapHeight')
;Considered to be added in non-global - but since code is synchronous those shouldn't really get overwritten
;useSkillStruct
;moveStruct
;changeTargetStruct
;packetStruct
;useHeroSkillStruct
#EndRegion

#Region Memory
;~ Opens a process for memory manipulation based on the provided process ID.
Func MemoryOpen($pid)
	$kernelHandle = DllOpen('kernel32.dll')
	Local $openProcess = DllCall($kernelHandle, 'int', 'OpenProcess', 'int', 0x1F0FFF, 'int', 1, 'int', $pid)
	$processHandle = $openProcess[0]
EndFunc


;~ Closes the opened process handle, releasing any associated resources.
Func MemoryClose()
	DllCall($kernelHandle, 'int', 'CloseHandle', 'int', $processHandle)
	DllClose($kernelHandle)
EndFunc


;~ Writes a binary string to a specified memory address in the process.
Func WriteBinary($binaryString, $address)
	Local $data = DllStructCreate('byte[' & 0.5 * StringLen($binaryString) & ']'), $i
	For $i = 1 To DllStructGetSize($data)
		DllStructSetData($data, 1, Dec(StringMid($binaryString, 2 * $i - 1, 2)), $i)
	Next
	DllCall($kernelHandle, 'int', 'WriteProcessMemory', 'int', $processHandle, 'ptr', $address, 'ptr', DllStructGetPtr($data), 'int', DllStructGetSize($data), 'int', 0)
EndFunc


;~ Writes the specified data to a memory address of a given type (default is 'dword').
Func MemoryWrite($address, $data, $type = 'dword')
	Local $buffer = DllStructCreate($type)
	DllStructSetData($buffer, 1, $data)
	DllCall($kernelHandle, 'int', 'WriteProcessMemory', 'int', $processHandle, 'int', $address, 'ptr', DllStructGetPtr($buffer), 'int', DllStructGetSize($buffer), 'int', '')
EndFunc


;~ Reads data from a memory address, returning it as the specified type (defaults to dword).
Func MemoryRead($address, $type = 'dword')
	Local $buffer = DllStructCreate($type)
	DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $address, 'ptr', DllStructGetPtr($buffer), 'int', DllStructGetSize($buffer), 'int', '')
	Return DllStructGetData($buffer, 1)
EndFunc


;~ Reads data from a memory address, following pointer chains based on the provided offsets.
Func MemoryReadPtr($address, $offset, $type = 'dword')
	Local $ptrCount = UBound($offset) - 2
	Local $buffer = DllStructCreate('dword')
	For $i = 0 To $ptrCount
		$address += $offset[$i]
		DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $address, 'ptr', DllStructGetPtr($buffer), 'int', DllStructGetSize($buffer), 'int', '')
		$address = DllStructGetData($buffer, 1)
		If $address == 0 Then
			Local $data[2] = [0, 0]
			Return $data
		EndIf
	Next
	$address += $offset[$ptrCount + 1]
	$buffer = DllStructCreate($type)
	DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $address, 'ptr', DllStructGetPtr($buffer), 'int', DllStructGetSize($buffer), 'int', '')
	Local $data[2] = [$address, DllStructGetData($buffer, 1)]
	Return $data
EndFunc


;~ Swaps the byte order (endianness) of a given hexadecimal string.
Func SwapEndian($hex)
	Return StringMid($hex, 7, 2) & StringMid($hex, 5, 2) & StringMid($hex, 3, 2) & StringMid($hex, 1, 2)
EndFunc
#EndRegion Memory


#Region Initialisation
;~ Returns a list of logged characters
Func GetLoggedCharNames()
	Local $array = ScanGameClientsForCharacters()
	; No characters logged
	If $array[0] == 0 Then Return ''
	Local $result = $array[1]
	For $i = 2 To $array[0]
		$result &= '|' & $array[$i]
	Next
	Return $result
EndFunc


;~ Returns an array of logged characters of gw windows (at pos 0 there is the size of the array)
Func ScanGameClientsForCharacters()
	Local $processList = ProcessList('gw.exe')
	Local $returnArray[1] = [0]

	For $i = 1 To $processList[0][0]
		MemoryOpen($processList[$i][1])

		If $processHandle Then
			$returnArray[0] += 1
			ReDim $returnArray[$returnArray[0] + 1]
			$returnArray[$returnArray[0]] = ScanForCharname()
		EndIf

		MemoryClose()

		$processHandle = 0
	Next

	Return $returnArray
EndFunc


; Retrieves the window handle for the specified game process
Func GetWindowHandleForProcess($process)
	Local $wins = WinList()
	For $i = 1 To UBound($wins) - 1
		If (WinGetProcess($wins[$i][1]) == $process) And (BitAND(WinGetState($wins[$i][1]), 2)) Then Return $wins[$i][1]
	Next
EndFunc


;~ Injects GWA2 into the game client.
Func InitializeGameClientData($gwProcess, $changeTitle = True, $initUseStringLog = False, $initUseEventSystem = True)
	Local $gwProcessID
	$useStringLogging = $initUseStringLog
	$useEventSystem = $initUseEventSystem

	; Check if $gwProcess is a string or a process ID
	If IsString($gwProcess) Then
		; Find the process ID of the game client
		Local $processList = ProcessList('gw.exe')
		For $i = 1 To $processList[0][0]
			$gwProcessID = $processList[$i][1]
			$windowHandle = GetWindowHandleForProcess($gwProcessID)
			MemoryOpen($gwProcessID)
			If $processHandle Then
				; Check if the character name matches
				If StringRegExp(ScanForCharname(), $gwProcess) = 1 Then ExitLoop
			EndIf
			MemoryClose()
			$processHandle = 0
		Next
	Else
		; Use the provided process ID
		$gwProcessID = $gwProcess
		$windowHandle = GetWindowHandleForProcess($gwProcessID)
		MemoryOpen($gwProcess)
		ScanForCharname()
	EndIf

	ScanGWBasePatterns()
	
	; Read memory values for game data
	$baseAddressPtr = MemoryRead(GetScannedAddress('ScanBasePointer', 8))
	If @error Then logCriticalErrors('Failed to read base pointer')
	SetValue('BasePointer', '0x' & Hex($baseAddressPtr, 8))
	
	$regionId = MemoryRead(GetScannedAddress('ScanRegion', -0x3))
	$instanceInfoPtr = MemoryRead(GetScannedAddress('ScanInstanceInfo', 0xE))
	$areaInfoPtr = MemoryRead(GetScannedAddress('ScanAreaInfo', 0x6))
	$attributeInfoPtr = MemoryRead(GetScannedAddress('ScanAttributeInfo', -0x3))

	SetValue('StringLogStart', '0x' & Hex(GetScannedAddress('ScanStringLog', 0x16), 8))
	SetValue('LoadFinishedStart', '0x' & Hex(GetScannedAddress('ScanLoadFinished', 1), 8))
	SetValue('LoadFinishedReturn', '0x' & Hex(GetScannedAddress('ScanLoadFinished', 6), 8))
	
	$agentBaseAddress = MemoryRead(GetScannedAddress('ScanAgentBasePointer', 8) + 0xC - 7)
	If @error Then logCriticalErrors('Failed to read agent base')
	SetValue('AgentBase', '0x' & Hex($agentBaseAddress, 8))
	$maxAgents = $agentBaseAddress + 8
	SetValue('MaxAgents', '0x' & Hex($maxAgents, 8))
	$agentArrayAddress = MemoryRead(GetScannedAddress('ScanAgentArray', -0x3))
	If @error Then logCriticalErrors('Failed to read agent array')

	$myID = MemoryRead(GetScannedAddress('ScanMyID', -3))
	If @error Then logCriticalErrors('Failed to read my ID')
	SetValue('MyID', '0x' & Hex($myID, 8))

	$currentTargetAgentId = MemoryRead(GetScannedAddress('ScanCurrentTarget', -14))
	If @error Then logCriticalErrors('Failed to read current target')

	$packetlocation = Hex(MemoryRead(GetScannedAddress('ScanBaseOffset', 11)), 8)
	If @error Then logCriticalErrors('Failed to read packet location')
	SetValue('PacketLocation', '0x' & $packetlocation)

	$currentPing = MemoryRead(GetScannedAddress('ScanPing', -0x14))
	If @error Then logCriticalErrors('Failed to read ping')

	$mapID = MemoryRead(GetScannedAddress('ScanMapID', 28))
	If @error Then logCriticalErrors('Failed to read map ID')

	$mapLoading = MemoryRead(GetScannedAddress('ScanMapLoading', 0xB))
	If @error Then logCriticalErrors('Failed to read loading status')

	$isLoggedIn = MemoryRead(GetScannedAddress('ScanLoggedIn', 0x3))
	If @error Then logCriticalErrors('Failed to read login status')

	$languageId = MemoryRead(GetScannedAddress('ScanMapInfo', 11)) + 0xC
	If @error Then logCriticalErrors('Failed to read language and region')

	$skillBaseAddress = MemoryRead(GetScannedAddress('ScanSkillBase', 8))
	If @error Then logCriticalErrors('Failed to read skill base')

	$skillTimer = MemoryRead(GetScannedAddress('ScanSkillTimer', -3))
	If @error Then logCriticalErrors('Failed to read skill timer')

	$tempValue = GetScannedAddress('ScanBuildNumber', 0x2C)
	If @error Then logCriticalErrors('Failed to read build number address')
	
	$buildNumber = MemoryRead($tempValue + MemoryRead($tempValue) + 5)
	If @error Then logCriticalErrors('Failed to read build number')

	$zoomWhenStill = GetScannedAddress('ScanZoomStill', 0x33)
	If @error Then logCriticalErrors('Failed to read zoom still address')

	$zoomWhenMoving = GetScannedAddress('ScanZoomMoving', 0x21)
	If @error Then logCriticalErrors('Failed to read zoom moving address')

	$currentStatus = MemoryRead(GetScannedAddress('ScanChangeStatusFunction', 35))
	If @error Then logCriticalErrors('Failed to read current status')
	
	;$characterSlots = MemoryRead(GetScannedAddress('ScanCharslots', 22))
	;If @error Then logCriticalErrors('Failed to read character slots')

	$tempValue = GetScannedAddress('ScanEngine', -0x22)
	If @error Then logCriticalErrors('Failed to read engine address')
	SetValue('MainStart', '0x' & Hex($tempValue, 8))
	SetValue('MainReturn', '0x' & Hex($tempValue + 5, 8))
	
	$tempValue = GetScannedAddress('ScanRenderFunc', -0x67)
	If @error Then logCriticalErrors('Failed to read render function address')
	SetValue('RenderingMod', '0x' & Hex($tempValue, 8))
	SetValue('RenderingModReturn', '0x' & Hex($tempValue + 10, 8))
	
	$tempValue = GetScannedAddress('ScanTargetLog', 1)
	If @error Then logCriticalErrors('Failed to read target log address')
	SetValue('TargetLogStart', '0x' & Hex($tempValue, 8))
	SetValue('TargetLogReturn', '0x' & Hex($tempValue + 5, 8))
	
	$tempValue = GetScannedAddress('ScanSkillLog', 1)
	If @error Then logCriticalErrors('Failed to read skill log address')
	SetValue('SkillLogStart', '0x' & Hex($tempValue, 8))
	SetValue('SkillLogReturn', '0x' & Hex($tempValue + 5, 8))
	
	$tempValue = GetScannedAddress('ScanSkillCompleteLog', -4)
	If @error Then logCriticalErrors('Failed to read skill complete log address')
	SetValue('SkillCompleteLogStart', '0x' & Hex($tempValue, 8))
	SetValue('SkillCompleteLogReturn', '0x' & Hex($tempValue + 5, 8))
	
	$tempValue = GetScannedAddress('ScanSkillCancelLog', 5)
	If @error Then logCriticalErrors('Failed to read skill cancel log address')
	SetValue('SkillCancelLogStart', '0x' & Hex($tempValue, 8))
	SetValue('SkillCancelLogReturn', '0x' & Hex($tempValue + 6, 8))
	
	$tempValue = GetScannedAddress('ScanChatLog', 18)
	If @error Then logCriticalErrors('Failed to read chat log address')
	SetValue('ChatLogStart', '0x' & Hex($tempValue, 8))
	SetValue('ChatLogReturn', '0x' & Hex($tempValue + 6, 8))
	
	$tempValue = GetScannedAddress('ScanTraderHook', -0x2F)    ; was -7
	If @error Then logCriticalErrors('Failed to read trader hook address')
	SetValue('TraderHookStart', '0x' & Hex($tempValue, 8))
	SetValue('TraderHookReturn', '0x' & Hex($tempValue + 5, 8))

	$tempValue = GetScannedAddress('ScanDialogLog', -4)
	If @error Then logCriticalErrors('Failed to read dialog log address')
	SetValue('DialogLogStart', '0x' & Hex($tempValue, 8))
	SetValue('DialogLogReturn', '0x' & Hex($tempValue + 5, 8))
	
	$tempValue = GetScannedAddress('ScanStringFilter1', -5)    ; was -0x23
	If @error Then logCriticalErrors('Failed to read string filter 1 address')
	SetValue('StringFilter1Start', '0x' & Hex($tempValue, 8))
	SetValue('StringFilter1Return', '0x' & Hex($tempValue + 5, 8))
	
	$tempValue = GetScannedAddress('ScanStringFilter2', 0x16)    ; was 0x61
	If @error Then logCriticalErrors('Failed to read string filter 2 address')
	SetValue('StringFilter2Start', '0x' & Hex($tempValue, 8))
	SetValue('StringFilter2Return', '0x' & Hex($tempValue + 5, 8))
	
	SetValue('PostMessage', '0x' & Hex(MemoryRead(GetScannedAddress('ScanPostMessage', 11)), 8))
	If @error Then logCriticalErrors('Failed to read post message')
	SetValue('Sleep', MemoryRead(MemoryRead(GetValue('ScanSleep') + 8) + 3))
	If @error Then logCriticalErrors('Failed to read sleep')
	SetValue('SalvageFunction', '0x' & Hex(GetScannedAddress('ScanSalvageFunction', -10), 8))
	If @error Then logCriticalErrors('Failed to read salvage function')
	SetValue('SalvageGlobal', '0x' & Hex(MemoryRead(GetScannedAddress('ScanSalvageGlobal', 1) - 0x4), 8))
	If @error Then logCriticalErrors('Failed to read salvage global')
	SetValue('IncreaseAttributeFunction', '0x' & Hex(GetScannedAddress('ScanIncreaseAttributeFunction', -0x5A), 8))
	If @error Then logCriticalErrors('Failed to read increase attribute function')
	SetValue('DecreaseAttributeFunction', '0x' & Hex(GetScannedAddress('ScanDecreaseAttributeFunction', 25), 8))
	If @error Then logCriticalErrors('Failed to read decrease attribute function')
	SetValue('MoveFunction', '0x' & Hex(GetScannedAddress('ScanMoveFunction', 1), 8))
	If @error Then logCriticalErrors('Failed to read move function')
	SetValue('UseSkillFunction', '0x' & Hex(GetScannedAddress('ScanUseSkillFunction', -0x125), 8))
	If @error Then logCriticalErrors('Failed to read use skill function')
	SetValue('ChangeTargetFunction', '0x' & Hex(GetScannedAddress('ScanChangeTargetFunction', -0x0086) + 1, 8))
	If @error Then logCriticalErrors('Failed to read change target function')
	SetValue('WriteChatFunction', '0x' & Hex(GetScannedAddress('ScanWriteChatFunction', -0x3D), 8))
	If @error Then logCriticalErrors('Failed to read write chat function')
	SetValue('SellItemFunction', '0x' & Hex(GetScannedAddress('ScanSellItemFunction', -85), 8))
	If @error Then logCriticalErrors('Failed to read sell item function')
	SetValue('PacketSendFunction', '0x' & Hex(GetScannedAddress('ScanPacketSendFunction', -0x50), 8))
	If @error Then logCriticalErrors('Failed to read packet send function')
	SetValue('ActionBase', '0x' & Hex(MemoryRead(GetScannedAddress('ScanActionBase', -3)), 8))
	If @error Then logCriticalErrors('Failed to read action base')
	SetValue('ActionFunction', '0x' & Hex(GetScannedAddress('ScanActionFunction', -3), 8))
	If @error Then logCriticalErrors('Failed to read action function')
	SetValue('UseHeroSkillFunction', '0x' & Hex(GetScannedAddress('ScanUseHeroSkillFunction', -0x59), 8))
	If @error Then logCriticalErrors('Failed to read use hero skill function')
	SetValue('BuyItemBase', '0x' & Hex(MemoryRead(GetScannedAddress('ScanBuyItemBase', 15)), 8))
	If @error Then logCriticalErrors('Failed to read buy item base')
	SetValue('TransactionFunction', '0x' & Hex(GetScannedAddress('ScanTransactionFunction', -0x7E), 8))
	If @error Then logCriticalErrors('Failed to read transaction function')
	SetValue('RequestQuoteFunction', '0x' & Hex(GetScannedAddress('ScanRequestQuoteFunction', -0x34), 8))
	If @error Then logCriticalErrors('Failed to read request quote function')
	SetValue('TraderFunction', '0x' & Hex(GetScannedAddress('ScanTraderFunction', -0x1E), 8))
	If @error Then logCriticalErrors('Failed to read trader function')
	SetValue('ClickToMoveFix', '0x' & Hex(GetScannedAddress('ScanClickToMoveFix', 1), 8))
	If @error Then logCriticalErrors('Failed to read click to move fix')
	SetValue('ChangeStatusFunction', '0x' & Hex(GetScannedAddress('ScanChangeStatusFunction', 1), 8))
	If @error Then logCriticalErrors('Failed to read change status function')
	SetValue('QueueSize', '0x00000010')
	SetValue('SkillLogSize', '0x00000010')
	SetValue('ChatLogSize', '0x00000010')
	SetValue('TargetLogSize', '0x00000200')
	SetValue('StringLogSize', '0x00000200')
	SetValue('CallbackEvent', '0x00000501')
	$tradeHackAddress = GetScannedAddress('ScanTradeHack', 0)
	If @error Then logCriticalErrors('Failed to read trade hack address')
	ModifyMemory()

	$queueCounter = MemoryRead(GetValue('QueueCounter'))
	If @error Then logCriticalErrors('Failed to read queue counter')
	$queueSize = GetValue('QueueSize') - 1
	$queueBaseAddress = GetValue('QueueBase')
	;$targetLogBase = GetValue('TargetLogBase')
	$stringLogBaseAddress = GetValue('StringLogBase')
	$mapIsLoaded = GetValue('MapIsLoaded')
	$forceEnglishLanguageFlag = GetValue('EnsureEnglish')
	$traderQuoteId = GetValue('TraderQuoteID')
	$traderCostId = GetValue('TraderCostID')
	$traderCostValue = GetValue('TraderCostValue')
	$disableRendering = GetValue('DisableRendering')
	$agentCopyCount = GetValue('AgentCopyCount')
	$agentCopyBase = GetValue('AgentCopyBase')
	$lastDialogId = GetValue('LastDialogID')

	; EventSystem
	If $useEventSystem Then MemoryWrite(GetValue('CallbackHandle'), $mainGui)
	If @error Then logCriticalErrors('Failed to write CallbackHandle')
	DllStructSetData($inviteGuildStruct, 1, GetValue('CommandPacketSend'))
	If @error Then logCriticalErrors('Failed to set invite guild command')
	DllStructSetData($inviteGuildStruct, 2, 0x4C)
	If @error Then logCriticalErrors('Failed to set invite guild subcommand')
	DllStructSetData($useSkillStruct, 1, GetValue('CommandUseSkill'))
	If @error Then logCriticalErrors('Failed to set CommandUseSkill command')
	DllStructSetData($moveStruct, 1, GetValue('CommandMove'))
	If @error Then logCriticalErrors('Failed to set CommandMove command')
	DllStructSetData($changeTargetStruct, 1, GetValue('CommandChangeTarget'))
	If @error Then logCriticalErrors('Failed to set CommandChangeTarget command')
	DllStructSetData($packetStruct, 1, GetValue('CommandPacketSend'))
	If @error Then logCriticalErrors('Failed to set CommandPacketSend command')
	DllStructSetData($sellItemStruct, 1, GetValue('CommandSellItem'))
	If @error Then logCriticalErrors('Failed to set CommandSellItem command')
	DllStructSetData($actionStruct, 1, GetValue('CommandAction'))
	If @error Then logCriticalErrors('Failed to set CommandAction command')
	DllStructSetData($toggleLanguageStruct, 1, GetValue('CommandToggleLanguage'))
	If @error Then logCriticalErrors('Failed to set CommandToggleLanguage command')
	DllStructSetData($useHeroSkillStruct, 1, GetValue('CommandUseHeroSkill'))
	If @error Then logCriticalErrors('Failed to set CommandUseHeroSkill command')
	DllStructSetData($buyItemStruct, 1, GetValue('CommandBuyItem'))
	If @error Then logCriticalErrors('Failed to set CommandBuyItem command')
	DllStructSetData($sendChatStruct, 1, GetValue('CommandSendChat'))
	If @error Then logCriticalErrors('Failed to set CommandSendChat command')
	DllStructSetData($sendChatStruct, 2, $HEADER_SEND_CHAT)
	If @error Then logCriticalErrors('Failed to set send chat subcommand')
	DllStructSetData($writeChatStruct, 1, GetValue('CommandWriteChat'))
	If @error Then logCriticalErrors('Failed to set CommandWriteChat command')
	DllStructSetData($requestQuoteStruct, 1, GetValue('CommandRequestQuote'))
	If @error Then logCriticalErrors('Failed to set CommandRequestQuote command')
	DllStructSetData($requestQuoteStructSell, 1, GetValue('CommandRequestQuoteSell'))
	If @error Then logCriticalErrors('Failed to set CommandRequestQuoteSell command')
	DllStructSetData($traderBuyStruct, 1, GetValue('CommandTraderBuy'))
	If @error Then logCriticalErrors('Failed to set CommandTraderBuy command')
	DllStructSetData($traderSellStruct, 1, GetValue('CommandTraderSell'))
	If @error Then logCriticalErrors('Failed to set CommandTraderSell command')
	DllStructSetData($salvageStruct, 1, GetValue('CommandSalvage'))
	If @error Then logCriticalErrors('Failed to set CommandSalvage command')
	DllStructSetData($increaseAttributeStruct, 1, GetValue('CommandIncreaseAttribute'))
	If @error Then logCriticalErrors('Failed to set CommandIncreaseAttribute command')
	DllStructSetData($decreaseAttributeStruct, 1, GetValue('CommandDecreaseAttribute'))
	If @error Then logCriticalErrors('Failed to set CommandDecreaseAttribute command')
	DllStructSetData($makeAgentArrayStruct, 1, GetValue('CommandMakeAgentArray'))
	If @error Then logCriticalErrors('Failed to set CommandMakeAgentArray command')
	DllStructSetData($changeStatusStruct, 1, GetValue('CommandChangeStatus'))
	If @error Then logCriticalErrors('Failed to set CommandChangeStatus command')
	If $changeTitle Then WinSetTitle($windowHandle, '', 'Guild Wars - ' & GetCharname())
	If @error Then logCriticalErrors('Failed to change window title')
	SetMaxMemory()
	Return $windowHandle
EndFunc


;~ Retrieves the value associated with the specified key (internal use only)
Func GetValue($key)
	For $i = 1 To $labelsStruct[0][0]
		If $labelsStruct[$i][0] = $key Then Return Number($labelsStruct[$i][1])
	Next
	Return -1
EndFunc

;~ Sets the value for the specified key (internal use only)
Func SetValue($key, $value)
	$labelsStruct[0][0] += 1
	ReDim $labelsStruct[$labelsStruct[0][0] + 1][2]
	$labelsStruct[$labelsStruct[0][0]][0] = $key
	$labelsStruct[$labelsStruct[0][0]][1] = $value
EndFunc

;~ Scan patterns for Guild Wars game client.
Func ScanGWBasePatterns()
	Local $gwBaseAddress = ScanForProcess()
	$asmInjectionSize = 0
	$asmCodeOffset = 0
	$asmInjectionString = ''

	_('MainModPtr/4')

	_('ScanBasePointer:')
	AddPatternToInjection('506A0F6A00FF35')
	_('ScanAgentBase:')
	AddPatternToInjection('FF501083C6043BF775E2')
	_('ScanAgentBasePointer:')
	AddPatternToInjection('FF501083C6043BF775E28B35')
	_('ScanAgentArray:')
	AddPatternToInjection('8B0C9085C97419')
	_('ScanCurrentTarget:')
	AddPatternToInjection('83C4085F8BE55DC3CCCCCCCCCCCCCCCCCCCCCC55')
	
	_('ScanMyID:')
	AddPatternToInjection('83EC08568BF13B15')
	_('ScanEngine:')
	AddPatternToInjection('568B3085F67478EB038D4900D9460C')
	_('ScanRenderFunc:')
	AddPatternToInjection('F6C401741C68B1010000BA')
	_('ScanLoadFinished:')
	AddPatternToInjection('8B561C8BCF52E8')
	_('ScanPostMessage:')
	AddPatternToInjection('6A00680080000051FF15')
	_('ScanTargetLog:')
	AddPatternToInjection('5356578BFA894DF4E8')
	_('ScanChangeTargetFunction:')
	AddPatternToInjection('3BDF0F95')
	_('ScanMoveFunction:')
	AddPatternToInjection('558BEC83EC208D45F0')
	_('ScanPing:')
	AddPatternToInjection('E874651600')
	
	_('ScanMapID:')
	AddPatternToInjection('558BEC8B450885C074078B')

	_('ScanMapLoading:')
	AddPatternToInjection('2480ED0000000000')

	_('ScanLoggedIn:')
	AddPatternToInjection('C705ACDE740000000000C3CCCCCCCC')

	_('ScanRegion:')
	AddPatternToInjection('8BF0EB038B750C3B')

	_('ScanMapInfo:')
	AddPatternToInjection('8BF0EB038B750C3B')

	_('ScanLanguage:')
	AddPatternToInjection('C38B75FC8B04B5')
	
	_('ScanUseSkillFunction:')
	AddPatternToInjection('85F6745B83FE1174')
	_('ScanPacketSendFunction:')
	AddPatternToInjection('C747540000000081E6')
	_('ScanBaseOffset:')
	AddPatternToInjection('83C40433C08BE55DC3A1')
	_('ScanWriteChatFunction:')
	AddPatternToInjection('8D85E0FEFFFF50681C01')
	_('ScanSkillLog:')
	AddPatternToInjection('408946105E5B5D')
	_('ScanSkillCompleteLog:')
	AddPatternToInjection('741D6A006A40')
	_('ScanSkillCancelLog:')
	AddPatternToInjection('741D6A006A48')
	_('ScanChatLog:')
	AddPatternToInjection('8B45F48B138B4DEC50')
	_('ScanSellItemFunction:')
	AddPatternToInjection('8B4D2085C90F858E')
	_('ScanStringLog:')
	AddPatternToInjection('893E8B7D10895E04397E08')
	_('ScanStringFilter1:')
	AddPatternToInjection('8B368B4F2C6A006A008B06')
	_('ScanStringFilter2:')
	AddPatternToInjection('515356578BF933D28B4F2C')
	_('ScanActionFunction:')
	AddPatternToInjection('8B7508578BF983FE09750C6876')
	_('ScanActionBase:')
	AddPatternToInjection('8D1C87899DF4')
	_('ScanSkillBase:')
	AddPatternToInjection('8D04B6C1E00505')
	_('ScanUseHeroSkillFunction:')
	AddPatternToInjection('BA02000000B954080000')
	_('ScanTransactionFunction:')
	AddPatternToInjection('85FF741D8B4D14EB08')
	_('ScanBuyItemFunction:')
	AddPatternToInjection('D9EED9580CC74004')
	_('ScanBuyItemBase:')
	AddPatternToInjection('D9EED9580CC74004')
	_('ScanRequestQuoteFunction:')
	AddPatternToInjection('8B752083FE107614')
	_('ScanTraderFunction:')
	AddPatternToInjection('83FF10761468D2210000')
	_('ScanTraderHook:')
	AddPatternToInjection('50516A466A06')
	_('ScanSleep:')
	AddPatternToInjection('6A0057FF15D8408A006860EA0000')
	_('ScanSalvageFunction:')
	AddPatternToInjection('33C58945FC8B45088945F08B450C8945F48B45108945F88D45EC506A10C745EC76')
	_('ScanSalvageGlobal:')
	AddPatternToInjection('8B4A04538945F48B4208')
	_('ScanIncreaseAttributeFunction:')
	AddPatternToInjection('8B7D088B702C8B1F3B9E00050000')
	_('ScanDecreaseAttributeFunction:')
	AddPatternToInjection('8B8AA800000089480C5DC3CC')
	_('ScanSkillTimer:')
	AddPatternToInjection('FFD68B4DF08BD88B4708')
	_('ScanClickToMoveFix:')
	AddPatternToInjection('3DD301000074')
	_('ScanZoomStill:')
	AddPatternToInjection('558BEC8B41085685C0')
	_('ScanZoomMoving:')
	AddPatternToInjection('EB358B4304')
	_('ScanBuildNumber:')
	AddPatternToInjection('558BEC83EC4053568BD9')
	_('ScanChangeStatusFunction:')
	AddPatternToInjection('558BEC568B750883FE047C14')
	_('ScanCharslots:')
	AddPatternToInjection('8B551041897E38897E3C897E34897E48897E4C890D')
	_('ScanReadChatFunction:')
	AddPatternToInjection('A128B6EB00')
	_('ScanDialogLog:')
	AddPatternToInjection('8B45088945FC8D45F8506A08C745F841')
	_('ScanTradeHack:')
	AddPatternToInjection('8BEC8B450883F846')
	_('ScanClickCoords:')
	AddPatternToInjection('8B451C85C0741CD945F8')
	_('ScanInstanceInfo:')
	AddPatternToInjection('6A2C50E80000000083C408C7')
	_('ScanAreaInfo:')
	AddPatternToInjection('6BC67C5E05')
	_('ScanAttributeInfo:')
	AddPatternToInjection('BA3300000089088d4004')
	_('ScanWorldConst:')
	AddPatternToInjection('8D0476C1E00405')

	_('ScanProc:')													; Label for the scan procedure
	_('pushad')														; Push all general-purpose registers onto the stack to save their values
	_('mov ecx,' & Hex($gwBaseAddress, 8))							; Move the base address of the Guild Wars process into the ECX register
	_('mov esi,ScanProc')											; Move the address of the ScanProc label into the ESI register
	_('ScanLoop:')													; Label for the scan loop
	_('inc ecx')													; Increment the value in the ECX register by 1
	_('mov al,byte[ecx]')											; Move the byte value at the address stored in ECX into the AL register
	_('mov edx,ScanBasePointer')									; Move the address of the ScanBasePointer into the EDX register

	_('ScanInnerLoop:')												; Label for the inner scan loop
	_('mov ebx,dword[edx]')											; Move the 4-byte value at the address stored in EDX into the EBX register
	_('cmp ebx,-1')													; Compare the value in EBX to -1
	_('jnz ScanContinue')											; Jump to the ScanContinue label if the comparison is not zero
	_('add edx,50')													; Add 50 to the value in the EDX register
	_('cmp edx,esi')												; Compare the value in EDX to the value in ESI
	_('jnz ScanInnerLoop')											; Jump to the ScanInnerLoop label if the comparison is not zero
	_('cmp ecx,' & SwapEndian(Hex($gwBaseAddress + 5238784, 8)))	; Compare the value in ECX to a specific address (+4FF000)
	_('jnz ScanLoop')												; Jump to the ScanLoop label if the comparison is not zero
	_('jmp ScanExit')												; Jump to the ScanExit label

	_('ScanContinue:')												; Label for the scan continue section
	_('lea edi,dword[edx+ebx]')										; Load the effective address of the value at EDX + EBX into the EDI register
	_('add edi,C')													; Add the value of C to the address in EDI
	_('mov ah,byte[edi]')											; Move the byte value at the address stored in EDI into the AH register
	_('cmp al,ah')													; Compare the value in AL to the value in AH
	_('jz ScanMatched')												; Jump to the ScanMatched label if the comparison is zero (i.e., the values match)
	;_('cmp ah,00')													; Added by Greg76 for scan wildcards
	;_('jz ScanMatched')											; Added by Greg76 for scan wildcards
	_('mov dword[edx],0')											; Move the value 0 into the 4-byte location at the address stored in EDX
	_('add edx,50')													; Add 50 to the value in the EDX register
	_('cmp edx,esi')												; Compare the value in EDX to the value in ESI
	_('jnz ScanInnerLoop')											; Jump to the ScanInnerLoop label if the comparison is not zero
	_('cmp ecx,' & SwapEndian(Hex($gwBaseAddress + 5238784, 8)))	; Compare the value in ECX to a specific address (+4FF000)
	_('jnz ScanLoop')												; Jump to the ScanLoop label if the comparison is not zero
	_('jmp ScanExit')												; Jump to the ScanExit label

	_('ScanMatched:')												; Label for the scan matched section
	_('inc ebx')													; Increment the value in the EBX register by 1
	_('mov edi,dword[edx+4]')										; Move the 4-byte value at the address EDX + 4 into the EDI register
	_('cmp ebx,edi')												; Compare the value in EBX to the value in EDI
	_('jz ScanFound')												; Jump to the ScanFound label if the comparison is zero (i.e., the values match)
	_('mov dword[edx],ebx')											; Move the value in EBX into the 4-byte location at the address stored in EDX
	_('add edx,50')													; Add 50 to the value in the EDX register
	_('cmp edx,esi')												; Compare the value in EDX to the value in ESI
	_('jnz ScanInnerLoop')											; Jump to the ScanInnerLoop label if the comparison is not zero
	_('cmp ecx,' & SwapEndian(Hex($gwBaseAddress + 5238784, 8)))	; Compare the value in ECX to a specific address (+4FF000)
	_('jnz ScanLoop')												; Jump to the ScanLoop label if the comparison is not zero
	_('jmp ScanExit')												; Jump to the ScanExit label

	_('ScanFound:')													; Label for the scan found section
	_('lea edi,dword[edx+8]')										; Load the effective address of the value at EDX + 8 into the EDI register
	_('mov dword[edi],ecx')											; Move the value in ECX into the 4-byte location at the address stored in EDI
	_('mov dword[edx],-1')											; Move the value -1 into the 4-byte location at the address stored in EDX (mark as found)
	_('add edx,50')													; Add 50 to the value in the EDX register
	_('cmp edx,esi')												; Compare the value in EDX to the value in ESI
	_('jnz ScanInnerLoop')											; Jump to the ScanInnerLoop label if the comparison is not zero
	_('cmp ecx,' & SwapEndian(Hex($gwBaseAddress + 5238784, 8)))	; Compare the value in ECX to a specific address (+4FF000)
	_('jnz ScanLoop')												; Jump to the ScanLoop label if the comparison is not zero

	_('ScanExit:')													; Label for the scan exit section
	_('popad')														; Pop all general-purpose registers from the stack to restore their original values
	_('retn')														; Return from the current function (exit the scan routine)

	$baseAddress = $gwBaseAddress + 0x9DF000
	Local $scanMemory = MemoryRead($baseAddress, 'ptr')

	; Check if the scan memory address is empty (no previous injection)
	If $scanMemory = 0 Then
		; Allocate a new block of memory for the scan routine
		$memoryInterface = DllCall($kernelHandle, 'ptr', 'VirtualAllocEx', 'handle', $processHandle, 'ptr', 0, 'ulong_ptr', $asmInjectionSize, 'dword', 0x1000, 'dword', 0x40)
		; Get the allocated memory address
		$memoryInterface = $memoryInterface[0]
		; Write the allocated memory address to the scan memory location
		MemoryWrite($baseAddress, $memoryInterface)
	Else
		; If the scan memory address is not empty, use the existing memory address
		$memoryInterface = $scanMemory
	EndIf

	; Complete the assembly code for the scan routine
	CompleteASMCode()

	; Check if this is the first injection (no previous scan memory address)
	If $scanMemory = 0 Then
		; Write the assembly code to the allocated memory address
		WriteBinary($asmInjectionString, $memoryInterface + $asmCodeOffset)

		; Create a new thread in the target process to execute the scan routine
		Local $thread = DllCall($kernelHandle, 'int', 'CreateRemoteThread', 'int', $processHandle, 'ptr', 0, 'int', 0, 'int', GetLabelInfo('ScanProc'), 'ptr', 0, 'int', 0, 'int', 0)
		; Get the thread ID
		$thread = $thread[0] 

		; Wait for the thread to finish executing
		Local $result
		; Wait until the thread is no longer waiting (258 is the WAIT_TIMEOUT constant)
		Do
			; Wait for up to 50ms for the thread to finish
			$result = DllCall($kernelHandle, 'int', 'WaitForSingleObject', 'int', $thread, 'int', 50)
		Until $result[0] <> 258

		; Close the thread handle to free up system resources
		DllCall($kernelHandle, 'int', 'CloseHandle', 'int', $thread)
	EndIf
EndFunc


; Retrieve Guild Wars process base address
Func GetGWBase()
	; Scan for Guild Wars process and get base address
	Local $gwBaseAddress = ScanForProcess() - 4096 ; Subtract 4096 from the process address to get the base address

	; Convert base address to hexadecimal string
	$gwBaseAddress = '0x' & Hex($gwBaseAddress)

	; Return base address as hexadecimal string
	Return $gwBaseAddress
EndFunc


; Find process by scanning memory
Func ScanForProcess()
	Local $pattern = BinaryToString('0x558BEC83EC105356578B7D0833F63BFE')
	Return ScanMemoryForPattern($pattern)
EndFunc


; Find character names by scanning memory
Func ScanForCharname()
	Local $patternBinary = BinaryToString('0x6A14FF751868')
	Return ScanMemoryForPattern($patternBinary, HandleCharNameMatch)
EndFunc


; Helper for ScanForCharName
Func HandleCharNameMatch($baseAddress, $matchOffset)
	Local $tmpAddress = $baseAddress + $matchOffset - 1
	Local $tmpBuffer = DllStructCreate('ptr')
	DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $tmpAddress + 6, 'ptr', DllStructGetPtr($tmpBuffer), 'int', DllStructGetSize($tmpBuffer), 'int', '')
	$characterName = DllStructGetData($tmpBuffer, 1)
	Return GetCharname()
EndFunc


; Scan memory for a pattern - used to find process and to find character names
Func ScanMemoryForPattern($patternBinary, $onMatchFunc = Null)
	Local $currentSearchAddress = 0x00000000
	Local $mbiBuffer = DllStructCreate('dword;dword;dword;dword;dword;dword;dword')

	While $currentSearchAddress < 0x01F00000
		Local $mbi[7]
		DllCall($kernelHandle, 'int', 'VirtualQueryEx', 'int', $processHandle, 'int', $currentSearchAddress, 'ptr', DllStructGetPtr($mbiBuffer), 'int', DllStructGetSize($mbiBuffer))
		For $i = 0 To 6
			$mbi[$i] = StringStripWS(DllStructGetData($mbiBuffer, ($i + 1)), 3)
		Next

		If $mbi[4] = 4096 Then
			Local $buffer = DllStructCreate('byte[' & $mbi[3] & ']')
			DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $currentSearchAddress, 'ptr', DllStructGetPtr($buffer), 'int', DllStructGetSize($buffer), 'int', '')
			
			Local $tmpMemoryData = DllStructGetData($buffer, 1)
			$tmpMemoryData = BinaryToString($tmpMemoryData)

			Local $matchOffset = StringInStr($tmpMemoryData, $patternBinary, 2)
			If $matchOffset > 0 Then
				If IsFunc($onMatchFunc) Then
					Return Call($onMatchFunc, $currentSearchAddress, $matchOffset)
				Else
					; default behavior: return base address
					Return $mbi[0]
				EndIf
			EndIf
		EndIf
		$currentSearchAddress += $mbi[3]
	WEnd
	Return ''
EndFunc


;~ Adds a new pattern to the ASM injection string
Func AddPatternToInjection($pattern)
	Local $size = Int(0.5 * StringLen($pattern))
	$asmInjectionString &= '00000000' & SwapEndian(Hex($size, 8)) & '00000000' & $pattern
	$asmInjectionSize += $size + 12
	For $i = 1 To 68 - $size
		$asmInjectionSize += 1
		$asmInjectionString &= '00'
	Next
EndFunc


;~ Retrieves the scanned memory address for a specific label and offset (internal use)
Func GetScannedAddress($label, $offset)
	Return MemoryRead(GetLabelInfo($label) + 8) - MemoryRead(GetLabelInfo($label) + 4) + $offset
EndFunc
#EndRegion Initialisation


#Region Commands
#Region Item
;~ Starts a salvaging session of an item.
Func StartSalvage($item)
	Local $offset[4] = [0, 0x18, 0x2C, 0x690]
	Local $salvageSessionID = MemoryReadPtr($baseAddressPtr, $offset)
	Local $itemID = $item
	If IsDllStruct($item) Then $itemID = DllStructGetData($item, 'ID')

	Local $salvageKit = FindSalvageKit()
	If $salvageKit = 0 Then Return

	DllStructSetData($salvageStruct, 2, $itemID)
	DllStructSetData($salvageStruct, 3, $salvageKit)
	DllStructSetData($salvageStruct, 4, $salvageSessionID[1])

	Enqueue($salvageStructPtr, 16)
EndFunc


;~ Doesn't work - Should validate salvage
Func ValidateSalvage()
	ControlSend(GetWindowHandle(), '', '', '{Enter}')
	Sleep(GetPing() + 750)
EndFunc


;~ Get itemID from an item structure or pointer
Func GetItemID($item)
	If IsPtr($item) Then
		Return MemoryRead($item, 'long')
	ElseIf IsDllStruct($item) Then
		Return DllStructGetData($item, 'ID')
	Else
		Return $item
	EndIf
EndFunc


;~ Salvage the materials out of an item.
Func SalvageMaterials()
	Return SendPacket(0x4, $HEADER_SALVAGE_MATERIALS)
EndFunc


;~ Salvages a mod out of an item. Index: 0 for prefix/inscription, 1 for suffix/rune, 2 for inscription
Func SalvageMod($modIndex)
	Return SendPacket(0x8, $HEADER_SALVAGE_UPGRADE, $modIndex)
EndFunc


;~ Salvage the materials out of an item.
Func EndSalvage()
	Return SendPacket(0x4, $HEADER_SALVAGE_SESSION_DONE)
EndFunc


;~ Cancel the salvaging session
Func CancelSalvage()
	Return SendPacket(0x4, $HEADER_SALVAGE_SESSION_CANCEL)
EndFunc


;~ Identifies an item.
Func IdentifyItem($item)
	If GetIsIdentified($item) Then Return

	Local $itemID = $item
	If IsDllStruct($item) Then $itemID = DllStructGetData($item, 'ID')

	Local $identificationKit = FindIdentificationKit()
	If $identificationKit == 0 Then Return

	SendPacket(0xC, $HEADER_ITEM_IDENTIFY, $identificationKit, $itemID)

	Local $deadlock = TimerInit()
	Do
		Sleep(20)
	Until GetIsIdentified($itemID) Or TimerDiff($deadlock) > 5000
EndFunc


;~ Identifies all items in a bag.
Func IdentifyBag($bag, $identifyWhiteItems = False, $identifyGoldItems = True)
	Local $item
	If Not IsDllStruct($bag) Then $bag = GetBag($bag)
	For $i = 1 To DllStructGetData($bag, 'Slots')
		$item = GetItemBySlot($bag, $i)
		If DllStructGetData($item, 'ID') == 0 Then ContinueLoop
		If GetRarity($item) == $RARITY_White And $identifyWhiteItems == False Then ContinueLoop
		If GetRarity($item) == $RARITY_Gold And $identifyGoldItems == False Then ContinueLoop
		IdentifyItem($item)
		Sleep(GetPing())
	Next
EndFunc


;~ Equips an item.
Func EquipItem($item)
	Local $itemID = $item
	If IsDllStruct($item) Then $itemID = DllStructGetData($item, 'ID')
	Return SendPacket(0x8, $HEADER_ITEM_EQUIP, $itemID)
EndFunc


;~ Uses an item.
Func UseItem($item)
	Local $itemID = $item
	If IsDllStruct($item) Then $itemID = DllStructGetData($item, 'ID')
	Return SendPacket(0x8, $HEADER_ITEM_USE, $itemID)
EndFunc


;~ Picks up an item.
Func PickUpItem($item)
	Local $agentID
	If Not IsDllStruct($item) Then
		$agentID = $item
	ElseIf DllStructGetSize($item) < 400 Then
		$agentID = DllStructGetData($item, 'AgentID')
	Else
		$agentID = DllStructGetData($item, 'ID')
	EndIf
	Return SendPacket(0xC, $HEADER_ITEM_INTERACT, $agentID, 0)
EndFunc


;~ Drops an item.
Func DropItem($item, $amount = 0)
	Local $itemID
	If IsDllStruct($item) Then
		$itemID = DllStructGetData($item, 'ID')
	Else
		$itemID = $item
		$item = GetItemByItemID($item)
	EndIf
	If $amount < 0 Then $amount = DllStructGetData($item, 'Quantity')
	Return SendPacket(0xC, $HEADER_DROP_ITEM, $itemID, $amount)
EndFunc


;~ Moves an item.
Func MoveItem($item, $bag, $slotIndex)
	Local $itemID = $item
	If IsDllStruct($item) Then $itemID = DllStructGetData($item, 'ID')

	Local $bagID
	If IsDllStruct($bag) Then
		$bagID = DllStructGetData($bag, 'ID')
	Else
		$bagID = DllStructGetData(GetBag($bag), 'ID')
	EndIf
	Return SendPacket(0x10, $HEADER_ITEM_MOVE, $itemID, $bagID, $slotIndex - 1)
EndFunc


;~ Accepts unclaimed items after a mission.
Func AcceptAllItems()
	Return SendPacket(0x8, $HEADER_ITEMS_ACCEPT_UNCLAIMED, DllStructGetData(GetBag(7), 'ID'))
EndFunc


;~ Sells an item.
Func SellItem($item, $amount = 0)
	If Not IsDllStruct($item) Then $item = GetItemByItemID($item)
	If $amount = 0 Or $amount > DllStructGetData($item, 'Quantity') Then $amount = DllStructGetData($item, 'Quantity')

	DllStructSetData($sellItemStruct, 2, $amount * DllStructGetData($item, 'Value'))
	DllStructSetData($sellItemStruct, 3, DllStructGetData($item, 'ID'))
	DllStructSetData($sellItemStruct, 4, MemoryRead(GetScannedAddress('ScanBuyItemBase', 15)))
	Enqueue($sellItemStructPtr, 16)
EndFunc


;~ Buys an item.
Func BuyItem($item, $amount, $value)
	Local $merchantItemsBase = GetMerchantItemsBase()

	If Not $merchantItemsBase Then Return
	If $item < 1 Or $item > GetMerchantItemsSize() Then Return

	DllStructSetData($buyItemStruct, 2, $amount)
	DllStructSetData($buyItemStruct, 3, MemoryRead($merchantItemsBase + 4 * ($item - 1)))
	DllStructSetData($buyItemStruct, 4, $amount * $value)
	DllStructSetData($buyItemStruct, 5, MemoryRead(GetScannedAddress('ScanBuyItemBase', 15)))
	Enqueue($buyItemStructPtr, 20)
EndFunc


;~ Buys an identification kit.
Func BuyIdentificationKit($amount = 1)
	BuyItem(5, $amount, 100)
EndFunc


;~ Buys a superior identification kit.
Func BuySuperiorIdentificationKit($amount = 1)
	BuyItem(6, $amount, 500)
	RndSleep(1000)
EndFunc


;~ Buys a basic salvage kit.
Func BuySalvageKit($amount = 1)
	BuyItem(2, $amount, 100)
	RndSleep(1000)
EndFunc


;~ Buys an expert salvage kit.
Func BuyExpertSalvageKit($amount = 1)
	BuyItem(3, $amount, 400)
	RndSleep(1000)
EndFunc


;~ Buys an expert salvage kit.
Func BuySuperiorSalvageKit($amount = 1)
	BuyItem(4, $amount, 2000)
	RndSleep(1000)
EndFunc


;~ FIXME: this function is written like trash
Func CraftItem($modelID, $amount, $gold, ByRef $materialsArray)
	Local $sourceItemPtr = GetInventoryItemPtrByModelId($materialsArray[0][0])
	If ((Not $sourceItemPtr) Or (MemoryRead($sourceItemPtr + 0x4B) < $materialsArray[0][1])) Then Return 0
	Local $destinationItemPtr = MemoryRead(GetMerchantItemPtrByModelId($modelID))
	If (Not $destinationItemPtr) Then Return 0
	Local $materialString = ''
	Local $materialCount = 0
	If IsArray($materialsArray) = 0 Then Return 0
	Local $materialsArraySize = UBound($materialsArray) - 1
	For $i = $materialsArraySize To 0 Step -1
		Local $checkQuantity = CountItemInBagsByModelID($materialsArray[$i][0])
		If $materialsArray[$i][1] * $amount > $checkQuantity Then
			;amount of missing mats in @extended
			Return SetExtended($materialsArray[$i][1] * $amount - $checkQuantity, $materialsArray[$i][0])
		EndIf
	Next
	Local $gold = GetGoldCharacter()

	For $i = 0 To $materialsArraySize
		$materialString &= GetItemIDFromModelID($materialsArray[$i][0]) & ';'
		Out($materialString)
		$materialCount += 1
	Next

	$craftingMaterialType = 'dword'
	For $i = 1 To $materialCount - 1
		$craftingMaterialType &= ';dword'
	Next
	$craftingMaterialStruct = DllStructCreate($craftingMaterialType)
	$craftingMaterialStructPtr = DllStructGetPtr($craftingMaterialStruct)
	For $i = 1 To $materialCount
		Local $size = StringInStr($materialString, ';')
		DllStructSetData($craftingMaterialStruct, $i, StringLeft($materialString, $size - 1))
		$materialString = StringTrimLeft($materialString, $size)
	Next
	Local $memorySize = $materialCount * 4
	Local $memoryBuffer = DllCall($kernelHandle, 'ptr', 'VirtualAllocEx', 'handle', $processHandle, 'ptr', 0, 'ulong_ptr', $memorySize, 'dword', 0x1000, 'dword', 0x40)
	If $memoryBuffer = 0 Then Return 0 ; couldnt allocate enough memory
	Local $buffer = DllCall($kernelHandle, 'int', 'WriteProcessMemory', 'int', $processHandle, 'int', $memoryBuffer[0], 'ptr', $craftingMaterialStructPtr, 'int', $memorySize, 'int', '')
	If $buffer = 0 Then Return
	DllStructSetData($craftItemStruct, 1, GetValue('CommandCraftItemEx'))
	DllStructSetData($craftItemStruct, 2, $amount)
	DllStructSetData($craftItemStruct, 3, $destinationItemPtr)
	DllStructSetData($craftItemStruct, 4, $memoryBuffer[0])
	Out($memoryBuffer[0])
	DllStructSetData($craftItemStruct, 5, $materialCount)
	Out($materialCount)
	DllStructSetData($craftItemStruct, 6, $amount * $gold)
	Out($amount * $gold)
	Enqueue($craftItemStructPtr, 24)
	$deadlock = TimerInit()
	Local $currentAmount
	Do
		Sleep(250)
		$currentAmount = CountItemInBagsByModelID($materialsArray[0][0])
	Until $currentAmount <> $checkQuantity Or $gold <> GetGoldCharacter() Or TimerDiff($deadlock) > 5000
	DllCall($kernelHandle, 'ptr', 'VirtualFreeEx', 'handle', $processHandle, 'ptr', $memoryBuffer[0], 'int', 0, 'dword', 0x8000)
	; should be zero if items were successfully crafted
	Return SetExtended($checkQuantity - $currentAmount - $materialsArray[0][1] * $amount, True)
EndFunc


;~ Find an item with the provided modelId in your inventory and return its itemID
Func GetItemIDFromModelID($modelID)
	For $i = 1 To 5
		For $j = 1 To DllStructGetData(GetBag($i), 'slots')
			Local $item = GetItemBySlot($i, $j)
			If DllStructGetData($item, 'ModelId') == $modelID Then Return DllStructGetData($item, 'Id')
		Next
	Next
EndFunc


;~ Get item from merchant corresponding given modelID
Func GetMerchantItemPtrByModelId($modelID)
	Local $offsets[5] = [0, 0x18, 0x40, 0xB8]
	Local $merchantBaseAddress = GetMerchantItemsBase()
	Local $itemID = 0
	Local $itemPtr = 0
	For $i = 0 To GetMerchantItemsSize() -1
		$itemID = MemoryRead($merchantBaseAddress + 4 * $i)
		If ($itemID) Then
			$offsets[4] = 4 * $itemID
			$itemPtr = MemoryReadPtr($baseAddressPtr, $offsets)[1]
			If (MemoryRead($itemPtr + 0x2C) = $modelID) Then
				Return Ptr($itemPtr)
			EndIf
		EndIf
	Next
EndFunc


;~ Request a quote to buy an item from a trader. Returns True if successful.
Func TraderRequest($modelID, $extraID = -1)
	Local $offset[4] = [0, 0x18, 0x40, 0xC0]
	Local $itemArraySize = MemoryReadPtr($baseAddressPtr, $offset)
	Local $offset[5] = [0, 0x18, 0x40, 0xB8, 0]
	Local $itemPtr, $itemID
	Local $found = False
	Local $quoteID = MemoryRead($traderQuoteId)
	Local $itemStruct = DllStructCreate($itemStructTemplate)
	
	For $itemID = 1 To $itemArraySize[1]
		$offset[4] = 0x4 * $itemID
		$itemPtr = MemoryReadPtr($baseAddressPtr, $offset)
		If $itemPtr[1] = 0 Then ContinueLoop
		
		DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $itemPtr[1], 'ptr', DllStructGetPtr($itemStruct), 'int', DllStructGetSize($itemStruct), 'int', '')
		If DllStructGetData($itemStruct, 'ModelID') = $modelID And DllStructGetData($itemStruct, 'bag') = 0 And DllStructGetData($itemStruct, 'AgentID') == 0 Then
			If $extraID = -1 Or DllStructGetData($itemStruct, 'ExtraID') = $extraID Then
				$found = True
				ExitLoop
			EndIf
		EndIf
	Next
	If Not $found Then Return False

	DllStructSetData($requestQuoteStruct, 2, DllStructGetData($itemStruct, 'ID'))
	Enqueue($requestQuoteStructPtr, 8)

	Local $deadlock = TimerInit()
	$found = False
	Do
		Sleep(20)
		$found = MemoryRead($traderQuoteId) <> $quoteID
	Until $found Or TimerDiff($deadlock) > GetPing() + 5000
	Return $found
EndFunc


;~ Buy the requested item.
Func TraderBuy()
	If Not GetTraderCostID() Or Not GetTraderCostValue() Then Return False
	Enqueue($traderBuyStructPtr, 4)
	Return True
EndFunc


Func TraderRequestBuy($item)
	Local $found = False
	Local $quoteID = MemoryRead($traderQuoteId)
	Local $itemID = $item

	If IsDllStruct($item) Then $itemID = DllStructGetData($item, 'ID')

	DllStructSetData($requestQuoteStruct, 1, $HEADER_REQUEST_QUOTE)
	DllStructSetData($requestQuoteStruct, 2, $itemID)
	Enqueue($requestQuoteStructPtr, 8)

	Local $deadlock = TimerInit()
	$found = False
	Do
		Sleep(20)
		$found = MemoryRead($traderQuoteId) <> $quoteID
	Until $found Or TimerDiff($deadlock) > GetPing() + 5000

	Return $found
 EndFunc


;~ Request a quote to sell an item to the trader.
Func TraderRequestSell($item)
	Local $found = False
	Local $quoteID = MemoryRead($traderQuoteId)

	Local $itemID = $item
	If IsDllStruct($item) Then $itemID = DllStructGetData($item, 'ID')
	DllStructSetData($requestQuoteStructSell, 1, $HEADER_REQUEST_QUOTE)
	DllStructSetData($requestQuoteStructSell, 2, $itemID)
	Enqueue($requestQuoteStructSellPtr, 8)

	Local $deadlock = TimerInit()
	Do
		Sleep(20)
		$found = MemoryRead($traderQuoteId) <> $quoteID
	Until $found Or TimerDiff($deadlock) > GetPing() + 5000
	Return $found
EndFunc


;~ ID of the item item being sold.
Func TraderSell()
	If Not GetTraderCostID() Or Not GetTraderCostValue() Then Return False
	Enqueue($traderSellStructPtr, 4)
	Return True
EndFunc


;~ Drop gold on the ground.
Func DropGold($amount = 0)
	Local $amount

	If $amount > 0 Then
		$amount = $amount
	Else
		$amount = GetGoldCharacter()
	EndIf

	Return SendPacket(0x8, $HEADER_DROP_GOLD, $amount)
EndFunc


;~ Deposit gold into storage.
Func DepositGold($amount = 0)
	Local $amount
	Local $storageGold = GetGoldStorage()
	Local $characterGold = GetGoldCharacter()

	If $amount > 0 And $characterGold >= $amount Then
		$amount = $amount
	Else
		$amount = $characterGold
	EndIf

	If $storageGold + $amount > 1000000 Then $amount = 1000000 - $storageGold

	ChangeGold($characterGold - $amount, $storageGold + $amount)
EndFunc


;~ Withdraw gold from storage.
Func WithdrawGold($amount = 0)
	Local $amount
	Local $storageGold = GetGoldStorage()
	Local $characterGold = GetGoldCharacter()

	If $amount > 0 And $storageGold >= $amount Then
		$amount = $amount
	Else
		$amount = $storageGold
	EndIf

	If $characterGold + $amount > 100000 Then $amount = 100000 - $characterGold

	ChangeGold($characterGold + $amount, $storageGold - $amount)
EndFunc


;~ Internal use for moving gold.
Func ChangeGold($character, $storage)
	Return SendPacket(0xC, $HEADER_CHANGE_GOLD, $character, $storage)
EndFunc
#EndRegion Item


#Region H&H
;~ Adds a hero to the party.
Func AddHero($heroID)
	Return SendPacket(0x8, $HEADER_HERO_ADD, $heroID)
EndFunc


;~ Kicks a hero from the party.
Func KickHero($heroID)
	Return SendPacket(0x8, $HEADER_HERO_KICK, $heroID)
EndFunc


;~ Kicks all heroes from the party.
Func KickAllHeroes()
	Return SendPacket(0x8, $HEADER_HERO_KICK, 0x26)
EndFunc


;~ Add a henchman to the party.
Func AddNpc($npcID)
	Return SendPacket(0x8, $HEADER_PARTY_INVITE_NPC, $npcID)
EndFunc


;~ Kick a henchman from the party.
Func KickNpc($npcID)
	Return SendPacket(0x8, $HEADER_PARTY_KICK_NPC, $npcID)
EndFunc


;~ Clear the position flag from a hero.
Func CancelHero($heroIndex)
	Local $agentID = GetHeroID($heroIndex)
	Return SendPacket(0x14, $HEADER_HERO_FLAG_SINGLE, $agentID, 0x7F800000, 0x7F800000, 0)
EndFunc


;~ Clear the position flag from all heroes.
Func CancelAll()
	Return SendPacket(0x10, $HEADER_HERO_FLAG_ALL, 0x7F800000, 0x7F800000, 0)
EndFunc


;~ Place a hero's position flag.
Func CommandHero($heroIndex, $X, $Y)
	Return SendPacket(0x14, $HEADER_HERO_FLAG_SINGLE, GetHeroID($heroIndex), FloatToInt($X), FloatToInt($Y), 0)
EndFunc


;~ Place the full-party position flag.
Func CommandAll($X, $Y)
	Return SendPacket(0x10, $HEADER_HERO_FLAG_ALL, FloatToInt($X), FloatToInt($Y), 0)
EndFunc


;~ Lock a hero onto a target.
Func LockHeroTarget($heroIndex, $agentID = 0)
	Local $heroID = GetHeroID($heroIndex)
	Return SendPacket(0xC, $HEADER_HERO_LOCK_TARGET, $heroID, $agentID)
EndFunc


;~ Change a hero's aggression level.
Func SetHeroAggression($heroIndex, $aggressionLevel) ;0=Fight, 1=Guard, 2=Avoid
	Local $heroID = GetHeroID($heroIndex)
	Return SendPacket(0xC, $HEADER_HERO_BEHAVIOR, $heroID, $aggressionLevel)
EndFunc


;~ Disable a skill on a hero's skill bar.
Func DisableHeroSkillSlot($heroIndex, $skillSlot)
	If Not GetIsHeroSkillSlotDisabled($heroIndex, $skillSlot) Then ChangeHeroSkillSlotState($heroIndex, $skillSlot)
EndFunc


;~ Enable a skill on a hero's skill bar.
Func EnableHeroSkillSlot($heroIndex, $skillSlot)
	If GetIsHeroSkillSlotDisabled($heroIndex, $skillSlot) Then ChangeHeroSkillSlotState($heroIndex, $skillSlot)
EndFunc


;~ Internal use for enabling or disabling hero skills
Func ChangeHeroSkillSlotState($heroIndex, $skillSlot)
	Return SendPacket(0xC, $HEADER_HERO_FLAG_ALL, GetHeroID($heroIndex), $skillSlot - 1)
EndFunc


;~ Order a hero to use a skill.
Func UseHeroSkill($hero, $skillSlot, $target = 0)
	DllStructSetData($useHeroSkillStruct, 2, GetHeroID($hero))
	DllStructSetData($useHeroSkillStruct, 3, ConvertID($target))
	DllStructSetData($useHeroSkillStruct, 4, $skillSlot - 1)
	Enqueue($useHeroSkillStructPtr, 16)
EndFunc
#EndRegion H&H


#Region Movement
;~ Move to a location. Returns True if successful
Func Move($X, $Y, $random = 50)
	If GetAgentExists(-2) Then
		DllStructSetData($moveStruct, 2, $X + Random(-$random, $random))
		DllStructSetData($moveStruct, 3, $Y + Random(-$random, $random))
		Enqueue($moveStructPtr, 16)
		Return True
	Else
		Return False
	EndIf
EndFunc


;~ Move to a location and wait until you reach it.
Func MoveTo($X, $Y, $random = 50, $doWhileRunning = null)
	Local $blockedCount = 0
	Local $me
	Local $mapLoading = GetInstanceType(), $mapLoadingOld
	Local $destinationX = $X + Random(-$random, $random)
	Local $destinationY = $Y + Random(-$random, $random)

	Move($destinationX, $destinationY, 0)

	Do
		Sleep(100)
		$me = GetAgentByID(-2)
		If GetAgentInfo($me, 'HP') <= 0 Then ExitLoop
		$mapLoadingOld = $mapLoading
		$mapLoading = GetInstanceType()
		If $mapLoading <> $mapLoadingOld Then ExitLoop
		If $doWhileRunning <> null Then $doWhileRunning()
		If GetAgentInfo($me, 'MoveX') == 0 And GetAgentInfo($me, 'MoveY') == 0 Then
			$blockedCount += 1
			$destinationX = $X + Random(-$random, $random)
			$destinationY = $Y + Random(-$random, $random)
			Move($destinationX, $destinationY, 0)
		EndIf
	Until ComputeDistance(GetAgentInfo($me, 'X'), GetAgentInfo($me, 'Y'), $destinationX, $destinationY) < 25 Or $blockedCount > 14
EndFunc


;~ Run to or follow a player.
Func GoPlayer($agent)
	Return SendPacket(0x8, $HEADER_INTERACT_PLAYER , ConvertID($agent))
EndFunc


;~ Talk to an NPC
Func GoNPC($agent)
	Return SendPacket(0xC, $HEADER_INTERACT_NPC, ConvertID($agent))
EndFunc


;~ Run to a signpost.
Func GoSignpost($agent)
	Return SendPacket(0xC, $HEADER_SIGNPOST_RUN, ConvertID($agent), 0)
EndFunc


;~ Talks to NPC and waits until you reach them.
Func GoToNPC($agent)
	GoToAgent($agent, GoNPC)
EndFunc


;~ Go to signpost and waits until you reach it.
Func GoToSignpost($agent)
	GoToAgent($agent, GoSignpost)
EndFunc


;~ Talks to an agent and waits until you reach it.
Func GoToAgent($agent, $GoFunction)
	Local $me
	Local $blockedCount = 0
	Local $mapLoading = GetInstanceType(), $mapLoadingOld
	Move(GetAgentInfo($agent, 'X'), GetAgentInfo($agent, 'Y'), 100)
	Sleep(100)
	$GoFunction($agent)
	Do
		Sleep(100)
		$me = GetAgentByID(-2)
		If GetAgentInfo($me, 'HP') <= 0 Then ExitLoop
		$mapLoadingOld = $mapLoading
		$mapLoading = GetInstanceType()
		If $mapLoading <> $mapLoadingOld Then ExitLoop
		If GetAgentInfo($me, 'MoveX') == 0 And GetAgentInfo($me, 'MoveY') == 0 Then
			$blockedCount += 1
			Move(GetAgentInfo($agent, 'X'), GetAgentInfo($agent, 'Y'), 100)
			Sleep(100)
			$GoFunction($agent)
		EndIf
	Until ComputeDistance(GetAgentInfo($me, 'X'), GetAgentInfo($me, 'Y'), GetAgentInfo($agent, 'X'), GetAgentInfo($agent, 'Y')) < 250 Or $blockedCount > 14
	Sleep(GetPing() + Random(1500, 2000, 1))
EndFunc


;~ Attack an agent.
Func Attack($agent, $callTarget = False)
	Return SendPacket(0xC, $HEADER_ACTION_ATTACK, ConvertID($agent), $callTarget)
EndFunc


;~ Turn character to the left.
Func TurnLeft($turn)
	Return PerformAction(0xA2, $turn ? 0x1E : 0x20)
EndFunc


;~ Turn character to the right.
Func TurnRight($turn)
	Return PerformAction(0xA3, $turn ? 0x1E : 0x20)
EndFunc


;~ Move backwards.
Func MoveBackward($move)
	Return PerformAction(0xAC, $move ? 0x1E : 0x20)
EndFunc


;~ Run forwards.
Func MoveForward($move)
	Return PerformAction(0xAD, $move ? 0x1E : 0x20)
EndFunc


;~ Strafe to the left.
Func StrafeLeft($strafe)
	Return PerformAction(0x91, $strafe ? 0x1E : 0x20)
EndFunc


;~ Strafe to the right.
Func StrafeRight($strafe)
	Return PerformAction(0x92, $strafe ? 0x1E : 0x20)
EndFunc


;~ Auto-run.
Func ToggleAutoRun()
	Return PerformAction(0xB7, 0x1E)
EndFunc


;~ Turn around.
Func ReverseDirection()
	Return PerformAction(0xB1, 0x1E)
EndFunc
#EndRegion Movement


#Region Travel
;~ Map travel to an outpost, returns True if successful
Func TravelTo($mapID, $district = 0)
	If GetMapID() = $mapID And $district = 0 And GetInstanceType() = 0 Then Return True
	ZoneMap($mapID, $district)
	Return WaitMapLoading($mapID)
EndFunc


;~ Internal use for map travel.
Func ZoneMap($mapID, $district = 0)
	MoveMap($mapID, GetRegion(), $district, GetLanguage());
EndFunc


;~ Internal use for map travel.
Func MoveMap($mapID, $region, $district, $language)
	Return SendPacket(0x18, $HEADER_MAP_TRAVEL, $mapID, $region, $district, $language, False)
EndFunc


;~ Returns to outpost after resigning/failure.
Func ReturnToOutpost()
	Return SendPacket(0x4, $HEADER_PARTY_RETURN_TO_OUTPOST)
EndFunc


;~ Enter a challenge mission/pvp.
Func EnterChallenge()
	Return SendPacket(0x8, $HEADER_PARTY_ENTER_CHALLENGE, 1)
EndFunc


;~ Enter a foreign challenge mission/pvp.
Func EnterChallengeForeign()
	Return SendPacket(0x8, $HEADER_PARTY_ENTER_FOREIGN_MISSION, 0)
EndFunc


;~ Travel to your guild hall.
Func TravelGuildHall()
	Local $offset[3] = [0, 0x18, 0x3C]
	Local $guildHall = MemoryReadPtr($baseAddressPtr, $offset)
	SendPacket(0x18, $HEADER_GUILDHALL_TRAVEL, MemoryRead($guildHall[1] + 0x64), MemoryRead($guildHall[1] + 0x68), MemoryRead($guildHall[1] + 0x6C), MemoryRead($guildHall[1] + 0x70), 1)
	Return WaitMapLoading()
EndFunc


;~ Leave your guild hall.
Func LeaveGuildHall()
	SendPacket(0x8, $HEADER_GUILDHALL_LEAVE, 1)
	Return WaitMapLoading()
EndFunc
#EndRegion Travel


#Region Quest
;~ Accept a quest from an NPC.
Func AcceptQuest($questID)
	Return SendPacket(0x8, $HEADER_DIALOG_SEND, '0x008' & Hex($questID, 3) & '01')
EndFunc


;~ Accept the reward for a quest.
Func QuestReward($questID)
	Return SendPacket(0x8, $HEADER_DIALOG_SEND, '0x008' & Hex($questID, 3) & '07')
EndFunc


;~ Abandon a quest.
Func AbandonQuest($questID)
	Return SendPacket(0x8, $HEADER_QUEST_ABANDON, $questID)
EndFunc
#EndRegion Quest


#Region Windows
;~ Close all in-game windows.
Func CloseAllPanels()
	Return PerformAction(0x85, 0x1E)
EndFunc


;~ Toggle hero window.
Func ToggleHeroWindow()
	Return PerformAction(0x8A, 0x1E)
EndFunc


;~ Toggle inventory window.
Func ToggleInventory()
	Return PerformAction(0x8B, 0x1E)
EndFunc


;~ Toggle all bags window.
Func ToggleAllBags()
	Return PerformAction(0xB8, 0x1E)
EndFunc


;~ Toggle world map.
Func ToggleWorldMap()
	Return PerformAction(0x8C, 0x1E)
EndFunc


;~ Toggle options window.
Func ToggleOptions()
	Return PerformAction(0x8D, 0x1E)
EndFunc


;~ Toggle quest window.
Func ToggleQuestWindow()
	Return PerformAction(0x8E, 0x1E)
EndFunc


;~ Toggle skills window.
Func ToggleSkillWindow()
	Return PerformAction(0x8F, 0x1E)
EndFunc


;~ Toggle mission map.
Func ToggleMissionMap()
	Return PerformAction(0xB6, 0x1E)
EndFunc


;~ Toggle friends list window.
Func ToggleFriendList()
	Return PerformAction(0xB9, 0x1E)
EndFunc


;~ Toggle guild window.
Func ToggleGuildWindow()
	Return PerformAction(0xBA, 0x1E)
EndFunc


;~ Toggle party window.
Func TogglePartyWindow()
	Return PerformAction(0xBF, 0x1E)
EndFunc


;~ Toggle score chart.
Func ToggleScoreChart()
	Return PerformAction(0xBD, 0x1E)
EndFunc


;~ Toggle layout window.
Func ToggleLayoutWindow()
	Return PerformAction(0xC1, 0x1E)
EndFunc


;~ Toggle minions window.
Func ToggleMinionList()
	Return PerformAction(0xC2, 0x1E)
EndFunc


;~ Toggle a hero panel.
Func ToggleHeroPanel($hero)
	Return PerformAction(($hero < 4 ? 0xDB : 0xFE) + $hero, 0x1E)
EndFunc


;~ Toggle hero's pet panel.
Func ToggleHeroPetPanel($hero)
	Return PerformAction(($hero < 4 ? 0xDF : 0xFA) + $hero, 0x1E)
EndFunc


;~ Toggle pet panel.
Func TogglePetPanel()
	Return PerformAction(0xDF, 0x1E)
EndFunc


;~ Toggle help window.
Func ToggleHelpWindow()
	Return PerformAction(0xE4, 0x1E)
EndFunc
#EndRegion Windows


#Region Targeting
;~ Target an agent.
Func ChangeTarget($agent)
	DllStructSetData($changeTargetStruct, 2, ConvertID($agent))
	Enqueue($changeTargetStructPtr, 8)
EndFunc


;~ Call target.
Func CallTarget($target)
	Return SendPacket(0xC, $HEADER_CALL_TARGET, 0xA, ConvertID($target))
EndFunc


;~ Clear current target.
Func ClearTarget()
	Return PerformAction(0xE3, 0x1E)
EndFunc


;~ Target the nearest enemy.
Func TargetNearestEnemy()
	Return PerformAction(0x93, 0x1E)
EndFunc


;~ Target the next enemy.
Func TargetNextEnemy()
	Return PerformAction(0x95, 0x1E)
EndFunc


;~ Target the next party member.
Func TargetPartyMember($partyMemberIndex)
	If $partyMemberIndex > 0 And $partyMemberIndex < 13 Then Return PerformAction(0x95 + $partyMemberIndex, 0x1E)
EndFunc


;~ Target the previous enemy.
Func TargetPreviousEnemy()
	Return PerformAction(0x9E, 0x1E)
EndFunc


;~ Target the called target.
Func TargetCalledTarget()
	Return PerformAction(0x9F, 0x1E)
EndFunc


;~ Target yourself.
Func TargetSelf()
	Return PerformAction(0xA0, 0x1E)
EndFunc


;~ Target the nearest ally.
Func TargetNearestAlly()
	Return PerformAction(0xBC, 0x1E)
EndFunc


;~ Target the nearest item.
Func TargetNearestItem()
	Return PerformAction(0xC3, 0x1E)
EndFunc


;~ Target the next item.
Func TargetNextItem()
	Return PerformAction(0xC4, 0x1E)
EndFunc


;~ Target the previous item.
Func TargetPreviousItem()
	Return PerformAction(0xC5, 0x1E)
EndFunc


;~ Target the next party member.
Func TargetNextPartyMember()
	Return PerformAction(0xCA, 0x1E)
EndFunc


;~ Target the previous party member.
Func TargetPreviousPartyMember()
	Return PerformAction(0xCB, 0x1E)
EndFunc
#EndRegion Targeting


#Region Display
;~ Enable graphics rendering.
Func EnableRendering($showWindow = True)
	Local $windowHandle = GetWindowHandle(), $prevGwState = WinGetState($windowHandle), $previousWindow = WinGetHandle('[ACTIVE]', ''), $previousWindowState = WinGetState($previousWindow)
	If $showWindow And $prevGwState Then
		If BitAND($prevGwState, 16) Then
			WinSetState($windowHandle, '', @SW_RESTORE)
		ElseIf Not BitAND($prevGwState, 2) Then
			WinSetState($windowHandle, '', @SW_SHOW)
		EndIf
		If $windowHandle <> $previousWindow And $previousWindow Then RestoreWindowState($previousWindow, $previousWindowState)
	EndIf
	If Not GetIsRendering() Then
		$disableRendering = True
		If Not MemoryWrite($disableRendering, 0) Then Return SetError(@error, False)
		Sleep(250)
	EndIf
	Return 1
EndFunc


;~ Disable graphics rendering.
Func DisableRendering($hideWindow = True)
	Local $windowHandle = GetWindowHandle()
	If $hideWindow And WinGetState($windowHandle) Then WinSetState($windowHandle, '', @SW_HIDE)
	If GetIsRendering() Then
		$disableRendering = False
		If Not MemoryWrite($disableRendering, 1) Then Return SetError(@error, False)
		Sleep(250)
	EndIf
	Return 1
EndFunc


;~ Toggles graphics rendering
Func ToggleRendering()
	Return GetIsRendering() ? DisableRendering() : EnableRendering()
EndFunc


Func GetIsRendering()
	Return MemoryRead($disableRendering) <> 1
EndFunc


;~ Internally used - restores a window to previous state.
Func RestoreWindowState($windowHandle, $previousWindowState)
	If Not $windowHandle Or Not $previousWindowState Then Return 0

	Local $currentWindowState = WinGetState($windowHandle)
	For $state In [1, 2, 4, 8, 16, 32]
		If BitAND($previousWindowState, $state) And Not BitAND($currentWindowState, $state) Then WinSetState($windowHandle, '', $state)
	Next
EndFunc

;~ Display all names.
Func DisplayAll($display)
	DisplayAllies($display)
	DisplayEnemies($display)
EndFunc


;~ Display the names of allies.
Func DisplayAllies($display)
	Return PerformAction(0x89, $display ? 0x1E : 0x20)
EndFunc


;~ Display the names of enemies.
Func DisplayEnemies($display)
	Return PerformAction(0x94, $display ? 0x1E : 0x20)
EndFunc
#EndRegion Display


#Region Chat
;~ Write a message in chat (can only be seen by user).
Func WriteChat($message, $sender = 'GWA2')
	Local $address = 256 * $queueCounter + $queueBaseAddress
	;FIXME: rewrite with modulo
	$queueCounter = $queueCounter = $queueSize ? 0 : $queueCounter + 1;
	If StringLen($sender) > 19 Then $sender = StringLeft($sender, 19)

	MemoryWrite($address + 4, $sender, 'wchar[20]')

	If StringLen($message) > 100 Then $message = StringLeft($message, 100)

	MemoryWrite($address + 44, $message, 'wchar[101]')
	DllCall($kernelHandle, 'int', 'WriteProcessMemory', 'int', $processHandle, 'int', $address, 'ptr', $writeChatStructPtr, 'int', 4, 'int', '')

	If StringLen($message) > 100 Then WriteChat(StringTrimLeft($message, 100), $sender)
EndFunc


;~ Send a whisper to another player.
Func SendWhisper($receiver, $message)
	Local $total = 'whisper ' & $receiver & ',' & $message
	If StringLen($total) > 120 Then
		$message = StringLeft($total, 120)
	Else
		$message = $total
	EndIf
	SendChat($message, '/')
	If StringLen($total) > 120 Then SendWhisper($receiver, StringTrimLeft($total, 120))
EndFunc


;~ Send a message to chat.
Func SendChat($message, $channel = '!')
	Local $address = 256 * $queueCounter + $queueBaseAddress
	;FIXME: rewrite with modulo
	$queueCounter = $queueCounter = $queueSize ? 0 : $queueCounter + 1;
	If StringLen($message) > 120 Then $message = StringLeft($message, 120)

	MemoryWrite($address + 12, $channel & $message, 'wchar[122]')
	DllCall($kernelHandle, 'int', 'WriteProcessMemory', 'int', $processHandle, 'int', $address, 'ptr', $sendChatStructPtr, 'int', 8, 'int', '')

	If StringLen($message) > 120 Then SendChat(StringTrimLeft($message, 120), $channel)
EndFunc
#EndRegion Chat


#Region Misc
;~ Change weapon sets.
Func ChangeWeaponSet($weaponSet)
	Return PerformAction(0x80 + $weaponSet, 0x1E)
EndFunc


;~ Use a skill.
Func UseSkill($skillSlot, $target = -2, $callTarget = False)
	DllStructSetData($useSkillStruct, 2, $skillSlot)
	DllStructSetData($useSkillStruct, 3, ConvertID($target))
	DllStructSetData($useSkillStruct, 4, $callTarget)
	Enqueue($useSkillStructPtr, 16)
EndFunc
	
	
Func UseSkillEx($skillSlot, $target = -2, $timeout = 3000)
	If GetIsDead(-2) Or Not IsRecharged($skillSlot) Then Return
	Local $Skill = GetSkillByID(GetSkillbarSkillID($skillSlot, 0))
	Local $Energy = StringReplace(StringReplace(StringReplace(StringMid(DllStructGetData($Skill, 'Unknown4'), 6, 1), 'C', '25'), 'B', '15'), 'A', '10')
	If GetEnergy(-2) < $Energy Then Return
	Local $aftercast = DllStructGetData($Skill, 'Aftercast')
	Local $deadlock = TimerInit()
	UseSkill($skillSlot, $target)
	Do
		Sleep(50)
		If GetIsDead(-2) Then Return
	Until (Not IsRecharged($skillSlot)) Or (TimerDiff($deadlock) > $timeout)
	Sleep($aftercast * 1000)
EndFunc


Func IsRecharged($skillSlot)
	Return GetSkillbarSkillRecharge($skillSlot) == 0
EndFunc


;~ Cancel current action.
Func CancelAction()
	Return SendPacket(0x4, $HEADER_ACTION_CANCEL)
EndFunc


;~ Same as hitting spacebar.
Func ActionInteract()
	Return PerformAction(0x80, 0x1E)
EndFunc


;~ Follow a player.
Func ActionFollow()
	Return PerformAction(0xCC, 0x1E)
EndFunc


;~ Drop environment object.
Func DropBundle()
	Return PerformAction(0xCD, 0x1E)
EndFunc


;~ Clear all hero flags.
Func ClearPartyCommands()
	Return PerformAction(0xDB, 0x1E)
EndFunc


;~ Suppress action.
Func SuppressAction($suppressAction)
	Return PerformAction(0xD0, $suppressAction ? 0x1E : 0x20)
EndFunc


;~ Open a chest.
Func OpenChest()
	Return SendPacket(0x8, $HEADER_OPEN_CHEST, 2)
EndFunc


;~ Stop maintaining enchantment on target.
Func DropBuff($skillID, $agentID, $heroIndex = 0)
	Local $buffCount = GetBuffCount($heroIndex)
	Local $buffStructAddress
	Local $offset[4]
	$offset[0] = 0
	$offset[1] = 0x18
	$offset[2] = 0x2C
	$offset[3] = 0x510
	Local $count = MemoryReadPtr($baseAddressPtr, $offset)
	ReDim $offset[5]
	$offset[3] = 0x508
	Local $buffer
	Local $buffStruct = DllStructCreate($buffStructTemplate)
	For $i = 0 To $count[1] - 1
		$offset[4] = 0x24 * $i
		$buffer = MemoryReadPtr($baseAddressPtr, $offset)
		If $buffer[1] == GetHeroID($heroIndex) Then
			$offset[4] = 0x4 + 0x24 * $i
			ReDim $offset[6]
			For $j = 0 To $buffCount - 1
				$offset[5] = 0 + 0x10 * $j
				$buffStructAddress = MemoryReadPtr($baseAddressPtr, $offset)
				DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $buffStructAddress[0], 'ptr', DllStructGetPtr($buffStruct), 'int', DllStructGetSize($buffStruct), 'int', '')
				If (DllStructGetData($buffStruct, 'SkillID') == $skillID) And (DllStructGetData($buffStruct, 'TargetId') == ConvertID($agentID)) Then
					Return SendPacket(0x8, $HEADER_BUFF_DROP, DllStructGetData($buffStruct, 'BuffId'))
					ExitLoop 2
				EndIf
			Next
		EndIf
	Next
EndFunc


;~ Take a screenshot.
Func MakeScreenshot()
	Return PerformAction(0xAE, 0x1E)
EndFunc


;~ Invite a player to the party.
Func InvitePlayer($playerName)
	SendChat('invite ' & $playerName, '/')
EndFunc


;~ Leave your party.
Func LeaveGroup($kickHeroes = True)
	If $kickHeroes Then KickAllHeroes()
	Return SendPacket(0x4, $HEADER_PARTY_LEAVE)
EndFunc


;~ Switches to/from Hard Mode.
Func SwitchMode($mode)
	Return SendPacket(0x8, $HEADER_SET_DIFFICULTY, $mode)
EndFunc


;~ Resign.
Func Resign()
	SendChat('resign', '/')
EndFunc


;~ Donate Kurzick or Luxon faction.
Func DonateFaction($faction)
	Return SendPacket(0x10, $HEADER_FACTION_DEPOSIT, 0, StringLeft($faction, 1) = 'k' ? 0 : 1, 5000)
EndFunc


;~ Open a dialog.
Func Dialog($dialogID)
	Return SendPacket(0x8, $HEADER_DIALOG_SEND, $dialogID)
EndFunc


;~ Skip a cinematic.
Func SkipCinematic()
	Return SendPacket(0x4, $HEADER_CINEMATIC_SKIP)
EndFunc


;~ Change a skill on the skillbar.
Func SetSkillbarSkill($slot, $skillID, $heroIndex = 0)
	Return SendPacket(0x14, $HEADER_SET_SKILLBAR_SKILL, GetHeroID($heroIndex), $slot - 1, $skillID, 0)
EndFunc


;~ Load all skills onto a skillbar simultaneously.
Func LoadSkillBar($skill1 = 0, $skill2 = 0, $skill3 = 0, $skill4 = 0, $skill5 = 0, $skill6 = 0, $skill7 = 0, $skill8 = 0, $heroIndex = 0)
	SendPacket(0x2C, $HEADER_LOAD_SKILLBAR, GetHeroID($heroIndex), 8, $skill1, $skill2, $skill3, $skill4, $skill5, $skill6, $skill7, $skill8)
EndFunc


;~ Loads skill template code.
Func LoadSkillTemplate($buildTemplate, $heroIndex = 0)
	Local $heroID = GetHeroID($heroIndex)
	Local $splitBuildTemplate = StringSplit($buildTemplate, '')

	Local $tempValuelateType ; 4 Bits
	Local $versionNumber ; 4 Bits
	Local $professionBits ; 2 Bits -> P
	Local $primaryProfession ; P Bits
	Local $secondaryProfession ; P Bits
	Local $attributesCount ; 4 Bits
	Local $attributesBits ; 4 Bits -> A
	Local $attributes[1][2] ; A Bits + 4 Bits (for each Attribute)
	Local $skillsBits ; 4 Bits -> S
	Local $skills[8] ; S Bits * 8
	Local $opTail ; 1 Bit

	$buildTemplate = ''
	For $i = 1 To $splitBuildTemplate[0]
		$buildTemplate &= Base64ToBin64($splitBuildTemplate[$i])
	Next

	$tempValuelateType = Bin64ToDec(StringLeft($buildTemplate, 4))
	$buildTemplate = StringTrimLeft($buildTemplate, 4)
	If $tempValuelateType <> 14 Then Return False

	$versionNumber = Bin64ToDec(StringLeft($buildTemplate, 4))
	$buildTemplate = StringTrimLeft($buildTemplate, 4)

	$professionBits = Bin64ToDec(StringLeft($buildTemplate, 2)) * 2 + 4
	$buildTemplate = StringTrimLeft($buildTemplate, 2)

	$primaryProfession = Bin64ToDec(StringLeft($buildTemplate, $professionBits))
	$buildTemplate = StringTrimLeft($buildTemplate, $professionBits)
	If $primaryProfession <> GetHeroProfession($heroIndex) Then Return False

	$secondaryProfession = Bin64ToDec(StringLeft($buildTemplate, $professionBits))
	$buildTemplate = StringTrimLeft($buildTemplate, $professionBits)

	$attributesCount = Bin64ToDec(StringLeft($buildTemplate, 4))
	$buildTemplate = StringTrimLeft($buildTemplate, 4)

	$attributesBits = Bin64ToDec(StringLeft($buildTemplate, 4)) + 4
	$buildTemplate = StringTrimLeft($buildTemplate, 4)

	$attributes[0][0] = $attributesCount
	For $i = 1 To $attributesCount
		If Bin64ToDec(StringLeft($buildTemplate, $attributesBits)) == GetProfPrimaryAttribute($primaryProfession) Then
			$buildTemplate = StringTrimLeft($buildTemplate, $attributesBits)
			$attributes[0][1] = Bin64ToDec(StringLeft($buildTemplate, 4))
			$buildTemplate = StringTrimLeft($buildTemplate, 4)
			ContinueLoop
		EndIf
		$attributes[0][0] += 1
		ReDim $attributes[$attributes[0][0] + 1][2]
		$attributes[$i][0] = Bin64ToDec(StringLeft($buildTemplate, $attributesBits))
		$buildTemplate = StringTrimLeft($buildTemplate, $attributesBits)
		$attributes[$i][1] = Bin64ToDec(StringLeft($buildTemplate, 4))
		$buildTemplate = StringTrimLeft($buildTemplate, 4)
	Next

	$skillsBits = Bin64ToDec(StringLeft($buildTemplate, 4)) + 8
	$buildTemplate = StringTrimLeft($buildTemplate, 4)

	For $i = 0 To 7
		$skills[$i] = Bin64ToDec(StringLeft($buildTemplate, $skillsBits))
		$buildTemplate = StringTrimLeft($buildTemplate, $skillsBits)
	Next

	$opTail = Bin64ToDec($buildTemplate)

	$attributes[0][0] = $secondaryProfession
	LoadAttributes($attributes, $heroIndex)
	LoadSkillBar($skills[0], $skills[1], $skills[2], $skills[3], $skills[4], $skills[5], $skills[6], $skills[7], $heroIndex)
EndFunc


;~ Load attributes from a two dimensional array.
Func LoadAttributes($attributesArray, $heroIndex = 0)
	Local $primaryAttribute
	Local $deadlock
	Local $heroID = GetHeroID($heroIndex)
	Local $level

	$primaryAttribute = GetProfPrimaryAttribute(GetHeroProfession($heroIndex))

	If $attributesArray[0][0] <> 0 And GetHeroProfession($heroIndex, True) <> $attributesArray[0][0] And GetHeroProfession($heroIndex) <> $attributesArray[0][0] Then
		Do
			$deadlock = TimerInit()
			ChangeSecondProfession($attributesArray[0][0], $heroIndex)
			Do
				Sleep(20)
			Until GetHeroProfession($heroIndex, True) == $attributesArray[0][0] Or TimerDiff($deadlock) > 5000
		Until GetHeroProfession($heroIndex, True) == $attributesArray[0][0]
	EndIf

	$attributesArray[0][0] = $primaryAttribute
	For $i = 0 To UBound($attributesArray) - 1
		If $attributesArray[$i][1] > 12 Then $attributesArray[$i][1] = 12
		If $attributesArray[$i][1] < 0 Then $attributesArray[$i][1] = 0
	Next

	While GetAttributeByID($primaryAttribute, False, $heroIndex) > $attributesArray[0][1]
		$level = GetAttributeByID($primaryAttribute, False, $heroIndex)
		$deadlock = TimerInit()
		DecreaseAttribute($primaryAttribute, $heroIndex)
		Do
			Sleep(20)
		Until GetAttributeByID($primaryAttribute, False, $heroIndex) < $level Or TimerDiff($deadlock) > 5000
		Sleep(20)
	WEnd
	For $i = 1 To UBound($attributesArray) - 1
		While GetAttributeByID($attributesArray[$i][0], False, $heroIndex) > $attributesArray[$i][1]
			$level = GetAttributeByID($attributesArray[$i][0], False, $heroIndex)
			$deadlock = TimerInit()
			DecreaseAttribute($attributesArray[$i][0], $heroIndex)
			Do
				Sleep(20)
			Until GetAttributeByID($attributesArray[$i][0], False, $heroIndex) < $level Or TimerDiff($deadlock) > 5000
			Sleep(20)
		WEnd
	Next
	For $i = 0 To 44
		If GetAttributeByID($i, False, $heroIndex) > 0 Then
			If $i = $primaryAttribute Then ContinueLoop
			For $j = 1 To UBound($attributesArray) - 1
				If $i = $attributesArray[$j][0] Then ContinueLoop 2
			Next
			While GetAttributeByID($i, False, $heroIndex) > 0
				$level = GetAttributeByID($i, False, $heroIndex)
				$deadlock = TimerInit()
				DecreaseAttribute($i, $heroIndex)
				Do
					Sleep(20)
				Until GetAttributeByID($i, False, $heroIndex) < $level Or TimerDiff($deadlock) > 5000
				Sleep(20)
			WEnd
		EndIf
	Next

	While GetAttributeByID($primaryAttribute, False, $heroIndex) < $attributesArray[0][1]
		$level = GetAttributeByID($primaryAttribute, False, $heroIndex)
		$deadlock = TimerInit()
		IncreaseAttribute($primaryAttribute, $heroIndex)
		Do
			Sleep(20)
		Until GetAttributeByID($primaryAttribute, False, $heroIndex) > $level Or TimerDiff($deadlock) > 5000
		Sleep(20)
	WEnd
	For $i = 1 To UBound($attributesArray) - 1
		While GetAttributeByID($attributesArray[$i][0], False, $heroIndex) < $attributesArray[$i][1]
			$level = GetAttributeByID($attributesArray[$i][0], False, $heroIndex)
			$deadlock = TimerInit()
			IncreaseAttribute($attributesArray[$i][0], $heroIndex)
			Do
				Sleep(20)
			Until GetAttributeByID($attributesArray[$i][0], False, $heroIndex) > $level Or TimerDiff($deadlock) > 5000
			Sleep(20)
		WEnd
	Next
EndFunc


;~ Increase attribute by 1
Func IncreaseAttribute($attributeID, $heroIndex = 0)
	DllStructSetData($increaseAttributeStruct, 2, $attributeID)
	DllStructSetData($increaseAttributeStruct, 3, GetHeroID($heroIndex))
	Enqueue($increaseAttributeStructPtr, 12)
EndFunc


;~ Decrease attribute by 1
Func DecreaseAttribute($attributeID, $heroIndex = 0)
	DllStructSetData($decreaseAttributeStruct, 2, $attributeID)
	DllStructSetData($decreaseAttributeStruct, 3, GetHeroID($heroIndex))
	Enqueue($decreaseAttributeStructPtr, 12)
EndFunc


;~ Set all attributes to 0
Func ClearAttributes($heroIndex = 0)
	Local $level
	If GetInstanceType() <> 0 Then Return
	For $i = 0 To 44
		If GetAttributeByID($i, False, $heroIndex) > 0 Then
			Do
				$level = GetAttributeByID($i, False, $heroIndex)
				$deadlock = TimerInit()
				DecreaseAttribute($i, $heroIndex)
				Do
					Sleep(20)
				Until $level > GetAttributeByID($i, False, $heroIndex) Or TimerDiff($deadlock) > 5000
				Sleep(100)
			Until GetAttributeByID($i, False, $heroIndex) == 0
		EndIf
	Next
EndFunc


;~ Change your secondary profession.
Func ChangeSecondProfession($profession, $heroIndex = 0)
	Return SendPacket(0xC, $HEADER_PROFESSION_CHANGE, GetHeroID($heroIndex), $profession)
EndFunc


;~ Changes game language to english.
Func EnsureEnglish($ensureEnglish)
	MemoryWrite($forceEnglishLanguageFlag, $ensureEnglish ? 1 : 0)
EndFunc


;~ Change game language.
Func ToggleLanguage()
	DllStructSetData($toggleLanguageStruct, 2, 0x18)
	Enqueue($toggleLanguageStructPtr, 8)
EndFunc


;~ Changes the maximum distance you can zoom out.
Func ChangeMaxZoom($zoom = 750)
	MemoryWrite($zoomWhenStill, $zoom, 'float')
	MemoryWrite($zoomWhenMoving, $zoom, 'float')
EndFunc


;~ Emptys Guild Wars client memory
Func ClearMemory()
	DllCall($kernelHandle, 'int', 'SetProcessWorkingSetSize', 'int', $processHandle, 'int', -1, 'int', -1)
EndFunc


;~ Changes the maximum memory Guild Wars can use.
Func SetMaxMemory($maxMemory = 157286400)
	DllCall($kernelHandle, 'int', 'SetProcessWorkingSetSizeEx', 'int', $processHandle, 'int', 1, 'int', $maxMemory, 'int', 6)
EndFunc
#EndRegion Misc


;~ Internal use only.
Func Enqueue($ptr, $aSize)
	DllCall($kernelHandle, 'int', 'WriteProcessMemory', 'int', $processHandle, 'int', 256 * $queueCounter + $queueBaseAddress, 'ptr', $ptr, 'int', $aSize, 'int', '')
	$queueCounter = $queueCounter = $queueSize ? 0 : $queueCounter + 1
EndFunc


;~ Converts float to integer.
Func FloatToInt($float)
	Local $floatStruct = DllStructCreate('float')
	Local $int = DllStructCreate('int', DllStructGetPtr($floatStruct))
	DllStructSetData($floatStruct, 1, $float)
	Return DllStructGetData($int, 1)
EndFunc
#EndRegion Commands


#Region Queries
#Region Titles
;~ Set a title on
Func SetDisplayedTitle($title = 0)
	If $title Then
		Return SendPacket(0x8, $HEADER_TITLE_DISPLAY, $title)
	Else
		Return SendPacket(0x4, $HEADER_TITLE_HIDE)
	EndIf
EndFunc


; Set the title to Spearmarshall
Func SetTitleSpearmarshall()
	SendPacket(0x8, $HEADER_TITLE_DISPLAY, $ID_Sunspear_Title)
EndFunc


; Set the title to Lightbringer
Func SetTitleLightbringer()
	SendPacket(0x8, $HEADER_TITLE_DISPLAY, $ID_Lightbringer_Title)
EndFunc


; Set the title to Asuran
Func SetTitleAsuran()
	SendPacket(0x8, $HEADER_TITLE_DISPLAY, $ID_Asura_Title)
EndFunc


; Set the title to Dwarven
Func SetTitleDwarven()
	SendPacket(0x8, $HEADER_TITLE_DISPLAY, $ID_Dwarf_Title)
EndFunc


; Set the title to Ebon Vanguard
Func SetTitleEbonVanguard()
	SendPacket(0x8, $HEADER_TITLE_DISPLAY, $ID_Ebon_Vanguard_Title)
EndFunc


; Set the title to Norn
Func SetTitleNorn()
	SendPacket(0x8, $HEADER_TITLE_DISPLAY, $ID_Norn_Title)
EndFunc


;~ Returns Hero title progress.
Func GetHeroTitle()
	Return GetTitleProgress(0x4)
EndFunc


;~ Returns Gladiator title progress.
Func GetGladiatorTitle()
	Return GetTitleProgress(0x7C)
EndFunc


;~ Returns Codex title progress.
Func GetCodexTitle()
	Return GetTitleProgress(0x75C)
EndFunc


;~ Returns Kurzick title progress.
Func GetKurzickTitle()
	Return GetTitleProgress(0xCC)
EndFunc


;~ Returns Luxon title progress.
Func GetLuxonTitle()
	Return GetTitleProgress(0xF4)
EndFunc


;~ Returns drunkard title progress.
Func GetDrunkardTitle()
	Return GetTitleProgress(0x11C)
EndFunc


;~ Returns survivor title progress.
Func GetSurvivorTitle()
	Return GetTitleProgress(0x16C)
EndFunc


;~ Returns max titles
Func GetMaxTitles()
	Return GetTitleProgress(0x194)
EndFunc


;~ Returns lucky title progress.
Func GetLuckyTitle()
	Return GetTitleProgress(0x25C)
EndFunc


;~ Returns unlucky title progress.
Func GetUnluckyTitle()
	Return GetTitleProgress(0x284)
EndFunc


;~ Returns Sunspear title progress.
Func GetSunspearTitle()
	Return GetTitleProgress(0x2AC)
EndFunc


;~ Returns Lightbringer title progress.
Func GetLightbringerTitle()
	Return GetTitleProgress(0x324)
EndFunc


;~ Returns Commander title progress.
Func GetCommanderTitle()
	Return GetTitleProgress(0x374)
EndFunc


;~ Returns Gamer title progress.
Func GetGamerTitle()
	Return GetTitleProgress(0x39C)
EndFunc


;~ Returns Legendary Guardian title progress.
Func GetLegendaryGuardianTitle()
	Return GetTitleProgress(0x4DC)
EndFunc


;~ Returns sweets title progress.
Func GetSweetTitle()
	Return GetTitleProgress(0x554)
EndFunc


;~ Returns Asura title progress.
Func GetAsuraTitle()
	Return GetTitleProgress(0x5F4)
EndFunc


;~ Returns Deldrimor title progress.
Func GetDeldrimorTitle()
	Return GetTitleProgress(0x61C)
EndFunc


;~ Returns Vanguard title progress.
Func GetVanguardTitle()
	Return GetTitleProgress(0x644)
EndFunc


;~ Returns Norn title progress.
Func GetNornTitle()
	Return GetTitleProgress(0x66C)
EndFunc


;~ Returns mastery of the north title progress.
Func GetNorthMasteryTitle()
	Return GetTitleProgress(0x694)
EndFunc


;~ Returns party title progress.
Func GetPartyTitle()
	Return GetTitleProgress(0x6BC)
EndFunc


;~ Returns Zaishen title progress.
Func GetZaishenTitle()
	Return GetTitleProgress(0x6E4)
EndFunc


;~ Returns treasure hunter title progress.
Func GetTreasureTitle()
	Return GetTitleProgress(0x70C)
EndFunc


;~ Returns wisdom title progress.
Func GetWisdomTitle()
	Return GetTitleProgress(0x734)
EndFunc


;~ Return title progression - common part for most titles
Func GetTitleProgress($finalOffset)
	Local $offset[5] = [0, 0x18, 0x2C, 0x81C, $finalOffset]
	Local $result = MemoryReadPtr($baseAddressPtr, $offset)
	Return $result[1]
EndFunc


;~ Returns current Tournament points.
Func GetTournamentPoints()
	Local $offset[5] = [0, 0x18, 0x2C, 0, 0x18]
	Local $result = MemoryReadPtr($baseAddressPtr, $offset)
	Return $result[1]
EndFunc
#EndRegion Titles

#Region Faction
;~ Returns current Kurzick faction.
Func GetKurzickFaction()
	Return GetFaction(0x748)
EndFunc


;~ Returns max Kurzick faction.
Func GetMaxKurzickFaction()
	Return GetFaction(0x7B8)
EndFunc


;~ Returns current Luxon faction.
Func GetLuxonFaction()
	Return GetFaction(0x758)
EndFunc


;~ Returns max Luxon faction.
Func GetMaxLuxonFaction()
	Return GetFaction(0x7BC)
EndFunc


;~ Returns current Balthazar faction.
Func GetBalthazarFaction()
	Return GetFaction(0x798)
EndFunc


;~ Returns max Balthazar faction.
Func GetMaxBalthazarFaction()
	Return GetFaction(0x7C0)
EndFunc


;~ Returns current Imperial faction.
Func GetImperialFaction()
	Return GetFaction(0x76C)
EndFunc


;~ Returns max Imperial faction.
Func GetMaxImperialFaction()
	Return GetFaction(0x7C4)
EndFunc


;~ Returns the faction points depending on the offset provided
Func GetFaction($finalOffset)
	Local $offset[4] = [0, 0x18, 0x2C, $finalOffset]
	Local $result = MemoryReadPtr($baseAddressPtr, $offset)
	Return $result[1]
EndFunc
#EndRegion Faction


#Region Item
;~ Returns rarity (name color) of an item.
Func GetRarity($item)
	If Not IsDllStruct($item) Then $item = GetItemByItemID($item)
	Local $ptr = DllStructGetData($item, 'NameString')
	If $ptr == 0 Then Return
	Return MemoryRead($ptr, 'ushort')
EndFunc


;~ Tests if an item is identified.
Func GetIsIdentified($item)
	If Not IsDllStruct($item) Then $item = GetItemByItemID($item)
	Return BitAND(DllStructGetData($item, 'Interaction'), 1) > 0
EndFunc


Func GetIsRareMaterial($item)
	If Not IsDllStruct($item) Then $item = GetItemByItemID($item)
	If DllStructGetData($item, 'Type') <> 11 Then Return False
	Return Not GetIsCommonMaterial($item)
EndFunc


;~ Returns if material is Common.
Func GetIsCommonMaterial($item)
	If Not IsDllStruct($item) Then $item = GetItemByItemID($item)
	Return BitAND(DllStructGetData($item, 'Interaction'), 0x20) <> 0
EndFunc


;~ Returns a weapon or shield's minimum required attribute.
Func GetItemReq($item)
	Local $mod = GetModByIdentifier($item, '9827')
	Return $mod[0]
EndFunc


;~ Returns a weapon or shield's required attribute.
Func GetItemAttribute($item)
	Local $mod = GetModByIdentifier($item, '9827')
	Return $mod[1]
EndFunc


;~ Returns an array of a the requested mod.
Func GetModByIdentifier($item, $identifier)
	If Not IsDllStruct($item) Then $item = GetItemByItemID($item)
	Local $result[2]
	Local $string = StringTrimLeft(GetModStruct($item), 2)
	For $i = 0 To StringLen($string) / 8 - 2
		If StringMid($string, 8 * $i + 5, 4) == $identifier Then
			$result[0] = Int('0x' & StringMid($string, 8 * $i + 1, 2))
			$result[1] = Int('0x' & StringMid($string, 8 * $i + 3, 2))
			ExitLoop
		EndIf
	Next
	Return $result
EndFunc


;~ Returns modstruct of an item.
Func GetModStruct($item)
	If Not IsDllStruct($item) Then $item = GetItemByItemID($item)
	Local $modstruct = DllStructGetData($item, 'modstruct')
	If $modstruct = 0 Then Return
	Return MemoryRead($modstruct, 'Byte[' & DllStructGetData($item, 'modstructsize') * 4 & ']')
EndFunc


;~ Tests if an item is assigned to you.
Func GetAssignedToMe($agent)
	If Not IsDllStruct($agent) Then $agent = GetAgentByID($agent)
	Return DllStructGetData($agent, 'Owner') == GetMyID()
EndFunc


;~ Tests if you can pick up an item.
Func GetCanPickUp($agent)
	If Not IsDllStruct($agent) Then $agent = GetAgentByID($agent)
	Return GetAssignedToMe($agent) Or DllStructGetData($agent, 'Owner') = 0
EndFunc


;~ Returns struct of an inventory bag.
Func GetBag($bag)
	Local $offset[5] = [0, 0x18, 0x40, 0xF8, 0x4 * $bag]
	Local $bagPtr = MemoryReadPtr($baseAddressPtr, $offset)
	If $bagPtr[1] = 0 Then Return
	Local $bagStruct = DllStructCreate($bagStructTemplate)
	DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $bagPtr[1], 'ptr', DllStructGetPtr($bagStruct), 'int', DllStructGetSize($bagStruct), 'int', '')
	Return $bagStruct
EndFunc


;~ Returns item by slot.
Func GetItemBySlot($bag, $slot)
	If Not IsDllStruct($bag) Then $bag = GetBag($bag)

	Local $itemPtr = DllStructGetData($bag, 'ItemArray')
	Local $buffer = DllStructCreate('ptr')
	DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $itemPtr + 4 * ($slot - 1), 'ptr', DllStructGetPtr($buffer), 'int', DllStructGetSize($buffer), 'int', '')
	Local $itemStruct = DllStructCreate($itemStructTemplate)
	DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', DllStructGetData($buffer, 1), 'ptr', DllStructGetPtr($itemStruct), 'int', DllStructGetSize($itemStruct), 'int', '')
	Return $itemStruct
EndFunc


;~ Returns item struct.
Func GetItemByItemID($itemID)
	Local $offset[5] = [0, 0x18, 0x40, 0xB8, 0x4 * $itemID]
	Local $itemPtr = MemoryReadPtr($baseAddressPtr, $offset)
	Local $itemStruct = DllStructCreate($itemStructTemplate)
	DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $itemPtr[1], 'ptr', DllStructGetPtr($itemStruct), 'int', DllStructGetSize($itemStruct), 'int', '')
	Return $itemStruct
EndFunc


;~ Returns item by agent ID.
Func GetItemByAgentID($agent)
	Local $offset[4] = [0, 0x18, 0x40, 0xC0]
	Local $itemArraySize = MemoryReadPtr($baseAddressPtr, $offset)
	Local $offset[5] = [0, 0x18, 0x40, 0xB8, 0]
	Local $itemPtr, $itemID
	Local $agentID = ConvertID($agent)

	For $itemID = 1 To $itemArraySize[1]
		$offset[4] = 0x4 * $itemID
		$itemPtr = MemoryReadPtr($baseAddressPtr, $offset)
		If $itemPtr[1] = 0 Then ContinueLoop
		Local $itemStruct = DllStructCreate($itemStructTemplate)
		DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $itemPtr[1], 'ptr', DllStructGetPtr($itemStruct), 'int', DllStructGetSize($itemStruct), 'int', '')
		If DllStructGetData($itemStruct, 'AgentID') = $agentID Then Return $itemStruct
	Next
EndFunc


;~ Returns item by model ID.
Func GetItemByModelID($modelID)
	Local $offset[4] = [0, 0x18, 0x40, 0xC0]
	Local $itemArraySize = MemoryReadPtr($baseAddressPtr, $offset)
	Local $offset[5] = [0, 0x18, 0x40, 0xB8, 0]
	Local $itemPtr, $itemID

	For $itemID = 1 To $itemArraySize[1]
		$offset[4] = 0x4 * $itemID
		$itemPtr = MemoryReadPtr($baseAddressPtr, $offset)
		If $itemPtr[1] = 0 Then ContinueLoop
		Local $itemStruct = DllStructCreate($itemStructTemplate)
		DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $itemPtr[1], 'ptr', DllStructGetPtr($itemStruct), 'int', DllStructGetSize($itemStruct), 'int', '')
		If DllStructGetData($itemStruct, 'ModelID') = $modelID Then Return $itemStruct
	Next
EndFunc


;~ Returns the nearest item by model ID to an agent.
Func GetNearestItemByModelIDToAgent($modelID, $agent = -2)
	Local $nearestAgent, $nearestDistance = 100000000
	Local $distance
	If GetMaxAgents() > 0 Then
		For $i = 1 To GetMaxAgents()
			Local $a = GetAgentPtr($i)
			If Not GetIsMovable($a) Then ContinueLoop
			Local $agentModelID = DllStructGetData(GetItemByAgentID($i), 'ModelID')
			If $agentModelID = $modelID Then
				$distance = (GetAgentInfo($agent, 'X') - GetAgentInfo($a, 'X')) ^ 2 + (GetAgentInfo($agent, 'Y') - GetAgentInfo($a, 'Y')) ^ 2
				If $distance < $nearestDistance Then
					$nearestAgent = $a
					$nearestDistance = $distance
				EndIf
			EndIf
		Next
		Return $nearestAgent
	EndIf
EndFunc

;~ Returns amount of gold in storage.
Func GetGoldStorage()
	Local $offset[5] = [0, 0x18, 0x40, 0xF8, 0x94]
	Local $result = MemoryReadPtr($baseAddressPtr, $offset)
	Return $result[1]
EndFunc


;~ Returns amount of gold being carried.
Func GetGoldCharacter()
	Local $offset[5] = [0, 0x18, 0x40, 0xF8, 0x90]
	Local $result = MemoryReadPtr($baseAddressPtr, $offset)
	Return $result[1]
EndFunc


;~ Returns item ID of basic salvage kit in inventory.
Func FindBasicSalvageKit()
	Local $kits = [$ID_Salvage_Kit]
	Return FindKit($kits)
EndFunc


;~ Returns item ID of salvage kit in inventory (except basic)
Func FindSalvageKit()
	Local $kits = [$ID_Expert_Salvage_Kit, $ID_Superior_Salvage_Kit]
	Return FindKit($kits)
EndFunc


;~ Returns item ID of identification kit in inventory.
Func FindIdentificationKit()
	Local $kits = [$ID_Identification_Kit, $ID_Superior_Identification_Kit]
	Return FindKit($kits)
EndFunc


;~ Returns item ID of  kit in inventory.
Func FindKit($enabledModelIDs)
	Local $kit = 0
	Local $uses = 101
	Local $item, $modelID, $value, $id

	For $i = 1 To 16
		For $j = 1 To DllStructGetData(GetBag($i), 'Slots')
			$item = GetItemBySlot($i, $j)
			$modelID = DllStructGetData($item, 'ModelID')

			; Skip this item if model is not in our list
			If Not FindKitArrayContainsHelper($enabledModelIDs, $modelID) Then ContinueLoop

			$id = DllStructGetData($item, 'ID')
			$value = DllStructGetData($item, 'Value')

			Switch $modelID
				Case $ID_Salvage_Kit
					If $value / 2 < $uses Then
						$uses = $value / 2
						$kit = $id
					EndIf
				Case $ID_Expert_Salvage_Kit
					If $value / 8 < $uses Then
						$uses = $value / 8
						$kit = $id
					EndIf
				Case $ID_Superior_Salvage_Kit
					If $value / 10 < $uses Then
						$uses = $value / 10
						$kit = $id
					EndIf
				Case $ID_Identification_Kit
					If $value / 2 < $uses Then
						$uses = $value / 2
						$kit = $id
					EndIf
				Case $ID_Superior_Identification_Kit
					If $value / 2.5 < $uses Then
						$uses = $value / 2.5
						$kit = $id
					EndIf
			EndSwitch
		Next
	Next

	Return $kit
EndFunc


;~ Return True if item is present in array, else False - duplicate in Utils
Func FindKitArrayContainsHelper($array, $item)
	For $i = 0 To UBound($array) - 1
		If $array[$i] == $item Then Return True
	Next
	Return False
EndFunc


;~ Returns the item ID of the quoted item.
Func GetTraderCostID()
	Return MemoryRead($traderCostId)
EndFunc


;~ Returns the cost of the requested item.
Func GetTraderCostValue()
	Return MemoryRead($traderCostValue)
EndFunc


;~ Internal use for BuyItem()
Func GetMerchantItemsBase()
	Local $offset[4] = [0, 0x18, 0x2C, 0x24]
	Local $result = MemoryReadPtr($baseAddressPtr, $offset)
	Return $result[1]
EndFunc


;~ Internal use for BuyItem()
Func GetMerchantItemsSize()
	Local $offset[4] = [0, 0x18, 0x2C, 0x28]
	Local $result = MemoryReadPtr($baseAddressPtr, $offset)
	Return $result[1]
EndFunc
#EndRegion Item


#Region H&H
;~ Returns number of heroes you control.
Func GetHeroCount()
	Local $offset[5] = [0, 0x18, 0x4C, 0x54, 0x2C]
	Local $heroCount = MemoryReadPtr($baseAddressPtr, $offset)
	Return $heroCount[1]
EndFunc


;~ Returns agent ID of a hero.
Func GetHeroID($heroIndex)
	If $heroIndex == 0 Then Return GetMyID()
	Local $offset[6] = [0, 0x18, 0x4C, 0x54, 0x24, 0x18 * ($heroIndex - 1)]
	Local $agentID = MemoryReadPtr($baseAddressPtr, $offset)
	Return $agentID[1]
EndFunc


;~ Returns hero number by agent ID.
Func GetHeroNumberByAgentID($heroID)
	Local $agentID
	Local $offset[6] = [0, 0x18, 0x4C, 0x54, 0x24, 0]
	For $i = 1 To GetHeroCount()
		$offset[5] = 0x18 * ($i - 1)
		$agentID = MemoryReadPtr($baseAddressPtr, $offset)
		If $agentID[1] == ConvertID($heroID) Then Return $i
	Next
	Return 0
EndFunc


;~ Returns hero number by hero ID.
Func GetHeroNumberByHeroID($heroID)
	Local $agentID
	Local $offset[6] = [0, 0x18, 0x4C, 0x54, 0x24, 0]
	For $i = 1 To GetHeroCount()
		$offset[5] = 8 + 0x18 * ($i - 1)
		$agentID = MemoryReadPtr($baseAddressPtr, $offset)
		If $agentID[1] == ConvertID($heroID) Then Return $i
	Next
	Return 0
EndFunc


;~ Returns hero's profession ID (when it can't be found by other means)
Func GetHeroProfession($heroIndex, $secondary = False)
	Local $offset[5] = [0, 0x18, 0x2C, 0x6BC, 0]
	Local $buffer
	$heroIndex = GetHeroID($heroIndex)
	For $i = 0 To GetHeroCount()
		$buffer = MemoryReadPtr($baseAddressPtr, $offset)
		If $buffer[1] = $heroIndex Then
			$offset[4] += 4
			If $secondary Then $offset[4] += 4
			$buffer = MemoryReadPtr($baseAddressPtr, $offset)
			Return $buffer[1]
		EndIf
		$offset[4] += 0x14
	Next
EndFunc


;~ Tests if a hero's skill slot is disabled.
Func GetIsHeroSkillSlotDisabled($heroIndex, $skillSlot)
	Return BitAND(BitShift(1, -($skillSlot - 1)), DllStructGetData(GetSkillbar($heroIndex), 'Disabled')) > 0
EndFunc
#EndRegion H&H


#Region Agent
;~ Returns an agent struct.
Func GetAgentByID($agentID = -2)
	Local $agentPtr = GetAgentPtr($agentID)
	Local $agentStruct = DllStructCreate($agentStructTemplate)
	DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $agentPtr, 'ptr', DllStructGetPtr($agentStruct), 'int', DllStructGetSize($agentStruct), 'int', '')
	Return $agentStruct
EndFunc


Func GetAgentInfo($agentID, $info = '')
	Local $agentPtr = GetAgentPtr($agentID)
	If $agentPtr = 0 Or $info = '' Then Return 0

	Switch $info
		Case 'vtable'
			Return MemoryRead($agentPtr, 'ptr')
		Case 'h0004'
			Return MemoryRead($agentPtr + 0x4, 'dword')
		Case 'h0008'
			Return MemoryRead($agentPtr + 0x8, 'dword')
		Case 'h000C'
			Return MemoryRead($agentPtr + 0xC, 'dword')
		Case 'h0010'
			Return MemoryRead($agentPtr + 0x10, 'dword')
		Case 'Timer'
			Return MemoryRead($agentPtr + 0x14, 'dword')
		Case 'Timer2'
			Return MemoryRead($agentPtr + 0x18, 'dword')
		Case 'h0018'
			Return MemoryRead($agentPtr + 0x1C, 'dword[4]')
		Case 'ID'
			Return MemoryRead($agentPtr + 0x2C, 'long')
		Case 'Z'
			Return MemoryRead($agentPtr + 0x30, 'float')
		Case 'Width1'
			Return MemoryRead($agentPtr + 0x34, 'float')
		Case 'Height1'
			Return MemoryRead($agentPtr + 0x38, 'float')
		Case 'Width2'
			Return MemoryRead($agentPtr + 0x3C, 'float')
		Case 'Height2'
			Return MemoryRead($agentPtr + 0x40, 'float')
		Case 'Width3'
			Return MemoryRead($agentPtr + 0x44, 'float')
		Case 'Height3'
			Return MemoryRead($agentPtr + 0x48, 'float')
		Case 'Rotation'
			Return MemoryRead($agentPtr + 0x4C, 'float')
		Case 'RotationCos'
			Return MemoryRead($agentPtr + 0x50, 'float')
		Case 'RotationSin'
			Return MemoryRead($agentPtr + 0x54, 'float')
		Case 'NameProperties'
			Return MemoryRead($agentPtr + 0x58, 'dword')
		Case 'Ground'
			Return MemoryRead($agentPtr + 0x5C, 'dword')
		Case 'h0060'
			Return MemoryRead($agentPtr + 0x60, 'dword')
		Case 'TerrainNormalX'
			Return MemoryRead($agentPtr + 0x64, 'float')
		Case 'TerrainNormalY'
			Return MemoryRead($agentPtr + 0x68, 'float')
		Case 'TerrainNormalZ'
			Return MemoryRead($agentPtr + 0x6C, 'dword')
		Case 'h0070'
			Return MemoryRead($agentPtr + 0x70, 'byte[4]')
		Case 'X'
			Return MemoryRead($agentPtr + 0x74, 'float')
		Case 'Y'
			Return MemoryRead($agentPtr + 0x78, 'float')
		Case 'Plane'
			Return MemoryRead($agentPtr + 0x7C, 'dword')
		Case 'h0080'
			Return MemoryRead($agentPtr + 0x80, 'byte[4]')
		Case 'NameTagX'
			Return MemoryRead($agentPtr + 0x84, 'float')
		Case 'NameTagY'
			Return MemoryRead($agentPtr + 0x88, 'float')
		Case 'NameTagZ'
			Return MemoryRead($agentPtr + 0x8C, 'float')
		Case 'VisualEffects'
			Return MemoryRead($agentPtr + 0x90, 'short')
		Case 'h0092'
			Return MemoryRead($agentPtr + 0x92, 'short')
		Case 'h0094'
			Return MemoryRead($agentPtr + 0x94, 'dword[2]')
		Case 'Type'
			Return MemoryRead($agentPtr + 0x98, 'long')
		Case 'MoveX'
			Return MemoryRead($agentPtr + 0xA0, 'float')
		Case 'MoveY'
			Return MemoryRead($agentPtr + 0xA4, 'float')
		Case 'h00A8'
			Return MemoryRead($agentPtr + 0xA8, 'dword')
		Case 'RotationCos2'
			Return MemoryRead($agentPtr + 0xAC, 'float')
		Case 'RotationSin2'
			Return MemoryRead($agentPtr + 0xB0, 'float')
		Case 'h00B4'
			Return MemoryRead($agentPtr + 0xB4, 'dword[4]')
		Case 'Owner'
			Return MemoryRead($agentPtr + 0xC4, 'long')
		Case 'ItemID'
			Return MemoryRead($agentPtr + 0xC8, 'dword')
		Case 'ExtraType'
			Return MemoryRead($agentPtr + 0xCC, 'dword')
		Case 'GadgetID'
			Return MemoryRead($agentPtr + 0xD0, 'dword')
		Case 'h00D4'
			Return MemoryRead($agentPtr + 0xD4, 'dword[3]')
		Case 'AnimationType'
			Return MemoryRead($agentPtr + 0xE0, 'float')
		Case 'h00E4'
			Return MemoryRead($agentPtr + 0xE4, 'dword[2]')
		Case 'AttackSpeed'
			Return MemoryRead($agentPtr + 0xEC, 'float')
		Case 'AttackSpeedModifier'
			Return MemoryRead($agentPtr + 0xF0, 'float')
		Case 'PlayerNumber'
			Return MemoryRead($agentPtr + 0xF4, 'short')
		Case 'AgentModelType'
			Return MemoryRead($agentPtr + 0xF6, 'short')
		Case 'TransmogNpcId'
			Return MemoryRead($agentPtr + 0xF8, 'dword')
		Case 'Equip'
			Return MemoryRead($agentPtr + 0xFC, 'ptr')
		Case 'h0100'
			Return MemoryRead($agentPtr + 0x100, 'dword')
		Case 'Tags'
			Return MemoryRead($agentPtr + 0x104, 'ptr')
		Case 'h0108'
			Return MemoryRead($agentPtr + 0x108, 'short')
		Case 'Primary'
			Return MemoryRead($agentPtr + 0x10A, 'byte')
		Case 'Secondary'
			Return MemoryRead($agentPtr + 0x10B, 'byte')
		Case 'Level'
			Return MemoryRead($agentPtr + 0x10C, 'byte')
		Case 'Team'
			Return MemoryRead($agentPtr + 0x10D, 'byte')
		Case 'h010E'
			Return MemoryRead($agentPtr + 0x10E, 'byte[2]')
		Case 'h0110'
			Return MemoryRead($agentPtr + 0x110, 'dword')
		Case 'EnergyRegen'
			Return MemoryRead($agentPtr + 0x114, 'float')
		Case 'Overcast'
			Return MemoryRead($agentPtr + 0x118, 'float')
		Case 'EnergyPercent'
			Return MemoryRead($agentPtr + 0x11C, 'float')
		Case 'MaxEnergy'
			Return MemoryRead($agentPtr + 0x120, 'dword')
		Case 'h0124'
			Return MemoryRead($agentPtr + 0x124, 'dword')
		Case 'HPPips'
			Return MemoryRead($agentPtr + 0x128, 'float')
		Case 'h012C'
			Return MemoryRead($agentPtr + 0x12C, 'dword')
		Case 'HP'
			Return MemoryRead($agentPtr + 0x130, 'float')
		Case 'MaxHP'
			Return MemoryRead($agentPtr + 0x134, 'dword')
		Case 'Effects'
			Return MemoryRead($agentPtr + 0x138, 'dword')
		Case 'h013C'
			Return MemoryRead($agentPtr + 0x13C, 'dword')
		Case 'Hex'
			Return MemoryRead($agentPtr + 0x140, 'byte')
		Case 'h0141'
			Return MemoryRead($agentPtr + 0x141, 'byte[19]')
		Case 'ModelState'
			Return MemoryRead($agentPtr + 0x154, 'dword')
		Case 'TypeMap'
			Return MemoryRead($agentPtr + 0x158, 'dword')
		Case 'h015C'
			Return MemoryRead($agentPtr + 0x15C, 'dword[4]')
		Case 'InSpiritRange'
			Return MemoryRead($agentPtr + 0x16C, 'dword')
		Case 'VisibleEffects'
			Return MemoryRead($agentPtr + 0x170, 'dword')
		Case 'VisibleEffectsID'
			Return MemoryRead($agentPtr + 0x174, 'dword')
		Case 'VisibleEffectsHasEnded'
			Return MemoryRead($agentPtr + 0x178, 'dword')
		Case 'h017C'
			Return MemoryRead($agentPtr + 0x17C, 'dword')
		Case 'LoginNumber'
			Return MemoryRead($agentPtr + 0x180, 'dword')
		Case 'AnimationSpeed'
			Return MemoryRead($agentPtr + 0x184, 'float')
		Case 'AnimationCode'
			Return MemoryRead($agentPtr + 0x188, 'dword')
		Case 'AnimationId'
			Return MemoryRead($agentPtr + 0x18C, 'dword')
		Case 'h0190'
			Return MemoryRead($agentPtr + 0x190, 'byte[32]')
		Case 'LastStrike'
			Return MemoryRead($agentPtr + 0x1B0, 'byte')
		Case 'Allegiance'
			Return MemoryRead($agentPtr + 0x1B1, 'byte')
		Case 'WeaponType'
			Return MemoryRead($agentPtr + 0x1B2, 'short')
		Case 'Skill'
			Return MemoryRead($agentPtr + 0x1B4, 'short')
		Case 'h01B6'
			Return MemoryRead($agentPtr + 0x1B6, 'short')
		Case 'WeaponItemType'
			Return MemoryRead($agentPtr + 0x1B8, 'byte')
		Case 'OffhandItemType'
			Return MemoryRead($agentPtr + 0x1B9, 'byte')
		Case 'WeaponItemId'
			Return MemoryRead($agentPtr + 0x1BA, 'short')
		Case 'OffhandItemId'
			Return MemoryRead($agentPtr + 0x1BC, 'short')
		Case Else
			Return 0
	EndSwitch

	Return 0
EndFunc


;~ Internal use for GetAgentByID()
Func GetAgentPtr($agentID = -2)
	Local $offset[3] = [0, 4 * ConvertID($agentID), 0]
	Local $lAgentStructAddress = MemoryReadPtr($agentBaseAddress, $offset)
	Return $lAgentStructAddress[0]
EndFunc


;~ Test if an agent exists.
Func GetAgentExists($agentID)
	Return GetAgentPtr($agentID) <> 0
EndFunc


;~ Returns the target of an agent.
Func GetTarget($agent)
	Return MemoryRead(GetValue('TargetLogBase') + 4 * ConvertID($agent))
EndFunc


;~ Returns agent by player name.
Func GetAgentByPlayerName($playerName)
	For $i = 1 To GetMaxAgents()
		If GetPlayerName($i) = $playerName Then
			Return GetAgentByID($i)
		EndIf
	Next
EndFunc


;~ Returns agent by name.
Func GetAgentByName($agentName)
	If $useStringLogging = False Then Return

	Local $name, $address

	For $i = 1 To GetMaxAgents()
		$address = $stringLogBaseAddress + 256 * $i
		$name = MemoryRead($address, 'wchar [128]')
		$name = StringRegExpReplace($name, '[<]{1}([^>]+)[>]{1}', '')
		If StringInStr($name, $agentName) > 0 Then Return GetAgentByID($i)
	Next

	DisplayAll(True)
	Sleep(100)
	DisplayAll(False)
	DisplayAll(True)
	Sleep(100)
	DisplayAll(False)

	For $i = 1 To GetMaxAgents()
		$address = $stringLogBaseAddress + 256 * $i
		$name = MemoryRead($address, 'wchar [128]')
		$name = StringRegExpReplace($name, '[<]{1}([^>]+)[>]{1}', '')
		If StringInStr($name, $agentName) > 0 Then Return GetAgentByID($i)
	Next
EndFunc


;~ Returns the nearest signpost to an agent.
Func GetNearestSignpostToAgent($agent = -2)
	Return GetNearestAgentToAgent($agent, 0x200)
EndFunc


;~ Returns the nearest NPC to an agent.
Func GetNearestNPCToAgent($agent)
	Return GetNearestAgentToAgent($agent, 0xDB, NPCAgentFilter)
EndFunc


;~ Return True if an agent is an enemy, False else
Func NPCAgentFilter($agent)
	If GetAgentInfo($agent, 'Allegiance') <> 6 Then Return False
	If GetAgentInfo($agent, 'HP') <= 0 Then Return False
	If BitAND(GetAgentInfo($agent, 'Effects'), 0x0010) > 0 Then Return False
	Return True
EndFunc


;~ Returns the nearest enemy to an agent.
Func GetNearestEnemyToAgent($agent = -2)
	Return GetNearestAgentToAgent($agent, 0xDB, EnemyAgentFilter)
EndFunc


;~ Return True if an agent is an enemy, False else
Func EnemyAgentFilter($agent)
	If GetAgentInfo($agent, 'Allegiance') <> 3 Then Return False
	If GetAgentInfo($agent, 'HP') <= 0 Then Return False
	If BitAND(GetAgentInfo($agent, 'Effects'), 0x0010) > 0 Then Return False
	If GetAgentInfo($agent, 'TypeMap') == 262144 Then Return False	;It's a spirit
	Return True
EndFunc


;~ Returns the nearest agent to an agent.
Func GetNearestAgentToAgent($agent = -2, $agentType = 0, $agentFilter = Null)
	Local $nearestAgent, $nearestDistance = 100000000
	Local $distance
	Local $agentArray = GetAgentArray($agentType)
	Local $agentID = GetAgentInfo($agent, 'ID')
	Local $ownID = GetAgentInfo(-2, 'ID')
	Local $X = GetAgentInfo($agent, 'X')
	Local $Y = GetAgentInfo($agent, 'Y')

	For $i = 1 To $agentArray[0]
		If GetAgentInfo($agentArray[$i], 'ID') == $agentID Then ContinueLoop
		If GetAgentInfo($agentArray[$i], 'ID') == $ownID Then ContinueLoop
		If $agentFilter <> Null And Not $agentFilter($agentArray[$i]) Then ContinueLoop
		$distance = ($X - GetAgentInfo($agentArray[$i], 'X')) ^ 2 + ($Y - GetAgentInfo($agentArray[$i], 'Y')) ^ 2
		If $distance < $nearestDistance Then
			$nearestAgent = $agentArray[$i]
			$nearestDistance = $distance
		EndIf
	Next

	SetExtended(Sqrt($nearestDistance))
	Return $nearestAgent
EndFunc


;~ Returns the nearest item to an agent.
Func GetNearestItemToAgent($agent = -2, $canPickUp = True)
	If $canPickUp Then
		Return GetNearestAgentToAgent($agent, 0x400, GetCanPickUp)
	Else
		Return GetNearestAgentToAgent($agent, 0x400)
	EndIf
EndFunc


;~ Returns the nearest signpost to a set of coordinates.
Func GetNearestSignpostToCoords($X, $Y)
	Return GetNearestAgentToCoords($X, $Y, 0x200)
EndFunc


;~ Returns the nearest NPC to a set of coordinates.
Func GetNearestNPCToCoords($X, $Y)
	Return GetNearestAgentToCoords($X, $Y, 0xDB, NPCAgentFilter)
EndFunc


;~ Returns the nearest enemy to coordinates
Func GetNearestEnemyToCoords($X, $Y)
	Return GetNearestAgentToCoords($X, $Y, 0xDB, EnemyAgentFilter)
EndFunc


;~ Returns the nearest agent to a set of coordinates.
Func GetNearestAgentToCoords($X, $Y, $agentType = 0, $agentFilter = Null)
	Local $nearestAgent, $nearestDistance = 100000000
	Local $distance
	Local $agentArray = GetAgentArray($agentType)
	Local $ownID = GetAgentInfo(-2, 'ID')

	For $i = 1 To $agentArray[0]
		If GetAgentInfo($agentArray[$i], 'ID') == $ownID Then ContinueLoop
		If $agentFilter <> Null And Not $agentFilter($agentArray[$i]) Then ContinueLoop
		$distance = ($X - GetAgentInfo($agentArray[$i], 'X')) ^ 2 + ($Y - GetAgentInfo($agentArray[$i], 'Y')) ^ 2
		If $distance < $nearestDistance Then
			$nearestAgent = $agentArray[$i]
			$nearestDistance = $distance
		EndIf
	Next

	SetExtended(Sqrt($nearestDistance))
	Return $nearestAgent
EndFunc


Func GetAgentByPlayerNumber($playerNumber)
	Local $agentArray = GetAgentArray()
	For $i = 1 To $agentArray[0]
		If GetAgentInfo($agentArray[$i], 'Allegiance') == 1 And GetAgentInfo($agentArray[$i], 'PlayerNumber') == $playerNumber Then Return $agentArray[$i]
	Next
EndFunc


;~ Returns array of party members
;~ Param: an array returned by GetAgentArray. This is totally optional, but can greatly improve script speed.
Func GetParty($agentArray = 0)
	Local $resultArray[1] = [0]
	If $agentArray == 0 Then $agentArray = GetAgentArray(0xDB)
	For $i = 1 To $agentArray[0]
		If GetAgentInfo($agentArray[$i], 'Allegiance') <> 1 Then ContinueLoop
		If Not BitAND(GetAgentInfo($agentArray[$i], 'TypeMap'), 131072) Then ContinueLoop
		$resultArray[0] += 1
		ReDim $resultArray[$resultArray[0] + 1]
		$resultArray[$resultArray[0]] = $agentArray[$i]
	Next
	Return $resultArray
EndFunc


; Returns true if any party member is dead
Func CheckIfAnyPartyMembersDead()
	Local $partyArray = GetParty()
	For $i = 1 To $partyArray[0]
		If GetIsDead($partyArray[$i]) Then
			Return True
		EndIf
	Next
	Return False
EndFunc


;~ Quickly creates an array of agents of a given type
Func GetAgentArray($type = 0)
	Local $struct
	Local $count
	Local $buffer = ''
	DllStructSetData($makeAgentArrayStruct, 2, $type)
	MemoryWrite($agentCopyCount, -1, 'long')
	Enqueue($makeAgentArrayStructPtr, 8)
	Local $deadlock = TimerInit()
	Do
		Sleep(1)
		$count = MemoryRead($agentCopyCount, 'long')
	Until $count >= 0 Or TimerDiff($deadlock) > 5000
	If $count < 0 Then $count = 0
	For $i = 1 To $count
		$buffer &= 'Byte[448];'
	Next
	$buffer = DllStructCreate($buffer)
	DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $agentCopyBase, 'ptr', DllStructGetPtr($buffer), 'int', DllStructGetSize($buffer), 'int', '')
	Local $returnArray[$count + 1] = [$count]
	For $i = 1 To $count
		$returnArray[$i] = DllStructCreate($agentStructTemplate)
		$struct = DllStructCreate('byte[448]', DllStructGetPtr($returnArray[$i]))
		DllStructSetData($struct, 1, DllStructGetData($buffer, $i))
	Next
	Return $returnArray
EndFunc


Func GetIsHardMode()
	Return GetPartyState(0x10)
EndFunc


;~ Return the number of enemy agents targeting the given agent.
Func GetAgentDanger($agent, $agentArray = 0)
	If $agentArray == 0 Then $agentArray = GetAgentArray(0xDB)
	Return GetPartyDanger($agentArray, [1, $agent])[1]
EndFunc


;~ Returns the 'danger level' of each party member
;~ Param1: an array returned by GetAgentArray(). This is totally optional, but can greatly improve script speed.
;~ Param2: an array returned by GetParty() This is totally optional, but can greatly improve script speed.
Func GetPartyDanger($agentArray = 0, $party = 0)
	If $agentArray == 0 Then $agentArray = GetAgentArray(0xDB)
	If $party == 0 Then $party = GetParty($agentArray)
	
	Local $resultArray[$party[0] + 1]
	$resultArray[0] = $party[0]
	For $i = 1 To $resultArray[0]
		$resultArray[$i] = 0
	Next

	For $i = 1 To $agentArray[0]
		If BitAND(GetAgentInfo($agentArray[$i], 'Effects'), 0x0010) > 0 Then ContinueLoop
		If GetAgentInfo($agentArray[$i], 'HP') <= 0 Then ContinueLoop
		If Not GetIsLiving($agentArray[$i]) Then ContinueLoop
		Local $allegiance = GetAgentInfo($agentArray[$i], 'Allegiance')
		If $allegiance > 3 Then ContinueLoop ; ignore NPCs, spirits, minions, pets

		Local $targetID = GetTarget(GetAgentInfo($agentArray[$i], 'ID'))
		Local $team = GetAgentInfo($agentArray[$i], 'Team')
		For $j = 1 To $party[0]
			If $targetID == GetAgentInfo($party[$j], 'ID') Then
				If GetDistance($agentArray[$i], $party[$j]) < 5000 Then
					If $team <> 0 Then
						If $team <> GetAgentInfo($party[$j], 'Team') Then
							$resultArray[$j] += 1
						EndIf
					ElseIf $allegiance <> GetAgentInfo($party[$j], 'Allegiance') Then
						$resultArray[$j] += 1
					EndIf
				EndIf
			EndIf
		Next
	Next
	Return $resultArray
EndFunc
#EndRegion Agent


#Region AgentInfo
;~ Tests if an agent is living.
Func GetIsLiving($agent)
	Return GetAgentInfo($agent, 'Type') = 0xDB
EndFunc


;~ Tests if an agent is a signpost/chest/etc.
Func GetIsStatic($agent)
	Return GetAgentInfo($agent, 'Type') = 0x200
EndFunc


;~ Tests if an agent is an item.
Func GetIsMovable($agent)
	Return GetAgentInfo($agent, 'Type') = 0x400
EndFunc


;~ Returns energy of an agent. (Only self/heroes)
Func GetEnergy($agent = -2)
	Return GetAgentInfo($agent, 'EnergyPercent') * GetAgentInfo($agent, 'MaxEnergy')
EndFunc


;~ Returns health of an agent. (Must have caused numerical change in health)
Func GetHealth($agent = -2)
	Return GetAgentInfo($agent, 'HP') * GetAgentInfo($agent, 'MaxHP')
EndFunc


;~ Tests if an agent is moving.
Func GetIsMoving($agent)
	If GetAgentInfo($agent, 'MoveX') <> 0 Or GetAgentInfo($agent, 'MoveY') <> 0 Then Return True
	Return False
EndFunc


;~ Tests if an agent is knocked down.
Func GetIsKnocked($agent)
	Return GetAgentInfo($agent, 'ModelState') = 0x450
EndFunc


;~ Tests if an agent is attacking.
Func GetIsAttacking($agent)
	Switch GetAgentInfo($agent, 'ModelState')
		Case 0x60, 0x440, 0x460
			Return True
	EndSwitch
	Return False
EndFunc


;~ Tests if an agent is casting.
Func GetIsCasting($agent)
	Return GetAgentInfo($agent, 'Skill') <> 0
EndFunc


;~ Tests if an agent is bleeding.
Func GetIsBleeding($agent)
	Return BitAND(GetAgentInfo($agent, 'Effects'), 0x0001) > 0
EndFunc


;~ Tests if an agent has a condition.
Func GetHasCondition($agent)
	Return BitAND(GetAgentInfo($agent, 'Effects'), 0x0002) > 0
EndFunc


;~ Tests if an agent is dead.
Func GetIsDead($agent)
	Return BitAND(GetAgentInfo($agent, 'Effects'), 0x0010) > 0
EndFunc

;~ Tests if an agent has a deep wound.
Func GetHasDeepWound($agent)
	Return BitAND(GetAgentInfo($agent, 'Effects'), 0x0020) > 0
EndFunc


;~ Tests if an agent is poisoned.
Func GetIsPoisoned($agent)
	Return BitAND(GetAgentInfo($agent, 'Effects'), 0x0040) > 0
EndFunc


;~ Tests if an agent is enchanted.
Func GetIsEnchanted($agent)
	Return BitAND(GetAgentInfo($agent, 'Effects'), 0x0080) > 0
EndFunc


;~ Tests if an agent has a degen hex.
Func GetHasDegenHex($agent)
	Return BitAND(GetAgentInfo($agent, 'Effects'), 0x0400) > 0
EndFunc


;~ Tests if an agent is hexed.
Func GetHasHex($agent)
	Return BitAND(GetAgentInfo($agent, 'Effects'), 0x0800) > 0
EndFunc


;~ Tests if an agent has a weapon spell.
Func GetHasWeaponSpell($agent)
	Return BitAND(GetAgentInfo($agent, 'Effects'), 0x8000) > 0
EndFunc


;~ Tests if an agent is a boss.
Func GetIsBoss($agent)
	Return BitAND(GetAgentInfo($agent, 'TypeMap'), 1024) > 0
EndFunc


;~ Returns a player's name.
Func GetPlayerName($agent)
	Local $loginNumber = GetAgentInfo($agent, 'LoginNumber')
	Local $offset[6] = [0, 0x18, 0x2C, 0x80C, 76 * $loginNumber + 0x28, 0]
	Local $result = MemoryReadPtr($baseAddressPtr, $offset, 'wchar[30]')
	Return $result[1]
EndFunc


;~ Returns the name of an agent.
Func GetAgentName($agent)
	Local $address = $stringLogBaseAddress + 256 * ConvertID($agent)
	Local $agentName = MemoryRead($address, 'wchar [128]')

	If $agentName = '' Then
		DisplayAll(True)
		Sleep(100)
		DisplayAll(False)
	EndIf

	Local $agentName = MemoryRead($address, 'wchar [128]')
	$agentName = StringRegExpReplace($agentName, '[<]{1}([^>]+)[>]{1}', '')
	Return $agentName
EndFunc
#EndRegion AgentInfo


#Region Buff
;~ Returns current number of buffs being maintained.
Func GetBuffCount($heroIndex = 0)
	Local $offset[4] = [0, 0x18, 0x2C, 0x510]
	Local $count = MemoryReadPtr($baseAddressPtr, $offset)
	ReDim $offset[5]
	$offset[3] = 0x508
	Local $buffer
	For $i = 0 To $count[1] - 1
		$offset[4] = 0x24 * $i
		$buffer = MemoryReadPtr($baseAddressPtr, $offset)
		If $buffer[1] == GetHeroID($heroIndex) Then
			Return MemoryRead($buffer[0] + 0xC)
		EndIf
	Next
	Return 0
EndFunc


;~ Tests if you are currently maintaining buff on target.
Func GetIsTargetBuffed($skillID, $agentID, $heroIndex = 0)
	Local $buffCount = GetBuffCount($heroIndex)
	Local $buffStructAddress
	Local $offset[4] = [0, 0x18, 0x2C, 0x510]
	Local $count = MemoryReadPtr($baseAddressPtr, $offset)
	ReDim $offset[5]
	$offset[3] = 0x508
	Local $buffer
	For $i = 0 To $count[1] - 1
		$offset[4] = 0x24 * $i
		$buffer = MemoryReadPtr($baseAddressPtr, $offset)
		If $buffer[1] == GetHeroID($heroIndex) Then
			$offset[4] = 0x4 + 0x24 * $i
			ReDim $offset[6]
			For $j = 0 To $buffCount - 1
				$offset[5] = 0 + 0x10 * $j
				$buffStructAddress = MemoryReadPtr($baseAddressPtr, $offset)
				Local $buffStruct = DllStructCreate($buffStructTemplate)
				DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $buffStructAddress[0], 'ptr', DllStructGetPtr($buffStruct), 'int', DllStructGetSize($buffStruct), 'int', '')
				If (DllStructGetData($buffStruct, 'SkillID') == $skillID) And (DllStructGetData($buffStruct, 'TargetId') == ConvertID($agentID)) Then
					Return $j + 1
				EndIf
			Next
		EndIf
	Next
	Return 0
EndFunc


;~ Returns buff struct.
Func GetBuffByIndex($buffIndex, $heroIndex = 0)
	Local $offset[4] = [0, 0x18, 0x2C, 0x510]
	Local $count = MemoryReadPtr($baseAddressPtr, $offset)
	ReDim $offset[5]
	$offset[3] = 0x508
	Local $buffer
	For $i = 0 To $count[1] - 1
		$offset[4] = 0x24 * $i
		$buffer = MemoryReadPtr($baseAddressPtr, $offset)
		If $buffer[1] == GetHeroID($heroIndex) Then
			$offset[4] = 0x4 + 0x24 * $i
			ReDim $offset[6]
			$offset[5] = 0 + 0x10 * ($buffIndex - 1)
			$buffStructAddress = MemoryReadPtr($baseAddressPtr, $offset)
			Local $buffStruct = DllStructCreate($buffStructTemplate)
			DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $buffStructAddress[0], 'ptr', DllStructGetPtr($buffStruct), 'int', DllStructGetSize($buffStruct), 'int', '')
			Return $buffStruct
		EndIf
	Next
	Return 0
EndFunc
#EndRegion Buff


#Region Misc
;~ Returns skillbar struct.
Func GetSkillbar($heroIndex = 0)
	Local $offset[5] = [0, 0x18, 0x2C, 0x6F0, 0]
	For $i = 0 To GetHeroCount()
		$offset[4] = $i * 0xBC
		Local $skillbarStructAddress = MemoryReadPtr($baseAddressPtr, $offset)
		Local $skillbarStruct = DllStructCreate($skillbarStructTemplate)
		DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $skillbarStructAddress[0], 'ptr', DllStructGetPtr($skillbarStruct), 'int', DllStructGetSize($skillbarStruct), 'int', '')
		If DllStructGetData($skillbarStruct, 'AgentId') == GetHeroID($heroIndex) Then
			Return $skillbarStruct
		EndIf
	Next
EndFunc
;~ Returns the skill ID of an equipped skill.
Func GetSkillbarSkillID($skillSlot, $heroIndex = 0)
	Return DllStructGetData(GetSkillbar($heroIndex), 'ID' & $skillSlot)
EndFunc


;~ Returns the adrenaline charge of an equipped skill.
Func GetSkillbarSkillAdrenaline($skillSlot, $heroIndex = 0)
	Return DllStructGetData(GetSkillbar($heroIndex), 'AdrenalineA' & $skillSlot)
EndFunc


;~ Returns the recharge time remaining of an equipped skill in milliseconds.
Func GetSkillbarSkillRecharge($skillSlot, $heroIndex = 0)
	Local $timestamp = DllStructGetData(GetSkillbar($heroIndex), 'Recharge' & $skillSlot)
	If $timestamp == 0 Then Return 0
	Return $timestamp - GetSkillTimer()
EndFunc


;~ Returns skill struct.
Func GetSkillByID($skillID)
	Local $skillstructAddress = $skillBaseAddress + (160 * $skillID)
	Local $skillStruct = DllStructCreate($skillStructTemplate)
	DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $skillstructAddress, 'ptr', DllStructGetPtr($skillStruct), 'int', DllStructGetSize($skillStruct), 'int', '')
	Return $skillStruct
EndFunc


;~ Returns current morale.
Func GetMorale($heroIndex = 0)
	Local $agentID = GetHeroID($heroIndex)
	Local $offset[4]
	$offset[0] = 0
	$offset[1] = 0x18
	$offset[2] = 0x2C
	$offset[3] = 0x638
	Local $index = MemoryReadPtr($baseAddressPtr, $offset)
	ReDim $offset[6]
	$offset[0] = 0
	$offset[1] = 0x18
	$offset[2] = 0x2C
	$offset[3] = 0x62C
	$offset[4] = 8 + 0xC * BitAND($agentID, $index[1])
	$offset[5] = 0x18
	Local $result = MemoryReadPtr($baseAddressPtr, $offset)
	Return $result[1] - 100
EndFunc


;~ Returns Attribute struct.
Func GetAttributeInfoByID($attributeID)
	Local $attributeStructAddress = $attributeInfoPtr + (0x14 * $attributeID)
	Local $attributeStruct = DllStructCreate($attributeStructTemplate)
	DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $attributeStructAddress, 'ptr', DllStructGetPtr($attributeStruct), 'int', DllStructGetSize($attributeStruct), 'int', '')
	Return $attributeStruct
EndFunc


Func GetAttributeProfession($attributeID)
	Local $attributeInfo = GetAttributeInfoByID($attributeID)
	Return DllStructGetData($attributeInfo, 'profession_id')
EndFunc


Func GetAttributeNameID($attributeID)
	Local $attributeInfo = GetAttributeInfoByID($attributeID)
	Return DllStructGetData($attributeInfo, 'name_id')
EndFunc


Func GetAttributeIsPvE($attributeID)
	Local $attributeInfo = GetAttributeInfoByID($attributeID)
	Return DllStructGetData($attributeInfo, 'is_pve')
EndFunc


;~ Returns effect struct or array of effects.
Func GetEffect($skillID = 0, $heroIndex = 0)
	Local $effectCount, $effectStructAddress
	Local $resultArray[1] = [0]

	Local $offset[4]
	$offset[0] = 0
	$offset[1] = 0x18
	$offset[2] = 0x2C
	$offset[3] = 0x510
	Local $count = MemoryReadPtr($baseAddressPtr, $offset)
	ReDim $offset[5]
	$offset[3] = 0x508
	Local $buffer
	For $i = 0 To $count[1] - 1
		$offset[4] = 0x24 * $i
		$buffer = MemoryReadPtr($baseAddressPtr, $offset)
		If $buffer[1] == GetHeroID($heroIndex) Then
			$offset[4] = 0x1C + 0x24 * $i
			$effectCount = MemoryReadPtr($baseAddressPtr, $offset)
			ReDim $offset[6]
			$offset[4] = 0x14 + 0x24 * $i
			$offset[5] = 0
			$effectStructAddress = MemoryReadPtr($baseAddressPtr, $offset)

			If $skillID = 0 Then
				ReDim $resultArray[$effectCount[1] + 1]
				$resultArray[0] = $effectCount[1]

				For $i = 0 To $effectCount[1] - 1
                    $resultArray[$i + 1] = DllStructCreate('long SkillId;long AttributeLevel;long EffectId;long AgentId;float Duration;long TimeStamp')
					$effectStructAddress[1] = $effectStructAddress[0] + 24 * $i
					DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $effectStructAddress[1], 'ptr', DllStructGetPtr($resultArray[$i + 1]), 'int', 24, 'int', '')
				Next

				ExitLoop
			Else
				For $i = 0 To $effectCount[1] - 1
					Local $effectStruct = DllStructCreate($effectStructTemplate)
					DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $effectStructAddress[0] + 24 * $i, 'ptr', DllStructGetPtr($effectStruct), 'int', 24, 'int', '')

					If DllStructGetData($effectStruct, 'SkillID') = $skillID Then
						Return $effectStruct
					EndIf
				Next
			EndIf
		EndIf
	Next
	Return $resultArray
EndFunc


;~ Returns time remaining before an effect expires, in milliseconds.
Func GetEffectTimeRemaining($effect, $heroIndex = 0)
	If Not IsDllStruct($effect) Then $effect = GetEffect($effect, $heroIndex)
	If IsArray($effect) Then Return 0
	Return DllStructGetData($effect, 'Duration') * 1000
	; Problem here is that DllStructGetData($effect, 'TimeStamp') returns the timestamp when the effect started
	; But we don't have current timestamp : GetSkillTimer doesn't return it and returns something fixed
	; Return DllStructGetData($effect, 'Duration') * 1000 - (GetSkillTimer() - DllStructGetData($effect, 'TimeStamp'))
EndFunc


;~ Returns the timestamp used for effects and skills (milliseconds).
Func GetSkillTimer()
	Return MemoryRead($skillTimer, 'long')
EndFunc


;~ Returns level of an attribute.
Func GetAttributeByID($attributeID, $withRunes = False, $heroIndex = 0)
	Local $agentID = GetHeroID($heroIndex)
	Local $buffer
	Local $offset[5]
	$offset[0] = 0
	$offset[1] = 0x18
	$offset[2] = 0x2C
	$offset[3] = 0xAC
	For $i = 0 To GetHeroCount()
		$offset[4] = 0x3D8 * $i
		$buffer = MemoryReadPtr($baseAddressPtr, $offset)
		If $buffer[1] == $agentID Then
			$offset[4] = 0x3D8 * $i + 0x14 * $attributeID + $withRunes ? 0xC : 0x8
			$buffer = MemoryReadPtr($baseAddressPtr, $offset)
			Return $buffer[1]
		EndIf
	Next
EndFunc


;~ Returns amount of experience.
Func GetExperience()
	Local $offset[4] = [0, 0x18, 0x2C, 0x740]
	Local $result = MemoryReadPtr($baseAddressPtr, $offset)
	Return $result[1]
EndFunc


;~ Tests if an area has been vanquished.
Func GetAreaVanquished()
	Return GetFoesToKill() = 0
EndFunc


;~ Returns number of foes that have been killed so far.
Func GetFoesKilled()
	Local $offset[4] = [0, 0x18, 0x2C, 0x84C]
	Local $result = MemoryReadPtr($baseAddressPtr, $offset)
	Return $result[1]
EndFunc


;~ Returns number of enemies left to kill for vanquish.
Func GetFoesToKill()
	Local $offset[4] = [0, 0x18, 0x2C, 0x850]
	Local $result = MemoryReadPtr($baseAddressPtr, $offset)
	Return $result[1]
EndFunc


;~ Returns number of agents currently loaded.
Func GetMaxAgents()
	Return MemoryRead($maxAgents)
EndFunc


;~ Returns your agent ID.
Func GetMyID()
	Return MemoryRead($myID)
	;Local $offset[5] = [0, 0x18, 0x2C, 0x680, 0x14]
	;Local $result = MemoryReadPtr($baseAddressPtr, $offset)
	;Return $result[1]
EndFunc


Func GetMyIDTest()
	Local $offset[5] = [0, 0x18, 0x2C, 0x680, 0x14]
	Local $ptr = $baseAddressPtr
	For $i = 0 To UBound($offset) - 2
		$ptr = MemoryRead($ptr + $offset[$i+1], 'ptr')
		If $ptr = 0 Or $ptr > 0x7FFFFFFF Then
			Out('Invalid ptr at level ' & $i & ' → 0x' & Hex($ptr) & @CRLF)
			Return -1
		EndIf
	Next

	Local $myID = MemoryRead($ptr, 'dword')
	ConsoleWrite('Resolved MyID: ' & $myID & ' at 0x' & Hex($ptr) & @CRLF)

	If $myID = 0 Or $myID > 999999 Then Return -1
	Return $myID
EndFunc

;~ Returns current target.
Func GetCurrentTarget()
	Return GetAgentByID(GetCurrentTargetID())
EndFunc


;~ Returns current target ID.
Func GetCurrentTargetID()
	Return MemoryRead($currentTargetAgentId)
EndFunc


;~ Returns current ping.
Func GetPing()
	Return MemoryRead($currentPing)
EndFunc


Func GetMapID()
	Return MemoryRead($mapID)
EndFunc


Func GetInstanceType()
	Local $offset[1] = [0x4]
	Local $result = MemoryReadPtr($instanceInfoPtr, $offset, 'dword')
	Return $result[1]
EndFunc


Func GetAreaInfoByID($mapID = 0)
	If $mapID = 0 Then $mapID = GetMapID()

	Local $areaInfoAddress = $areaInfoPtr + (0x7C * $mapID)
	Local $areaInfoStruct = DllStructCreate($areaInfoStructTemplate)
	DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $areaInfoAddress, 'ptr', DllStructGetPtr($areaInfoStruct), 'int', DllStructGetSize($areaInfoStruct), 'int', '')

	Return $areaInfoStruct
EndFunc


Func GetMapCampaign($mapID = 0)
	Local $mapStruct = GetAreaInfoByID($mapID)
	Return DllStructGetData($mapStruct, 'campaign')
EndFunc


Func GetMapRegion($mapID = 0)
	Local $mapStruct = GetAreaInfoByID($mapID)
	Return DllStructGetData($mapStruct, 'region')
EndFunc


Func GetMapRegionType($mapID = 0)
	Local $mapStruct = GetAreaInfoByID($mapID)
	Return DllStructGetData($mapStruct, 'regiontype')
EndFunc


;~ Returns current load-state.
Func GetMapLoading()
	Return MemoryRead($mapLoading)
EndFunc


;~ Returns if map has been loaded.
Func GetMapIsLoaded()
	Return GetAgentExists(-2)
EndFunc


;~ Returns current district
Func GetDistrict()
	Local $offset[4] = [0, 0x18, 0x44, 0x220]
	Local $result = MemoryReadPtr($baseAddressPtr, $offset)
	Return $result[1]
EndFunc


;~ Internal use for travel functions.
Func GetRegion()
	Return MemoryRead($regionId)
EndFunc


;~ Internal use for travel functions.
Func GetLanguage()
	Return MemoryRead($languageId)
EndFunc


;~ Returns quest struct.
Func GetQuestByID($questID = 0)
	Local $questPtr, $questLogSize, $questID
	Local $offset[4] = [0, 0x18, 0x2C, 0x534]

	$questLogSize = MemoryReadPtr($baseAddressPtr, $offset)

	If $questID = 0 Then
		$offset[1] = 0x18
		$offset[2] = 0x2C
		$offset[3] = 0x528
		$questID = MemoryReadPtr($baseAddressPtr, $offset)
		$questID = $questID[1]
	Else
		$questID = $questID
	EndIf

	Local $offset[5] = [0, 0x18, 0x2C, 0x52C, 0]
	For $i = 0 To $questLogSize[1]
		$offset[4] = 0x34 * $i
		$questPtr = MemoryReadPtr($baseAddressPtr, $offset)
		Local $questStruct = DllStructCreate($questStructTemplate)
		DllCall($kernelHandle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $questPtr[0], 'ptr', DllStructGetPtr($questStruct), 'int', DllStructGetSize($questStruct), 'int', '')
		If DllStructGetData($questStruct, 'ID') = $questID Then Return $questStruct
	Next
EndFunc


;~ Returns your characters name.
Func GetCharname()
	Return MemoryRead($characterName, 'wchar[30]')
EndFunc


;~ Returns if you're logged in.
Func GetLoggedIn()
	Return MemoryRead($isLoggedIn)
EndFunc


;~ Returns language currently being used.
Func GetDisplayLanguage()
	Local $offset[6] = [0, 0x18, 0x18, 0x194, 0x4C, 0x40]
	Local $result = MemoryReadPtr($baseAddressPtr, $offset)
	Return $result[1]
EndFunc


;~ Returns how long the current instance has been active, in milliseconds.
Func GetInstanceUpTime()
	Local $offset[4]
	$offset[0] = 0
	$offset[1] = 0x18
	$offset[2] = 0x8
	$offset[3] = 0x1AC
	Local $timer = MemoryReadPtr($baseAddressPtr, $offset)
	Return $timer[1]
EndFunc


;~ Returns the game client's build number
Func GetBuildNumber()
	Return $buildNumber
EndFunc


Func GetProfPrimaryAttribute($profession)
	Switch $profession
		Case $ID_Warrior
			Return $ID_Strength
		Case $ID_Ranger
			Return $ID_Expertise
		Case $ID_Monk
			Return $ID_Divine_Favor
		Case $ID_Necromancer
			Return $ID_Soul_Reaping
		Case $ID_Mesmer
			Return $ID_Fast_Casting
		Case $ID_Elementalist
			Return $ID_Energy_Storage
		Case $ID_Assassin
			Return $ID_Critical_Strikes
		Case $ID_Ritualist
			Return $ID_Spawning_Power
		Case $ID_Paragon
			Return $ID_Leadership
		Case $ID_Dervish
			Return $ID_Mysticism	
	EndSwitch
EndFunc
#EndRegion Misc
#EndRegion Queries


#Region Other Functions
#Region Misc
;~ Sleep a random amount of time.
Func RndSleep($baseAmount, $randomFactor = null)
	Local $randomAmount
	Select
		Case $randomFactor <> null
			$randomAmount = $baseAmount * $randomFactor
		Case $baseAmount >= 15000
			$randomAmount = $baseAmount * 0.025
		Case $baseAmount >= 6000
			$randomAmount = $baseAmount * 0.05
		Case $baseAmount >= 3000
			$randomAmount = $baseAmount * 0.1
		Case $baseAmount >= 10
			$randomAmount = $baseAmount * 0.2
		Case Else
			$randomAmount = 1
	EndSelect
	Sleep(Random($baseAmount - $randomAmount, $baseAmount + $randomAmount))
EndFunc


;~ Sleep a period of time, plus or minus a tolerance
Func TolSleep($amount = 150, $randomAmount = 50)
	Sleep(Random($amount - $randomAmount, $amount + $randomAmount))
EndFunc


;~ Returns window handle of Guild Wars.
Func GetWindowHandle()
	Return $windowHandle
EndFunc


;~ Returns the distance between two coordinate pairs.
Func ComputeDistance($X1, $Y1, $X2, $Y2)
	Return Sqrt(($X1 - $X2) ^ 2 + ($Y1 - $Y2) ^ 2)
EndFunc


;~ Returns the distance between two agents.
Func GetDistance($agent1 = -1, $agent2 = -2)
	Return Sqrt((GetAgentInfo($agent1, 'X') - GetAgentInfo($agent2, 'X')) ^ 2 + (GetAgentInfo($agent1, 'Y') - GetAgentInfo($agent2, 'Y')) ^ 2)
EndFunc


;~ Return the square of the distance between two agents.
Func GetPseudoDistance($agent1, $agent2)
	Return (GetAgentInfo($agent1, 'X') - GetAgentInfo($agent2, 'X')) ^ 2 + (GetAgentInfo($agent1, 'Y') - GetAgentInfo($agent2, 'Y')) ^ 2
EndFunc


;~ Checks if a point is within a polygon defined by an array
Func GetIsPointInPolygon($areaCoordinates, $X = 0, $Y = 0)
	Local $edges = UBound($areaCoordinates)
	Local $oddNodes = False
	If $edges < 3 Then Return False
	If $X = 0 Then
		Local $me = GetAgentByID(-2)
		$X = GetAgentInfo($me, 'X')
		$Y = GetAgentInfo($me, 'Y')
	EndIf
	$j = $edges - 1
	For $i = 0 To $edges - 1
		If (($areaCoordinates[$i][1] < $Y And $areaCoordinates[$j][1] >= $Y) _
				Or ($areaCoordinates[$j][1] < $Y And $areaCoordinates[$i][1] >= $Y)) _
				And ($areaCoordinates[$i][0] <= $X Or $areaCoordinates[$j][0] <= $X) Then
			If ($areaCoordinates[$i][0] + ($Y - $areaCoordinates[$i][1]) / ($areaCoordinates[$j][1] - $areaCoordinates[$i][1]) * ($areaCoordinates[$j][0] - $areaCoordinates[$i][0]) < $aPosX) Then
				$oddNodes = Not $oddNodes
			EndIf
		EndIf
		$j = $i
	Next
	Return $oddNodes
EndFunc


;~ Internal use for handing -1 and -2 agent IDs.
Func ConvertID($agentID)
	Select
		Case $agentID = -2
			Return GetMyID()
		Case $agentID = -1
			Return GetCurrentTargetID()
		Case IsPtr($agentID) <> 0
			Return MemoryRead($agentID + 0x2C, 'long')
		Case IsDllStruct($agentID) <> 0
			Return DllStructGetData($agentID, 'ID')
		Case Else
			Return $agentID
	EndSelect
EndFunc


Func InviteGuild($characterName)
	If GetAgentExists(-2) Then
		DllStructSetData($inviteGuildStruct, 1, GetValue('CommandPacketSend'))
		DllStructSetData($inviteGuildStruct, 2, 0x4C)
		DllStructSetData($inviteGuildStruct, 3, 0xBC)
		DllStructSetData($inviteGuildStruct, 4, 0x01)
		DllStructSetData($inviteGuildStruct, 5, $characterName)
		DllStructSetData($inviteGuildStruct, 6, 0x02)
		Enqueue(DllStructGetPtr($inviteGuildStruct), DllStructGetSize($inviteGuildStruct))
		Return True
	Else
		Return False
	EndIf
EndFunc


Func InviteGuest($characterName)
	If GetAgentExists(-2) Then
		DllStructSetData($inviteGuildStruct, 1, GetValue('CommandPacketSend'))
		DllStructSetData($inviteGuildStruct, 2, 0x4C)
		DllStructSetData($inviteGuildStruct, 3, 0xBC)
		DllStructSetData($inviteGuildStruct, 4, 0x01)
		DllStructSetData($inviteGuildStruct, 5, $characterName)
		DllStructSetData($inviteGuildStruct, 6, 0x01)
		Enqueue(DllStructGetPtr($inviteGuildStruct), DllStructGetSize($inviteGuildStruct))
		Return True
	Else
		Return False
	EndIf
EndFunc


;~ Internal use only.
Func SendPacket($size, $header, $param1 = 0, $param2 = 0, $param3 = 0, $param4 = 0, $param5 = 0, $param6 = 0, $param7 = 0, $param8 = 0, $param9 = 0, $param10 = 0)
	DllStructSetData($packetStruct, 2, $size)
	DllStructSetData($packetStruct, 3, $header)
	DllStructSetData($packetStruct, 4, $param1)
	DllStructSetData($packetStruct, 5, $param2)
	DllStructSetData($packetStruct, 6, $param3)
	DllStructSetData($packetStruct, 7, $param4)
	DllStructSetData($packetStruct, 8, $param5)
	DllStructSetData($packetStruct, 9, $param6)
	DllStructSetData($packetStruct, 10, $param7)
	DllStructSetData($packetStruct, 11, $param8)
	DllStructSetData($packetStruct, 12, $param9)
	DllStructSetData($packetStruct, 13, $param10)
	Enqueue($packetStructPtr, 52)
	Return True
EndFunc


;~ Internal use only.
Func PerformAction($action, $flag)
	If GetAgentExists(-2) Then
		DllStructSetData($actionStruct, 2, $action)
		DllStructSetData($actionStruct, 3, $flag)
		Enqueue($actionStructPtr, 12)
		Return True
	Else
		Return False
	EndIf
EndFunc


;~ Internal use only.
Func Bin64ToDec($binary)
	Local $result = 0
	For $i = 1 To StringLen($binary)
		If StringMid($binary, $i, 1) == 1 Then $result += BitShift(1, -($i - 1))
	Next
	Return $result
EndFunc


;~ Internal use only.
Func Base64ToBin64($character)
	Select
		Case $character == 'A'
			Return '000000'
		Case $character == 'B'
			Return '100000'
		Case $character == 'C'
			Return '010000'
		Case $character == 'D'
			Return '110000'
		Case $character == 'E'
			Return '001000'
		Case $character == 'F'
			Return '101000'
		Case $character == 'G'
			Return '011000'
		Case $character == 'H'
			Return '111000'
		Case $character == 'I'
			Return '000100'
		Case $character == 'J'
			Return '100100'
		Case $character == 'K'
			Return '010100'
		Case $character == 'L'
			Return '110100'
		Case $character == 'M'
			Return '001100'
		Case $character == 'N'
			Return '101100'
		Case $character == 'O'
			Return '011100'
		Case $character == 'P'
			Return '111100'
		Case $character == 'Q'
			Return '000010'
		Case $character == 'R'
			Return '100010'
		Case $character == 'S'
			Return '010010'
		Case $character == 'T'
			Return '110010'
		Case $character == 'U'
			Return '001010'
		Case $character == 'V'
			Return '101010'
		Case $character == 'W'
			Return '011010'
		Case $character == 'X'
			Return '111010'
		Case $character == 'Y'
			Return '000110'
		Case $character == 'Z'
			Return '100110'
		Case $character == 'a'
			Return '010110'
		Case $character == 'b'
			Return '110110'
		Case $character == 'c'
			Return '001110'
		Case $character == 'd'
			Return '101110'
		Case $character == 'e'
			Return '011110'
		Case $character == 'f'
			Return '111110'
		Case $character == 'g'
			Return '000001'
		Case $character == 'h'
			Return '100001'
		Case $character == 'i'
			Return '010001'
		Case $character == 'j'
			Return '110001'
		Case $character == 'k'
			Return '001001'
		Case $character == 'l'
			Return '101001'
		Case $character == 'm'
			Return '011001'
		Case $character == 'n'
			Return '111001'
		Case $character == 'o'
			Return '000101'
		Case $character == 'p'
			Return '100101'
		Case $character == 'q'
			Return '010101'
		Case $character == 'r'
			Return '110101'
		Case $character == 's'
			Return '001101'
		Case $character == 't'
			Return '101101'
		Case $character == 'u'
			Return '011101'
		Case $character == 'v'
			Return '111101'
		Case $character == 'w'
			Return '000011'
		Case $character == 'x'
			Return '100011'
		Case $character == 'y'
			Return '010011'
		Case $character == 'z'
			Return '110011'
		Case $character == '0'
			Return '001011'
		Case $character == '1'
			Return '101011'
		Case $character == '2'
			Return '011011'
		Case $character == '3'
			Return '111011'
		Case $character == '4'
			Return '000111'
		Case $character == '5'
			Return '100111'
		Case $character == '6'
			Return '010111'
		Case $character == '7'
			Return '110111'
		Case $character == '8'
			Return '001111'
		Case $character == '9'
			Return '101111'
		Case $character == '+'
			Return '011111'
		Case $character == '/'
			Return '111111'
	EndSelect
EndFunc
#EndRegion Misc


#Region Callback
;~ Controls Event System.
Func SetEvent($skillActivate = '', $skillCancel = '', $skillComplete = '', $chatReceive = '', $loadFinished = '')
	If Not $useEventSystem Then Return
	If $skillActivate <> '' Then
		WriteDetour('SkillLogStart', 'SkillLogProc')
	Else
		$asmInjectionString = ''
		_('inc eax')
		_('mov dword[esi+10],eax')
		_('pop esi')
		WriteBinary($asmInjectionString, GetValue('SkillLogStart'))
	EndIf

	If $skillCancel <> '' Then
		WriteDetour('SkillCancelLogStart', 'SkillCancelLogProc')
	Else
		$asmInjectionString = ''
		_('push 0')
		_('push 42')
		_('mov ecx,esi')
		WriteBinary($asmInjectionString, GetValue('SkillCancelLogStart'))
	EndIf

	If $skillComplete <> '' Then
		WriteDetour('SkillCompleteLogStart', 'SkillCompleteLogProc')
	Else
		$asmInjectionString = ''
		_('mov eax,dword[edi+4]')
		_('test eax,eax')
		WriteBinary($asmInjectionString, GetValue('SkillCompleteLogStart'))
	EndIf

	If $chatReceive <> '' Then
		WriteDetour('ChatLogStart', 'ChatLogProc')
	Else
		$asmInjectionString = ''
		_('add edi,E')
		_('cmp eax,B')
		WriteBinary($asmInjectionString, GetValue('ChatLogStart'))
	EndIf

	$skillActivateEvent = $skillActivate
	$skillCancelEvent = $skillCancel
	$skillCompleteEvent = $skillComplete
	$loadFinishedEvent = $loadFinished
EndFunc


Func ProcessChatMessage($chatLogStruct)
	Local $messageType = DllStructGetData($chatLogStruct, 1)
	Local $message = DllStructGetData($chatLogStruct, 'message[512]')
	Local $channel = 'Unknown'
	Local $sender = 'Unknown'

	Switch $messageType
		Case 0
			$channel = 'Alliance'
		Case 3
			$channel = 'All'
		Case 9
			$channel = 'Guild'
		Case 11
			$channel = 'Team'
		Case 12
			$channel = 'Trade'
		Case 10
			If StringLeft($message, 3) == '-> ' Then
				$channel = 'Sent'
			Else
				$channel = 'Global'
				$sender = 'Guild Wars'
			EndIf
		Case 13
			$channel = 'Advisory'
			$sender = 'Guild Wars'
		Case 14
			$channel = 'Whisper'
		Case Else
			$channel = 'Other'
			$sender = 'Other'
	EndSwitch

	If $channel <> 'Global' And $channel <> 'Advisory' And $channel <> 'Other' Then
		$sender = StringMid($message, 6, StringInStr($message, '</a>') - 6)
		$message = StringTrimLeft($message, StringInStr($message, '<quote>') + 6)
	EndIf

	If $channel == 'Sent' Then
		$sender = StringMid($message, 10, StringInStr($message, '</a>') - 10)
		$message = StringTrimLeft($message, StringInStr($message, '<quote>') + 6)
	EndIf
EndFunc
#EndRegion Callback


#Region Modification
Func ModifyMemory()
	$asmInjectionSize = 0
	$asmCodeOffset = 0
	$asmInjectionString = ''
	CreateData()
	CreateMain()
	CreateTraderHook()
	CreateStringLog()
	CreateRenderingMod()
	CreateCommands()
	CreateDialogHook()
	$memoryInterface = MemoryRead(MemoryRead($baseAddress), 'ptr')

	Switch $memoryInterface
		Case 0
			$memoryInterface = DllCall($kernelHandle, 'ptr', 'VirtualAllocEx', 'handle', $processHandle, 'ptr', 0, 'ulong_ptr', $asmInjectionSize, 'dword', 0x1000, 'dword', 64)
			$memoryInterface = $memoryInterface[0]
			MemoryWrite(MemoryRead($baseAddress), $memoryInterface)
			CompleteASMCode()
			WriteBinary($asmInjectionString, $memoryInterface + $asmCodeOffset)
			MemoryWrite(GetValue('QueuePtr'), GetValue('QueueBase'))
		Case Else
			CompleteASMCode()
	EndSwitch
	WriteDetour('MainStart', 'MainProc')
	WriteDetour('TargetLogStart', 'TargetLogProc')
	WriteDetour('TraderHookStart', 'TraderHookProc')
	WriteDetour('LoadFinishedStart', 'LoadFinishedProc')
	WriteDetour('RenderingMod', 'RenderingModProc')
	WriteDetour('DialogLogStart', 'DialogLogProc')
EndFunc


;~ Internal use only.
Func WriteDetour($from, $to)
	WriteBinary('E9' & SwapEndian(Hex(GetLabelInfo($to) - GetLabelInfo($from) - 5)), GetLabelInfo($from))
EndFunc


;~ Internal use only.
Func CreateData()
	_('CallbackHandle/4')
	_('QueueCounter/4')
	_('SkillLogCounter/4')
	_('ChatLogCounter/4')
	_('ChatLogLastMsg/4')
	_('MapIsLoaded/4')
	_('NextStringType/4')
	_('EnsureEnglish/4')
	_('TraderQuoteID/4')
	_('TraderCostID/4')
	_('TraderCostValue/4')
	_('DisableRendering/4')

	_('QueueBase/' & 256 * GetValue('QueueSize'))
	_('TargetLogBase/' & 4 * GetValue('TargetLogSize'))
	_('SkillLogBase/' & 16 * GetValue('SkillLogSize'))
	_('StringLogBase/' & 256 * GetValue('StringLogSize'))
	_('ChatLogBase/' & 512 * GetValue('ChatLogSize'))

	_('LastDialogID/4')

	_('AgentCopyCount/4')
	_('AgentCopyBase/' & 0x1C0 * 256)
EndFunc


;~ Internal use only.
Func CreateMain()
	_('MainProc:')
	_('nop x')
	_('pushad')
	_('mov eax,dword[EnsureEnglish]')
	_('test eax,eax')
	_('jz MainMain')
	_('mov ecx,dword[BasePointer]')
	_('mov ecx,dword[ecx+18]')
	_('mov ecx,dword[ecx+18]')
	_('mov ecx,dword[ecx+194]')
	_('mov al,byte[ecx+4f]')
	_('cmp al,f')
	_('ja MainMain')
	_('mov ecx,dword[ecx+4c]')
	_('mov al,byte[ecx+3f]')
	_('cmp al,f')
	_('ja MainMain')
	_('mov eax,dword[ecx+40]')
	_('test eax,eax')
	_('jz MainMain')

	_('MainMain:')
	_('mov eax,dword[QueueCounter]')
	_('mov ecx,eax')
	_('shl eax,8')
	_('add eax,QueueBase')
	_('mov ebx,dword[eax]')
	_('test ebx,ebx')

	_('jz MainExit')
	_('push ecx')
	_('mov dword[eax],0')
	_('jmp ebx')
	_('CommandReturn:')
	_('pop eax')
	_('inc eax')
	_('cmp eax,QueueSize')
	_('jnz MainSkipReset')
	_('xor eax,eax')
	_('MainSkipReset:')
	_('mov dword[QueueCounter],eax')
	_('MainExit:')
	_('popad')

	_('mov ebp,esp')
	_('fld st(0),dword[ebp+8]')

	_('ljmp MainReturn')
EndFunc


;~ Internal use only.
Func CreateTargetLog()
	_('TargetLogProc:')
	_('cmp ecx,4')
	_('jz TargetLogMain')
	_('cmp ecx,32')
	_('jz TargetLogMain')
	_('cmp ecx,3C')
	_('jz TargetLogMain')
	_('jmp TargetLogExit')

	_('TargetLogMain:')
	_('pushad')
	_('mov ecx,dword[ebp+8]')
	_('test ecx,ecx')
	_('jnz TargetLogStore')
	_('mov ecx,edx')

	_('TargetLogStore:')
	_('lea eax,dword[edx*4+TargetLogBase]')
	_('mov dword[eax],ecx')
	_('popad')

	_('TargetLogExit:')
	_('push ebx')
	_('push esi')
	_('push edi')
	_('mov edi,edx')
	_('ljmp TargetLogReturn')
EndFunc


;~ Internal use only.
Func CreateSkillLog()
	_('SkillLogProc:')
	_('pushad')

	_('mov eax,dword[SkillLogCounter]')
	_('push eax')
	_('shl eax,4')
	_('add eax,SkillLogBase')

	_('mov ecx,dword[edi]')
	_('mov dword[eax],ecx')
	_('mov ecx,dword[ecx*4+TargetLogBase]')
	_('mov dword[eax+4],ecx')
	_('mov ecx,dword[edi+4]')
	_('mov dword[eax+8],ecx')
	_('mov ecx,dword[edi+8]')
	_('mov dword[eax+c],ecx')

	_('push 1')
	_('push eax')
	_('push CallbackEvent')
	_('push dword[CallbackHandle]')
	_('call dword[PostMessage]')

	_('pop eax')
	_('inc eax')
	_('cmp eax,SkillLogSize')
	_('jnz SkillLogSkipReset')
	_('xor eax,eax')
	_('SkillLogSkipReset:')
	_('mov dword[SkillLogCounter],eax')

	_('popad')
	_('inc eax')
	_('mov dword[esi+10],eax')
	_('pop esi')
	_('ljmp SkillLogReturn')
EndFunc


;~ Internal use only.
Func CreateSkillCancelLog()
	_('SkillCancelLogProc:')
	_('pushad')

	_('mov eax,dword[SkillLogCounter]')
	_('push eax')
	_('shl eax,4')
	_('add eax,SkillLogBase')

	_('mov ecx,dword[edi]')
	_('mov dword[eax],ecx')
	_('mov ecx,dword[ecx*4+TargetLogBase]')
	_('mov dword[eax+4],ecx')
	_('mov ecx,dword[edi+4]')
	_('mov dword[eax+8],ecx')

	_('push 2')
	_('push eax')
	_('push CallbackEvent')
	_('push dword[CallbackHandle]')
	_('call dword[PostMessage]')

	_('pop eax')
	_('inc eax')
	_('cmp eax,SkillLogSize')
	_('jnz SkillCancelLogSkipReset')
	_('xor eax,eax')
	_('SkillCancelLogSkipReset:')
	_('mov dword[SkillLogCounter],eax')

	_('popad')
	_('push 0')
	_('push 48')
	_('mov ecx,esi')
	_('ljmp SkillCancelLogReturn')
EndFunc


;~ Internal use only.
Func CreateSkillCompleteLog()
	_('SkillCompleteLogProc:')
	_('pushad')

	_('mov eax,dword[SkillLogCounter]')
	_('push eax')
	_('shl eax,4')
	_('add eax,SkillLogBase')

	_('mov ecx,dword[edi]')
	_('mov dword[eax],ecx')
	_('mov ecx,dword[ecx*4+TargetLogBase]')
	_('mov dword[eax+4],ecx')
	_('mov ecx,dword[edi+4]')
	_('mov dword[eax+8],ecx')

	_('push 3')
	_('push eax')
	_('push CallbackEvent')
	_('push dword[CallbackHandle]')
	_('call dword[PostMessage]')

	_('pop eax')
	_('inc eax')
	_('cmp eax,SkillLogSize')
	_('jnz SkillCompleteLogSkipReset')
	_('xor eax,eax')
	_('SkillCompleteLogSkipReset:')
	_('mov dword[SkillLogCounter],eax')

	_('popad')
	_('mov eax,dword[edi+4]')
	_('test eax,eax')
	_('ljmp SkillCompleteLogReturn')
EndFunc


;~ Internal use only.
Func CreateChatLog()
	_('ChatLogProc:')

	_('pushad')
	_('mov ecx,dword[esp+1F4]')
	_('mov ebx,eax')
	_('mov eax,dword[ChatLogCounter]')
	_('push eax')
	_('shl eax,9')
	_('add eax,ChatLogBase')
	_('mov dword[eax],ebx')

	_('mov edi,eax')
	_('add eax,4')
	_('xor ebx,ebx')

	_('ChatLogCopyLoop:')
	_('mov dx,word[ecx]')
	_('mov word[eax],dx')
	_('add ecx,2')
	_('add eax,2')
	_('inc ebx')
	_('cmp ebx,FF')
	_('jz ChatLogCopyExit')
	_('test dx,dx')
	_('jnz ChatLogCopyLoop')

	_('ChatLogCopyExit:')
	_('push 4')
	_('push edi')
	_('push CallbackEvent')
	_('push dword[CallbackHandle]')
	_('call dword[PostMessage]')

	_('pop eax')
	_('inc eax')
	_('cmp eax,ChatLogSize')
	_('jnz ChatLogSkipReset')
	_('xor eax,eax')
	_('ChatLogSkipReset:')
	_('mov dword[ChatLogCounter],eax')
	_('popad')

	_('ChatLogExit:')
	_('add edi,E')
	_('cmp eax,B')
	_('ljmp ChatLogReturn')
EndFunc


;~ Internal use only.
Func CreateTraderHook()
	_('TraderHookProc:')
	_('push eax')
	_('mov eax,dword[ebx+28] -> 8b 43 28')
	_('mov eax,[eax] -> 8b 00')
	_('mov dword[TraderCostID],eax')
	_('mov eax,dword[ebx+28] -> 8b 43 28')
	_('mov eax,[eax+4] -> 8b 40 04')
	_('mov dword[TraderCostValue],eax')
	_('pop eax')
	_('mov ebx,dword[ebp+C] -> 8B 5D 0C')
	_('mov esi,eax')
	_('push eax')
	_('mov eax,dword[TraderQuoteID]')
	_('inc eax')
	_('cmp eax,200')
	_('jnz TraderSkipReset')
	_('xor eax,eax')
	_('TraderSkipReset:')
	_('mov dword[TraderQuoteID],eax')
	_('pop eax')
	_('ljmp TraderHookReturn')
EndFunc


;~ Internal use only.
Func CreateDialogHook()
	_('DialogLogProc:')
	_('push ecx')
	_('mov ecx,esp')
	_('add ecx,C')
	_('mov ecx,dword[ecx]')
	_('mov dword[LastDialogID],ecx')
	_('pop ecx')
	_('mov ebp,esp')
	_('sub esp,8')
	_('ljmp DialogLogReturn')
EndFunc


;~ Internal use only.
Func CreateLoadFinished()
	_('LoadFinishedProc:')
	_('pushad')

	_('mov eax,1')
	_('mov dword[MapIsLoaded],eax')

	_('xor ebx,ebx')
	_('mov eax,StringLogBase')
	_('LoadClearStringsLoop:')
	_('mov dword[eax],0')
	_('inc ebx')
	_('add eax,100')
	_('cmp ebx,StringLogSize')
	_('jnz LoadClearStringsLoop')

	_('xor ebx,ebx')
	_('mov eax,TargetLogBase')
	_('LoadClearTargetsLoop:')
	_('mov dword[eax],0')
	_('inc ebx')
	_('add eax,4')
	_('cmp ebx,TargetLogSize')
	_('jnz LoadClearTargetsLoop')

	_('push 5')
	_('push 0')
	_('push CallbackEvent')
	_('push dword[CallbackHandle]')
	_('call dword[PostMessage]')

	_('popad')
	_('mov edx,dword[esi+1C]')
	_('mov ecx,edi')
	_('ljmp LoadFinishedReturn')
EndFunc


;~ Internal use only.
Func CreateStringLog()
	_('StringLogProc:')
	_('pushad')
	_('mov eax,dword[NextStringType]')
	_('test eax,eax')
	_('jz StringLogExit')

	_('cmp eax,1')
	_('jnz StringLogFilter2')
	_('mov eax,dword[ebp+37c]')
	_('jmp StringLogRangeCheck')

	_('StringLogFilter2:')
	_('cmp eax,2')
	_('jnz StringLogExit')
	_('mov eax,dword[ebp+338]')

	_('StringLogRangeCheck:')
	_('mov dword[NextStringType],0')
	_('cmp eax,0')
	_('jbe StringLogExit')
	_('cmp eax,StringLogSize')
	_('jae StringLogExit')

	_('shl eax,8')
	_('add eax,StringLogBase')

	_('xor ebx,ebx')
	_('StringLogCopyLoop:')
	_('mov dx,word[ecx]')
	_('mov word[eax],dx')
	_('add ecx,2')
	_('add eax,2')
	_('inc ebx')
	_('cmp ebx,80')
	_('jz StringLogExit')
	_('test dx,dx')
	_('jnz StringLogCopyLoop')

	_('StringLogExit:')
	_('popad')
	_('mov esp,ebp')
	_('pop ebp')
	_('retn 10')
EndFunc


;~ Internal use only.
Func CreateStringFilter1()
	_('StringFilter1Proc:')
	_('mov dword[NextStringType],1')

	_('push ebp')
	_('mov ebp,esp')
	_('push ecx')
	_('push esi')
	_('ljmp StringFilter1Return')
EndFunc


;~ Internal use only.
Func CreateStringFilter2()
	_('StringFilter2Proc:')
	_('mov dword[NextStringType],2')

	_('push ebp')
	_('mov ebp,esp')
	_('push ecx')
	_('push esi')
	_('ljmp StringFilter2Return')
EndFunc


;~ Internal use only.
Func CreateRenderingMod()
	_('RenderingModProc:')
	_('add esp,4')
	_('cmp dword[DisableRendering],1')
	_('ljmp RenderingModReturn')
EndFunc


;~ Internal use only.
Func CreateCommands()
	_('CommandUseSkill:')
	_('mov ecx,dword[eax+C]')
	_('push ecx')
	_('mov ebx,dword[eax+8]')
	_('push ebx')
	_('mov edx,dword[eax+4]')
	_('dec edx')
	_('push edx')
	_('mov eax,dword[MyID]')
	_('push eax')
	_('call UseSkillFunction')
	_('pop eax')
	_('pop edx')
	_('pop ebx')
	_('pop ecx')
	_('ljmp CommandReturn')

	_('CommandMove:')
	_('lea eax,dword[eax+4]')
	_('push eax')
	_('call MoveFunction')
	_('pop eax')
	_('ljmp CommandReturn')

	_('CommandChangeTarget:')
	_('xor edx,edx')
	_('push edx')
	_('mov eax,dword[eax+4]')
	_('push eax')
	_('call ChangeTargetFunction')
	_('pop eax')
	_('pop edx')
	_('ljmp CommandReturn')

	_('CommandPacketSend:')
	_('lea edx,dword[eax+8]')
	_('push edx')
	_('mov ebx,dword[eax+4]')
	_('push ebx')
	_('mov eax,dword[PacketLocation]')
	_('push eax')
	_('call PacketSendFunction')
	_('pop eax')
	_('pop ebx')
	_('pop edx')
	_('ljmp CommandReturn')

	_('CommandChangeStatus:')
	_('mov eax,dword[eax+4]')
	_('push eax')
	_('call ChangeStatusFunction')
	_('pop eax')
	_('ljmp CommandReturn')

	_('CommandWriteChat:')
	_('push 0')
	_('add eax,4')
	_('push eax')
	_('call WriteChatFunction')
	_('add esp,8')
	_('ljmp CommandReturn')

	_('CommandSellItem:')
	_('mov esi,eax')
	_('add esi,C')
	_('push 0')
	_('push 0')
	_('push 0')
	_('push dword[eax+4]')
	_('push 0')
	_('add eax,8')
	_('push eax')
	_('push 1')
	_('push 0')
	_('push B')
	_('call TransactionFunction')
	_('add esp,24')
	_('ljmp CommandReturn')

	_('CommandBuyItem:')
	_('mov esi,eax')
	_('add esi,10')
	_('mov ecx,eax')
	_('add ecx,4')
	_('push ecx')
	_('mov edx,eax')
	_('add edx,8')
	_('push edx')
	_('push 1')
	_('push 0')
	_('push 0')
	_('push 0')
	_('push 0')
	_('mov eax,dword[eax+C]')
	_('push eax')
	_('push 1')
	_('call TransactionFunction')
	_('add esp,24')
	_('ljmp CommandReturn')

	_('CommandCraftItemEx:')
	_('add eax,4')
	_('push eax')
	_('add eax,4')
	_('push eax')
	_('push 1')
	_('push 0')
	_('push 0')
	_('mov ecx,dword[TradeID]')
	_('mov ecx,dword[ecx]')
	_('mov edx,dword[eax+4]')
	_('lea ecx,dword[ebx+ecx*4]')
	_('push ecx')
	_('push 1')
	_('push dword[eax+8]')
	_('push dword[eax+C]')
	_('call TraderFunction')
	_('add esp,24')
	_('mov dword[TraderCostID],0')
	_('ljmp CommandReturn')

	_('CommandAction:')
	_('mov ecx,dword[ActionBase]')
	_('mov ecx,dword[ecx+c]')
	_('add ecx,A0')
	_('push 0')
	_('add eax,4')
	_('push eax')
	_('push dword[eax+4]')
	_('mov edx,0')
	_('call ActionFunction')
	_('ljmp CommandReturn')

	_('CommandUseHeroSkill:')
	_('mov ecx,dword[eax+8]')
	_('push ecx')
	_('mov ecx,dword[eax+c]')
	_('push ecx')
	_('mov ecx,dword[eax+4]')
	_('push ecx')
	_('call UseHeroSkillFunction')
	_('add esp,C')
	_('ljmp CommandReturn')
	
;~	_('CommandToggleLanguage:')

	_('CommandSendChat:')
	_('lea edx,dword[eax+4]')
	_('push edx')
	_('mov ebx,11c')
	_('push ebx')
	_('mov eax,dword[PacketLocation]')
	_('push eax')
	_('call PacketSendFunction')
	_('pop eax')
	_('pop ebx')
	_('pop edx')
	_('ljmp CommandReturn')

	_('CommandRequestQuote:')
	_('mov dword[TraderCostID],0')
	_('mov dword[TraderCostValue],0')
	_('mov esi,eax')
	_('add esi,4')
	_('push esi')
	_('push 1')
	_('push 0')
	_('push 0')
	_('push 0')
	_('push 0')
	_('push 0')
	_('push C')
	_('mov ecx,0')
	_('mov edx,2')
	_('call RequestQuoteFunction')
	_('add esp,20')
	_('ljmp CommandReturn')

	_('CommandRequestQuoteSell:')
	_('mov dword[TraderCostID],0')
	_('mov dword[TraderCostValue],0')
	_('push 0')
	_('push 0')
	_('push 0')
	_('add eax,4')
	_('push eax')
	_('push 1')
	_('push 0')
	_('push 0')
	_('push D')
	_('xor edx,edx')
	_('call RequestQuoteFunction')
	_('add esp,20')
	_('ljmp CommandReturn')

	_('CommandTraderBuy:')
	_('push 0')
	_('push TraderCostID')
	_('push 1')
	_('push 0')
	_('push 0')
	_('push 0')
	_('push 0')
	_('mov edx,dword[TraderCostValue]')
	_('push edx')
	_('push C')
	_('mov ecx,C')
	_('call TraderFunction')
	_('add esp,24')
	_('mov dword[TraderCostID],0')
	_('mov dword[TraderCostValue],0')
	_('ljmp CommandReturn')

	_('CommandTraderSell:')
	_('push 0')
	_('push 0')
	_('push 0')
	_('push dword[TraderCostValue]')
	_('push 0')
	_('push TraderCostID')
	_('push 1')
	_('push 0')
	_('push D')
	_('mov ecx,d')
	_('xor edx,edx')
	_('call TransactionFunction')
	_('add esp,24')
	_('mov dword[TraderCostID],0')
	_('mov dword[TraderCostValue],0')
	_('ljmp CommandReturn')

	_('CommandSalvage:')
	_('push eax')
	_('push ecx')
	_('push ebx')
	_('mov ebx,SalvageGlobal')
	_('mov ecx,dword[eax+4]')
	_('mov dword[ebx],ecx')
	_('add ebx,4')
	_('mov ecx,dword[eax+8]')
	_('mov dword[ebx],ecx')
	_('mov ebx,dword[eax+4]')
	_('push ebx')
	_('mov ebx,dword[eax+8]')
	_('push ebx')
	_('mov ebx,dword[eax+c]')
	_('push ebx')
	_('call SalvageFunction')
	_('add esp,C')
	_('pop ebx')
	_('pop ecx')
	_('pop eax')
	_('ljmp CommandReturn')

	_('CommandCraftItemEx2:')
	_('add eax,4')
	_('push eax')
	_('add eax,4')
	_('push eax')
	_('push 1')
	_('push 0')
	_('push 0')
	_('mov ecx,dword[TradeID]')
	_('mov ecx,dword[ecx]')
	_('mov edx,dword[eax+8]')
	_('lea ecx,dword[ebx+ecx*4]')
	_('mov ecx,dword[ecx]')
	_('mov [eax+8],ecx')
	_('mov ecx,dword[TradeID]')
	_('mov ecx,dword[ecx]')
	_('mov ecx,dword[ecx+0xF4]')
	_('lea ecx,dword[ecx+ecx*2]')
	_('lea ecx,dword[ebx+ecx*4]')
	_('mov ecx,dword[ecx]')
	_('mov [eax+C],ecx')
	_('mov ecx,eax')
	_('add ecx,8')
	_('push ecx')
	_('push 2')
	_('push dword[eax+4]')
	_('push 3')
	_('call TransactionFunction')
	_('add esp,24')
	_('mov dword[TraderCostID],0')
	_('ljmp CommandReturn')
	_('CommandIncreaseAttribute:')
	_('mov edx,dword[eax+4]')
	_('push edx')
	_('mov ecx,dword[eax+8]')
	_('push ecx')
	_('call IncreaseAttributeFunction')
	_('pop ecx')
	_('pop edx')
	_('ljmp CommandReturn')

	_('CommandDecreaseAttribute:')
	_('mov edx,dword[eax+4]')
	_('push edx')
	_('mov ecx,dword[eax+8]')
	_('push ecx')
	_('call DecreaseAttributeFunction')
	_('pop ecx')
	_('pop edx')
	_('ljmp CommandReturn')

	_('CommandMakeAgentArray:')
	_('mov eax,dword[eax+4]')
	_('xor ebx,ebx')
	_('xor edx,edx')
	_('mov edi,AgentCopyBase')

	_('AgentCopyLoopStart:')
	_('inc ebx')
	_('cmp ebx,dword[MaxAgents]')
	_('jge AgentCopyLoopExit')

	_('mov esi,dword[AgentBase]')
	_('lea esi,dword[esi+ebx*4]')
	_('mov esi,dword[esi]')
	_('test esi,esi')
	_('jz AgentCopyLoopStart')

	_('cmp eax,0')
	_('jz CopyAgent')
	_('cmp eax,dword[esi+9C]')
	_('jnz AgentCopyLoopStart')

	_('CopyAgent:')
	_('mov ecx,1C0')
	_('clc')
	_('repe movsb')
	_('inc edx')
	_('jmp AgentCopyLoopStart')

	_('AgentCopyLoopExit:')
	_('mov dword[AgentCopyCount],edx')
	_('ljmp CommandReturn')

	_('CommandSendChatPartySearch:')
	_('lea edx,dword[eax+4]')
	_('push edx')
	_('mov ebx,4C')
	_('push ebx')
	_('mov eax,dword[PacketLocation]')
	_('push eax')
	_('call PacketSendFunction')
	_('pop eax')
	_('pop ebx')
	_('pop edx')
	_('ljmp CommandReturn')
EndFunc
#EndRegion Modification


#Region Online Status
;~ Change online status. 0 = Offline, 1 = Online, 2 = Do not disturb, 3 = Away
Func SetPlayerStatus($status)
	If (($status >= 0 And $status <= 3) And (GetPlayerStatus() <> $status)) Then
		DllStructSetData($changeStatusStruct, 2, $status)

		Enqueue($changeStatusStructPtr, 8)
		Return True
	Else
		Return False
	EndIf
EndFunc


Func GetPlayerStatus()
	Return MemoryRead($currentStatus)
EndFunc
#EndRegion Online Status


#Region Assembler
;~ Internal use only.
Func _($asm)
	; quick and dirty x86assembler unit:
	; relative values stringregexp
	; static values hardcoded
	Local $buffer
	Local $opCode
	Select
		Case StringInStr($asm, ' -> ')
			Local $split = StringSplit($asm, ' -> ', 1)
			$opCode = StringReplace($split[2], ' ', '')
			$asmInjectionSize += 0.5 * StringLen($opCode)
			$asmInjectionString &= $opCode
		Case StringLeft($asm, 3) = 'jb '
			$asmInjectionSize += 2
			$asmInjectionString &= '72(' & StringRight($asm, StringLen($asm) - 3) & ')'
		Case StringLeft($asm, 3) = 'je '
			$asmInjectionSize += 2
			$asmInjectionString &= '74(' & StringRight($asm, StringLen($asm) - 3) & ')'
		Case StringRegExp($asm, 'cmp ebx,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asmInjectionSize += 6
			$asmInjectionString &= '81FB[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'cmp edx,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asmInjectionSize += 6
			$asmInjectionString &= '81FA[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRight($asm, 1) = ':'
			SetValue('Label_' & StringLeft($asm, StringLen($asm) - 1), $asmInjectionSize)
		Case StringInStr($asm, '/') > 0
			SetValue('Label_' & StringLeft($asm, StringInStr($asm, '/') - 1), $asmInjectionSize)
			Local $offset = StringRight($asm, StringLen($asm) - StringInStr($asm, '/'))
			$asmInjectionSize += $offset
			$asmCodeOffset += $offset
		Case StringLeft($asm, 5) = 'nop x'
			$buffer = Int(Number(StringTrimLeft($asm, 5)))
			$asmInjectionSize += $buffer
			For $i = 1 To $buffer
				$asmInjectionString &= '90'
			Next
		Case StringLeft($asm, 5) = 'ljmp '
			$asmInjectionSize += 5
			$asmInjectionString &= 'E9{' & StringRight($asm, StringLen($asm) - 5) & '}'
		Case StringLeft($asm, 5) = 'ljne '
			$asmInjectionSize += 6
			$asmInjectionString &= '0F85{' & StringRight($asm, StringLen($asm) - 5) & '}'
		Case StringLeft($asm, 4) = 'jmp ' And StringLen($asm) > 7
			$asmInjectionSize += 2
			$asmInjectionString &= 'EB(' & StringRight($asm, StringLen($asm) - 4) & ')'
		Case StringLeft($asm, 4) = 'jae '
			$asmInjectionSize += 2
			$asmInjectionString &= '73(' & StringRight($asm, StringLen($asm) - 4) & ')'
		Case StringLeft($asm, 3) = 'jz '
			$asmInjectionSize += 2
			$asmInjectionString &= '74(' & StringRight($asm, StringLen($asm) - 3) & ')'
		Case StringLeft($asm, 4) = 'jnz '
			$asmInjectionSize += 2
			$asmInjectionString &= '75(' & StringRight($asm, StringLen($asm) - 4) & ')'
		Case StringLeft($asm, 4) = 'jbe '
			$asmInjectionSize += 2
			$asmInjectionString &= '76(' & StringRight($asm, StringLen($asm) - 4) & ')'
		Case StringLeft($asm, 3) = 'ja '
			$asmInjectionSize += 2
			$asmInjectionString &= '77(' & StringRight($asm, StringLen($asm) - 3) & ')'
		Case StringLeft($asm, 3) = 'jl '
			$asmInjectionSize += 2
			$asmInjectionString &= '7C(' & StringRight($asm, StringLen($asm) - 3) & ')'
		Case StringLeft($asm, 4) = 'jge '
			$asmInjectionSize += 2
			$asmInjectionString &= '7D(' & StringRight($asm, StringLen($asm) - 4) & ')'
		Case StringLeft($asm, 4) = 'jle '
			$asmInjectionSize += 2
			$asmInjectionString &= '7E(' & StringRight($asm, StringLen($asm) - 4) & ')'
		Case StringRegExp($asm, 'mov eax,dword[[][a-z,A-Z]{4,}[]]')
			$asmInjectionSize += 5
			$asmInjectionString &= 'A1[' & StringMid($asm, 15, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'mov ebx,dword[[][a-z,A-Z]{4,}[]]')
			$asmInjectionSize += 6
			$asmInjectionString &= '8B1D[' & StringMid($asm, 15, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'mov ecx,dword[[][a-z,A-Z]{4,}[]]')
			$asmInjectionSize += 6
			$asmInjectionString &= '8B0D[' & StringMid($asm, 15, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'mov edx,dword[[][a-z,A-Z]{4,}[]]')
			$asmInjectionSize += 6
			$asmInjectionString &= '8B15[' & StringMid($asm, 15, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'mov esi,dword[[][a-z,A-Z]{4,}[]]')
			$asmInjectionSize += 6
			$asmInjectionString &= '8B35[' & StringMid($asm, 15, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'mov edi,dword[[][a-z,A-Z]{4,}[]]')
			$asmInjectionSize += 6
			$asmInjectionString &= '8B3D[' & StringMid($asm, 15, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'cmp ebx,dword\[[a-z,A-Z]{4,}\]')
			$asmInjectionSize += 6
			$asmInjectionString &= '3B1D[' & StringMid($asm, 15, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'lea eax,dword[[]ecx[*]8[+][a-z,A-Z]{4,}[]]')
			$asmInjectionSize += 7
			$asmInjectionString &= '8D04CD[' & StringMid($asm, 21, StringLen($asm) - 21) & ']'
		Case StringRegExp($asm, 'lea edi,dword\[edx\+[a-z,A-Z]{4,}\]')
			$asmInjectionSize += 7
			$asmInjectionString &= '8D3C15[' & StringMid($asm, 19, StringLen($asm) - 19) & ']'
		Case StringRegExp($asm, 'cmp dword[[][a-z,A-Z]{4,}[]],[-[:xdigit:]]')
			$buffer = StringInStr($asm, ',')
			$buffer = ASMNumber(StringMid($asm, $buffer + 1), True)
			If @extended Then
				$asmInjectionSize += 7
				$asmInjectionString &= '833D[' & StringMid($asm, 11, StringInStr($asm, ',') - 12) & ']' & $buffer
			Else
				$asmInjectionSize += 10
				$asmInjectionString &= '813D[' & StringMid($asm, 11, StringInStr($asm, ',') - 12) & ']' & $buffer
			EndIf
		Case StringRegExp($asm, 'cmp ecx,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asmInjectionSize += 6
			$asmInjectionString &= '81F9[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'cmp ebx,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asmInjectionSize += 6
			$asmInjectionString &= '81FB[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'cmp eax,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asmInjectionSize += 5
			$asmInjectionString &= '3D[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'add eax,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asmInjectionSize += 5
			$asmInjectionString &= '05[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'mov eax,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asmInjectionSize += 5
			$asmInjectionString &= 'B8[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'mov ebx,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asmInjectionSize += 5
			$asmInjectionString &= 'BB[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'mov ecx,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asmInjectionSize += 5
			$asmInjectionString &= 'B9[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'mov esi,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asmInjectionSize += 5
			$asmInjectionString &= 'BE[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'mov edi,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asmInjectionSize += 5
			$asmInjectionString &= 'BF[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'mov edx,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asmInjectionSize += 5
			$asmInjectionString &= 'BA[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'mov dword[[][a-z,A-Z]{4,}[]],ecx')
			$asmInjectionSize += 6
			$asmInjectionString &= '890D[' & StringMid($asm, 11, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'fstp dword[[][a-z,A-Z]{4,}[]]')
			$asmInjectionSize += 6
			$asmInjectionString &= 'D91D[' & StringMid($asm, 12, StringLen($asm) - 12) & ']'
		Case StringRegExp($asm, 'mov dword[[][a-z,A-Z]{4,}[]],edx')
			$asmInjectionSize += 6
			$asmInjectionString &= '8915[' & StringMid($asm, 11, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'mov dword[[][a-z,A-Z]{4,}[]],eax')
			$asmInjectionSize += 5
			$asmInjectionString &= 'A3[' & StringMid($asm, 11, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'lea eax,dword[[]edx[*]4[+][a-z,A-Z]{4,}[]]')
			$asmInjectionSize += 7
			$asmInjectionString &= '8D0495[' & StringMid($asm, 21, StringLen($asm) - 21) & ']'
		Case StringRegExp($asm, 'mov eax,dword[[]ecx[*]4[+][a-z,A-Z]{4,}[]]')
			$asmInjectionSize += 7
			$asmInjectionString &= '8B048D[' & StringMid($asm, 21, StringLen($asm) - 21) & ']'
		Case StringRegExp($asm, 'mov ecx,dword[[]ecx[*]4[+][a-z,A-Z]{4,}[]]')
			$asmInjectionSize += 7
			$asmInjectionString &= '8B0C8D[' & StringMid($asm, 21, StringLen($asm) - 21) & ']'
		Case StringRegExp($asm, 'push dword[[][a-z,A-Z]{4,}[]]')
			$asmInjectionSize += 6
			$asmInjectionString &= 'FF35[' & StringMid($asm, 12, StringLen($asm) - 12) & ']'
		Case StringRegExp($asm, 'push [a-z,A-Z]{4,}\z')
			$asmInjectionSize += 5
			$asmInjectionString &= '68[' & StringMid($asm, 6, StringLen($asm) - 5) & ']'
		Case StringRegExp($asm, 'call dword[[][a-z,A-Z]{4,}[]]')
			$asmInjectionSize += 6
			$asmInjectionString &= 'FF15[' & StringMid($asm, 12, StringLen($asm) - 12) & ']'
		Case StringLeft($asm, 5) = 'call ' And StringLen($asm) > 8
			$asmInjectionSize += 5
			$asmInjectionString &= 'E8{' & StringMid($asm, 6, StringLen($asm) - 5) & '}'
		Case StringRegExp($asm, 'mov dword\[[a-z,A-Z]{4,}\],[-[:xdigit:]]{1,8}\z')
			$buffer = StringInStr($asm, ',')
			$asmInjectionSize += 10
			$asmInjectionString &= 'C705[' & StringMid($asm, 11, $buffer - 12) & ']' & ASMNumber(StringMid($asm, $buffer + 1))
		Case StringRegExp($asm, 'push [-[:xdigit:]]{1,8}\z')
			$buffer = ASMNumber(StringMid($asm, 6), True)
			If @extended Then
				$asmInjectionSize += 2
				$asmInjectionString &= '6A' & $buffer
			Else
				$asmInjectionSize += 5
				$asmInjectionString &= '68' & $buffer
			EndIf
		Case StringRegExp($asm, 'mov eax,[-[:xdigit:]]{1,8}\z')
			$asmInjectionSize += 5
			$asmInjectionString &= 'B8' & ASMNumber(StringMid($asm, 9))
		Case StringRegExp($asm, 'mov ebx,[-[:xdigit:]]{1,8}\z')
			$asmInjectionSize += 5
			$asmInjectionString &= 'BB' & ASMNumber(StringMid($asm, 9))
		Case StringRegExp($asm, 'mov ecx,[-[:xdigit:]]{1,8}\z')
			$asmInjectionSize += 5
			$asmInjectionString &= 'B9' & ASMNumber(StringMid($asm, 9))
		Case StringRegExp($asm, 'mov edx,[-[:xdigit:]]{1,8}\z')
			$asmInjectionSize += 5
			$asmInjectionString &= 'BA' & ASMNumber(StringMid($asm, 9))
		Case StringRegExp($asm, 'add eax,[-[:xdigit:]]{1,8}\z')
			$buffer = ASMNumber(StringMid($asm, 9), True)
			If @extended Then
				$asmInjectionSize += 3
				$asmInjectionString &= '83C0' & $buffer
			Else
				$asmInjectionSize += 5
				$asmInjectionString &= '05' & $buffer
			EndIf
		Case StringRegExp($asm, 'add ebx,[-[:xdigit:]]{1,8}\z')
			$buffer = ASMNumber(StringMid($asm, 9), True)
			If @extended Then
				$asmInjectionSize += 3
				$asmInjectionString &= '83C3' & $buffer
			Else
				$asmInjectionSize += 6
				$asmInjectionString &= '81C3' & $buffer
			EndIf
		Case StringRegExp($asm, 'add ecx,[-[:xdigit:]]{1,8}\z')
			$buffer = ASMNumber(StringMid($asm, 9), True)
			If @extended Then
				$asmInjectionSize += 3
				$asmInjectionString &= '83C1' & $buffer
			Else
				$asmInjectionSize += 6
				$asmInjectionString &= '81C1' & $buffer
			EndIf
		Case StringRegExp($asm, 'add edx,[-[:xdigit:]]{1,8}\z')
			$buffer = ASMNumber(StringMid($asm, 9), True)
			If @extended Then
				$asmInjectionSize += 3
				$asmInjectionString &= '83C2' & $buffer
			Else
				$asmInjectionSize += 6
				$asmInjectionString &= '81C2' & $buffer
			EndIf
		Case StringRegExp($asm, 'add edi,[-[:xdigit:]]{1,8}\z')
			$buffer = ASMNumber(StringMid($asm, 9), True)
			If @extended Then
				$asmInjectionSize += 3
				$asmInjectionString &= '83C7' & $buffer
			Else
				$asmInjectionSize += 6
				$asmInjectionString &= '81C7' & $buffer
			EndIf
		Case StringRegExp($asm, 'add esi,[-[:xdigit:]]{1,8}\z')
			$buffer = ASMNumber(StringMid($asm, 9), True)
			If @extended Then
				$asmInjectionSize += 3
				$asmInjectionString &= '83C6' & $buffer
			Else
				$asmInjectionSize += 6
				$asmInjectionString &= '81C6' & $buffer
			EndIf
		Case StringRegExp($asm, 'add esp,[-[:xdigit:]]{1,8}\z')
			$buffer = ASMNumber(StringMid($asm, 9), True)
			If @extended Then
				$asmInjectionSize += 3
				$asmInjectionString &= '83C4' & $buffer
			Else
				$asmInjectionSize += 6
				$asmInjectionString &= '81C4' & $buffer
			EndIf
		Case StringRegExp($asm, 'cmp ebx,[-[:xdigit:]]{1,8}\z')
			$buffer = ASMNumber(StringMid($asm, 9), True)
			If @extended Then
				$asmInjectionSize += 3
				$asmInjectionString &= '83FB' & $buffer
			Else
				$asmInjectionSize += 6
				$asmInjectionString &= '81FB' & $buffer
			EndIf
		Case StringLeft($asm, 8) = 'cmp ecx,' And StringLen($asm) > 10
			Local $opCode = '81F9' & StringMid($asm, 9)
			$asmInjectionSize += 0.5 * StringLen($opCode)
			$asmInjectionString &= $opCode
		Case Else
			Local $opCode
			Switch $asm
				Case 'Flag_'
					$opCode = '9090903434'
				Case 'nop'
					$opCode = '90'
				Case 'pushad'
					$opCode = '60'
				Case 'popad'
					$opCode = '61'
				Case 'mov ebx,dword[eax]'
					$opCode = '8B18'
				Case 'mov ebx,dword[ecx]'
					$opCode = '8B19'
				Case 'mov ecx,dword[ebx+ecx]'
					$opCode = '8B0C0B'
				Case 'test eax,eax'
					$opCode = '85C0'
				Case 'test ebx,ebx'
					$opCode = '85DB'
				Case 'test ecx,ecx'
					$opCode = '85C9'
				Case 'mov dword[eax],0'
					$opCode = 'C70000000000'
				Case 'push eax'
					$opCode = '50'
				Case 'push ebx'
					$opCode = '53'
				Case 'push ecx'
					$opCode = '51'
				Case 'push edx'
					$opCode = '52'
				Case 'push ebp'
					$opCode = '55'
				Case 'push esi'
					$opCode = '56'
				Case 'push edi'
					$opCode = '57'
				Case 'jmp ebx'
					$opCode = 'FFE3'
				Case 'pop eax'
					$opCode = '58'
				Case 'pop ebx'
					$opCode = '5B'
				Case 'pop edx'
					$opCode = '5A'
				Case 'pop ecx'
					$opCode = '59'
				Case 'pop esi'
					$opCode = '5E'
				Case 'inc eax'
					$opCode = '40'
				Case 'inc ecx'
					$opCode = '41'
				Case 'inc ebx'
					$opCode = '43'
				Case 'dec edx'
					$opCode = '4A'
				Case 'mov edi,edx'
					$opCode = '8BFA'
				Case 'mov ecx,esi'
					$opCode = '8BCE'
				Case 'mov ecx,edi'
					$opCode = '8BCF'
				Case 'mov ecx,esp'
					$opCode = '8BCC'
				Case 'xor eax,eax'
					$opCode = '33C0'
				Case 'xor ecx,ecx'
					$opCode = '33C9'
				Case 'xor edx,edx'
					$opCode = '33D2'
				Case 'xor ebx,ebx'
					$opCode = '33DB'
				Case 'mov edx,eax'
					$opCode = '8BD0'
				Case 'mov edx,ecx'
					$opCode = '8BD1'
				Case 'mov ebp,esp'
					$opCode = '8BEC'
				Case 'sub esp,8'
					$opCode = '83EC08'
				Case 'sub esi,4'
					$opCode = '83EE04'
				Case 'sub esp,14'
					$opCode = '83EC14'
				Case 'sub eax,C'
					$opCode = '83E80C'
				Case 'cmp ecx,4'
					$opCode = '83F904'
				Case 'cmp ecx,32'
					$opCode = '83F932'
				Case 'cmp ecx,3C'
					$opCode = '83F93C'
				Case 'mov ecx,edx'
					$opCode = '8BCA'
				Case 'mov eax,ecx'
					$opCode = '8BC1'
				Case 'mov ecx,dword[ebp+8]'
					$opCode = '8B4D08'
				Case 'mov ecx,dword[esp+1F4]'
					$opCode = '8B8C24F4010000'
				Case 'mov ecx,dword[edi+4]'
					$opCode = '8B4F04'
				Case 'mov ecx,dword[edi+8]'
					$opCode = '8B4F08'
				Case 'mov eax,dword[edi+4]'
					$opCode = '8B4704'
				Case 'mov dword[eax+4],ecx'
					$opCode = '894804'
				Case 'mov dword[eax+8],ebx'
					$opCode = '895808'
				Case 'mov dword[eax+8],ecx'
					$opCode = '894808'
				Case 'mov dword[eax+C],ecx'
					$opCode = '89480C'
				Case 'mov dword[esi+10],eax'
					$opCode = '894610'
				Case 'mov ecx,dword[edi]'
					$opCode = '8B0F'
				Case 'mov dword[eax],ecx'
					$opCode = '8908'
				Case 'mov dword[eax],ebx'
					$opCode = '8918'
				Case 'mov edx,dword[eax+4]'
					$opCode = '8B5004'
				Case 'mov edx,dword[eax+8]'
					$opCode = '8B5008'
				Case 'mov edx,dword[eax+c]'
					$opCode = '8B500C'
				Case 'mov edx,dword[esi+1c]'
					$opCode = '8B561C'
				Case 'push dword[eax+8]'
					$opCode = 'FF7008'
				Case 'lea eax,dword[eax+18]'
					$opCode = '8D4018'
				Case 'lea ecx,dword[eax+4]'
					$opCode = '8D4804'
				Case 'lea ecx,dword[eax+C]'
					$opCode = '8D480C'
				Case 'lea eax,dword[eax+4]'
					$opCode = '8D4004'
				Case 'lea edx,dword[eax]'
					$opCode = '8D10'
				Case 'lea edx,dword[eax+4]'
					$opCode = '8D5004'
				Case 'lea edx,dword[eax+8]'
					$opCode = '8D5008'
				Case 'mov ecx,dword[eax+4]'
					$opCode = '8B4804'
				Case 'mov esi,dword[eax+4]'
					$opCode = '8B7004'
				Case 'mov esp,dword[eax+4]'
					$opCode = '8B6004'
				Case 'mov ecx,dword[eax+8]'
					$opCode = '8B4808'
				Case 'mov eax,dword[eax+8]'
					$opCode = '8B4008'
				Case 'mov eax,dword[eax+C]'
					$opCode = '8B400C'
				Case 'mov ebx,dword[eax+4]'
					$opCode = '8B5804'
				Case 'mov ebx,dword[eax]'
					$opCode = '8B10'
				Case 'mov ebx,dword[eax+8]'
					$opCode = '8B5808'
				Case 'mov ebx,dword[eax+C]'
					$opCode = '8B580C'
				Case 'mov ebx,dword[ecx+148]'
					$opCode = '8B9948010000'
				Case 'mov ecx,dword[ebx+13C]'
					$opCode = '8B9B3C010000'
				Case 'mov ebx,dword[ebx+F0]'
					$opCode = '8B9BF0000000'
				Case 'mov ecx,dword[eax+C]'
					$opCode = '8B480C'
				Case 'mov ecx,dword[eax+10]'
					$opCode = '8B4810'
				Case 'mov eax,dword[eax+4]'
					$opCode = '8B4004'
				Case 'push dword[eax+4]'
					$opCode = 'FF7004'
				Case 'push dword[eax+c]'
					$opCode = 'FF700C'
				Case 'mov esp,ebp'
					$opCode = '8BE5'
				Case 'mov esp,ebp'
					$opCode = '8BE5'
				Case 'pop ebp'
					$opCode = '5D'
				Case 'retn 10'
					$opCode = 'C21000'
				Case 'cmp eax,2'
					$opCode = '83F802'
				Case 'cmp eax,0'
					$opCode = '83F800'
				Case 'cmp eax,B'
					$opCode = '83F80B'
				Case 'cmp eax,200'
					$opCode = '3D00020000'
				Case 'shl eax,4'
					$opCode = 'C1E004'
				Case 'shl eax,8'
					$opCode = 'C1E008'
				Case 'shl eax,6'
					$opCode = 'C1E006'
				Case 'shl eax,7'
					$opCode = 'C1E007'
				Case 'shl eax,8'
					$opCode = 'C1E008'
				Case 'shl eax,9'
					$opCode = 'C1E009'
				Case 'mov edi,eax'
					$opCode = '8BF8'
				Case 'mov dx,word[ecx]'
					$opCode = '668B11'
				Case 'mov dx,word[edx]'
					$opCode = '668B12'
				Case 'mov word[eax],dx'
					$opCode = '668910'
				Case 'test dx,dx'
					$opCode = '6685D2'
				Case 'cmp word[edx],0'
					$opCode = '66833A00'
				Case 'cmp eax,ebx'
					$opCode = '3BC3'
				Case 'cmp eax,ecx'
					$opCode = '3BC1'
				Case 'mov eax,dword[esi+8]'
					$opCode = '8B4608'
				Case 'mov ecx,dword[eax]'
					$opCode = '8B08'
				Case 'mov ebx,edi'
					$opCode = '8BDF'
				Case 'mov ebx,eax'
					$opCode = '8BD8'
				Case 'mov eax,edi'
					$opCode = '8BC7'
				Case 'mov al,byte[ebx]'
					$opCode = '8A03'
				Case 'test al,al'
					$opCode = '84C0'
				Case 'mov eax,dword[ecx]'
					$opCode = '8B01'
				Case 'lea ecx,dword[eax+180]'
					$opCode = '8D8880010000'
				Case 'mov ebx,dword[ecx+14]'
					$opCode = '8B5914'
				Case 'mov eax,dword[ebx+c]'
					$opCode = '8B430C'
				Case 'mov ecx,eax'
					$opCode = '8BC8'
				Case 'cmp eax,-1'
					$opCode = '83F8FF'
				Case 'mov al,byte[ecx]'
					$opCode = '8A01'
				Case 'mov ebx,dword[edx]'
					$opCode = '8B1A'
				Case 'lea edi,dword[edx+ebx]'
					$opCode = '8D3C1A'
				Case 'mov ah,byte[edi]'
					$opCode = '8A27'
				Case 'cmp al,ah'
					$opCode = '3AC4'
				Case 'mov dword[edx],0'
					$opCode = 'C70200000000'
				Case 'mov dword[ebx],ecx'
					$opCode = '890B'
				Case 'cmp edx,esi'
					$opCode = '3BD6'
				Case 'cmp ecx,1050000'
					$opCode = '81F900000501'
				Case 'mov edi,dword[edx+4]'
					$opCode = '8B7A04'
				Case 'mov edi,dword[eax+4]'
					$opCode = '8B7804'
				Case $asm = 'mov ecx,dword[E1D684]'
					$opCode = '8B0D84D6E100'
				Case $asm = 'mov dword[edx-0x70],ecx'
					$opCode = '894A90'
				Case $asm = 'mov ecx,dword[edx+0x1C]'
					$opCode = '8B4A1C'
				Case $asm = 'mov dword[edx+0x54],ecx'
					$opCode = '894A54'
				Case $asm = 'mov ecx,dword[edx+4]'
					$opCode = '8B4A04'
				Case $asm = 'mov dword[edx-0x14],ecx'
					$opCode = '894AEC'
				Case 'cmp ebx,edi'
					$opCode = '3BDF'
				Case 'mov dword[edx],ebx'
					$opCode = '891A'
				Case 'lea edi,dword[edx+8]'
					$opCode = '8D7A08'
				Case 'mov dword[edi],ecx'
					$opCode = '890F'
				Case 'retn'
					$opCode = 'C3'
				Case 'mov dword[edx],-1'
					$opCode = 'C702FFFFFFFF'
				Case 'cmp eax,1'
					$opCode = '83F801'
				Case 'mov eax,dword[ebp+37c]'
					$opCode = '8B857C030000'
				Case 'mov eax,dword[ebp+338]'
					$opCode = '8B8538030000'
				Case 'mov ecx,dword[ebx+250]'
					$opCode = '8B8B50020000'
				Case 'mov ecx,dword[ebx+194]'
					$opCode = '8B8B94010000'
				Case 'mov ecx,dword[ebx+18]'
					$opCode = '8B5918'
				Case 'mov ecx,dword[ebx+40]'
					$opCode = '8B5940'
				Case 'mov ebx,dword[ecx+10]'
					$opCode = '8B5910'
				Case 'mov ebx,dword[ecx+18]'
					$opCode = '8B5918'
				Case 'mov ebx,dword[ecx+4c]'
					$opCode = '8B594C'
				Case 'mov ecx,dword[ebx]'
					$opCode = '8B0B'
				Case 'mov edx,esp'
					$opCode = '8BD4'
				Case 'mov ecx,dword[ebx+170]'
					$opCode = '8B8B70010000'
				Case 'cmp eax,dword[esi+9C]'
					$opCode = '3B869C000000'
				Case 'mov ebx,dword[ecx+20]'
					$opCode = '8B5920'
				Case 'mov ecx,dword[ecx]'
					$opCode = '8B09'
				Case 'mov eax,dword[ecx+40]'
					$opCode = '8B4140'
				Case 'mov ecx,dword[ecx+4]'
					$opCode = '8B4904'
				Case 'mov ecx,dword[ecx+8]'
					$opCode = '8B4908'
				Case 'mov ecx,dword[ecx+34]'
					$opCode = '8B4934'
				Case 'mov ecx,dword[ecx+C]'
					$opCode = '8B490C'
				Case 'mov ecx,dword[ecx+10]'
					$opCode = '8B4910'
				Case 'mov ecx,dword[ecx+18]'
					$opCode = '8B4918'
				Case 'mov ecx,dword[ecx+20]'
					$opCode = '8B4920'
				Case 'mov ecx,dword[ecx+4c]'
					$opCode = '8B494C'
				Case 'mov ecx,dword[ecx+50]'
					$opCode = '8B4950'
				Case 'mov ecx,dword[ecx+148]'
					$opCode = '8B8948010000'
				Case 'mov ecx,dword[ecx+170]'
					$opCode = '8B8970010000'
				Case 'mov ecx,dword[ecx+194]'
					$opCode = '8B8994010000'
				Case 'mov ecx,dword[ecx+250]'
					$opCode = '8B8950020000'
				Case 'mov ecx,dword[ecx+134]'
					$opCode = '8B8934010000'
				Case 'mov ecx,dword[ecx+13C]'
					$opCode = '8B893C010000'
				Case 'mov al,byte[ecx+4f]'
					$opCode = '8A414F'
				Case 'mov al,byte[ecx+3f]'
					$opCode = '8A413F'
				Case 'cmp al,f'
					$opCode = '3C0F'
				Case 'lea esi,dword[esi+ebx*4]'
					$opCode = '8D349E'
				Case 'mov esi,dword[esi]'
					$opCode = '8B36'
				Case 'test esi,esi'
					$opCode = '85F6'
				Case 'clc'
					$opCode = 'F8'
				Case 'repe movsb'
					$opCode = 'F3A4'
				Case 'inc edx'
					$opCode = '42'
				Case 'mov eax,dword[ebp+8]'
					$opCode = '8B4508'
				Case 'mov eax,dword[ecx+8]'
					$opCode = '8B4108'
				Case 'test al,1'
					$opCode = 'A801'
				Case $asm = 'mov eax,[eax+2C]'
					$opCode = '8B402C'
				Case $asm = 'mov eax,[eax+680]'
					$opCode = '8B8080060000'
				Case $asm = 'fld st(0),dword[ebp+8]'
					$opCode = 'D94508'
				Case 'mov esi,eax'
					$opCode = '8BF0'
				Case 'mov edx,dword[ecx]'
					$opCode = '8B11'
				Case 'mov dword[eax],edx'
					$opCode = '8910'
				Case 'test edx,edx'
					$opCode = '85D2'
				Case 'mov dword[eax],F'
					$opCode = 'C7000F000000'
				Case 'mov ebx,[ebx+0]'
					$opCode = '8B1B'
				Case 'mov ebx,[ebx+AC]'
					$opCode = '8B9BAC000000'
				Case 'mov ebx,[ebx+C]'
					$opCode = '8B5B0C'
				Case 'mov eax,dword[ebx+28]'
					$opCode = '8B4328'
				Case 'mov eax,[eax]'
					$opCode = '8B00'
				Case 'mov eax,[eax+4]'
					$opCode = '8B4004'
				Case 'mov ebx,dword[ebp+C]'
					$opCode = '8B5D0C'
				Case 'add ebx,ecx'
					$opCode = '03D9'
				Case 'lea ecx,dword[ecx+ecx*2]'
					$opCode = '8D0C49'
				Case 'lea ecx,dword[ebx+ecx*4]'
					$opCode = '8D0C8B'
				Case 'lea ecx,dword[ecx+18]'
					$opCode = '8D4918'
				Case 'mov ecx,dword[ecx+edx]'
					$opCode = '8B0C11'
				Case 'push dword[ebp+8]'
					$opCode = 'FF7508'
				Case 'mov dword[eax],edi'
					$opCode = '8938'
				Case 'mov [eax+8],ecx'
					$opCode = '894808'
				Case 'mov [eax+C],ecx'
					$opCode = '89480C'
				Case 'mov ebx,dword[ecx-C]'
					$opCode = '8B59F4'
				Case 'mov [eax+!],ebx'
					$opCode = '89580C'
				Case 'mov ecx,[eax+8]'
					$opCode = '8B4808'
				Case 'lea ecx,dword[ebx+18]'
					$opCode = '8D4B18'
				Case 'mov ebx,dword[ebx+18]'
					$opCode = '8B5B18'
				Case 'mov ecx,dword[ecx+0xF4]'
					$opCode = '8B89F4000000'
				Case 'cmp ah,00'
					$lOpCode = '80FC00'
				Case Else
					MsgBox(0x0, 'ASM', 'Could not assemble: ' & $asm)
					Exit
			EndSwitch
			$asmInjectionSize += 0.5 * StringLen($opCode)
			$asmInjectionString &= $opCode
	EndSelect
EndFunc


;~ Internal use only.
Func CompleteASMCode()
	Local $inExpression = False
	Local $expression
	Local $tempValueASM = $asmInjectionString
	Local $currentOffset = Dec(Hex($memoryInterface)) + $asmCodeOffset
	Local $token

	For $i = 1 To $labelsStruct[0][0]
		If StringLeft($labelsStruct[$i][0], 6) = 'Label_' Then
			$labelsStruct[$i][0] = StringTrimLeft($labelsStruct[$i][0], 6)
			$labelsStruct[$i][1] = $memoryInterface + $labelsStruct[$i][1]
		EndIf
	Next

	$asmInjectionString = ''
	For $i = 1 To StringLen($tempValueASM)
		$token = StringMid($tempValueASM, $i, 1)
		Switch $token
			Case '(', '[', '{'
				$inExpression = True
			Case ')'
				$asmInjectionString &= Hex(GetLabelInfo($expression) - Int($currentOffset) - 1, 2)
				$currentOffset += 1
				$inExpression = False
				$expression = ''
			Case ']'
				$asmInjectionString &= SwapEndian(Hex(GetLabelInfo($expression), 8))
				$currentOffset += 4
				$inExpression = False
				$expression = ''
			Case '}'
				$asmInjectionString &= SwapEndian(Hex(GetLabelInfo($expression) - Int($currentOffset) - 4, 8))
				$currentOffset += 4
				$inExpression = False
				$expression = ''
			Case Else
				If $inExpression Then
					$expression &= $token
				Else
					$asmInjectionString &= $token
					$currentOffset += 0.5
				EndIf
		EndSwitch
	Next
EndFunc


;~ Internal use only.
Func GetLabelInfo($label)
	Local Const $value = GetValue($label)
	Return $value
EndFunc


;~ Internal use only.
Func ASMNumber($number, $small = False)
	If $number >= 0 Then
		$number = Dec($number)
	EndIf
	If $small And $number <= 127 And $number >= -128 Then
		Return SetExtended(1, Hex($number, 2))
	Else
		Return SetExtended(0, SwapEndian(Hex($number, 8)))
	EndIf
EndFunc
#EndRegion Assembler
#EndRegion Other Functions


; #FUNCTION# ====================================================================================================================
; Name...........:	_ProcessGetName
; Description ...:	Returns a string containing the process name that belongs to a given PID.
; Syntax.........:	_ProcessGetName( $iPID )
; Parameters ....:	$iPID - The PID of a currently running process
; Return values .:	Success		- The name of the process
;					Failure		- Blank string and sets @error
;						1 - Process doesn't exist
;						2 - Error getting process list
;						3 - No processes found
; Author ........: Erifash <erifash [at] gmail [dot] com>, Wouter van Kesteren.
; Remarks .......: Supplementary to ProcessExists().
; ===============================================================================================================================
Func __ProcessGetName($pid)
	If Not ProcessExists($pid) Then Return SetError(1, 0, '')
	If Not @error Then
		Local $processes = ProcessList()
		For $i = 1 To $processes[0][0]
			If $processes[$i][1] = $pid Then Return $processes[$i][0]
		Next
	EndIf
	Return SetError(1, 0, '')
EndFunc


Func CheckArea($X, $Y)
	Local $result = False
	Local $agentX = GetAgentInfo(-2, 'X')
	Local $agentY = GetAgentInfo(-2, 'Y')

	If ($agentX < $X + 500) And ($agentX > $X - 500) And ($agentY < $Y + 500) And ($agentY > $Y - 500) Then
		$result = True
	EndIf
	Return $result
EndFunc


Func Disconnected()
	Local $check = False
	Local $deadlock = TimerInit()
	Do
		Sleep(20)
		$check = GetInstanceType() <> 2 And GetAgentExists(-2)
	Until $check Or TimerDiff($deadlock) > 5000
	If $check = False Then
		Out('Disconnected!')
		Out('Attempting to reconnect.')
		ControlSend(GetWindowHandle(), '', '', '{Enter}')
		$deadlock = TimerInit()
		Do
			Sleep(20)
			$check = GetInstanceType() <> 2 And GetAgentExists(-2)
		Until $check Or TimerDiff($deadlock) > 60000
		If $check = False Then
			Out('Failed to Reconnect 1!')
			Out('Retrying.')
			ControlSend(GetWindowHandle(), '', '', '{Enter}')
			$deadlock = TimerInit()
			Do
				Sleep(20)
				$check = GetInstanceType() <> 2 And GetAgentExists(-2)
			Until $check Or TimerDiff($deadlock) > 60000
			If $check = False Then
				Out('Failed to Reconnect 2!')
				Out('Retrying.')
				ControlSend(GetWindowHandle(), '', '', '{Enter}')
				$deadlock = TimerInit()
				Do
					Sleep(20)
					$check = GetInstanceType() <> 2 And GetAgentExists(-2)
				Until $check Or TimerDiff($deadlock) > 60000
				If $check = False Then
					Out('Could not reconnect!')
					Out('Exiting.')
					EnableRendering()
					Exit 1
				EndIf
			EndIf
		EndIf
	EndIf
	Out('Reconnected!')
	Sleep(5000)
EndFunc


Func GetPartySize()
	Local $offset[5] = [0, 0x18, 0x4C, 0x54, 0xC]
	Local $playersPtr = MemoryReadPtr($baseAddressPtr, $offset)

	Local $offset[5] = [0, 0x18, 0x4C, 0x54, 0x1C]
	Local $henchmenPtr = MemoryReadPtr($baseAddressPtr, $offset)

	Local $offset[5] = [0, 0x18, 0x4C, 0x54, 0x2C]
	Local $heroesPtr = MemoryReadPtr($baseAddressPtr, $offset)

	Local $players = MemoryRead($playersPtr[0], 'long')
	Local $henchmen = MemoryRead($henchmenPtr[0], 'long')
	Local $heroes = MemoryRead($heroesPtr[0], 'long')

	Local $result = $players + $henchmen + $heroes
	Return $result
EndFunc


Func GetPartyAlliesSize()
	Local $offset[5] = [0, 0x18, 0x4C, 0x54, 0x3C]
	Local $alliesPtr = MemoryReadPtr($baseAddressPtr, $offset)
	Local $result = MemoryRead($alliesPtr[0], 'long')
	Return $result
EndFunc


Func GetPartyWaitingForMission()
	Return GetPartyState(0x8)
EndFunc


Func GetBestTarget($range = 1320)
	Local $bestTarget, $distance, $lowestSum = 100000000
	Local $agentArray = GetAgentArray(0xDB)
	For $i = 1 To $agentArray[0]
		Local $distancesSum = 0
		If GetAgentInfo($agentArray[$i], 'Allegiance') <> 3 Then ContinueLoop
		If GetAgentInfo($agentArray[$i], 'HP') <= 0 Then ContinueLoop
		If GetAgentInfo($agentArray[$i], 'ID') = GetMyID() Then ContinueLoop
		If GetDistance($agentArray[$i]) > $range Then ContinueLoop
		For $j = 1 To $agentArray[0]
			If GetAgentInfo($agentArray[$j], 'Allegiance') <> 3 Then ContinueLoop
			If GetAgentInfo($agentArray[$j], 'HP') <= 0 Then ContinueLoop
			If GetAgentInfo($agentArray[$j], 'ID') = GetMyID() Then ContinueLoop
			If GetDistance($agentArray[$j]) > $range Then ContinueLoop
			$distance = GetDistance($agentArray[$i], $agentArray[$j])
			$distancesSum += $distance
		Next
		If $distancesSum < $lowestSum Then
			$lowestSum = $distancesSum
			$bestTarget = $agentArray[$i]
		EndIf
	Next
	Return $bestTarget
EndFunc


Func WaitMapLoading($mapID = -1, $deadlockTime = 10000, $waitingTime = 5000)
	Local $offset[5] = [0, 0x18, 0x2C, 0x6F0, 0xBC]
	Local $deadlock = TimerInit()
	Local $skillbarStruct
	Do
		Sleep(200)
		$skillbarStruct = MemoryReadPtr($baseAddressPtr, $offset, 'ptr')
		If $skillbarStruct[0] = 0 Then $deadlock = TimerInit()
		If TimerDiff($deadlock) > $deadlockTime And $deadlockTime > 0 Then Return False
	Until GetAgentExists(-2) And $skillbarStruct[0] <> 0 And (GetMapID() = $mapID Or $mapID = -1)
	RndSleep($waitingTime)
	Return True
EndFunc


Func TradePlayer($agent)
	Local $agentID

	If IsDllStruct($agent) Then
		$agentID = DllStructGetData($agent, 'ID')
	Else
		$agentID = ConvertID($agent)
	EndIf
	SendPacket(0x08, $HEADER_TRADE_PLAYER, $agentID)
EndFunc


Func AcceptTrade()
	Return SendPacket(0x4, $HEADER_TRADE_ACCEPT)
EndFunc


;~ Like pressing the 'Accept' button in a trade. Can only be used after both players have submitted their offer.
Func SubmitOffer($gold = 0)
	Return SendPacket(0x8, $HEADER_TRADE_SUBMIT_OFFER, $gold)
EndFunc


;~ Like pressing the 'Cancel' button in a trade.
Func CancelTrade()
	Return SendPacket(0x4, $HEADER_TRADE_CANCEL)
EndFunc


;~ Like pressing the 'Change Offer' button.
Func ChangeOffer()
	Return SendPacket(0x4, $HEADER_TRADE_CHANGE_OFFER)
EndFunc


;~ $itemID = ID of the item or item agent, $amount = Quantity
Func OfferItem($itemID, $amount = 1)
	Return SendPacket(0xC, $HEADER_TRADE_OFFER_ITEM, $itemID, $amount)
EndFunc


;~ Returns: 1 - Trade windows exist; 3 - Offer; 7 - Accepted Trade
Func TradeWinExist()
	Local $offset = [0, 0x18, 0x58, 0]
	Return MemoryReadPtr($baseAddressPtr, $offset)[1]
EndFunc


Func TradeOfferItemExist()
	Local $offset = [0, 0x18, 0x58, 0x28, 0]
	Return MemoryReadPtr($baseAddressPtr, $offset)[1]
EndFunc


Func TradeOfferMoneyExist()
	Local $offset = [0, 0x18, 0x58, 0x24]
	Return MemoryReadPtr($baseAddressPtr, $offset)[1]
EndFunc


Func ToggleTradePatch($enableTradePatch = True)
	MemoryWrite($tradeHackAddress, $enableTradePatch ? 0xC3 : 0x55, 'BYTE')
EndFunc


Func GetLastDialogID()
	Return MemoryRead($lastDialogId)
EndFunc


Func GetLastDialogIDHex(Const ByRef $ID)
	If $ID Then Return '0x' & StringReplace(Hex($ID, 8), StringRegExpReplace(Hex($ID, 8), '[^0].*', ''), '')
EndFunc


;~ Returns array with itemIDs of Items in Bags with correct ModelID.
Func GetBagItemIDByModelID($modelID)
	Local $resultArray[291][3]
	Local $count = 0
	For $bag = 1 To 17
		Local $bagPtr = GetBag($bag)
		Local $lSlots = MemoryRead($bagPtr + 32, 'long')
		For $slot = 1 To $lSlots
			Local $itemPtr = GetItemPtrBySlot($bagPtr, $slot)
			Local $itemMID = MemoryRead($itemPtr + 44, 'long')
			If $itemMID = $modelID Then
				Local $itemID = MemoryRead($itemPtr, 'long')
				$resultArray[$count][0] = $itemID
				$resultArray[$count][1] = $bag
				$resultArray[$count][2] = $slot
				$count += 1
			EndIf
		Next
	Next
	ReDim $resultArray[$count][3]
	Return $itemID
EndFunc


Func GetBagPtr($bagIndex)
	Local $offset[5] = [0, 0x18, 0x40, 0xF8, 0x4 * $bagIndex]
	Local $itemStructAddress = MemoryReadPtr($baseAddressPtr, $offset, 'ptr')
	Return $itemStructAddress[1]
EndFunc


Func GetItemPtrBySlot($bag, $slot)
	If IsPtr($bag) Then
		$bagPtr = $bag
	Else
		If $bag < 1 Or $bag > 17 Then Return 0
		If $slot < 1 Or $slot > GetMaxSlots($bag) Then Return 0
		Local $bagPtr = GetBagPtr($bag)
	EndIf
	Local $itemArrayPtr = MemoryRead($bagPtr + 24, 'ptr')
	Return MemoryRead($itemArrayPtr + 4 * ($slot - 1), 'ptr')
EndFunc


;~ Returns amount of slots of bag.
Func GetMaxSlots($bag)
	If IsPtr($bag) Then
		Return MemoryRead($bag + 32, 'long')
	ElseIf IsDllStruct($bag) Then
		Return DllStructGetData($bag, 'Slots')
	Else
		Return MemoryRead(GetBagPtr($bag) + 32, 'long')
	EndIf
EndFunc


;~ Log critical errors to a file - don't use for any other purpose (opens and closes files in a very inefficient manner)
Func logCriticalErrors($log)
	Local $loggingFile = FileOpen('logs/critical_errors.log' , $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)
	FileWrite($loggingFile, '[' & @YEAR & @MONTH & @DAY & '-' & @HOUR & ':' & @MIN & @SEC & ']-' & $log)
	FileClose($loggingFile)
EndFunc