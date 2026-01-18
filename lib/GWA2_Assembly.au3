#CS ===========================================================================
; Author: gigi, tjubutsi, Greg-76
; Modified by: MrZambix, Night, Gahais, and more
; This file contains all GWA2 memory scanning content, sensitive to game versions
#CE ===========================================================================

#include-once

#include 'GWA2_Headers.au3'
#include 'Utils-Debugger.au3'

; Required for memory access, opening external process handles and injecting code
#RequireAdmin

#Region Constants
Global Const $MAX_CLIENTS = 30

; Memory interaction constants
Global Const $GWA2_REFORGED_HEADER_HEXA = '4757413252415049'
Global Const $GWA2_REFORGED_HEADER_STRING = 'GWA2RAPI'
Global Const $GWA2_REFORGED_HEADER_SIZE = 16
Global Const $GWA2_REFORGED_OFFSET_SCAN_ADDRESS = 8
Global Const $GWA2_REFORGED_OFFSET_COMMAND_ADDRESS = 12

Global Const $CONTROL_TYPE_ACTIVATE = 0x20
Global Const $CONTROL_TYPE_DEACTIVATE = 0x22

#Region GWA2 Structure templates
; Don't create global DllStruct for those (can exist simultaneously in several instances)
Global Const $AGENT_STRUCT_TEMPLATE = 'ptr vtable;dword unknown008[4];dword Timer;dword Timer2;ptr NextAgent;dword unknown032[3];long ID;float Z;float Width1;float Height1;float Width2;float Height2;float Width3;float Height3;float Rotation;float RotationCos;float RotationSin;dword NameProperties;dword Ground;dword unknown096;float TerrainNormalX;float TerrainNormalY;dword TerrainNormalZ;byte unknown112[4];float X;float Y;dword Plane;byte unknown128[4];float NameTagX;float NameTagY;float NameTagZ;short VisualEffects;short unknown146;dword unknown148[2];long Type;float MoveX;float MoveY;dword unknown168;float RotationCos2;float RotationSin2;dword unknown180[4];long Owner;dword ItemID;dword ExtraType;dword GadgetID;dword unknown212[3];float AnimationType;dword unknown228[2];float AttackSpeed;float AttackSpeedModifier;short ModelID;short AgentModelType;dword TransmogNpcID;ptr Equip;dword unknown256;dword unknown260;ptr Tags;short unknown268;byte Primary;byte Secondary;byte Level;byte Team;byte unknown274[2];dword unknown276;float EnergyRegen;float Overcast;float EnergyPercent;dword MaxEnergy;dword unknown296;float HPPips;dword unknown304;float HealthPercent;dword MaxHealth;dword Effects;dword unknown320;byte Hex;byte unknown325[19];dword ModelState;dword TypeMap;dword unknown352[4];dword InSpiritRange;dword VisibleEffects;dword VisibleEffectsID;dword VisibleEffectsHasEnded;dword unknown384;dword LoginNumber;float AnimationSpeed;dword AnimationCode;dword AnimationID;byte unknown404[32];byte LastStrike;byte Allegiance;short WeaponType;short Skill;short unknown442;byte WeaponItemType;byte OffhandItemType;short WeaponItemId;short OffhandItemID'
Global Const $BUFF_STRUCT_TEMPLATE = 'long SkillId;long unknown1;long BuffId;long TargetID'
Global Const $EFFECT_STRUCT_TEMPLATE = 'long SkillId;long AttributeLevel;long EffectId;long AgentId;float Duration;long TimeStamp'
Global Const $SKILLBAR_STRUCT_TEMPLATE = 'long AgentId;long AdrenalineA1;long AdrenalineB1;dword Recharge1;dword SkillId1;dword Event1;long AdrenalineA2;long AdrenalineB2;dword Recharge2;dword SkillId2;dword Event2;long AdrenalineA3;long AdrenalineB3;dword Recharge3;dword SkillId3;dword Event3;long AdrenalineA4;long AdrenalineB4;dword Recharge4;dword SkillId4;dword Event4;long AdrenalineA5;long AdrenalineB5;dword Recharge5;dword SkillId5;dword Event5;long AdrenalineA6;long AdrenalineB6;dword Recharge6;dword SkillId6;dword Event6;long AdrenalineA7;long AdrenalineB7;dword Recharge7;dword SkillId7;dword Event7;long AdrenalineA8;long AdrenalineB8;dword Recharge8;dword SkillId8;dword Event8;dword disabled;long unknown1[2];dword Casting;long unknown2[2]'
Global Const $SKILL_STRUCT_TEMPLATE = 'long ID;long Unknown1;long campaign;long Type;long Special;long ComboReq;long InflictsCondition;long Condition;long EffectFlag;long WeaponReq;byte Profession;byte Attribute;short Title;long PvPID;byte Combo;byte Target;byte unknown3;byte EquipType;byte Overcast;byte EnergyCost;byte HealthCost;byte unknown4;dword Adrenaline;float Activation;float Aftercast;long Duration0;long Duration15;long Recharge;long Unknown5[4];dword SkillArguments;long Scale0;long Scale15;long BonusScale0;long BonusScale15;float AoERange;float ConstEffect;dword caster_overhead_animation_id;dword caster_body_animation_id;dword target_body_animation_id;dword target_overhead_animation_id;dword projectile_animation_1_id;dword projectile_animation_2_id;dword icon_file_id_hd;dword icon_file_id;dword icon_file_id_2;dword name;dword concise;dword description'
Global Const $ATTRIBUTE_STRUCT_TEMPLATE = 'dword profession_id;dword attribute_id;dword name_id;dword desc_id;dword is_pve'
Global Const $BAG_STRUCT_TEMPLATE = 'long TypeBag;long index;long id;ptr containerItem;long ItemsCount;ptr bagArray;ptr itemArray;long fakeSlots;long slots'
Global Const $ITEM_STRUCT_TEMPLATE = 'long Id;long AgentId;ptr BagEquiped;ptr Bag;ptr ModStruct;long ModStructSize;ptr Customized;long ModelFileID;byte Type;byte DyeTint;short DyeColor;short Value;byte unknown38[2];long Interaction;long ModelId;ptr ModString;ptr NameEnc;ptr NameString;ptr SingleItemName;byte unknown64[8];short ItemFormula;byte IsMaterialSalvageable;byte unknown75;short Quantity;byte Equipped;byte Profession;byte Slot'
Global Const $QUEST_STRUCT_TEMPLATE = 'long id;long LogState;ptr Location;ptr Name;ptr NPC;long MapFrom;float X;float Y;long Z;long unknown1;long MapTo;ptr Description;ptr Objective'
Global Const $TITLE_STRUCT_TEMPLATE = 'dword properties;long CurrentPoints;long CurrentTitleTier;long PointsNeededCurrentRank;long NextTitleTier;long PointsNeededNextRank;long MaxTitleRank;long MaxTitleTier;dword unknown36;dword unknown40'
; Grey area, unlikely to exist several at the same time
Global Const $AREA_INFO_STRUCT_TEMPLATE = 'dword campaign;dword continent;dword region;dword regiontype;dword flags;dword thumbnail_id;dword min_party_size;dword max_party_size;dword min_player_size;dword max_player_size;dword controlled_outpost_id;dword fraction_mission;dword min_level;dword max_level;dword needed_pq;dword mission_maps_to;dword x;dword y;dword icon_start_x;dword icon_start_y;dword icon_end_x;dword icon_end_y;dword icon_start_x_dupe;dword icon_start_y_dupe;dword icon_end_x_dupe;dword icon_end_y_dupe;dword file_id;dword mission_chronology;dword ha_map_chronology;dword name_id;dword description_id'
; Safe zone, can just create DllStruct globally
Global Const $WORLD_STRUCT = SafeDllStructCreate('long MinGridWidth;long MinGridHeight;long MaxGridWidth;long MaxGridHeight;long Flags;long Type;long SubGridWidth;long SubGridHeight;long StartPosX;long StartPosY;long MapWidth;long MapHeight')
#EndRegion GWA2 Structure templates

#Region GWA2 Structures
Global Const $INVITE_GUILD_STRUCT = SafeDllStructCreate('ptr commandPacketSendPtr;dword id;dword header;dword counter;wchar name[32];dword type')
Global Const $INVITE_GUILD_STRUCT_PTR = DllStructGetPtr($INVITE_GUILD_STRUCT)

Global Const $USE_SKILL_STRUCT = SafeDllStructCreate('ptr useSkillCommandPtr;dword skillSlot;dword targetID;dword callTarget')
Global Const $USE_SKILL_STRUCT_PTR = DllStructGetPtr($USE_SKILL_STRUCT)

