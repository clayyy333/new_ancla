return function(context)
	setfenv(1, context)

	local coordinator = {
		Owner = nil,
	}

	function coordinator:Claim(owner)
		if owner == "car1" then
			CarFling2Delta:SetPlayer(nil)
			CarFling2Xeno:SetPlayer(nil)
			if UpdateCarFling2Panel then UpdateCarFling2Panel() end
		elseif owner == "car2" then
			CarFling:SetPlayer(nil)
			CarFlingXeno:SetPlayer(nil)
			if UpdateCarFlingPanel then UpdateCarFlingPanel() end
		else
			return false
		end

		self.Owner = owner
		return true
	end

	function coordinator:Release(owner)
		if self.Owner == owner then
			self.Owner = nil
		end
	end

	CarFlingAutoCoordinator = coordinator
	return true
end