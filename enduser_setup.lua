print('enduser_setupstart...')
-- Очистка параметров соединения wifi
wifi.sta.clearconfig()
if file.exists('eus_params.lua') then
	local cfg_content = file.getcontents('eus_params.lua');
    file.putcontents('eus_params.lua.bak', cfg_content);
    --file.remove('eus_params.lua')
    cfg_content = nil;
end
wifi.sta.disconnect();
--MQTT = nil;
--Индикация режима настройки
gpio.serout(ledOut, gpio.LOW, {200000, 200000}, 10, function ()
    gpio.write(ledOut, status);
end)
enduser_setup.start(
	'ESPnode-Weather'..node.chipid(),
	function()
		print("Connected to WiFi as:" .. wifi.sta.getip())
        --Индикация режима настройки
        gpio.serout(ledOut, gpio.LOW, {100000, 200000}, 5, function ()
            gpio.write(ledOut, status);
        end)
        tmr.create():alarm(2000, tmr.ALARM_SINGLE, function()
            node.restart();
        end);
	end,
	function(err, str)
		print("Enduser_setup: Err #" .. err .. ": " .. str)
        gpio.serout(ledOut, gpio.LOW, {200000, 100000}, 4, function ()
            gpio.write(ledOut, status);
        end)
	end
)
tmr.create():alarm(60*5*1000, tmr.ALARM_SINGLE, function()
    node.restart();
end);
collectgarbage();