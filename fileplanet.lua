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
  local ishtml = urlpos["link_expect_html"]
  local parenturl = parent["url"]
  
  -- These arguments will be used when the link is a 'download' item
  if item_type == "download" then
    -- Download an url if it has the item_value in the url
    if string.match(url, item_value) then
      return true
    -- Download everything from download.fileplanet.com
    elseif string.match(url, "download%.fileplanet") then
      return true
    -- Download everything from download.direct2drive.com
    elseif string.match(url, "download%.direct2drive%.com") then
      return true
    -- Download one link deep on external urls
    elseif not (string.match(parenturl, "%.fileplanet") or string.match(parenturl, "download%.direct2drive%.com")) then
      return true
    -- After everything, if something is a html file, do not download the file
    elseif ishtml == 1 then
      return false
    -- Return WGET's veridct for the other links
    else
      return verdict
    end
  -- These arguments will be used when the link is a 'site' item
  elseif item_type =='site':
    -- Download an url if it has the item_value in the url
    if string.match(url, item_value) then
      return true
    -- Download one link deep on external urls
    elseif not string.match(parenturl, item_value) then
      return true
    -- After everything, if something is a html file, do not download the file
    elseif ishtml == 1 then
      return false
    -- Return WGET's veridct for the other links
    else
      return verdict
    end
  -- If the url is not from a item_type that we know of, don't download the link
  else
    return false
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
    if string.match(url["host"], "fileplanet%.com") or
      string.match(url["host"], "download%.direct2drive%.com") then
      
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
