#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Contributor: Gahais
; Copyright 2025 caustic-kronos
;
; Licensed under the Apache License, Version 2.0 (the 'License');
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
; http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an 'AS IS' BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
#CE ===========================================================================

#include-once
#include <Array.au3>
#include 'Utils.au3'

; TO ADD :
#Region Unknown IDs
; Special - something like a ToT :
Global Const $ID_UNKNOWN_CONSUMABLE_1	= 5656
Global Const $ID_UNKNOWN_STACKABLE_1	= 1150
Global Const $ID_UNKNOWN_STACKABLE_2	= 1172
Global Const $ID_UNKNOWN_STACKABLE_3	= 1805
Global Const $ID_UNKNOWN_STACKABLE_4	= 4629
Global Const $ID_UNKNOWN_STACKABLE_5	= 4631
Global Const $ID_UNKNOWN_STACKABLE_6	= 5123
Global Const $ID_UNKNOWN_STACKABLE_7	= 7052
#EndRegion Unknown IDs


#Region Modes
Global Const $ID_NORMAL_MODE			= 0
Global Const $ID_HARD_MODE				= 1
#EndRegion Modes


#Region Locations
Global Const $ID_AMERICA				= 0
Global Const $ID_ASIA_KOREA				= 1
Global Const $ID_EUROPE					= 2
Global Const $ID_ASIA_CHINA				= 3
Global Const $ID_ASIA_JAPAN				= 4
Global Const $ID_INTERNATIONAL			= -2

Global Const $ID_ENGLISH				= 0
Global Const $ID_FRENCH					= 2
Global Const $ID_GERMAN					= 3
Global Const $ID_ITALIAN				= 4
Global Const $ID_SPANISH				= 5
Global Const $ID_POLISH					= 9
Global Const $ID_RUSSIAN				= 10

Global Const $ID_KOREA					= 0
Global Const $ID_CHINA					= 0
Global Const $ID_JAPAN					= 0

Global Const $ID_ENGLISH_DISTRICT		=	[$ID_ENGLISH, $ID_EUROPE]
Global Const $ID_FRENCH_DISTRICT		=	[$ID_FRENCH, $ID_EUROPE]
Global Const $ID_GERMAN_DISTRICT		=	[$ID_GERMAN, $ID_EUROPE]
Global Const $ID_ITALIAN_DISTRICT		=	[$ID_ITALIAN, $ID_EUROPE]
Global Const $ID_POLISH_DISTRICT		=	[$ID_POLISH, $ID_EUROPE]
Global Const $ID_RUSSIAN_DISTRICT		=	[$ID_RUSSIAN, $ID_EUROPE]
Global Const $ID_SPANISH_DISTRICT		=	[$ID_SPANISH, $ID_EUROPE]

Global Const $ID_AMERICAN_DISTRICT		=	[$ID_ENGLISH, $ID_AMERICA]

Global Const $ID_CHINESE_DISTRICT		=	[$ID_ENGLISH, $ID_ASIA_CHINA]
Global Const $ID_JAPANESE_DISTRICT		=	[$ID_ENGLISH, $ID_ASIA_JAPAN]
Global Const $ID_KOREAN_DISTRICT		=	[$ID_ENGLISH, $ID_ASIA_KOREA]
Global Const $ID_INTERNATIONAL_DISTRICT	=	[$ID_ENGLISH, $ID_INTERNATIONAL]

Global Const $DISTRICT_NAMES			=	['English', 'French', 'German', 'Italian', 'Polish', 'Russian', 'Spanish', 'America', 'China', 'Japan', 'Korea', 'International']
Global Const $DISTRICT_AND_REGION_IDS	=	[$ID_ENGLISH_DISTRICT, $ID_FRENCH_DISTRICT, $ID_GERMAN_DISTRICT, $ID_ITALIAN_DISTRICT, $ID_POLISH_DISTRICT, $ID_RUSSIAN_DISTRICT, _
												$ID_SPANISH_DISTRICT, $ID_AMERICAN_DISTRICT, $ID_CHINESE_DISTRICT, $ID_JAPANESE_DISTRICT, $ID_KOREAN_DISTRICT, $ID_INTERNATIONAL_DISTRICT]
Global Const $REGION_MAP				=	MapFromArrays($DISTRICT_NAMES, $DISTRICT_AND_REGION_IDS)
#EndRegion Locations


