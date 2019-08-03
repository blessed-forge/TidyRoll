if( TidyRoll == nil ) then
	TidyRoll = {}
end

TidyRoll.dVersion = L"v1.3.0"


--------------------------------------------------------------
-- CONSTANTS
--------------------------------------------------------------

local c_PLAYER_CAREER_LINE = GameData.Player.career.line

local c_MAX_ROLL_BUTTONS = 10

local c_TIDY_ROLL_FRAME = "TidyRollFrame"
local c_TIDY_ROLL_ANCHOR = "TidyRollAnchor"
local c_TIDY_ROLL_OPTIONS = "TidyRollOptions"
local c_TIDY_ROLL_TIMER = "TidyRollTimer"
local c_TIDY_ROLL_ESC = "TidyRollEsc"

local c_ROLL_CHOICE_GREED = GameData.LootRoll.GREED
local c_ROLL_CHOICE_NEED = GameData.LootRoll.NEED
local c_ROLL_CHOICE_PASS = GameData.LootRoll.PASS
local c_ROLL_CHOICE_INVALID  = GameData.LootRoll.INVALID

local c_SORT_TYPE_TIMER = 1
local c_SORT_TYPE_NAME = 2
local c_SORT_TYPE_RARITY = 3
local c_SORT_TYPE_LEVEL = 4
local c_SORT_TYPE_RENOWN = 5
local c_SORT_TYPE_TYPE = 6

local c_SORT_ORDER_UP = 1
local c_SORT_ORDER_DOWN = 2

--------------------------------------------------------------
-- LOCAL VARIABLES
--------------------------------------------------------------

-- locals for perfomance
local TidyRoll = TidyRoll
local pairs = pairs
local ipairs = ipairs
local tinsert = table.insert
local tremove = table.remove
local tsort = table.sort

local SelectItemRollChoice = SelectItemRollChoice
local GetLootRollData = GetLootRollData
local GetCareerIconIDFromCareerLine = Icons.GetCareerIconIDFromCareerLine
local GetItemRarityColor = DataUtils.GetItemRarityColor
local WindowSetShowing = WindowSetShowing

local Settings
local GetSetting
local SetSetting


-- util locals
local rVersion = 14
local troll_debug = false


-- Hooks' locals
local old_EASelectRollOption = nil
local old_EAUpdateLootRollData = nil


-- locals
local rollFrames = {}
local lootData = {}
local lootDataDisplayOrder = {}
local lastSourceId
local lootDataDirty = true
local firstLoad =  true
local testMode = false
local timePassed = 0

-- Custom items IDS --
local customAutoRollIds = {}

-- Instances zone IDs
local instanceZones = nil


-- LOCAL SETTINGS FOR PERFORMANCE --

local LocalSettings = {}

local SCROLL_INVERT
local DEFAULT_ENABLED
local DISABLE_AUTOROLL = false

-- DEFAULT SETTINGS --

local DefaultSettings = {
	-- General tab
	["default-disable"] = true,
	["tooltip-disable-comparison"] = false,
	["button-number"] = 1,
	["button-offset"] = 0,
	["button-growth-direction"] = L"down",
	
	-- Controls tab
	["scroll-invert"] = false,
	["managment-onesc-rollchoice"] = c_ROLL_CHOICE_INVALID,
	["managment-onesc-visible-only"] = true,
	["managment-bind-need"] = 2,
	["managment-bind-need-modificator"] = 0,
	["managment-bind-greed"] = 3,
	["managment-bind-greed-modificator"] = 0,
	["managment-bind-pass"] = 4,
	["managment-bind-pass-modificator"] = 0,

	-- Misc tab
	["auto-greed"] = false,
	["auto-need-for-medallions"] = false,
	["auto-roll-disable-in-dungeons"] = false,
	["timer-show-text"] = true,
	["career-icon-show"] = true,
	["onnew-save-position"] = true,
	["onnew-flash"] = true,
	["onnew-glow"] = true,
	["onnew-flash-only-new-items"] = false,
	["onnew-glow-only-new-items"] = false,
	["sort-type"] = c_SORT_TYPE_TIMER,
	["sort-order"] = c_SORT_ORDER_UP,
}


-- LOCAL FUNCTIONS --

-- declaration
local SetupTestData


local function GetLootId(rollData)
	return( rollData.sourceId * 100 + rollData.lootSlot )
end


local function ScrollTableDown(tbl)
	local temp = tbl[1]
	tremove(tbl, 1)
	tinsert(tbl, temp)
end


local function ScrollTableUp(tbl)
	local length = #tbl
	local temp = tbl[length]
	tremove(tbl, length)
	tinsert(tbl, 1, temp)
end


local sortKeys = {
	[c_SORT_TYPE_RARITY] = "rarity",
	[c_SORT_TYPE_LEVEL] = "level",
	[c_SORT_TYPE_RENOWN] = "renown",
	[c_SORT_TYPE_TYPE] = "type",
}