Global Const $MOVE_STRUCT = SafeDllStructCreate('ptr commandMovePtr;float X;float Y;dword')
Global Const $MOVE_STRUCT_PTR = DllStructGetPtr($MOVE_STRUCT)

Global Const $CHANGE_TARGET_STRUCT = SafeDllStructCreate('ptr commandChangeTargetPtr;dword targetID')
Global Const $CHANGE_TARGET_STRUCT_PTR = DllStructGetPtr($CHANGE_TARGET_STRUCT)

Global Const $PACKET_STRUCT = SafeDllStructCreate('ptr commandPackSendPtr;dword;dword;dword;dword characterName;dword;dword;dword;dword;dword;dword;dword;dword')
Global Const $PACKET_STRUCT_PTR = DllStructGetPtr($PACKET_STRUCT)

Global Const $WRITE_CHAT_STRUCT = SafeDllStructCreate('ptr commandWriteChatPtr')
Global Const $WRITE_CHAT_STRUCT_PTR = DllStructGetPtr($WRITE_CHAT_STRUCT)

Global Const $SELL_ITEM_STRUCT = SafeDllStructCreate('ptr commandSellItemPtr;dword totalSoldValue;dword itemID;dword ScanBuyItemBase')
Global Const $SELL_ITEM_STRUCT_PTR = DllStructGetPtr($SELL_ITEM_STRUCT)

Global Const $ACTION_STRUCT = SafeDllStructCreate('ptr commandActionPtr;dword action;dword flag;')
Global Const $ACTION_STRUCT_PTR = DllStructGetPtr($ACTION_STRUCT)

Global Const $TOGGLE_LANGUAGE_STRUCT = SafeDllStructCreate('ptr commandToggleLanguagePtr;dword')
Global Const $TOGGLE_LANGUAGE_STRUCT_PTR = DllStructGetPtr($TOGGLE_LANGUAGE_STRUCT)

Global Const $USE_HERO_SKILL_STRUCT = SafeDllStructCreate('ptr;dword;dword;dword')
Global Const $USE_HERO_SKILL_STRUCT_PTR = DllStructGetPtr($USE_HERO_SKILL_STRUCT)

Global Const $BUY_ITEM_STRUCT = SafeDllStructCreate('ptr;dword;dword;dword;dword')
Global Const $BUY_ITEM_STRUCT_PTR = DllStructGetPtr($BUY_ITEM_STRUCT)

Global Const $CRAFT_ITEM_STRUCT = SafeDllStructCreate('ptr;dword;dword;ptr;dword;dword')
Global Const $CRAFT_ITEM_STRUCT_PTR = DllStructGetPtr($CRAFT_ITEM_STRUCT)

Global Const $SEND_CHAT_STRUCT = SafeDllStructCreate('ptr;dword')
Global Const $SEND_CHAT_STRUCT_PTR = DllStructGetPtr($SEND_CHAT_STRUCT)

Global Const $REQUEST_QUOTE_STRUCT = SafeDllStructCreate('ptr;dword')
Global Const $REQUEST_QUOTE_STRUCT_PTR = DllStructGetPtr($REQUEST_QUOTE_STRUCT)

Global Const $REQUEST_QUOTE_STRUCT_SELL = SafeDllStructCreate('ptr;dword')
Global Const $REQUEST_QUOTE_STRUCT_SELL_PTR = DllStructGetPtr($REQUEST_QUOTE_STRUCT_SELL)

Global Const $TRADER_BUY_STRUCT = SafeDllStructCreate('ptr')
Global Const $TRADER_BUY_STRUCT_PTR = DllStructGetPtr($TRADER_BUY_STRUCT)

Global Const $TRADER_SELL_STRUCT = SafeDllStructCreate('ptr')
Global Const $TRADER_SELL_STRUCT_PTR = DllStructGetPtr($TRADER_SELL_STRUCT)

Global Const $SALVAGE_STRUCT = SafeDllStructCreate('ptr;dword;dword;dword')
Global Const $SALVAGE_STRUCT_PTR = DllStructGetPtr($SALVAGE_STRUCT)

Global Const $INCREASE_ATTRIBUTE_STRUCT = SafeDllStructCreate('ptr;dword;dword')
Global Const $INCREASE_ATTRIBUTE_STRUCT_PTR = DllStructGetPtr($INCREASE_ATTRIBUTE_STRUCT)

Global Const $DECREASE_ATTRIBUTE_STRUCT = SafeDllStructCreate('ptr;dword;dword')
Global Const $DECREASE_ATTRIBUTE_STRUCT_PTR = DllStructGetPtr($DECREASE_ATTRIBUTE_STRUCT)

Global Const $MAX_ATTRIBUTES_STRUCT = SafeDllStructCreate('ptr;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword')
Global Const $MAX_ATTRIBUTES_STRUCT_PTR = DllStructGetPtr($MAX_ATTRIBUTES_STRUCT)

Global Const $SET_ATTRIBUTES_STRUCT = SafeDllStructCreate('ptr;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword')
Global Const $SET_ATTRIBUTES_STRUCT_PTR = DllStructGetPtr($SET_ATTRIBUTES_STRUCT)

Global Const $MAKE_AGENT_ARRAY_STRUCT = SafeDllStructCreate('ptr;dword')
Global Const $MAKE_AGENT_ARRAY_STRUCT_PTR = DllStructGetPtr($MAKE_AGENT_ARRAY_STRUCT)

Global Const $CHANGE_STATUS_STRUCT = SafeDllStructCreate('ptr;dword')
Global Const $CHANGE_STATUS_STRUCT_PTR = DllStructGetPtr($CHANGE_STATUS_STRUCT)

Global Const $ENTER_MISSION_STRUCT = SafeDllStructCreate('ptr')
Global Const $ENTER_MISSION_STRUCT_PTR = DllStructGetPtr($ENTER_MISSION_STRUCT)
#EndRegion GWA2 Structures
#EndRegion Constants


; Windows and process handles
Global $kernel_handle = DllOpen('kernel32.dll')
; Each gameClient will be a 4-elements array: [0] = PID, [1] = process handle (or 0 if invalidated), [2] = window handle, [3] = character name
; Caution, first element of this 2D array $game_clients[0][0] is considered a count of currently inserted elements (like in AutoIT ProcessList() function), hence $MAX_CLIENTS+1
Global $game_clients[$MAX_CLIENTS+1][4]
Global $selected_client_index = -1

If Not $kernel_handle Then
	MsgBox(16, 'Error', 'Failed to open kernel32.dll')
	Exit
Else
	OnAutoItExitRegister('CloseAllHandles')
EndIf

; Memory interaction
;Global $base_address = 0x00C50000
Global $memory_interface_header = 0
Global $asm_injection_string, $asm_injection_size, $asm_code_offset
Global $trade_hack_address
Global $labels_map[]


#Region Initialisation
;~ Scan all existing GW game clients
Func ScanAndUpdateGameClients()
	Local $processList = ProcessList('gw.exe')
	If @error Or $processList[0][0] = 0 Then Return

	; Step 1: Mark all existing entries as 'unseen'
	Local $initialClientCount = $game_clients[0][0]
	Local $seen[$initialClientCount + 1]
	FillArray($seen, False)

	; Step 2: Process current gw.exe instances
	For $i = 1 To $processList[0][0]
		Local $pid = $processList[$i][1]
		Local $index = FindClientIndexByPID($pid)

		If $index <> -1 Then
			; Existing client, mark as seen
			$seen[$index] = True
		Else
			; New client, add to array
			Local $openProcess = SafeDllCall9($kernel_handle, 'int', 'OpenProcess', 'int', 0x1F0FFF, 'int', 1, 'int', $pid)
			Local $processHandle = IsArray($openProcess) ? $openProcess[0] : 0
			If $processHandle <> 0 Then
				Local $windowHandle = GetWindowHandleForProcess($pid)
				Local $characterName = ScanForCharname($processHandle)
				AddClient($pid, $processHandle, $windowHandle, $characterName)
			Else
				Error('GW Process with incorrect handle.')
			EndIf
		EndIf
	Next

	; Step 3: Invalidate unseen (terminated) processes
	For $i = 1 To $initialClientCount
		If Not $seen[$i] Then
			$game_clients[$i][0] = -1
			$game_clients[$i][1] = -1
			$game_clients[$i][2] = -1
			$game_clients[$i][3] = ''
		EndIf
	Next
EndFunc


;~ Find character names by scanning memory
Func ScanForCharname($processHandle)
	Local $scannedMemory = ScanMemoryForPattern($processHandle, BinaryToString('0x6A14FF751868'))
	; If you have issues finding your character name, tries this line instead of the previous one :
	;Local $scannedMemory = ScanMemoryForPattern($processHandle, BinaryToString('0x00E20878'))
	Local $baseAddress = $scannedMemory[1]
	Local $matchOffset = $scannedMemory[2]
	Local $tmpAddress = $baseAddress + $matchOffset - 1
	Local $buffer = SafeDllStructCreate('ptr')
	SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $tmpAddress + 6, 'ptr', DllStructGetPtr($buffer), 'int', DllStructGetSize($buffer), 'int', 0)
	Local $characterName = DllStructGetData($buffer, 1)
	Return MemoryRead($processHandle, $characterName, 'wchar[30]')
