local BASE_URL = os.getenv("LITELLM_BASE_URL") or "http://localhost:4000"

local OpenAI = uji.api.openai

local LiteLLM = uji.class(OpenAI)

function LiteLLM:assistant(item, request)
  local out = OpenAI.assistant(self, item, request)
  if request.model:match("^deepseek") then
    out.reasoning_content = item.reasoning or ""
  end
  return out
end

uji.provider.add({
  id = "litellm",
  name = "LiteLLM",
  api = LiteLLM(),
  base_url = BASE_URL,
  auth_env = { "LITELLM_API_KEY" },
  models = {
    -- Claude
    { id = "claude-fable-5", context = 1000000, output = 128000, reasoning = true },
    { id = "claude-fable-5-1", context = 1000000, output = 128000, reasoning = true },
    { id = "claude-haiku-4-5", context = 200000, output = 64000, reasoning = true },
    { id = "claude-haiku-4-5-20251001", context = 200000, output = 64000, reasoning = true },
    { id = "claude-opus-4-5", context = 200000, output = 64000, reasoning = true },
    { id = "claude-opus-4-5-20251101", context = 200000, output = 64000, reasoning = true },
    { id = "claude-opus-4-6", context = 1000000, output = 128000, reasoning = true },
    { id = "claude-opus-4-7", context = 1000000, output = 128000, reasoning = true },
    { id = "claude-opus-4-8", context = 1000000, output = 128000, reasoning = true },
    { id = "claude-opus-5", context = 1000000, output = 128000, reasoning = true },
    { id = "claude-sonnet-4-5", context = 1000000, output = 64000, reasoning = true },
    { id = "claude-sonnet-4-5-20250929", context = 1000000, output = 64000, reasoning = true },
    { id = "claude-sonnet-4-6", context = 1000000, output = 128000, reasoning = true },
    { id = "claude-sonnet-5", context = 1000000, output = 128000, reasoning = true },
    -- GLM
    { id = "glm-4.5", context = 131072, output = 98304, reasoning = true },
    { id = "glm-4.5-air", context = 131072, output = 98304, reasoning = true },
    { id = "glm-4.5-flash", context = 131072, output = 98304, reasoning = true },
    { id = "glm-4.5v", context = 64000, output = 16384, reasoning = true },
    { id = "glm-4.6", context = 204800, output = 131072, reasoning = true },
    { id = "glm-4.6v", context = 128000, output = 32768, reasoning = true },
    { id = "glm-4.7", context = 204800, output = 131072, reasoning = true },
    { id = "glm-4.7-flash", context = 200000, output = 131072, reasoning = true },
    { id = "glm-4.7-flashx", context = 200000, output = 131072, reasoning = true },
    { id = "glm-5", context = 204800, output = 131072, reasoning = true },
    { id = "glm-5.1", context = 200000, output = 131072, reasoning = true },
    { id = "glm-5.2", context = 1000000, output = 131072, reasoning = true },
    { id = "glm-5.3", context = 1000000, output = 131072, reasoning = true },
    { id = "glm-5.3-flash", context = 1000000, output = 131072, reasoning = true },
    { id = "glm-5v-turbo", context = 200000, output = 131072, reasoning = true },
    -- DeepSeek
    { id = "deepseek-flash", context = 1000000, output = 384000, reasoning = true },
    { id = "deepseek-v4-flash", context = 1000000, output = 384000, reasoning = true },
    { id = "deepseek-v4-flash-vision-exp", context = 1000000, output = 384000, reasoning = true },
    { id = "deepseek-v4-pro", context = 1000000, output = 384000, reasoning = true },
  },
})

local function listed()
  for _, provider in ipairs(uji.provider.list()) do
    if provider.id == "litellm" then
      local models = {}
      for _, model in ipairs(provider.models) do
        models[model.id] = model
      end
      return models
    end
  end
  return {}
end

uji.http.request({
  url = BASE_URL .. "/model/info",
  headers = { Authorization = "Bearer " .. (os.getenv("LITELLM_API_KEY") or "") },
}, function(response)
  if not response or response.status ~= 200 then
    return
  end
  local ok, info = pcall(uji.json.decode, response.body, { nulls = false })
  if not ok or type(info) ~= "table" or type(info.data) ~= "table" then
    return
  end
  local known, changed = listed(), {}
  for _, entry in ipairs(info.data) do
    local model = known[entry.model_name]
    local limits = entry.model_info or {}
    if model and (limits.max_input_tokens or limits.max_output_tokens) then
      model.context = limits.max_input_tokens or model.context
      model.output = limits.max_output_tokens or model.output
      changed[#changed + 1] = model
    end
  end
  if #changed > 0 then
    uji.provider.add({ id = "litellm", models = changed })
    uji.emit("status_changed", {})
  end
end)
