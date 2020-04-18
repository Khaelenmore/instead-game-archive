--$Name: Архив
--$Version: 0.1
--$Author:Пётр Косых

require "fmt"

fmt.dash = true
fmt.quotes = true

require 'parser/mp-ru'

game.dsc = [[{$fmt b|АРХИВ}^^Интерактивная новелла-миниатюра для
выполнения на ПЭВМ.^^Для
помощи, наберите "помощь" и нажмите "ввод".]];

-- чтоб можно было писать "на кухню" вместо "идти на кухню"
game:dict {
	["Димидий/мр,C,но,ед"] = {
		"Димидий/им",
		"Димидий/вн",
		"Димидия/рд",
		"Димидию/дт",
		"Димидием/тв",
		"Димидии/пр",
	}
}

function game:before_Any(ev, w)
	if ev == "Ask" or ev == "Say" or ev == "Tell" or ev == "AskFor" or ev == "AskTo" then
		p [[Попробуйте просто поговорить.]];
		return
	end
	return false
end

function mp:pre_input(str)
	local a = std.split(str)
	if #a <= 1 or #a > 3 then
		return str
	end
	if a[1] == 'в' or a[1] == 'на' or a[1] == 'во' or
		a[1] == "к" or a[1] == 'ко' then
		return "идти "..str
	end
	return str
end

Path = Class {
	['before_Walk,Enter'] = function(s)
		if mp:check_inside(std.ref(s.walk_to)) then
			return
		end
		walk(s.walk_to)
	end;
	before_Default = function(s)
		if s.desc then
			p(s.desc)
			return
		end
		p ([[Ты можешь пойти в ]], std.ref(s.walk_to):noun('вн'), '.');
	end;
	default_Event = 'Walk';
}:attr'scenery,enterable';

Careful = Class {
	before_Default = function(s, ev)
		if ev == "Exam" or ev == "Look" or ev == "Search" or
	ev == 'Listen' or ev == 'Smell' then
			return false
		end
		p ("Лучше оставить ", s:noun 'вн', " в покое.")
	end;
}:attr 'scenery'

Distance = Class {
	before_Default = function(s, ev)
		if ev == "Exam" or ev == "Look" or ev == "Search" then
			return false
		end
		p ("Но ", s:noun(), " очень далеко.");
	end;
}:attr 'scenery'

