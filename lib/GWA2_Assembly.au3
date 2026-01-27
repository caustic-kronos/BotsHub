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
Global Const $AGENT_STRUCT_TEMPLATE = 'ptr vtable;dword unknown008[4];dword Timer;dword Timer2;ptr NextAgent;dword unknown032[3];long ID;float Z;float Width1;float Height1;float Width2;float Height2;float Width3;float Height3;float Rotation;float RotationCos;float RotationSin;dword NameProperties;dword Ground;dword unknown096;float TerrainNormalX;float TerrainNormalY;dword TerrainNormalZ;byte unknown112[4];float X;float Y;dword Plane;byte unknown128[4];float NameTagX;float NameTagY;float NameTagZ;short VisualEffects;short unknown146;dword unknown148[2];long Type;float MoveX;float MoveY;dword unknown168;float RotationCos2;float RotationSin2;dword unknown180[4];long Owner;dword ItemID;dword ExtraType;dword GadgetID;dword unknown212[3];float AnimationType;dword unknown228[2];float AttackSpeed;float AttackSpeedModifier;short ModelID;short AgentModelType;dword TransmogNpcID;ptr Equipment;dword unknown256;dword unknown260;ptr Tags;short unknown268;byte Primary;byte Secondary;byte Level;byte Team;byte unknown274[2];dword unknown276;float EnergyRegen;float Overcast;float EnergyPercent;dword MaxEnergy;dword unknown296;float HPPips;dword unknown304;float HealthPercent;dword MaxHealth;dword Effects;dword unknown320;byte Hex;byte unknown325[19];dword ModelState;dword TypeMap;dword unknown352[4];dword InSpiritRange;dword VisibleEffects;dword VisibleEffectsID;dword VisibleEffectsHasEnded;dword unknown384;dword LoginNumber;float AnimationSpeed;dword AnimationCode;dword AnimationID;byte unknown404[32];byte LastStrike;byte Allegiance;short WeaponType;short Skill;short unknown442;byte WeaponItemType;byte OffhandItemType;short WeaponItemId;short OffhandItemID'
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

Global Const $USE_SKILL_STRUCT = SafeDllStructCreate('ptr useSkillCommandPtr;dword skillSlot;dword targetID;dword callTarget;bool')
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

Global Const $CANCEL_HERO_SKILL_STRUCT = DllStructCreate('ptr;dword;dword')
Global Const $CANCEL_HERO_SKILL_STRUCT_PTR = DllStructGetPtr($CANCEL_HERO_SKILL_STRUCT)

Global Const $TRADE_INITIATE_STRUCT = DllStructCreate('ptr;dword;dword')
Global Const $TRADE_CANCEL_STRUCT = DllStructCreate('ptr')
Global Const $TRADE_ACCEPT_STRUCT = DllStructCreate('ptr')
Global Const $TRADE_SUBMIT_STRUCT = DllStructCreate('ptr;dword')
Global Const $TRADE_OFFER_ITEM_STRUCT = DllStructCreate('ptr;dword;dword')

; UI
Global Const $DIALOG_STRUCT = DllStructCreate('ptr;dword')
Global Const $OPEN_CHEST_STRUCT = DllStructCreate('ptr;dword')
Global Const $MOVE_MAP_STRUCT = DllStructCreate('ptr;dword;dword;dword;dword;dword')
Global Const $SET_DIFFICULTY_STRUCT = DllStructCreate('ptr;dword')
Global Const $ENTER_MISSION_STRUCT = DllStructCreate('ptr;dword')
Global Const $ENTER_MISSION_STRUCT_PTR = DllStructGetPtr($ENTER_MISSION_STRUCT)
Global Const $ACTIVE_QUEST_STRUCT = DllStructCreate('ptr;dword')

Global Const $FLAG_HERO_STRUCT = DllStructCreate('ptr;dword;dword;dword;dword')
Global Const $FLAG_ALL_STRUCT = DllStructCreate('ptr;dword;dword;dword')
Global Const $SET_HERO_BEHAVIOUR_STRUCT = DllStructCreate('ptr;dword;dword')
Global Const $DROP_HERO_BUNDLE_STRUCT = DllStructCreate('ptr;dword')
Global Const $LOCK_HERO_TARGET_STRUCT = DllStructCreate('ptr;dword;dword')
Global Const $TOGGLE_HERO_SKILL_STATE = DllStructCreate('ptr;dword;dword')
Global Const $EQUIP_ITEM_STRUCT = DllStructCreate('ptr;dword;dword;dword')
Global Const $EQUIP_ITEM_STRUCT_PTR = DllStructGetPtr($EQUIP_ITEM_STRUCT)

; Party
Global Const $ADD_PLAYER_STRUCT = DllStructCreate('ptr;dword')
Global Const $KICK_PLAYER_STRUCT = DllStructCreate('ptr;dword')
Global Const $KICK_INVITED_PLAYER_STRUCT = DllStructCreate('ptr;dword')
Global Const $REJECT_INVITATION_STRUCT = DllStructCreate('ptr;dword')
Global Const $ACCEPT_INVITATION_STRUCT = DllStructCreate('ptr;dword')
Global Const $LEAVE_GROUP_STRUCT = DllStructCreate('ptr;dword')
Global Const $ADD_HERO_STRUCT = DllStructCreate('ptr;dword')
Global Const $KICK_HERO_STRUCT = DllStructCreate('ptr;dword')
Global Const $ADD_NPC_STRUCT = DllStructCreate('ptr;dword')
Global Const $KICK_NPC_STRUCT = DllStructCreate('ptr;dword')
#EndRegion GWA2 Structures
#EndRegion Constants


; Windows and process handles
Global $kernel_handle = DllOpen('kernel32.dll')
If Not $kernel_handle Then
	MsgBox(16, 'Error', 'Failed to open kernel32.dll')
	Exit
Else
	OnAutoItExitRegister('CloseAllHandles')
EndIf

; Each gameClient will be a 4-elements array: [0] = PID, [1] = process handle (or 0 if invalidated), [2] = window handle, [3] = character name
; Caution, first element of this 2D array $game_clients[0][0] is considered a count of currently inserted elements (like in AutoIT ProcessList() function), hence $MAX_CLIENTS+1
Global $game_clients[$MAX_CLIENTS+1][4]
Global $selected_client_index = -1

; Memory interaction
;Global $base_address = 0x00C50000
Global $memory_interface_header = 0
Global $asm_injection_string, $asm_injection_size, $asm_code_offset
Global $trade_hack_address
Global $labels_map[]

; [labelName, bytePattern, resultOffset, patternType, assertSourceFile, assertMessage]
Global $scan_patterns[57][6]
Global $scan_patterns_count = 0
; [file, message]
Global $assertions_patterns_cache[]
Global $scan_results[]

; PE Sections
Global Const $PE_TEXT_SECTION = 0
Global Const $PE_RDATA_SECTION = 1
Global Const $PE_DATA_SECTION = 2
Global Const $PE_RSRC_SECTION = 3
Global Const $PE_RELOC_SECTION = 4

; [section][0=start, 1=end]
Global $pe_sections_ranges[5][2]


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


;~ Scan, inject and initialize GWA2
Func InitializeGameClientForGWA2($changeTitle = True)
	; Populate scanner with patterns
	RegisterScanPatterns()
	; Resolve assertion scan patterns
	ResolveAssertionsPatterns()
	; Inject and scan for all patterns
	ExecutePatternScan()
	; Publish labels and global values
	MapScanResultsToLabels()
	; Modify memory
	ModifyMemory()
	; Initialize command structures
	InitializeCommandStructures()
	If $changeTitle Then WinSetTitle(GetWindowHandle(), '', 'Guild Wars - ' & GetCharacterName())
	If @error Then LogCriticalError('Failed to change window title')
	SetMaxMemory(GetProcessHandle())
	Return GetWindowHandle()
EndFunc


;~ Register all patterns that the scanner must find
Func RegisterScanPatterns()
	Debug('Registering scan patterns')
	$scan_patterns_count = 0
	; Core patterns
	AddScanPattern('BasePointer',				'506A0F6A00FF35',														0x8,	'ptr')
	AddScanPattern('Ping',						'568B750889165E',														-0x3,	'ptr')
	AddScanPattern('StatusCode',				'8945088D45086A04',														-0x10,	'ptr')
	AddScanPattern('PacketSend',				'C747540000000081E6',													-0x4F,	'func')
	AddScanPattern('PacketLocation',			'83C40433C08BE55DC3A1',													0xB,	'ptr')
	AddScanPattern('Action',					'8B7508578BF983FE09750C6877',											-0x3,	'func')
	AddScanPattern('ActionBase',				'8D1C87899DF4',															-0x3,	'ptr')
	AddScanPattern('Environment',				'6BC67C5E05',															0x6,	'ptr')
	AddScanPattern('PreGame',					'',																		'',		'ptr',	'P:\Code\Gw\Ui\UiPregame.cpp',			'!s_scene')
	AddScanPattern('FrameArray',				'',																		'',		'ptr',	'P:\Code\Engine\Frame\FrMsg.cpp',		'frame')
	; Skill patterns
	AddScanPattern('SkillBase',					'69C6A40000005E',														0x9,	'ptr')
	AddScanPattern('SkillTimer',				'FFD68B4DF08BD88B4708',													-0x3,	'ptr')
	AddScanPattern('UseSkill',					'85F6745B83FE1174',														-0x127,	'func')
	AddScanPattern('UseHeroSkill',				'BA02000000B954080000',													-0x59,	'func')
	; Friend patterns
	AddScanPattern('FriendList',				'',																		'',		'ptr',	'P:\Code\Gw\Friend\FriendApi.cpp',		'friendName && *friendName')
	AddScanPattern('PlayerStatus',				'83FE037740FF24B50000000033C0',											-0x25,	'func')
	AddScanPattern('AddFriend',					'8B751083FE037465',														-0x47,	'func')
	AddScanPattern('RemoveFriend',				'83F803741D83F8047418',													0x0,	'func')
	; Attribute patterns
	AddScanPattern('AttributeInfo',				'BA3300000089088d4004',													-0x3,	'ptr')
	AddScanPattern('IncreaseAttribute',			'8B7D088B702C8B1F3B9E00050000',											-0x5A,	'func')
	AddScanPattern('DecreaseAttribute',			'8B8AA800000089480C5DC3CC',												0x19,	'func')
	; Trade patterns
	AddScanPattern('Transaction',				'85FF741D8B4D14EB08',													-0x7E,	'func')
	AddScanPattern('BuyItemBase',				'D9EED9580CC74004',														0xF,	'ptr')
	AddScanPattern('RequestQuote',				'8B752083FE107614',														-0x34,	'func')
	AddScanPattern('Salvage',					'33C58945FC8B45088945F08B450C8945F48B45108945F88D45EC506A10C745EC77',	-0xA,	'func')
	AddScanPattern('SalvageGlobal',				'8B4A04538945F48B4208',													0x1,	'ptr')
	; Agent patterns
	AddScanPattern('AgentBase',					'8B0C9085C97419',														-0x3,	'ptr')
	AddScanPattern('ChangeTarget',				'3BDF0F95',																-0x89,	'func')
	AddScanPattern('CurrentTarget',				'83C4085F8BE55DC3CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC55',						-0xE,	'ptr')
	AddScanPattern('MyID',						'83EC08568BF13B15',														-0x3,	'ptr')
	; Map patterns
	AddScanPattern('Move',						'558BEC83EC208D45F0',													0x1,	'func')
	AddScanPattern('ClickCoords',				'8B451C85C0741CD945F8',													0xD,	'ptr')
	AddScanPattern('InstanceInfo',				'6A2C50E80000000083C408C7',												0xE,	'ptr')
	AddScanPattern('WorldConst',				'8D0476C1E00405',														0x8,	'ptr')
	AddScanPattern('Region',					'6A548D46248908',														-0x3,	'ptr')
	AddScanPattern('AreaInfo',					'6BC67C5E05',															0x6,	'ptr')
	; Trade patterns
	AddScanPattern('TradeCancel',				'C745FC01000000506A04',													-0x6,	'func')
	; Ui patterns
	AddScanPattern('UIMessage',					'B900000000E8000000005DC3894508',										-0x14,	'func')
	AddScanPattern('CompassFlag',				'8D451050566A5B57',														0x1,	'func')
	AddScanPattern('PartySearchButtonCallback',	'8B450883EC08568BF18B480483F90E',										-0x2,	'func')
	AddScanPattern('PartyWindowButtonCallback',	'837d0800578bf97411',													-0x2,	'func')
	AddScanPattern('EnterMission',				'A900001000743A',														0x52,	'func')
	AddScanPattern('SetDifficulty',				'83C41C682A010010',														0x8C,	'func')
	AddScanPattern('OpenChest',					'83C901894B24',															0x29,	'func')
	AddScanPattern('Dialog',					'894B248B4B2883E900',													0x16,	'func')
	AddScanPattern('AiMode',					'683A000010FF36',														0x1,	'ptr')
	AddScanPattern('HeroCommand',				'33D268E0010000',														0x1,	'ptr')
	AddScanPattern('HeroSkills',				'8B4E04505185FF',														0x1,	'ptr')
	AddScanPattern('PlayerAdd',					'',																		'',		'ptr',	'P:\Code\Gw\Ui\Game\Party\PtInvite.cpp',	'm_invitePlayerId')
	AddScanPattern('PlayerKick',				'',																		'',		'ptr',	'P:\Code\Gw\Ui\Game\Party\PtUtil.cpp',		'playerId == MissionCliGetPlayerId()')
	AddScanPattern('PartyInvitations',			'8B7D0C8BF083C4048B4704',												0x1,	'ptr')
	AddScanPattern('ActiveQuest',				'8B45083B46040F842D010000',												0x1,	'Ptr')
	; Hook patterns
	AddScanPattern('Engine',					'568B3085F67478EB038D4900D9460C',										-0x22,	'hook')
	AddScanPattern('Render',					'F6C401741C68',															-0x68,	'hook')
	AddScanPattern('LoadFinished',				'2BD9C1E303',															0xA0,	'hook')
	AddScanPattern('HookedTrader',				'8D4DFC51576A5450',														-0x3C,	'hook')
	AddScanPattern('TradePartner',				'6A008D45F8C745F801000000',												-0xC,	'hook')
	If IsDeclared('g_b_AddPattern') Then Extend_AddPattern()
EndFunc


;~ Adds a new pattern to be located
Func AddScanPattern($name, $pattern, $offset = 0, $type = 'ptr', $sourceFile = '', $message = '')
	;Local $fullName = 'Scan' & $name & $type
	Local $fullName = $name
	$scan_patterns[$scan_patterns_count][0] = $fullName
	$scan_patterns[$scan_patterns_count][1] = $pattern
	$scan_patterns[$scan_patterns_count][2] = $offset
	$scan_patterns[$scan_patterns_count][3] = $type
	$scan_patterns[$scan_patterns_count][4] = $sourceFile
	$scan_patterns[$scan_patterns_count][5] = $message
	$scan_patterns_count += 1
EndFunc


;~ Find process by scanning memory
;~ This process is located at 0x00401000, i.e.: shifted of 0x1000 from real start of the process. Why do we start here ? PE Headers ?
Func GetGameProcessBaseAddress()
	Debug('Getting game base address (PE excluded)')
	Local $scannedMemory = ScanMemoryForPattern(GetProcessHandle(), BinaryToString('0x558BEC83EC105356578B7D0833F63BFE'))
	Return $scannedMemory[0]
