# llama.cpp server for local agents: one OpenAI-compatible endpoint on
# 127.0.0.1:8080, the model resident, and the server sleeping (model unloaded)
# after 30 minutes idle — the next request reloads it.
#
# The GGUF is pinned in Nix, so `make switch` fetches it once (~2.7 GB) and the
# store keeps it; bump url + hash to move to a new build. Keeping the file
# outside the store instead is just a matter of pointing -m at a plain path.
{ pkgs, ... }:

let
  user = "karthihegde";
  model = pkgs.fetchurl {
    name = "Qwen3.5-4B-Q4_K_M.gguf";
    url = "https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/main/Qwen3.5-4B-Q4_K_M.gguf";
    hash = "sha256-AP55hv9fa0Y+YkVYIRRgSdtvkxNgOTinCADR+2nvEaQ=";
  };
in
{
  home.packages = [ pkgs.llama-cpp ];

  launchd.agents.llama-cpp = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.llama-cpp}/bin/llama-server"
        "-m"
        "${model}"
        "--host"
        "127.0.0.1"
        "--port"
        "8080"
        # the API's model id this otherwise the store filename
        "--alias"
        "qwen3.5-4b-q4_k_m"
        "--ctx-size"
        "8192"
        "--no-ui" # this build deprecates --no-webui in favour of --no-ui
        # tool calling: CodeCompanion's inline interaction edits the buffer
        # through the edit_file tool, which needs the model's tool template
        "--jinja"
        "--sleep-idle-seconds"
        "1800"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/Users/${user}/Library/Logs/llama-cpp.log";
      StandardErrorPath = "/Users/${user}/Library/Logs/llama-cpp.log";
    };
  };
}
