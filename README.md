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

## katapult-spoon: open Katapult links without the page

On a Mac, `katapult-spoon.lua` makes Hammerspoon the handler of every http(s)
link, so a Katapult link never loads the page: Hammerspoon unwraps the target
and opens it itself, offline included.

- `obsidian://` opens the note in an Obsidian window on the focused
  [AeroSpace](https://github.com/nikitabobko/AeroSpace) workspace, in a new
  tab (a new window when that workspace has none).
- `http(s)://` goes to the browser, unwrapped.
- A scheme listed in `TRUSTED_SCHEMES` opens straight away; any other one asks
  first, in an alert that shows the URI (Cancel is the default).
- Every other link goes to the browser too, into a window on the focused
  workspace rather than whichever one the browser focused last.

It needs [Hammerspoon](https://www.hammerspoon.org), AeroSpace and Google
Chrome (`BROWSER_BUNDLE_ID` names the browser).

### Install

1. Copy the file into Hammerspoon's config:

   ```sh
   cp katapult-spoon.lua ~/.hammerspoon/
   ```

2. Load it from `~/.hammerspoon/init.lua`, into a global — it keeps running
   tasks that a local would let Lua collect:

   ```lua
   require("hs.ipc") -- lets the `hs` CLI talk to Hammerspoon
   katapult = require("katapult-spoon")
   ```

3. Reload Hammerspoon, then make it the default handler for http and https
   (macOS asks to confirm):

   ```sh
   hs -c 'hs.urlevent.setDefaultHandler("http")'
   ```

4. Optionally, trust schemes you click often, so they open without asking:

   ```lua
   local TRUSTED_SCHEMES = { ["x-things"] = true }
   ```

### Tests

```sh
bash test/katapult-spoon-test.sh
```

They load the file under a stub `hs`, so nothing opens. They need `lua` or
`luajit` on the PATH.
