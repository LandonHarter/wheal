use std::env;

use clap::Parser;

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
    cwd.push(args.file);
    let searchable_files = files::list_files(&cwd.to_path_buf(), args.recursive).unwrap();

    let mut pattern = args.pattern;
    if args.ignore_case {
        pattern = pattern.to_lowercase();
    }

    let mut all_matches = vec![];
    for file in searchable_files {
        let mut matches = matcher::find_matches(file, &pattern);
        all_matches.append(&mut matches);
    }

    for mat in all_matches {
        println!("{}: {}", mat.file.display(), mat.content);
    }

    Ok(())
}