#Region Game Locations
; Locations varying seasonally and their default versions
Global Const $ID_DEFAULT_EYE_OF_THE_NORTH	= 642
GLOBAL CONST $ID_CHRISTMAS_EYE_OF_THE_NORTH	= 821
GLOBAL CONST $ID_DEFAULT_KAINENG_CITY		= 194
GLOBAL CONST $ID_KAINENG_CITY_EVENTS		= 817
; Generic
GLOBAL CONST $ID_OUTPOST					= 0
GLOBAL CONST $ID_EXPLORABLE					= 1
GLOBAL CONST $ID_LOADING					= 2
; Eden
Global Const $ID_LAKESIDE_COUNTY			= 146
Global Const $ID_ASCALON_CITY_PRESEARING	= 148
Global Const $ID_GREEN_HILLS_COUNTY			= 160
Global Const $ID_WIZARDS_FOLLY				= 161
Global Const $ID_REGENT_VALLEY				= 162
Global Const $ID_BARRADIN_ESTATE			= 163
Global Const $ID_ASHFORD_ABBEY				= 164
Global Const $ID_FOIBLES_FAIR				= 165
Global Const $ID_FORT_RANIK_PRESEARING		= 166
; Battle Isles
Global Const $ID_GREAT_TEMPLE_OF_BALTHAZAR	= 248
Global Const $ID_EMBARK_BEACH				= 857
; Common
Global Const $ID_FISSURE_OF_WOE				= 34
Global Const $ID_UNDERWORLD					= 72
; Prophecies
Global Const $ID_WARRIORS_ISLE				= 4
Global Const $ID_HUNTERS_ISLE				= 5
Global Const $ID_WIZARDS_ISLE				= 6
Global Const $ID_AUGURY_ROCK				= 38
Global Const $ID_BURNING_ISLE				= 52
Global Const $ID_LIONS_ARCH					= 55
Global Const $ID_TASCAS_DEMISE				= 92
Global Const $ID_PROPHETS_PATH				= 113
Global Const $ID_ELONA_REACH				= 118
Global Const $ID_TEMPLE_OF_THE_AGES			= 138
Global Const $ID_THE_GRANITE_CITADEL		= 156
Global Const $ID_FROZEN_ISLE				= 176
Global Const $ID_NOMADS_ISLE				= 177
Global Const $ID_DRUIDS_ISLE				= 178
Global Const $ID_ISLE_OF_THE_DEAD			= 179
; Factions
Global Const $ID_HOUSE_ZU_HELTZER			= 77
Global Const $ID_CAVALON					= 193
Global Const $ID_KAINENG_CITY				= IsAnniversaryCelebration() Or IsDragonFestival() ? $ID_KAINENG_CITY_EVENTS : $ID_DEFAULT_KAINENG_CITY
Global Const $ID_DRAZACH_THICKET			= 195
Global Const $ID_JAYA_BLUFFS				= 196
Global Const $ID_MOUNT_QINKAI				= 200
Global Const $ID_SILENT_SURF				= 203
Global Const $ID_FERNDALE					= 210
Global Const $ID_PONGMEI_VALLEY				= 211
Global Const $ID_MINISTER_CHOS_ESTATE		= 214
Global Const $ID_NAHPUI_QUARTER				= 216
Global Const $ID_BOREAS_SEABED				= 219
Global Const $ID_THE_ETERNAL_GROVE			= 222
Global Const $ID_SUNQUA_VALE				= 238
Global Const $ID_WAJJUN_BAZAAR				= 239
Global Const $ID_BUKDEK_BYWAY				= 240
Global Const $ID_SHING_JEA_MONASTERY		= 242
Global Const $ID_SEITUNG_HARBOR				= 250
Global Const $ID_URGOZ_WARREN				= 266
Global Const $ID_ISLE_OF_WEEPING_STONE		= 275
Global Const $ID_ISLE_OF_JADE				= 276
Global Const $ID_LEVIATHAN_PITS				= 279
Global Const $ID_ZIN_KU_CORRIDOR			= 284
Global Const $ID_THE_MARKETPLACE			= 303
Global Const $ID_THE_DEEP					= 307
Global Const $ID_SAINT_ANJEKAS_SHRINE		= 349
Global Const $ID_IMPERIAL_ISLE				= 359
Global Const $ID_ISLE_OF_MEDITATION			= 360
Global Const $ID_ASPENWOOD_GATE_LUXON		= 389
Global Const $ID_KAINENG_A_CHANCE_ENCOUNTER	= 861
; Nightfall
Global Const $ID_KAMADAN					= 370
Global Const $ID_SUNWARD_MARCHES			= 373
Global Const $ID_SUNSPEAR_SANCTUARY			= 387
Global Const $ID_CHANTRY_OF_SECRETS			= 393
Global Const $ID_KODASH_BAZAAR				= 414
Global Const $ID_MIRROR_OF_LYSS				= 419
Global Const $ID_MODDOK_CREVICE				= 427
Global Const $ID_COMMAND_POST				= 436
Global Const $ID_JOKOS_DOMAIN				= 437
Global Const $ID_BONE_PALACE				= 438
Global Const $ID_THE_SHATTERED_RAVINES		= 441
Global Const $ID_THE_SULFUROUS_WASTES		= 444
Global Const $ID_EBONY_CITADEL_OF_MALLYX	= 445
Global Const $ID_GATE_OF_ANGUISH			= 474
Global Const $ID_UNCHARTED_ISLE				= 529
Global Const $ID_ISLE_OF_WURMS				= 530
Global Const $ID_CORRUPTED_ISLE				= 537
Global Const $ID_ISLE_OF_SOLITUDE			= 538
Global Const $ID_REMAINS_OF_SAHLAHJA		= 545
Global Const $ID_DAJKAH_INLET				= 554
Global Const $ID_NEXUS						= 555
; EotN
Global Const $ID_GLINTS_CHALLENGE			= 37
Global Const $ID_BJORA_MARCHES				= 482
Global Const $ID_ARBOR_BAY					= 485
Global Const $ID_ICE_CLIFF_CHASMS			= 499
Global Const $ID_RIVEN_EARTH				= 501
Global Const $ID_JAGA_MORAINE				= 546
Global Const $ID_VARAJAR_FELLS				= 553
Global Const $ID_SPARKFLY_SWAMP				= 558
Global Const $ID_VERDANT_CASCADES			= 566
Global Const $ID_MAGUS_STONES				= 569
Global Const $ID_SLAVERS_EXILE				= 577
Global Const $ID_SHARDS_OF_ORR_FLOOR_1		= 581
Global Const $ID_SHARDS_OF_ORR_FLOOR_2		= 582
Global Const $ID_SHARDS_OF_ORR_FLOOR_3		= 583
Global Const $ID_BOGROOT_LVL1				= 615
Global Const $ID_BOGROOT_LVL2				= 616
Global Const $ID_VLOXS_FALL					= 624
Global Const $ID_GADDS_CAMP					= 638
Global Const $ID_UMBRAL_GROTTO				= 639
Global Const $ID_RATA_SUM					= 640
Global Const $ID_EYE_OF_THE_NORTH			= IsChristmasFestival() ? $ID_CHRISTMAS_EYE_OF_THE_NORTH : $ID_DEFAULT_EYE_OF_THE_NORTH
Global Const $ID_GUNNARS_HOLD				= 644
Global Const $ID_OLAFSTEAD					= 645
Global Const $ID_HALL_OF_MONUMENTS			= 646
Global Const $ID_DALADA_UPLANDS				= 647
Global Const $ID_DOOMLORE_SHRINE			= 648
Global Const $ID_LONGEYES_LEDGE				= 650
Global Const $ID_BOREAL_STATION				= 675
Global Const $ID_CENTRAL_TRANSFER_CHAMBER	= 652
Global Const $ID_AUSPICIOUS_BEGINNINGS		= 849

