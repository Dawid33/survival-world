local lfs     = require 'lfs'
local serpent = require 'serpent'

local function ternary(condition, if_true, if_false)
    return condition and if_true or if_false
end

local last_modified = 0
local function _check_modification(dir, _last_modified, callback)
    local directory = ternary(string.sub(dir, #dir, #dir) == '/', dir, dir .. '/')
    last_modified = _last_modified
    local file

    for _file in lfs.dir(directory) do
        if _file ~= '..' and _file ~= '.' then
            file = directory .. _file 

            if lfs.attributes(file, 'mode') == 'file' and
               lfs.attributes(file, 'modification') > last_modified then
                last_modified = lfs.attributes(file, 'modification')
                callback(last_modified)
            elseif lfs.attributes(file, 'mode') == 'directory' then
                _check_modification(file .. '/', last_modified, callback)
            end
        end
    end
end

local function _get_last_modified(directory)
    local last = 0

    _check_modification(directory, last_modified, function(_last_modified)
        last = _last_modified
    end)

    return last
end

local function watcher(directory, callback)
    local last = _get_last_modified(directory)
    callback()

    while true do
        _check_modification(directory, last_modified, function(_last_modified)
            last = _last_modified
            callback()
        end)
    end
end

function filemon(dir_path, cb)
  local files = {}
  watcher(dir_path, function()
    -- Check for new files and add them to the table
    -- if they don't already exist.
    for file in lfs.dir(dir_path) do
      local file_path = dir_path .. "/" .. file
      if lfs.attributes(file_path, "mode") == "file" and files[file] == nil then
        local file_handle = io.open(file_path)
        if not file_handle then
          print("Failed to open file: " .. file_handle)
          break
        end
        local current = file_handle:seek()      -- get current position
        local size = file_handle:seek("end")    -- get file size
        file_handle:close()
        local modification = lfs.attributes(file_path, "modification")
        files[file] = { path = file_path, last_end = size, modification = modification }
        print("Adding new file: " .. serpent.line(files[file]))
      end
    end

    for key, value in pairs(files) do
      local file_path = files[key].path
      local file_handle = io.open(file_path)
      if not file_handle then
        print("Failed to open file: " .. file_handle)
        break
      end

      -- Check if file has changed by seeing if its larger than before. 
      local modification = lfs.attributes(file_path, "modification")
      if modification ~= files[key].modification then
        -- Update known timestamp
        files[key].modification = modification

        -- Since file has changed, get delta. 
        file_handle:seek("set", files[key].last_end)
        local delta = file_handle:read("*all")
        files[key].last_end = file_handle:seek()
        file_handle:close()

        -- Split data on new line
        for line in delta:gmatch("[^\n]+") do 
          cb(key, line)
        end
      end
    end
  end)
end

return filemon