local function CompareItems(index1, index2)
	if( index1 == nil ) then
		return true
	end
	
	if( index2 == nil ) then
		return false
	end
	
	local type = GetSetting("sort-type")
	local order = GetSetting("sort-order")
	
	if( type ~= c_SORT_TYPE_TIMER ) then
		
		local rollData1 = lootData[index1]
		local rollData2 = lootData[index2]
		
		if( rollData1 == nil or rollData1.itemData == nil or rollData1.itemData.id == 0 ) then
			return false
		end
		if( rollData2 == nil or rollData2.itemData == nil or rollData2.itemData.id == 0 ) then
			return true
		end
		
		
		if( type == c_SORT_TYPE_NAME ) then
			-- Sort by name
			
			compareResult = WStringsCompare(rollData1.itemData.name, rollData2.itemData.name)
			
			if( compareResult ~= 0 ) then
				if( order == c_SORT_ORDER_UP ) then
					return( compareResult < 0 )
				else
					return( compareResult > 0 )
				end
			end
			
		else
			-- Sort by key-number
			
			local key = sortKeys[type]
			
			local value1 = rollData1.itemData[key]
			local value2 = rollData2.itemData[key]
			
			if( value1 ~= value2 ) then
				if( order == c_SORT_ORDER_UP ) then
					return( value1 < value2 )
				else
					return( value1 > value2 )
				end
			end
		end
	
	end
	
	-- Sort by timer
	if( order == c_SORT_ORDER_UP ) then
		return( index1 < index2 )
	else
		return( index1 > index2 )
	end
end


local function print_autoroll(text)
	TextLogAddEntry ("Chat", SystemData.ChatLogFilters.LOOT_ROLL, text)
end

--------------------------------------------------------------
-- END LOCAL VARIABLES
--------------------------------------------------------------


function TidyRoll.ToggleOptions()
	WindowSetShowing( c_TIDY_ROLL_OPTIONS, not WindowGetShowing(c_TIDY_ROLL_OPTIONS) )
end


function TidyRoll.Initialize()
	CreateWindow(c_TIDY_ROLL_ANCHOR, false)
	CreateWindow(c_TIDY_ROLL_TIMER, false)
	CreateWindow(c_TIDY_ROLL_ESC, false)

	LayoutEditor.RegisterWindow(c_TIDY_ROLL_ANCHOR, L"Tidy Roll", L"Where Tidy Roll are displayed.", false, false, true, nil)
	
	RegisterEventHandler( SystemData.Events.LOADING_END,  "TidyRoll.OnLoad")
    RegisterEventHandler( SystemData.Events.RELOAD_INTERFACE,  "TidyRoll.OnLoad")
    RegisterEventHandler( SystemData.Events.INTERACT_SHOW_LOOT_ROLL_DATA, "TidyRoll.OnUpdateLootRollData")
	RegisterEventHandler( SystemData.Events.INTERACT_LOOT_ROLL_FIRST_ITEM, "TidyRoll.OnLootRollFirstItem")
	RegisterEventHandler( SystemData.Events.PLAYER_ZONE_CHANGED, "TidyRoll.OnZoneChange" )
	
    tinsert(LayoutEditor.EventHandlers,
		function (eventId)
			if eventId == LayoutEditor.EDITING_END then
				TidyRoll.RefreshFrames()
			end
		end
	)
end


function TidyRoll.Shutdown()
	UnregisterEventHandler( SystemData.Events.LOADING_END,  "TidyRoll.OnLoad")
    UnregisterEventHandler( SystemData.Events.RELOAD_INTERFACE,  "TidyRoll.OnLoad")
    UnregisterEventHandler( SystemData.Events.INTERACT_SHOW_LOOT_ROLL_DATA, "TidyRoll.OnUpdateLootRollData")
	UnregisterEventHandler( SystemData.Events.INTERACT_LOOT_ROLL_FIRST_ITEM, "TidyRoll.OnLootRollFirstItem")
	UnregisterEventHandler( SystemData.Events.PLAYER_ZONE_CHANGED, "TidyRoll.OnZoneChange" )
	
    LayoutEditor.UnregisterWindow( c_TIDY_ROLL_ANCHOR )
end


function TidyRoll.SetupLocals()
	Settings = TidyRoll.Settings
	GetSetting = TidyRoll.GetSetting
	SetSetting = TidyRoll.SetSetting
end


