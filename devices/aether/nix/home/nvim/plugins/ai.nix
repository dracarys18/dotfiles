# AI completion for Neovim, two separate things:
#
#  * minuet-ai.nvim — ghost-text inline suggestions while typing, served by the
#    local llama.cpp server (home/llama-cpp.nix). It plugs into blink.cmp as a
#    source; blink's ghost_text renders the suggestion inline (see completion.nix).
#  * codecompanion.nvim — prompt-driven inline edits: select code, run
#    :CodeCompanion <prompt>, and the model rewrites it through the edit_file
#    tool. Accept with g2, reject with g3.
{ pkgs, ... }:

{
  extraPlugins = with pkgs.vimPlugins; [
    minuet-ai-nvim
    codecompanion-nvim
  ];

  extraConfigLua = ''
    require("minuet").setup({
      -- chat completions, not FIM: Qwen3.5-4B is an instruct model, so it is
      -- prompted with the surrounding code rather than FIM sentinel tokens
      provider = "openai_compatible",
      -- llama-server unloads the model after 30 min idle; the first request
      -- then has to reload it
      request_timeout = 20,
      -- keep the llama-server load low enough that typing stays responsive
      debounce = 400,
      throttle = 1000,
      n_completions = 1,
      context_window = 2048,
      provider_options = {
        openai_compatible = {
          -- minuet reads api_key as an env var name (or a function); llama.cpp
          -- needs no key, so return a literal
          api_key = function()
            return "local"
          end,
          name = "llama.cpp",
          end_point = "http://127.0.0.1:8080/v1/chat/completions",
          model = "qwen3.5-4b-q4_k_m",
          optional = {
            max_tokens = 160,
            top_p = 0.9,
            -- Qwen3.5 "thinks" first and would spend every token on
            -- reasoning_content, leaving content empty (no suggestion)
            chat_template_kwargs = { enable_thinking = false },
          },
        },
      },
    })

    require("codecompanion").setup({
      adapters = {
        http = {
          llama_cpp = function()
            return require("codecompanion.adapters").extend("openai_compatible", {
              env = {
                url = "http://127.0.0.1:8080/v1",
                api_key = "local",
              },
              schema = {
                model = { default = "qwen3.5-4b-q4_k_m" },
              },
            })
          end,
        },
      },
      interactions = {
        inline = { adapter = "llama_cpp" },
      },
    })
  '';

  keymaps = [
    {
      mode = [ "n" ];
      key = "<leader>cA";
      action = "<cmd>CodeCompanionActions<cr>";
      options = {
        silent = true;
        desc = "AI actions";
      };
    }
  ];
}
