use std::path::PathBuf;

use crate::files;

pub struct MatchResult {
    pub file: PathBuf,
    pub content: String
}

pub fn find_matches(file: PathBuf, pattern: &String) -> Vec<MatchResult> {
    let content = files::read_file(&file).unwrap();
    let lines = content.lines();

    let mut matches = vec![];

    for line in lines {
        if line.contains(pattern) {
            let match_result = MatchResult {
                file: file.clone(),
                content: line.to_string()
            };
            matches.push(match_result);
        }
    }

    return matches;
}
