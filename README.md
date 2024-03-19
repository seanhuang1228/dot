# Dot

## Dependency

- This repo is managed by [Stow](https://www.gnu.org/software/stow/).

## Usage

You can use `stow` to get those dotfiles in the repo by the symbol link. Take the nvim config as an example:

```
stow nvim
```

This command will create the symlinks according to the file structure in the `nvim` directory. If you already have some own config file, try:

```
stow --adopt nvim
```

This will check the confliction between us config, you can remain your own config without doing anything. But you can use something like `git restore` to use my config to replace yours. You can check the document of `stow` to get more information of this option.
