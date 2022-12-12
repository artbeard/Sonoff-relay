do
    local wifi_client = {
        wifi_connect_status = -1
    };
    
    wifi_client.connect = function(wifi_ssid, wifi_password, onConnect, onDisconnect, onConnFail)
        wifi.setmode(wifi.STATION);
        if wifi.sta.config({ ssid = wifi_ssid, pwd = wifi_password}) ~= false then
            --Событие подключения к wi-fi
            wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function()
                wifi_client.wifi_connect_status = 0;
                --print('Connecting Wifi success! heap='..node.heap())
            end)

            --Событие отключения от wifi
            wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
                --print('Wifi is disconnected: '..wifi.sta.status())
                if type(onDisconnect) == 'function' and wifi_client.wifi_connect_status == 0 then
                    onDisconnect()
                end
                wifi_client.wifi_connect_status = wifi_client.wifi_connect_status + 1;
                --print('wifi connect status: '..wifi_client.wifi_connect_status)
                if onConnFail ~= nil and wifi_client.wifi_connect_status == onConnFail then
                    if file.exists('enduser_setup.lc') then
                        dofile('enduser_setup.lc');
                    end
                end
            end)
            --Событие получения ip адреса
            wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
                --print('Ip got '..wifi.sta.getip()..' heap='..node.heap());
                if type(onConnect) == 'function' then
                    onConnect()
                end
            end)
            
        end
        wifi.sta.connect();
    end;

    return wifi_client;
end