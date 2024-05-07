LC_ALL=C.UTF-8

set -e

source ~/trabajo/env/venv_py3.6_PyTorch1.2_fairseq-0.9.0-efficient-simultaneous_CUDA10.0_Ubuntu20.04/bin/activate
#Execute this script inside the model output folder, in order to quickly clean multiple systems
mv checkpoint_best.pt checkpoint_best_original.pt

python /home/jiranzo/trabajo/git/nmt-scripts/average_checkpoints_scripts/fairseq_average_checkpoints.py --input $PWD --output checkpoint_best.pt \
    --num-update-checkpoints 8

ls | grep -E -v 'checkpoint_best.pt|checkpoint_last.pt|checkpoint_best_original.pt' | xargs rm