EndFunc


;~ Converts assertion based patterns into real instruction patterns
Func ResolveAssertionsPatterns()
	Debug('Resolving file-message assertions patterns')
	; Indexes of unresolved pattern in $scan_patterns
	Local $unresolvedIndexes[0]
	Local $allStrings[0]

	; Phase 1: collect unresolved assertions
	For $i = 0 To $scan_patterns_count - 1
		; Unresolved assertion
		If $scan_patterns[$i][4] <> '' And $scan_patterns[$i][5] <> '' Then
			Local $cacheKey = $scan_patterns[$i][4] & '|' & $scan_patterns[$i][5]

			If $assertions_patterns_cache[$cacheKey] <> Null Then
				$scan_patterns[$i][1] = $assertions_patterns_cache[$cacheKey]
			Else
				_ArrayAdd($unresolvedIndexes, $i)
				_ArrayAdd($allStrings, $scan_patterns[$i][4])
				_ArrayAdd($allStrings, $scan_patterns[$i][5])
			EndIf
		EndIf
	Next
	If UBound($unresolvedIndexes) == 0 Then Return

	; Ensure scanner sections are initialized - single equality operator is required here
	If $pe_sections_ranges[$PE_RDATA_SECTION][0] = 0 Then ReadExecutableSections(GetGameProcessBaseAddressWithPE())

	; Phase 2: locate strings in memory
	Local $addresses = FindStringsInMemorySection($allStrings)
	Local $stringToAddress[]
	For $i = 0 To UBound($allStrings) - 1
		If $addresses[$i] > 0 Then
			$stringToAddress[$allStrings[$i]] = $addresses[$i]
		EndIf
	Next

	; Phase 3: build patterns and populate cache
	For $i = 0 To UBound($unresolvedIndexes) - 1
		Local $patternIndex = $unresolvedIndexes[$i]
		Local $file = $scan_patterns[$patternIndex][4]
		Local $message = $scan_patterns[$patternIndex][5]

		Local $fileAddr = $stringToAddress[$file]
		Local $messageAddr = $stringToAddress[$message]
		If $fileAddr <> Null And $messageAddr <> Null Then
			Local $pattern = 'BA' & SwapEndian(Hex($fileAddr, 8)) & 'B9' & SwapEndian(Hex($messageAddr, 8))
			$scan_patterns[$patternIndex][1] = $pattern
			Local $cacheKey = $file & '|' & $message
			$assertions_patterns_cache[$cacheKey] = $pattern
		EndIf
	Next
EndFunc


;~ Build, inject, execute and harvest the scan results
Func ExecutePatternScan()
	; Locate game process
	Local $gwBaseAddress = GetGameProcessBaseAddress()
	Debug('Executing pattern scan')
	Local $results[]
	$asm_injection_size = 0
	$asm_code_offset = 0
	$asm_injection_string = ''

	Debug('Appending patterns to ASM injection string')
	; Building the ASM payload
	For $i = 0 To UBound($scan_patterns) - 1
		_($scan_patterns[$i][0] & ':')
		AppendPatternToASMInjection($scan_patterns[$i][1])
	Next
	Debug('Creating scan procedure')
	AssemblerCreateScanProcedure($gwBaseAddress)

	Local $newHeader = False
	Local $fixedHeader = $gwBaseAddress + 0x9E4000
	Local $processHandle = GetProcessHandle()
	Local $headerBytes = MemoryRead($processHandle, $fixedHeader, 'byte[8]')

	Debug('Checking for no previous injection')
	; Check if the scan memory address is empty (no previous injection)
	If $headerBytes == StringToBinary($GWA2_REFORGED_HEADER_STRING) Then
		$memory_interface_header = $fixedHeader
	ElseIf $headerBytes == 0 Then
		$memory_interface_header = $fixedHeader
		$newHeader = True
	Else
		$memory_interface_header = ScanMemoryForPattern($processHandle, $GWA2_REFORGED_HEADER_STRING)
		If $memory_interface_header == Null Then
			; Allocate a new block of memory for the scan routine
			$memory_interface_header = SafeDllCall13($kernel_handle, 'ptr', 'VirtualAllocEx', 'handle', $processHandle, 'ptr', 0, 'ulong_ptr', $GWA2_REFORGED_HEADER_SIZE, 'dword', 0x1000, 'dword', 0x40)
			; Get the allocated memory address
			$memory_interface_header = $memory_interface_header[0]
			If $memory_interface_header == 0 Then Return SetError(1, 0, 0)
			$newHeader = True
		Else
			; Found base address, adding position of the match and -1 to get the start of the header
			$memory_interface_header = $memory_interface_header[1] + $memory_interface_header[2] - 1
		EndIf
	EndIf

	Debug('Writing header to external process')
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

	Debug('Completing ASM code')
	; Complete the assembly code for the scan routine
	CompleteASMCode($memoryInterface)

	Debug('Writing ASM code')
	If $allocationScan Then
		; Write the assembly code to the allocated memory address
		WriteBinary($processHandle, $asm_injection_string, $memoryInterface + $asm_code_offset)

		Debug('Executing scan routine')
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
	FillScanResults()
EndFunc


;~ Adds a new pattern to the ASM injection string
Func AppendPatternToASMInjection($pattern)
	$pattern = StringReplace($pattern, '??', '00')

	Local $size = Int(0.5 * StringLen($pattern))
	$asm_injection_string &= '00000000' & SwapEndian(Hex($size, 8)) & '00000000' & $pattern
	$asm_injection_size += $size + 12
	; Padding each pattern to 68 bytes
	For $i = 1 To 68 - $size
		$asm_injection_size += 1
		$asm_injection_string &= '00'
	Next
EndFunc


;~ Compute final resolved addresses for each scan entry
Func FillScanResults()
	Debug('Retrieving scan results')
	Local $processHandle = GetProcessHandle()
	For $i = 0 To UBound($scan_patterns) - 1
		Local $label = $scan_patterns[$i][0]
		$scan_results[$label] = GetScannedAddress($processHandle, $label, $scan_patterns[$i][2])
	Next
EndFunc


;~ Get resulting scanned address
Func GetScannedAddress($processHandle, $label, $offset = 0)
	Return MemoryRead($processHandle, GetLabel($label) + 8) - MemoryRead($processHandle, GetLabel($label) + 4) + $offset
EndFunc


;~ Translate raw scan results into usable runtime elements
Func MapScanResultsToLabels()
	Debug('Mapping scan results to labels')
	Local $processHandle = GetProcessHandle()
	Local $tempValue

	; Core
	$base_address_ptr = MemoryRead($processHandle, $scan_results['BasePointer'])
	$ping_address = MemoryRead($processHandle, $scan_results['Ping'])
	$status_code_address = MemoryRead($processHandle, $scan_results['StatusCode'])
	Local $packetLocationAddress = MemoryRead($processHandle, $scan_results['PacketLocation'])
	$pre_game_address = MemoryRead($processHandle, $scan_results['PreGame'] + 0x35)
	Local $frameArray = MemoryRead($processHandle, $scan_results['FrameArray'] - 0x13)
	SetLabel('BasePointer', Ptr($base_address_ptr))
	SetLabel('PacketLocation', Ptr($packetLocationAddress))
	SetLabel('Ping', Ptr($ping_address))
	SetLabel('StatusCode', Ptr($status_code_address))
	SetLabel('PreGame', Ptr($pre_game_address))
	SetLabel('FrameArray', Ptr($frameArray))
	SetLabel('PacketSend', Ptr($scan_results['PacketSend']))
	SetLabel('ActionBase', Ptr(MemoryRead($processHandle, $scan_results['ActionBase'])))
	SetLabel('Action', Ptr($scan_results['Action']))
	SetLabel('Environment', Ptr($scan_results['Environment']))

	; Skill
	$skill_base_address = MemoryRead($processHandle, $scan_results['SkillBase'])
	$skill_timer_address = MemoryRead($processHandle, $scan_results['SkillTimer'])
	SetLabel('SkillBase', Ptr($skill_base_address))
	SetLabel('SkillTimer', Ptr($skill_timer_address))
	SetLabel('UseSkill', Ptr($scan_results['UseSkill']))
	SetLabel('UseHeroSkill', Ptr($scan_results['UseHeroSkill']))

	; Friend
	$friend_list_address = $scan_results['FriendList']
	$friend_list_address = MemoryRead($processHandle, FindInRange($processHandle, '57B9', 'xx', 2, $friend_list_address, $friend_list_address + 0xFF))
	$tempValue = $scan_results['RemoveFriend']
	$tempValue = FindInRange($processHandle, '50E8', 'xx', 1, $tempValue, $tempValue + 0x32)
	$tempValue = ResolveDirectBranchTarget($processHandle, $tempValue)
	SetLabel('FriendList', Ptr($friend_list_address))
	SetLabel('PlayerStatus', Ptr($scan_results['PlayerStatus']))
	SetLabel('AddFriend', Ptr($scan_results['AddFriend']))
	SetLabel('RemoveFriend', Ptr($tempValue))

	; Attributes
	$attribute_info_ptr = MemoryRead($processHandle, $scan_results['AttributeInfo'])
	SetLabel('AttributeInfo', Ptr($attribute_info_ptr))
	SetLabel('IncreaseAttribute', Ptr($scan_results['IncreaseAttribute']))
	SetLabel('DecreaseAttribute', Ptr($scan_results['DecreaseAttribute']))

	; Trader
	Local $buyItemBase = MemoryRead($processHandle, $scan_results['BuyItemBase'])
	Local $salvageGlobal = MemoryRead($processHandle, $scan_results['SalvageGlobal'] - 0x4)
	SetLabel('BuyItemBase', Ptr($buyItemBase))
	SetLabel('SalvageGlobal', Ptr($salvageGlobal))
	SetLabel('Transaction', Ptr($scan_results['Transaction']))
	SetLabel('RequestQuote', Ptr($scan_results['RequestQuote']))
	SetLabel('Salvage', Ptr($scan_results['Salvage']))

	; Agent
	$agent_base_address = MemoryRead($processHandle, $scan_results['AgentBase'])
	$max_agents = $agent_base_address + 0x8
	$my_ID = MemoryRead($processHandle, $scan_results['MyID'])
	$current_target_agent_ID = MemoryRead($processHandle, $scan_results['CurrentTarget'])
	SetLabel('AgentBase', Ptr($agent_base_address))
	SetLabel('MaxAgents', Ptr($max_agents))
	SetLabel('MyID', Ptr($my_ID))
	SetLabel('CurrentTarget', Ptr($current_target_agent_ID))
	SetLabel('ChangeTarget', Ptr($scan_results['ChangeTarget'] + 1))

	; Map
	$instance_info_ptr = MemoryRead($processHandle, $scan_results['InstanceInfo'])
	Local $worldConst = MemoryRead($processHandle, $scan_results['WorldConst'])
	Local $clickCoordsX = MemoryRead($processHandle, $scan_results['ClickCoords'])
	Local $clickCoordsY = MemoryRead($processHandle, $scan_results['ClickCoords'] + 9)
	$region_ID = MemoryRead($processHandle, $scan_results['Region'])
	$area_info_ptr = MemoryRead($processHandle, $scan_results['AreaInfo'])
	SetLabel('InstanceInfo', Ptr($instance_info_ptr))
	SetLabel('WorldConst', Ptr($worldConst))
	SetLabel('ClickCoords', Ptr($clickCoordsX))
	SetLabel('ClickCoords', Ptr($clickCoordsY))
	SetLabel('Region', Ptr($region_ID))
	SetLabel('Move', Ptr($scan_results['Move']))
	SetLabel('AreaInfo', Ptr($area_info_ptr))

	; Trade
	SetLabel('TradeCancel', Ptr($scan_results['TradeCancel']))
	$tempValue = $scan_results['TradeCancel']
	SetLabel('TradeAccept', Ptr($tempValue + 0x60))
	SetLabel('TradeOfferItem', Ptr($tempValue + 0x90))
	SetLabel('TradeSubmitOffer', Ptr($tempValue + 0x190))

	; UI
	SetLabel('UIMessage', Ptr($scan_results['UIMessage']))
	$tempValue = $scan_results['Dialog']
	SetLabel('Dialog', Ptr(GetCallTargetAddress($processHandle, $tempValue)))
	$tempValue = $scan_results['OpenChest']
	SetLabel('OpenChest', Ptr(GetCallTargetAddress($processHandle, $tempValue)))
	$tempValue = $scan_results['PartySearchButtonCallback']
	SetLabel('AddNPC', Ptr(GetCallTargetAddress($processHandle, $tempValue + 0xB0)))
	SetLabel('AddHero', Ptr(GetCallTargetAddress($processHandle, $tempValue + 0x100)))
	SetLabel('KickNPC', Ptr(GetCallTargetAddress($processHandle, $tempValue + 0x229)))
	SetLabel('KickHero', Ptr(GetCallTargetAddress($processHandle, $tempValue + 0x23A)))
	$tempValue = $scan_results['PartyWindowButtonCallback']
	SetLabel('LeaveGroup', Ptr(GetCallTargetAddress($processHandle, $tempValue + 0x58)))
	$tempValue = $scan_results['SetDifficulty']
	SetLabel('SetDifficulty', Ptr(GetCallTargetAddress($processHandle, $tempValue)))
	$tempValue = $scan_results['EnterMission']
	SetLabel('EnterMission', Ptr(GetCallTargetAddress($processHandle, $tempValue)))
	$tempValue = $scan_results['CompassFlag']
	SetLabel('FlagHero', Ptr(GetCallTargetAddress($processHandle, $tempValue + 0x4B)))
	SetLabel('FlagAll', Ptr(GetCallTargetAddress($processHandle, $tempValue + 0x83)))
	$tempValue = $scan_results['AiMode']
	SetLabel('SetHeroBehavior', Ptr(GetCallTargetAddress($processHandle, $tempValue + 0x83)))
	$tempValue = $scan_results['HeroCommand']
	SetLabel('DropHeroBundle', Ptr(GetCallTargetAddress($processHandle, $tempValue + 0xF6)))
	SetLabel('LockHeroTarget', Ptr(GetCallTargetAddress($processHandle, $tempValue + 0x13E)))
	$tempValue = $scan_results['HeroSkills']
	SetLabel('ToggleHeroSkillState', Ptr(GetCallTargetAddress($processHandle, $tempValue - 0xB5)))
	SetLabel('CancelHeroSkill', Ptr(GetCallTargetAddress($processHandle, $tempValue + 0x1B)))
	$tempValue = $scan_results['PlayerAdd']
	SetLabel('AddPlayer', Ptr(GetCallTargetAddress($processHandle, $tempValue + 0x13)))
	$tempValue = $scan_results['PlayerKick']
	SetLabel('KickPlayer', Ptr(GetCallTargetAddress($processHandle, $tempValue + 0x63)))
	SetLabel('KickInvitedPlayer', Ptr(GetCallTargetAddress($processHandle, $tempValue + 0x90)))
	$tempValue = $scan_results['PartyInvitations']
	SetLabel('RejectInvitation', Ptr(GetCallTargetAddress($processHandle, $tempValue + 0x34)))
	SetLabel('AcceptInvitation', Ptr(GetCallTargetAddress($processHandle, $tempValue + 0x4D)))
	$tempValue = $scan_results['ActiveQuest']
	SetLabel('ActiveQuest', Ptr(GetCallTargetAddress($processHandle, $tempValue + 0xF)))

	; Hook
	$tempValue = $scan_results['Engine']
	SetLabel('MainStart', Ptr($tempValue))
	SetLabel('MainReturn', Ptr($tempValue + 0x5))
	$tempValue = $scan_results['Render']
	SetLabel('RenderingMod', Ptr($tempValue))
	SetLabel('RenderingModReturn', Ptr($tempValue + 0xA))
	$tempValue = $scan_results['LoadFinished']
	SetLabel('LoadFinishedStart', Ptr($tempValue))
	SetLabel('LoadFinishedReturn', Ptr($tempValue + 0x5))
	$tempValue = $scan_results['HookedTrader']
	SetLabel('TraderStart', Ptr($tempValue))
	SetLabel('TraderReturn', Ptr($tempValue + 0x5))
	$tempValue = $scan_results['TradePartner']
	SetLabel('TradePartnerStart', Ptr($tempValue))
	SetLabel('TradePartnerReturn', Ptr($tempValue + 0x5))
	; Hook log
	If IsDeclared('g_b_Scanner') Then Extend_Scanner()
	SetLabel('QueueSize', '0x00000040')

	; Logging all labels
	For $key In MapKeys($labels_map)
		Debug($key & ': ' & $labels_map[$key])
	Next
