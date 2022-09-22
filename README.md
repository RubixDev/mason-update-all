# mason-update-all
Easily update all [Mason](https://github.com/williamboman/mason.nvim) packages with one command.

## Table of Contents
* [Requirements](#requirements)
* [Installation](#installation)
  * [Packer](#packer)
  * [vim-plug](#vim-plug)
* [Setup](#setup)
* [Commands](#commands)
* [Events](#events)
* [Updating from CLI](#updating-from-cli)

## Requirements
- [`mason.nvim`](https://github.com/williamboman/mason.nvim)

## Installation
### [Packer](https://github.com/wbthomason/packer.nvim)
```lua
use { 'RubixDev/mason-update-all' }
```

### [vim-plug](https://github.com/junegunn/vim-plug)
```vim
Plug 'RubixDev/mason-update-all'
```

## Setup
```lua
require('mason-update-all').setup()
```

## Commands
- `:MasonUpdateAll` — update all installed Mason packages

## Events
Upon completion of all updates the user event `MasonUpdateAllComplete` will be emitted. You can use it like so:

```lua
vim.api.nvim_create_autocmd('User', {
    pattern = 'MasonUpdateAllComplete',
    callback = function()
        print('mason-update-all has finished')
    end,
})
```

or in VimScript:

```vim
autocmd User MasonUpdateAllComplete echo 'mason-update-all has finished'
```

## Updating from CLI
Using the provided vim command and user event, it is possible to update the Mason packages from the command line or shell scripts.

```bash
# Update Packer plugins
nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

# Update Mason packages
nvim --headless -c 'autocmd User MasonUpdateAllComplete quitall' -c 'MasonUpdateAll'
```
