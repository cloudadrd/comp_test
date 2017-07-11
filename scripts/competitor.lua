
--[[
  request format:
    {
       "country" : "CN"
    }

  return: 
    {
        "errmsg": "ok",
        "gaid": "0000000-000abd-0abdabdab-0abdabd"
        "aid": "1018acad7dabd3b8"
        "pkg": "com.bitmango.go.lollipopmatch3"
        "method": "com1"
    }
]]


local cjson = require 'cjson'

local encode = cjson.encode
local decode = cjson.decode

local function exit_err(err)
    ngx.print(encode{
        ['errmsg'] = err,
    })
    ngx.exit(ngx.HTTP_OK)
end

local function get_body()
    -- update data are usually large and should be cached
    local data = ngx.req.get_body_file() 
    
    if not data then
        -- try to get from buffer
        data = ngx.req.get_body_data()
        if not data then
            exit_err("no data")
        end
    else
        -- read files
        local ok, fn = pcall(io.input, data)
        if not ok then
            exit_err("tmp file error")
        end
        
        data = fn:read("*all")
        fn:close()
    end

    return data
end

local function check_req(req)
    -- check and record
    if not req.country then 
        exit_err("require country")
    end
end


if ngx.req.get_method() ~= 'POST' then
    ngx.exit(ngx.HTTP_NOT_ALLOWED)
end

ngx.req.read_body()
local body = get_body()
if math.random(1,10000) <= 5 then
    ngx.log(ngx.ERR, "get request ..", body)
end

local ok, req = pcall(decode, body)
if not ok then
    exit_err("post body json format error")
end

check_req(req)
local line = ngx.shared.user_queue:lpop(req.country)
if not line then
    exit_err("country not exist " .. req.country)
end

-- format: gaid \t aid \t pkg_name \t method
local text = {}
for w in string.gmatch(line, "%S+") do
    table.insert(text,w)
end

if not text[1] or not text[2] or not text[3] or text[1] == '' or text[2] == '' or text[3] == '' then
    exit_err("wrong data size")
end

local method = 'com0'
if text[4] and text[4] ~= '' then
    method = text[4]
end

local resp = {
    errmsg = 'ok',
    gaid = text[1],
    aid = text[2],
    pkg= text[3],
    method= method
}

ngx.print(encode(resp))