EndFunc


;~ Injects GWA2 into the game client.
Func InitializeGameClientData($changeTitle = True, $initUseStringLog = False, $inituse_event_system = True)
	$use_string_logging = $initUseStringLog
	$use_event_system = $inituse_event_system

	ScanGWBasePatterns()

	Local $processHandle = GetProcessHandle()
	; Read memory values for game data
	$base_address_ptr = MemoryRead($processHandle, GetScannedAddress('ScanBasePointer', 8))
	If @error Then LogCriticalError('Failed to read base pointer')

	SetLabel('BasePointer', '0x' & Hex($base_address_ptr, 8))
	$region_ID = MemoryRead($processHandle, GetScannedAddress('ScanRegion', -0x3))
	Local $tempValue = GetScannedAddress('ScanInstanceInfo', -0x04)
	$instance_info_ptr = MemoryRead($processHandle, $tempValue + MemoryRead($processHandle, $tempValue + 0x01) + 0x05 + 0x01, 'dword')

	$area_info_ptr = MemoryRead($processHandle, GetScannedAddress('ScanAreaInfo', 0x6))
	$attribute_info_ptr = MemoryRead($processHandle, GetScannedAddress('ScanAttributeInfo', -0x3))
	SetLabel('StringLogStart', '0x' & Hex(GetScannedAddress('ScanStringLog', 0x16), 8))
	SetLabel('LoadFinishedStart', '0x' & Hex(GetScannedAddress('ScanLoadFinished', 1), 8))
	SetLabel('LoadFinishedReturn', '0x' & Hex(GetScannedAddress('ScanLoadFinished', 6), 8))

	$agent_base_address = MemoryRead($processHandle, GetScannedAddress('ScanAgentBasePointer', 8) + 0xC - 7)
	If @error Then LogCriticalError('Failed to read agent base')
	SetLabel('AgentBase', '0x' & Hex($agent_base_address, 8))
	$max_agents = $agent_base_address + 8
	SetLabel('MaxAgents', '0x' & Hex($max_agents, 8))

	Local $agentArrayAddress = MemoryRead($processHandle, GetScannedAddress('ScanAgentArray', -0x3))
	If @error Then LogCriticalError('Failed to read agent array')

	$my_ID = MemoryRead($processHandle, GetScannedAddress('ScanMyID', -3))
	If @error Then LogCriticalError('Failed to read my ID')
	SetLabel('MyID', '0x' & Hex($my_ID, 8))

	$current_target_agent_ID = MemoryRead($processHandle, GetScannedAddress('ScanCurrentTarget', -14))
	If @error Then LogCriticalError('Failed to read current target')

	Local $packetLocation = Hex(MemoryRead($processHandle, GetScannedAddress('ScanBaseOffset', 11)), 8)
	If @error Then LogCriticalError('Failed to read packet location')
	SetLabel('PacketLocation', '0x' & $packetLocation)

	$scan_ping_address = MemoryRead($processHandle, GetScannedAddress('ScanPing', -0x3))
	If @error Then LogCriticalError('Failed to read ping')

	$map_ID = MemoryRead($processHandle, GetScannedAddress('ScanMapID', 28))
	If @error Then LogCriticalError('Failed to read map ID')

	; FIXME: this call fails
	;$map_loading = MemoryRead($processHandle, GetScannedAddress('ScanMapLoading', 0xB))
	;If @error Then LogCriticalError('Failed to read loading status')

	; FIXME: this call fails
	;$is_logged_in = MemoryRead($processHandle, GetScannedAddress('ScanLoggedIn', 0x3))
	;If @error Then LogCriticalError('Failed to read login status')

	$language_ID = MemoryRead($processHandle, GetScannedAddress('ScanMapInfo', 11)) + 0xC
	If @error Then LogCriticalError('Failed to read language and region')

	$skill_base_address = MemoryRead($processHandle, GetScannedAddress('ScanSkillBase', 0x9))
	If @error Then LogCriticalError('Failed to read skill base')

	$skill_timer = MemoryRead($processHandle, GetScannedAddress('ScanSkillTimer', -3))
	If @error Then LogCriticalError('Failed to read skill timer')

	$tempValue = GetScannedAddress('ScanBuildNumber', 0x2C)
	If @error Then LogCriticalError('Failed to read build number address')

	; FIXME: these calls fail
	;$build_number = MemoryRead($processHandle, $tempValue + MemoryRead($processHandle, $tempValue) + 5)
	;If @error Then LogCriticalError('Failed to read build number')

	$zoom_when_still = GetScannedAddress('ScanZoomStill', 0x33)
	If @error Then LogCriticalError('Failed to read zoom still address')

	$zoom_when_moving = GetScannedAddress('ScanZoomMoving', 0x21)
	If @error Then LogCriticalError('Failed to read zoom moving address')

	$current_status = MemoryRead($processHandle, GetScannedAddress('ScanChangeStatusFunction', 35))
	If @error Then LogCriticalError('Failed to read current status')

	; FIXME: this call fails
	;Local $characterSlots = MemoryRead($processHandle, GetScannedAddress('ScanCharslots', 22))
	;If @error Then LogCriticalError('Failed to read character slots')

	$tempValue = GetScannedAddress('ScanEngine', -0x22)
	If @error Then LogCriticalError('Failed to read engine address')
	SetLabel('MainStart', '0x' & Hex($tempValue, 8))
	SetLabel('MainReturn', '0x' & Hex($tempValue + 5, 8))

	$tempValue = GetScannedAddress('ScanRenderFunc', -0x68)
	If @error Then LogCriticalError('Failed to read render function address')
	SetLabel('RenderingMod', '0x' & Hex($tempValue, 8))
	SetLabel('RenderingModReturn', '0x' & Hex($tempValue + 10, 8))

	$tempValue = GetScannedAddress('ScanTargetLog', 1)
	If @error Then LogCriticalError('Failed to read target log address')
	SetLabel('TargetLogStart', '0x' & Hex($tempValue, 8))
	SetLabel('TargetLogReturn', '0x' & Hex($tempValue + 5, 8))

	$tempValue = GetScannedAddress('ScanSkillLog', 1)
	If @error Then LogCriticalError('Failed to read skill log address')
	SetLabel('SkillLogStart', '0x' & Hex($tempValue, 8))
	SetLabel('SkillLogReturn', '0x' & Hex($tempValue + 5, 8))

	$tempValue = GetScannedAddress('ScanSkillCompleteLog', -4)
	If @error Then LogCriticalError('Failed to read skill complete log address')
	SetLabel('SkillCompleteLogStart', '0x' & Hex($tempValue, 8))
	SetLabel('SkillCompleteLogReturn', '0x' & Hex($tempValue + 5, 8))

	$tempValue = GetScannedAddress('ScanSkillCancelLog', 5)
	If @error Then LogCriticalError('Failed to read skill cancel log address')
	SetLabel('SkillCancelLogStart', '0x' & Hex($tempValue, 8))
	SetLabel('SkillCancelLogReturn', '0x' & Hex($tempValue + 6, 8))

	$tempValue = GetScannedAddress('ScanChatLog', 18)
	If @error Then LogCriticalError('Failed to read chat log address')
	SetLabel('ChatLogStart', '0x' & Hex($tempValue, 8))
	SetLabel('ChatLogReturn', '0x' & Hex($tempValue + 6, 8))

	$tempValue = GetScannedAddress('ScanTraderHook', -0x3C)
	If @error Then LogCriticalError('Failed to read trader hook address')
	SetLabel('TraderStart', Ptr($tempValue))
	SetLabel('TraderReturn', Ptr($tempValue + 0x5))

	$tempValue = GetScannedAddress('ScanDialogLog', -4)
	If @error Then LogCriticalError('Failed to read dialog log address')
	SetLabel('DialogLogStart', '0x' & Hex($tempValue, 8))
	SetLabel('DialogLogReturn', '0x' & Hex($tempValue + 5, 8))

	$tempValue = GetScannedAddress('ScanStringFilter1', -5)
	If @error Then LogCriticalError('Failed to read string filter 1 address')
	SetLabel('StringFilter1Start', '0x' & Hex($tempValue, 8))
	SetLabel('StringFilter1Return', '0x' & Hex($tempValue + 5, 8))

	$tempValue = GetScannedAddress('ScanStringFilter2', 0x16)
	If @error Then LogCriticalError('Failed to read string filter 2 address')
	SetLabel('StringFilter2Start', '0x' & Hex($tempValue, 8))
	SetLabel('StringFilter2Return', '0x' & Hex($tempValue + 5, 8))

	; FIXME: this call fails
	;SetLabel('PostMessage', '0x' & Hex(MemoryRead($processHandle, GetScannedAddress('ScanPostMessage', 11)), 8))
	;If @error Then LogCriticalError('Failed to read post message')

	; FIXME: this call fails
	;SetLabel('Sleep', MemoryRead($processHandle, MemoryRead($processHandle, GetLabel('ScanSleep') + 8) + 3))
	;If @error Then LogCriticalError('Failed to read sleep')

	SetLabel('SalvageFunction', '0x' & Hex(GetScannedAddress('ScanSalvageFunction', -10), 8))
	If @error Then LogCriticalError('Failed to read salvage function')

	SetLabel('SalvageGlobal', '0x' & Hex(MemoryRead($processHandle, GetScannedAddress('ScanSalvageGlobal', 1) - 0x4), 8))
	If @error Then LogCriticalError('Failed to read salvage global')

	SetLabel('IncreaseAttributeFunction', '0x' & Hex(GetScannedAddress('ScanIncreaseAttributeFunction', -0x5A), 8))
	If @error Then LogCriticalError('Failed to read increase attribute function')

	SetLabel('DecreaseAttributeFunction', '0x' & Hex(GetScannedAddress('ScanDecreaseAttributeFunction', 25), 8))
	If @error Then LogCriticalError('Failed to read decrease attribute function')

	SetLabel('MoveFunction', '0x' & Hex(GetScannedAddress('ScanMoveFunction', 1), 8))
	If @error Then LogCriticalError('Failed to read move function')
	$tempValue = GetScannedAddress('ScanEnterMissionFunction', 0x52)
	SetLabel('EnterMissionFunction', '0x' & Hex(GetCallTargetAddress($processHandle, $tempValue), 8))
	If @error Then LogCriticalError('Failed to read EnterMission function')

	SetLabel('UseSkillFunction', '0x' & Hex(GetScannedAddress('ScanUseSkillFunction', -0x127), 8))
	If @error Then LogCriticalError('Failed to read use skill function')

	SetLabel('ChangeTargetFunction', '0x' & Hex(GetScannedAddress('ScanChangeTargetFunction', -0x89) + 1, 8))
	If @error Then LogCriticalError('Failed to read change target function')

	SetLabel('WriteChatFunction', '0x' & Hex(GetScannedAddress('ScanWriteChatFunction', -0x3D), 8))
	If @error Then LogCriticalError('Failed to read write chat function')

	SetLabel('SellItemFunction', '0x' & Hex(GetScannedAddress('ScanSellItemFunction', -85), 8))
	If @error Then LogCriticalError('Failed to read sell item function')

	SetLabel('PacketSendFunction', '0x' & Hex(GetScannedAddress('ScanPacketSendFunction', -0x4F), 8))
	If @error Then LogCriticalError('Failed to read packet send function')

	SetLabel('ActionBase', '0x' & Hex(MemoryRead($processHandle, GetScannedAddress('ScanActionBase', -3)), 8))
	If @error Then LogCriticalError('Failed to read action base')

	SetLabel('ActionFunction', '0x' & Hex(GetScannedAddress('ScanActionFunction', -3), 8))
	If @error Then LogCriticalError('Failed to read action function')

	SetLabel('UseHeroSkillFunction', '0x' & Hex(GetScannedAddress('ScanUseHeroSkillFunction', -0x59), 8))
	If @error Then LogCriticalError('Failed to read use hero skill function')

	SetLabel('BuyItemBase', '0x' & Hex(MemoryRead($processHandle, GetScannedAddress('ScanBuyItemBase', 15)), 8))
	If @error Then LogCriticalError('Failed to read buy item base')

	SetLabel('TransactionFunction', '0x' & Hex(GetScannedAddress('ScanTransactionFunction', -0x7E), 8))
	If @error Then LogCriticalError('Failed to read transaction function')

	SetLabel('RequestQuoteFunction', '0x' & Hex(GetScannedAddress('ScanRequestQuoteFunction', -0x34), 8))
	If @error Then LogCriticalError('Failed to read request quote function')

	SetLabel('TraderFunction', '0x' & Hex(GetScannedAddress('ScanTraderFunction', -0x1E), 8))
	If @error Then LogCriticalError('Failed to read trader function')

	SetLabel('ClickToMoveFix', '0x' & Hex(GetScannedAddress('ScanClickToMoveFix', 1), 8))
	If @error Then LogCriticalError('Failed to read click to move fix')

	SetLabel('ChangeStatusFunction', '0x' & Hex(GetScannedAddress('ScanChangeStatusFunction', 1), 8))
	If @error Then LogCriticalError('Failed to read change status function')
	SetLabel('QueueSize', '0x00000010')
	SetLabel('SkillLogSize', '0x00000010')
	SetLabel('ChatLogSize', '0x00000010')
	SetLabel('TargetLogSize', '0x00000200')
	SetLabel('StringLogSize', '0x00000200')
	SetLabel('CallbackEvent', '0x00000501')

	$trade_hack_address = GetScannedAddress('ScanTradeHack', 0)
	If @error Then LogCriticalError('Failed to read trade hack address')

	ModifyMemory()

	$queue_counter = MemoryRead($processHandle, GetLabel('QueueCounter'))
	If @error Then LogCriticalError('Failed to read queue counter')

	$queue_size = GetLabel('QueueSize')
	$queue_base_address = GetLabel('QueueBase')
	;$targetLogBase = GetLabel('TargetLogBase')
	$string_log_base_address = GetLabel('StringLogBase')
	Local $mapIsLoaded = GetLabel('MapIsLoaded')
	$force_english_language_flag = GetLabel('EnsureEnglish')
	$trader_quote_ID = GetLabel('TraderQuoteID')
	$trader_cost_ID = GetLabel('TraderCostID')
	$trader_cost_value = GetLabel('TraderCostValue')
	$disable_rendering_address = GetLabel('DisableRendering')
	$agent_copy_count = GetLabel('AgentCopyCount')
	$agent_copy_base = GetLabel('AgentCopyBase')
	$last_dialog_ID = GetLabel('LastDialogID')

	; EventSystem
	DllStructSetData($INVITE_GUILD_STRUCT, 1, GetLabel('CommandPacketSend'))
	If @error Then LogCriticalError('Failed to set invite guild command')
	DllStructSetData($INVITE_GUILD_STRUCT, 2, 0x4C)
	If @error Then LogCriticalError('Failed to set invite guild subcommand')
	DllStructSetData($USE_SKILL_STRUCT, 1, GetLabel('CommandUseSkill'))
	If @error Then LogCriticalError('Failed to set CommandUseSkill command')
	DllStructSetData($MOVE_STRUCT, 1, GetLabel('CommandMove'))
	If @error Then LogCriticalError('Failed to set CommandMove command')
	DllStructSetData($CHANGE_TARGET_STRUCT, 1, GetLabel('CommandChangeTarget'))
	If @error Then LogCriticalError('Failed to set CommandChangeTarget command')
	DllStructSetData($PACKET_STRUCT, 1, GetLabel('CommandPacketSend'))
	If @error Then LogCriticalError('Failed to set CommandPacketSend command')
	DllStructSetData($SELL_ITEM_STRUCT, 1, GetLabel('CommandSellItem'))
	If @error Then LogCriticalError('Failed to set CommandSellItem command')
	DllStructSetData($ACTION_STRUCT, 1, GetLabel('CommandAction'))
	If @error Then LogCriticalError('Failed to set CommandAction command')
	DllStructSetData($TOGGLE_LANGUAGE_STRUCT, 1, GetLabel('CommandToggleLanguage'))
	If @error Then LogCriticalError('Failed to set CommandToggleLanguage command')
	DllStructSetData($USE_HERO_SKILL_STRUCT, 1, GetLabel('CommandUseHeroSkill'))
	If @error Then LogCriticalError('Failed to set CommandUseHeroSkill command')
	DllStructSetData($BUY_ITEM_STRUCT, 1, GetLabel('CommandBuyItem'))
	If @error Then LogCriticalError('Failed to set CommandBuyItem command')
	DllStructSetData($SEND_CHAT_STRUCT, 1, GetLabel('CommandSendChat'))
	If @error Then LogCriticalError('Failed to set CommandSendChat command')
	DllStructSetData($SEND_CHAT_STRUCT, 2, $HEADER_SEND_CHAT)
	If @error Then LogCriticalError('Failed to set send chat subcommand')
	DllStructSetData($WRITE_CHAT_STRUCT, 1, GetLabel('CommandWriteChat'))
	If @error Then LogCriticalError('Failed to set CommandWriteChat command')
	DllStructSetData($REQUEST_QUOTE_STRUCT, 1, GetLabel('CommandRequestQuote'))
	If @error Then LogCriticalError('Failed to set CommandRequestQuote command')
	DllStructSetData($REQUEST_QUOTE_STRUCT_SELL, 1, GetLabel('CommandRequestQuoteSell'))
	If @error Then LogCriticalError('Failed to set CommandRequestQuoteSell command')
	DllStructSetData($TRADER_BUY_STRUCT, 1, GetLabel('CommandTraderBuy'))
	If @error Then LogCriticalError('Failed to set CommandTraderBuy command')
	DllStructSetData($TRADER_SELL_STRUCT, 1, GetLabel('CommandTraderSell'))
	If @error Then LogCriticalError('Failed to set CommandTraderSell command')
	DllStructSetData($SALVAGE_STRUCT, 1, GetLabel('CommandSalvage'))
	If @error Then LogCriticalError('Failed to set CommandSalvage command')
	DllStructSetData($INCREASE_ATTRIBUTE_STRUCT, 1, GetLabel('CommandIncreaseAttribute'))
	If @error Then LogCriticalError('Failed to set CommandIncreaseAttribute command')
	DllStructSetData($DECREASE_ATTRIBUTE_STRUCT, 1, GetLabel('CommandDecreaseAttribute'))
	If @error Then LogCriticalError('Failed to set CommandDecreaseAttribute command')
	DllStructSetData($MAKE_AGENT_ARRAY_STRUCT, 1, GetLabel('CommandMakeAgentArray'))
	If @error Then LogCriticalError('Failed to set CommandMakeAgentArray command')
	DllStructSetData($CHANGE_STATUS_STRUCT, 1, GetLabel('CommandChangeStatus'))
	If @error Then LogCriticalError('Failed to set CommandChangeStatus command')
	DllStructSetData($ENTER_MISSION_STRUCT, 1, GetLabel('CommandEnterMission'))
	If @error Then LogCriticalError('Failed to set CommandEnterMission command')
	If $changeTitle Then WinSetTitle(GetWindowHandle(), '', 'Guild Wars - ' & GetCharacterName())
	If @error Then LogCriticalError('Failed to change window title')
	SetMaxMemory($processHandle)
	Return GetWindowHandle()
