use std::{fs::{self},path::PathBuf};

pub fn list_files(dir: &PathBuf, recursive: bool) -> std::io::Result<Vec<PathBuf>> {
    let mut files = vec![];

    if dir.is_dir() {
        let paths = fs::read_dir(dir).unwrap();
        for path in paths {
            let buf = path.unwrap().path();
         
            if recursive && buf.is_dir() {
                let mut sub_files = list_files(&buf, true).unwrap();
                files.append(&mut sub_files);
            } else if !buf.is_dir() {
                files.push(buf);
            }
        }
    } else {
        files.push(dir.clone());
    }

    Ok(files)
}