function TidyRoll.OnLoad()
	if( firstLoad ) then
		firstLoad = false
		
		-- Register slash command
		if( LibSlash ~= nil ) then
            LibSlash.RegisterWSlashCmd("troll", TidyRoll.ToggleOptions)
		end
		
		if( TidyRoll.Settings == nil ) then TidyRoll.Settings = {} end
		
		TidyRoll.SetupLocals()
		TidyRollFrame.SetupLocals()
		TidyRollOptions.SetupLocals()
		TidyRoll.CustomAutoRoll.SetupLocals()
		
		TidyRoll.Reload()
		TidyRollOptions.Initialize()
		TidyRoll.CustomAutoRoll.Initialize()
		
		-- Unregister some events
		if( DoesWindowExist("EA_Window_LootRoll") ) then
			WindowUnregisterCoreEventHandler("EA_Window_LootRoll", "OnShown")
			WindowUnregisterCoreEventHandler("EA_Window_LootRoll", "OnHidden")
			
			if( not DEFAULT_ENABLED ) then
				WindowSetShowing("EA_Window_LootRoll", false)
			end
			
			-- Set hooks
			if( EA_Window_LootRoll and type(EA_Window_LootRoll.SelectRollOption) == "function" ) then
				old_EASelectRollOption = EA_Window_LootRoll.SelectRollOption
				EA_Window_LootRoll.SelectRollOption = function (...)
					old_EASelectRollOption(...)
					if( troll_debug ) then DEBUG(L"TidyRoll: EA_Window_LootRoll.SelectRollOption") end
					TidyRoll.UpdateLootRollData()
				end
				
				old_EAUpdateLootRollData = EA_Window_LootRoll.UpdateLootRollData
				EA_Window_LootRoll.UpdateLootRollData = function (...)
					if( DEFAULT_ENABLED ) then
						old_EAUpdateLootRollData(...)
					end
				end
			end

		end
		
		SetSetting("version", rVersion)
	end
	-- end firstLoad
	
	if( troll_debug ) then DEBUG(L"TidyRoll: TidyRoll.OnLoad") end
	TidyRoll.OnZoneChange()
	TidyRoll.UpdateLootRollData()
end


function TidyRoll.Reload()
	TidyRoll.SetupLocalSettings()
	
	TidyRoll.ToggleDefault()
	TidyRoll.InitializeFrames()
	TidyRoll.RefreshFrames()
end


function TidyRoll.ToggleDefault()
	if( not DEFAULT_ENABLED and EA_Window_LootRoll and EA_Window_LootRoll.lootDataDisplayOrder ) then
		EA_Window_LootRoll.lootDataDisplayOrder = nil
	end
end


function TidyRoll.InitializeFrames()
	local buttonNum = GetSetting("button-number")
	
	for index = 1, c_MAX_ROLL_BUTTONS do
		
		if ( index <= buttonNum ) and ( rollFrames[index] == nil ) then
			rollFrames[index] = TidyRollFrame:Create( c_TIDY_ROLL_FRAME .. tostring(index) )
			
		elseif ( index > buttonNum ) and ( rollFrames[index] ~= nil ) then
			rollFrames[index]:Destroy()
			rollFrames[index] = nil
		end
	end
end


function TidyRoll.RefreshFrames()
	local direction = GetSetting("button-growth-direction")
	local offset = GetSetting("button-offset")

	if type(offset) ~= "number" then offset = 0 end
	
	local anchor = {
		RelativeTo = c_TIDY_ROLL_ANCHOR,
		Point = "topleft",
		RelativePoint = "topleft",
	}
	
	for _, frame in ipairs(rollFrames) do
		frame:SetAnchor(anchor)
		frame:SetScale( WindowGetScale(c_TIDY_ROLL_ANCHOR) )
		
		anchor = TidyRoll.CreateAnchor( frame:GetName(), direction, offset )
	end
end


local function AutoRoll(lootIndex, rollData )
    local autoRollSettings = EA_Window_OpenPartyLootRollOptions.Settings
    local item = rollData.itemData
    local rolled = false
    
    -- Don't auto roll on item set pieces
    if item.itemSet > 0
    then
        return rolled
    end

    local function CheckAndDoAutoRoll( filter, rollChoice )
        if filter and rollChoice and rollChoice ~= c_ROLL_CHOICE_INVALID
        then
            rolled = TidyRoll.SelectRollOption( lootIndex, rollChoice, false )
            return true
        end
        return false
    end
    
    local function CheckAndDoAutoRollWithRarity( filter, rollChoiceTable )
        local rollChoice = rollChoiceTable[item.rarity]
        CheckAndDoAutoRoll( filter, rollChoice )
    end
    
    -- simple type checks
    if      CheckAndDoAutoRoll( item.rarity == SystemData.ItemRarity.UTILITY, autoRollSettings.trash )
        or  CheckAndDoAutoRollWithRarity( DataUtils.IsTradeSkillItem( item, nil ), autoRollSettings.crafting )
        or  CheckAndDoAutoRollWithRarity( item.type == GameData.ItemTypes.CURRENCY, autoRollSettings.currency )
        or  CheckAndDoAutoRollWithRarity( item.type == GameData.ItemTypes.POTION, autoRollSettings.potion )
        or  CheckAndDoAutoRollWithRarity( item.type == GameData.ItemTypes.ENHANCEMENT, autoRollSettings.talisman )
    then
        return rolled
    end
    
    -- equipment (usable and unusable)
    local playerCanEventuallyUse = DataUtils.PlayerCanEventuallyUseItem( item )
    local isEquipment = DataUtils.ItemIsWeapon( item ) or DataUtils.ItemIsArmor( item )
    if      CheckAndDoAutoRollWithRarity( isEquipment and playerCanEventuallyUse, autoRollSettings.usableEquipment )
        or  CheckAndDoAutoRollWithRarity( isEquipment and not playerCanEventuallyUse, autoRollSettings.unusableEquipment )
    then
        return rolled
    end

    return rolled
