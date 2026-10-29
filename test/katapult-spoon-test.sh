#!/usr/bin/env bash
# Regression tests for katapult-spoon.lua.
#
# Loads it under a stub `hs` that records which app each click goes to
# instead of starting a task, so nothing opens.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LUA=${LUA:-$(command -v lua || command -v luajit)}

# Real files for the file:// cases: hs.fs below answers from the disk.
files=$(mktemp -d)
trap 'rm -rf "$files"' EXIT
mkdir -p "$files/trusted/sub" "$files/trusted/Tool.app" "$files/other" \
  "$files/trusted-not"
touch "$files/trusted/sub/page.html" "$files/trusted/run.command" \
  "$files/trusted/my file.md" "$files/other/page.html" \
  "$files/trusted-not/page.html"
printf '#!/bin/sh\n' >"$files/trusted/script"
chmod +x "$files/trusted/script"
ln -s "$files/trusted" "$files/link"

"$LUA" - "$ROOT" "$files" <<'LUA'
package.path = arg[1] .. "/?.lua;" .. package.path
local files = arg[2]

local function sh(cmd)
  local out = io.popen(cmd):read("*a"):gsub("\n$", "")
  return out ~= "" and out or nil
end

local function quote(text)
  return "'" .. text:gsub("'", "'\\''") .. "'"
end

local started, answer, asked
hs = {
  urlevent = {},
  focus = function() end,
  fs = {
    pathToAbsolute = function(path)
      path = path:gsub("^~", os.getenv("HOME"))
      return sh("realpath " .. quote(path) .. " 2>/dev/null")
    end,
    attributes = function(path)
      local out = sh("stat -f '%HT|%Sp' " .. quote(path) .. " 2>/dev/null")
      if not out then
        return nil
      end
      local kind, permissions = out:match("^(.-)|(.*)$")
      return {
        mode = kind == "Directory" and "directory" or "file",
        permissions = permissions:sub(2),
      }
    end,
  },
  dialog = {
    blockAlert = function(_, target)
      asked = target
      return answer
    end,
  },
  task = {
    new = function(_, _, args)
      started = { bundle = args[4], url = args[5] }
      return { start = function() end }
    end,
  },
}
local katapult = require("katapult-spoon")

local K = "https://kelvinst.github.io/katapult/#"
local failures = 0

local function click(url, reply)
  started, asked, answer = nil, nil, reply
  hs.urlevent.httpCallback("https", nil, nil, url)
end

local function expect(name, ok)
  print((ok and "ok   " or "FAIL ") .. name)
  if not ok then
    failures = failures + 1
  end
end

click(K .. "obsidian%3A%2F%2Fopen%3Fvault%3DStingdom%26file%3DRoutines")
expect(
  "obsidian:// goes to Obsidian, unwrapped, without asking",
  started.bundle == "md.obsidian"
    and started.url == "obsidian://open?vault=Stingdom&file=Routines"
    and not asked
)

click(K .. "https%3A%2F%2Fexample.com%2Fa%3Fb%3D1")
expect(
  "https:// goes to the browser, unwrapped",
  started.bundle == "com.google.Chrome"
    and started.url == "https://example.com/a?b=1"
    and not asked
)

click(K .. "x-things%3A%2F%2Fshow%3Fid%3Dtoday", "Open")
expect(
  "another scheme asks, then opens",
  asked == "x-things://show?id=today"
    and started.bundle == ""
    and started.url == "x-things://show?id=today"
)

katapult.trusted_schemes["x-things"] = true
click(K .. "x-things%3A%2F%2Fshow", "Cancel")
expect(
  "a trusted scheme opens without asking",
  not asked and started.url == "x-things://show"
)
katapult.trusted_schemes["x-things"] = nil

click(K .. "shortcuts%3A%2F%2Frun-shortcut%3Fname%3Dx", "Cancel")
expect("another scheme declined opens nothing", asked and not started)

local function file_link(path)
  local uri = "file://" .. path:gsub(" ", "%%20")
  return K .. uri:gsub("[^%w._~-]", function(c)
    return string.format("%%%02X", c:byte())
  end)
end

table.insert(katapult.trusted_paths, files .. "/link")

click(file_link(files .. "/trusted/sub/page.html"), "Cancel")
expect(
  "a file under a trusted path opens without asking",
  not asked and started and started.url == "file://" .. files .. "/trusted/sub/page.html"
)

click(file_link(files .. "/trusted/my file.md"), "Cancel")
expect("a percent-encoded name under a trusted path opens", not asked and started)

click(file_link(files .. "/other/page.html"), "Cancel")
expect("a file outside the trusted paths asks", asked and not started)

click(file_link(files .. "/trusted/../other/page.html"), "Cancel")
expect("climbing out of a trusted path with .. asks", asked and not started)

click(file_link(files .. "/trusted-not/page.html"), "Cancel")
expect("a sibling sharing the prefix asks", asked and not started)

click(file_link(files .. "/trusted/run.command"), "Cancel")
expect("a launched extension under a trusted path asks", asked and not started)

click(file_link(files .. "/trusted/script"), "Cancel")
expect("an executable under a trusted path asks", asked and not started)

click(file_link(files .. "/trusted/Tool.app"), "Cancel")
expect("an app bundle under a trusted path asks", asked and not started)

click(K .. "file%3A%2F%2Fexample.com" .. files:gsub("/", "%%2F") .. "%2Ftrusted%2Fsub%2Fpage.html", "Cancel")
expect("a file:// on another host asks", asked and not started)

katapult.trusted_paths[1] = nil

click(K .. "not%20a%20uri")
expect(
  "a target with no scheme goes to the browser as it came",
  started.bundle == "com.google.Chrome" and started.url == K .. "not%20a%20uri"
)

click("https://example.com/")
expect(
  "a plain link goes to the browser",
  started.bundle == "com.google.Chrome"
    and started.url == "https://example.com/"
)

if failures > 0 then
  print(failures .. " failure(s)")
  os.exit(1)
end
print("all passed")
LUA
