dofile "$GAME_DATA/Scripts/game/AnimationUtil.lua"
--dofile "$SURVIVAL_DATA/Scripts/util.lua"

InGameMenu = class()

local renderablesTp = { "$GAME_DATA/Character/Char_Male/Animations/char_male_tp_handbook.rend", "$GAME_DATA/Character/Char_Tools/Char_handbook/char_handbook_tp_animlist.rend" }
local renderablesFp = { "$GAME_DATA/Character/Char_Tools/Char_handbook/char_handbook_fp_animlist.rend" }

local renderables = {
	"$GAME_DATA/Character/Char_Tools/Char_handbook/char_handbook.rend"
}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

local Range = 3.0
local SwingStaminaSpend = 1.5

InGameMenu.swingCount = 2
InGameMenu.mayaFrameDuration = 1.0/30.0
InGameMenu.player_list = {}
InGameMenu.name_list = {}

InGameMenu.swings = { "open" }
InGameMenu.swingFrames = { 4.2 * InGameMenu.mayaFrameDuration, 4.2 * InGameMenu.mayaFrameDuration }
InGameMenu.swingExits = { "close" }

InGameMenu.options_buttons = {
	["falldamageOn"]= false,
	["falldamageOff"] = false,
	["inactivityOn"] = false,
	["inactivityOff"] = false,
	["noitemsOn"] = false,
	["noitemsOff"] = false,
	["spectateOn"] = false,
	["spectateOff"] = false,
	["oneshotOn"] = false,
	["oneshotOff"] = false,
	["halfhealthOn"] = false,
	["halfhealthOff"] = false,
	["fullhealthOn"] = false,
	["fullhealthOff"] = false,
	["hiderscanseeOn"] = false,
	["hiderscanseeOff"] = false,
	["hideallnameOn"] = false,
	["hideallnameOff"] = false,
}

function InGameMenu.client_onCreate( self )
	self.isLocal = self.tool:isLocal()
	self:init()
	self.test_running = false
	self.player = sm.localPlayer.getPlayer()
	sm.event.sendToPlayer(self.player, "client_getMode", self.tool)
end

function InGameMenu.client_onRefresh( self )
	self:init()
	self:loadAnimations()
	sm.event.sendToPlayer(self.player, "client_getMode", self.tool)
end

function InGameMenu.init( self )
	self.attackCooldownTimer = 0.0
	self.pendingRaycastFlag = false
	self.nextAttackFlag = false
	self.currentSwing = 1
    self.ToggleOnOff = false
	self.swingCooldowns = {}
	for i = 1, self.swingCount do
		self.swingCooldowns[i] = 0.0
	end	
	self.swing = false
	self.block = false	
	if self.animationsLoaded == nil then
		self.animationsLoaded = false
	end
    self.WasButtonClickedLocally = false
    self.ToggleOnOff = false
    self.HasBeenRun = false
    self.AnimationEnded = true
    self.IdleHasBeenRun = false
    self.Ready = false
    self.ExitSwing = false
    self.FailToExit = true
    self.closeAnim = false
    self.CanSave = true
end

function InGameMenu.loadAnimations( self )

	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			--equip = { "open_equipt", { nextAnimation = "idle" } },
			equip = { "handbook_pickup", { nextAnimation = "idle" } },
			unequip = { "handbook_putdown" },
			idle = {"handbook_idle", { looping = true } },
		}
	)
	local movementAnimations = {
		
		--equip = "open_equipt",

		idle = "handbook_idle",

		runFwd = "handbook_run_fwd",
		runBwd = "handbook_run_bwd",

		sprint = "handbook_sprint",

		jump = "handbook_jump",
		jumpUp = "handbook_jump_up",
		jumpDown = "handbook_jump_down",

		land = "handbook_jump_land",
		landFwd = "handbook_jump_land_fwd",
		landBwd = "handbook_jump_land_bwd",

		crouchIdle = "handbook_crouch_idle",
		crouchFwd = "handbook_crouch_fwd",
		crouchBwd = "handbook_crouch_bwd"		
	}
    
	for name, animation in pairs( movementAnimations ) do
		self.tool:setMovementAnimation( name, animation )
	end
    
	setTpAnimation( self.tpAnimations, "idle", 5.0 )
    
	if self.isLocal then
		self.fpAnimations = createFpAnimations(
			self.tool,
			{   
				--equip = { "open_equipt", { nextAnimation = "idle" } },
				equip = { "handbook_pickup", { nextAnimation = "idle" } },
				unequip = { "handbook_putdown" },				
				idle = { "handbook_idle",  { looping = true } },
				
				sprintInto = { "handbook_sprint_into", { nextAnimation = "sprintIdle" } },
				sprintIdle = { "handbook_sprint_idle", { looping = true } },
				sprintExit = { "handbook_sprint_exit", { nextAnimation = "idle" } },

				open = { "handbook_use_into" , { nextAnimation = "hold" } },
                hold = { "handbook_use_idle" , { nextAnimation = "close" } },
				close = { "handbook_use_exit" , { nextAnimation = "idle" } },
			}
		)
		setFpAnimation( self.fpAnimations, "idle", 0.0 )
	end

	self.animationsLoaded = true