EndFunc


;~ Scan patterns for Guild Wars game client.
Func ScanGWBasePatterns()
	Local $gwBaseAddress = ScanForProcess()
	$asm_injection_size = 0
	$asm_code_offset = 0
	$asm_injection_string = ''

	_('ScanBasePointer:')
	AddPatternToInjection('506A0F6A00FF35')
	_('ScanAgentBase:')
	AddPatternToInjection('FF501083C6043BF775E2')
	_('ScanAgentBasePointer:')
	AddPatternToInjection('FF501083C6043BF775E28B35')
	_('ScanAgentArray:')
	AddPatternToInjection('8B0C9085C97419')
	_('ScanCurrentTarget:')
	AddPatternToInjection('83C4085F8BE55DC3CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC55')

	_('ScanMyID:')
	AddPatternToInjection('83EC08568BF13B15')
	_('ScanEngine:')
	AddPatternToInjection('568B3085F67478EB038D4900D9460C')
	_('ScanRenderFunc:')
	AddPatternToInjection('F6C401741C68')
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
	AddPatternToInjection('568B750889165E')
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
	AddPatternToInjection('8B7508578BF983FE09750C6877')
	_('ScanActionBase:')
	AddPatternToInjection('8D1C87899DF4')
	_('ScanSkillBase:')
	AddPatternToInjection('69C6A40000005E')
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
	AddPatternToInjection('8D4DFC51576A5450')
	_('ScanSleep:')
	AddPatternToInjection('6A0057FF15D8408A006860EA0000')
	_('ScanSalvageFunction:')
	AddPatternToInjection('33C58945FC8B45088945F08B450C8945F48B45108945F88D45EC506A10C745EC77')
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
	AddPatternToInjection('85c07417ff7508e8')
	_('ScanAreaInfo:')
	AddPatternToInjection('6BC67C5E05')
	_('ScanAttributeInfo:')
	AddPatternToInjection('BA3300000089088d4004')
	_('ScanWorldConst:')
	AddPatternToInjection('8D0476C1E00405')
	_('ScanEnterMissionFunction:')
	AddPatternToInjection('A900001000743A')


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

	Local $newHeader = False
	Local $fixedHeader = $gwBaseAddress + 0x9E4000
	Local $processHandle = GetProcessHandle()
	Local $headerBytes = MemoryRead($processHandle, $fixedHeader, 'byte[8]')

	; Check if the scan memory address is empty (no previous injection)
	If $headerBytes == StringToBinary($GWA2_REFORGED_HEADER_STRING) Then
	$memory_interface_header = $fixedHeader
	ElseIf $headerBytes == 0 Then
		$memory_interface_header = $fixedHeader
		$newHeader = True
	Else
		$memory_interface_header = ScanMemoryForPattern($processHandle, $GWA2_REFORGED_HEADER_STRING)
		If $memory_interface_header = 0 Then
			; Allocate a new block of memory for the scan routine
			$memory_interface_header = SafeDllCall13($kernel_handle, 'ptr', 'VirtualAllocEx', 'handle', $processHandle, 'ptr', 0, 'ulong_ptr', $GWA2_REFORGED_HEADER_SIZE, 'dword', 0x1000, 'dword', 0x40)
			; Get the allocated memory address
			$memory_interface_header = $memory_interface_header[0]
			If $memory_interface_header = 0 Then Return SetError(1, 0, 0)
			$newHeader = True
		EndIf
	EndIf

	If $newHeader Then
		; Write the allocated memory address to the scan memory location
		WriteBinary($processHandle, $GWA2_REFORGED_HEADER_HEXA, $memory_interface_header)
		MemoryWrite($processHandle, $memory_interface_header + $GWA2_REFORGED_OFFSET_SCAN_ADDRESS, 0)
		MemoryWrite($processHandle, $memory_interface_header + $GWA2_REFORGED_OFFSET_COMMAND_ADDRESS, 0)
	EndIf

	Local $allocationScan = False
	Local $memoryInterface = MemoryRead($processHandle, $memory_interface_header + $GWA2_REFORGED_OFFSET_SCAN_ADDRESS, 'ptr')

	If $memoryInterface = 0 Then
		; Allocate a new block of memory for the scan routine
		$memoryInterface = SafeDllCall13($kernel_handle, 'ptr', 'VirtualAllocEx', 'handle', $processHandle, 'ptr', 0, 'ulong_ptr', $asm_injection_size, 'dword', 0x1000, 'dword', 0x40)
		; Get the allocated memory address
		$memoryInterface = $memoryInterface[0]
		If $memoryInterface = 0 Then Return SetError(2, 0, 0)

		MemoryWrite($processHandle, $memory_interface_header + $GWA2_REFORGED_OFFSET_SCAN_ADDRESS, $memoryInterface)
		$allocationScan = True
	EndIf

	; Complete the assembly code for the scan routine
	CompleteASMCode($memoryInterface)

	If $allocationScan Then
		; Write the assembly code to the allocated memory address
		WriteBinary($processHandle, $asm_injection_string, $memoryInterface + $asm_code_offset)

		; Create a new thread in the target process to execute the scan routine
		Local $thread = SafeDllCall17($kernel_handle, 'int', 'CreateRemoteThread', 'int', $processHandle, 'ptr', 0, 'int', 0, 'int', GetLabel('ScanProc'), 'ptr', 0, 'int', 0, 'int', 0)
		; Get the thread ID
		$thread = $thread[0]

		; Wait for the thread to finish executing
		Local $result
		; Wait until the thread is no longer waiting (258 is the WAIT_TIMEOUT constant)
		Do
			; Wait for up to 50ms for the thread to finish
			$result = SafeDllCall7($kernel_handle, 'int', 'WaitForSingleObject', 'int', $thread, 'int', 50)
		Until $result[0] <> 258

		SafeDllCall5($kernel_handle, 'int', 'CloseHandle', 'int', $thread)
	EndIf
