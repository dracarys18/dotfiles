# dotfiles

## Fresh Mac

```sh
xcode-select --install   # wait for it to finish
git clone https://github.com/dracarys18/dotfiles.git ~/dotfiles && cd ~/dotfiles
curl -sSf https://just.systems/install.sh | bash -s -- --to /tmp/just
/tmp/just/just bootstrap mac
```

## Update

```sh
just switch   # apply changes made in the repo
just update   # update packages, nvim plugins and treesitter, then switch
```

`just` lists the rest.
