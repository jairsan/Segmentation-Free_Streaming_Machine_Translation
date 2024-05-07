LC_ALL=C.UTF-8


#Execute this script inside the model output folder, in order to quickly clean multiple systems

set -e

ls | grep -E -v 'checkpoint_best.pt|checkpoint_last.pt|checkpoint_best_original.pt' | xargs rm


