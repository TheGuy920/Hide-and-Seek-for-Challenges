
dofile( "$GAME_DATA/Scripts/game/AnimationUtil.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_meleeattacks.lua" )

---@class Sledgehammer : ToolClass
---@field animationsLoaded boolean
---@field tpAnimations table
Sledgehammer = class()

local renderables = {
	"$GAME_DATA/Character/Char_Tools/Char_sledgehammer/char_sledgehammer_mainmenu.rend"
}

local renderablesTp = {"$GAME_DATA/Character/Char_Male/Animations/char_male_tp_sledgehammer_mainmenu.rend"}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )

function Sledgehammer.client_onCreate( self )
	self:init()
	self.tool:setCrossHairAlpha( 0 )
end

function Sledgehammer.client_onRefresh( self )
	self:init()
	self:loadAnimations()
end

function Sledgehammer.init( self )		
	if self.animationsLoaded == nil then
		self.animationsLoaded = false
	end
end

function Sledgehammer.loadAnimations( self )

	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			menu = {"sledgehammer_menu_idle", { looping = true } }	
		}
	)
	local movementAnimations = {
		menu = "sledgehammer_menu_idle"		
	}

	for name, animation in pairs( movementAnimations ) do
		self.tool:setMovementAnimation( name, animation )
	end

	setTpAnimation( self.tpAnimations, "menu", 5.0 )
	
	self.animationsLoaded = true

end

function Sledgehammer.client_onUpdate( self, dt )
	if sm.exists(self.tool) then
		if not self.animationsLoaded then
			return
		end
		--standard third person updateAnimation
		updateTpAnimations( self.tpAnimations, true, dt )
	end
end

function Sledgehammer.client_onEquippedUpdate( self, primaryState, secondaryState )
	return true, false
end

function Sledgehammer.client_onEquip( self, animate )

	if animate then
		sm.audio.play( "Sledgehammer - Equip", self.tool:getPosition() )
	end

	for k,v in pairs( renderables ) do renderablesTp[#renderablesTp+1] = v end
	
	self.tool:setTpRenderables( renderablesTp )

	self:init()
	self:loadAnimations()

	setTpAnimation( self.tpAnimations, "menu", 0.0001 )
end

function Sledgehammer.client_onUnequip( self, animate )
	if sm.exists( self.tool ) then
		setTpAnimation( self.tpAnimations, "menu" )
	end
end