EndFunc


;~ Bind command entry points to usable DllStruct
Func InitializeCommandStructures()
	Debug('Initializing command structures')
	Local $processHandle = GetProcessHandle()
	$agent_copy_count = GetLabel('AgentCopyCount')
	$agent_copy_base = GetLabel('AgentCopyBase')
	$trader_quote_ID = GetLabel('TraderQuoteID')
	$trader_cost_ID = GetLabel('TraderCostID')
	$trader_cost_value = GetLabel('TraderCostValue')
	Local $savedIndex = GetLabel('SavedIndex')
	$queue_counter = MemoryRead($processHandle, GetLabel('QueueCounter'))
	$queue_size = GetLabel('QueueSize')
	$queue_base_address = GetLabel('QueueBase')
	$disable_rendering_address = GetLabel('DisableRendering')
	$map_is_loaded_ptr = GetLabel('MapIsLoaded')
	$trade_partner_ptr = GetLabel('TradePartner')
	If IsDeclared('g_b_InitializeResult') Then Extend_InitializeResult()

	; Setup command structures
	DllStructSetData($INVITE_GUILD_STRUCT, 1, GetLabel('CommandPacketSend'))
	DllStructSetData($PACKET_STRUCT, 1, GetLabel('CommandPacketSend'))
	DllStructSetData($ACTION_STRUCT, 1, GetLabel('CommandAction'))
	DllStructSetData($SEND_CHAT_STRUCT, 1, GetLabel('CommandSendChat'))
	DllStructSetData($SEND_CHAT_STRUCT, 2, $HEADER_SEND_CHAT)
	;Skill
	DllStructSetData($USE_SKILL_STRUCT, 1, GetLabel('CommandUseSkill'))
	DllStructSetData($USE_HERO_SKILL_STRUCT, 1, GetLabel('CommandUseHeroSkill'))
	DllStructSetData($CANCEL_HERO_SKILL_STRUCT, 1, GetLabel('CommandCancelHeroSkill'))
	;Friend
	DllStructSetData($CHANGE_STATUS_STRUCT, 1, GetLabel('CommandPlayerStatus'))
	Local $addFriend = DllStructCreate('ptr;ptr;ptr;dword')
	DllStructSetData($addFriend, 1, GetLabel('CommandAddFriend'))
	Local $removeFriend = DllStructCreate('ptr;byte[16];ptr;dword')
	DllStructSetData($removeFriend, 1, GetLabel('CommandRemoveFriend'))
	;Attribute
	DllStructSetData($INCREASE_ATTRIBUTE_STRUCT, 1, GetLabel('CommandIncreaseAttribute'))
	DllStructSetData($DECREASE_ATTRIBUTE_STRUCT, 1, GetLabel('CommandDecreaseAttribute'))
	;Trade
	DllStructSetData($SELL_ITEM_STRUCT, 1, GetLabel('CommandSellItem'))
	DllStructSetData($BUY_ITEM_STRUCT, 1, GetLabel('CommandBuyItem'))
	DllStructSetData($REQUEST_QUOTE_STRUCT, 1, GetLabel('CommandRequestQuote'))
	DllStructSetData($REQUEST_QUOTE_STRUCT_SELL, 1, GetLabel('CommandRequestQuoteSell'))
	DllStructSetData($TRADER_BUY_STRUCT, 1, GetLabel('CommandTraderBuy'))
	DllStructSetData($TRADER_SELL_STRUCT, 1, GetLabel('CommandTraderSell'))
	DllStructSetData($SALVAGE_STRUCT, 1, GetLabel('CommandSalvage'))
	;Agent
	DllStructSetData($CHANGE_TARGET_STRUCT, 1, GetLabel('CommandChangeTarget'))
	DllStructSetData($MAKE_AGENT_ARRAY_STRUCT, 1, GetLabel('CommandMakeAgentArray'))
	;Map
	DllStructSetData($MOVE_STRUCT, 1, GetLabel('CommandMove'))
	;Trade
	DllStructSetData($TRADE_INITIATE_STRUCT, 1, GetLabel('CommandTradeInitiate'))
	DllStructSetData($TRADE_CANCEL_STRUCT, 1, GetLabel('CommandTradeCancel'))
	DllStructSetData($TRADE_ACCEPT_STRUCT, 1, GetLabel('CommandTradeAccept'))
	DllStructSetData($TRADE_SUBMIT_STRUCT, 1, GetLabel('CommandTradeSubmitOffer'))
	DllStructSetData($TRADE_OFFER_ITEM_STRUCT, 1, GetLabel('CommandTradeOfferItem'))
	;Ui
	DllStructSetData($DIALOG_STRUCT, 1, GetLabel('CommandDialog'))
	DllStructSetData($OPEN_CHEST_STRUCT, 1, GetLabel('CommandOpenChest'))
	DllStructSetData($ADD_NPC_STRUCT, 1, GetLabel('CommandAddNPC'))
	DllStructSetData($ADD_HERO_STRUCT, 1, GetLabel('CommandAddHero'))
	DllStructSetData($KICK_NPC_STRUCT, 1, GetLabel('CommandKickNPC'))
	DllStructSetData($KICK_HERO_STRUCT, 1, GetLabel('CommandKickHero'))
	DllStructSetData($LEAVE_GROUP_STRUCT, 1, GetLabel('CommandLeaveGroup'))
	DllStructSetData($SET_DIFFICULTY_STRUCT, 1, GetLabel('CommandSetDifficulty'))
	DllStructSetData($ENTER_MISSION_STRUCT, 1, GetLabel('CommandEnterMission'))
	DllStructSetData($FLAG_HERO_STRUCT, 1, GetLabel('CommandFlagHero'))
	DllStructSetData($FLAG_ALL_STRUCT, 1, GetLabel('CommandFlagAll'))
	DllStructSetData($SET_HERO_BEHAVIOUR_STRUCT, 1, GetLabel('CommandSetHeroBehavior'))
	DllStructSetData($DROP_HERO_BUNDLE_STRUCT, 1, GetLabel('CommandDropHeroBundle'))
	DllStructSetData($LOCK_HERO_TARGET_STRUCT, 1, GetLabel('CommandLockHeroTarget'))
	DllStructSetData($TOGGLE_HERO_SKILL_STATE, 1, GetLabel('CommandToggleHeroSkillState'))
	DllStructSetData($ACTIVE_QUEST_STRUCT, 1, GetLabel('CommandActiveQuest'))
	;UIMsg
	DllStructSetData($MOVE_MAP_STRUCT, 1, GetLabel('CommandUIMsg'))
	DllStructSetData($EQUIP_ITEM_STRUCT, 1, GetLabel('CommandUIMsg'))
	;Party
	DllStructSetData($ADD_PLAYER_STRUCT, 1, GetLabel('CommandAddPlayer'))
	DllStructSetData($KICK_PLAYER_STRUCT, 1, GetLabel('CommandKickPlayer'))
	DllStructSetData($KICK_INVITED_PLAYER_STRUCT, 1, GetLabel('CommandKickInvitedPlayer'))
	DllStructSetData($REJECT_INVITATION_STRUCT, 1, GetLabel('CommandRejectInvitation'))
	DllStructSetData($ACCEPT_INVITATION_STRUCT, 1, GetLabel('CommandAcceptInvitation'))
EndFunc


;~ Find multiple strings within a PE section
Func FindStringsInMemorySection($strings, $section = $PE_RDATA_SECTION)
	Local $gwBaseAddress = GetGameProcessBaseAddressWithPE()
	Local $stringsCount = UBound($strings)
	Local $results[$stringsCount]

	; Checking if section initialization is required - single equality operator is required here
	If $pe_sections_ranges[$section][0] = 0 Or $pe_sections_ranges[$section][1] = 0 Then
		If $gwBaseAddress == 0 Then
			Error('Failed to get GW base address')
			Return $results
		EndIf

		If Not ReadExecutableSections($gwBaseAddress) Then
			Error('Failed to initialize memory sections')
			Return $results
		EndIf
	EndIf

	Local $sectionStart = $pe_sections_ranges[$section][0]
	Local $sectionEnd = $pe_sections_ranges[$section][1]

	If $sectionStart = 0 Or $sectionEnd = 0 Or $sectionStart >= $sectionEnd Then
		Debug('Invalid section bounds. Start: ' & Hex($sectionStart) & ', End: ' & Hex($sectionEnd))
		Debug('Falling back to bruteforce scanner due to invalid section bounds')
		Return FallbackMemoryStringSearch($strings, $section)
	EndIf

	Local $sectionSize = Number($sectionEnd - $sectionStart)
	Local $maxReadSize = 8 * 1024 * 1024

	If $sectionSize > $maxReadSize Then
		Debug('Falling back to bruteforce scanner due to too large sectionSize')
		Return FallbackMemoryStringSearch($strings, $section)
	EndIf

	Local $sectionBuffer = DllStructCreate('byte[' & $sectionSize & ']')
	If @error Then
		Debug('Falling back to bruteforce scanner; could not create section buffer')
		Return FallbackMemoryStringSearch($strings, $section)
	EndIf

	Local $bytesRead = 0
	Local $success = SafeDllCall13($kernel_handle, 'bool', 'ReadProcessMemory', 'handle', GetProcessHandle(), 'ptr', $sectionStart, 'ptr', DllStructGetPtr($sectionBuffer), 'ulong_ptr', $sectionSize, 'ulong_ptr*', $bytesRead)

	If @error Or Not $success[0] Or $success[5] < $sectionSize Then
		Debug('Falling back to bruteforce scanner; failed to read section')
		Return FallbackMemoryStringSearch($strings, $section)
	EndIf

	; Preprocess patterns (Boyer–Moore–Horspool) + preconvert patterns to byte arrays
	Local $patternBytes[$stringsCount]
	Local $patternLengths[$stringsCount]
	Local $skipTables[$stringsCount][256]
	Local $found[$stringsCount]

	For $i = 0 To $stringsCount - 1
		$found[$i] = False

		Local $patternBinary = Binary($strings[$i] & Chr(0))
		$patternLengths[$i] = BinaryLen($patternBinary)

		Local $byteArray[$patternLengths[$i]]
		For $j = 0 To $patternLengths[$i] - 1
			$byteArray[$j] = Number(BinaryMid($patternBinary, $j + 1, 1))
		Next
		$patternBytes[$i] = $byteArray

		For $b = 0 To 255
			$skipTables[$i][$b] = $patternLengths[$i]
		Next

		For $j = 0 To $patternLengths[$i] - 2
			$skipTables[$i][$byteArray[$j]] = $patternLengths[$i] - $j - 1
		Next
	Next

	Local $totalFound = 0

	; Search each pattern independently with BMH
	For $patternIndex = 0 To $stringsCount - 1
		If $totalFound >= $stringsCount Then ExitLoop
		If $found[$patternIndex] Then ContinueLoop

		Local $patternLength = $patternLengths[$patternIndex]
		Local $pos = $patternLength - 1
		Local $patternByteArray = $patternBytes[$patternIndex]

		While $pos < $sectionSize
			Local $match = True
			Local $checkIndex = $patternLength - 1

			While $checkIndex >= 0
				Local $memByte = DllStructGetData($sectionBuffer, 1, $pos - ($patternLength - 1 - $checkIndex) + 1)
				Local $patternByte = $patternByteArray[$checkIndex]

				If $memByte <> $patternByte Then
					$match = False
					$pos += $skipTables[$patternIndex][$memByte]
					ExitLoop
				EndIf
				$checkIndex -= 1
			WEnd

			If $match Then
				$results[$patternIndex] = $sectionStart + $pos - ($patternLength - 1)
				$found[$patternIndex] = True
				$totalFound += 1
				ExitLoop
			EndIf
		WEnd
	Next
	Return $results
EndFunc


;~ Locate the base address of GW.exe via module enumeration - pattern scanning is not enough to identify PE layout reliably
Func GetGameProcessBaseAddressWithPE()
	Debug('Getting game base address (PE included)')
	Local $processHandle = GetProcessHandle()
	If $processHandle = 0 Then
		Error('Invalid process handle')
		Return 0
	EndIf

	Local $modules = DllStructCreate('ptr[1024]')
	Local $bytesNeeded = DllStructCreate('dword')
	Local $psapiHandle = DllOpen('psapi.dll')
	If @error Then
		Error('Failed to open psapi.dll')
		Return 0
	EndIf

	Local $result = SafeDllCall11($psapiHandle, 'bool', 'EnumProcessModules', 'handle', $processHandle, 'ptr', DllStructGetPtr($modules), 'dword', DllStructGetSize($modules), 'ptr', DllStructGetPtr($bytesNeeded))
	If @error Or Not $result[0] Then
		Error('EnumProcessModules failed')
		DllClose($psapiHandle)
		Return 0
	EndIf

	Local $moduleCount = DllStructGetData($bytesNeeded, 1) / 4
	For $i = 1 To $moduleCount
		Local $moduleBase = DllStructGetData($modules, 1, $i)
		Local $modulePath = _WinAPI_GetModuleFileNameEx($processHandle, $moduleBase)
		If StringInStr($modulePath, 'Gw.exe', 1) Then
			DllClose($psapiHandle)
			Return $moduleBase
		EndIf
	Next
	Error('Gw.exe module not found')
	DllClose($psapiHandle)
	Return 0
EndFunc


