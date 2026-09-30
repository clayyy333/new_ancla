-- Puente HTTP del panel privado. La clave se usa solo para iniciar sesion.
return function(context)
	setfenv(1,context)
	local Config=BackendAnchorConfig or {}
	local Bridge={Token=nil,ExpiresAt=0,Generation=0}
	local requestFn

	local function resolveRequest()
		local environment=_genv and _genv() or {}
		local candidates={
			environment.request,
			environment.http_request,
			environment.httprequest,
			environment.syn and environment.syn.request,
			environment.http and environment.http.request,
		}
		for _,candidate in ipairs(candidates) do
			if type(candidate)=="function" then return candidate end
		end
		return nil
	end

	local function decode(body)
		if type(body)~="string" or body=="" then return {} end
		local ok,value=pcall(function() return HttpService:JSONDecode(body) end)
		return ok and type(value)=="table" and value or nil
	end

	local function call(method,path,body,token)
		requestFn=requestFn or resolveRequest()
		if not requestFn then return nil,"request_unavailable" end
		local headers={
			["Accept"]="application/json",
			["Content-Type"]="application/json",
		}
		if token then headers.Authorization="Bearer "..token end
		local options={
			Url=tostring(Config.BaseUrl or "")..path,
			Method=method,
			Headers=headers,
			Timeout=8,
		}
		if body~=nil then options.Body=HttpService:JSONEncode(body) end
		local ok,response=pcall(requestFn,options)
		if not ok or type(response)~="table" then return nil,"request_failed" end
		local status=tonumber(response.StatusCode or response.Status or response.status_code) or 0
		local value=decode(response.Body or response.body or "")
		if status<200 or status>=300 then
			return nil,(value and value.detail) or ("http_"..tostring(status)),status
		end
		return value or {},nil,status
	end

	local function messageFor(errorCode)
		if errorCode=="request_unavailable" then
			return isES and "Este entorno no permite solicitudes HTTP." or "This environment does not allow HTTP requests."
		end
		if errorCode=="request_failed" then
			return isES and "No se pudo contactar con Render." or "Could not contact Render."
		end
		if errorCode=="Invalid owner credentials" then
			return isES and "Usuario o clave privada incorrectos." or "Incorrect user or private key."
		end
		return isES and "No se pudo validar el acceso." or "Access could not be validated."
	end

	function Bridge:Login(key,callback)
		callback=type(callback)=="function" and callback or function() end
		if game.GameId~=Config.GameId or game.PlaceId~=Config.PlaceId then
			callback(false,isES and "El panel solo esta disponible en Metro Life." or "The panel is only available in Metro Life.")
			return
		end
		if type(key)~="string" or key=="" then
			callback(false,isES and "Introduce la clave privada." or "Enter the private key.")
			return
		end
		self.Generation+=1
		local generation=self.Generation
		task.spawn(function()
			local response,err=call("POST","/api/v1/owner/login",{
				user_id=player.UserId,
				username=player.Name,
				key=key,
			})
			key=nil
			if generation~=Bridge.Generation then return end
			if not response or type(response.token)~="string" then
				callback(false,messageFor(err))
				return
			end
			Bridge.Token=response.token
			Bridge.ExpiresAt=tonumber(response.expires_at) or 0
			callback(true,isES and "Acceso validado." or "Access validated.")
		end)
	end

	function Bridge:LoadPlayers(scope,callback)
		callback=type(callback)=="function" and callback or function() end
		if not self.Token then
			callback({},isES and "Inicia sesion nuevamente." or "Sign in again.")
			return
		end
		local selected=scope=="game" and "game" or "server"
		local path="/api/v1/owner/players?scope="..selected.."&job_id="..HttpService:UrlEncode(game.JobId)
		local token=self.Token
		task.spawn(function()
			local response,err,status=call("GET",path,nil,token)
			if status==401 then
				Bridge.Token=nil
				Bridge.ExpiresAt=0
			end
			if not response or type(response.players)~="table" then
				callback({},messageFor(err))
				return
			end
			callback(response.players,nil)
		end)
	end

	function Bridge:Destroy()
		self.Generation+=1
		local token=self.Token
		self.Token=nil
		self.ExpiresAt=0
		if token then
			task.spawn(function() call("POST","/api/v1/owner/logout",nil,token) end)
		end
	end

	AdminPanelBridge=Bridge
	return true
end