end


function TidyRoll.OnUpdateLootRollData()
	if( firstLoad ) then return end
	
	if( troll_debug ) then DEBUG(L"TidyRoll: TidyRoll.OnUpdateLootRollData") end
	
	lootDataDirty = true
	WindowSetShowing( c_TIDY_ROLL_TIMER, true )
end


function TidyRoll.UpdateLootRollData( temptest )
	if( firstLoad ) then return end
	
	lootDataDirty = false
	
	local AUTO_GREED = not DISABLE_AUTOROLL and GetSetting("auto-greed")
	local AUTO_NEED_FOR_MEDALLIONS = not DISABLE_AUTOROLL and GetSetting("auto-need-for-medallions")
	
	local oldlootData = lootData
	local oldlootDataDisplayOrder = lootDataDisplayOrder
	local oldListLen = #oldlootDataDisplayOrder
	
	local oldPositionLootId
	if( oldListLen > 0 ) then
		local rollData
		for _, lootIndex in ipairs(oldlootDataDisplayOrder) do
			rollData = oldlootData[lootIndex]
			
			if( lootIndex and rollData.rollChoice == c_ROLL_CHOICE_INVALID ) then
				oldPositionLootId = GetLootId(rollData)
				break
			end
		end
	end
	
	lootData = GetLootRollData()
	lootDataDisplayOrder = {}
	
	if( troll_debug and temptest ~= 123 ) then
		local oldlootDataLen = 0
		for _, rollData in ipairs( oldlootData ) do
			if( rollData.sourceId ~= 0 and rollData.rollChoice == c_ROLL_CHOICE_INVALID ) then
				oldlootDataLen = oldlootDataLen + 1
			end
		end
		
		local lootDataLen = 0
		for _, rollData in ipairs( lootData ) do
			if( rollData.sourceId ~= 0 and rollData.rollChoice == c_ROLL_CHOICE_INVALID ) then
				lootDataLen = lootDataLen + 1
			end
		end
		
		DEBUG(L"TidyRoll.UpdateLootRollData, oldlootDataLen = " .. oldlootDataLen .. L", newlootDataLen = " .. lootDataLen)
	end
	
	-- Test Data
	if( testMode and lootData[1].itemData.id == 0 ) then
		SetupTestData()
		lastSourceId = 12345000 + c_MAX_ROLL_BUTTONS
		oldListLen = 7
		
		if( AUTO_GREED ) then
			oldListLen = 3
		end
	end
	
	local itemData
	local choice
	for lootIndex, rollData in ipairs( lootData )
	do
		itemData = rollData.itemData
		
		if( itemData.id ~= 0 and rollData.rollChoice == c_ROLL_CHOICE_INVALID ) 
		then
			if( AUTO_NEED_FOR_MEDALLIONS and customAutoRollIds[itemData.uniqueID]
					and ( rollData.allowNeed == true or customAutoRollIds[itemData.uniqueID] ~= c_ROLL_CHOICE_NEED ) ) then
					
				choice = customAutoRollIds[itemData.uniqueID]
				if( choice ~= c_ROLL_CHOICE_INVALID ) then
					TidyRoll.SelectRollOption( lootIndex, choice, false )
					--print_autoroll( L"TidyRoll: Auto Roll on " .. itemData.name .. L" !!!" )
					if( troll_debug ) then DEBUG(L"TidyRoll: Auto Roll on " .. itemData.name .. L" !!!") end
				else
					tinsert( lootDataDisplayOrder, lootIndex )
				end
				
			elseif( AUTO_GREED and not rollData.allowNeed ) then
				TidyRoll.SelectRollOption( lootIndex, c_ROLL_CHOICE_GREED, false )
				--print_autoroll( L"TidyRoll: Auto Greed on " .. itemData.name .. L" !!!" )
				if( troll_debug ) then DEBUG(L"TidyRoll: Auto Greed on " .. itemData.name .. L" !!!") end
				
			elseif( not DISABLE_AUTOROLL and not DEFAULT_ENABLED and AutoRoll(lootIndex, rollData) ) then
				--print_autoroll( L"Auto Roll on " .. itemData.name .. L" !!!" )
				if( troll_debug ) then DEBUG(L"Auto Roll on " .. itemData.name .. L" !!!") end
				
			else
				tinsert( lootDataDisplayOrder, lootIndex )
			end
		end    	    
	end
	
	-- NEW ITEM ANIMATION / SAVE POSITION / SORT
	
	local listLen = #lootDataDisplayOrder
	local diff = listLen - oldListLen
	
	local isNewItems
	
	if( diff == 0 ) then
		-- do nothing
		if( listLen == 0 ) then
			if( troll_debug ) then DEBUG(L"TidyRoll: diff = 0, listLen = 0") end
			return
		end
		
		if( troll_debug ) then
			local equalLootData
			local oldLootID
			
			for _, oldlootIndex in ipairs(oldlootDataDisplayOrder) do
				oldLootID = GetLootId(oldlootData[oldlootIndex])
				equalLootData = false
				
				for _, lootIndex in ipairs(lootDataDisplayOrder) do
					if( oldLootID == GetLootId(lootData[lootIndex]) ) then
						if( oldlootData[oldlootIndex].rollChoice ~= lootData[lootIndex].rollChoice ) then
							DEBUG(L"TidyRoll: LootRollData same but rollChoice not equal")
							d(oldlootData[oldlootIndex])
							d(lootData[lootIndex])
						end
						if( oldlootData[oldlootIndex].itemData.uniqueID ~= lootData[lootIndex].itemData.uniqueID ) then
							DEBUG(L"TidyRoll: LootRollData same but uniqueID not equal")
							d(oldlootData[oldlootIndex])
							d(lootData[lootIndex])
						end
						equalLootData = true
						break
					end
				end
				
				if( not equalLootData ) then
					break
				end
			end
			
			if( equalLootData ) then
				DEBUG(L"TidyRoll: diff = 0, Loot Data same")
				lootDataDisplayOrder = oldlootDataDisplayOrder
				lootData = oldlootData
				return
			else
				DEBUG(L"TidyRoll: diff = 0, but Loot Data not same")
				DEBUG(L"======================================== ============================================ OLD LOOT DATA")
				d(oldlootData)
				DEBUG(L"======================================== ============================================ NEW LOOT DATA")
				d(lootData)
			end
			
			--[[
			equalLootData = true
			for _, lootIndex in ipairs(oldlootDataDisplayOrder) do
				if( lootData[ lootIndex ].sourceId ~= oldlootData[ lootIndex ].sourceId 
					or lootData[ lootIndex ].lootSlot ~= oldlootData[ lootIndex ].lootSlot)
				then
					equalLootData = false
					if( troll_debug ) then
						DEBUG(L"TidyRoll: diff = 0, but Loot Data not equal")
					end
					break
				end
			end
			
			if( equalLootData ) then
				--lootDataDisplayOrder = oldlootDataDisplayOrder
				if( troll_debug ) then DEBUG(L"TidyRoll: diff = 0, Loot Data equal") end
				--return
			end
			--]]
		else
			lootDataDisplayOrder = oldlootDataDisplayOrder
			lootData = oldlootData
			return
		end
		
	elseif( diff > 0 ) then
		if( troll_debug ) then DEBUG(L"TidyRoll: diff > 0") end
		
		if( not GetSetting("onnew-save-position") ) then
			oldPositionLootId = nil
		end
		
		isNewItems = true
		
		lastSourceId = lootData[ lootDataDisplayOrder[listLen] ].sourceId
		
	else
		if( troll_debug ) then DEBUG(L"TidyRoll: diff < 0 ") end
		
		isNewItems = false
		
		-- DEBUG
		if( troll_debug and temptest ~= 123 ) then
			DEBUG(L"TidyRoll.UpdateLootRollData: Item lost, diff = " .. diff)
			EA_ChatWindow.Print(L"  !!!  TIDYROLL: ITEM LOST, diff = " .. diff)
			DEBUG(L"======================================== ============================================ OLD LOOT DATA")
			d(oldlootData)
			DEBUG(L"======================================== ============================================ NEW LOOT DATA")
			d(lootData)
		end
	end
	
	if( listLen > 1 ) then
		
		-- Sort Table
		tsort(lootDataDisplayOrder, CompareItems)
		
		-- Scroll to old position or to top item in list
		if( oldPositionLootId ) then
			for index = 1, listLen do
				if( oldPositionLootId == GetLootId(lootData[ lootDataDisplayOrder[1] ]) ) then
					break
				end
				
				ScrollTableDown(lootDataDisplayOrder)
			end
		end
	end
	
	TidyRoll.UpdateFrames(true, isNewItems)
