# Katapult

A one-page redirector: it throws the browser at whatever URL comes after the
`#`, any scheme included. Useful where only `https` links are clickable but
the destination is an app (`obsidian://`, `things://`, `claude://`…).

```
https://kelvinst.github.io/katapult/#<url-encoded target>
```

The target lives in the fragment, so it never reaches the server. Script-ish
schemes (`javascript:`, `data:`, `vbscript:`, `blob:`, `file:`) are refused.