end

function InGameMenu.client_onFixedUpdate( self, dt )	
	if sm.exists(self.menu) and not self.menu:isActive() and sm.exists(self.blur) and self.blur:isActive() then
		self:client_CloseMenu()
	end
end

function InGameMenu.client_onUpdate( self, dt )
    if sm.exists(self.tool) then
        local isSprinting =  self.tool:isSprinting()
        if self.fpAnimations ~= nil then
            if not isSprinting and not self.ToggleOnOff and self.fpAnimations.currentAnimation == "sprintExit" then
                local params = { name = "idle" }
                self:client_startLocalEvent( params )
            end
        end
        if self.ToggleOnOff and self.AnimationEnded then
            isSprinting = true
            self.closeAnim = true
        elseif self.equipped and self.closeAnim then
            self.closeAnim = false
            isSprinting = false
            local params = { name = "close" }
            self:client_startLocalEvent( params )
        end
        if self.ExitSwing then
            local params = { name = self.swingExits[1] }
            self:client_startLocalEvent( params )
            self.ToggleOnOff = false
            self.ExitSwing = false
        end
        if (self.AnimationEnded and not self.IdleHasBeenRun and self.ToggleOnOff == false) then
            local params = { name = "idle" }
            self:client_startLocalEvent( params )
            self.IdleHasBeenRun = true
        end
        
        if not self.animationsLoaded then
            return
        end
        
        --synchronized update
        self.attackCooldownTimer = math.max( self.attackCooldownTimer - dt, 0.0 )
        --standard third person updateAnimation
        updateTpAnimations( self.tpAnimations, self.equipped, dt )
        

        --update
        if self.isLocal then

            if self.ToggleOnOff and self.AnimationEnded then 
                dt = 0
            end
            
            local preAnimation = self.fpAnimations.currentAnimation

            updateFpAnimations( self.fpAnimations, self.equipped, dt )
            
            if preAnimation ~= self.fpAnimations.currentAnimation then
                self.AnimationEnded = true
                local keepBlockSprint = false
                local endedSwing = preAnimation == self.swings[self.currentSwing] and self.fpAnimations.currentAnimation == self.swingExits[self.currentSwing]
            end

            if isSprinting and self.fpAnimations.currentAnimation == "idle" and self.attackCooldownTimer <= 0 and not isAnyOf( self.fpAnimations.currentAnimation, { "sprintInto", "sprintIdle" } ) then
                local params = { name = "sprintInto" }
                self:client_startLocalEvent( params )
            end
            
            if ( not isSprinting and isAnyOf( self.fpAnimations.currentAnimation, { "sprintInto", "sprintIdle" } ) ) and self.fpAnimations.currentAnimation ~= "sprintExit" then
                local params = { name = "sprintExit" }
                self:client_startLocalEvent( params )
            end
        end
    end
end

function InGameMenu.client_startLocalEvent( self, params3 )
	self:client_handleEvent( params3 )
end

function InGameMenu.client_handleEvent( self, params )
	-- Setup animation data on equip
	if params.name == "equip" then
		self.equipped = true
		self:loadAnimations()
	elseif params.name == "unequip" then
		self.equipped = false
	end

	if not self.animationsLoaded then
		return
	end
	
	-- Third person animations
	local tpAnimation = self.tpAnimations.animations[params.name]
	if tpAnimation then
		local isSwing = false
		for i = 1, self.swingCount do
			if self.swings[i] == params.name then
				self.tpAnimations.animations[self.swings[i]].playRate = 1
				isSwing = true
			end
		end
		
		local blend = not isSwing
		setTpAnimation( self.tpAnimations, params.name, blend and 0.2 or 0.0 )
	end
	
	-- First person animations
	if self.isLocal then
		local isSwing = false
		
		for i = 1, self.swingCount do
			if self.swings[i] == params.name then
				self.fpAnimations.animations[self.swings[i]].playRate = 1
				isSwing = true
			end
		end
	
		local blend = not ( isSwing or isAnyOf( params.name, { "equip", "unequip" } ) )
		setFpAnimation( self.fpAnimations, params.name, blend and 0.2 or 0.0 )
	end	
