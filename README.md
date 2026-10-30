# Katapult

A one-page redirector: it throws the browser at whatever URL comes after the
`#`, any scheme included. Useful where only `https` links are clickable but
the destination is an app (`obsidian://`, `things://`, `claude://`…).

```
https://kelvinst.github.io/katapult/#<url-encoded target>
```

The target lives in the fragment, so it never reaches the server. For app
schemes the tab closes itself right after launching, where the browser
allows it. Script-ish schemes (`javascript:`, `data:`,
`vbscript:`, `blob:`, `file:`) are refused.

## Install

The `katapult` command and the Hammerspoon spoon ship together.

With [Homebrew](https://brew.sh):

```sh
brew tap kelvinst/katapult https://github.com/kelvinst/katapult
brew install kelvinst/katapult/katapult
```

With [mise](https://mise.jdx.dev):

```sh
mise use -g github:kelvinst/katapult
```

`katapult` needs `python3` on the PATH (macOS ships one).

## `katapult`: print Katapult links

```sh
katapult 'obsidian://open?vault=Notes&file=Inbox'
# https://kelvinst.github.io/katapult/#obsidian%3A%2F%2Fopen%3Fvault%3DNotes%26file%3DInbox

katapult note Notes Inbox 'Projects#Next steps'
# [Inbox](https://kelvinst.github.io/katapult/#…)
# [Projects › Next steps](https://kelvinst.github.io/katapult/#…)
```

`katapult <uri>...` prints one Katapult URL per URI. `katapult note <vault>
<name>[#heading]...` prints a Markdown link per Obsidian note, opening it in a
new tab.

## katapult-spoon: open Katapult links without the page

On a Mac, `katapult-spoon.lua` makes Hammerspoon the handler of every http(s)
link, so a Katapult link never loads the page: Hammerspoon unwraps the target
and opens it itself, offline included.

- `obsidian://` opens the note in a new tab of Obsidian's main window,
  focusing it on whichever [AeroSpace](https://github.com/nikitabobko/AeroSpace)
  workspace it lives.
- `http(s)://` goes to the browser, unwrapped.
- A scheme in `trusted_schemes`, and a `file://` link to a file under one of
  `trusted_paths`, open straight away; anything else asks first, in an alert
  that shows the URI (Cancel is the default). A file `open` would run rather
  than show — an app, a script, anything executable — always asks.
- Every other link goes to the browser too, into a window on the focused
  workspace rather than whichever one the browser focused last.

It needs [Hammerspoon](https://www.hammerspoon.org), AeroSpace and Google
Chrome (`BROWSER_BUNDLE_ID` names the browser).

### Setup

1. Load it from `~/.hammerspoon/init.lua`, into a global — it keeps running
   tasks that a local would let Lua collect. Point `package.path` at where
   the package manager put it:

   ```lua
   require("hs.ipc") -- lets the `hs` CLI talk to Hammerspoon
   -- Homebrew:
   package.path = package.path .. ";/opt/homebrew/opt/katapult/share/katapult/?.lua"
   -- mise: the folder `mise where github:kelvinst/katapult` prints, plus /share/katapult
   katapult = require("katapult-spoon")
   ```

   Without a package manager, copy `katapult-spoon.lua` into `~/.hammerspoon/`
   and skip the `package.path` line.

2. Reload Hammerspoon, then make it the default handler for http and https
   (macOS asks to confirm):

   ```sh
   hs -c 'hs.urlevent.setDefaultHandler("http")'
   ```

3. Optionally, trust schemes you click often, and folders whose files
   `file://` links may open, in `~/.config/katapult/config.json`
   (`$XDG_CONFIG_HOME/katapult/config.json` when that is set):

   ```json
   {
     "trusted_schemes": ["x-things"],
     "trusted_paths": ["~/Notes", "/private/tmp/claude-501"]
   }
   ```

   It is read on every click, so an edit applies without reloading
   Hammerspoon; a file that does not parse trusts nothing and raises an alert.
   A trusted path covers everything below it, with symlinks resolved (`/tmp`
   is `/private/tmp`). The same lists can also be filled from `init.lua`,
   after the `require`:

   ```lua
   katapult.trusted_schemes["x-things"] = true
   table.insert(katapult.trusted_paths, "~/Notes")
   ```

## Tests

```sh
bash test/katapult-test.sh
bash test/katapult-spoon-test.sh
```

The spoon's tests load it under a stub `hs`, so nothing opens. They need
`lua` or `luajit` on the PATH.

## Releasing

```sh
script/release 0.2.0
```

Builds the tarball Homebrew and mise install from, points
`Formula/katapult.rb` at it, tags, pushes and uploads it to a GitHub release.
