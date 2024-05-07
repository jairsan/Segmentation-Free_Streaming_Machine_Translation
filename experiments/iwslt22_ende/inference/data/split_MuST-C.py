import sys
import yaml
import os
from typing import Dict, List

def split(file_fp: str, yaml_fp: str, output_folder: str):
    os.makedirs(output_folder, exist_ok=True)
    with open(file_fp) as file_to_split, open(yaml_fp) as yaml_file:
        files_dict: Dict[str, List[str]] = {}
        yaml_obj = yaml.safe_load(yaml_file)
        for src_line, yaml_line in zip(file_to_split, yaml_obj):
            wav_lines = files_dict.get(yaml_line["wav"], None)
            if wav_lines is None:
                wav_lines = []
            wav_lines.append(src_line.strip())
            files_dict[yaml_line["wav"]] = wav_lines
    prefix_name = ".".join(file_fp.split("/")[-1].split(".")[:-1])

    for wav in list(files_dict.keys()):
        with open(output_folder + "/" + prefix_name + "." + wav + "." + file_fp.split("/")[-1].split(".")[-1], "w") as outf:
            for line in files_dict[wav]:
                print(line, file=outf)

if __name__ == "__main__":
    split(sys.argv[1], sys.argv[2], sys.argv[3])
