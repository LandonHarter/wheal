use std::{fs, path::PathBuf};

pub fn list_files(dir: &PathBuf, recursive: bool) -> std::io::Result<Vec<PathBuf>> {
    let paths = fs::read_dir(dir).unwrap();
    let mut files = vec![];
    
    for path in paths {
        let buf = path.unwrap().path();
        
        if recursive && buf.is_dir() {
            let mut sub_files = list_files(&buf, true).unwrap();
            files.append(&mut sub_files);
        } else if !buf.is_dir() {
            files.push(buf);
        }
    }

    Ok(files)
}
