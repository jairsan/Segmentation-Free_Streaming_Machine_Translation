import sys
import yaml
import os
from typing import Dict, List

def split(file_fp: str, segments_fp: str, output_folder: str):
    os.makedirs(output_folder, exist_ok=True)
    with open(file_fp) as file_to_split, open(segments_fp) as segments_file:
        files_dict: Dict[str, List[str]] = {}
        for src_line, segments_line in zip(file_to_split, segments_file):
            video=segments_line.strip().split()[0]
            wav_lines = files_dict.get(video, None)
            if wav_lines is None:
                wav_lines = []
            wav_lines.append(src_line.strip())
            files_dict[video] = wav_lines
    prefix_name = ".".join(file_fp.split("/")[-1].split(".")[:-1])

    for wav in list(files_dict.keys()):
        with open(output_folder + "/" + prefix_name + "." + wav + "." + file_fp.split("/")[-1].split(".")[-1], "w") as outf:
            for line in files_dict[wav]:
                print(line, file=outf)

if __name__ == "__main__":
    split(sys.argv[1], sys.argv[2], sys.argv[3])
