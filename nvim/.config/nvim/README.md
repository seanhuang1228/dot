# kickstart.nvim

This nvim configuration is base on [Kickstart](https://github.com/nvim-lua/kickstart.nvim). Please check their repo for the basic introduction to the content and structure of this configuration.

## My configuration

### Dependency

- [uncrustify][uncrustify]: for c* auto-formatting, check [Formatting](#formatting) if you don't need it.
- [npm](https://www.npmjs.com/): The dependency for `pylsp`, remove it in `init.lua` and ignore this if you hate python.

### Formatting

This config also use [conform](https://github.com/stevearc/conform.nvim) for auto-formatting files. Base on default config, I use [uncrustify][uncrustify] for c* files, be sure you have installed it if you want to use it too.

You can check `.uncrustify.cfg` in the `/nvim` in the repo for the config.

#### Key bindings

| key | action |
| --- | ------ |
| <Leader>rf | reformat current buffer |

[uncrustify](https://github.com/uncrustify/uncrustify)
