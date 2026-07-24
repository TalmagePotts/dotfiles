# systemd user units

These are **copied** into `~/.config/systemd/user/`, never stowed.

That is not a style preference. systemd treats any symlink it finds in a unit
search path as an *enablement* link rather than a unit file, so
`systemctl --user disable <unit>` deletes the symlink outright — silently
unlinking the file from your dotfiles repo and leaving the unit undiscoverable
(`Unit foo.service does not exist`). Stowing units works right up until the
first time you disable one, which is a miserable way to find out.

`install.sh --with-clipsync` handles the copy. To update a unit by hand after
editing it here:

```sh
cp services/clipsync.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user reenable clipsync
```

Because these are copies, `check.sh` does not track them — edits made directly
in `~/.config/systemd/user/` will not show up as repo drift. Edit the copy in
this directory and re-run the commands above.
