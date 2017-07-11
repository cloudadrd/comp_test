local function check_folder(root_folder, file_md5_table, comp_file_table)
    local lfs = require 'lfs'
    local new_md5_table = {}
    local new_file_table = {}

    for file in lfs.dir(root_folder) do
        if string.find(file, '[A-Z]') == 1 then
            local f_tmp = io.open(root_folder .. '/' .. file, "rb")
            local s_all = f_tmp:read("*a")
            local file_md5 = ngx.md5(s_all)
            if file_md5_table[file] == file_md5 then
                new_file_table[file] = comp_file_table[file]
            else
                new_file_table[file] = io.open(root_folder .. '/' .. file, "r")
            end
            new_md5_table[file] = file_md5
        end
    end
    return new_md5_table, new_file_table
end


ngx.timer.at(0, function(premature)
    ngx.thread.spawn(function()
        local comp_file_table = {}
        local file_md5_table = {}
        local counter = -1
        local update_freq = 600
        local sleep_time = 0.5
        local max_queue_len = 5000
        local root_folder = '/data/competitor'

        while not ngx.worker.exiting() and ngx.worker.id() == 0 do
            -- check local file to fill comp_file_table
            if counter< 0 or counter>= update_freq then
                file_md5_table, comp_file_table = check_folder(root_folder, file_md5_table, comp_file_table)
                counter = 0
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
                        if not line then
                            break
                        end
                        ngx.shared.user_queue:rpush(country, line)
                    end
                end
            end
            ngx.sleep(sleep_time)
        end
    end)
end)
