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
#include 'GWA2_ID_Skills.au3'
#include 'GWA2_ID_Quests.au3'
#include 'GWA2_ID_Items.au3'
#include 'GWA2_ID_Maps.au3'

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


#Region Districts and Regions
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
#EndRegion Districts and Regions


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
Global Const $ID_TYPEMAP_IDLE_FOE		= 0x0000					; = 0 = enemies, who do not do anything, for example when far away
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
Global Const $GADGETID_PHANTOM_CHEST		= 68
Global Const $GADGETID_BROTHERHOOD_CHEST	= 9157
Global Const $CHESTS_ARRAY[]				= [$GADGETID_ISTANI_CHEST, $GADGETID_SHING_JEA_CHEST, $GADGETID_NM_CHEST, $GADGETID_HM_CHEST, $GADGETID_OBSIDIAN_CHEST, $GADGETID_PHANTOM_CHEST]
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

#Region Mob IDs
; LDOA foes model IDs
Global Const $ID_BANDIT_FIRESTARTER			= 7824
Global Const $ID_BANDIT_RAIDER				= 7825
; Voltaic farm foes model IDs
Global Const $ID_STONE_SUMMIT_DOMINATOR		= 6544
Global Const $ID_STONE_SUMMIT_DREAMER		= 6545
Global Const $ID_STONE_SUMMIT_CONTAMINATOR	= 6546
Global Const $ID_STONE_SUMMIT_BLASPHEMER	= 6547
Global Const $ID_STONE_SUMMIT_WARDER		= 6548
Global Const $ID_STONE_SUMMIT_PRIEST		= 6549
Global Const $ID_STONE_SUMMIT_DEFENDER		= 6550
Global Const $ID_STONE_SUMMIT_ZEALOT		= 6557
Global Const $ID_STONE_SUMMIT_SUMMONER		= 6558
Global Const $ID_MODNIIR_PRIEST				= 6563
; Gemstone farm foes model IDs
Global Const $ID_MARGONITE_ANUR_KAYA		= 5217
Global Const $ID_MARGONITE_ANUR_DABI		= 5218
Global Const $ID_MARGONITE_ANUR_SU			= 5219
Global Const $ID_MARGONITE_ANUR_KI			= 5220
Global Const $ID_MARGONITE_ANUR_TUK			= 5222
Global Const $ID_MARGONITE_ANUR_RUND		= 5224
Global Const $ID_MISERY_TITAN				= 5246
Global Const $ID_RAGE_TITAN					= 5247
Global Const $ID_DEMENTIA_TITAN				= 5248
Global Const $ID_ANGUISH_TITAN				= 5249
Global Const $ID_FURY_TITAN					= 5251
Global Const $ID_MIND_TORMENTOR				= 5255
Global Const $ID_SOUL_TORMENTOR				= 5256
Global Const $ID_WATER_TORMENTOR			= 5257
Global Const $ID_HEART_TORMENTOR			= 5258
Global Const $ID_FLESH_TORMENTOR			= 5259
Global Const $ID_TORTUREWEB_DRYDER			= 5266
Global Const $ID_GREATER_DREAM_RIDER		= 5267
; War Supply farm foes model IDs, why so many? (o_O)
Global Const $ID_PEACEKEEPER_ENFORCER_1		= 8146
Global Const $ID_PEACEKEEPER_ENFORCER_2		= 8147
Global Const $ID_PEACEKEEPER_ENFORCER_3		= 8148
Global Const $ID_PEACEKEEPER_ENFORCER_4		= 8170
Global Const $ID_PEACEKEEPER_ENFORCER_5		= 8171
Global Const $ID_WHITE_MANTLE_MARKSMAN_1	= 8187
Global Const $ID_WHITE_MANTLE_MARKSMAN_2	= 8188
Global Const $ID_WHITE_MANTLE_MARKSMAN_3	= 8189
Global Const $ID_WHITE_MANTLE_ENFORCER_1	= 8232
Global Const $ID_WHITE_MANTLE_ENFORCER_2	= 8233
Global Const $ID_WHITE_MANTLE_ENFORCER_3	= 8234
Global Const $ID_WHITE_MANTLE_ENFORCER_4	= 8235
Global Const $ID_WHITE_MANTLE_ENFORCER_5	= 8236
Global Const $ID_WHITE_MANTLE_SYCOPHANT_1	= 8237
Global Const $ID_WHITE_MANTLE_SYCOPHANT_2	= 8238
Global Const $ID_WHITE_MANTLE_SYCOPHANT_3	= 8239
Global Const $ID_WHITE_MANTLE_SYCOPHANT_4	= 8240
Global Const $ID_WHITE_MANTLE_SYCOPHANT_5	= 8241
Global Const $ID_WHITE_MANTLE_SYCOPHANT_6	= 8242
Global Const $ID_WHITE_MANTLE_RITUALIST_1	= 8243
Global Const $ID_WHITE_MANTLE_RITUALIST_2	= 8244
Global Const $ID_WHITE_MANTLE_RITUALIST_3	= 8245
Global Const $ID_WHITE_MANTLE_RITUALIST_4	= 8246
Global Const $ID_WHITE_MANTLE_FANATIC_1		= 8247
Global Const $ID_WHITE_MANTLE_FANATIC_2		= 8248
Global Const $ID_WHITE_MANTLE_FANATIC_3		= 8249
Global Const $ID_WHITE_MANTLE_FANATIC_4		= 8250
Global Const $ID_WHITE_MANTLE_SAVANT_1		= 8251
Global Const $ID_WHITE_MANTLE_SAVANT_2		= 8252
Global Const $ID_WHITE_MANTLE_SAVANT_3		= 8253
Global Const $ID_WHITE_MANTLE_ADHERENT_1	= 8254
Global Const $ID_WHITE_MANTLE_ADHERENT_2	= 8255
Global Const $ID_WHITE_MANTLE_ADHERENT_3	= 8256
Global Const $ID_WHITE_MANTLE_ADHERENT_4	= 8257
Global Const $ID_WHITE_MANTLE_ADHERENT_5	= 8258
Global Const $ID_WHITE_MANTLE_PRIEST_1		= 8259
Global Const $ID_WHITE_MANTLE_PRIEST_2		= 8260
Global Const $ID_WHITE_MANTLE_PRIEST_3		= 8261
Global Const $ID_WHITE_MANTLE_PRIEST_4		= 8262
Global Const $ID_WHITE_MANTLE_ABBOT_1		= 8263
Global Const $ID_WHITE_MANTLE_ABBOT_2		= 8264
Global Const $ID_WHITE_MANTLE_ABBOT_3		= 8265
Global Const $ID_WHITE_MANTLE_ZEALOT_1		= 8267
Global Const $ID_WHITE_MANTLE_ZEALOT_2		= 8268
Global Const $ID_WHITE_MANTLE_ZEALOT_3		= 8269
Global Const $ID_WHITE_MANTLE_ZEALOT_4		= 8270
Global Const $ID_WHITE_MANTLE_KNIGHT_1		= 8273
Global Const $ID_WHITE_MANTLE_KNIGHT_2		= 8274
Global Const $ID_WHITE_MANTLE_SCOUT_1		= 8275
Global Const $ID_WHITE_MANTLE_SCOUT_2		= 8276
Global Const $ID_WHITE_MANTLE_SCOUT_3		= 8277
Global Const $ID_WHITE_MANTLE_SCOUT_4		= 8278
Global Const $ID_WHITE_MANTLE_SEEKER_1		= 8279
Global Const $ID_WHITE_MANTLE_SEEKER_2		= 8280
Global Const $ID_WHITE_MANTLE_SEEKER_3		= 8281
Global Const $ID_WHITE_MANTLE_SEEKER_4		= 8282
Global Const $ID_WHITE_MANTLE_SEEKER_5		= 8283
Global Const $ID_WHITE_MANTLE_SEEKER_6		= 8284
Global Const $ID_WHITE_MANTLE_SEEKER_7		= 8285
Global Const $ID_WHITE_MANTLE_SEEKER_8		= 8286
Global Const $ID_WHITE_MANTLE_RITUALIST_5	= 8287
Global Const $ID_WHITE_MANTLE_RITUALIST_6	= 8288
Global Const $ID_WHITE_MANTLE_RITUALIST_7	= 8289
Global Const $ID_WHITE_MANTLE_RITUALIST_8	= 8290
Global Const $ID_WHITE_MANTLE_RITUALIST_9	= 8291
Global Const $ID_WHITE_MANTLE_RITUALIST_10	= 8292
Global Const $ID_WHITE_MANTLE_RITUALIST_11	= 8293
Global Const $ID_WHITE_MANTLE_CHAMPION_1	= 8295
Global Const $ID_WHITE_MANTLE_CHAMPION_2	= 8296
Global Const $ID_WHITE_MANTLE_CHAMPION_3	= 8297
Global Const $ID_WHITE_MANTLE_ZEALOT_5		= 8392
; Underworld farm foes model IDs
Global Const $ID_KEEPER_OF_SOULS	 		= 2373
Global Const $ID_VENGEFUL_AATXE 			= 2390
Global Const $ID_TERRORWEB_DRYDER 			= 2371
Global Const $ID_TERRORWEB_DRYDER_SILVER	= 2372
Global Const $ID_SMITE_CRAWLER				= 2375
Global Const $ID_BANISHED_DREAM_RIDER		= 2377
Global Const $ID_MINDBLADE_SPECTRE			= 2380
Global Const $ID_BLADED_AATXE				= 2389
Global Const $ID_SKELETON_OF_DHUUM			= 2392
#EndRegion Mob IDs
