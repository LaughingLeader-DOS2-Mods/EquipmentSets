Ext.Require("Shared.lua")

local ts = Classes.TranslatedString

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

local levelText = ts:Create("h7286f6b9gecadg429aga866gddc4297ee876", "Level")

---@param characterGUID Guid
function SyncEquipmentData(characterGUID)
	local character = GameHelpers.GetCharacter(characterGUID, "EsvCharacter")
	local equipmentSetData = {
		Shout_LLEQSET_EquipmentSet1 = {Name="", Data={}},
		Shout_LLEQSET_EquipmentSet2 = {Name="", Data={}},
		Shout_LLEQSET_EquipmentSet3 = {Name="", Data={}},
		Shout_LLEQSET_EquipmentSet4 = {Name="", Data={}},
		Shout_LLEQSET_EquipmentSet5 = {Name="", Data={}},
	}

	local preserveEmpty = Osi.ObjectGetFlag(characterGUID, "LLEQSET_Settings_SaveEmptySlots") == 1

	local hasEquipmentData = false
	--DB_LLEQSET_SetManager_SetConfig(_SetID, _Skill, _ItemTemplate, _BackpackTemplate)

	--DB_LLEQSET_SetManager_SetNames(_Player, _SetID, _Name)
	--DB_LLEQSET_SetManager_DefaultSetNames(_SetID, _DefaultName)

	for id,skill in pairs(SetToSkill) do
		local setData = equipmentSetData[skill]
		local setName = Osi.DB_LLEQSET_SetManager_SetNames:Get(characterGUID, id, nil)
		if setName ~= nil and #setName > 0 then
			setData.Name = setName[1][3]
		else
			local defaultName = Osi.DB_LLEQSET_SetManager_DefaultSetNames:Get(id, nil)[1][2]
			setData.Name = defaultName
		end

		for i,slot in Data.VisibleEquipmentSlots:Get() do
			local entry = Osi.DB_LLEQSET_SetManager_SavedSetEquipment:Get(characterGUID, id, slot, nil)
			if entry ~= nil and #entry > 0 then
				hasEquipmentData = true
				local itemGuid = entry[1][4]
				if StringHelpers.IsNullOrEmpty(itemGuid) then
					if preserveEmpty then
						setData.Data[slot] = {IsEmpty=true}
					end
				else
					local item = GameHelpers.GetItem(itemGuid, "EsvItem")
					if item then
						local name = GameHelpers.GetDisplayName(item)
						local rarityColor = Data.Colors.Rarity[item.Stats.ItemTypeReal]
						if rarityColor then
							name = ("<font color='%s'>%s</font>"):format(rarityColor, name)
						end
						setData.Data[slot] = {
							Name=name,
							Level = string.format("<font color='#00FFAF' size='16'>%s %i</font>", levelText.Value, item.Stats.Level)
						}
					end
				end
			end
		end
	end

	if hasEquipmentData then
		GameHelpers.Net.PostToUser(character, "LLEQSET_SyncEquipmentSets", {
			NetID = character.NetID,
			Data = equipmentSetData
		})
	end
end

Events.LuaReset:Subscribe(function (e)
	for player in GameHelpers.Character.GetPlayers() do
		Osi.LeaderLib_Timers_StartObjectTimer(player.MyGuid, 1000, "Timers_LLEQSET_SyncEquipmentData", "LLEQSET_SyncEquipmentData")
	end
end)

Ext.RegisterConsoleCommand("eqset_sync", function(command)
	for i,entry in pairs(Osi.DB_IsPlayer:Get(nil)) do
		SyncEquipmentData(entry[1])
	end
end)