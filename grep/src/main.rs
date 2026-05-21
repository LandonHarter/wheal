use std::{env};

use clap::Parser;
use colored::Colorize;

mod files;
mod matcher;

#[derive(Parser, Debug)]
struct Args {
    // flags
    #[arg(short, long)]
    recursive: bool,
    
    #[arg(short, long)]
    ignore_case: bool,

    // required args
    pattern: String,
    file: String,
}

fn main() -> std::io::Result<()> {
    let args = Args::parse();
    let mut cwd = env::current_dir()?;
    if  args.file != "*" {
        cwd.push(args.file);
    }

    let searchable_files = files::list_files(&cwd.to_path_buf(), args.recursive).unwrap();

    let mut pattern = args.pattern;
    if args.ignore_case {
        pattern = pattern.to_lowercase();
    }

    for file in searchable_files {
        let matches = matcher::find_matches(&file, &pattern);
        
        for line in matches {
            let parts: Vec<&str> = line.split(&pattern).collect();

            print!("{}: ", file.display());
            for part_index in 0..parts.len() {
                print!("{}{}", parts[part_index], if part_index < parts.len() - 1 { pattern.red() } else { "".red() });
            }
            println!();
        }
    }

    Ok(())
}
