#!/usr/bin/env bash

LST='/scratch/project_2002820/lihsin/bert-pos/slurm/selected-params.tsv'
REPETITION=10

cat $LST | while read l; do
    model=$(echo "$l" | cut -f 2)
    data_dir=$(echo "$l" | cut -f 4)
    seq_len=$(echo "$l" | cut -f 6)
    batch_size=$(echo "$l" | cut -f 8)
    learning_rate=$(echo "$l" | cut -f 10)
    epochs=$(echo "$l" | cut -f 12)
    sbatch batch-test-pos.sh $model $data_dir $seq_len $batch_size $learning_rate $epochs $REPETITION
    sleep 5
done
