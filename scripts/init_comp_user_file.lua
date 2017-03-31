local function check_folder(root_folder)
    local lfs = require 'lfs'
    local folder_counter = 0
    local file_table = {}

    for file in lfs.dir(root_folder) do
        local n = tonumber(file)
        if n then
            folder_counter = folder_counter + 1
        end
    end
    if folder_counter ~= 1 then
        return nil
    end
    for folder in lfs.dir(root_folder) do
        local n = tonumber(folder)
        if n then
            file_table = {}
            for file in lfs.dir(root_folder .. '/' .. n) do
                if string.find(file, '[A-Z]') == 1 then
                    file_table[file] = io.open(root_folder .. '/' .. n .. '/' .. file, "r")
                end
            end
        end
    end
    return file_table
end

ngx.timer.at(0, function(premature)
    ngx.thread.spawn(function()
        local comp_file_table = {}
        local counter = -1
        local update_freq = 6000
        local sleep_time = 0.5
        local max_queue_len = 5000
        local root_folder = '/data/competitor/'

        while not ngx.worker.exiting() and ngx.worker.id() == 0 do
            -- check local file to fill comp_file_table
            if counter< 0 or counter>= update_freq then
                local file_table = check_folder(root_folder)
                if file_table then
                    comp_file_table = file_table
                    counter = 0
                else
                    counter = -1
                end
            else
                counter = counter + sleep_time
                -- push data to user_queue
                for country, file in pairs(comp_file_table) do
                    while ngx.shared.user_queue:llen(country) < max_queue_len do
                        local line = file:read()
                        if not line then
                            file:seek('set')
                            line = file:read()
                        end
                        ngx.shared.user_queue:rpush(country, line)
                    end
                end
            end

            ngx.sleep(sleep_time)
        end
    end)
end)
