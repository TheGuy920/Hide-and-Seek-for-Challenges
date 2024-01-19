MenuLock = class()

function MenuLock.server_onCreate( self )
	
end

function MenuLock.server_onFixedUpdate( self, timeStep )
	
end

function MenuLock.client_onCreate( self )
	
end

function MenuLock.client_onClientDataUpdate( self, clientData )
	
end

function MenuLock.client_onAction( self, action, state )
    if action ~= 17 then
        sm.event.sendToGame("client_onActionReopen")
    end
    return true, true
end