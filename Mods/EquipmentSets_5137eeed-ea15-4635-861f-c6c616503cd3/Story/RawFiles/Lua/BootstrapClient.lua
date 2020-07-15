local LeaderLib = Mods.LeaderLib
local Classes = LeaderLib.Classes

local setSkills = {
	Shout_LLEQSET_EquipmentSet1 = true,
	Shout_LLEQSET_EquipmentSet2 = true,
	Shout_LLEQSET_EquipmentSet3 = true,
	Shout_LLEQSET_EquipmentSet4 = true,
	Shout_LLEQSET_EquipmentSet5 = true,
}

local EquipmentData = {}

Ext.RegisterNetListener("LLEQSET_SyncEquipmentSets", function(channel, payload, ...)
	print("LLEQSET_SyncEquipmentSets", channel, payload, Ext.JsonStringify({...}))
	local messageData = Classes.MessageData:CreateFromString(payload)
	if messageData.Params ~= nil and messageData.Params.UUID ~= nil then
		EquipmentData[messageData.Params.UUID] = messageData.Params.Data
	end
end)

---@type TranslatedString
local nameText = LeaderLib.Classes.TranslatedString:Create("h92cac3a8g92efg4afbg9af2g6751eebf89fa", "Equip [1]")

---@param character EsvCharacter
---@param skill string
---@param tooltip TooltipData
local function OnSkillTooltip(character, skill, tooltip)
	if setSkills[skill] then
		--print("EquipmentData", Ext.JsonStringify(EquipmentData))
		local characterSetData = EquipmentData[character.MyGuid]
		if characterSetData ~= nil then
			local setData = characterSetData[skill]
			if setData ~= nil then
				local name = setData.Name
				if name ~= "" and name ~= nil then
					local element = tooltip:GetElement("SkillName")
					if element ~= nil then
						element.Label = nameText:ReplacePlaceholders(name)
					else
						tooltip:AppendElement({
							Type = "SkillName",
							Label = nameText:ReplacePlaceholders(name)
						})
					end
				end
				for i,slotData in pairs(setData.Data) do
					print(slotData.Slot)
					local slotText = LeaderLib.LocalizedText.Slots[slotData.Slot].Value
					local element = {
						Type = "Tags",
						Label = slotText,
						Value = slotData.Name
					}
					tooltip:AppendElement(element)
				end
			end
		end
		-- element = tooltip:GetElement("SkillDescription")
		-- if element ~= nil then
		-- 	local nextText = element.Label
		-- 	element.Label = nextText
		-- end
	end
end

Ext.RegisterListener("SessionLoaded", function()
	Game.Tooltip.RegisterListener("Skill", nil, OnSkillTooltip)
	--Game.Tooltip.RegisterListener("Status", nil, OnStatusTooltip)
	--Game.Tooltip.RegisterListener("Item", nil, OnItemTooltip)
end)