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

local MAX_CHAR = 30

Ext.RegisterNetListener("LLEQSET_SyncEquipmentSets", function(channel, payload, ...)
	--print("LLEQSET_SyncEquipmentSets", channel, payload, Ext.JsonStringify({...}))
	local messageData = Classes.MessageData:CreateFromString(payload)
	if messageData.Params ~= nil and messageData.Params.UUID ~= nil then
		EquipmentData[messageData.Params.UUID] = messageData.Params.Data
	end
end)

---@type TranslatedString
local nameText = LeaderLib.Classes.TranslatedString:Create("h92cac3a8g92efg4afbg9af2g6751eebf89fa", "Equip [1]")
local emptySetText = LeaderLib.Classes.TranslatedString:Create("h01989188gef0fg454bgbbe2geeee6f0d8df4", "<font color='#CCCC00'>No items saved to this set.</font>")
local emptySetHelpText = LeaderLib.Classes.TranslatedString:Create("h9e4ee809g3b14g4616ga649g3811fe27c9a7", "<font color='#77FF00'>Use this skill to register your currently equipped items and save this equipment set.</font>")

---@param character EsvCharacter
---@param skill string
---@param tooltip TooltipData
local function OnSkillTooltip(character, skill, tooltip)
	if setSkills[skill] then
		--print("EquipmentData", Ext.JsonStringify(EquipmentData))
		local characterSetData = EquipmentData[character.MyGuid]
		local hasSetText = false
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
					if slotData.Slot == "Shield" then
						slotData.Slot = "Offhand"
					end
					local slotText = LeaderLib.LocalizedText.Slots[slotData.Slot].Value
					local itemName = slotData.Name
					local ref,handle = Ext.GetTranslatedStringFromKey(slotData.Name)
					
					if handle ~= nil then
						itemName = Ext.GetTranslatedString(handle, ref)
					end
					if string.len(itemName) >= MAX_CHAR then
						itemName = string.sub(itemName, 0, MAX_CHAR) .. "..."
					end
					local element = {
						Type = "Tags",
						Label = slotText,
						Value = itemName,
						Warning = slotData.Level
					}
					tooltip:AppendElement(element)
					hasSetText = true
				end
			end
		end

		if not hasSetText then
			local element = tooltip:GetElement("SkillDescription")
			if element ~= nil then
				local nextText = element.Label
				element.Label = nextText.."<br>"..emptySetText.Value.."<br>"..emptySetHelpText.Value
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