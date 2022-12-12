node.setcpufreq(node.CPU80MHZ)
--node.CPU80MHZ
--node.CPU160MHZ
--[[
	Первая кнопка   		GPIO0   3
	Выход реле				GPIO12	6	
	Выход сигнального диода	GPIO13	7	(Зеленый диод)
	NC						GPIO14	5	(Вывод на гребенке, не используется)
--]]

MQTT = {status = false, client = nil}; --объект mqtt брокера
--Выходы
relayOut = 6;
ledOut = 7;
--Входы
pinIn  = 3;

--Статус выключателя
status = 0;

--Определение подключения кнопки и логических состояний
--gpio.mode(pinIn, gpio.INPUT); --Вход
--KEY_ON = gpio.read(pinIn) == gpio.LOW and 0 or 1;
KEY_ON = 0;

-- Функция переключеня статуса
function toggleStatus(i)
	if i == nil then
		status = status == 1 and 0 or 1;
	else
		status = i;
	end
	gpio.write(relayOut, status);
	gpio.write(ledOut, status == 1 and 0 or 1);
	if MQTT.status then
		MQTT.publish('relay/0', status == 1 and 'on' or 'off', 0, 0);
	end
end

--Подугрузка скриптов
function do_file(fname)
    if file.exists(fname .. '.lua') then
        return dofile(fname .. '.lua')
    else
        return dofile(fname .. '.lc')
    end    
end

-- Загрузка конфигурации
Config = {};
-- 	Config = dofile('getConfig.lua')
Config = do_file('getConfig');
if Config == nil or Config.mqtt_login == nil
        or Config.mqtt_password == nil
        or Config.mqtt_client_id == nil
        or Config.wifi_ssid == nil
        or Config.wifi_password  == nil then
    --dofile('enduser_setup.lua')
    do_file('enduser_setup');
else
    --dofile('main.lua')
    do_file('main');
end

--Блок обработки дребезга при нажатии кнопки
timerStatus = 0 -- состояние таймера защиты от дребезга на каждом канале
pressStatus = 0 -- состояние входа на каждом канале
pressLongTimer = tmr.create() -- таймеры для определения длинного нажатия
function inputTrigger(val)
	-- Если произошло длинное нажатие
	-- пропускаем событие отпускания кнопки
	if timerStatus == 2 then
		timerStatus = 0;
		pressStatus = val;
		return;
	end

	if timerStatus == 0 then
		pressStatus = val;
		timerStatus = 1;
		tmr.create():alarm(100, tmr.ALARM_SINGLE, function()
			--сброс блокировки
			timerStatus = 0;
			
			if gpio.read(pinIn) == pressStatus then
				if pressStatus == KEY_ON then
					-- устанавливаем счетчик для проверки длительного нажатия
					pressLongTimer:unregister()
				 	pressLongTimer = tmr.create()
				 	pressLongTimer:register(5000, tmr.ALARM_SINGLE, function (t)
				 		--Статус срабатывания длительного нажатия
						timerStatus = 2;
				 		t:unregister()
				 		-- Выполняем функцию для длительного нажатия
				 		print('Long pressed Event');
						--dofile('enduser_setup.lua')
                        do_file('enduser_setup');
				 	end)
				 	pressLongTimer:start()
					--print('Key Pressed')
				else
				 	--Очищаем счетчик, если длительного нажатия не случилось
				 	pressLongTimer:unregister()
				 	--print('Key Released');
					toggleStatus();
				end;
			end;
			
		end);
		-- /tmr.create
	end
end

-- Конфигурация режима входов
gpio.mode(pinIn, gpio.INT); --Вход триг
-- установка обработчиков событий входных сигналов
gpio.trig(pinIn, 'both', inputTrigger);
-- Конфигурация режима выходов
gpio.mode(relayOut, gpio.OUTPUT);
gpio.mode(ledOut, gpio.OUTPUT);
toggleStatus(status);