end


function TidyRoll.UpdateFrames(updateShowing, isNewItems)
	local ON_NEW_FLASH_ONLY_NEW_ITEMS = GetSetting("onnew-flash-only-new-items")
	local ON_NEW_GLOW_ONLY_NEW_ITEMS  = GetSetting("onnew-glow-only-new-items")
	local ON_NEW_FLASH = GetSetting("onnew-flash") and isNewItems
	local ON_NEW_GLOW  = GetSetting("onnew-glow") and (ON_NEW_GLOW_ONLY_NEW_ITEMS or isNewItems)
	local CAREER_ICON_SHOW = GetSetting("career-icon-show")
	
	local rollData
	local frame
	local flash
	local glow
	local itemCareer
	for index, lootIndex in ipairs( lootDataDisplayOrder )
	do
		rollData = lootData[lootIndex]
		frame = rollFrames[index]
		
		if( frame ) then
			
			-- Flash & Glow
			flash = ON_NEW_FLASH and ( not ON_NEW_FLASH_ONLY_NEW_ITEMS or rollData.sourceId == lastSourceId )
			glow  = ON_NEW_GLOW  and ( not ON_NEW_GLOW_ONLY_NEW_ITEMS  or rollData.sourceId == lastSourceId )
			
			if( CAREER_ICON_SHOW ) then
				itemCareer = rollData.itemData.careers[1]
				
				if( rollData.itemData.careers[2] ~= nil ) then
					for _, careerLine in ipairs(rollData.itemData.careers) do
						if( careerLine == c_PLAYER_CAREER_LINE ) then
							itemCareer = careerLine
							break
						end
					end
				end
			end
			
			frame:SetLootData(
				lootIndex,
				rollData.itemData.iconNum,
				rollData.allowNeed,
				rollData.timer,
				GetItemRarityColor(rollData.itemData),
				GetCareerIconIDFromCareerLine( itemCareer ),
				flash,
				glow)
		end
	end
	
	if( updateShowing ) then
		for index, frame in ipairs(rollFrames) do
			--Show frames when they contain items
			if( lootDataDisplayOrder[index] ) then
				frame:Show( true )
			else
				frame:Show( false )
				frame.isValidTidyRollFrame = false
			end
		end
		
		local listNotEmpty = lootDataDisplayOrder[1] ~= nil
		
		WindowSetShowing( c_TIDY_ROLL_TIMER, listNotEmpty )
		if( not listNotEmpty ) then
			timePassed = 0
		end
		
		if( (listNotEmpty) and (GetSetting("managment-onesc-rollchoice") ~= c_ROLL_CHOICE_INVALID) and (not testMode) ) then
			WindowSetShowing( c_TIDY_ROLL_ESC, true )
		else
			WindowSetShowing( c_TIDY_ROLL_ESC, false )
		end
		
		TidyRoll.UpdateTooltip()
	end