EndFunc


;~ Find process by scanning memory
;~ This process is located at 0x00401000, i.e.: shifted of 0x1000 from real start of the process. Why do we start here ? PE Headers ?
Func ScanForProcess()
	Local $scannedMemory = ScanMemoryForPattern(GetProcessHandle(), BinaryToString('0x558BEC83EC105356578B7D0833F63BFE'))
	Return $scannedMemory[0]
EndFunc


;~ Adds a new pattern to the ASM injection string
Func AddPatternToInjection($pattern)
	Local $size = Int(0.5 * StringLen($pattern))
	$asm_injection_string &= '00000000' & SwapEndian(Hex($size, 8)) & '00000000' & $pattern
	$asm_injection_size += $size + 12
	For $i = 1 To 68 - $size
		$asm_injection_size += 1
		$asm_injection_string &= '00'
	Next
EndFunc


;~ Retrieves the scanned memory address for a specific label and offset (internal use)
Func GetScannedAddress($label, $offset)
	Local $processHandle = GetProcessHandle()
	Return MemoryRead($processHandle, GetLabel($label) + 8) - MemoryRead($processHandle, GetLabel($label) + 4) + $offset
EndFunc
#EndRegion Initialisation


#Region Other Functions
;~ Internal use only.
Func Enqueue($ptr, $size)
	SafeDllCall13($kernel_handle, 'int', 'WriteProcessMemory', 'int', GetProcessHandle(), 'int', 256 * $queue_counter + $queue_base_address, 'ptr', $ptr, 'int', $size, 'int', 0)
	$queue_counter = Mod($queue_counter + 1, $queue_size)