;~ Slower string scanner but more robust
Func FallbackMemoryStringSearch($strings, $section = $PE_RDATA_SECTION)
	Local $stringCount = UBound($strings)
	Local $results[$stringCount]
	Local $found[$stringCount]
	Local $patterns[$stringCount]
	Local $lengths[$stringCount]
	Local $firstBytes[$stringCount]
	Local $hashTable[256]
	Local $minLength = 999999
	Local $maxLength = 0
	Local $processHandle = GetProcessHandle()

	For $i = 0 To 255
		$hashTable[$i] = ''
	Next

	For $i = 0 To $stringCount - 1
		$found[$i] = False
		$patterns[$i] = Binary($strings[$i] & Chr(0))
		$lengths[$i] = BinaryLen($patterns[$i])
		$firstBytes[$i] = Number(BinaryMid($patterns[$i], 1, 1))

		If $lengths[$i] < $minLength Then $minLength = $lengths[$i]
		If $lengths[$i] > $maxLength Then $maxLength = $lengths[$i]

		If $hashTable[$firstBytes[$i]] = '' Then
			$hashTable[$firstBytes[$i]] = String($i)
		Else
			$hashTable[$firstBytes[$i]] &= ',' & $i
		EndIf
	Next

	Local $sectionStart = $pe_sections_ranges[$section][0]
	Local $sectionEnd = $pe_sections_ranges[$section][1]
	; 2 Mb
	Local $bufferSize = 2 * 1024 * 1024
	Local $buffer = DllStructCreate('byte[' & $bufferSize & ']')
	Local $totalFound = 0
	Local $startTime = TimerInit()
	Local $overlap = $maxLength - 1

	Local $patternData[$stringCount][$maxLength]
	For $i = 0 To $stringCount - 1
		For $b = 0 To $lengths[$i] - 1
			$patternData[$i][$b] = Number(BinaryMid($patterns[$i], $b + 1, 1))
		Next
	Next

	For $currentAddr = $sectionStart To $sectionEnd Step $bufferSize - $overlap
		If $totalFound = $stringCount Then ExitLoop

		Local $readSize = $bufferSize
		If $currentAddr + $readSize > $sectionEnd Then $readSize = $sectionEnd - $currentAddr

		Local $bytesRead = 0
		Local $success = SafeDllCall13($kernel_handle, 'bool', 'ReadProcessMemory', 'handle', $processHandle, 'ptr', $currentAddr, 'ptr', DllStructGetPtr($buffer), 'ulong_ptr', $readSize, 'ulong_ptr*', $bytesRead)

		If @error Or Not $success[0] Or $success[5] = 0 Then ContinueLoop
		$readSize = $success[5]

		Local $searchEnd = $readSize - $minLength + 1
		For $searchIdx = 0 To $searchEnd - 1
			Local $byte = DllStructGetData($buffer, 1, $searchIdx + 1)
			If $hashTable[$byte] = '' Then ContinueLoop

			Local $indices = StringSplit($hashTable[$byte], ',', 2)
			For $idx = 0 To UBound($indices) - 1
				Local $patternIdx = Number($indices[$idx])
				If $found[$patternIdx] Then ContinueLoop

				Local $patternLen = $lengths[$patternIdx]
				If $searchIdx + $patternLen > $readSize Then ContinueLoop

				Local $mid = Int($patternLen / 2)
				If DllStructGetData($buffer, 1, $searchIdx + $mid + 1) <> $patternData[$patternIdx][$mid] Then ContinueLoop
				If DllStructGetData($buffer, 1, $searchIdx + $patternLen) <> $patternData[$patternIdx][$patternLen - 1] Then ContinueLoop

				Local $match = True
				For $c = 1 To $patternLen - 2
					If $c = $mid Then ContinueLoop
					If DllStructGetData($buffer, 1, $searchIdx + $c + 1) <> $patternData[$patternIdx][$c] Then
						$match = False
						ExitLoop
					EndIf
				Next

				If $match Then
					$results[$patternIdx] = $currentAddr + $searchIdx
					$found[$patternIdx] = True
					$totalFound += 1

					Local $newIndices = ''
					For $r = 0 To UBound($indices) - 1
						If Number($indices[$r]) <> $patternIdx Then
							If $newIndices = '' Then
								$newIndices = $indices[$r]
							Else
								$newIndices &= ',' & $indices[$r]
							EndIf
						EndIf
					Next
					$hashTable[$byte] = $newIndices

					If $totalFound = $stringCount Then ExitLoop 3
				EndIf
			Next
		Next
	Next

	Return $results
EndFunc


;~ Parse PE headers and populate pe_sections_ranges with their start and end
Func ReadExecutableSections($baseAddress)
	Debug('Reading PE sections to map their start/end')
	Local $bytesRead
	Local $dosHeader = DllStructCreate('struct;word e_magic;byte[58];dword e_lfanew;endstruct')
	Local $processHandle = GetProcessHandle()
	Local $success = _WinAPI_ReadProcessMemory($processHandle, $baseAddress, DllStructGetPtr($dosHeader), DllStructGetSize($dosHeader), $bytesRead)
	If Not $success Then
		Error('Failed to read DOS header')
		Return False
	ElseIf DllStructGetData($dosHeader, 'e_magic') <> 0x5A4D Then
		Error('Invalid DOS signature ' & DllStructGetData($dosHeader, 'e_magic'))
		Return False
	EndIf

	Local $peHeaderOffset = DllStructGetData($dosHeader, 'e_lfanew')

	Local $ntHeaders = DllStructCreate('struct;dword Signature;word Machine;word NumberOfSections;dword TimeDateStamp;dword PointerToSymbolTable;dword NumberOfSymbols;word SizeOfOptionalHeader;word Characteristics;endstruct')
	$success = _WinAPI_ReadProcessMemory($processHandle, $baseAddress + $peHeaderOffset, DllStructGetPtr($ntHeaders), DllStructGetSize($ntHeaders), $bytesRead)
	If Not $success Then
		Error('Failed to read NT headers')
		Return False
	ElseIf DllStructGetData($ntHeaders, 'Signature') <> 0x4550 Then
		Error('Invalid PE signature')
		Return False
	EndIf

	Local $sectionCount = DllStructGetData($ntHeaders, 'NumberOfSections')
	Local $optionalHeaderSize = DllStructGetData($ntHeaders, 'SizeOfOptionalHeader')
	Local $sectionHeaderOffset = $peHeaderOffset + 24 + $optionalHeaderSize

	For $i = 0 To 4
		$pe_sections_ranges[$i][0] = 0
		$pe_sections_ranges[$i][1] = 0
	Next

	Local $sectionHeader = DllStructCreate('struct;' & _
		'char Name[8];' & _
		'dword VirtualSize;' & _
		'dword VirtualAddress;' & _
		'dword SizeOfRawData;' & _
		'dword PointerToRawData;' & _
		'dword PointerToRelocations;' & _
		'dword PointerToLinenumbers;' & _
		'word NumberOfRelocations;' & _
		'word NumberOfLinenumbers;' & _
		'dword Characteristics;' & _
		'endstruct')

	For $i = 0 To $sectionCount - 1
		$success = _WinAPI_ReadProcessMemory($processHandle, $baseAddress + $sectionHeaderOffset + ($i * 40), DllStructGetPtr($sectionHeader), DllStructGetSize($sectionHeader), $bytesRead)

		If Not $success Then
			Warn('Failed to read section header ' & $i)
			ContinueLoop
		EndIf

		Local $sectionName = StringStripWS(DllStructGetData($sectionHeader, 'Name'), 8)
		Local $virtualAddress = DllStructGetData($sectionHeader, 'VirtualAddress')
		Local $virtualSize = DllStructGetData($sectionHeader, 'VirtualSize')
		Local $rawSize = DllStructGetData($sectionHeader, 'SizeOfRawData')

		Local $actualSize = $virtualSize > $rawSize ? $virtualSize : $rawSize

		Switch $sectionName
			Case '.text'
				$pe_sections_ranges[$PE_TEXT_SECTION][0] = $baseAddress + $virtualAddress
				$pe_sections_ranges[$PE_TEXT_SECTION][1] = $pe_sections_ranges[$PE_TEXT_SECTION][0] + $actualSize

			Case '.rdata'
				$pe_sections_ranges[$PE_RDATA_SECTION][0] = $baseAddress + $virtualAddress
				$pe_sections_ranges[$PE_RDATA_SECTION][1] = $pe_sections_ranges[$PE_RDATA_SECTION][0] + $actualSize

			Case '.data'
				$pe_sections_ranges[$PE_DATA_SECTION][0] = $baseAddress + $virtualAddress
				$pe_sections_ranges[$PE_DATA_SECTION][1] = $pe_sections_ranges[$PE_DATA_SECTION][0] + $actualSize

			Case '.rsrc'
				$pe_sections_ranges[$PE_RSRC_SECTION][0] = $baseAddress + $virtualAddress
				$pe_sections_ranges[$PE_RSRC_SECTION][1] = $pe_sections_ranges[$PE_RSRC_SECTION][0] + $actualSize

			Case '.reloc'
				$pe_sections_ranges[$PE_RELOC_SECTION][0] = $baseAddress + $virtualAddress
				$pe_sections_ranges[$PE_RELOC_SECTION][1] = $pe_sections_ranges[$PE_RELOC_SECTION][0] + $actualSize
		EndSwitch
	Next

	If $pe_sections_ranges[$PE_TEXT_SECTION][0] = 0 Then
		Error('Failed to find .text section')
		Return False
	EndIf

	Return True
EndFunc



#Region Other Functions
;~ Internal use only.
Func SafeEnqueue($ptr, $size)
	If Not IsMemoryWritable(GetProcessHandle(), 256 * $queue_counter + $queue_base_address, $size) Then
		Return False
	EndIf
	SafeDllCall13($kernel_handle, 'int', 'WriteProcessMemory', 'int', GetProcessHandle(), 'int', 256 * $queue_counter + $queue_base_address, 'ptr', $ptr, 'int', $size, 'int', 0)
	$queue_counter = Mod($queue_counter + 1, $queue_size)
	Return True
EndFunc


;~ Internal use only.
Func Enqueue($ptr, $size)
	SafeDllCall13($kernel_handle, 'int', 'WriteProcessMemory', 'int', GetProcessHandle(), 'int', 256 * $queue_counter + $queue_base_address, 'ptr', $ptr, 'int', $size, 'int', 0)
	$queue_counter = Mod($queue_counter + 1, $queue_size)
	Return True
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


#Region Modification
;~ Internal use only.
Func ModifyMemory()
	$asm_injection_size = 0
	$asm_code_offset = 0
	$asm_injection_string = ''

	AssemblerCreateData()
	AssemblerCreateMain()
	AssemblerCreateRenderingMod()
	AssemblerCreateLoadFinished()
	AssemblerCreateTradePartner()
	AssemblerCreateCommands()
	AssemblerCreateSkillCommands()
	AssemblerCreateFriendCommands()
	AssemblerCreateAttributeCommands()
	AssemblerCreateTrader()
	AssemblerCreateSellItemCommand()
	AssemblerCreateBuyItemCommand()
	AssemblerCreateRequestQuoteCommand()
	AssemblerCreateRequestQuoteSellCommand()
	AssemblerCreateTraderBuyCommand()
	AssemblerCreateTraderSellCommand()
	AssemblerCreateCraftItemCommand()
	AssemblerCreateCollectorExchangeCommand()
	AssemblerCreateSalvageCommand()
	AssemblerCreateAgentCommands()
	AssemblerCreateMapCommands()
	AssemblerCreateTradeCommands()
	AssemblerCreateUICommands()
	AssemblerCreatePartyCommands()
	If IsDeclared('g_b_Assembler') Then Extend_Assembler()

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
		; FIXME: failures happening here - expected, QueuePtr label does not exist
		MemoryWrite($processHandle, GetLabel('QueuePtr'), GetLabel('QueueBase'))
		If IsDeclared('g_b_Write') Then Extend_Write()

		WriteDetour('MainStart', 'MainProc')
		WriteDetour('TraderStart', 'TraderProc')
		WriteDetour('RenderingMod', 'RenderingModProc')
		WriteDetour('LoadFinishedStart', 'LoadFinishedProc')
		WriteDetour('TradePartnerStart', 'TradePartnerProc')
		If IsDeclared('g_b_AssemblerWriteDetour') Then Extend_AssemblerWriteDetour()
	EndIf
EndFunc


;~ Internal use only.
Func WriteDetour($from, $to)
	WriteBinary(GetProcessHandle(),'E9' & SwapEndian(Hex(GetLabel($to) - GetLabel($from) - 5)), GetLabel($from))
EndFunc
#EndRegion Modification


Func AssemblerCreateScanProcedure($gwBaseAddress)
	_('ScanProc:')
	_('pushad')
	_('mov ecx,' & Hex($gwBaseAddress, 8))
	_('mov esi,ScanProc')
	_('ScanLoop:')
	_('inc ecx')
	_('mov al,byte[ecx]')
	; First pattern - BasePointer
	_('mov edx,' & $scan_patterns[0][0])

	_('ScanInnerLoop:')
	_('mov ebx,dword[edx]')
	_('cmp ebx,-1')
	_('jnz ScanContinue')
	_('add edx,50')
	_('cmp edx,esi')
	_('jnz ScanInnerLoop')
	_('cmp ecx,' & SwapEndian(Hex($gwBaseAddress + 5238784, 8)))
	_('jnz ScanLoop')
	_('jmp ScanExit')

	_('ScanContinue:')
	_('lea edi,dword[edx+ebx]')
	_('add edi,C')
	_('mov ah,byte[edi]')
	_('cmp al,ah')
	_('jz ScanMatched')
	_('cmp ah,00')
	_('jz ScanMatched')
	_('mov dword[edx],0')
	_('add edx,50')
	_('cmp edx,esi')
	_('jnz ScanInnerLoop')
	_('cmp ecx,' & SwapEndian(Hex($gwBaseAddress + 5238784, 8)))
	_('jnz ScanLoop')
	_('jmp ScanExit')

	_('ScanMatched:')
	_('inc ebx')
	_('mov edi,dword[edx+4]')
	_('cmp ebx,edi')
	_('jz ScanFound')
	_('mov dword[edx],ebx')
	_('add edx,50')
	_('cmp edx,esi')
	_('jnz ScanInnerLoop')
	_('cmp ecx,' & SwapEndian(Hex($gwBaseAddress + 5238784, 8)))
	_('jnz ScanLoop')
	_('jmp ScanExit')

	_('ScanFound:')
	_('lea edi,dword[edx+8]')
	_('mov dword[edi],ecx')
	_('mov dword[edx],-1')
	_('add edx,50')
	_('cmp edx,esi')
	_('jnz ScanInnerLoop')
	_('cmp ecx,' & SwapEndian(Hex($gwBaseAddress + 5238784, 8)))
	_('jnz ScanLoop')

	_('ScanExit:')
	_('popad')
	_('retn')
EndFunc


Func AssemblerCreateData()
	_('SavedIndex/4')
	_('QueueCounter/4')
	_('TraderQuoteID/4')
	_('TraderCostID/4')
	_('TraderCostValue/4')
	_('DisableRendering/4')
	_('MapIsLoaded/4')
	_('TradePartner/4')
	_('AgentCopyCount/4')

	If IsDeclared('g_b_AssemblerData') Then Extend_AssemblerData()

	_('QueueBase/' & 256 * GetLabel('QueueSize'))
	_('AgentCopyBase/' & 0x1C0 * 256)
EndFunc

