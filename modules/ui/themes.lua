-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

Themes = {

	Dark = {
		primary     = Color3.fromRGB(0,  0,  0 ),
		sidebar     = Color3.fromRGB(0,  0,  0 ),
		secondary   = Color3.fromRGB(0,  0,  0 ),
		tertiary    = Color3.fromRGB(22, 22, 22),
		accent      = Color3.fromRGB(200, 200, 200),
		text        = Color3.fromRGB(255, 255, 255),
		textDim     = Color3.fromRGB(140, 140, 140),
		stroke      = Color3.fromRGB(22, 22, 22),
		strokeHover = Color3.fromRGB(65, 65, 65),
		critical    = Color3.fromRGB(196, 30, 30),
		success     = Color3.fromRGB(80, 200, 100)
	},
	Purple = {
		primary     = Color3.fromRGB(10, 6, 18),
		sidebar     = Color3.fromRGB(14, 9, 24),
		secondary   = Color3.fromRGB(20, 13, 34),
		tertiary    = Color3.fromRGB(28, 18, 48),
		accent      = Color3.fromRGB(138, 43, 226),
		text        = Color3.fromRGB(255, 255, 255),
		textDim     = Color3.fromRGB(180, 155, 220),
		stroke      = Color3.fromRGB(55, 22, 90),
		strokeHover = Color3.fromRGB(110, 45, 190),
		critical    = Color3.fromRGB(255, 60, 100),
		success     = Color3.fromRGB(100, 240, 120)
	},
	Blue = {
		primary     = Color3.fromRGB(8, 11, 20),
		sidebar     = Color3.fromRGB(11, 15, 27),
		secondary   = Color3.fromRGB(16, 21, 36),
		tertiary    = Color3.fromRGB(22, 30, 50),
		accent      = Color3.fromRGB(0, 160, 255),
		text        = Color3.fromRGB(255, 255, 255),
		textDim     = Color3.fromRGB(150, 180, 220),
		stroke      = Color3.fromRGB(28, 55, 110),
		strokeHover = Color3.fromRGB(60, 130, 220),
		critical    = Color3.fromRGB(250, 60, 80),
		success     = Color3.fromRGB(60, 230, 140)
	},
	Green = {
		primary     = Color3.fromRGB(8, 14, 10),
		sidebar     = Color3.fromRGB(11, 18, 13),
		secondary   = Color3.fromRGB(14, 24, 17),
		tertiary    = Color3.fromRGB(20, 34, 24),
		accent      = Color3.fromRGB(0, 220, 110),
		text        = Color3.fromRGB(255, 255, 255),
		textDim     = Color3.fromRGB(150, 215, 170),
		stroke      = Color3.fromRGB(22, 80, 40),
		strokeHover = Color3.fromRGB(40, 180, 80),
		critical    = Color3.fromRGB(240, 80, 80),
		success     = Color3.fromRGB(120, 255, 120)
	},
	Red = {
		primary     = Color3.fromRGB(18, 7, 8),
		sidebar     = Color3.fromRGB(22, 9, 11),
		secondary   = Color3.fromRGB(28, 12, 14),
		tertiary    = Color3.fromRGB(38, 17, 20),
		accent      = Color3.fromRGB(255, 60, 80),
		text        = Color3.fromRGB(255, 255, 255),
		textDim     = Color3.fromRGB(220, 155, 165),
		stroke      = Color3.fromRGB(100, 28, 36),
		strokeHover = Color3.fromRGB(200, 55, 75),
		critical    = Color3.fromRGB(255, 30, 30),
		success     = Color3.fromRGB(80, 240, 100)
	},
	Light = {
		primary     = Color3.fromRGB(238, 238, 244),
		sidebar     = Color3.fromRGB(230, 230, 238),
		secondary   = Color3.fromRGB(248, 248, 252),
		tertiary    = Color3.fromRGB(255, 255, 255),
		accent      = Color3.fromRGB(75, 80, 105),
		text        = Color3.fromRGB(24, 24, 30),
		textDim     = Color3.fromRGB(115, 115, 128),
		stroke      = Color3.fromRGB(196, 196, 210),
		strokeHover = Color3.fromRGB(130, 130, 150),
		critical    = Color3.fromRGB(220, 50, 50),
		success     = Color3.fromRGB(50, 175, 75)
	},
	MaterialYou = {
		primary     = Color3.fromRGB(16, 18, 26),
		sidebar     = Color3.fromRGB(20, 22, 32),
		secondary   = Color3.fromRGB(24, 27, 38),
		tertiary    = Color3.fromRGB(32, 36, 52),
		accent      = Color3.fromRGB(130, 177, 255),
		text        = Color3.fromRGB(225, 228, 240),
		textDim     = Color3.fromRGB(138, 143, 163),
		stroke      = Color3.fromRGB(45, 52, 78),
		strokeHover = Color3.fromRGB(100, 130, 200),
		critical    = Color3.fromRGB(255, 130, 120),
		success     = Color3.fromRGB(120, 210, 160)
	},
	FrostedGlass = {
		primary     = Color3.fromRGB(198, 208, 228),
		sidebar     = Color3.fromRGB(188, 200, 222),
		secondary   = Color3.fromRGB(212, 222, 240),
		tertiary    = Color3.fromRGB(224, 232, 248),
		accent      = Color3.fromRGB(75, 125, 215),
		text        = Color3.fromRGB(18, 22, 38),
		textDim     = Color3.fromRGB(85, 96, 126),
		stroke      = Color3.fromRGB(155, 175, 212),
		strokeHover = Color3.fromRGB(110, 150, 218),
		critical    = Color3.fromRGB(210, 45, 55),
		success     = Color3.fromRGB(35, 175, 95)
	},
	DarkGlass = {
		primary     = Color3.fromRGB(13, 13, 17),
		sidebar     = Color3.fromRGB(17, 17, 22),
		secondary   = Color3.fromRGB(22, 22, 28),
		tertiary    = Color3.fromRGB(28, 28, 36),
		accent      = Color3.fromRGB(175, 196, 255),
		text        = Color3.fromRGB(228, 233, 255),
		textDim     = Color3.fromRGB(128, 138, 168),
		stroke      = Color3.fromRGB(52, 56, 88),
		strokeHover = Color3.fromRGB(118, 138, 220),
		critical    = Color3.fromRGB(255, 75, 85),
		success     = Color3.fromRGB(75, 218, 128)
	}
}

currentTheme = Themes[Settings.theme] or Themes.Dark
themeElements = {}
mainStrokeGrad, miniIconGrad = nil, nil
UpdateTabStyles = nil
UpdateTabData = nil
_updateTitleGrad = nil

function RegisterTheme(el, prop, key)
	if el then themeElements[#themeElements + 1] = {el = el, prop = prop, key = key} end
end

	return true
end
