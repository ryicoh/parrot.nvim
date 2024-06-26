local logger = require("parrot.logger")

local Anthropic = {}
Anthropic.__index = Anthropic

local available_model_set = {
  ["claude-3-opus-20240229"] = true,
  ["claude-3-sonnet-20240229"] = true,
  ["claude-3-haiku-20240307"] = true,
}

function Anthropic:new(endpoint, api_key)
  return setmetatable({
    endpoint = endpoint,
    api_key = api_key,
    name = "anthropic",
  }, self)
end

function Anthropic:curl_params()
  return {
    self.endpoint,
    "-H",
    "x-api-key: " .. self.api_key,
    "-H",
    "anthropic-version: 2023-06-01",
  }
end

function Anthropic:verify()
  if type(self.api_key) == "table" then
    logger.error("api_key is still an unresolved command: " .. vim.inspect(self.api_key))
    return false
  elseif self.api_key and string.match(self.api_key, "%S") then
    return true
  else
    logger.error("Error with api key " .. self.name .. " " .. vim.inspect(self.api_key) .. " run :checkhealth parrot")
    return false
  end
end

function Anthropic:preprocess_messages(messages)
  -- remove the first message that serves as the system prompt as anthropic
  -- expects the system prompt to be part of the curl request and not the messages
  table.remove(messages, 1)
  return messages
end

function Anthropic:add_system_prompt(messages, _)
  return messages
end

function Anthropic:process(line)
  if line:match("content_block_delta") and line:match("text_delta") then
    local decoded_line = vim.json.decode(line)
    if decoded_line.delta and decoded_line.delta.type == "text_delta" and decoded_line.delta.text then
      return decoded_line.delta.text
    end
  end
end

function Anthropic:check(agent)
  local model = type(agent.model) == "string" and agent.model or agent.model.model
  return available_model_set[model]
end

return Anthropic
