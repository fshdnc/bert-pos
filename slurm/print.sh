#!/bin/bash

# from Devlin et al. 2018 (https://arxiv.org/pdf/1810.04805.pdf), Sec. A.3
# """
# [...] we found the following range of possible values to work well across all tasks:
# * Batch size: 16, 32
# * Learning rate (Adam): 5e-5, 3e-5, 2e-5
# * Number of epochs: 2, 3, 4
# """

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

MODELS="
biBERT80
biBERT70
"

DATA_DIRS="
data/tdt
data/ftb
data/pud
"

SEQ_LENS="512"

BATCH_SIZES="16 20"

LEARNING_RATES="5e-5 3e-5 2e-5"

EPOCHS="2 3 4"

REPETITIONS=3

for repetition in `seq $REPETITIONS`; do
    for seq_len in $SEQ_LENS; do
	for batch_size in $BATCH_SIZES; do
	    for learning_rate in $LEARNING_RATES; do
		for epochs in $EPOCHS; do
		    for model in $MODELS; do
			for data_dir in $DATA_DIRS; do
			    echo $model \
				    $data_dir \
				    $seq_len \
				    $batch_size \
				    $learning_rate \
				    $epochs
			done
		    done
		done
	    done
	done
    done
done
