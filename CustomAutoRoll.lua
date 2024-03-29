if( TidyRoll == nil ) then
	TidyRoll = {}
end

TidyRoll.CustomAutoRoll = {}
TidyRoll.CustomAutoRoll.autoRollList = {}
TidyRoll.CustomAutoRoll.autoRollDisplayOrder = {}

--------------------------------------------------------------
-- CONSTANTS
--------------------------------------------------------------

local c_TROLL_AUTO_ROLL_WINDOW = "TRollAutoRoll"
local c_AUTO_ROLL_TITLE_LABEL = c_TROLL_AUTO_ROLL_WINDOW .. "TitleLabel"
local c_AUTO_ROLL_APPLY_BUTTON = c_TROLL_AUTO_ROLL_WINDOW .. "ApplyButton"
local c_AUTO_ROLL_ADD_BY_ID_LABEL = c_TROLL_AUTO_ROLL_WINDOW .. "AddByIdLabel"
local c_AUTO_ROLL_ADD_BY_ID_ID_LABEL = c_TROLL_AUTO_ROLL_WINDOW .. "AddByIdIdLabel"
local c_AUTO_ROLL_ADD_BY_ID_ID_EDITBOX = c_TROLL_AUTO_ROLL_WINDOW .. "AddByIdIdEditBox"
local c_AUTO_ROLL_ADD_BY_ID_NAME_LABEL = c_TROLL_AUTO_ROLL_WINDOW .. "AddByIdNameLabel"
local c_AUTO_ROLL_ADD_BY_ID_NAME_EDITBOX = c_TROLL_AUTO_ROLL_WINDOW .. "AddByIdNameEditBox"
local c_AUTO_ROLL_ADD_BY_ID_BUTTON = c_TROLL_AUTO_ROLL_WINDOW .. "AddByIdButton"
local c_AUTO_ROLL_AUTO_ROLL_LIST = c_TROLL_AUTO_ROLL_WINDOW .. "List"
local c_AUTO_ROLL_AUTO_ROLL_LIST_COLUMNS_LABEL = c_TROLL_AUTO_ROLL_WINDOW .. "ListColumnsLabel"
local c_AUTO_ROLL_AUTO_ROLL_LIST_HELP_LABEL = c_TROLL_AUTO_ROLL_WINDOW .. "ListHelpLabel"


local choiceComboLabels = { L"Ask me", L"Need", L"Greed", L"Pass" }


--------------------------------------------------------------
-- LOCAL VARIABLES
--------------------------------------------------------------

local TidyRoll = TidyRoll
local CustomAutoRoll = TidyRoll.CustomAutoRoll
local DataUtils = DataUtils
local pairs = pairs
local ipairs = ipairs
local tinsert = table.insert
local tremove = table.remove

local Settings


-- DEFAULT SETTINGS --

