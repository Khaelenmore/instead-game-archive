--$Name: Архив$
--$Version: 0.9$
--$Author:Пётр Косых$

require "fmt"
require "link"
obj {
	nam = '@lang';
	act = function(s, t)
		gamefile('main3-'..t..'.lua', true)
	end;
}
room {
	nam = 'main';
	pic = 'gfx/gate.jpg';
	title = function(s)
		if std.rawget(_G, 'LANG') == 'ru' then
			p [[Выбор языка]]
		else
			p [[Select language]]
		end
	end;
	decor = [[- {@lang ru|Русский}^
	- {@lang en|English} (TODO)]];
}
