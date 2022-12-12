MQTT = require('mqttClient').init(
    Config.mqtt_client_id,
    Config.mqtt_login,
    Config.mqtt_password,
    Config.mqtt_topic..'/'..Config.mqtt_client_id,
    {
        { topic = 'relay/0/set', qos = 0}
        --'relay/0/set',
    },
    function(clnt, topic, data)
        if string.find(topic, 'relay/0/set') then
            if data == 'on' then
                toggleStatus(1);
            else
                toggleStatus(0);
            end
        end
    end
);
package.loaded['mqttClient'] = nil;
local wifiClient = require('wifiClient').connect(
    Config.wifi_ssid,
    Config.wifi_password,
    function()
        print('wifi connected')
        MQTT.connect(Config.mqtt_broker_ip, Config.mqtt_broker_port);
        MQTT.publish('relay/0', status, 0, 0);
    end,
    function()
        MQTT.disconnect();
        print('wifi disconnected')
    end,
    100
)
package.loaded['wifiClient'] = nil;
collectgarbage();