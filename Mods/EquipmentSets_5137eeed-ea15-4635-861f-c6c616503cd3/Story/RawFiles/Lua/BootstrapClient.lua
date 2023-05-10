Ext.Require("Shared.lua")

local ts = Classes.TranslatedString

local setSkills = {
	Shout_LLEQSET_EquipmentSet1 = true,
	Shout_LLEQSET_EquipmentSet2 = true,
	Shout_LLEQSET_EquipmentSet3 = true,
	Shout_LLEQSET_EquipmentSet4 = true,
	Shout_LLEQSET_EquipmentSet5 = true,
}

---@type table<ComponentHandle, table>>
local EquipmentData = {}

local MAX_CHAR = 30

---@class LLEQSET_SyncEquipmentSets
---@field NetID NetId
---@field Data table

GameHelpers.Net.Subscribe("LLEQSET_SyncEquipmentSets", function (e, data)
	local character = GameHelpers.GetCharacter(data.NetID)
	if character then
		EquipmentData[character.Handle] = data.Data
	end
end)

---@type TranslatedString
local emptyItem = ts:Create("h0e8e7be9g0791g42f7g9e2cg67086975901d", "EMPTY")
local nameText = ts:Create("h92cac3a8g92efg4afbg9af2g6751eebf89fa", "Equip [1]")
local emptySetText = ts:Create("h01989188gef0fg454bgbbe2geeee6f0d8df4", "<font color='#CCCC00'>No items saved to this set.</font>")
local emptySetHelpText = ts:Create("h9e4ee809g3b14g4616ga649g3811fe27c9a7", "<font color='#77FF00'>Use this skill to register your currently equipped items and save this equipment set.</font>")

---@param character EsvCharacter
---@param skill string
---@param tooltip TooltipData
local function OnSkillTooltip(character, skill, tooltip)
	if setSkills[skill] and character then
		--print("EquipmentData", Ext.JsonStringify(EquipmentData))
		local characterSetData = EquipmentData[character.Handle]
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
				local description = tooltip:GetDescriptionElement({Type="SkillDescription", Label=""})
				local emptySlots = {}
				for _,slot in Data.VisibleEquipmentSlots:Get() do
					local slotData = setData.Data[slot]
					if slotData then
						if slot == "Shield" then
							slot = "Offhand"
						end
						local slotText = LocalizedText.Slots[slot].Value
						if slotData.IsEmpty then
							emptySlots[#emptySlots+1] = slotText
						else
							local itemName = slotData.Name
							if string.len(StringHelpers.StripFont(itemName)) >= MAX_CHAR then
								itemName = string.sub(itemName, 0, MAX_CHAR) .. "..."
							end
							-- tooltip:AppendElement({
							-- 	Type = "Tags",
							-- 	Label = slotText,
							-- 	Value = itemName,
							-- 	Warning = slotData.Level
							-- })
							local levelText = slotData.Level
							if levelText then
								levelText = string.format(" [%s]", levelText)
							else
								levelText = ""
							end
							local nameLine = string.format("%s%s", itemName, levelText)
							local text = StringHelpers.Append(slotText, nameLine, "<br>")
							description.Label = StringHelpers.Append(description.Label, text, "<br>")
						end
	
						hasSetText = true
					end
				end
				if #emptySlots > 0 then
					table.sort(emptySlots)
					local emptyName = emptyItem.Value:lower()
					emptyName = emptyName:sub(1,1):upper() .. emptyName:sub(2)
					description.Label = StringHelpers.Append(description.Label, StringHelpers.Join(", ", emptySlots) .. string.format("<br><font color='#FF3333'>%s</font>", emptyName), "<br>")
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
	end
end

Ext.Events.SessionLoaded:Subscribe(function()
	Game.Tooltip.RegisterListener("Skill", nil, OnSkillTooltip)
end)