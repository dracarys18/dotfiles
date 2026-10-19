{ config, ... }:

{
  plugins.treesitter = {
    enable = true;
    # starts highlighting on every FileType that has a parser
    highlight.enable = true;
    indent.enable = false;
    folding.enable = false;
    # prebuilt by Nix: no :TSUpdate, no compiler at runtime
    grammarPackages = with config.plugins.treesitter.package.builtGrammars; [
      bash
      c
      cmake
      cpp
      css
      fish
      go
      gomod
      gowork
      html
      json
      lua
      make
      markdown
      markdown_inline
      ocaml
      python
      rust
      terraform
      toml
      typescript
      typst
      vim
      yaml
      zig
    ];
  };

  # custom markdown injections (code fences, front matter, inline)
  extraFiles."queries/markdown/injections.scm".source = ../queries/markdown/injections.scm;
}