Func AssemblerCreateMain()
	_('MainProc:')
	_('pushad')
	_('pushfd')

	_('mov eax,dword[BasePointer]')
	_('test eax,eax')
	_('jz RegularFlow')
	_('mov eax,dword[eax]')
	_('test eax,eax')
	_('jz RegularFlow')
	_('mov eax,dword[eax+18]')
	_('test eax,eax')
	_('jz RegularFlow')
	_('mov eax,dword[eax+44]')
	_('test eax,eax')
	_('jz RegularFlow')
	_('mov ebx,dword[eax+19C]')
	_('test ebx,ebx')
	_('jz RegularFlow')
	_('mov eax,dword[eax+198]')
	_('cmp eax,0')
	_('je HandleCase')
	_('mov ebx,eax')
	_('imul ebx,ebx,7C')
	_('add ebx,dword[Environment]')
	_('test ebx,ebx')
	_('jz RegularFlow')
	_('mov ebx,dword[ebx+10]')
	_('test ebx,40001')
	_('jz RegularFlow')

	_('HandleCase:')
	_('mov eax,dword[QueueCounter]')
	_('mov ecx,eax')
	_('shl eax,8')
	_('add eax,QueueBase')
	_('mov ebx,dword[eax]')
	_('test ebx,ebx')
	_('jz MainExit')
	_('mov dword[eax],0')
	_('mov eax,ecx')
	_('inc eax')
	_('cmp eax,QueueSize')
	_('jnz SubSkipReset')
	_('xor eax,eax')
	_('SubSkipReset:')
	_('mov dword[QueueCounter],eax')
	_('jmp MainExit')

	_('RegularFlow:')
	_('mov eax,dword[QueueCounter]')
	_('mov ecx,eax')
	_('shl eax,8')
	_('add eax,QueueBase')
	_('mov ebx,dword[eax]')
	_('test ebx,ebx')
	_('jz MainExit')
	_('mov dword[SavedIndex],ecx')
	_('mov dword[eax],0')
	_('jmp ebx')

	_('CommandReturn:')
	_('mov ecx,dword[SavedIndex]')
	_('mov edx,dword[QueueCounter]')
	_('cmp edx,ecx')
	_('jnz MainExit')
	_('mov eax,ecx')
	_('inc eax')
	_('cmp eax,QueueSize')
	_('jnz MainSkipReset')
	_('xor eax,eax')
	_('MainSkipReset:')
	_('mov dword[QueueCounter],eax')

	_('MainExit:')
	_('popfd')
	_('popad')
	_('mov ebp,esp')
	_('fld st(0),dword[ebp+8]')
	_('ljmp MainReturn')
EndFunc

Func AssemblerCreateTrader()
	_('TraderProc:')
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

Func AssemblerCreateRenderingMod()
	_('RenderingModProc:')
	_('add esp,4')
	_('cmp dword[DisableRendering],1')
	_('ljmp RenderingModReturn')
EndFunc

Func AssemblerCreateLoadFinished()
	_('LoadFinishedProc:')
	_('mov dword[MapIsLoaded],1')
	_('push dword[edi+1C]')
	_('mov ecx,esi')
	_('ljmp LoadFinishedReturn')
EndFunc

Func AssemblerCreateTradePartner()
	_('TradePartnerProc:')
	_('push esi')
	_('mov esi,dword[ebp+C]')
	_('push esi')
	_('mov dword[TradePartner],esi')
	_('ljmp TradePartnerReturn')
EndFunc

Func AssemblerCreateCommands()
	_('CommandPacketSend:')
	_('lea edx,dword[eax+8]')
	_('push edx')
	_('mov ebx,dword[eax+4]')
	_('push ebx')
	_('mov eax,dword[PacketLocation]')
	_('push eax')
	_('call PacketSend')
	_('pop eax')
	_('pop ebx')
	_('pop edx')
	_('ljmp CommandReturn')

	_('CommandAction:')
	_('mov ecx,dword[ActionBase]')
	_('cmp dword[eax+C],0')
	_('jnz ActionType2')
	_('ActionType1:')
	_('mov ecx,dword[ecx+C]')
	_('jmp ActionCommon')
	_('ActionType2:')
	_('mov ecx,dword[ecx+4]')
	_('ActionCommon:')
	_('add ecx,A8')
	_('push 0')
	_('add eax,4')
	_('push eax')
	_('push dword[eax+4]')
	_('mov edx,0')
	_('call Action')
	_('ljmp CommandReturn')

	_('CommandSendChat:')
	_('lea edx,dword[eax+4]')
	_('push edx')
	_('mov ebx,11c')
	_('push ebx')
	_('mov eax,dword[PacketLocation]')
	_('push eax')
	_('call PacketSend')
	_('pop eax')
	_('pop ebx')
	_('pop edx')
	_('ljmp CommandReturn')
EndFunc

Func AssemblerCreateSkillCommands()
	_('CommandUseSkill:')
	_('mov ecx,dword[eax+10]')
	_('push ecx')
	_('mov ebx,dword[eax+C]')
	_('push ebx')
	_('mov edx,dword[eax+8]')
	_('push edx')
	_('mov ecx,dword[eax+4]')
	_('push ecx')
	_('call UseSkill')
	_('add esp,10')
	_('ljmp CommandReturn')

	_('CommandUseHeroSkill:')
	_('mov ecx,dword[eax+8]')
	_('push ecx')
	_('mov ecx,dword[eax+c]')
	_('push ecx')
	_('mov ecx,dword[eax+4]')
	_('push ecx')
	_('call UseHeroSkill')
	_('add esp,C')
	_('ljmp CommandReturn')

	_('CommandCancelHeroSkill:')
	_('push dword[eax+8]')
	_('push dword[eax+4]')
	_('call CancelHeroSkill')
	_('add esp,8')
	_('ljmp CommandReturn')
EndFunc

Func AssemblerCreateFriendCommands()
	_('CommandPlayerStatus:')
	_('mov eax,dword[eax+4]')
	_('push eax')
	_('call PlayerStatus')
	_('pop eax')
	_('ljmp CommandReturn')

	_('CommandAddFriend:')
	_('mov ecx,dword[eax+C]')
	_('push ecx')
	_('mov edx,dword[eax+8]')
	_('push edx')
	_('mov ecx,dword[eax+4]')
	_('push ecx')
	_('call AddFriend')
	_('add esp,C')
	_('ljmp CommandReturn')

	_('CommandRemoveFriend:')
	_('mov ecx,dword[eax+18]')
	_('push ecx')
	_('mov edx,dword[eax+14]')
	_('push edx')
	_('lea ecx,dword[eax+4]')
	_('push ecx')
	_('call RemoveFriend')
	_('add esp,C')
	_('ljmp CommandReturn')
EndFunc

Func AssemblerCreateAttributeCommands()
	_('CommandIncreaseAttribute:')
	_('mov edx,dword[eax+4]')
	_('push edx')
	_('mov ecx,dword[eax+8]')
	_('push ecx')
	_('call IncreaseAttribute')
	_('add esp,8')
	_('ljmp CommandReturn')

	_('CommandDecreaseAttribute:')
	_('mov edx,dword[eax+4]')
	_('push edx')
	_('mov ecx,dword[eax+8]')
	_('push ecx')
	_('call DecreaseAttribute')
	_('add esp,8')
	_('ljmp CommandReturn')
EndFunc

Func AssemblerCreateSellItemCommand()
	_('CommandSellItem:')
	_('push 0')
	_('push 0')
	_('push 0')
	_('push dword[eax+C]')
	_('add eax,4')
	_('mov ecx,[eax]')
	_('test ecx,ecx')
	_('jz SellItemAll')
	_('push eax')
	_('jmp SellItemContinue')
	_('SellItemAll:')
	_('push 0')
	_('SellItemContinue:')
	_('add eax,4')
	_('push eax')
	_('push 1')
	_('push 0')
	_('push B')
	_('call Transaction')
	_('add esp,24')
	_('ljmp CommandReturn')
EndFunc

Func AssemblerCreateBuyItemCommand()
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
	_('call Transaction')
	_('add esp,24')
	_('ljmp CommandReturn')
EndFunc

Func AssemblerCreateCraftItemCommand()
	_('CommandCraftItem:')
	_('add eax,4')
	_('push eax')
	_('add eax,4')
	_('push eax')
	_('push 1')
	_('push 0')
	_('push 0')
	_('lea edi,[eax+C]')
	_('push edi')
	_('push dword[eax+8]')
	_('push dword[eax+4]')
	_('push 3')
	_('call Transaction')
	_('add esp,24')
	_('mov dword[TraderCostID],0')
	_('ljmp CommandReturn')
EndFunc

Func AssemblerCreateCollectorExchangeCommand()
	_('CommandCollectorExchange:')
	_('mov edx,eax')
	_('push 0')
	_('lea ecx,[edx+4]')
	_('push ecx')
	_('push 1')
	_('push 0')
	_('lea eax,[edx+C]')
	_('push eax')
	_('mov ebx,[edx+8]')
	_('lea ecx,[edx+ebx*4+C]')
	_('push ecx')
	_('push ebx')
	_('push 0')
	_('push 2')
	_('call Transaction')
	_('add esp,24')
	_('ljmp CommandReturn')
EndFunc

Func AssemblerCreateRequestQuoteCommand()
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
	_('call RequestQuote')
	_('add esp,20')
	_('ljmp CommandReturn')
EndFunc

Func AssemblerCreateRequestQuoteSellCommand()
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
	_('call RequestQuote')
	_('add esp,20')
	_('ljmp CommandReturn')
EndFunc

Func AssemblerCreateTraderBuyCommand()
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
	_('call Transaction')
	_('add esp,24')
	_('mov dword[TraderCostID],0')
	_('mov dword[TraderCostValue],0')
	_('ljmp CommandReturn')
EndFunc

Func AssemblerCreateTraderSellCommand()
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
	_('call Transaction')
	_('add esp,24')
	_('mov dword[TraderCostID],0')
	_('mov dword[TraderCostValue],0')
	_('ljmp CommandReturn')
EndFunc

Func AssemblerCreateSalvageCommand()
	_('CommandSalvage:')
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
	_('call Salvage')
	_('add esp,C')
	_('ljmp CommandReturn')
EndFunc

Func AssemblerCreateAgentCommands()
	_('CommandChangeTarget:')
	_('xor edx,edx')
	_('push edx')
	_('mov eax,dword[eax+4]')
	_('push eax')
	_('call ChangeTarget')
	_('add esp,8')
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
EndFunc

Func AssemblerCreateMapCommands()
	_('CommandMove:')
	_('lea eax,dword[eax+4]')
	_('push eax')
	_('call Move')
	_('pop eax')
	_('ljmp CommandReturn')
EndFunc

Func AssemblerCreateTradeCommands()
	_('CommandTradeInitiate:')
	_('push dword[eax+8]')
	_('push dword[eax+4]')
	_('call UIMessage')
	_('add esp,8')
	_('ljmp CommandReturn')

	_('CommandTradeCancel:')
	_('call TradeCancel')
	_('ljmp CommandReturn')

	_('CommandTradeAccept:')
	_('call TradeAccept')
	_('ljmp CommandReturn')

	_('CommandTradeSubmitOffer:')
	_('push dword[eax+4]')
	_('call TradeSubmitOffer')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandTradeOfferItem:')
	_('push dword[eax+8]')
	_('push dword[eax+4]')
	_('call TradeOfferItem')
	_('add esp,8')
	_('ljmp CommandReturn')
EndFunc

Func AssemblerCreateUICommands()
	_('CommandUIMsg:')
	_('push 0')
	_('mov edx,eax')
	_('add edx,8')
	_('push edx')
	_('push dword[eax+4]')
	_('call UIMessage')
	_('add esp,C')
	_('ljmp CommandReturn')

	_('CommandDialog:')
	_('push dword[eax+4]')
	_('call Dialog')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandOpenChest:')
	_('push dword[eax+4]')
	_('call OpenChest')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandAddNPC:')
	_('push dword[eax+4]')
	_('call AddNPC')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandAddHero:')
	_('push dword[eax+4]')
	_('call AddHero')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandKickNPC:')
	_('push dword[eax+4]')
	_('call KickNPC')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandKickHero:')
	_('push dword[eax+4]')
	_('call KickHero')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandLeaveGroup:')
	_('push dword[eax+4]')
	_('call LeaveGroup')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandSetDifficulty:')
	_('push dword[eax+4]')
	_('call SetDifficulty')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandEnterMission:')
	_('push dword[eax+4]')
	_('call EnterMission')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandFlagHero:')
	_('mov ecx,eax')
	_('add ecx,8')
	_('push ecx')
	_('mov eax,dword[eax+4]')
	_('push eax')
	_('call FlagHero')
	_('add esp,8')
	_('ljmp CommandReturn')

	_('CommandFlagAll:')
	_('mov ecx,eax')
	_('add ecx,4')
	_('push ecx')
	_('call FlagAll')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandSetHeroBehavior:')
	_('push dword[eax+8]')
	_('push dword[eax+4]')
	_('call SetHeroBehavior')
	_('add esp,8')
	_('ljmp CommandReturn')

	_('CommandDropHeroBundle:')
	_('push dword[eax+4]')
	_('call DropHeroBundle')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandLockHeroTarget:')
	_('push dword[eax+8]')
	_('push dword[eax+4]')
	_('call LockHeroTarget')
	_('add esp,8')
	_('ljmp CommandReturn')

	_('CommandToggleHeroSkillState:')
	_('push dword[eax+8]')
	_('push dword[eax+4]')
	_('call ToggleHeroSkillState')
	_('add esp,8')
	_('ljmp CommandReturn')

	_('CommandActiveQuest:')
	_('push dword[eax+4]')
	_('call ActiveQuest')
	_('add esp,4')
	_('ljmp CommandReturn')
EndFunc

Func AssemblerCreatePartyCommands()
	_('CommandAddPlayer:')
	_('push dword[eax+4]')
	_('call AddPlayer')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandKickPlayer:')
	_('push dword[eax+4]')
	_('call KickPlayer')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandKickInvitedPlayer:')
	_('push dword[eax+4]')
	_('call KickInvitedPlayer')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandRejectInvitation:')
	_('push dword[eax+4]')
	_('call RejectInvitation')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandAcceptInvitation:')
	_('push dword[eax+4]')
	_('call AcceptInvitation')
	_('add esp,4')
	_('ljmp CommandReturn')
EndFunc