local DefaultSettings = {
	[1] =	{
				id		= 208400,
				iconNum	= 25003,
				name	= L"Recruit's Medallion",
				rarity	= SystemData.ItemRarity.UNCOMMON,
				choice	= GameData.LootRoll.NEED
			},
	[2] =	{
				id		= 208401,
				iconNum	= 25005,
				name	= L"Scout's Medallion",
				rarity	= SystemData.ItemRarity.UNCOMMON,
				choice	= GameData.LootRoll.NEED
			},
	[3] =	{
				id		= 208402,
				iconNum	= 25006,
				name	= L"Soldier's Medallion",
				rarity	= SystemData.ItemRarity.UNCOMMON,
				choice	= GameData.LootRoll.NEED
			},
	[4] =	{
				id		= 208403,
				iconNum	= 25001,
				name	= L"Officer's Medallion",
				rarity	= SystemData.ItemRarity.UNCOMMON,
				choice	= GameData.LootRoll.NEED
			},
	[5] =	{
				id		= 208452,
				iconNum	= 25000,
				name	= L"Conquerer's Crest",
				rarity	= SystemData.ItemRarity.RARE,
				choice	= GameData.LootRoll.NEED
			},
	[6] =	{
				id		= 208453,
				iconNum	= 25002,
				name	= L"Invader's Crest",
				rarity	= SystemData.ItemRarity.VERY_RARE,
				choice	= GameData.LootRoll.NEED
			},
	[7] =	{
				id		= 208454,
				iconNum	= 25007,
				name	= L"Warlord's Crest",
				rarity	= SystemData.ItemRarity.VERY_RARE,
				choice	= GameData.LootRoll.NEED
			},
	[8] =	{
				id		= 208455,
				iconNum	= 25004,
				name	= L"Royal Crest",
				rarity	= SystemData.ItemRarity.ARTIFACT,
				choice	= GameData.LootRoll.NEED
			},
	
	[9] =	{
				id = 208458,
				iconNum = 25016,
				name	= L"Captain's Medallion",
				rarity	= SystemData.ItemRarity.RARE,
				choice	= GameData.LootRoll.NEED
			},
	[10] =	{
				id = 208460,
				iconNum = 25018,
				name	= L"Doomflayer Crest",
				rarity	= SystemData.ItemRarity.VERY_RARE,
				choice	= GameData.LootRoll.NEED
			},
	[11] =	{
				id = 208462,
				iconNum = 25020,
				name	= L"Warpforged Crest",
				rarity	= SystemData.ItemRarity.ARTIFACT,
				choice	= GameData.LootRoll.NEED
			},
	[12] =	{
				id		= 208408,
				iconNum	= 27041,
				name	= L"Silver Scarab",
				rarity	= SystemData.ItemRarity.UNCOMMON,
				choice	= GameData.LootRoll.NEED
			},
	[13] =	{
				id		= 208409,
				iconNum	= 27005,
				name	= L"Golden Scarab",
				rarity	= SystemData.ItemRarity.UNCOMMON,
				choice	= GameData.LootRoll.NEED
			},
	[14] =	{
				id		= 11847,
				iconNum	= 374,
				name	= L"Skull of the Fallen",
				rarity	= SystemData.ItemRarity.UNCOMMON,
				choice	= GameData.LootRoll.NEED
			},
	[15] =	{
				id		= 11837,
				iconNum	= 919,
				name	= L"Ordnance",
				rarity	= SystemData.ItemRarity.UNCOMMON,
				choice	= GameData.LootRoll.NEED
			},
	[16] =	{
				id		= 207413,
				iconNum	= 762,
				name	= L"Expedition Resources",
				rarity	= SystemData.ItemRarity.UNCOMMON,
				choice	= GameData.LootRoll.NEED
			},
	[17] =	{
				id		= 5759208,
				iconNum	= 864,
				name	= L"Insignia Cluster",
				rarity	= SystemData.ItemRarity.VERY_RARE,
				choice	= GameData.LootRoll.NEED
			},
	[18] =	{
				id		= 208470,
				iconNum	= 25022,
				name	= L"War Crest",
				rarity	= SystemData.ItemRarity.COMMON,
				choice	= GameData.LootRoll.NEED
			},
	[19] =	{
				id		= 208474,
				iconNum	= 20487,
				name	= L"Fused War Crests",
				rarity	= SystemData.ItemRarity.RARE,
				choice	= GameData.LootRoll.NEED
			},
	[20] =	{
				id		= 208472,
				iconNum	= 538,
				name	= L"Box of War Crests",
				rarity	= SystemData.ItemRarity.UNCOMMON,
				choice	= GameData.LootRoll.NEED
			},
}


--------------------------------------------------------------
-- END LOCAL VARIABLES
--------------------------------------------------------------


function CustomAutoRoll.ToggleOptions()
	WindowSetShowing( c_TROLL_AUTO_ROLL_WINDOW, not WindowGetShowing(c_TROLL_AUTO_ROLL_WINDOW) )
end


function CustomAutoRoll.Initialize()
	CreateWindow(c_TROLL_AUTO_ROLL_WINDOW, false)
	
	LabelSetText( c_AUTO_ROLL_TITLE_LABEL, L"Custom Auto Roll" )
	ButtonSetText( c_AUTO_ROLL_APPLY_BUTTON, L"Ok" )
	
	LabelSetText( c_AUTO_ROLL_ADD_BY_ID_LABEL, L"Add item to auto roll list by id")
	LabelSetText( c_AUTO_ROLL_ADD_BY_ID_ID_LABEL, L"Id")
	LabelSetText( c_AUTO_ROLL_ADD_BY_ID_NAME_LABEL, L"Commentary")
	ButtonSetText( c_AUTO_ROLL_ADD_BY_ID_BUTTON, L"Add")
	
	-- Init List
	LabelSetText( c_AUTO_ROLL_AUTO_ROLL_LIST_COLUMNS_LABEL, L" Icon               Name                    Id           Choice" )
	LabelSetText( c_AUTO_ROLL_AUTO_ROLL_LIST_HELP_LABEL, L"To add an item, pick up this item from the backpack and drop it to the list" )
	
	for row = 1, 7 do
		local rowName = c_AUTO_ROLL_AUTO_ROLL_LIST .. "Row" .. row
		
		ButtonSetText( rowName .. "DeleteButton", L"Del")
		
		ComboBoxClearMenuItems(rowName .. "Choice")
		for _, text in ipairs(choiceComboLabels) do
			ComboBoxAddMenuItem(rowName .. "Choice", text)
		end
		
		-- Update the Row Background		
		local row_mod = math.mod(row, 2)
		local color = DataUtils.GetAlternatingRowColor( row_mod )
		DefaultColor.SetWindowTint( rowName .. "Background", color )
	end
	
	CustomAutoRoll.InitializeSettings()
