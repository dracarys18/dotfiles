# settings.nix denies `rm -rf` outright, which also stopped the agent from
# clearing scratch files. A before_tool hook runs before the policy and
# overrides it, so allow it when every target is under /tmp (and nothing can
# climb out with `..`); anything else falls through to the deny rule.
{ ... }:

{
  programs.uji.pluginFiles.policy = ''
    uji.on("before_tool", function(call)
      if call.name ~= "run_command" and call.name ~= "Bash" then
        return nil
      end
      local command = call.arguments.command or ""
      local rest = command:match("^%s*rm%s+%-rf%s*(.*)$")
      if not rest then
        return nil
      end
      local targets = 0
      for token in rest:gmatch("%S+") do
        if token:sub(1, 1) ~= "-" then
          if token:find("%.%.") or (token ~= "/tmp" and token:sub(1, 5) ~= "/tmp/") then
            return nil
          end
          targets = targets + 1
        end
      end
      if targets == 0 then
        return nil
      end
      return { allow = true }
    end, { priority = 10 })
  '';
}
