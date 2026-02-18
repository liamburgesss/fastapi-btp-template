import zipfile
import os
import sys

def zip_files(output_filename, source_paths):
    # 'w' mode truncates the file if it exists, use 'a' to append
    # zipfile.ZIP_DEFLATED is the standard compression method
    with zipfile.ZipFile(output_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:

        for path in source_paths:
            if not os.path.exists(path):
                print(f"⚠️  Warning: '{path}' does not exist. Skipping.")
                continue

            # If it's a file, just write it
            if os.path.isfile(path):
                # arcname ensures we don't store the full absolute path structure inside the zip
                zipf.write(path, arcname=os.path.basename(path))
                print(f"Added file: {path}")

            # If it's a directory, walk through it recursively
            elif os.path.isdir(path):
                print(f"Processing folder: {path}...")
                for root, dirs, files in os.walk(path):
                    for file in files:
                        file_path = os.path.join(root, file)
                        # Create a relative path for inside the zip to keep structure clean
                        # This removes the parent directories from the zip structure
                        arcname = os.path.relpath(file_path, os.path.dirname(path))
                        zipf.write(file_path, arcname=arcname)

    print(f"✅ Successfully created {output_filename}")

if __name__ == "__main__":
    zip_files("deploy.zip", [
        "./../main.py",
        "./../requirements.txt",
        "./../services",
        "./../env_models",
        "./../manifest.yml",
        "./../Procfile"
    ])