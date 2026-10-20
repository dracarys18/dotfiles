# CodeCompanion, used only for the inline interaction: select code (or put the
# cursor on a word) and run :CodeCompanion <prompt>. The model edits the buffer
# through the edit_file tool and the resulting diff is accepted with g2 /
# rejected with g3. No chat keymaps on purpose.
#
# Backend is the local llama.cpp server (home/llama-cpp.nix): nothing leaves the
# machine and there is no API key. That server must run with --jinja, otherwise
# the model's tool-call template is not loaded and the inline interaction gets
# plain text back with nothing to apply.
{ pkgs, ... }:

{
  extraPlugins = [ pkgs.vimPlugins.codecompanion-nvim ];

  extraConfigLua = ''
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
      mode = [
        "n"
        "v"
      ];
      key = "<leader>ca";
      # trailing space so the prompt is typed on the cmdline
      action = "<cmd>CodeCompanion ";
      options = {
        silent = true;
        desc = "Inline AI edit";
      };
    }
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
