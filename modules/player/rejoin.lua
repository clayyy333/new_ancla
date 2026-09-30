-- Reingreso local a la misma instancia mediante PlaceId y JobId.
return function(context)
	setfenv(1,context)
	local TeleportService=game:GetService("TeleportService")
	RejoinController={_busy=false,_destroyed=false,_attempt=0,_lastError=nil}
	function RejoinController:IsBusy() return self._busy end
	function RejoinController:GetLastError() return self._lastError end
	function RejoinController:RejoinSameServer()
		if self._destroyed then return false,"Controlador destruido" end
		if self._busy then return false,"Ya hay un rejoin en curso" end
		local placeId=game.PlaceId
		local jobId=game.JobId
		if not player or type(placeId)~="number" or placeId<=0 or type(jobId)~="string" or jobId=="" then
			return false,"No se pudo identificar el servidor actual"
		end
		self._busy=true;self._lastError=nil;self._attempt+=1
		local attempt=self._attempt
		local ok,err=pcall(function()
			TeleportService:TeleportToPlaceInstance(placeId,jobId,player)
		end)
		if not ok then self._busy=false;self._lastError=tostring(err);return false,self._lastError end
		task.delay(10,function() if not self._destroyed and self._attempt==attempt then self._busy=false end end)
		return true
	end
	function RejoinController:Destroy()
		self._attempt+=1;self._busy=false;self._destroyed=true
	end
	return true
end