Furniture = Class {
	['before_Push,Pull,Transfer,Take'] = [[Пусть лучше
	{#if_hint/#first,plural,стоят,стоит} там, где
	{#if_hint/#first,plural,стоят,стоит}.]];
}:attr 'static'

Prop = Class {
	before_Default = function(s, ev)
		p ("Тебе нет дела до ", s:noun 'рд', ".")
	end;
}:attr 'scenery'

Distance {
	-"звёзды/мн,но,жр";
	nam = 'stars';
	description = [[Звёзды смотрят на тебя.]];
}

obj {
	-"космос|пустота";
	nam = 'space';
	description = [[Выход человечества в гиперпространство не сильно
приблизил звёзды. Ведь прежде чем построить ворота у новой звёздной системы,
нужно добраться до неё. Полёт до неисследованной звезды по
прежнему занимает годы или даже десятки лет.]];
	obj = {
		'stars';
	}
}:attr 'scenery';

global 'radio_ack' (false)

Careful {
	nam = 'windows';
	-"окна|иллюминаторы";
	description = function(s)
		if here() ^ 'burnout' then
			p [[Сквозь толстые окна ты видишь
	сияние гиперпространства.]];
		elseif here() ^ 'ship1' then
			p [[Сквозь толстые окна ты видишь
фиолетовую планету. Это -- Димидий.]];
		end
	end;
	found_in = { 'ship1', 'burnout' };
};

obj {
	-"фото|фотография";
	nam = 'photo';
	init_dsc = [[К углу одного из окон прикреплена
фотография.]];
	description = [[Это фотография
твоей дочери Лизы, когда её было всего 9 лет.]];
	found_in = { 'ship1', 'burnout' };
};

Careful {
	nam = 'panel';
	-"приборы|панель";
	till = 27;
	stop = false;
	daemon = function(s)
		s.till = s.till - 1
		if s.till == 0 then
			DaemonStop(s)
		end
	end;
	description = function(s)
		if here() ^ 'ship1' then
			p [[Все системы корабля в
норме. Можно толкнуть рычаг тяги.]];
		elseif here() ^ 'burnout' then
			if here().flames then
				p [[Пожар в машинном отсеке!]];
			end
			if s.till > 20 then
				p [[Неполадки во 2-м
	двигателе!]];
			elseif s.till > 15 then
				p [[1-й и 2-й двигатель вышли
	из строя! Сбой системы стабилизации!]];
			else
				p [[Все двигатели вышли из
	строя!]]
				s.stop = true
			end
			p [[Это очень опасно!]]
			_'throttle':description()
			if s.till then
				p ([[^^До конца перехода ]], s.till,
	[[ сек.]])
			end
		end
	end;
	found_in = { 'ship1', 'burnout' };
	obj = {
		obj {
			-"рычаг|тяга|рычаг тяги";
			nam = 'throttle';
			ff = false;
			['before_SwitchOn,SwitchOff'] = [[Рычаг тяги можно
	тянуть или толкать.]];
			description = function(s)
				if here() ^ 'ship1' then
					p [[Массивный
рычаг тяги стоит на нейтральной позиции.]];
				elseif here() ^ 'burnout' then
					if s.ff then
						pr [[Тяга включена]];
						if _'panel'.stop then
							pr [[, только
	двигатели больше не работают]]
						end
						pr '.'
					else
						p [[Тяга выключена.]]
					end
				end
			end;
			before_Push = function(s)
				if not radio_ack then
					p [[Ты совсем
забыл связаться с диспетчерской. Для этого нужно включить радио.]];
				elseif here() ^ 'ship1' then
					s.ff = true
					walk 'transfer'
				elseif here() ^ 'burnout' then
					if not s.ff then
						p [[Ты передвинул рычаг вперёд.]]
					end
					s.ff = true
					p [[Рычаг установлен в позиции
	максимальной тяги.]];
				end
			end;
			before_Transfer = function(s, w)
				if w == pl then
					return mp:xaction("Pull", s)
				end
				return false
			end;
			before_Pull = function(s)
				if here() ^ 'ship1' then
					return false
				elseif here() ^ 'burnout' then
					if s.ff then
						if not _'panel'.stop then
							p
	[[Перемещение в туннеле возможно только с применением постоянной
	тяги. Остановка двигателей будет означать непредсказуемое
	движение под действием "ветра гиперпространства",  который
	вытолкнет корабль из туннеля и тогда -- пути назад уже не будет!]];
							return
						end
						p [[Ты тянешь рычаг на себя.]]
					end
					s.ff = false
					p [[Рычаг тяги на нейтральной позиции.]]
				end
			end;
		}:attr'static';
		obj {
				-"радио";
			description = [[Радио встроено
в панель управления.]];
			before_SwitchOn = function(s)
				if s:once() then
					p [[-- PEG51,
борт FL510, запрашиваю разрешение на вылет.^
-- ... FL510, вылет разрешаю. Ворота свободны. Счастливого пути!^
-- Принято.]];
					radio_ack = true;
				elseif here() ^ 'burnout' then
					p [[Автоматика и так уже шлёт
	"SOS", а также передаёт все показания приборов. Возможно, это поможет
	комиссии разобраться в причинах аварии. "Возможно" -- так как
	ещё ни один инцидент в гиперпространстве не заканчивался возвращением
	корабля.]]
				else
					p [[Ты уже
получил разрешение на вылет.]]
				end
			end;
		}:attr 'switchable,static';
	};
}:attr'supporter';

room {
	-"рубка|Резвый|корабль";
	title = "рубка";
	nam = 'ship1';
	dsc = [[В рубке "Резвого" тесно. Сквозь узкие окна в кабину
	проникают косые лучи звезды 51 Peg, освещая приборную
	панель. Прямо по курсу -- ворота перехода.^^
Всё подготовлено, чтобы начать переход. Но всё-таки,
	ты хочешь ещё раз осмотреть приборы.]];
	out_to = function(s)
		p [[Не время гулять по кораблю. Ты готовишься совершить переход. Все приборы
находятся в рубке.]]
	end;
	obj = {
		'space',
		'panel',
		Distance {
			-"звезда|солнце|Peg";
			description = [[О том, что вокруг 51 Peg
вращается экзопланета похожая на Землю, было известно очень давно.
И только в 2220-м году здесь были открыты ворота в гиперпространство.
До Земли -- 50 световых лет или 4 перехода. 120 лет экспансии
человечества в дальний космос...]];

		};
		'windows';
		Distance {
			-"планета|Димидий";
			description = [[
Димидий стал первой достигнутой планетой, условия жизни на которой
были пригодны для человека. Как только в 2220-м здесь были
установлены ворота, в поисках новой жизни на Димидий ринулись первопроходцы.^^
А ещё через 5 лет на планете были обнаружены богатейшие залежи
урана. Старый мир страдал от нехватки ресурсов, но в нём были
сосредоточены деньги и власть. Поэтому Димидию не суждено было стать
Новой Землёй. Он превратился в колонию.^^
Твой полугодовой контракт на Димидии завершился, пора возвращаться домой.]];
		};
		obj {
			-"лучи";
			description = [[Это лучи местного
солнца. Они скользят по приборной панели.]];
		}:attr'scenery';
		Distance {
			-"ворота|переход";
			description = function(s)
				if s:once() then
					p [[Ворота -- так называется вход
в гиперпространство. Выглядят ворота как 40-метровое кольцо, медленно
вращающееся в пустоте. Ворота в системе 51 Peg открыли в 2220-м. Они
стали 12-ми воротами, построенными за 125 летнюю историю экспансии
		человечества в дальний космос.]];
				else
					p [[Сквозь ворота ты видишь
всполохи гиперпространства.]];
				end
			end;
			obj = {
				Distance {
					-"гиперпространство|всполохи";
					description =
						[[Гиперпространство
было открыто в 2095-м, во время экспериментов
на БСР. Ещё 4 года понадобилось на то, чтобы найти способ
синхронизировать континуум между выходами из гиперпространства.]]
				}:attr 'scenery';
			}
		};
	}
}

cutscene {
	nam = "transfer";
	title = "Переход";
	text = {
		[[Перед тем, как положить руку на массивный рычаг,
	ты бросил взгляд на фото своей дочери.^
-- С Богом...]];
		[[Ты плавно передвигаешь массивную ручку вперёд и
	наблюдаешь за приближением ворот. За свою 20-летнюю карьеру,
	ты делал это не раз. Корабль вздрагивает, гигантская сила
	втягивает его и вот, ты уже наблюдаешь причудливое
	переплетение огней. Ещё несколько секунд и... БАМ!!!]];
		[[Корабль сотрясает вибрация. Что-то не так? Вибрация
	нарастает. Удар. Ещё удар. Приборная панель расцветает
	россыпью огней.]];
	};
	next_to = 'burnout';
	exit = function(s)
		DaemonStart 'panel'
	end;
}

room {
	-"рубка|Резвый|корабль";
	title = "рубка";
	nam = 'burnout';
	flames = true;
	Listen = function(s)
		p [[Рубка заполнена сигналом тревоги.]]
	end;
	dsc = function(s)
		if s.flames then
			p [[Рубка "Резвого" заполнена сигналом
	тревоги. Нужно осмотреть приборы, чтобы выяснить что
	происходит.]];
		else
			p [[В рубке "Резвого" тесно. Сквозь окна ты
	видишь сияние гиперпространства.]]
		end
		p [[^^Ты можешь выйти из рубки.]]
	end;
	out_to = 'room';
	obj = {
		Distance {
			-"гиперпространство|сияние";
			description =
				[[Переход ещё не завершён. Эта мысль
мешает тебе наслаждаться великолепным сиянием.]];
		};
		'panel';
		'windows';
	};
}

room {
	-"трюм";
	title = 'трюм';
	nam = 'storage';
	u_to = 'room';
	dsc = [[Отсюда ты можешь подняться наверх.]];
	obj = {
		Furniture {
			-"контейнеры,ящики";
			description = [[Это контейнеры с оборудованием.]];
			before_Open = [[Контейнеры опечатаны. Не стоит
их открывать.]];
		}:attr'openable';
	};
}

room {
	-"коридор";
	title = 'коридор';
	nam = 'room';
	dsc = [[Отсюда ты можешь попасть в рубку и к двигателям.]];
	d_to = "#trapdoor";
	before_Sleep = [[Не время спать.]];
	before_Smell = [[Пахнет гарью.]];
	obj = {
		obj {
			-"шкаф";
			description = function(s)
				p [[В этом шкафу должен храниться
скафандр.]];
				if s:has 'open' then
					p [[Но его здесь нет.]]
				end
				return false
			end;
			obj = {
				obj {
					-"огнетушитель,баллон";
					nam = "огнетушитель";
					description = [[Баллон ярко-красного
цвета. Разработан специально для использования на космическом
флоте.]];
				}
			};
		}:attr 'static,openable,container';
		Furniture {
			-"кровать";
			description = [[Стандартная кровать. Такая
стоит почти во всех небольших судах, типа "Резвого".]];
		}:attr 'enterable,supporter';
		door {
			-"люк";
			nam = "#trapdoor";
			description = function(s)
				p [[Люк ведёт вниз.]]
			end;
			door_to = 'storage';
		}:attr 'static,openable';
		Path {
			-"рубка";
			walk_to = 'burnout';
			desc = [[Ты можешь пойти в рубку.]];
		};
		Path {
			-"двигатели|машинный отсек";
			walk_to = 'engine';
			desc = [[Ты можешь пойти к двигателям.]];
		};
	}
}

room {
	-"машинный отсек,отсек";
	title = "Машинный отсек";
	nam = 'engine';
	flame = true;
	dsc = function(s)
		if s.flame then
			p [[В машинном отсеке пылает огонь!]];
		end
		p [[^^Ты можешь выйти из машинного отсека.]]
	end;
	out_to = 'room';
	obj = {
		obj {
			nam = '#flame';
			-"огонь|пламя";
			before_Default = [[Пожар в машинном
отсеке!]];
		}:attr 'scenery';
		Path {
			-"коридор";
			walk_to = 'room';
			desc = [[Ты можешь выйти в коридор.]];
		};
	}
}
function game:after_Taste()
	p [[Что за странные идеи?]]
end

function game:after_Smell()
	p [[Ничего интересного.]]
end

obj {
	-"борода,щетина";
	nam = "beard";
	description = [[Тебе просто лень бриться. Ты совсем не следишь
за своим внешним видом.]];
}:attr 'static';

pl.description = function(s)
	p [[Ты -- геолог-разведчик объектов дальнего
космоса. Пробивающаяся седина в бороде, усталый взгляд и морщины на
лице выдают в тебе мужчину средних лет.]]
	if here() ^ 'ship1' then
		p [[
Пол года ты работал по контракту на
"Димидии", занимаясь разведкой месторождений урана. Но теперь контракт
завершён.]]
	end;
end
pl.scope = std.list { 'beard' }

VerbExtendWord {
	"#Climb",
	"подняться,поднимись";
}

function mp:before_Exting(w)
	if not have 'огнетушитель' then
		p [[Тебе нечем тушить.]]
		return
	end
	return false
end
function mp:after_Exting(w)
	if not w then
		p [[Тут нечего тушить.]]
	else
		p ([[Тушить ]], w:noun 'вн', "?")
	end
end

Verb {
	"туши/ть,[по|за]туши/ть";
	": Exting";
	"{noun}/вн,scene: Exting";
}
function init()
	mp.togglehelp = true
	mp.autohelp = false
	mp.autohelp_limit = 8
	mp.compl_thresh = 1
	walk 'ship1'
end
