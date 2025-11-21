#!/bin/zsh
# $1 is JSON if you ever want to parse it
# brew install terminal-notifier

terminal-notifier \
  -title "Codex CLI" \
  -message "Task/turn finished" \
  -group "codex" \
  -activate "com.googlecode.iterm2"