end


function TidyRoll.UpdateTooltip(rollFrame)
	rollFrame = rollFrame or FrameManager:GetMouseOverWindow()
	
	if( rollFrame and rollFrame.isValidTidyRollFrame ) then
		Tooltips.CreateItemTooltip( lootData[rollFrame.m_LootIndex].itemData, SystemData.MouseOverWindow.name, nil, GetSetting("tooltip-disable-comparison") )
	end
end


function TidyRoll.SelectRollOption( lootIndex, rollChoice, update )
	local rollData = lootData[lootIndex]
	if( troll_debug ) then
		DEBUG(L"TidyRoll.SelectRollOption sourceId=" .. towstring(tostring( rollData.sourceId )) .. L",lootSlot=" .. towstring(tostring( rollData.lootSlot )) .. L",index=" .. towstring(tostring( lootIndex )) .. L",choice=" .. towstring(tostring( rollChoice )) .. L",name=" .. towstring(tostring( rollData.itemData.name )) .. L",uniqueID=" .. towstring(tostring( rollData.itemData.uniqueID )))
	end
	
	if( rollChoice ~= c_ROLL_CHOICE_NEED or rollData.allowNeed == true ) then
		rollData.rollChoice = rollChoice
		
		SelectItemRollChoice( rollData.sourceId, rollData.lootSlot, rollChoice )
	
		if( update ~= false ) then
			TidyRoll.UpdateLootRollDataWithDefault()
		end
		
		return true
	end
	
	return false
end


function TidyRoll.UpdateLootRollDataWithDefault()
	--if( troll_debug ) then DEBUG(L"TidyRoll.UpdateLootRollDataWithDefault") end
	
	TidyRoll.UpdateLootRollData(123)
	
    if( DEFAULT_ENABLED and EA_Window_LootRoll and EA_Window_LootRoll.UpdateLootRollData ) then
		EA_Window_LootRoll.UpdateLootRollData()
	end
end


--------------------------------------------------------------
-- UTILS
--------------------------------------------------------------

function TidyRoll.CreateAnchor( toWindow, direction, offset )
	local anchor = {
		RelativeTo = toWindow,
		Point = "bottomleft",
		RelativePoint = "topleft",
		XOffset = 0,
		YOffset = 0,
	}
	
	if( direction == L"left" ) then
		anchor.Point = "topleft"
		anchor.RelativePoint = "topright"
		anchor.XOffset = - offset
	elseif( direction == L"right" ) then
		anchor.Point = "topright"
		anchor.RelativePoint = "topleft"
		anchor.XOffset = offset
	elseif( direction == L"up" ) then
		anchor.Point = "topleft"
		anchor.RelativePoint = "bottomleft"
		anchor.YOffset = - offset
	else
		anchor.YOffset = offset
	end
	
	return anchor
end


function TidyRoll.GetSetting(key)
	return LocalSettings[key]
end

function TidyRoll.SetSetting(key, value)
    Settings[key] = value
end


