#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 DIR"
    echo "where DIR is the path to where the venv will be located"
    exit 1
fi

set -euo pipefail

DEST="$1"

cd $DEST

module purge
module load tensorflow/1.14.0
python3 -m venv bert-pos
source bert-pos/bin/activate
pip install keras_bert

echo "venv bert-pos created at $DEST"
echo "If there are module import issues using venvs on puhti, read this source code."

### NOTE: the following may have to be added to the python code
#import sys
## '/appl/soft/ai/miniconda3/envs/tensorflow-1.14.0/lib/python3.7' is searched but this one has to be appended otherwise it doesn't work :/
#sys.path.append('/appl/soft/ai/miniconda3/envs/tensorflow-1.14.0/lib/python3.7/site-packages/')