Global Const $LOCATION_IDS					= [$ID_OUTPOST, $ID_Explorable, $ID_Loading, $ID_ASHFORD_ABBEY, $ID_LAKESIDE_COUNTY, $ID_GREAT_TEMPLE_OF_BALTHAZAR, $ID_EMBARK_BEACH, $ID_FISSURE_OF_WOE, $ID_UNDERWORLD, _
											$ID_WARRIORS_ISLE, $ID_HUNTERS_ISLE, $ID_WIZARDS_ISLE, $ID_AUGURY_ROCK, $ID_BURNING_ISLE, $ID_LIONS_ARCH, $ID_TASCAS_DEMISE, $ID_ELONA_REACH, $ID_TEMPLE_OF_THE_AGES, $ID_THE_GRANITE_CITADEL, $ID_FROZEN_ISLE, _
											$ID_NOMADS_ISLE, $ID_DRUIDS_ISLE, $ID_ISLE_OF_THE_DEAD, $ID_HOUSE_ZU_HELTZER, $ID_CAVALON, $ID_KAINENG_CITY, $ID_DRAZACH_THICKET, $ID_JAYA_BLUFFS, $ID_MOUNT_QINKAI, _
											$ID_SILENT_SURF, $ID_FERNDALE, $ID_PONGMEI_VALLEY, $ID_MINISTER_CHOS_ESTATE, $ID_NAHPUI_QUARTER, $ID_BOREAS_SEABED, $ID_THE_ETERNAL_GROVE, $ID_SUNQUA_VALE, _
											$ID_WAJJUN_BAZAAR, $ID_BUKDEK_BYWAY, $ID_SHING_JEA_MONASTERY, $ID_SEITUNG_HARBOR, $ID_URGOZ_WARREN, $ID_ISLE_OF_WEEPING_STONE, $ID_ISLE_OF_JADE, $ID_LEVIATHAN_PITS, _
											$ID_ZIN_KU_CORRIDOR, $ID_THE_MARKETPLACE, $ID_THE_DEEP, $ID_SAINT_ANJEKAS_SHRINE, $ID_IMPERIAL_ISLE, $ID_ISLE_OF_MEDITATION, $ID_ASPENWOOD_GATE_LUXON, $ID_KAINENG_CITY_EVENTS, _
											$ID_KAINENG_A_CHANCE_ENCOUNTER, $ID_KAMADAN, $ID_SUNWARD_MARCHES, $ID_SUNSPEAR_SANCTUARY, $ID_CHANTRY_OF_SECRETS, $ID_KODASH_BAZAAR, $ID_MIRROR_OF_LYSS, _
											$ID_MODDOK_CREVICE, $ID_COMMAND_POST, $ID_JOKOS_DOMAIN, $ID_BONE_PALACE, $ID_THE_SHATTERED_RAVINES, $ID_THE_SULFUROUS_WASTES, $ID_GATE_OF_ANGUISH, $ID_UNCHARTED_ISLE, _
											$ID_ISLE_OF_WURMS, $ID_CORRUPTED_ISLE, $ID_ISLE_OF_SOLITUDE, $ID_REMAINS_OF_SAHLAHJA, $ID_DAJKAH_INLET, $ID_NEXUS, $ID_BJORA_MARCHES, $ID_ARBOR_BAY, $ID_ICE_CLIFF_CHASMS, $ID_RIVEN_EARTH, _
											$ID_JAGA_MORAINE, $ID_VARAJAR_FELLS, $ID_SPARKFLY_SWAMP, $ID_VERDANT_CASCADES, $ID_SLAVERS_EXILE, $ID_SHARDS_OF_ORR_FLOOR_1, $ID_SHARDS_OF_ORR_FLOOR_2, $ID_SHARDS_OF_ORR_FLOOR_3, _
											$ID_BOGROOT_LVL1, $ID_BOGROOT_LVL2, $ID_VLOXS_FALL, $ID_GADDS_CAMP, $ID_UMBRAL_GROTTO, $ID_RATA_SUM, $ID_EYE_OF_THE_NORTH, $ID_OLAFSTEAD, $ID_HALL_OF_MONUMENTS, _
											$ID_DALADA_UPLANDS, $ID_DOOMLORE_SHRINE, $ID_LONGEYES_LEDGE, $ID_BOREAL_STATION, $ID_CENTRAL_TRANSFER_CHAMBER]

Global Const $LOCATION_NAMES				= ['Outpost', 'Explorable', 'Loading', 'Ashford Abbey', 'Lakeside County', 'Great Temple of Balthazar', 'Embark Beach', 'Fissure of Woe', 'Underworld', 'Warriors Isle', 'Hunters Isle', _
											'Wizards Isle', 'Augury Rock', 'Burning Isle', 'Lions Arch', 'Tascas Demise', 'Elona Reach', 'Temple of the Ages', 'The Granite Citadel', 'Frozen Isle', 'Nomads Isle', 'Druids Isle', 'Isle Of The Dead', _
											'House Zu Heltzer', 'Cavalon', 'Kaineng Center', 'Drazach Thicket', 'Jaya Bluffs', 'Mount Qinkai', 'Silent Surf', 'Ferndale', 'Pongmei Valley', 'Minister Chos Estate', 'Nahpui Quarter', _
											'Boreas Seabed', 'The Eternal Grove', 'Sunqua Vale', 'Wajjun Bazaar', 'Bukdek Byway', 'Shing Jea Monastery', 'Seitung Harbor', 'Urgoz Warren', 'Isle Of Weeping Stone', _
											'Isle Of Jade', 'Leviathan Pits', 'Zin Ku Corridor', 'The Marketplace', 'The Deep', 'Saint Anjekas Shrine', 'Imperial Isle', 'Isle Of Meditation', 'Aspenwood Gate Luxon', 'Kaineng City Events', _
											'Kaineng A Chance Encounter', 'Kamadan', 'Sunward Marches', 'Sunspear Sanctuary', 'Chantry of Secrets', 'Kodash Bazaar', 'Mirror of Lyss', 'Moddok Crevice', 'Command Post', _
											'Jokos Domain', 'Bone Palace', 'The Shattered Ravines', 'The Sulfurous Wastes', 'Gate Of Anguish', 'Uncharted Isle', 'Isle Of Wurms', 'Corrupted Isle', 'Isle Of Solitude', _
											'Remains of Sahlahja', 'Dajkah Inlet', 'Nexus', 'Bjora Marches', 'Arbor Bay', 'Ice Cliff Chasms', 'Riven Earth', 'Jaga Moraine', 'Varajar Fells', 'Sparkfly Swamp', 'Verdant Cascades', 'Slavers Exile', _
											'Shards of Orr Floor 1', 'Shards of Orr Floor 2', 'Shards of Orr Floor 3', 'Bogroot lvl1', 'Bogroot lvl2', 'Vloxs Fall', 'Gadds Camp', 'Umbral Grotto', 'Rata Sum', 'Eye of the North', _
											'Olafstead', 'Hall of Monuments', 'Dalada Uplands', 'Doomlore Shrine', 'Longeyes Ledge', 'Boreal Station', 'Central Transfer Chamber']

