do
	local client = {
		status=false,
		ip = '192.168.0.10',
		port = 1883,
		root_topic = '/',
		for_public = {
			--0 = {topic = 'topic', data = 'data', qos = 0, ret = 0}
		},
		publishing = false, --флаг отправки сообщений
		subscribe_items = {
			--{topic='topic', call_back = function(client, topic, data)}
		},
		sendTimer = nil,
	};
	
	--[[
		Функция добавления сообщения в очередь
	]]
	client.publish = function(topic, data, qos, ret)
		if client.status == false then
			--Если соединение не установлено, ничего не пишем
			return
		end
		--если в очереди скопилось больше 100 сообщенй, затираем первые
		if (#client.for_public > 10) then
			table.remove(client.for_public, 1)
		end
		--если топик не начинается со / слеша, дописываем к нему root_topic
		if string.find(topic, '/', 1, true) ~= 1 then
			topic = client.root_topic..'/'..topic
		end
		local topic_obj = {
			["topic"] = topic,
			["data"] = data,
		};
		if qos ~= nil then
			topic_obj.qos = qos; 
		end
		if ret ~= nil then
			topic_obj.ret = ret
		end
		table.insert(client.for_public, topic_obj);
	end;
	
	--отправка сообщений из очереди по типу FIFO
	-- один за тик таймера
	client.send = function()
		--Если очередь пуста, или клиент не подключен, или отправка уже идет, выходим
		if #client.for_public == 0 or client.status ~= true or client.publishing == true then
			return
		end
		client.publishing = true;
		--while #client.for_public > 0 and client.status == true and client.publishing == true do
			client.m:publish(
				client.for_public[1].topic,
				client.for_public[1].data,
				client.for_public[1].qos ~= nil and client.for_public[1].qos or 0,
				client.for_public[1].ret ~= nil and client.for_public[1].ret or 0
			)
			table.remove(client.for_public, 1);
		--end
		client.publishing = false;
	end;

	--[[
		Добавляет подписчики
	]]
	client.subscribe = function(subs)
		client.m:subscribe(subs.topic, subs.qos);
	end;
	
	-- Выполняется при подключении к брокеру
	client.onSuccessConnect = function(c)
		client.status = true;
		c:publish(client.root_topic..'/lwt', 'online', 0, 1)--, function(client) print("sent") end)
		--подписка на топики, если нужна
		if #client.subscribe_items > 0 then
			for i = 1, #client.subscribe_items do
				client.subscribe(client.subscribe_items[i]);
			end
		end

		--проверка наличия топиков и отправка в цикле
		client.sendTimer = tmr.create()
		client.sendTimer:register(500, tmr.ALARM_AUTO, client.send)
		client.sendTimer:start()
	end;
	-- Выполняется при ошибке подключения к брокеру.
	-- повтор через 10 сек
	client.onErrorConnect = function(c, reason)
		client.status = false;
		client.publishing = false;
		if client.sendTimer ~= nil then
			client.sendTimer = client.sendTimer:unregister()
		end
		tmr.create():alarm(10 * 1000, tmr.ALARM_SINGLE, client.do_connect)
	end;
	-- Непосредственно функция подключения к брокеру
	client.do_connect = function()
		if client.status == false then
			client.m:connect(client.ip, client.port, false, client.onSuccessConnect, client.onErrorConnect);
		end
	end;
	
	--[[
		Функция подключения к брокеру
	]]
	client.init = function (clientid, user, password, root_topic, subscribe_items, subscribe_callback)
		client.m = mqtt.Client(clientid, 60, user, password);
		client.root_topic = root_topic;
		client.m:lwt(client.root_topic..'/lwt', 'offline', 0, 1);
		
		local function normalize_topic(topic)
			if string.find(topic, '/', 1, true) ~= 1 then
				topic = client.root_topic..'/'..topic
			end
			return topic;
		end

		if subscribe_items ~= nil and #subscribe_items > 0 then
			for i = 1, #subscribe_items do
				if type(subscribe_items[i]) == 'string' then
					client.subscribe_items[i] = {
						topic = normalize_topic(subscribe_items[i]),
						qos = 0
					};
				else
					client.subscribe_items[i] = {
						topic = normalize_topic(subscribe_items[i].topic),
						qos = subscribe_items[i].qos
					};
				end
			end
			--Установка обработчика события, если объявлен
			if subscribe_callback ~= nil then
				client.m:on('message', subscribe_callback)
			end
		end

		--TODO переподключение клиента wifi.sta.status() == wifi.STA_GOTIP ??
		client.m:on('offline', function(clnt)
			client.status = false;
			client.publishing = false;
			if client.sendTimer ~= nil then
				client.sendTimer = client.sendTimer:unregister()
			end
			tmr.create():alarm(10 * 1000, tmr.ALARM_SINGLE, client.do_connect)
			print ("offline")
		end)

		-- client.m:on('message', function(clnt, topic, data)
		-- 	if #client.subscribe_items > 0 then
		-- 		for i = 1, #client.subscribe_items do
		-- 			if client.subscribe_items[i].topic == topic then
		-- 				client.subscribe_items[i].callback(data);
		-- 				return
		-- 			end
		-- 		end
		-- 		print('Topic not found: '..topic ..' = '.. data)
		-- 	end
		-- end)
		return client;
	end;

	--[[
		Выполнение подключения
	]]
	client.connect = function(ip, port)
		client.ip = ip;
		client.port = port;
		client.do_connect();
	end;

	--[[
		Отключение от брокера
	]]
	client.disconnect = function()
		client.publishing = false;
		client.m:close();
		client.status = false;
		--client.subscribe_items = {}
	end;

	return client;
end
