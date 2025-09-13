local F = table.remove(RequiredScript:split("/"))
local Hooks = Hooks

if F == "gamesetup" then
	Hooks:PreHook(GameSetup, "paused_update", "GameSetupPausedUpdateBase", function(self, t, dt)
        Hooks:Call("GameSetupPrePausedUpdate", t, dt)
	end)
	Hooks:PostHook(GameSetup, "paused_update", "GameSetupPausedUpdateBase", function(self, t, dt)
        Hooks:Call("GameSetupPauseUpdate", t, dt)
	end)
elseif F == "setup" then
	Hooks:PreHook(Setup, "update", "BeardLibSetupPreUpdate", function(self, t, dt)
        Hooks:Call("SetupPreUpdate", t, dt)
	end)

	Hooks:PostHook(Setup, "init_managers", "BeardLibAddMissingDLCPackages", function(self)
		if managers.dlc.give_missing_package then
			managers.dlc:give_missing_package()
		end
		Hooks:Call("SetupInitManagers", self)
	end)

	Hooks:PostHook(Setup, "init_finalize", "BeardLibInitFinalize", function(self)
		BeardLib.Managers.Sound:Open()
		Hooks:Call("BeardLibSetupInitFinalize", self)
	end)

	Hooks:PostHook(Setup, "unload_packages", "BeardLibUnloadPackages", function(self)
		BeardLib.Managers.Sound:Close()
		BeardLib.Managers.Package:Unload()
		Hooks:Call("BeardLibSetupUnloadPackages", self)
	end)
elseif F == "localizationmanager" then
	-- Don't you love when you crash just for asking if this shit exist?
	function LocalizationManager:modded_exists(str)
		return self._custom_localizations[str] ~= nil
	end
elseif F == "networkpeer" then
	local NetworkPeerSend = NetworkPeer.send

	function NetworkPeer:send(func_name, ...)
		if not self._ip_verified then
			return
		end
		local params = table.pack(...)
		Hooks:Call("NetworkPeerSend", self, func_name, params)
		NetworkPeerSend(self, func_name, unpack(params, 1, params.n))
	end
elseif F == "tweakdata" then
	TweakDataHelper:Apply()
elseif F == "networktweakdata" then
	if BeardLib:GetGame() ~= "pd2" then
		for _, framework in pairs(BeardLib.Frameworks) do framework:RegisterHooks() end
	end
	--Makes sure that rect can be returned as a null if it's a custom icon
	local get_icon = HudIconsTweakData.get_icon_data
	function HudIconsTweakData:get_icon_data(id, rect, ...)
		local icon, texture_rect = get_icon(self, id, rect, ...)
		local data = self[id]
		if not rect and data and data.custom and not data.texture_rect then
			texture_rect = nil
		end
		return icon, texture_rect
	end
elseif F == "blackmarketgui" then
	local item = BlackMarketGuiSlotItem.init
	function BlackMarketGuiSlotItem:init(main_panel, data, ...)
		item(self, main_panel, data, ...)

		if data.bitmap_texture and not DB:has(Idstring("texture"), data.bitmap_texture) then
			local texture_loaded_clbk = callback(self, self, "texture_loaded_clbk")
			self._loading_texture = true
			if data.stream then
				self._requested_texture = data.bitmap_texture
				self._request_index = managers.menu_component:request_texture(self._requested_texture, callback(self, self, "texture_loaded_clbk"))
			else
				texture_loaded_clbk(data.bitmap_texture, Idstring(data.bitmap_texture))
			end
		end
	end
end