Global Const $LOCATIONMAPNAMES				=	MapFromArrays($LOCATION_IDS, $LOCATION_NAMES)
#EndRegion Game Locations


#Region Professions
Global Const $ID_UNKNOWN				= 0
Global Const $ID_WARRIOR				= 1
Global Const $ID_RANGER					= 2
Global Const $ID_MONK					= 3
Global Const $ID_NECROMANCER			= 4
Global Const $ID_MESMER					= 5
Global Const $ID_ELEMENTALIST			= 6
Global Const $ID_ASSASSIN				= 7
Global Const $ID_RITUALIST				= 8
Global Const $ID_PARAGON				= 9
Global Const $ID_DERVISH				= 10
Global Const $ID_ANY_PROFESSION			= 11
#EndRegion Professions


#Region Team Sizes
Global Const $ID_TEAM_SIZE_SMALL		= 4
Global Const $ID_TEAM_SIZE_MEDIUM		= 6
Global Const $ID_TEAM_SIZE_LARGE		= 8
#EndRegion Team Sizes

#Region Hero combat behaviour
Global Const $ID_HERO_FIGHTING			= 0
Global Const $ID_HERO_GUARDING			= 1
Global Const $ID_HERO_AVOIDING			= 2
#EndRegion Hero combat behaviour

#Region Agents Allegiance
Global Const $ID_ALLEGIANCE_TEAM		= 1								; player and team party members
Global Const $ID_ALLEGIANCE_ANIMAL		= 2								; untamed animals
Global Const $ID_ALLEGIANCE_FOE			= 3								; enemies
Global Const $ID_ALLEGIANCE_SPIRIT		= 4								; ranger and ritualist spirits and tamed animals (pets)
Global Const $ID_ALLEGIANCE_MINION		= 5								; necromancer's minions
Global Const $ID_ALLEGIANCE_NPC			= 6								; npcs, can be team allies
#EndRegion Agents Allegiance

#Region Agents Types
Global Const $ID_AGENT_TYPE_NPC			= 0xDB							; player, team members, npcs, foes
Global Const $ID_AGENT_TYPE_STATIC		= 0x200							; static objects like chests and signposts
Global Const $ID_AGENT_TYPE_ITEM		= 0x400							; item lying on the ground
#EndRegion Agents Types

#Region Agents TypeMap Values
Global Const $ID_TYPEMAP_ATTACK_STANCE	= 0x0001					; = 2^0 = 1 = attacking or attack stance of an agent. Bit on 1st position
Global Const $ID_TYPEMAP_SKILL_USAGE	= 0x2000					; = 2^13 = 8192 = usage of skill by agent. Bit on 14th position
Global Const $ID_TYPEMAP_DEATH_STATE	= 0x0008					; = 2^3 = 8 = death of party member or foe agent. Bit on 4th position

Global Const $ID_TYPEMAP_CITY_NPC		= 0x0002					; = 2^1 = 2 = npcs in cities. Bit on 2nd position
Global Const $ID_TYPEMAP_IDLE_FOE		= 0x0000					; = 0 = enemies, who don't do anything, for example when far away
Global Const $ID_TYPEMAP_ATTACKING_FOE	= 0x2001					; = 8193 = enemies, during fights, when using skills/attacking, Bits on 1st and 14th positions
Global Const $ID_TYPEMAP_AGGROED_FOE	= $ID_TYPEMAP_ATTACK_STANCE	; = 0x1 = enemies, when they are in attack stance, but not using skills
Global Const $ID_TYPEMAP_DEAD_FOE		= $ID_TYPEMAP_DEATH_STATE	; = 0x8 = enemies in dead state

Global Const $ID_TYPEMAP_IDLE_ALLY		= 0x20000					; = 2^17 = 131072 = party members, NPC allies and other players. Allies that are idle and not using any skills. Bit on 18th position
Global Const $ID_TYPEMAP_AGGROED_ALLY	= 0x20001					; = 131073 = aggroed party members and NPC allies but not using any skills. Bits on 1st and 18th positions
Global Const $ID_TYPEMAP_ATTACKING_ALLY	= 0x22001					; = 139265 = attacking party members and NPC allies, that are using skills. Bits on 1st and 14th and 18th positions
Global Const $ID_TYPEMAP_DEAD_ALLY		= 0x20008					; = 131080 = dead party members and NPC allies. Bits on 4th and 18th positions

Global Const $ID_TYPEMAP_IDLE_PLAYER	= 0x421004					; = 4329476 = idle player, when not using skills and not fighting
Global Const $ID_TYPEMAP_AGGROED_PLAYER	= 0x421005					; = 4329477 = aggroed player, in attack stance, but not using skills
Global Const $ID_TYPEMAP_CASTING_PLAYER	= 0x423005					; = 4337669 = attacking player who is using a skill
Global Const $ID_TYPEMAP_DEAD_PLAYER	= 0x42100C					; = 4329484 = dead player

Global Const $ID_TYPEMAP_IDLE_MINION	= 0x40000					; = 262144 = idle spirits created by ranger. Bit on 19th position
Global Const $ID_TYPEMAP_AGGROED_MINION	= 0x40001					; = 262145 = spirits created by ritualist and bone minions created by necromancers. Agents that can attack. Bits on 1st and 19th positions
#EndRegion Agents TypeMap Values


