//! `halo` — the command-line entry point.
//!
//! Parses arguments, loads configuration and dispatches to the daemon. Running
//! `halo` with no arguments launches the default HUD.
//!
//! `main` is intentionally synchronous: the overlay backend drives a `winit`
//! event loop that must own the process main thread, so the async run loop is
//! entered explicitly via a Tokio runtime only when needed.

use std::path::PathBuf;

use anyhow::Context;
use clap::{Parser, Subcommand};
use halo_config::Config;

/// Lightweight system HUD overlay.
#[derive(Debug, Parser)]
#[command(name = "halo", version, about)]
struct Cli {
    /// Path to a `config.toml`. Falls back to built-in defaults when omitted.
    #[arg(short, long, global = true)]
    config: Option<PathBuf>,

    #[command(subcommand)]
    command: Option<Command>,
}

#[derive(Debug, Default, Subcommand)]
enum Command {
    /// Run the terminal HUD: sample the system and print each tick.
    #[default]
    Run,
    /// Launch the transparent overlay window (requires a desktop session).
    #[cfg(feature = "overlay")]
    Overlay,
    /// Print the effective configuration and exit.
    Config,
}

fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()),
        )
        .init();

    let cli = Cli::parse();

    let config = match &cli.config {
        Some(path) => {
            Config::load(path).with_context(|| format!("loading config from {}", path.display()))?
        }
        None => Config::default(),
    };

    match cli.command.unwrap_or_default() {
        Command::Run => run_async(halo_daemon::run(config))?,
        #[cfg(feature = "overlay")]
        Command::Overlay => halo_daemon::run_overlay(config)?,
        Command::Config => println!("{config:#?}"),
    }

    Ok(())
}

/// Drive an async task to completion on a fresh multi-threaded runtime.
fn run_async<F: std::future::Future<Output = anyhow::Result<()>>>(fut: F) -> anyhow::Result<()> {
    tokio::runtime::Runtime::new()
        .context("building Tokio runtime")?
        .block_on(fut)
}
