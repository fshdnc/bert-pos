#!/usr/bin/env bash

LST='/scratch/project_2002820/lihsin/bert-pos/delme.unrun'

#for batch in 16 20; do
#    for model in biBERT70 biBERT80; do
#	for epoch in '[23]$' '4$'; do
for batch in 20; do
    for model in biBERT70; do
	for epoch in '4$'; do
#	    cat $LST | grep -P '\t'$batch'\t' | grep $model | grep $epoch | wc -l
	    sbatch batch-dev-pos.sh $LST $batch $model $epoch
	    sleep 5
	done
    done
done
