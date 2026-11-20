# Recipe: CLI tool

- **Build:** the repo's build command (`go build -o /tmp/<tool> ./cmd/<tool>`, `npm run build`), so you
  test the binary users get, not `go run`.
- **Drive:** run real commands against a temp workspace (`mktemp -d`), never the user's real config or data.
  Point config/home at the temp dir (`HOME=$tmp`, `XDG_CONFIG_HOME=$tmp`, a `--config` flag).
- **Observe:** exit code (`echo $?`), stdout/stderr separately, files written in the temp dir.
- **Golden checks:** for each command in the map, record the command and the expected exit code and key
  output lines; compare with `diff <(cmd) expected.txt` when the output is stable.
- **Interactive TUIs:** drive them in a tuios or tmux pane (`tuios send-keys`, `tmux send-keys`) and read the
  pane text, rather than guessing from the code.