#Region Profession Attributes
Global Const $ID_FAST_CASTING					= 0
Global Const $ID_ILLUSION_MAGIC					= 1
Global Const $ID_DOMINATION_MAGIC				= 2
Global Const $ID_INSPIRATION_MAGIC				= 3
Global Const $ID_BLOOD_MAGIC					= 4
Global Const $ID_DEATH_MAGIC					= 5
Global Const $ID_SOUL_REAPING					= 6
Global Const $ID_CURSES							= 7
Global Const $ID_AIR_MAGIC						= 8
Global Const $ID_EARTH_MAGIC					= 9
Global Const $ID_FIRE_MAGIC						= 10
Global Const $ID_WATER_MAGIC					= 11
Global Const $ID_ENERGY_STORAGE					= 12
Global Const $ID_HEALING_PRAYERS				= 13
Global Const $ID_SMITING_PRAYERS				= 14
Global Const $ID_PROTECTION_PRAYERS				= 15
Global Const $ID_DIVINE_FAVOR					= 16
Global Const $ID_STRENGTH						= 17
Global Const $ID_AXE_MASTERY					= 18
Global Const $ID_HAMMER_MASTERY					= 19
Global Const $ID_SWORDSMANSHIP					= 20
Global Const $ID_TACTICS						= 21
Global Const $ID_BEASTMASTERY					= 22
Global Const $ID_EXPERTISE						= 23
Global Const $ID_WILDERNESS_SURVIVAL			= 24
Global Const $ID_MARKSMANSHIP					= 25
;Global Const $ID_EMPTY_ATTRIBUTE_1				= 26
;Global Const $ID_EMPTY_ATTRIBUTE_2				= 27
;Global Const $ID_EMPTY_ATTRIBUTE_3				= 28
Global Const $ID_DAGGER_MASTERY					= 29
Global Const $ID_DEADLY_ARTS					= 30
Global Const $ID_SHADOW_ARTS					= 31
Global Const $ID_COMMUNING						= 32
Global Const $ID_RESTORATION_MAGIC				= 33
Global Const $ID_CHANNELING_MAGIC				= 34
Global Const $ID_CRITICAL_STRIKES				= 35
Global Const $ID_SPAWNING_POWER					= 36
Global Const $ID_SPEAR_MASTERY					= 37
Global Const $ID_COMMAND						= 38
Global Const $ID_MOTIVATION						= 39
Global Const $ID_LEADERSHIP						= 40
Global Const $ID_SCYTHE_MASTERY					= 41
Global Const $ID_WIND_PRAYERS					= 42
Global Const $ID_EARTH_PRAYERS					= 43
Global Const $ID_MYSTICISM						= 44
Global Const $ID_ALL_CASTER_PRIMARIES			= 45
Global Const $ATTRIBUTES_ARRAY[]				= [	$ID_FAST_CASTING, $ID_ILLUSION_MAGIC, $ID_DOMINATION_MAGIC, $ID_INSPIRATION_MAGIC, _
													$ID_BLOOD_MAGIC, $ID_DEATH_MAGIC, $ID_SOUL_REAPING, $ID_CURSES, _
													$ID_AIR_MAGIC, $ID_EARTH_MAGIC, $ID_FIRE_MAGIC, $ID_WATER_MAGIC, $ID_ENERGY_STORAGE, _
													$ID_HEALING_PRAYERS, $ID_SMITING_PRAYERS, $ID_PROTECTION_PRAYERS, $ID_DIVINE_FAVOR, _
													$ID_STRENGTH, $ID_AXE_MASTERY, $ID_HAMMER_MASTERY, $ID_SWORDSMANSHIP, $ID_TACTICS, _
													$ID_BEASTMASTERY, $ID_EXPERTISE, $ID_WILDERNESS_SURVIVAL, $ID_MARKSMANSHIP, _
													_ ;$ID_EMPTY_ATTRIBUTE_1, $ID_EMPTY_ATTRIBUTE_2, $ID_EMPTY_ATTRIBUTE_3, _
													$ID_DAGGER_MASTERY, $ID_DEADLY_ARTS, $ID_SHADOW_ARTS, $ID_CRITICAL_STRIKES, _
													$ID_COMMUNING, $ID_RESTORATION_MAGIC, $ID_CHANNELING_MAGIC, $ID_SPAWNING_POWER, _
													$ID_SPEAR_MASTERY, $ID_COMMAND, $ID_MOTIVATION, $ID_LEADERSHIP, _
													$ID_SCYTHE_MASTERY, $ID_WIND_PRAYERS, $ID_EARTH_PRAYERS, $ID_MYSTICISM ]
Global Const $ATTRIBUTES_DOUBLE_ARRAY[][]		= [	[$ID_FAST_CASTING, 'Fast Casting'], [$ID_ILLUSION_MAGIC, 'Illusion Magic'], [$ID_DOMINATION_MAGIC, 'Domination Magic'], [$ID_INSPIRATION_MAGIC, 'Inspiration Magic'], _
													[$ID_BLOOD_MAGIC, 'Blood Magic'], [$ID_DEATH_MAGIC, 'Death Magic'], [$ID_SOUL_REAPING, 'Soul Reaping'], [$ID_CURSES, 'Curses'], _
													[$ID_AIR_MAGIC, 'Air Magic'], [$ID_EARTH_MAGIC, 'Earth Magic'], [$ID_FIRE_MAGIC, 'Fire Magic'], [$ID_WATER_MAGIC, 'Water Magic'], [$ID_ENERGY_STORAGE, 'Energy Storage'], _
													[$ID_HEALING_PRAYERS, 'Healing Prayers'], [$ID_SMITING_PRAYERS, 'Smiting Prayers'], [$ID_PROTECTION_PRAYERS, 'Protection Prayers'], [$ID_DIVINE_FAVOR, 'Divine Favor'], _
													[$ID_STRENGTH, 'Strength'], [$ID_AXE_MASTERY, 'Axe Mastery'], [$ID_HAMMER_MASTERY, 'Hammer Mastery'], [$ID_SWORDSMANSHIP, 'Swordsmanship'], [$ID_TACTICS, 'Tactics'], _
													[$ID_BEASTMASTERY, 'Beast Mastery'], [$ID_EXPERTISE, 'Expertise'], [$ID_WILDERNESS_SURVIVAL, 'Wilderness Survival'], [$ID_MARKSMANSHIP, 'Marksmanship'], _
													[$ID_DAGGER_MASTERY, 'Dagger Mastery'], [$ID_DEADLY_ARTS, 'Deadly Arts'], [$ID_SHADOW_ARTS, 'Shadow Arts'], [$ID_CRITICAL_STRIKES, 'Critical Strikes'], _
													[$ID_RESTORATION_MAGIC, 'Restoration Magic'], [$ID_CHANNELING_MAGIC, 'Channeling Magic'], [$ID_SPAWNING_POWER, 'Spawning Power'], [$ID_COMMUNING, 'Communing'], _
													[$ID_COMMAND, 'Command'], [$ID_MOTIVATION, 'Motivation'], [$ID_LEADERSHIP, 'Leadership'], [$ID_SPEAR_MASTERY, 'Spear Mastery'], _
													[$ID_SCYTHE_MASTERY, 'Scythe Mastery'], [$ID_WIND_PRAYERS, 'Wind Prayers'], [$ID_EARTH_PRAYERS, 'Earth Prayers'], [$ID_MYSTICISM, 'Mysticism']]
