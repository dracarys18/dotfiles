local BASE_URL = os.getenv("LITELLM_BASE_URL") or "http://localhost:4000"
local KEY = os.getenv("LITELLM_API_KEY") or ""

local OpenAI = uji.api.openai

local LiteLLM = uji.class(OpenAI)

function LiteLLM:assistant(item, request)
    local out = OpenAI.assistant(self, item, request)
    if request.model:match("^deepseek") then
        out.reasoning_content = item.reasoning or ""
    end
    return out
end

local function model(entry)
    local info = entry.model_info or {}
    return {
        id = entry.model_name,
        context = info.max_input_tokens,
        output = info.max_output_tokens or info.max_tokens,
        reasoning = info.supports_reasoning,
        images = info.supports_vision,
    }
end

local function listed()
    local response = uji.http.request({
        url = BASE_URL .. "/model/info",
        headers = { Authorization = "Bearer " .. KEY },
        timeout = 5,
    })
    if not response or response.status ~= 200 then
        return {}
    end
    local ok, info = pcall(uji.json.decode, response.body, { nulls = false })
    if not ok or type(info) ~= "table" or type(info.data) ~= "table" then
        return {}
    end
    local models, seen = {}, {}
    for _, entry in ipairs(info.data) do
        local id = entry.model_name
        if type(id) == "string" and not seen[id] then
            seen[id] = true
            models[#models + 1] = model(entry)
        end
    end
    table.sort(models, function(a, b)
        return a.id < b.id
    end)
    return models
end

uji.provider.add({
    id = "litellm",
    name = "LiteLLM",
    api = LiteLLM(),
    base_url = BASE_URL,
    auth_env = { "LITELLM_API_KEY" },
    models = listed(),
})
