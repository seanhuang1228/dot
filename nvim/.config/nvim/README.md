# kickstart.nvim

This nvim configuration is base on [Kickstart](https://github.com/nvim-lua/kickstart.nvim). Please check their repo for the basic introduction to the content and structure of this configuration.

## My configuration

### Dependency

- [uncrustify][uncrustify]: for c* auto-formatting, check [Formatting](#formatting) if you don't need it.
- [npm](https://www.npmjs.com/): The dependency for `pylsp`, remove it in `init.lua` and ignore this if you hate python.
- [rust](https://www.rust-lang.org/): The dependency for [nvim-silicon](#Code Snapshot).

### Formatting

This config also use [conform](https://github.com/stevearc/conform.nvim) for auto-formatting files. Base on default config, I use [uncrustify][uncrustify] for c* files, be sure you have installed it if you want to use it too.

You can check `.uncrustify.cfg` in the `/nvim` in the repo for the config, or just find this plugin in `init.lua` and remove the config for c*

#### Key bindings

| key | action |
| --- | ------ |
| \<Leader\>rf | reformat current buffer |

### Code Snapshot

I use [silicon-nvim][silicon-nvim] to generate the code snapshot. The advantage is that you can do it without mouse and provide enough custom setting. The config file is in the `silicon.lua` in the custom plugin directory.

#### Key bindings

| key | action |
| --- | ------ |
| \<Leader\>ms | take a snapshot for the codes selected in visual mode |

### Markdown

I use [markdown-preview][markdown-preview] to preview markdown file. Config file is in the `markdown.lua` ins the custom plugin directory.

#### Key bindings

| key | action |
| --- | ------ |
| \<Leader\>mm | toggle markdown preview |


[uncrustify]: https://github.com/uncrustify/uncrustify
[silicon-nvim]: https://github.com/michaelrommel/nvim-silicon
[markdown-preview]: https://github.com/iamcco/markdown-preview.nvim
