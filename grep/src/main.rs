use std::env;

use clap::Parser;

mod files;

#[derive(Parser, Debug)]
struct Args {
    // flags
    #[arg(short, long)]
    recursive: bool,

    // required args
    pattern: String,
    file: String,
}

fn main() -> std::io::Result<()> {
    let args = Args::parse();
    let cwd = env::current_dir()?;
    let searchable_files = files::list_files(&cwd.to_path_buf(), args.recursive);

    for file in searchable_files.unwrap() {
        println!("Searching file {}", file.display());
    }

    Ok(())
}