end

function InGameMenu.client_onEquippedUpdate( self, primaryState, secondaryState, data0, data1, data2 )
	if self.pendingRaycastFlag then
		local time = 0.0
		local frameTime = 0.0
		if self.fpAnimations.currentAnimation == self.swings[self.currentSwing] then
			time = self.fpAnimations.animations[self.swings[self.currentSwing]].time
			frameTime = self.swingFrames[self.currentSwing]
		end
		if time >= frameTime and frameTime ~= 0 then
			self.pendingRaycastFlag = false
		end
	end

	if primaryState == sm.tool.interactState.start  then
		if self.fpAnimations.currentAnimation == self.swings[self.currentSwing] then
			if self.attackCooldownTimer < self.swingCooldowns[self.currentSwing] - 0.25 then
				self.nextAttackFlag = true
			end
		else
			if self.attackCooldownTimer <= 0 then
				self.currentSwing = 1
				local params = { name = "" }
				if (self.ToggleOnOff) then
					params.name = self.swingExits[1]
				else
					params.name = self.swings[1]
				end
				sm.audio.play("Handbook - Turn page", sm.localPlayer.getPlayer():getCharacter():getWorldPosition())
				self:client_startLocalEvent( params )
				self.pendingRaycastFlag = true
				self.nextAttackFlag = false
				self.attackCooldownTimer = self.swingCooldowns[self.currentSwing]
				self.AnimationEnded = false
			end
		end
        self.ToggleOnOff = not self.ToggleOnOff
		self.Ready = true
	end
	if primaryState == 0 and self.Ready == true and self.ToggleOnOff then
        self.Ready = false
		self.WasButtonClickedLocally = true
        self:client_OpenMenu()
	end
    if primaryState == 0 and self.Ready == true and not self.ToggleOnOff then
        self.Ready = false
		self.WasButtonClickedLocally = true
        self:client_CloseMenu()
	end
	return true, false
end