function TidyRoll.SetupLocalSettings()
	for key, default in pairs( DefaultSettings ) do
		local setting = Settings[key]
		local old_setting = LocalSettings[key]
		
		if( type(setting) == type(default) ) then
			LocalSettings[key] = setting
			
		elseif( type(old_setting) == type(default) ) then
			Settings[key] = old_setting
			
		else
			LocalSettings[key] = default
			Settings[key] = default
		end
	end
	
	-- Fix number if needed
	local key = "button-number"
	if( LocalSettings[key] > c_MAX_ROLL_BUTTONS ) then
		LocalSettings[key] = c_MAX_ROLL_BUTTONS
		Settings[key] = c_MAX_ROLL_BUTTONS
	elseif( LocalSettings[key] < 1 ) then
		LocalSettings[key] = 1
		Settings[key] = 1
	end
	
	
	-- SCROLL_INVERT
	local direction = LocalSettings["button-growth-direction"]
	local invert = LocalSettings["scroll-invert"]
	
	if( (direction == L"up") or (direction == L"right") ) then
		SCROLL_INVERT = true
	else
		SCROLL_INVERT = false
	end
	
	if( invert == true ) then
		SCROLL_INVERT = not SCROLL_INVERT
	end
	
	
	-- DEFAULT_ENABLED
	DEFAULT_ENABLED = not LocalSettings["default-disable"]
	
	TidyRollFrame.SetupLocalSettings()
end


function TidyRoll.UpdateCustomAutoRollIds( customAutoRollSettings )
	customAutoRollIds = {}
	
	for _, autoRollData in ipairs( customAutoRollSettings ) do
		local choice = autoRollData.choice
		if( choice == c_ROLL_CHOICE_INVALID or choice == c_ROLL_CHOICE_NEED or choice == c_ROLL_CHOICE_GREED or choice == c_ROLL_CHOICE_PASS ) then
			customAutoRollIds[autoRollData.id] = choice
		end
	end
end


-------------------
-- TEST DATA
-------------------

function TidyRoll.SetTestMode(flag)
	testMode = flag
end


function SetupTestData()
	for index = 1, c_MAX_ROLL_BUTTONS do
		local flag = false
		if( math.mod(index, 2) == 0 ) then flag = true end
		
		lootData[index] = {
			lootSlot = index - 1,
			timer = 40 + index * 2,
			allowNeed = flag,
			rollChoice = -1,
			sourceId = 12345000 + index,
			itemData = {
				id = 12345,
				uniqueID = 123456789,
				iconNum = math.floor(math.random(200, 934)),
				name = L"Test Item " .. index,
				description = L"Test Item 1 - the oldest, Test Item 10 - the newest",
				level = math.floor(math.random(40)),
				renown = math.floor(math.random(40)),
				iLevel = math.floor(math.random(40)),
				equipSlot = math.floor(math.random(20)),
				rarity = math.floor(math.random(6)),
				careers = { [1] = math.floor(math.random(24)), },
				
				timeLeftBeforeDecay = 0,
				blockRating = 0,
				armor = 0,
				maxEquip = 0,
				petAbility = false,
				capacity = 5,
				marketingVariation = 0,
				hasAction = true,
				actionType = "item",
				broken = false,
				timestamp = 24932,
				customizedIconNum = 0,
				marketingIndex = 0,
				speed = 0,
				isTwoHanded = false,
				decayPaused = false,
				speed = 0,
				craftingSkillRequirement = 0,
				sellPrice = 12,
				cultivationType = 0,
				dyeTintB = 0,
				dyeTintA = 0,
				tintA = 0,
				tier = 0,
				currChargesRemaining = 1,
				trophyLocation = 0,
				numEnhancementSlots = 0,
				type = 0,
				boundToPlayer = true,
				customizedIconName = "",
				dps = 0,
				trophyLocIndex = 1,
				isNew = false,
				bop = true,
				noChargeLeftDontDelete = 0,
				stackCount = 1,
				itemSet = 0,
				isRefinable = false,
				
				slots = {},
				races = {},
				flags = {},
				enhSlot = {},
				bonus = {},
				craftingBonus = {},
				skills = {},
			}
		}
	end
end


--------------------------------------------------------------
-- EVENTS
--------------------------------------------------------------

function TidyRoll.OnUpdate( passed )
	timePassed = timePassed + passed
	
	if( timePassed < 0.1 ) then return end
	
	if( lootDataDirty ) then TidyRoll.UpdateLootRollData() end
	
	local allLootsDone = true
	local updateNeeded = false
	
	if( lootDataDisplayOrder ~= nil and lootData ~= nil )
    then
		local rollData
		local frame
		for index, lootIndex in ipairs( lootDataDisplayOrder )
        do
			rollData = lootData[ lootIndex ]
			frame = rollFrames[index]
			
			-- Decrement the Timer
			if( rollData.timer ~= nil and rollData.timer ~= 0 )
			then
				rollData.timer = rollData.timer - timePassed
				
				if( rollData.timer <= 0 )
				then
                    rollData.timer = 0
                    if( rollData.itemData.id ~= 0 and rollData.rollChoice == c_ROLL_CHOICE_INVALID )
                    then
						if( troll_debug ) then DEBUG(L"TidyRoll: timer = 0 pass on item, name = " .. towrustring(torustring(rollData.itemData.name))) end
						
						TidyRoll.SelectRollOption( lootIndex, c_ROLL_CHOICE_PASS, false )
						updateNeeded = true
                    end
                else
                    allLootsDone = false
                    
                    if( frame ) then
						frame:SetTimer( rollData.timer )
					end
                end
            end
		end
	end
	
	if( allLootsDone )
    then
		if( troll_debug ) then DEBUG(L"TidyRoll.OnUpdate allLootsDone") end
		
		if( lootDataDisplayOrder[1] ) then
			lootDataDisplayOrder = {}
			TidyRoll.UpdateFrames(true)
		end
		
		WindowSetShowing( c_TIDY_ROLL_TIMER, false )
    end
    
    if( updateNeeded ) then
		TidyRoll.UpdateLootRollDataWithDefault()
	end
	
	timePassed = 0
