#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=5G
#SBATCH -p gpu
#SBATCH -t 01:30:00
#SBATCH --gres=gpu:v100:1
#SBATCH --ntasks-per-node=1
#SBATCH --account=Project_2002085
#SBATCH -o /scratch/project_2002820/lihsin/bert-pos/logs/%j.out
#SBATCH -e /scratch/project_2002820/lihsin/bert-pos/logs/%j.err

function on_exit {
    rm -f slurm/jobs/$SLURM_JOBID
}
trap on_exit EXIT

if [ "$#" -ne 6 ]; then
    echo "Usage: $0 model_name data_dir seq_len batch_size learning_rate epochs"
    exit 1
fi

MODEL_NAME="$1"
DATA_DIR="$2"
MAX_SEQ_LENGTH="$3"
BATCH_SIZE="$4"
LEARNING_RATE="$5"
EPOCHS="$6"

SCRIPTDIR="/scratch/project_2002820/lihsin/bert-pos/scripts"
cd /scratch/project_2002820/lihsin/bert-pos

# returns MODELDIR and MODEL
source /scratch/project_2002820/lihsin/bert-experiments/scripts/select-model.sh
return_model $MODEL_NAME

VOCAB="$MODELDIR/vocab.txt"
CONFIG="$MODELDIR/bert_config.json"

:<<'END'
if [[ $MODEL =~ "uncased" ]]; then
    caseparam="--do_lower_case"
elif [[ $MODEL =~ "multilingual" ]]; then
    caseparam="--do_lower_case"
else
    caseparam=""
fi
END


module purge
module load tensorflow
source /projappl/project_2002820/venv/bert-pos/bin/activate


export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

#echo "Task: bert-pos; Model: $MODEL_NAME; Data: $(basename $DATA_DIR); Max sequence length: $MAX_SEQ_LENGTH; Batch size: $BATCH_SIZE; Learning rate: $LEARNING_RATE; Epoch: $EPOCHS"
echo "START $SLURM_JOBID: $(date)"

srun python3 train.py \
    --vocab_file "$VOCAB" \
    --bert_config_file "$CONFIG" \
    --init_checkpoint "$MODELDIR/$MODEL" \
    --data_dir "$DATA_DIR" \
    --learning_rate $LEARNING_RATE \
    --num_train_epochs $EPOCHS \
    --max_seq_length $MAX_SEQ_LENGTH \
    --train_batch_size $BATCH_SIZE \
    --predict dev \
    --output out-$SLURM_JOBID.tsv \
    $caseparam

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

seff $SLURM_JOBID
echo "END $SLURM_JOBID: $(date)"
