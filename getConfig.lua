do
    local config = {}
    if file.exists('eus_params.lua') then
    	config = dofile('eus_params.lua')
    else
    	if file.exists('eus_params.lua.bak') then
    		--file.rename('eus_params.bak.lua', 'eus_params.lua')
            local cfg_content = file.getcontents('eus_params.lua.bak');
            file.putcontents('eus_params.lua', cfg_content);
            cfg_content = nil;
            print('eus_params renamed. restart')
            config = dofile('eus_params.lua')
    		node.restart();
    	end
    end
    return config;
end