end


function TidyRoll.OnMouseWheel (x, y, delta, flags, rollFrame)
	if( not lootDataDisplayOrder[2] ) then
		return
	end
	
	if( SCROLL_INVERT ) then
		delta = - delta
	end
	
	if( delta < 0 ) then
		ScrollTableDown (lootDataDisplayOrder)
	elseif( delta > 0 ) then
		ScrollTableUp (lootDataDisplayOrder)
	end
	
	TidyRoll.UpdateFrames()
	TidyRoll.UpdateTooltip(rollFrame)
end


function TidyRoll.OnEsc()
	WindowUtils.OnHidden()
	
	local rollChoice = GetSetting("managment-onesc-rollchoice")

	if( (not lootDataDisplayOrder[1]) or (rollChoice == c_ROLL_CHOICE_INVALID) or (testMode) ) then
		return
	end
	
	if( GetSetting("managment-onesc-visible-only") ) then
		if( troll_debug ) then DEBUG(L"TidyRoll.OnEsc roll on visible-only") end
		
		for _, frame in ipairs(rollFrames) do
			if( frame:IsShowing() == true and frame.isValidTidyRollFrame ) then
				TidyRoll.SelectRollOption( frame.m_LootIndex, rollChoice, false )
			end
		end
	else
		if( troll_debug ) then DEBUG(L"TidyRoll.OnEsc roll on all") end
		
		for rowIndex, rollData in ipairs( lootData ) do
			if( rollData.itemData.id ~= 0 and rollData.rollChoice == c_ROLL_CHOICE_INVALID ) then
				TidyRoll.SelectRollOption( rowIndex, rollChoice, false )
			end
		end
	end
	
	TidyRoll.UpdateLootRollDataWithDefault()
end


function TidyRoll.OnLootRollFirstItem(rollChoice)
	if( troll_debug ) then DEBUG(L"============================== !!!!!!!!!!!!!!!!!!!!! TidyRoll.OnLootRollFirstItem, rollChoice = " .. towstring(tostring(rollChoice))) end
end


function TidyRoll.OnZoneChange()
	if( troll_debug ) then DEBUG(L"TidyRoll.OnZoneChange, zoneId = " .. towstring(tostring(GameData.Player.zone))) end
	
	if( firstLoad or not GetSetting("auto-roll-disable-in-dungeons") ) then return end
	
	instanceZones = instanceZones or {
			[41]  = true, --	Altdorf War Quarters^n,in
			[50]  = true, --	Hunter's Vale^n,in
			[60]  = true, --	Mount Gunbad^n,in
			[63]  = true, --	Gunbad Nursery^n,in
			[64]  = true, --	Gunbad Lab^n,in
			[65]  = true, --	Squig Boss^n,in
			[66]  = true, --	Gunbad Barracks^n,in
			[152] = true, --	The Sewers of Altdorf^n,in
			[153] = true, --	The Sewers of Altdorf^n,in
			[154] = true, --	Warpblade Tunnels^n,in
			[155] = true, --	Sacellum Dungeons^n,in
			[156] = true, --	Sacellum Dungeons^n,in
			[157] = true, --	Temple of Sigmar
			[158] = true, --	The Monolith^n,in
			[159] = true, --	The Sacellum^n,in
			[160] = true, --	Bastion Stair^n,in
			[163] = true, --	Thar'Ignan^n,in
			[164] = true, --	Lord Slaurith^n,in
			[165] = true, --	Kaarn the Vanquisher^n,in
			[166] = true, --	Skull Lord Var'Ithrok^n,in
			[169] = true, --	The Sewers of Altdorf^n,in
			[170] = true, --	Altdorf Palace^n,in
			[171] = true, --	The Screaming Cat^n,in
			[173] = true, --	Sacellum Dungeons^n,in
			[174] = true, --	The Elysium^n,in
			[176] = true, --	Sigmar Crypts^n,in
			[177] = true, --	Warpblade Tunnels^n,in
			[179] = true, --	Tomb of the Vulture Lord^n,in
			[195] = true, --	Bloodwrought Enclave^n,in
			[196] = true, --	Bilerot Burrow^n,in
			[241] = true, --	Tomb of the Stars^n,in
			[242] = true, --	Tomb of the Moon^n,in
			[243] = true, --	Tomb of the Sky^n,in
			[244] = true, --	Tomb of the Sun^n,in
			[260] = true, --	The Lost Vale^n,in
		}
	
	DISABLE_AUTOROLL = instanceZones[GameData.Player.zone] or false
	
	if( troll_debug ) then DEBUG(L"DISABLE_AUTOROLL = " .. towstring(tostring(DISABLE_AUTOROLL))) end
end