Global Const $UNKNOWN_ATTRIBUTES				= []
Global Const $MESMER_ATTRIBUTES					= [$ID_FAST_CASTING, $ID_ILLUSION_MAGIC, $ID_DOMINATION_MAGIC, $ID_INSPIRATION_MAGIC]
Global Const $NECROMANCER_ATTRIBUTES			= [$ID_BLOOD_MAGIC, $ID_DEATH_MAGIC, $ID_SOUL_REAPING, $ID_CURSES]
Global Const $ELEMENTALIST_ATTRIBUTES			= [$ID_AIR_MAGIC, $ID_EARTH_MAGIC, $ID_FIRE_MAGIC, $ID_WATER_MAGIC, $ID_ENERGY_STORAGE]
Global Const $MONK_ATTRIBUTES					= [$ID_HEALING_PRAYERS, $ID_SMITING_PRAYERS, $ID_PROTECTION_PRAYERS, $ID_DIVINE_FAVOR]
Global Const $WARRIOR_ATTRIBUTES				= [$ID_STRENGTH, $ID_AXE_MASTERY, $ID_HAMMER_MASTERY, $ID_SWORDSMANSHIP, $ID_TACTICS]
Global Const $RANGER_ATTRIBUTES					= [$ID_BEASTMASTERY, $ID_EXPERTISE, $ID_WILDERNESS_SURVIVAL, $ID_MARKSMANSHIP]
Global Const $ASSASSIN_ATTRIBUTES				= [$ID_DAGGER_MASTERY, $ID_DEADLY_ARTS, $ID_SHADOW_ARTS, $ID_CRITICAL_STRIKES]
Global Const $RITUALIST_ATTRIBUTES				= [$ID_COMMUNING, $ID_RESTORATION_MAGIC, $ID_CHANNELING_MAGIC, $ID_SPAWNING_POWER]
Global Const $PARAGON_ATTRIBUTES				= [$ID_SPEAR_MASTERY, $ID_COMMAND, $ID_MOTIVATION, $ID_LEADERSHIP]
Global Const $DERVISH_ATTRIBUTES				= [$ID_SCYTHE_MASTERY, $ID_WIND_PRAYERS, $ID_EARTH_PRAYERS, $ID_MYSTICISM]

Global Const $ALL_PROFESSION_IDS				=	[$ID_UNKNOWN, $ID_MESMER, $ID_NECROMANCER, $ID_ELEMENTALIST, $ID_MONK, $ID_WARRIOR, $ID_RANGER, $ID_ASSASSIN, $ID_RITUALIST, $ID_PARAGON, $ID_DERVISH]
Global Const $ALL_PROFESSION_ATTRIBUTES			=	[$UNKNOWN_ATTRIBUTES, $MESMER_ATTRIBUTES, $NECROMANCER_ATTRIBUTES, $ELEMENTALIST_ATTRIBUTES, $MONK_ATTRIBUTES, $WARRIOR_ATTRIBUTES, $RANGER_ATTRIBUTES, _
														$ASSASSIN_ATTRIBUTES, $RITUALIST_ATTRIBUTES, $PARAGON_ATTRIBUTES, $DERVISH_ATTRIBUTES]
Global Const $ATTRIBUTES_BY_PROFESSION_MAP[]	=	MapFromArrays($ALL_PROFESSION_IDS, $ALL_PROFESSION_ATTRIBUTES)
#EndRegion Profession Attributes


#Region MapMarkers
Global Const $GADGETID_ISTANI_CHEST			= 6062
Global Const $GADGETID_SHING_JEA_CHEST		= 4579
Global Const $GADGETID_NM_CHEST				= 4582
Global Const $GADGETID_HM_CHEST				= 8141
Global Const $GADGETID_OBSIDIAN_CHEST		= 74
Global Const $GADGETID_BROTHERHOOD_CHEST	= 9157
Global Const $CHESTS_ARRAY[]				= [$GADGETID_ISTANI_CHEST, $GADGETID_SHING_JEA_CHEST, $GADGETID_NM_CHEST, $GADGETID_HM_CHEST, $GADGETID_OBSIDIAN_CHEST]
Global Const $MAP_CHESTS_IDS				= MapFromArray($CHESTS_ARRAY)
#EndRegion MapMarkers


#Region Hero IDs
Global Const $ID_NORGU				= 1
Global Const $ID_GOREN				= 2
Global Const $ID_TAHLKORA			= 3
Global Const $ID_MASTER_OF_WHISPERS	= 4
Global Const $ID_ACOLYTE_JIN		= 5
Global Const $ID_KOSS				= 6
Global Const $ID_DUNKORO			= 7
Global Const $ID_ACOLYTE_SOUSUKE	= 8
Global Const $ID_MELONNI			= 9
Global Const $ID_ZHED_SHADOWHOOF	= 10
Global Const $ID_GENERAL_MORGAHN	= 11
Global Const $ID_MARGRID_THE_SLY	= 12
Global Const $ID_ZENMAI				= 13
Global Const $ID_OLIAS				= 14
Global Const $ID_RAZAH				= 15
Global Const $ID_MOX				= 16
Global Const $ID_KEIRAN_THACKERAY	= 17
Global Const $ID_JORA				= 18
Global Const $ID_PYRE_FIERCESHOT	= 19
Global Const $ID_ANTON				= 20
Global Const $ID_LIVIA				= 21
Global Const $ID_HAYDA				= 22
Global Const $ID_KAHMU				= 23
Global Const $ID_GWEN				= 24
Global Const $ID_XANDRA				= 25
Global Const $ID_VEKK				= 26
Global Const $ID_OGDEN				= 27
Global Const $ID_MERCENARY_HERO_1	= 28
Global Const $ID_MERCENARY_HERO_2	= 29
Global Const $ID_MERCENARY_HERO_3	= 30
Global Const $ID_MERCENARY_HERO_4	= 31
Global Const $ID_MERCENARY_HERO_5	= 32
Global Const $ID_MERCENARY_HERO_6	= 33
Global Const $ID_MERCENARY_HERO_7	= 34
Global Const $ID_MERCENARY_HERO_8	= 35
Global Const $ID_MIKU				= 36
Global Const $ID_ZEIRI				= 37

