#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=6G
#SBATCH -p gpu
#SBATCH -t 72:00:00
#SBATCH --gres=gpu:v100:1
#SBATCH --ntasks-per-node=1
#SBATCH --account=Project_2002820
#SBATCH -o /scratch/project_2002820/lihsin/bert-pos/logs/batch-%j.out
#SBATCH -e /scratch/project_2002820/lihsin/bert-pos/logs/batch-%j.err

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 LIST_PATH BATCH_SIZE MODEL EPOCH"
    exit 1
fi

SCRIPTDIR="/scratch/project_2002820/lihsin/bert-pos/scripts"
cd /scratch/project_2002820/lihsin/bert-pos

module purge
module load tensorflow
source /projappl/project_2002820/venv/bert-pos/bin/activate

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
#echo "Task: bert-pos; Model: $MODEL_NAME; Data: $(basename $DATA_DIR); Max sequence length: $MAX_SEQ_LENGTH; Batch size: $BATCH_SIZE; Learning rate: $LEARNING_RATE; Epoch: $EPOCHS"
echo "START $SLURM_JOBID: $(date)"

# l in the form of `biBERT80        data/ftb        512     16      5e-5    2`
cat "$1" | grep -P '\t'"$2"'\t' | grep "$3" | grep "$4" | while read l; do
    MODEL_NAME=$(echo "$l" | cut -f 1)
    DATA_DIR=$(echo "$l" | cut -f 2)
    MAX_SEQ_LENGTH=$(echo "$l" | cut -f 3)
    BATCH_SIZE=$(echo "$l" | cut -f 4)
    LEARNING_RATE=$(echo "$l" | cut -f 5)
    EPOCHS=$(echo "$l" | cut -f 6)
    echo '------------------------NEW RUN-------------------------'
    echo '------------------------NEW RUN-------------------------' >&2
    echo -ne "Model: $MODEL_NAME\tData: $DATA_DIR\tSeq length: $MAX_SEQ_LENGTH\t"
    echo -e "Batch size: $BATCH_SIZE\tLearning rate: $LEARNING_RATE\tEpoch: $EPOCHS"
    echo -ne "Model: $MODEL_NAME\tData: $DATA_DIR\tSeq length: $MAX_SEQ_LENGTH\t" >&2
    echo -e "Batch size: $BATCH_SIZE\tLearning rate: $LEARNING_RATE\tEpoch: $EPOCHS" >&2

    # returns MODELDIR and MODEL
    source /scratch/project_2002820/lihsin/bert-experiments/scripts/select-model.sh
    return_model $MODEL_NAME
    
    VOCAB="$MODELDIR/vocab.txt"
    CONFIG="$MODELDIR/bert_config.json"

    python3 train.py \
	--vocab_file "$VOCAB" \
	--bert_config_file "$CONFIG" \
	--init_checkpoint "$MODELDIR/$MODEL" \
	--data_dir "$DATA_DIR" \
	--learning_rate $LEARNING_RATE \
	--num_train_epochs $EPOCHS \
	--max_seq_length $MAX_SEQ_LENGTH \
	--train_batch_size $BATCH_SIZE \
	--predict dev \
	--output out-$SLURM_JOBID.tsv

    result=$(python $SCRIPTDIR/accuracy.py "$DATA_DIR/dev.tsv" out-$SLURM_JOBID.tsv)

    echo -n 'DEV-RESULT'$'\t'
    echo -n 'init_checkpoint'$'\t'"$MODEL_NAME"$'\t'
    echo -n 'data_dir'$'\t'"$DATA_DIR"$'\t'
    echo -n 'max_seq_length'$'\t'"$MAX_SEQ_LENGTH"$'\t'
    echo -n 'train_batch_size'$'\t'"$BATCH_SIZE"$'\t'
    echo -n 'learning_rate'$'\t'"$LEARNING_RATE"$'\t'
    echo -n 'num_train_epochs'$'\t'"$EPOCHS"$'\t'
    echo "$result"

    rm out-$SLURM_JOBID.tsv
done 

seff $SLURM_JOBID
echo "END $SLURM_JOBID: $(date)"