EndFunc


;~ Internal use only.
Func SendPacket($size, $header, $param1 = 0, $param2 = 0, $param3 = 0, $param4 = 0, $param5 = 0, $param6 = 0, $param7 = 0, $param8 = 0, $param9 = 0, $param10 = 0)
	DllStructSetData($PACKET_STRUCT, 2, $size)
	DllStructSetData($PACKET_STRUCT, 3, $header)
	DllStructSetData($PACKET_STRUCT, 4, $param1)
	DllStructSetData($PACKET_STRUCT, 5, $param2)
	DllStructSetData($PACKET_STRUCT, 6, $param3)
	DllStructSetData($PACKET_STRUCT, 7, $param4)
	DllStructSetData($PACKET_STRUCT, 8, $param5)
	DllStructSetData($PACKET_STRUCT, 9, $param6)
	DllStructSetData($PACKET_STRUCT, 10, $param7)
	DllStructSetData($PACKET_STRUCT, 11, $param8)
	DllStructSetData($PACKET_STRUCT, 12, $param9)
	DllStructSetData($PACKET_STRUCT, 13, $param10)
	Enqueue($PACKET_STRUCT_PTR, 52)
	Return True
EndFunc


;~ Internal use only.
Func PerformAction($action, $flag = $CONTROL_TYPE_ACTIVATE)
	If GetAgentExists(GetMyID()) Then
		DllStructSetData($ACTION_STRUCT, 2, $action)
		DllStructSetData($ACTION_STRUCT, 3, $flag)
		Enqueue($ACTION_STRUCT_PTR, 12)
		Return True
	EndIf
	Return False
EndFunc
#EndRegion Other Functions


#Region Callback
;~ Controls Event System.
Func SetEvent($skillActivate = '', $skillCancel = '', $skillComplete = '', $chatReceive = '', $loadFinished = '')
	Local $processHandle = GetProcessHandle()
	If Not $use_event_system Then Return
	If $skillActivate <> '' Then
		WriteDetour('SkillLogStart', 'SkillLogProc')
	Else
		$asm_injection_string = ''
		_('inc eax')
		_('mov dword[esi+10],eax')
		_('pop esi')
		WriteBinary($processHandle, $asm_injection_string, GetLabel('SkillLogStart'))
	EndIf

	If $skillCancel <> '' Then
		WriteDetour('SkillCancelLogStart', 'SkillCancelLogProc')
	Else
		$asm_injection_string = ''
		_('push 0')
		_('push 42')
		_('mov ecx,esi')
		WriteBinary($processHandle, $asm_injection_string, GetLabel('SkillCancelLogStart'))
	EndIf

	If $skillComplete <> '' Then
		WriteDetour('SkillCompleteLogStart', 'SkillCompleteLogProc')
	Else
		$asm_injection_string = ''
		_('mov eax,dword[edi+4]')
		_('test eax,eax')
		WriteBinary($processHandle, $asm_injection_string, GetLabel('SkillCompleteLogStart'))
	EndIf

	If $chatReceive <> '' Then
		WriteDetour('ChatLogStart', 'ChatLogProc')
	Else
		$asm_injection_string = ''
		_('add edi,E')
		_('cmp eax,B')
		WriteBinary($processHandle, $asm_injection_string, GetLabel('ChatLogStart'))
	EndIf
EndFunc
#EndRegion Callback


#Region Modification
;~ Internal use only.
Func ModifyMemory()
	$asm_injection_size = 0
	$asm_code_offset = 0
	$asm_injection_string = ''
	CreateData()
	CreateMain()
	CreateTraderHook()
	CreateStringLog()
	CreateRenderingMod()
	CreateCommands()
	CreateUICommands()
	CreateDialogHook()
	Local $allocationCommand = False
	Local $processHandle = GetProcessHandle()
	Local $memoryInterface = MemoryRead($processHandle, $memory_interface_header + $GWA2_REFORGED_OFFSET_COMMAND_ADDRESS, 'ptr')
	If $memoryInterface = 0 Then
		Local $memoryInterface = SafeDllCall13($kernel_handle, 'ptr', 'VirtualAllocEx', _
			'handle', $processHandle, _
			'ptr', 0, _
			'ulong_ptr', $asm_injection_size, _
			'dword', 0x1000, _
			'dword', 0x40)
		$memoryInterface = $memoryInterface[0]
		MemoryWrite($processHandle, $memory_interface_header + $GWA2_REFORGED_OFFSET_COMMAND_ADDRESS, $memoryInterface)
		$allocationCommand = True
	EndIf

	CompleteASMCode($memoryInterface)

	If $allocationCommand Then
		WriteBinary($processHandle, $asm_injection_string, $memoryInterface + $asm_code_offset)
		MemoryWrite($processHandle, GetLabel('QueuePtr'), GetLabel('QueueBase'))
		If IsDeclared('g_b_Write') Then Extend_Write()

		WriteDetour('MainStart', 'MainProc')
		WriteDetour('TraderStart', 'TraderProc')
		WriteDetour('RenderingMod', 'RenderingModProc')
		WriteDetour('LoadFinishedStart', 'LoadFinishedProc')
		; FIXME: add this back
		WriteDetour('TradePartnerStart', 'TradePartnerProc')
		If IsDeclared('g_b_AssemblerWriteDetour') Then Extend_AssemblerWriteDetour()
	EndIf
EndFunc


;~ Internal use only.
Func WriteDetour($from, $to)
	WriteBinary(GetProcessHandle(),'E9' & SwapEndian(Hex(GetLabel($to) - GetLabel($from) - 5)), GetLabel($from))
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

	_('QueueBase/' & 256 * GetLabel('QueueSize'))
	_('TargetLogBase/' & 4 * GetLabel('TargetLogSize'))
	_('SkillLogBase/' & 16 * GetLabel('SkillLogSize'))
	_('StringLogBase/' & 256 * GetLabel('StringLogSize'))
	_('ChatLogBase/' & 512 * GetLabel('ChatLogSize'))

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
	_('ljmp TraderReturn')
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
	_('add ecx,A8')
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


;~ Create UI commands like EnterMission
Func CreateUICommands()
	_('CommandEnterMission:')
	_('push 1')
	_('call EnterMissionFunction')
	_('add esp,4')
	_('ljmp CommandReturn')