Global Const $HERO_IDS[]						= [$ID_NORGU, $ID_GOREN, $ID_TAHLKORA, $ID_MASTER_OF_WHISPERS, $ID_ACOLYTE_JIN, _
													$ID_KOSS, $ID_DUNKORO, $ID_ACOLYTE_SOUSUKE, $ID_MELONNI, $ID_ZHED_SHADOWHOOF, _
													$ID_GENERAL_MORGAHN, $ID_MARGRID_THE_SLY, $ID_ZENMAI, $ID_OLIAS, $ID_RAZAH, _
													$ID_MOX, $ID_KEIRAN_THACKERAY, $ID_JORA, $ID_PYRE_FIERCESHOT, $ID_ANTON, _
													$ID_LIVIA, $ID_HAYDA, $ID_KAHMU, $ID_GWEN, $ID_XANDRA, $ID_VEKK, $ID_OGDEN, _
													$ID_MIKU, $ID_ZEIRI, $ID_MERCENARY_HERO_1, $ID_MERCENARY_HERO_2, _
													$ID_MERCENARY_HERO_3, $ID_MERCENARY_HERO_4, $ID_MERCENARY_HERO_5, _
													$ID_MERCENARY_HERO_6, $ID_MERCENARY_HERO_7, $ID_MERCENARY_HERO_8]

Global Const $HERO_NAMES[]						= [ 'Norgu', 'Goren', 'Tahlkora', 'Master of Whispers', 'Acolyte Jin', _
													'Koss', 'Dunkoro', 'Acolyte Sousuke', 'Melonni', 'Zhed Shadowhoof', _
													'General Morgahn', 'Margrid the Sly', 'Zenmai', 'Olias', 'Razah', _
													'MOX', 'Keiran Thackeray', 'Jora', 'Pyre Fierceshot', 'Anton', _
													'Livia', 'Hayda', 'Kahmu', 'Gwen', 'Xandra', 'Vekk', 'Ogden', _
													'Miku', 'ZeiRi', 'Mercenary Hero 1', 'Mercenary Hero 2', _
													'Mercenary Hero 3', 'Mercenary Hero 4', 'Mercenary Hero 5', _
													'Mercenary Hero 6', 'Mercenary Hero 7', 'Mercenary Hero 8']

;Global Const $HERO_NAMES_FROM_IDS				=	MapFromArrays($HERO_IDS, $HERO_NAMES)
Global Const $HERO_IDS_FROM_NAMES				=	MapFromArrays($HERO_NAMES, $HERO_IDS)
#EndRegion Hero IDs


#Region Titles
Global Const $ID_SUNSPEAR_TITLE					= 0x11
Global Const $ID_LIGHTBRINGER_TITLE				= 0x14
Global Const $ID_ASURA_TITLE					= 0x26
Global Const $ID_DWARF_TITLE					= 0x27
Global Const $ID_EBON_VANGUARD_TITLE			= 0x28
Global Const $ID_NORN_TITLE						= 0x29
#EndRegion Titles


