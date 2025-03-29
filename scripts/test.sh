#!/bin/sh

# RUSTFLAGS="-Zproc-macro-backtrace" cargo test -p experiment --color=always 2>&1 | less -R +F
# cargo test -p ceylon --color=always 2>&1 | less -R +F
RUST_BACKTRACE=1 cargo run --color=always 2>&1 | less -R +F 