function split_string (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function InGameMenu.client_setMode( self, mode )
	if not States then dofile("$CONTENT_DATA/Scripts/Core/Util.lua") end
	self.test_running = mode == States.PlayBuild
	self.play_running = mode == States.Play
	if sm.exists(self.menu) then
		self.menu:setVisible("ChallengeBuilderPanel", not self.play_running)
		self.menu:setVisible("ChallengePanel", self.play_running)
		self.menu:setVisible("StopTest_CBP", self.test_running)
		self.menu:setVisible("SaveAndTest_CBP", not self.test_running and not self.play_running)
		self.menu:setVisible("Save_CBP", not self.test_running and not self.play_running)
		self.menu:setVisible("Reset_CBP", self.test_running or self.play_running )
    	self.menu:setVisible("Restart_CBP", self.test_running or self.play_running )
	end
end

local PlayerStates = {
	Spectator = 0,
	Hider = 1,
	Seeker = 2,
}

function InGameMenu.server_bounceBackPlayerList( self, callback )
	local client = callback.client
	local func = callback.func
	local players = sm.player.getAllPlayers()
	local i = 0
	if not self.player_list then self.player_list = {} end
	if not self.name_list then self.name_list = {} end
	for _, player in pairs( players ) do
		for _,name in pairs( self.name_list ) do
			if player:getName() == name then
				goto skip
			end
		end
		table.insert( self.name_list, player:getName() )
		table.insert( self.player_list, tonumber(i), { name = player:getName(), state = PlayerStates.Hider } )
		i = i + 1
		::skip::
	end
	self.network:sendToClient(client, func, self.player_list)
end

function InGameMenu.client_updatePlayerStates(self, data)
	if not sm.isHost then return end
	local count = 0
	for _,_ in pairs(data) do count = count + 1 end

	self.menu:setSliderData( "VNameSlider", count, count-1 )

	local llen = count
	while llen < 5 do
		self.menu:setVisible("Name"..tostring(llen), false)
		llen = llen + 1
	end
	--local i = 0
	for i,player in pairs(data) do
		self.menu:setButtonCallback("Name"..tostring(i), "client_togglePlayerState")
		self.menu:setVisible("Name"..tostring(i), true)
		local color = ""
		if player.state == PlayerStates.Spectator then
			color = "#808080 Spectator: "
		elseif player.state == PlayerStates.Hider then
			color = "#00FF00 Hider: "
		elseif player.state == PlayerStates.Seeker then
			color = "#FF0000 Seeker: "
		end
		self.menu:setText("Name"..tostring(i), color..player.name)
		--i = i + 1
	end
end

function InGameMenu.client_OpenMenu( self )
	if not sm.isHost then return end
	sm.event.sendToPlayer(self.player, "client_getMode", self.tool)

    self.menu = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/InGameMenu.layout")
    self.menu:setVisible("ChallengeBuilderPanel", true)
    self.menu:setVisible("StopTest_CBP", self.test_running)
	self.menu:setVisible("Save_CBP", not self.test_running)
	self.menu:setVisible("SaveAndTest_CBP", not self.test_running)
    --self.menu:setOnCloseCallback( "client_CloseMenu" )
    self.menu:setButtonCallback( "Resume_CBP", "client_CloseMenu" )
    self.menu:setButtonCallback( "Reset_CBP", "client_sendEvent" )
    self.menu:setButtonCallback( "Restart_CBP", "client_sendEvent" )
    self.menu:setButtonCallback( "Save_CBP", "client_sendEvent" )
    self.menu:setButtonCallback( "SaveAndTest_CBP", "client_sendEvent" )
    self.menu:setButtonCallback( "StopTest_CBP", "client_sendEvent" )
	self.menu:setButtonCallback( "Exit_CBP", "client_exitToMenu" )
	self.menu:setButtonCallback( "Options_CP", "client_openHideAndSeekOptions" )

	self.option_scroll_pos = 0
	self.menu:createVerticalSlider( "VNameSlider", 1, 1, "client_scrollAction" )

	for button_name,_ in pairs(self.options_buttons) do
		self.menu:setButtonCallback( button_name, "client_toggleOptions" )
	end
	
	self.network:sendToServer("server_requestOptionsFomeGame")
	self.network:sendToServer("server_bounceBackPlayerList", {func="client_updatePlayerStates", client=self.player})

	self.menu:setButtonCallback( "Resume_CP", "client_CloseMenu" )
    self.menu:setButtonCallback( "Reset_CP", "client_sendEvent" )
    self.menu:setButtonCallback( "Restart_CP", "client_sendEvent" )
	self.menu:setButtonCallback( "Exit_CP", "client_exitToMenu" )
	
    self.blur = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/ingame_darken.layout", true, {
        isHud = true,
        isInteractive = false,
        needsCursor = false,
        hidesHotbar = false,
        isOverlapped = true,
        backgroundAlpha = 0.3,
    })
    self.blur:setImage("BackgroundImage", "$CONTENT_DATA/Gui/t_mapinspectorscreen_gradient.png")
    self.menu:open()
	self.blur:open()
end

function InGameMenu.server_requestOptionsFomeGame( self )
	sm.event.sendToGame("server_getHideAndSeekOptions", self.tool)
end

function InGameMenu.server_recieveOptionsFromGame( self, data )
	if data then
		self.options_buttons = data.options
		self.player_list = data.players
		self.network:sendToClients("client_setButtonStates", self.options_buttons)
		self.network:sendToClients("client_updatePlayerStates", self.player_list)	
	end
end

function InGameMenu.client_toggleOptions(self, button)
	if not sm.isHost then return end
	local rname = ""
	local nstate = false
	if button:sub(-2) == "On" then
		rname = button:sub(1, -3)
		nstate = true
		self.menu:setVisible(button, false)
		self.menu:setVisible(button:sub(1, -3).."OffActive", false)
		self.menu:setVisible(button:sub(1, -3).."Off", true)
		self.menu:setVisible(button.."Active", true)
	else
		rname = button:sub(1, -4)
		self.menu:setVisible(button, false)
		self.menu:setVisible(button:sub(1, -4).."OnActive", false)
		self.menu:setVisible(button:sub(1, -4).."On", true)
		self.menu:setVisible(button.."Active", true)
	end
	self.options_buttons[rname] = nstate

	self.network:sendToServer("server_setButtonStates", self.options_buttons)
end

