local url_count = 0
local tries = 0
local item_type = os.getenv('item_type')
local item_value = os.getenv('item_value')


read_file = function(file)
  if file then
    local f = assert(io.open(file))
    local data = f:read("*all")
    f:close()
    return data
  else
    return ""
  end
end

wget.callbacks.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
  local url = urlpos["url"]["url"]

  -- Skip redirect from mysite.verizon.net and members.bellatlantic.net
  if url == "http://entertainment.verizon.com/" then
    return false
  elseif string.match(url, "bellatlantic%.net/([^/]+)/") or
    string.match(url, "verizon%.net/([^/]+)/") then
    if item_type == "verizon" then
      local directory_name_verizon = string.match(url, "verizon%.net/([^/]+)/")
      directory_name_verizon = string.gsub(directory_name_verizon, '%%7E', '~')
      if directory_name_verizon ~= item_value then
        -- do not want someone else's homepage
        -- io.stdout:write("\n Reject " .. url .. " " .. directory_name_verizon .. "\n")
        -- io.stdout:flush()
        return false
      else
        return verdict
      end
    elseif item_type == "bellatlantic" then
      local directory_name_bellatlantic = string.match(url, "bellatlantic%.net/([^/]+)/")
      directory_name_bellatlantic = string.gsub(directory_name_bellatlantic, '%%7E', '~')
      if directory_name_bellatlantic ~= item_value then
        -- do not want someone else's homepage
        -- io.stdout:write("\n Reject " .. url .. " " .. directory_name_bellatlantic .. "\n")
        -- io.stdout:flush()
        return false
      else
        return verdict
      end
    elseif item_type == "bellatlantic36pack" then
      local directory_name_bellatlantic36pack = string.match(url, "bellatlantic%.net/([^/]+)/")
      directory_name_bellatlantic36pack = string.gsub(directory_name_bellatlantic36pack, '%%7E', '~')
      if not string.match(directory_name_bellatlantic36pack, item_value) then
        -- do not want someone else's homepage
        -- io.stdout:write("\n Reject " .. url .. " " .. directory_name_bellatlantic36pack .. "\n")
        -- io.stdout:flush()
        return false
      else
        return verdict
      end
    elseif item_type == "verizon36pack" then
      local directory_name_verizon36pack = string.match(url, "verizon%.net/([^/]+)/")
      directory_name_verizon36pack = string.gsub(directory_name_verizon36pack, '%%7E', '~')
      if not string.match(directory_name_verizon36pack, item_value) then
        -- do not want someone else's homepage
        -- io.stdout:write("\n Reject " .. url .. " " .. directory_name_verizon36pack .. "\n")
        -- io.stdout:flush()
        return false
      else
        return verdict
      end
    else
      -- shouldn't reach here!
      assert(false)
    end
  elseif string.match(url, "//////////") then
    return false
  else
    return verdict
  end
end

wget.callbacks.httploop_result = function(url, err, http_stat)
  -- NEW for 2014: Slightly more verbose messages because people keep
  -- complaining that it's not moving or not working
  local status_code = http_stat["statcode"]
  
  url_count = url_count + 1
  io.stdout:write(url_count .. "=" .. status_code .. " " .. url["url"] .. ".  \r")
  io.stdout:flush()
  if status_code >= 500 or
    (status_code >= 400 and status_code ~= 404 and status_code ~= 403) then
    if string.match(url["host"], "verizon%.net") or
      string.match(url["host"], "bellatlantic%.net") then
      if status_code == 423 then
        return wget.actions.ABORT
      end
      
      io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
      io.stdout:flush()
      
      os.execute("sleep 10")
      
      tries = tries + 1
      
      if tries >= 5 then
        io.stdout:write("\nI give up...\n")
        io.stdout:flush()
        return wget.actions.ABORT
      else
        return wget.actions.CONTINUE
      end
    else
      io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
      io.stdout:flush()
      
      os.execute("sleep 10")
      
      tries = tries + 1
      
      if tries >= 5 then
        io.stdout:write("\nI give up...\n")
        io.stdout:flush()
        return wget.actions.NOTHING
      else
        return wget.actions.CONTINUE
      end
    end
  elseif status_code == 0 then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()
    
    os.execute("sleep 1")
    tries = tries + 1
    
    if tries >= 5 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      return wget.actions.ABORT
    else
      return wget.actions.CONTINUE
    end
  end

  tries = 0

  -- We're okay; sleep a bit (if we have to) and continue
  local sleep_time = 0.1 * (math.random(1000, 2000) / 100.0)
  -- local sleep_time = 0

  --  if string.match(url["host"], "cdn") or string.match(url["host"], "media") then
  --    -- We should be able to go fast on images since that's what a web browser does
  --    sleep_time = 0
  --  end

  if sleep_time > 0.001 then
    os.execute("sleep " .. sleep_time)
  end

  return wget.actions.NOTHING
end
