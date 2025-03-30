local lfs     = require 'lfs'
local filemon = require 'filemon'
local serpent = require 'serpent'
local cjson   = require "cjson"
local http    = require "socket.http"

local dir_path = os.getenv("script_output_dir")
local dir_path = os.getenv("db_username")
local dir_path = os.getenv("db_password")
if dir_path == nil then
  print("Must supply script_output_dir env variable.")
  return;
end

-- while not lfs.attributes(dir_path) do
--   print("Waiting for script-output directory...")
--   os.execute("sleep 1")
-- end

function Authenticate(username, password)
  http.request("https://factoriosurvivalworld.com/db/")
end

-- while not lfs.attributes(dir_path) do:wq
--   print("Waiting for script-output directory...")
--   os.execute("sleep 1")
-- end

-- filemon(dir_path, function(file, line)
--   local value = cjson.decode(line)
--   if value == nil then
--     print("failed to parse line: " .. line)
--     return
--   end
--   print(value.test)
-- end)

