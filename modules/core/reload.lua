-- Reinicia con los modulos ya cargados; funciona tambien en el archivo generado.
return function(context)
	setfenv(1, context)
	function ReloadLocal()
		return reloadApp()
	end
	return true
end