end


--------------------------------------------------------------
-- UTILS
--------------------------------------------------------------

function CustomAutoRoll.SetupLocals()
	Settings = TidyRoll.Settings
end


function CustomAutoRoll.UpdateSettings()
	if( type(Settings.CustomAutoRollSettings) ~= "table" ) then
		Settings.CustomAutoRollSettings = DataUtils.CopyTable(DefaultSettings)
	end
	
	TidyRoll.UpdateCustomAutoRollIds(Settings.CustomAutoRollSettings)
end


function CustomAutoRoll.InitializeSettings()
	if( type(Settings.CustomAutoRollSettings) ~= "table" ) then
		Settings.CustomAutoRollSettings = DataUtils.CopyTable( DefaultSettings )
		
	else
		CustomAutoRoll.UpdatePrevVersion()
		
		-- Restore defaults
		local list = Settings.CustomAutoRollSettings
		for defIndex, autoRollData in ipairs( DefaultSettings ) do
			local index = CustomAutoRoll.SearchItemById( list, autoRollData.id )
			
			--[[
			if( index ~= defIndex ) then
				if( index ~= nil ) then
					local temp = list[index]
					
					tremove(list, index)
					tinsert(list, defIndex, temp)
				else
					tinsert(list, defIndex, DataUtils.CopyTable( autoRollData ))
				end
			end
			--]]
			
			local temp
			
			if( index ~= nil ) then
				temp = list[index].choice
				
				tremove(list, index)
			end
			
			tinsert(list, defIndex, DataUtils.CopyTable( autoRollData ))
			
			if( temp ~= nil ) then list[defIndex].choice = temp end
			
		end
	end
	
	TidyRoll.UpdateCustomAutoRollIds(Settings.CustomAutoRollSettings)
end



function CustomAutoRoll.UpdatePrevVersion()
	if( Settings.version and Settings.version < 13 ) then
		local changeTable = {
			[208404] = 208452,
			[208429] = 208453,
			[208406] = 208454,
			[208407] = 208455,
		}
		
		local list = Settings.CustomAutoRollSettings
		for oldId, newId in pairs( changeTable ) do
			local index = CustomAutoRoll.SearchItemById( list, oldId )
			
			if( index ~= nil) then
				local index2 = CustomAutoRoll.SearchItemById( list, newId )
				
				list[ index ].id = newId
				if( index2 ~= nil) then
					list[ index ].choice = list[ index2 ].choice
					tremove(list, index2)
				end
			end
		end
		
	end
end


function CustomAutoRoll.SearchItemById( list, id )
	if( id ) then
		for index, autoRollData in ipairs( list ) do
			if( autoRollData.id == id ) then
				return index
			end
		end
	end
	
	return nil
end



--------------------------------------------------------------
-- GUI
--------------------------------------------------------------

function CustomAutoRoll.OnShown()
	WindowUtils.OnShown()
	CustomAutoRoll.Reset()
end


function CustomAutoRoll.OnHidden()
	WindowUtils.OnHidden()
	CustomAutoRoll.autoRollList = {}
end


function CustomAutoRoll.OnClose()
	WindowSetShowing( c_TROLL_AUTO_ROLL_WINDOW, false )
end


function CustomAutoRoll.OnApply()
	Settings.CustomAutoRollSettings = CustomAutoRoll.autoRollList
	CustomAutoRoll.UpdateSettings()
	
	WindowSetShowing( c_TROLL_AUTO_ROLL_WINDOW, false )
end


function CustomAutoRoll.Reset()
	TextEditBoxSetText( c_AUTO_ROLL_ADD_BY_ID_ID_EDITBOX, L"" )
	TextEditBoxSetText( c_AUTO_ROLL_ADD_BY_ID_NAME_EDITBOX, L"" )
	
	CustomAutoRoll.autoRollList = DataUtils.CopyTable(Settings.CustomAutoRollSettings)
	CustomAutoRoll.UpdateList()
end



-------------------------------
-- LIST
-------------------------------

function CustomAutoRoll.UpdateList()
	CustomAutoRoll.autoRollDisplayOrder = {}
	
	for autoRollIndex, _ in ipairs( CustomAutoRoll.autoRollList ) do
		tinsert( CustomAutoRoll.autoRollDisplayOrder, autoRollIndex )
	end
	
	ListBoxSetDisplayOrder(c_AUTO_ROLL_AUTO_ROLL_LIST, CustomAutoRoll.autoRollDisplayOrder)
