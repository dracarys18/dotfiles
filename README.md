# dotfiles

## Fresh Mac

```sh
xcode-select --install   # wait for it to finish
git clone https://github.com/dracarys18/dotfiles.git ~/dotfiles && cd ~/dotfiles
make bootstrap-mac
```

## Update

```sh
make switch   # apply changes made in the repo
make update   # update packages, nvim plugins and treesitter, then switch
```

`make` lists the rest.
