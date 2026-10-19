{
  plugins.telescope = {
    enable = true;
    settings.defaults.initial_mode = "insert";
    extensions = {
      fzf-native = {
        enable = true;
        settings = {
          fuzzy = true;
          override_generic_sorter = true;
          override_file_sorter = true;
          case_mode = "smart_case";
        };
      };
      ui-select.enable = true;
    };
  };
}
