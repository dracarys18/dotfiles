# packages/rust.just — Rust toolchain and cargo tools

# Install rustup + cargo tools
install-rust:
    #!/usr/bin/env bash
    set -euo pipefail

    # Install rustup if not present
    if ! command -v rustup &>/dev/null; then
        echo "Installing rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
        source "$HOME/.cargo/env"
    else
        echo "  skip   rustup (already installed)"
        source "$HOME/.cargo/env" 2>/dev/null || true
    fi

    # ra-multiplex — multiplexes rust-analyzer across projects
    if ! command -v ra-multiplex &>/dev/null; then
        echo "Installing ra-multiplex..."
        cargo install ra-multiplex
    else
        echo "  skip   ra-multiplex (already installed)"
    fi

    echo "Rust tools installed."
