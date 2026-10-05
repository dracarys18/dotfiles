{
  # `git config --global` writes to ~/.gitconfig, which stays a plain local
  # file for machine-specific or tool-written settings
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "dracarys18";
        email = "me@karthihegde.dev";
        signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFHGo84IGTNa1zi4ckKllR3w9/ihV52b3BWEJpitcqME";
      };
      # sign commits with the SSH key in 1Password
      gpg.format = "ssh";
      gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      commit.gpgsign = true;
    };
    ignores = [ "**/.claude/settings.local.json" ];
  };
}
