{ config, ... }:

{
  plugins.treesitter = {
    enable = true;
    highlight.enable = true;
    indent.enable = false;
    folding.enable = false;
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

  extraFiles."queries/markdown/injections.scm".source = ../queries/markdown/injections.scm;
}