#Region Skill IDs
; Warrior
Global Const $ID_HEALING_SIGNET					= 1
Global Const $ID_TO_THE_LIMIT					= 316
Global Const $ID_FOR_GREAT_JUSTICE				= 343
Global Const $ID_100_BLADES						= 381
Global Const $ID_WHIRLWIND_ATTACK				= 2107
Global Const $ID_SEVEN_WEAPONS_STANCE			= 3426
; Ranger
Global Const $ID_TROLL_UNGUENT					= 446
Global Const $ID_WHIRLING_DEFENSE				= 450
Global Const $ID_QUICKENING_ZEPHYR				= 475
Global Const $ID_TOGETHER_AS_ONE				= 3427
; Monk
Global Const $ID_UNYIELDING_AURA				= 268
Global Const $ID_LIGHT_OF_DWAYNA				= 304
Global Const $ID_RESURRECT						= 305
Global Const $ID_REBIRTH						= 306
Global Const $ID_RESTORE_LIFE					= 314
Global Const $ID_BALTHAZARS_SPIRIT				= 242
Global Const $ID_WATCHFUL_SPIRIT				= 255
Global Const $ID_LIFE_BARRIER					= 270
Global Const $ID_LIFE_BOND						= 241
Global Const $ID_VITAL_BLESSING					= 289
Global Const $ID_VENGEANCE						= 315
Global Const $ID_RAY_OF_JUDGEMENT				= 830
Global Const $ID_RESURRECTION_CHANT				= 1128
Global Const $ID_RENEW_LIFE						= 1263
Global Const $ID_JUDGEMENT_STRIKE				= 3425
; Necromancer
Global Const $ID_ANIMATE_BONE_MINIONS			= 85
Global Const $ID_DEATH_NOVA						= 104
Global Const $ID_ANIMATE_FLESH_GOLEM			= 832
Global Const $ID_SOUL_TAKER						= 3423
; Mesmer
Global Const $ID_EMPATHY						= 26
Global Const $ID_SYMPATHETIC_VISAGE				= 34
Global Const $ID_ARCANE_CONUNDRUM				= 36
Global Const $ID_CHANNELING						= 38
Global Const $ID_MIGRAINE						= 53
Global Const $ID_ARCANE_ECHO					= 75
Global Const $ID_STOLEN_SPEED					= 880
Global Const $ID_SHARED_BURDEN					= 900
Global Const $ID_ANCESTORS_VISAGE				= 1054
Global Const $ID_WASTRELS_DEMISE				= 1335
Global Const $ID_FRUSTRATION					= 1341
Global Const $ID_SUM_OF_ALL_FEARS				= 1996
Global Const $ID_CONFUSING_IMAGES				= 2137
Global Const $ID_TIME_WARD						= 3422
; Elementalist
Global Const $ID_ELEMENTAL_ATTUNEMENT			= 164
Global Const $ID_METEOR							= 187
Global Const $ID_RODGORTS_INVOCATION			= 189
Global Const $ID_METEOR_SHOWER					= 192
Global Const $ID_FLARE							= 194
Global Const $ID_SEARING_HEAT					= 196
Global Const $ID_FIRE_STORM						= 197
Global Const $ID_GLYPH_OF_ELEMENTAL_POWER		= 198
Global Const $ID_GLYPH_OF_SACRIFICE				= 198
Global Const $ID_UNSTEADY_GROUND				= 1083
Global Const $ID_GLYPH_OF_ESSENCE				= 1096
Global Const $ID_SAND_STORM						= 1372
Global Const $ID_SAVANNAH_HEAT					= 1380
Global Const $ID_OVER_THE_LIMIT					= 3424
; Assassin
Global Const $ID_DEADLY_PARADOX					= 572
Global Const $ID_SHADOW_REFUGE					= 814
Global Const $ID_SHADOW_FORM					= 826
Global Const $ID_WAY_OF_PERFECTION				= 1028
Global Const $ID_SHROUD_OF_DISTRESS				= 1031
Global Const $ID_DARK_ESCAPE					= 1037
Global Const $ID_SHADOW_THEFT					= 3428
; Ritualist
Global Const $ID_FLESH_OF_MY_FLESH				= 791
Global Const $ID_UNION							= 911
Global Const $ID_RESTORATION					= 963
Global Const $ID_SHELTER						= 982
Global Const $ID_LIVELY_WAS_NAOMEI				= 1222
Global Const $ID_SOUL_TWISTING					= 1240
Global Const $ID_DISPLACEMENT					= 1249
Global Const $ID_DEATH_PACT_SIGNET				= 1481
Global Const $ID_WEAPONS_OF_THREE_FORGES		= 3429
; Paragon
Global Const $ID_BURNING_REFRAIN				= 1576
Global Const $ID_WE_SHALL_RETURN				= 1592
Global Const $ID_FALL_BACK						= 1595
Global Const $ID_THEYRE_ON_FIRE					= 1597
Global Const $ID_AGGRESSIVE_REFRAIN				= 1774
Global Const $ID_SIGNET_OF_RETURN				= 1778
Global Const $ID_HEROIC_REFRAIN					= 3431
; Dervish
Global Const $ID_MIRAGE_CLOAK					= 1500
Global Const $ID_MYSTIC_VIGOR					= 1503
Global Const $ID_VITAL_BOON						= 1506
Global Const $ID_SAND_SHARDS					= 1510
Global Const $ID_MYSTIC_REGENERATION			= 1516
Global Const $ID_CONVICTION						= 1540
Global Const $ID_HEART_OF_FURY					= 1762
Global Const $ID_SIGNET_OF_MYSTIC_SPEED			= 2200
Global Const $ID_VOW_OF_REVOLUTION				= 3430
; Common
Global Const $ID_RESURRECTION_SIGNET			= 2
; PvE
Global Const $ID_SUNSPEAR_REBIRTH_SIGNET		= 1816
Global Const $ID_JUNUNDU_WAIL					= 1865
Global Const $ID_INTENSITY						= 2104
Global Const $ID_ETERNAL_AURA					= 2109
Global Const $ID_BY_URALS_HAMMER				= 2217
Global Const $ID_GREAT_DWARF_ARMOR				= 2220
Global Const $ID_EBON_BATTLE_STANDARD_OF_HONOR	= 2233
Global Const $ID_I_AM_UNSTOPPABLE				= 2356
Global Const $ID_MINDBENDER						= 2411
Global Const $ID_MENTAL_BLOCK					= 2417
Global Const $ID_DWARVEN_STABILITY				= 2423
; Consumables, food and drink boosts
Global Const $ID_DRAKE_SKIN						= 1680		; obtained using Drake Kabob
Global Const $ID_SKALE_VIGOR					= 1681		; obtained using Bowl of Skalefin Soup
Global Const $ID_PAHNAI_SALAD_RUSH				= 1682		; obtained using Pahnai Salad
Global Const $ID_SUGAR_JOLT_2					= 1916		; obtained using Sugary Blue Drink
Global Const $ID_SUGAR_JOLT_5					= 1933		; obtained using Chocolate Bunny
Global Const $ID_GOLDEN_EGG_EFFECT				= 1934
Global Const $ID_BIRTHDAY_CUPCAKE_EFFECT		= 1945
Global Const $ID_ARMOR_OF_SALVATION_EFFECT		= 2520
Global Const $ID_GRAIL_OF_MIGHT_EFFECT			= 2521
Global Const $ID_ESSENCE_OF_CELERITY_EFFECT		= 2522
Global Const $ID_CANDY_CORN_EFFECT				= 2604
Global Const $ID_CANDY_APPLE_EFFECT				= 2605
Global Const $ID_PIE_INDUCED_ECSTASY			= 2649		; obtained using Slice of Pumpkin Pie
Global Const $ID_SUGAR_INFUSION					= 2762
Global Const $ID_BLUE_ROCK_CANDY_RUSH			= 2971
Global Const $ID_GREEN_ROCK_CANDY_RUSH			= 2972
Global Const $ID_RED_ROCK_CANDY_RUSH			= 2973
Global Const $ID_WELL_SUPPLIED					= 3174		; obtained using War Supplies
#EndRegion Skill IDs


#Region Conditions
Global Const $ID_BLEEDING	= 478
Global Const $ID_BLIND		= 479
Global Const $ID_BURNING	= 480
Global Const $ID_CRIPPLED	= 481
Global Const $ID_DEEP_WOUND	= 482
Global Const $ID_DISEASE	= 483
Global Const $ID_POISON		= 484
Global Const $ID_DAZED		= 485
Global Const $ID_WEAKNESS	= 486
#EndRegionConditions