#Region Assembler
;~ Quick and dirty x86assembler unit
Func _($asm)
	Local $buffer
	Local $opCode
	Select
		Case StringLeft($asm, 1) = ';'
			Return
		Case StringInStr($asm, ' -> ')
			Local $split = StringSplit($asm, ' -> ', 1)
			$opCode = StringReplace($split[2], ' ', '')
			$asm_injection_size += 0.5 * StringLen($opCode)
			$asm_injection_string &= $opCode
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
		Case StringLeft($asm, 3) = 'jb '
			$asm_injection_size += 2
			$asm_injection_string &= '72(' & StringRight($asm, StringLen($asm) - 3) & ')'
		Case StringLeft($asm, 3) = 'je '
			$asm_injection_size += 2
			$asm_injection_string &= '74(' & StringRight($asm, StringLen($asm) - 3) & ')'
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

		Case StringRegExp($asm, 'call dword[[][a-z,A-Z]{4,}[]]')
			$asm_injection_size += 6
			$asm_injection_string &= 'FF15[' & StringMid($asm, 12, StringLen($asm) - 12) & ']'
		Case StringLeft($asm, 5) = 'call ' And StringLen($asm) > 8
			$asm_injection_size += 5
			$asm_injection_string &= 'E8{' & StringMid($asm, 6, StringLen($asm) - 5) & '}'
		Case StringRegExp($asm, 'fstp dword[[][a-z,A-Z]{4,}[]]')
			$asm_injection_size += 6
			$asm_injection_string &= 'D91D[' & StringMid($asm, 12, StringLen($asm) - 12) & ']'
		Case StringRegExp($asm, 'retn [0-9A-Fa-f]+h')
			Local $value = StringRegExpReplace($asm, 'retn ([0-9A-Fa-f]+)h', '$1')
			$value = Dec($value)
			$asm_injection_size += 3
			$asm_injection_string &= 'C2' & SwapEndian(Hex($value, 4))
		Case StringRegExp($asm, 'retn 0x[0-9A-Fa-f]+')
			Local $value = StringRegExpReplace($asm, 'retn 0x([0-9A-Fa-f]+)', '$1')
			$value = Dec($value)
			$asm_injection_size += 3
			$asm_injection_string &= 'C2' & SwapEndian(Hex($value, 4))
		Case StringRegExp($asm, 'retn [-[:xdigit:]]{1,4}\z')
			Local $value = StringMid($asm, 6)
			$asm_injection_size += 3
			$asm_injection_string &= 'C2' & SwapEndian(Hex(Number($value), 4))
		Case StringRegExp($asm, 'cmp ebx,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asm_injection_size += 6
			$asm_injection_string &= '81FB[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'cmp edx,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asm_injection_size += 6
			$asm_injection_string &= '81FA[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'cmp eax,[0-9A-Fa-f]+\z')
			Local $value = Dec(StringMid($asm, 9))
			If $value <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '83F8' & Hex($value, 2)
			Else
				$asm_injection_size += 5
				$asm_injection_string &= '3D' & SwapEndian(Hex($value, 8))
			EndIf
		Case StringRegExp($asm, 'cmp eax,[-[:xdigit:]]{1,2}\z')
			Local $value = StringMid($asm, 9)
			If StringLen($value) <= 2 Then
				$asm_injection_size += 3
				$asm_injection_string &= '83F8' & Hex(Number($value), 2)
			Else
				$asm_injection_size += 5
				$asm_injection_string &= '3D' & ASMNumber($value)
			EndIf
		Case StringRegExp($asm, 'cmp ebx,[-[:xdigit:]]{1,2}\z')
			Local $value = StringMid($asm, 9)
			$asm_injection_size += 3
			$asm_injection_string &= '83FB' & Hex(Number($value), 2)
		Case StringRegExp($asm, 'cmp ecx,[-[:xdigit:]]{1,2}\z')
			Local $value = StringMid($asm, 9)
			$asm_injection_size += 3
			$asm_injection_string &= '83F9' & Hex(Number($value), 2)
		Case StringRegExp($asm, 'cmp edx,[-[:xdigit:]]{1,2}\z')
			Local $value = StringMid($asm, 9)
			$asm_injection_size += 3
			$asm_injection_string &= '83FA' & Hex(Number($value), 2)
		Case StringRegExp($asm, 'cmp ebx,dword\[[a-z,A-Z]{4,}\]')
			$asm_injection_size += 6
			$asm_injection_string &= '3B1D[' & StringMid($asm, 15, StringLen($asm) - 15) & ']'
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
		Case StringRegExp($asm, 'cmp eax,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asm_injection_size += 5
			$asm_injection_string &= '3D[' & StringRight($asm, StringLen($asm) - 8) & ']'
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
		Case StringRegExp($asm, 'add esp,0x[0-9A-Fa-f]+')
			Local $value = StringRegExpReplace($asm, 'add esp,0x([0-9A-Fa-f]+)', '$1')
			$value = Dec($value)
			If $value <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '83C4' & Hex($value, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '81C4' & SwapEndian(Hex($value, 8))
			EndIf
		Case StringRegExp($asm, 'add eax,[0-9A-Fa-f]+h')
			Local $value = StringRegExpReplace($asm, 'add eax,([0-9A-Fa-f]+)h', '$1')
			$value = Dec($value)
			If $value <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '83C0' & Hex($value, 2)
			Else
				$asm_injection_size += 5
				$asm_injection_string &= '05' & SwapEndian(Hex($value, 8))
			EndIf
		Case StringRegExp($asm, 'add ebx,[0-9A-Fa-f]+h')
			Local $value = StringRegExpReplace($asm, 'add ebx,([0-9A-Fa-f]+)h', '$1')
			$value = Dec($value)
			If $value <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '83C3' & Hex($value, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '81C3' & SwapEndian(Hex($value, 8))
			EndIf
		Case StringRegExp($asm, 'add ebx,dword\[[a-zA-Z_][a-zA-Z0-9_]*\]')
			Local $label = StringRegExpReplace($asm, 'add ebx,dword\[([a-zA-Z_][a-zA-Z0-9_]*)\]', '$1')
			$asm_injection_size += 6
			$asm_injection_string &= '031D[' & $label & ']'
		Case StringRegExp($asm, 'add eax,dword\[[a-zA-Z_][a-zA-Z0-9_]*\]')
			Local $label = StringRegExpReplace($asm, 'add eax,dword\[([a-zA-Z_][a-zA-Z0-9_]*)\]', '$1')
			$asm_injection_size += 5
			$asm_injection_string &= '0305[' & $label & ']'
		Case StringRegExp($asm, 'add ecx,[0-9A-Fa-f]+h')
			Local $value = StringRegExpReplace($asm, 'add ecx,([0-9A-Fa-f]+)h', '$1')
			$value = Dec($value)
			If $value <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '83C1' & Hex($value, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '81C1' & SwapEndian(Hex($value, 8))
			EndIf
		Case StringRegExp($asm, 'add edx,[0-9A-Fa-f]+h')
			Local $value = StringRegExpReplace($asm, 'add edx,([0-9A-Fa-f]+)h', '$1')
			$value = Dec($value)
			If $value <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '83C2' & Hex($value, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '81C2' & SwapEndian(Hex($value, 8))
			EndIf
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
		Case StringRegExp($asm, 'add eax,[a-z,A-Z]{4,}') And StringInStr($asm, ',dword') = 0
			$asm_injection_size += 5
			$asm_injection_string &= '05[' & StringRight($asm, StringLen($asm) - 8) & ']'
		Case StringRegExp($asm, 'inc dword\[eax\+[0-9A-Fa-f]+h\]')
			Local $offset = StringRegExpReplace($asm, 'inc dword\[eax\+([0-9A-Fa-f]+)h\]', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= 'FF40' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= 'FF80' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'inc dword\[esi\+0x[0-9A-Fa-f]+\]')
			Local $offset = StringRegExpReplace($asm, 'inc dword\[esi\+0x([0-9A-Fa-f]+)\]', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= 'FF46' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= 'FF86' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'inc dword\[ebx\+[0-9A-Fa-f]+h\]')
			Local $offset = StringRegExpReplace($asm, 'inc dword\[ebx\+([0-9A-Fa-f]+)h\]', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= 'FF43' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= 'FF83' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'inc dword\[ecx\+[0-9A-Fa-f]+h\]')
			Local $offset = StringRegExpReplace($asm, 'inc dword\[ecx\+([0-9A-Fa-f]+)h\]', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= 'FF41' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= 'FF81' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'inc dword\[edx\+[0-9A-Fa-f]+h\]')
			Local $offset = StringRegExpReplace($asm, 'inc dword\[edx\+([0-9A-Fa-f]+)h\]', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= 'FF42' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= 'FF82' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'inc dword\[esi\+[0-9A-Fa-f]+h\]')
			Local $offset = StringRegExpReplace($asm, 'inc dword\[esi\+([0-9A-Fa-f]+)h\]', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= 'FF46' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= 'FF86' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'inc dword\[edi\+[0-9A-Fa-f]+h\]')
			Local $offset = StringRegExpReplace($asm, 'inc dword\[edi\+([0-9A-Fa-f]+)h\]', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= 'FF47' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= 'FF87' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'inc dword\[ebp\+[0-9A-Fa-f]+h\]')
			Local $offset = StringRegExpReplace($asm, 'inc dword\[ebp\+([0-9A-Fa-f]+)h\]', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= 'FF45' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= 'FF85' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'inc dword\[esp\+[0-9A-Fa-f]+h\]')
			Local $offset = StringRegExpReplace($asm, 'inc dword\[esp\+([0-9A-Fa-f]+)h\]', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 4
				$asm_injection_string &= 'FF4424' & Hex($offset, 2)
			Else
				$asm_injection_size += 7
				$asm_injection_string &= 'FF8424' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'inc dword\[esi\+[0-9A-Fa-f]+\]')
			Local $offset = StringRegExpReplace($asm, 'inc dword\[esi\+([0-9A-Fa-f]+)\]', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= 'FF46' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= 'FF86' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'inc dword\[[a-zA-Z_][a-zA-Z0-9_]*\]')
			Local $label = StringRegExpReplace($asm, 'inc dword\[([a-zA-Z_][a-zA-Z0-9_]*)\]', '$1')
			$asm_injection_size += 6
			$asm_injection_string &= 'FF05[' & $label & ']'
		Case StringRegExp($asm, 'dec dword\[[a-zA-Z_][a-zA-Z0-9_]*\]')
			Local $label = StringRegExpReplace($asm, 'dec dword\[([a-zA-Z_][a-zA-Z0-9_]*)\]', '$1')
			$asm_injection_size += 6
			$asm_injection_string &= 'FF0D[' & $label & ']'
		Case StringRegExp($asm, 'and ebx,[-[:xdigit:]]{1,8}\z')
			Local $value = StringMid($asm, 9)
			If StringLen($value) <= 2 And Dec($value) <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '83E3' & Hex(Dec($value), 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '81E3' & ASMNumber($value)
			EndIf
		Case StringRegExp($asm, 'and edx,[-[:xdigit:]]{1,8}\z')
			Local $value = StringMid($asm, 9)
			If StringLen($value) <= 2 And Dec($value) <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '83E2' & Hex(Dec($value), 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '81E2' & ASMNumber($value)
			EndIf
		Case StringRegExp($asm, 'and ecx,[-[:xdigit:]]{1,8}\z')
			Local $value = StringMid($asm, 9)
			$asm_injection_size += 6
			$asm_injection_string &= '81E1' & ASMNumber($value)
		Case StringRegExp($asm, 'and eax,[-[:xdigit:]]{1,8}\z')
			Local $value = StringMid($asm, 9)
			$asm_injection_size += 5
			$asm_injection_string &= '25' & ASMNumber($value)
		Case StringRegExp($asm, 'or eax,[-[:xdigit:]]{1,8}\z')
			Local $value = StringMid($asm, 8)
			$asm_injection_size += 5
			$asm_injection_string &= '0D' & ASMNumber($value)
		Case StringRegExp($asm, 'push dword\[eax\+[0-9A-Fa-f]+\]')
			Local $offset = StringRegExpReplace($asm, 'push dword\[eax\+([0-9A-Fa-f]+)\]', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= 'FF70' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= 'FFB0' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'push dword[[][a-z,A-Z]{4,}[]]')
			$asm_injection_size += 6
			$asm_injection_string &= 'FF35[' & StringMid($asm, 12, StringLen($asm) - 12) & ']'
		Case StringRegExp($asm, 'push [a-z,A-Z]{4,}\z')
			$asm_injection_size += 5
			$asm_injection_string &= '68[' & StringMid($asm, 6, StringLen($asm) - 5) & ']'
		Case StringRegExp($asm, 'push [-[:xdigit:]]{1,8}\z')
			$buffer = ASMNumber(StringMid($asm, 6), True)
			If @extended Then
				$asm_injection_size += 2
				$asm_injection_string &= '6A' & $buffer
			Else
				$asm_injection_size += 5
				$asm_injection_string &= '68' & $buffer
			EndIf
		Case StringRegExp($asm, 'lea eax,dword[[]ecx[*]8[+][a-z,A-Z]{4,}[]]')
			$asm_injection_size += 7
			$asm_injection_string &= '8D04CD[' & StringMid($asm, 21, StringLen($asm) - 21) & ']'
		Case StringRegExp($asm, 'lea edi,dword\[edx\+[a-z,A-Z]{4,}\]')
			$asm_injection_size += 7
			$asm_injection_string &= '8D3C15[' & StringMid($asm, 19, StringLen($asm) - 19) & ']'
		Case StringRegExp($asm, 'lea eax,dword[[]edx[*]4[+][a-z,A-Z]{4,}[]]')
			$asm_injection_size += 7
			$asm_injection_string &= '8D0495[' & StringMid($asm, 21, StringLen($asm) - 21) & ']'
		Case StringRegExp($asm, 'mov eax,dword\[esp\+[0-9A-Fa-f]+h?\]')
			Local $offset = StringRegExpReplace($asm, 'mov eax,dword\[esp\+([0-9A-Fa-f]+)h?\]', '$1')
			$offset = StringReplace($offset, 'h', '')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 4
				$asm_injection_string &= '8B4424' & Hex($offset, 2)
			Else
				$asm_injection_size += 7
				$asm_injection_string &= '8B8424' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'mov ebx,dword\[esp\+[0-9A-Fa-f]+h?\]')
			Local $offset = StringRegExpReplace($asm, 'mov ebx,dword\[esp\+([0-9A-Fa-f]+)h?\]', '$1')
			$offset = StringReplace($offset, 'h', '')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 4
				$asm_injection_string &= '8B5C24' & Hex($offset, 2)
			Else
				$asm_injection_size += 7
				$asm_injection_string &= '8B9C24' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'mov ecx,dword\[esp\+[0-9A-Fa-f]+h?\]')
			Local $offset = StringRegExpReplace($asm, 'mov ecx,dword\[esp\+([0-9A-Fa-f]+)h?\]', '$1')
			$offset = StringReplace($offset, 'h', '')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 4
				$asm_injection_string &= '8B4C24' & Hex($offset, 2)
			Else
				$asm_injection_size += 7
				$asm_injection_string &= '8B8C24' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'mov edx,dword\[esp\+[0-9A-Fa-f]+h?\]')
			Local $offset = StringRegExpReplace($asm, 'mov edx,dword\[esp\+([0-9A-Fa-f]+)h?\]', '$1')
			$offset = StringReplace($offset, 'h', '')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 4
				$asm_injection_string &= '8B5424' & Hex($offset, 2)
			Else
				$asm_injection_size += 7
				$asm_injection_string &= '8B9424' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'mov esi,dword\[esp\+[0-9A-Fa-f]+h?\]')
			Local $offset = StringRegExpReplace($asm, 'mov esi,dword\[esp\+([0-9A-Fa-f]+)h?\]', '$1')
			$offset = StringReplace($offset, 'h', '')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 4
				$asm_injection_string &= '8B7424' & Hex($offset, 2)
			Else
				$asm_injection_size += 7
				$asm_injection_string &= '8BB424' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'mov edi,dword\[esp\+[0-9A-Fa-f]+h?\]')
			Local $offset = StringRegExpReplace($asm, 'mov edi,dword\[esp\+([0-9A-Fa-f]+)h?\]', '$1')
			$offset = StringReplace($offset, 'h', '')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 4
				$asm_injection_string &= '8B7C24' & Hex($offset, 2)
			Else
				$asm_injection_size += 7
				$asm_injection_string &= '8BBC24' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'mov ebp,dword\[esp\+[0-9A-Fa-f]+h?\]')
			Local $offset = StringRegExpReplace($asm, 'mov ebp,dword\[esp\+([0-9A-Fa-f]+)h?\]', '$1')
			$offset = StringReplace($offset, 'h', '')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 4
				$asm_injection_string &= '8B6C24' & Hex($offset, 2)
			Else
				$asm_injection_size += 7
				$asm_injection_string &= '8BAC24' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'mov dword\[eax\],0x[0-9A-Fa-f]+\z')
			Local $value = StringMid($asm, 15)
			$value = StringReplace($value, '0x', '')
			$asm_injection_size += 6
			$asm_injection_string &= 'C700' & SwapEndian(Hex(Dec('0x' & $value), 8))
		Case StringLeft($asm, 17) = 'mov edx,dword[esi]'
			$asm_injection_size += 2
			$asm_injection_string &= '8B16'
		Case StringLeft($asm, 17) = 'mov edx,dword[edi]'
			$asm_injection_size += 2
			$asm_injection_string &= '8B17'
		Case StringLeft($asm, 17) = 'mov eax,dword[esi]'
			$asm_injection_size += 2
			$asm_injection_string &= '8B06'
		Case StringLeft($asm, 17) = 'mov eax,dword[edi]'
			$asm_injection_size += 2
			$asm_injection_string &= '8B07'
		Case StringLeft($asm, 17) = 'mov ecx,dword[esi]'
			$asm_injection_size += 2
			$asm_injection_string &= '8B0E'
		Case StringLeft($asm, 17) = 'mov ecx,dword[edi]'
			$asm_injection_size += 2
			$asm_injection_string &= '8B0F'
		Case StringLeft($asm, 17) = 'mov ebx,dword[esi]'
			$asm_injection_size += 2
			$asm_injection_string &= '8B1E'
		Case StringLeft($asm, 17) = 'mov ebx,dword[edi]'
			$asm_injection_size += 2
			$asm_injection_string &= '8B1F'
		Case StringRegExp($asm, 'mov dword\[eax\+[0-9A-Fa-f]+\],esi')
			Local $offset = StringRegExpReplace($asm, 'mov dword\[eax\+([0-9A-Fa-f]+)\],esi', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '8970' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '89B0' & SwapEndian(Hex($offset, 8))
			EndIf
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
		Case StringRegExp($asm, 'mov dword[[][a-z,A-Z]{4,}[]],edx')
			$asm_injection_size += 6
			$asm_injection_string &= '8915[' & StringMid($asm, 11, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'mov dword[[][a-z,A-Z]{4,}[]],eax')
			$asm_injection_size += 5
			$asm_injection_string &= 'A3[' & StringMid($asm, 11, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'mov dword[[][a-z,A-Z]{4,}[]],esi')
			$asm_injection_size += 6
			$asm_injection_string &= '8935[' & StringMid($asm, 11, StringLen($asm) - 15) & ']'
		Case StringRegExp($asm, 'mov eax,dword[[]ecx[*]4[+][a-z,A-Z]{4,}[]]')
			$asm_injection_size += 7
			$asm_injection_string &= '8B048D[' & StringMid($asm, 21, StringLen($asm) - 21) & ']'
		Case StringRegExp($asm, 'mov ecx,dword[[]ecx[*]4[+][a-z,A-Z]{4,}[]]')
			$asm_injection_size += 7
			$asm_injection_string &= '8B0C8D[' & StringMid($asm, 21, StringLen($asm) - 21) & ']'
		Case StringRegExp($asm, 'mov dword\[[a-z,A-Z]{4,}\],[-[:xdigit:]]{1,8}\z')
			$buffer = StringInStr($asm, ',')
			$asm_injection_size += 10
			$asm_injection_string &= 'C705[' & StringMid($asm, 11, $buffer - 12) & ']' & ASMNumber(StringMid($asm, $buffer + 1))
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
		Case StringRegExp($asm, 'mov ecx,dword\[eax\+[0-9A-Fa-f]+\]')
			Local $offset = StringRegExpReplace($asm, 'mov ecx,dword\[eax\+([0-9A-Fa-f]+)\]', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '8B48' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '8B88' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'mov edx,dword\[eax\+[0-9A-Fa-f]+\]')
			Local $offset = StringRegExpReplace($asm, 'mov edx,dword\[eax\+([0-9A-Fa-f]+)\]', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '8B50' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '8B90' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'mov esi,dword\[ebp\+[0-9A-Fa-f]+\]')
			Local $offset = StringRegExpReplace($asm, 'mov esi,dword\[ebp\+([0-9A-Fa-f]+)\]', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '8B75' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '8BB5' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'mov edi,dword\[ebp\+[0-9A-Fa-f]+\]')
			Local $offset = StringRegExpReplace($asm, 'mov edi,dword\[ebp\+([0-9A-Fa-f]+)\]', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '8B7D' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '8BBD' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'mov ebx,dword\[ebp\+[0-9A-Fa-f]+\]')
			Local $offset = StringRegExpReplace($asm, 'mov ebx,dword\[ebp\+([0-9A-Fa-f]+)\]', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '8B5D' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '8B9D' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'mov edx,dword\[ebp\+[0-9A-Fa-f]+\]')
			Local $offset = StringRegExpReplace($asm, 'mov edx,dword\[ebp\+([0-9A-Fa-f]+)\]', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '8B55' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '8B95' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'mov dword\[eax\+[0-9A-Fa-f]+\],0')
			Local $offset = StringRegExpReplace($asm, 'mov dword\[eax\+([0-9A-Fa-f]+)\],0', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 7
				$asm_injection_string &= 'C740' & Hex($offset, 2) & '00000000'
			Else
				$asm_injection_size += 10
				$asm_injection_string &= 'C780' & SwapEndian(Hex($offset, 8)) & '00000000'
			EndIf
		Case StringRegExp($asm, 'mov dword\[ebx\+[0-9A-Fa-f]+\],0')
			Local $offset = StringRegExpReplace($asm, 'mov dword\[ebx\+([0-9A-Fa-f]+)\],0', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 7
				$asm_injection_string &= 'C743' & Hex($offset, 2) & '00000000'
			Else
				$asm_injection_size += 10
				$asm_injection_string &= 'C783' & SwapEndian(Hex($offset, 8)) & '00000000'
			EndIf
		Case StringRegExp($asm, 'mov dword\[ecx\+[0-9A-Fa-f]+\],0')
			Local $offset = StringRegExpReplace($asm, 'mov dword\[ecx\+([0-9A-Fa-f]+)\],0', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 7
				$asm_injection_string &= 'C741' & Hex($offset, 2) & '00000000'
			Else
				$asm_injection_size += 10
				$asm_injection_string &= 'C781' & SwapEndian(Hex($offset, 8)) & '00000000'
			EndIf
		Case StringRegExp($asm, 'mov dword\[edx\+[0-9A-Fa-f]+\],0')
			Local $offset = StringRegExpReplace($asm, 'mov dword\[edx\+([0-9A-Fa-f]+)\],0', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 7
				$asm_injection_string &= 'C742' & Hex($offset, 2) & '00000000'
			Else
				$asm_injection_size += 10
				$asm_injection_string &= 'C782' & SwapEndian(Hex($offset, 8)) & '00000000'
			EndIf
		Case StringRegExp($asm, 'mov dword\[eax\],[-[:xdigit:]]{1,8}\z')
			Local $value = StringMid($asm, 15)
			$asm_injection_size += 6
			$asm_injection_string &= 'C700' & ASMNumber($value)
		Case StringRegExp($asm, 'mov dword\[ebx\],[-[:xdigit:]]{1,8}\z')
			Local $value = StringMid($asm, 15)
			$asm_injection_size += 6
			$asm_injection_string &= 'C703' & ASMNumber($value)
		Case StringRegExp($asm, 'mov dword\[ecx\],[-[:xdigit:]]{1,8}\z')
			Local $value = StringMid($asm, 15)
			$asm_injection_size += 6
			$asm_injection_string &= 'C701' & ASMNumber($value)
		Case StringRegExp($asm, 'mov dword\[edx\],[-[:xdigit:]]{1,8}\z')
			Local $value = StringMid($asm, 15)
			$asm_injection_size += 6
			$asm_injection_string &= 'C702' & ASMNumber($value)
		Case StringRegExp($asm, 'mov dword\[eax\],[0-9]\z')
			Local $value = StringMid($asm, 15)
			$asm_injection_size += 6
			$asm_injection_string &= 'C700' & SwapEndian(Hex(Number($value), 8))
		Case StringRegExp($asm, 'mov dword\[eax\],\d+\z')
			Local $value = Number(StringMid($asm, 15))
			If $value <= 127 Then
				$asm_injection_size += 6
				$asm_injection_string &= 'C700' & SwapEndian(Hex($value, 8))
			Else
				$asm_injection_size += 6
				$asm_injection_string &= 'C700' & ASMNumber($value)
			EndIf
		Case StringRegExp($asm, 'mov dword\[eax\+[0-9A-Fa-f]+\],eax')
			Local $offset = StringRegExpReplace($asm, 'mov dword\[eax\+([0-9A-Fa-f]+)\],eax', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '8940' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '8980' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'mov dword\[eax\+[0-9A-Fa-f]+\],ebx')
			Local $offset = StringRegExpReplace($asm, 'mov dword\[eax\+([0-9A-Fa-f]+)\],ebx', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '8958' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '8998' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'mov dword\[eax\+[0-9A-Fa-f]+\],ecx')
			Local $offset = StringRegExpReplace($asm, 'mov dword\[eax\+([0-9A-Fa-f]+)\],ecx', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '8948' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '8988' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'mov dword\[eax\+[0-9A-Fa-f]+\],edx')
			Local $offset = StringRegExpReplace($asm, 'mov dword\[eax\+([0-9A-Fa-f]+)\],edx', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '8950' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '8990' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'mov dword\[eax\+[0-9A-Fa-f]+\],esi')
			Local $offset = StringRegExpReplace($asm, 'mov dword\[eax\+([0-9A-Fa-f]+)\],esi', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '8970' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '89B0' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'mov dword\[eax\+[0-9A-Fa-f]+\],edi')
			Local $offset = StringRegExpReplace($asm, 'mov dword\[eax\+([0-9A-Fa-f]+)\],edi', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '8978' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '89B8' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'mov dword\[eax\+[0-9A-Fa-f]+\],ebp')
			Local $offset = StringRegExpReplace($asm, 'mov dword\[eax\+([0-9A-Fa-f]+)\],ebp', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '8968' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '89A8' & SwapEndian(Hex($offset, 8))
			EndIf
		Case StringRegExp($asm, 'mov dword\[eax\+[0-9A-Fa-f]+\],esp')
			Local $offset = StringRegExpReplace($asm, 'mov dword\[eax\+([0-9A-Fa-f]+)\],esp', '$1')
			$offset = Dec($offset)
			If $offset <= 0x7F Then
				$asm_injection_size += 3
				$asm_injection_string &= '8960' & Hex($offset, 2)
			Else
				$asm_injection_size += 6
				$asm_injection_string &= '89A0' & SwapEndian(Hex($offset, 8))
			EndIf
		Case Else
			Local $opCode
			Switch $asm
				Case 'Flag_'
					$opCode = '9090903434'
				Case 'clc'
					$opCode = 'F8'
				Case 'retn'
					$opCode = 'C3'
				Case 'retn 10'
					$opCode = 'C21000'
				Case 'nop'
					$opCode = '90'
				Case 'pushad'
					$opCode = '60'
				Case 'popad'
					$opCode = '61'
				Case 'pushfd'
					$opCode = '9C'
				Case 'popfd'
					$opCode = '9D'
				Case 'pushf'
					$opCode = '9C'
				Case 'popf'
					$opCode = '9D'
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
				Case 'push dword[ebp+8]'
					$opCode = 'FF7508'
				Case 'fld st(0),dword[ebp+8]'
					$opCode = 'D94508'
				Case 'repe movsb'
					$opCode = 'F3A4'
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
				Case 'pop ebp'
					$opCode = '5D'
				Case 'pop edi'
					$opCode = '5F'
				Case 'inc eax'
					$opCode = '40'
				Case 'inc ecx'
					$opCode = '41'
				Case 'inc ebx'
					$opCode = '43'
				Case 'inc edx'
					$opCode = '42'
				Case 'dec edx'
					$opCode = '4A'
				Case 'dec ecx'
					$opCode = '49'
				Case 'test eax,eax'
					$opCode = '85C0'
				Case 'test ax,ax'
					$opCode = '6685C0'
				Case 'test ebx,ebx'
					$opCode = '85DB'
				Case 'test ecx,ecx'
					$opCode = '85C9'
				Case 'test dx,dx'
					$opCode = '6685D2'
				Case 'test al,al'
					$opCode = '84C0'
				Case 'test esi,esi'
					$opCode = '85F6'
				Case 'test al,1'
					$opCode = 'A801'
				Case 'test edx,edx'
					$opCode = '85D2'
				Case 'test ebx,40001'
					$opCode = 'F7C301000400'
				Case 'test ebx,1'
					$opCode = 'F7C301000000'
				Case 'test ebx,40000'
					$opCode = 'F7C300000400'
				Case 'test ebx,40001'
					$opCode = 'F7C301000400'
				Case 'test eax,1DA'
					$opCode = 'A9DA010000'
				Case 'xor eax,eax'
					$opCode = '33C0'
				Case 'xor ecx,ecx'
					$opCode = '33C9'
				Case 'xor edx,edx'
					$opCode = '33D2'
				Case 'xor ebx,ebx'
					$opCode = '33DB'
				Case 'sub eax,4'
					$opCode = '83E804'
				Case 'sub esp,8'
					$opCode = '83EC08'
				Case 'sub esi,4'
					$opCode = '83EE04'
				Case 'sub esp,14'
					$opCode = '83EC14'
				Case 'sub eax,C'
					$opCode = '83E80C'
				Case 'sub esp,16'
					$opCode = '83EC10'
				Case 'sub esp,12'
					$opCode = '83EC0C'
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
				Case 'lea ecx,dword[eax+180]'
					$opCode = '8D8880010000'
				Case 'lea edi,dword[edx+ebx]'
					$opCode = '8D3C1A'
				Case 'lea edi,dword[edx+8]'
					$opCode = '8D7A08'
				Case 'lea esi,dword[esi+ebx*4]'
					$opCode = '8D349E'
				Case 'lea ecx,dword[ecx+ecx*2]'
					$opCode = '8D0C49'
				Case 'lea ecx,dword[ebx+ecx*4]'
					$opCode = '8D0C8B'
				Case 'lea ecx,dword[ecx+18]'
					$opCode = '8D4918'
				Case 'lea ecx,dword[ebx+18]'
					$opCode = '8D4B18'
				Case 'shl eax,4'
					$opCode = 'C1E004'
				Case 'shl eax,8'
					$opCode = 'C1E008'
				Case 'shl eax,6'
					$opCode = 'C1E006'
				Case 'shl eax,7'
					$opCode = 'C1E007'
				Case 'shl eax,9'
					$opCode = 'C1E009'
				Case 'shl ebx,8'
					$opCode = 'C1E308'
				Case 'shl edx,16'
					$opCode = 'C1E210'
				Case 'shl ebx,16'
					$opCode = 'C1E310'
				Case 'shl esi,8'
					$opCode = 'C1E608'
				Case 'add ebx,ecx'
					$opCode = '03D9'
				Case 'add esi,D'
					$opCode = '83C60D'
				Case 'add esi,12'
					$opCode = '83C612'
				Case 'add edi,8'
					$opCode = '83C708'
				Case 'add eax,ebx'
					$opCode = '03C3'
				Case 'add ecx,edx'
					$opCode = '03CA'
				Case 'add eax,esi'
					$opCode = '03C6'
				Case 'add esp,16'
					$opCode = '83C410'
				Case 'add esp,12'
					$opCode = '83C40C'
				Case 'or eax,esi'
					$opCode = '0BC6'
				Case 'or eax,edi'
					$opCode = '0BC7'
				Case 'or ecx,ebx'
					$opCode = '0BCB'
				Case 'or eax,ebx'
					$opCode = '0BC3'
				Case 'and ecx,0xFFFF'
					$opCode = '81E1FFFF0000'
				Case 'and eax,0xFFFF'
					$opCode = '25FFFF0000'
				Case 'and eax,0xF'
					$opCode = '83E00F'
				Case 'and eax,0xFF'
					$opCode = '25FF000000'
				Case 'and eax,0xFFFF'
					$opCode = '25FFFF0000'
				Case 'and ebx,0xF'
					$opCode = '83E30F'
				Case 'and ecx,0xF'
					$opCode = '83E10F'
				Case 'and edx,0xF'
					$opCode = '83E20F'
				Case 'imul ebx,ebx,7C'
					$opCode = '6BDB7C'
				Case 'imul eax,eax,7C'
					$opCode = '6BC07C'
				Case 'cmp ecx,4'
					$opCode = '83F904'
				Case 'cmp ecx,32'
					$opCode = '83F932'
				Case 'cmp ecx,3C'
					$opCode = '83F93C'
				Case 'cmp eax,2'
					$opCode = '83F802'
				Case 'cmp eax,0'
					$opCode = '83F800'
				Case 'cmp eax,B'
					$opCode = '83F80B'
				Case 'cmp eax,200'
					$opCode = '3D00020000'
				Case 'cmp word[edx],0'
					$opCode = '66833A00'
				Case 'cmp eax,ebx'
					$opCode = '3BC3'
				Case 'cmp eax,ecx'
					$opCode = '3BC1'
				Case 'cmp edx,esi'
					$opCode = '3BD6'
				Case 'cmp ecx,1050000'
					$opCode = '81F900000501'
				Case 'cmp eax,-1'
					$opCode = '83F8FF'
				Case 'cmp al,ah'
					$opCode = '3AC4'
				Case 'cmp eax,1'
					$opCode = '83F801'
				Case 'cmp ebx,edi'
					$opCode = '3BDF'
				Case 'cmp edx,ecx'
					$opCode = '39CA'
				Case 'cmp eax,dword[esi+9C]'
					$opCode = '3B869C000000'
				Case 'cmp al,f'
					$opCode = '3C0F'
				Case 'cmp ah,00'
					$opCode = '80FC00'
				Case 'cmp bl,AA'
					$opCode = '80FBAA'
				Case 'cmp bl,B9'
					$opCode = '80FBB9'
				Case 'cmp al,BA'
					$opCode = '3CBA'
				Case 'cmp ebx,esi'
					$opCode = '3BDE'
				Case 'cmp eax,1DA'
					$opCode = '3DDA010000'
				Case 'mov ebx,dword[eax]'
					$opCode = '8B18'
				Case 'mov ebx,dword[ecx]'
					$opCode = '8B19'
				Case 'mov ecx,dword[ebx+ecx]'
					$opCode = '8B0C0B'
				Case 'mov ecx,[ecx]'
					$opCode = '8B09'
				Case 'mov ax,word[esi]'
					$opCode = '668B06'
					Case 'mov word[edi],ax'
					$opCode = '668907'
				Case 'mov word[esi],ax'
					$opCode = '668906'
				Case 'mov dword[eax],0'
					$opCode = 'C70000000000'
				Case 'mov edi,edx'
					$opCode = '8BFA'
				Case 'mov ecx,esi'
					$opCode = '8BCE'
				Case 'mov ecx,edi'
					$opCode = '8BCF'
				Case 'mov ecx,esp'
					$opCode = '8BCC'
				Case 'mov edx,eax'
					$opCode = '8BD0'
				Case 'mov edx,ecx'
					$opCode = '8BD1'
				Case 'mov ebp,esp'
					$opCode = '8BEC'
				Case 'mov ecx,edx'
					$opCode = '8BCA'
				Case 'mov eax,ecx'
					$opCode = '8BC1'
				Case 'mov eax,esp'
					$opCode = '8BC4'
				Case 'mov eax,[ebp+10]'
					$opCode = '8B4510'
				Case 'mov eax,dword[ebp+10]'
					$opCode = '8B4510'
				Case 'mov esi,[ebp+C]'
					$opCode = '8B750C'
				Case 'mov esi,[ebp+0C]'
					$opCode = '8B750C'
				Case 'mov esi,dword[ebp+C]'
					$opCode = '8B750C'
				Case 'mov esi,dword[ebp+0C]'
					$opCode = '8B750C'
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
				Case 'mov dword[edi],eax'
					$opCode = '8907'
				Case 'mov edx,dword[eax+4]'
					$opCode = '8B5004'
				Case 'mov edx,dword[eax+8]'
					$opCode = '8B5008'
				Case 'mov edx,dword[eax+c]'
					$opCode = '8B500C'
				Case 'mov edx,dword[esi+1c]'
					$opCode = '8B561C'
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
				Case 'mov esp,ebp'
					$opCode = '8BE5'
				Case 'mov edi,eax'
					$opCode = '8BF8'
				Case 'mov dx,word[ecx]'
					$opCode = '668B11'
				Case 'mov dx,word[edx]'
					$opCode = '668B12'
				Case 'mov word[eax],dx'
					$opCode = '668910'
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
				Case 'mov eax,dword[ecx]'
					$opCode = '8B01'
				Case 'mov ebx,dword[ecx+14]'
					$opCode = '8B5914'
				Case 'mov eax,dword[ebx+c]'
					$opCode = '8B430C'
				Case 'mov ecx,eax'
					$opCode = '8BC8'
				Case 'mov al,byte[ecx]'
					$opCode = '8A01'
				Case 'mov ebx,dword[edx]'
					$opCode = '8B1A'
				Case 'mov ah,byte[edi]'
					$opCode = '8A27'
				Case 'mov dword[edx],0'
					$opCode = 'C70200000000'
				Case 'mov dword[ebx],ecx'
					$opCode = '890B'
				Case 'mov edi,dword[edx+4]'
					$opCode = '8B7A04'
				Case 'mov edi,dword[eax+4]'
					$opCode = '8B7804'
				Case 'mov ecx,dword[E1D684]'
					$opCode = '8B0D84D6E100'
				Case 'mov dword[edx-0x70],ecx'
					$opCode = '894A90'
				Case 'mov ecx,dword[edx+0x1C]'
					$opCode = '8B4A1C'
				Case 'mov dword[edx+0x54],ecx'
					$opCode = '894A54'
				Case 'mov ecx,dword[edx+4]'
					$opCode = '8B4A04'
				Case 'mov dword[edx-0x14],ecx'
					$opCode = '894AEC'
				Case 'mov dword[edx],ebx'
					$opCode = '891A'
				Case 'mov dword[edi],ecx'
					$opCode = '890F'
				Case 'mov dword[edx],-1'
					$opCode = 'C702FFFFFFFF'
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
				Case 'mov esi,dword[esi]'
					$opCode = '8B36'
				Case 'mov eax,dword[ebp+8]'
					$opCode = '8B4508'
				Case 'mov eax,dword[ecx+8]'
					$opCode = '8B4108'
				Case 'mov eax,[eax+2C]'
					$opCode = '8B402C'
				Case 'mov eax,[eax+680]'
					$opCode = '8B8080060000'
				Case 'mov esi,eax'
					$opCode = '8BF0'
				Case 'mov edx,dword[ecx]'
					$opCode = '8B11'
				Case 'mov dword[eax],edx'
					$opCode = '8910'
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
				Case 'mov ecx,dword[ecx+edx]'
					$opCode = '8B0C11'
				Case 'mov dword[eax],edi'
					$opCode = '8938'
				Case 'mov [eax+8],ecx'
					$opCode = '894808'
				Case 'mov [eax+C],ecx'
					$opCode = '89480C'
				Case 'mov ebx,dword[ecx-C]'
					$opCode = '8B59F4'
				Case 'mov [eax+C],ebx'
					$opCode = '89580C'
				Case 'mov ecx,[eax+8]'
					$opCode = '8B4808'
				Case 'mov ebx,dword[ebx+18]'
					$opCode = '8B5B18'
				Case 'mov ecx,dword[ecx+0xF4]'
					$opCode = '8B89F4000000'
				Case 'mov eax,edx'
					$opCode = '8BC2'
				Case 'mov esi,edx'
					$opCode = '8BF2'
				Case 'mov bl,byte[eax]'
					$opCode = '8A18'
				Case 'mov bl,byte[ecx+5]'
					$opCode = '8A5905'
				Case 'mov ebx,dword[ecx+1]'
					$opCode = '8B5901'
				Case 'mov ebx,dword[ecx+6]'
					$opCode = '8B5906'
				Case 'mov edi,dword[esi]'
					$opCode = '8B3E'
				Case 'mov ecx,dword[eax+14]'
					$opCode = '8B4814'
				Case 'mov edx,dword[eax+14]'
					$opCode = '8B5014'
				Case 'mov edx,dword[eax+18]'
					$opCode = '8B5018'
				Case 'mov edi,ecx'
					$opCode = '8BF9'
				Case 'mov edi,ebx'
					$opCode = '8BFB'
				Case 'mov esi,ecx'
					$opCode = '8BF1'
				Case 'mov esi,ebx'
					$opCode = '8BF3'
				Case 'mov edi,esi'
					$opCode = '8BFE'
				Case 'mov ebx,ecx'
					$opCode = '8BD9'
				Case 'mov eax,ebx'
					$opCode = '8BC3'
				Case 'mov eax,esi'
					$opCode = '8BC6'
				Case 'mov ecx,ebx'
					$opCode = '8BCB'
				Case 'mov ebx,edx'
					$opCode = '8BDA'
				Case 'mov esi,edx'
					$opCode = '8BF2'
				Case 'mov ebx,esi'
					$opCode = '8BDE'
				Case 'mov edx,ebx'
					$opCode = '8BD3'
				Case 'mov edx,esi'
					$opCode = '8BD6'
				Case 'mov edx,edi'
					$opCode = '8BD7'
				Case 'mov ecx,edx'
					$opCode = '8BCA'
				Case 'mov esi,edi'
					$opCode = '8BF7'
				Case 'mov ebp,eax'
					$opCode = '8BE8'
				Case 'mov ebp,ebx'
					$opCode = '8BEB'
				Case 'mov ebp,ecx'
					$opCode = '8BE9'
				Case 'mov ebp,edx'
					$opCode = '8BEA'
				Case 'mov esp,eax'
					$opCode = '8BE0'
				Case 'mov esp,ecx'
					$opCode = '8BE1'
				Case 'mov esp,edx'
					$opCode = '8BE2'
				Case 'mov esp,ebx'
					$opCode = '8BE3'
				Case 'mov esi,dword[ebp+8]'
					$opCode = '8B7508'
				Case 'mov esi,dword[ebp+C]'
					$opCode = '8B750C'
				Case 'mov esi,dword[ebp+10]'
					$opCode = '8B7510'
				Case 'mov edi,dword[ebp+8]'
					$opCode = '8B7D08'
				Case 'mov edi,dword[ebp+C]'
					$opCode = '8B7D0C'
				Case 'mov ebx,dword[ebp+8]'
					$opCode = '8B5D08'
				Case 'mov edx,dword[ebp+8]'
					$opCode = '8B5508'
				Case 'mov edx,dword[ebp+C]'
					$opCode = '8B550C'
				Case 'mov dword[eax+C],0'
					$opCode = 'C7400C00000000'
				Case 'mov dword[eax+4],edx'
					$opCode = '895004'
				Case 'mov dword[eax+4],ebx'
					$opCode = '895804'
				Case 'mov dword[eax+8],edx'
					$opCode = '895008'
				Case 'mov dword[eax+C],edx'
					$opCode = '89500C'
				Case 'mov dword[eax+C],0'
					$opCode = 'C7400C00000000'
				Case 'mov dword[eax+C],1'
					$opCode = 'C7400C01000000'
				Case 'mov edx,dword[ebp+C]'
					$opCode = '8B550C'
				Case 'mov ebx,dword[ebp+10]'
					$opCode = '8B5D10'
				Case 'mov edx,dword[ebp+10]'
					$opCode = '8B5510'
				Case 'mov esi,ebp'
					$opCode = '8BF5'
				Case 'mov ecx,dword[esi]'
					$opCode = '8B0E'
				Case 'mov ecx,dword[ebp+C]'
					$opCode = '8B4D0C'
				Case 'mov ecx,dword[ebp+10]'
					$opCode = '8B4D10'
				Case 'mov edx,dword[esi]'
					$opCode = '8B16'
				Case 'mov edx,dword[edi]'
					$opCode = '8B17'
				Case 'mov eax,dword[esi]'
					$opCode = '8B06'
				Case 'mov eax,dword[edi]'
					$opCode = '8B07'
				Case 'mov ebx,dword[esi]'
					$opCode = '8B1E'
				Case 'mov ebx,dword[edi]'
					$opCode = '8B1F'
				Case 'mov eax,dword[eax]'
					$opCode = '8B00'
				Case 'mov eax,dword[eax+18]'
					$opCode = '8B4018'
				Case 'mov eax,dword[eax+44]'
					$opCode = '8B4044'
				Case 'mov eax,dword[eax+198]'
					$opCode = '8B8098010000'
				Case 'mov ebx,dword[ebx+10]'
					$opCode = '8B5B10'
				Case 'mov ebx,dword[eax+10]'
					$opCode = '8B5810'
				Case 'mov ebx,dword[eax+19C]'
					$opCode = '8B989C010000'
				Case 'movzx ecx,di'
					$opCode = '0FB7CF'
				Case 'movzx eax,di'
					$opCode = '0FB7C7'
				Case 'movzx ecx,cx'
					$opCode = '0FB7C9'
				; SellItem
				Case 'mov ecx,[eax]'
					$opCode = '8B08'
				; Crafting
				Case 'lea edi,[eax+C]'
					$opCode = '8D780C'
				; Collector Exchange
				Case 'lea ecx,[edx+4]'
					$opCode = '8D4A04'
				Case 'lea eax,[edx+C]'
					$opCode = '8D420C'
				Case 'mov ebx,[edx+8]'
					$opCode = '8B5A08'
				Case 'lea ecx,[edx+ebx*4+C]'
					$opCode = '8D4C9A0C'
				; LoadFinished
				Case 'push dword[edi+1C]'
					$opCode = 'FF771C'
				; Action
				Case 'cmp dword[eax+C],0'
					$opCode = '83780C00'
				Case Else
					Error('Could not assemble: ' & $asm)
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