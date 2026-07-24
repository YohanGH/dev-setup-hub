//! `halo` — the command-line entry point.
//!
//! Parses arguments, loads configuration and starts the daemon run loop.
//! Running `halo` with no arguments launches the HUD immediately.

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

#[derive(Debug, Subcommand)]
enum Command {
    /// Launch the HUD overlay (default when no subcommand is given).
    Run,
    /// Print the effective configuration and exit.
    Config,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
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

    match cli.command.unwrap_or(Command::Run) {
        Command::Run => halo_daemon::run(config).await?,
        Command::Config => println!("{config:#?}"),
    }

    Ok(())
}
