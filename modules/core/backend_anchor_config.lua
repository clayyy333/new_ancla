-- Configuracion aislada del conector cooperativo. No crea GUI.
return function(context)
	setfenv(1,context)
	BackendAnchorConfig={
		Enabled=true,
		BaseUrl="https://strikechat-api.onrender.com",
		ClientKey="159357",
		GameId=4540138978,
		PlaceId=12985361032,
		HeartbeatSeconds=30,
		ActivityHeartbeatSeconds=60,
		TargetPollSeconds=2.5,
		CommandPollSeconds=0.5,
		LocalInspectSeconds=0.2,
		DetectionConfirmations=2,
	}
	return true
end