function InGameMenu.client_setButtonStates( self, data )
	if not sm.isHost then return end
	if data then
		self.options_buttons = data
	end
	for button_name,state in pairs(self.options_buttons) do
		if state then
			self.menu:setVisible( button_name.."OnActive", true )
			self.menu:setVisible( button_name.."Off", true )
			self.menu:setVisible( button_name.."On", false )
			self.menu:setVisible( button_name.."OffActive", false )
		else
			self.menu:setVisible( button_name.."OnActive", false )
			self.menu:setVisible( button_name.."Off", false )
			self.menu:setVisible( button_name.."On", true )
			self.menu:setVisible( button_name.."OffActive", true )
		end
	end
	self.network:sendToServer("server_setButtonStates", self.options_buttons)
end

function InGameMenu.server_setButtonStates( self, data )
	self.options_buttons = data
	sm.event.sendToGame("server_setHideAndSeekOptions", {players=self.player_list, options=self.options_buttons})
end

function InGameMenu.client_togglePlayerState( self, button )
	if not sm.isHost then return end
	local index = tonumber(button:sub(5))
	self.network:sendToServer("server_togglePlayerState", index)
end

function InGameMenu.server_togglePlayerState(self, index)
	local player = self.player_list[index]
	if player.state < 2 then
		player.state = player.state + 1
	else
		player.state = 0
	end
	self:server_setButtonStates(self.options_buttons)
	self.network:sendToClients("client_updatePlayerStates", self.player_list)
end

function InGameMenu.client_openHideAndSeekOptions( self, button )
	if not sm.isHost then return end
	self.menu:setVisible("ChallengePanel", false)
	self.menu:setVisible("BackPanel", true)
end

function InGameMenu.client_exitToMenu( self, button )
	if not sm.isHost then return end
	self:client_CloseMenu()
	sm.event.sendToGame("client_exitToMenu")
end

function InGameMenu.client_sendEvent( self, button )
	if not sm.isHost then return end
    self.network:sendToServer("server_sendEvent", button)
	self:client_CloseMenu()
end

function InGameMenu.server_sendEvent( self, button )
    local target = split_string(button, "_")[1]
    if target == "Save" then target = "SaveLevel" end
    if target == "SaveAndTest" then
        sm.event.sendToGame("_server_onSaveLevel")
        sm.event.sendToGame("_server_onTestLevel")
        return
    end
    sm.event.sendToGame("_server_on"..target)
end

function InGameMenu.client_CloseMenu( self )
	if not sm.isHost then return end
    if sm.exists(self.menu) then
        self.menu:close()
        self.menu:destroy()
	end
	if sm.exists(self.blur) then
        self.blur:close()
        self.blur:destroy()
	end
	self.ToggleOnOff = false
	self.currentSwing = 1
	local params = { name = self.swingExits[1] }
	sm.audio.play("Handbook - Turn page", sm.localPlayer.getPlayer():getCharacter():getWorldPosition())
	self:client_startLocalEvent( params )
	self.pendingRaycastFlag = true
	self.nextAttackFlag = false
	self.attackCooldownTimer = self.swingCooldowns[self.currentSwing]
	self.AnimationEnded = false
end

function InGameMenu.client_onEquip( self )
	if not sm.isHost then return end
	if sm.exists(self.tool) then
		self.equipped = true
		for k,v in pairs( renderables ) do renderablesTp[#renderablesTp+1] = v end
		for k,v in pairs( renderables ) do renderablesFp[#renderablesFp+1] = v end
		
		self.tool:setTpRenderables( renderablesTp )

		self:init()
		self:loadAnimations()

		setTpAnimation( self.tpAnimations, "equip", 0.0001 )

		if self.isLocal then
			self.tool:setFpRenderables( renderablesFp )
			swapFpAnimation( self.fpAnimations, "unequip", "equip", 0.2 )
		end
	end
end

function InGameMenu.client_onUnequip( self )
	if not sm.isHost then return end
	if sm.exists(self.tool) then
		self.SwitchDurration = 0
		self.equipped = false
		pcall(function()
			setTpAnimation( self.tpAnimations, "unequip" )
			if self.isLocal and self.fpAnimations.currentAnimation ~= "unequip" then
				swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
			end
		end)
	end
end

function InGameMenu.client_onDestroy( self )
	if sm.exists(self.blur) then
        self.blur:close()
        self.blur:destroy()
	end
	if sm.exists(self.menu) then
		self.menu:close()
        self.menu:destroy()
	end
end