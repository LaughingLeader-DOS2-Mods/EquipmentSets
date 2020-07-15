local LeaderLib = Mods.LeaderLib
local Classes = LeaderLib.Classes
local MessageData = Classes.MessageData
local TranslatedString = Classes.TranslatedString

local SetToSkill = {
	["Set1"] = "Shout_LLEQSET_EquipmentSet1",
	["Set2"] = "Shout_LLEQSET_EquipmentSet2",
	["Set3"] = "Shout_LLEQSET_EquipmentSet3",
	["Set4"] = "Shout_LLEQSET_EquipmentSet4",
	["Set5"] = "Shout_LLEQSET_EquipmentSet5",
}

local SlotOrder = {
	"Ring2",
	"Ring",
	"Belt",
	"Boots",
	"Leggings",
	"Gloves",
	"Breast",
	"Helmet",
	"Amulet",
	"Shield",
	"Weapon",
}

function SyncEquipmentData(character)
	local equipmentSetData = {
		Shout_LLEQSET_EquipmentSet1 = {Name="", Data={}},
		Shout_LLEQSET_EquipmentSet2 = {Name="", Data={}},
		Shout_LLEQSET_EquipmentSet3 = {Name="", Data={}},
		Shout_LLEQSET_EquipmentSet4 = {Name="", Data={}},
		Shout_LLEQSET_EquipmentSet5 = {Name="", Data={}},
	}

	local hasEquipmentData = false
	--DB_LLEQSET_SetManager_SetConfig(_SetID, _Skill, _ItemTemplate, _BackpackTemplate)

	--DB_LLEQSET_SetManager_SetNames(_Player, _SetID, _Name)
	--DB_LLEQSET_SetManager_DefaultSetNames(_SetID, _DefaultName)

	for id,skill in pairs(SetToSkill) do
		local setName = Osi.DB_LLEQSET_SetManager_SetNames:Get(character, id, nil)
		if setName ~= nil and #setName > 0 then
			equipmentSetData[skill].Name = setName[1][3]
		else
			local defaultName = Osi.DB_LLEQSET_SetManager_DefaultSetNames:Get(id, nil)[1][2]
			equipmentSetData[skill].Name = defaultName
		end

		for i,slot in LeaderLib.Data.VisibleEquipmentSlots:Get() do
			local entry = Osi.DB_LLEQSET_SetManager_SavedSetEquipment:Get(character, id, slot, nil)
			if entry ~= nil and #entry > 0 then
				hasEquipmentData = true
				local item = entry[1][4]
				local itemName = Ext.GetItem(item).DisplayName
				-- local handle,ref = ItemTemplateGetDisplayString(item)
				-- local itemName = NRD_ItemGetStatsId(item)
				-- if handle ~= nil then
				-- 	itemName = Ext.GetTranslatedString(handle, ref)
				-- end
				table.insert(equipmentSetData[skill].Data, {Slot=slot, Name = itemName})
			end
		end
	end
	--DB_LLEQSET_SetManager_SavedSetEquipment(_Player, _SetID, _Slot, _Item)
	-- local savedSets = Osi.DB_LLEQSET_SetManager_SavedSetEquipment:Get(character, nil, nil, nil)
	-- for i,entry in pairs(savedSets) do
	-- 	local id = entry[2]
	-- 	local slot = entry[3]
	-- 	local item = entry[4]
	-- 	local handle,ref = ItemTemplateGetDisplayString(item)
	-- 	local itemName = NRD_ItemGetStatsId(item)
	-- 	if handle ~= nil then
	-- 		itemName = Ext.GetTranslatedString(handle, ref)
	-- 	end
	-- 	table.insert(equipmentSetData[SetToSkill[id]].Data, {Slot=slot, Name = itemName})
	-- 	hasEquipmentData = true
	-- end

	if hasEquipmentData then
		local uuid = GetUUID(character)
		Ext.PostMessageToClient(uuid, "LLEQSET_SyncEquipmentSets", MessageData:CreateFromTable("EquipmentSetsData", {
			UUID = uuid,
			Data = equipmentSetData
		}):ToString())
	else
		print("No EQ data for", character)
	end
end

Ext.RegisterConsoleCommand("luareset", function(command)
	LeaderLib.StartOneshotTimer("Timers_LLEQSET_ReSyncData", 500, function()
		for i,entry in pairs(Osi.DB_IsPlayer:Get(nil)) do
			SyncEquipmentData(entry[1])
		end
	end)
end)

Ext.RegisterConsoleCommand("eqset_sync", function(command)
	for i,entry in pairs(Osi.DB_IsPlayer:Get(nil)) do
		SyncEquipmentData(entry[1])
	end
end)