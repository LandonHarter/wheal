use std::{fs, path::PathBuf};

pub fn find_matches(file: &PathBuf, pattern: &String) -> Vec<String> {
    let mut matches = vec![];
    let content_result = fs::read_to_string(&file);
    if content_result.is_err() {
        return matches;
    }
    let content = content_result.unwrap();
    let lines = content.lines();

    for line in lines {
        if line.contains(pattern) {
            matches.push(line.to_string());
        }
    }

    return matches;
}