EndFunc
#EndRegion Modification


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
			$asm_injection_size += 0.5 * StringLen($opCode)
			$asm_injection_string &= $opCode
		Case StringLeft($asm, 3) = 'jb '
			$asm_injection_size += 2
			$asm_injection_string &= '72(' & StringRight($asm, StringLen($asm) - 3) & ')'
		Case StringLeft($asm, 3) = 'je '
			$asm_injection_size += 2
			$asm_injection_string &= '74(' & StringRight($asm, StringLen($asm) - 3) & ')'
		Case StringRegExp($asm, 'cmp ebx,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asm_injection_size += 6
			$asm_injection_string &= '81FB[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'cmp edx,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asm_injection_size += 6
			$asm_injection_string &= '81FA[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRight($asm, 1) = ':'
			SetLabel('Label_' & StringLeft($asm, StringLen($asm) - 1), $asm_injection_size)
		Case StringInStr($asm, '/') > 0
			SetLabel('Label_' & StringLeft($asm, StringInStr($asm, '/') - 1), $asm_injection_size)
			Local $offset = StringRight($asm, StringLen($asm) - StringInStr($asm, '/'))
			$asm_injection_size += $offset
			$asm_code_offset += $offset
		Case StringLeft($asm, 5) = 'nop x'
			$buffer = Int(Number(StringTrimLeft($asm, 5)))
			$asm_injection_size += $buffer
			For $i = 1 To $buffer
				$asm_injection_string &= '90'
			Next
		Case StringLeft($asm, 5) = 'ljmp '
			$asm_injection_size += 5
			$asm_injection_string &= 'E9{' & StringRight($asm, StringLen($asm) - 5) & '}'
		Case StringLeft($asm, 5) = 'ljne '
			$asm_injection_size += 6
			$asm_injection_string &= '0F85{' & StringRight($asm, StringLen($asm) - 5) & '}'
		Case StringLeft($asm, 4) = 'jmp ' And StringLen($asm) > 7
			$asm_injection_size += 2
			$asm_injection_string &= 'EB(' & StringRight($asm, StringLen($asm) - 4) & ')'
		Case StringLeft($asm, 4) = 'jae '
			$asm_injection_size += 2
			$asm_injection_string &= '73(' & StringRight($asm, StringLen($asm) - 4) & ')'
		Case StringLeft($asm, 3) = 'jz '
			$asm_injection_size += 2
			$asm_injection_string &= '74(' & StringRight($asm, StringLen($asm) - 3) & ')'
		Case StringLeft($asm, 4) = 'jnz '
			$asm_injection_size += 2
			$asm_injection_string &= '75(' & StringRight($asm, StringLen($asm) - 4) & ')'
		Case StringLeft($asm, 4) = 'jbe '
			$asm_injection_size += 2
			$asm_injection_string &= '76(' & StringRight($asm, StringLen($asm) - 4) & ')'
		Case StringLeft($asm, 3) = 'ja '
			$asm_injection_size += 2
			$asm_injection_string &= '77(' & StringRight($asm, StringLen($asm) - 3) & ')'
		Case StringLeft($asm, 3) = 'jl '
			$asm_injection_size += 2
			$asm_injection_string &= '7C(' & StringRight($asm, StringLen($asm) - 3) & ')'
		Case StringLeft($asm, 4) = 'jge '
			$asm_injection_size += 2
			$asm_injection_string &= '7D(' & StringRight($asm, StringLen($asm) - 4) & ')'
		Case StringLeft($asm, 4) = 'jle '
			$asm_injection_size += 2
			$asm_injection_string &= '7E(' & StringRight($asm, StringLen($asm) - 4) & ')'
		Case StringRegExp($asm, 'mov eax,dword[[][a-z,A-Z]{4,}[]]')
			$asm_injection_size += 5
			$asm_injection_string &= 'A1[' & StringMid($asm, 15, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'mov ebx,dword[[][a-z,A-Z]{4,}[]]')
			$asm_injection_size += 6
			$asm_injection_string &= '8B1D[' & StringMid($asm, 15, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'mov ecx,dword[[][a-z,A-Z]{4,}[]]')
			$asm_injection_size += 6
			$asm_injection_string &= '8B0D[' & StringMid($asm, 15, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'mov edx,dword[[][a-z,A-Z]{4,}[]]')
			$asm_injection_size += 6
			$asm_injection_string &= '8B15[' & StringMid($asm, 15, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'mov esi,dword[[][a-z,A-Z]{4,}[]]')
			$asm_injection_size += 6
			$asm_injection_string &= '8B35[' & StringMid($asm, 15, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'mov edi,dword[[][a-z,A-Z]{4,}[]]')
			$asm_injection_size += 6
			$asm_injection_string &= '8B3D[' & StringMid($asm, 15, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'cmp ebx,dword\[[a-z,A-Z]{4,}\]')
			$asm_injection_size += 6
			$asm_injection_string &= '3B1D[' & StringMid($asm, 15, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'lea eax,dword[[]ecx[*]8[+][a-z,A-Z]{4,}[]]')
			$asm_injection_size += 7
			$asm_injection_string &= '8D04CD[' & StringMid($asm, 21, StringLen($asm) - 21) & ']'
		Case StringRegExp($asm, 'lea edi,dword\[edx\+[a-z,A-Z]{4,}\]')
			$asm_injection_size += 7
			$asm_injection_string &= '8D3C15[' & StringMid($asm, 19, StringLen($asm) - 19) & ']'
		Case StringRegExp($asm, 'cmp dword[[][a-z,A-Z]{4,}[]],[-[:xdigit:]]')
			$buffer = StringInStr($asm, ',')
			$buffer = ASMNumber(StringMid($asm, $buffer + 1), True)
			If @extended Then
				$asm_injection_size += 7
				$asm_injection_string &= '833D[' & StringMid($asm, 11, StringInStr($asm, ',') - 12) & ']' & $buffer
			Else
				$asm_injection_size += 10
				$asm_injection_string &= '813D[' & StringMid($asm, 11, StringInStr($asm, ',') - 12) & ']' & $buffer
			EndIf
		Case StringRegExp($asm, 'cmp ecx,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asm_injection_size += 6
			$asm_injection_string &= '81F9[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'cmp ebx,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asm_injection_size += 6
			$asm_injection_string &= '81FB[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'cmp eax,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asm_injection_size += 5
			$asm_injection_string &= '3D[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'add eax,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asm_injection_size += 5
			$asm_injection_string &= '05[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'mov eax,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asm_injection_size += 5
			$asm_injection_string &= 'B8[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'mov ebx,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asm_injection_size += 5
			$asm_injection_string &= 'BB[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'mov ecx,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asm_injection_size += 5
			$asm_injection_string &= 'B9[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'mov esi,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asm_injection_size += 5
			$asm_injection_string &= 'BE[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'mov edi,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asm_injection_size += 5
			$asm_injection_string &= 'BF[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'mov edx,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asm_injection_size += 5
			$asm_injection_string &= 'BA[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'mov dword[[][a-z,A-Z]{4,}[]],ecx')
			$asm_injection_size += 6
			$asm_injection_string &= '890D[' & StringMid($asm, 11, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'fstp dword[[][a-z,A-Z]{4,}[]]')
			$asm_injection_size += 6
			$asm_injection_string &= 'D91D[' & StringMid($asm, 12, StringLen($asm) - 12) & ']'
		Case StringRegExp($asm, 'mov dword[[][a-z,A-Z]{4,}[]],edx')
			$asm_injection_size += 6
			$asm_injection_string &= '8915[' & StringMid($asm, 11, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'mov dword[[][a-z,A-Z]{4,}[]],eax')
			$asm_injection_size += 5
			$asm_injection_string &= 'A3[' & StringMid($asm, 11, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'lea eax,dword[[]edx[*]4[+][a-z,A-Z]{4,}[]]')
			$asm_injection_size += 7
			$asm_injection_string &= '8D0495[' & StringMid($asm, 21, StringLen($asm) - 21) & ']'
		Case StringRegExp($asm, 'mov eax,dword[[]ecx[*]4[+][a-z,A-Z]{4,}[]]')
			$asm_injection_size += 7
			$asm_injection_string &= '8B048D[' & StringMid($asm, 21, StringLen($asm) - 21) & ']'
		Case StringRegExp($asm, 'mov ecx,dword[[]ecx[*]4[+][a-z,A-Z]{4,}[]]')
			$asm_injection_size += 7
			$asm_injection_string &= '8B0C8D[' & StringMid($asm, 21, StringLen($asm) - 21) & ']'
		Case StringRegExp($asm, 'push dword[[][a-z,A-Z]{4,}[]]')
			$asm_injection_size += 6
			$asm_injection_string &= 'FF35[' & StringMid($asm, 12, StringLen($asm) - 12) & ']'
		Case StringRegExp($asm, 'push [a-z,A-Z]{4,}\z')
			$asm_injection_size += 5
			$asm_injection_string &= '68[' & StringMid($asm, 6, StringLen($asm) - 5) & ']'
		Case StringRegExp($asm, 'call dword[[][a-z,A-Z]{4,}[]]')
			$asm_injection_size += 6
			$asm_injection_string &= 'FF15[' & StringMid($asm, 12, StringLen($asm) - 12) & ']'
		Case StringLeft($asm, 5) = 'call ' And StringLen($asm) > 8
			$asm_injection_size += 5
			$asm_injection_string &= 'E8{' & StringMid($asm, 6, StringLen($asm) - 5) & '}'
		Case StringRegExp($asm, 'mov dword\[[a-z,A-Z]{4,}\],[-[:xdigit:]]{1,8}\z')
			$buffer = StringInStr($asm, ',')
			$asm_injection_size += 10
			$asm_injection_string &= 'C705[' & StringMid($asm, 11, $buffer - 12) & ']' & ASMNumber(StringMid($asm, $buffer + 1))
		Case StringRegExp($asm, 'push [-[:xdigit:]]{1,8}\z')
			$buffer = ASMNumber(StringMid($asm, 6), True)
			If @extended Then
				$asm_injection_size += 2
				$asm_injection_string &= '6A' & $buffer
			Else
				$asm_injection_size += 5
				$asm_injection_string &= '68' & $buffer
			EndIf
		Case StringRegExp($asm, 'mov eax,[-[:xdigit:]]{1,8}\z')
			$asm_injection_size += 5
			$asm_injection_string &= 'B8' & ASMNumber(StringMid($asm, 9))
		Case StringRegExp($asm, 'mov ebx,[-[:xdigit:]]{1,8}\z')
			$asm_injection_size += 5
			$asm_injection_string &= 'BB' & ASMNumber(StringMid($asm, 9))
		Case StringRegExp($asm, 'mov ecx,[-[:xdigit:]]{1,8}\z')
			$asm_injection_size += 5
			$asm_injection_string &= 'B9' & ASMNumber(StringMid($asm, 9))
		Case StringRegExp($asm, 'mov edx,[-[:xdigit:]]{1,8}\z')
			$asm_injection_size += 5
			$asm_injection_string &= 'BA' & ASMNumber(StringMid($asm, 9))
		Case StringRegExp($asm, 'add eax,[-[:xdigit:]]{1,8}\z')
			$buffer = ASMNumber(StringMid($asm, 9), True)
			If @extended Then
				$asm_injection_size += 3
				$asm_injection_string &= '83C0' & $buffer
			Else
				$asm_injection_size += 5
				$asm_injection_string &= '05' & $buffer
			EndIf
		Case StringRegExp($asm, 'add ebx,[-[:xdigit:]]{1,8}\z')
			$buffer = ASMNumber(StringMid($asm, 9), True)
			If @extended Then
				$asm_injection_size += 3
				$asm_injection_string &= '83C3' & $buffer
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '81C3' & $buffer
			EndIf
		Case StringRegExp($asm, 'add ecx,[-[:xdigit:]]{1,8}\z')
			$buffer = ASMNumber(StringMid($asm, 9), True)
			If @extended Then
				$asm_injection_size += 3
				$asm_injection_string &= '83C1' & $buffer
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '81C1' & $buffer
			EndIf
		Case StringRegExp($asm, 'add edx,[-[:xdigit:]]{1,8}\z')
			$buffer = ASMNumber(StringMid($asm, 9), True)
			If @extended Then
				$asm_injection_size += 3
				$asm_injection_string &= '83C2' & $buffer
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '81C2' & $buffer
			EndIf
		Case StringRegExp($asm, 'add edi,[-[:xdigit:]]{1,8}\z')
			$buffer = ASMNumber(StringMid($asm, 9), True)
			If @extended Then
				$asm_injection_size += 3
				$asm_injection_string &= '83C7' & $buffer
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '81C7' & $buffer
			EndIf
		Case StringRegExp($asm, 'add esi,[-[:xdigit:]]{1,8}\z')
			$buffer = ASMNumber(StringMid($asm, 9), True)
			If @extended Then
				$asm_injection_size += 3
				$asm_injection_string &= '83C6' & $buffer
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '81C6' & $buffer
			EndIf
		Case StringRegExp($asm, 'add esp,[-[:xdigit:]]{1,8}\z')
			$buffer = ASMNumber(StringMid($asm, 9), True)
			If @extended Then
				$asm_injection_size += 3
				$asm_injection_string &= '83C4' & $buffer
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '81C4' & $buffer
			EndIf
		Case StringRegExp($asm, 'cmp ebx,[-[:xdigit:]]{1,8}\z')
			$buffer = ASMNumber(StringMid($asm, 9), True)
			If @extended Then
				$asm_injection_size += 3
				$asm_injection_string &= '83FB' & $buffer
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '81FB' & $buffer
			EndIf
		Case StringLeft($asm, 8) = 'cmp ecx,' And StringLen($asm) > 10
			Local $opCode = '81F9' & StringMid($asm, 9)
			$asm_injection_size += 0.5 * StringLen($opCode)
			$asm_injection_string &= $opCode
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
					$opCode = '80FC00'
				Case Else
					MsgBox(0x0, 'ASM', 'Could not assemble: ' & $asm)
					Exit
			EndSwitch
			$asm_injection_size += 0.5 * StringLen($opCode)
			$asm_injection_string &= $opCode
	EndSelect
EndFunc


;~ Internal use only.
Func CompleteASMCode($memoryInterface)
	Local $inExpression = False
	Local $expression
	Local $tempValueASM = $asm_injection_string
	Local $currentOffset = Dec(Hex($memoryInterface)) + $asm_code_offset
	Local $token

	Local $labelsKeys = MapKeys($labels_map)
	For $key In $labelsKeys
		If StringLeft($key, 6) = 'Label_' Then
			Local $value = $labels_map[$key]
			Local $newKey = StringTrimLeft($key, 6)
			$labels_map[$newKey] = $memoryInterface + $value
			MapRemove($labels_map, $key)
		EndIf
	Next

	$asm_injection_string = ''
	For $i = 1 To StringLen($tempValueASM)
		$token = StringMid($tempValueASM, $i, 1)
		Switch $token
			Case '(', '[', '{'
				$inExpression = True
			Case ')'
				$asm_injection_string &= Hex(GetLabel($expression) - Int($currentOffset) - 1, 2)
				$currentOffset += 1
				$inExpression = False
				$expression = ''
			Case ']'
				$asm_injection_string &= SwapEndian(Hex(GetLabel($expression), 8))
				$currentOffset += 4
				$inExpression = False
				$expression = ''
			Case '}'
				$asm_injection_string &= SwapEndian(Hex(GetLabel($expression) - Int($currentOffset) - 4, 8))
				$currentOffset += 4
				$inExpression = False
				$expression = ''
			Case Else
				If $inExpression Then
					$expression &= $token
				Else
					$asm_injection_string &= $token
					$currentOffset += 0.5
				EndIf
		EndSwitch
	Next
EndFunc


;~ Retrieves the label associated with the specified key (internal use only)
Func GetLabel($key)
	Return $labels_map[$key] <> Null ? $labels_map[$key] : -1
EndFunc


;~ Sets the label for the specified key (internal use only)
Func SetLabel($key, $value)
	$labels_map[$key] = $value
EndFunc
#EndRegion Assembler



#Region Client Management Functions
;~ Close all handles once bot stops
Func CloseAllHandles()
	For $index = 1 To $game_clients[0][0]
		If $game_clients[$index][0] <> -1 Then SafeDllCall5($kernel_handle, 'int', 'CloseHandle', 'int', $game_clients[$index][1])
	Next
	If $kernel_handle Then DllClose($kernel_handle)
EndFunc


;~ Finds index in $game_clients by PID
Func FindClientIndexByPID($pid)
	For $i = 1 To $game_clients[0][0]
		If $game_clients[$i][0] = $pid Then Return $i
	Next
	Return -1
EndFunc


;~ Adds a new client entry to $game_clients
Func AddClient($pid, $processHandle, $windowHandle, $characterName)
	$game_clients[0][0] += 1
	Local $newIndex = $game_clients[0][0]
	If $newIndex > UBound($game_clients) - 1 Then
		Error('GameClients array is full. Cannot add new client. Restart the bot.')
	EndIf
	$game_clients[$newIndex][0] = $pid
	$game_clients[$newIndex][1] = $processHandle
	$game_clients[$newIndex][2] = $windowHandle
	$game_clients[$newIndex][3] = $characterName
EndFunc


;~ Select the client -PID, process handle, window handle and character- to use for the bot
Func SelectClient($index)
	If $index > 0 And $index <= $game_clients[0][0] Then
		$selected_client_index = $index
		Return True
	EndIf
	Return False
EndFunc


;~ Finds index in $game_clients by character name
Func FindClientIndexByCharacterName($characterName)
	For $i = 1 To $game_clients[0][0]
		If $game_clients[$i][3] = $characterName Then Return $i
	Next
	Return -1
EndFunc


;~ Return currently chosen process ID
Func GetPID()
	If $selected_client_index > 0 And $selected_client_index <= $game_clients[0][0] Then
		Return $game_clients[$selected_client_index][0]
	EndIf
	Return
EndFunc


;~ Return currently chosen process handle
Func GetProcessHandle()
	If $selected_client_index > 0 And $selected_client_index <= $game_clients[0][0] Then
		Return $game_clients[$selected_client_index][1]
	EndIf
	Return
EndFunc


;~ Return currently chosen window handle
Func GetWindowHandle()
	If $selected_client_index > 0 And $selected_client_index <= $game_clients[0][0] Then
		Return $game_clients[$selected_client_index][2]
	EndIf
	Return
EndFunc


;~ Return currently chosen character name
Func GetCharacterName()
	If $selected_client_index > 0 And $selected_client_index <= $game_clients[0][0] Then
		Return $game_clients[$selected_client_index][3]
	EndIf
	Return
EndFunc
#EndRegion Client Management Functions