end


function CustomAutoRoll.PopulateAutoRollList()
	local PopulatorIndices = _G[ c_AUTO_ROLL_AUTO_ROLL_LIST ].PopulatorIndices
	if( nil == PopulatorIndices ) then
		return
	end
	
	for row, autoRollIndex in ipairs( PopulatorIndices ) do
		local rowName		= c_AUTO_ROLL_AUTO_ROLL_LIST .. "Row" .. row
		local autoRollData	= CustomAutoRoll.autoRollList[autoRollIndex]
		
		local color = DefaultColor.TOOLTIP_HEADING
		
		local rarityData = GameDefs.ItemRarity[autoRollData.rarity]
		if( rarityData ) then
			color = rarityData.color
		end
		
		LabelSetTextColor( rowName .. "Name", color.r, color.g, color.b )
		ComboBoxSetSelectedMenuItem( rowName .. "Choice", autoRollData.choice + 2 )
		ButtonSetDisabledFlag( rowName .. "DeleteButton", DefaultSettings[autoRollIndex] ~= nil )
	end
end


function CustomAutoRoll.OnChoiceChange()
	local rowNum = WindowGetId( SystemData.ActiveWindow.name )	
	local autoRollIndex = _G[c_AUTO_ROLL_AUTO_ROLL_LIST].PopulatorIndices[ rowNum ]
	local comboName = c_AUTO_ROLL_AUTO_ROLL_LIST .. "Row" .. rowNum .. "Choice"
	
	CustomAutoRoll.autoRollList[autoRollIndex].choice = ComboBoxGetSelectedMenuItem(comboName) - 2
end


function CustomAutoRoll.OnDeleteButton()
	local buttonName = SystemData.ActiveWindow.name
	
	if( not ButtonGetDisabledFlag( buttonName ) ) then
		local rowNum = WindowGetId( buttonName )
		local autoRollIndex = _G[c_AUTO_ROLL_AUTO_ROLL_LIST].PopulatorIndices[ rowNum ]
		
		tremove(CustomAutoRoll.autoRollList, autoRollIndex)
		CustomAutoRoll.UpdateList()
	end
end


function CustomAutoRoll.OnListLbuttonUp()
	if( Cursor.IconOnCursor() ) then
		local backpackType = EA_BackpackUtilsMediator.GetCurrentBackpackType()
		local possibleBackpackCursor = EA_BackpackUtilsMediator.GetCursorForBackpack( backpackType )
		
		if( Cursor.Data and Cursor.Data.Source == possibleBackpackCursor ) then
			local inventorySlot = Cursor.Data.SourceSlot
			local itemData = EA_BackpackUtilsMediator.GetItemsFromBackpack( backpackType )[inventorySlot]
			
			CustomAutoRoll.AddByItemData(itemData)
			Cursor.Clear()
		end
	end
end


function CustomAutoRoll.AddByItemData( itemData )
	if( itemData
			and CustomAutoRoll.SearchItemById( CustomAutoRoll.autoRollList, itemData.uniqueID ) == nil
			and itemData.id ~= 0 ) then
		local autoRollRowData = {
			id		= itemData.uniqueID,
			iconNum	= itemData.iconNum,
			name	= itemData.name,
			rarity	= itemData.rarity,
			choice	= GameData.LootRoll.NEED,
		}
		tinsert(CustomAutoRoll.autoRollList, autoRollRowData)
		
		CustomAutoRoll.UpdateList()
	end
end


function CustomAutoRoll.AddById()
	local id = tonumber( TextEditBoxGetText(c_AUTO_ROLL_ADD_BY_ID_ID_EDITBOX) )
	
	if( CustomAutoRoll.SearchItemById( CustomAutoRoll.autoRollList, id) == nil ) then
		local name = TextEditBoxGetText(c_AUTO_ROLL_ADD_BY_ID_NAME_EDITBOX) or L""
		local autoRollRowData = {
			id		= id,
			name	= name,
			choice	= GameData.LootRoll.NEED,
		}
		tinsert(CustomAutoRoll.autoRollList, autoRollRowData)
		
		TextEditBoxSetText( c_AUTO_ROLL_ADD_BY_ID_ID_EDITBOX, L"" )
		TextEditBoxSetText( c_AUTO_ROLL_ADD_BY_ID_NAME_EDITBOX, L"" )
		
		CustomAutoRoll.UpdateList()
	end
end


-------------------------------
-- end LIST
-------------------------------

