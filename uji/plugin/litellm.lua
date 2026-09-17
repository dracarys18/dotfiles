uji.provider.add({
  id = "litellm",
  name = "LiteLLM",
  wire = "openai-chat",
  base_url = os.getenv("LITELLM_BASE_URL") or "http://localhost:4000",
  auth_env = { "LITELLM_API_KEY" },
  -- These are the values uji would infer from the base url anyway; spelled out
  -- so a quirk can be corrected here without a rebuild.
  --   max_tokens_field = "max_tokens" | "max_completion_tokens" | "none"
  --   thinking         = "openai" | "openrouter" | "deepseek" | "zai" | "qwen" | "none"
  compat = {
    max_tokens_field = "max_tokens",
    thinking = "openai",
    tool_result_name = false,
    finish_reason = true,
  },
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
