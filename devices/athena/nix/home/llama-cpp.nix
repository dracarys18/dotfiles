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
        "--alias"
        "qwen3.5-4b-q4_k_m"
        "--ctx-size"
        "8192"
        "--no-ui"
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
