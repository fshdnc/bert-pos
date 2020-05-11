# BERT POS

Part-of-speech tagging using BERT

## Quickstart

Download BERT models

```
./scripts/getmodels.sh
```

Experiment with FinBERT cased and TDT data

```
MODELDIR="models/bert-base-finnish-cased"
DATADIR="data/tdt"

python3 train.py \
    --vocab_file "$MODELDIR/vocab.txt" \
    --bert_config_file "$MODELDIR/bert_config.json" \
    --init_checkpoint "$MODELDIR/bert-base-finnish-cased" \
    --data_dir "$DATADIR" \
    --learning_rate 5e-5 \
    --num_train_epochs 3 \
    --predict test \
    --output pred.tsv

python scripts/mergepos.py "$DATADIR/test.conllu" pred.tsv > pred.conllu
python scripts/conll18_ud_eval.py -v "$DATADIR/gold-test.conllu" pred.conllu
```

## CoNLL'18 UD data

Manually annotated data

(A small part of this data is found in `data/ud-treebanks-v2.2/`)

```
curl --remote-name-all https://lindat.mff.cuni.cz/repository/xmlui/bitstream/handle/11234/1-2837/ud-treebanks-v2.2.tgz

tar xvzf ud-treebanks-v2.2.tgz
```

Predictions from CoNLL'18 participants

(A small part of this data is found in `data/official-submissions/`)

```
curl --remote-name-all https://lindat.mff.cuni.cz/repository/xmlui/bitstream/handle/11234/1-2885/conll2018-test-runs.tgz

tar xvzf conll2018-test-runs.tgz
```

Evaluation script

```
wget https://universaldependencies.org/conll18/conll18_ud_eval.py \
    -O scripts/conll18_ud_eval.py
```

## Reformat

Gold data

```
for t in tdt ftb pud; do
    mkdir data/$t
    for f in data/ud-treebanks-v2.2/*/fi_${t}-ud-*.conllu; do
        s=$(echo "$f" | perl -pe 's/.*\/.*-ud-(.*)\.conllu/$1/')
	egrep '^([0-9]+'$'\t''|[[:space:]]*$)' $f | cut -f 2,4 \
            > data/$t/$s.tsv
    done
    cut -f 2 data/$t/test.tsv | egrep -v '^[[:space:]]*$' | sort | uniq \
        > data/$t/labels.txt
    mv data/$t/test.tsv data/$t/gold-test.tsv
    cp data/ud-treebanks-v2.2/*/fi_${t}-ud-test.conllu data/$t/gold-test.conllu
done
```

PUD doesn't have train and dev, use TDT

```
for s in train dev; do
    cp data/tdt/$s.tsv data/pud
done
```

Test data with predicted tokens

```
for t in tdt ftb pud; do
    cp data/official-submissions/Uppsala-18/fi_$t.conllu data/$t/test.conllu
    egrep '^([0-9]+'$'\t''|[[:space:]]*$)' data/$t/test.conllu \
        | cut -f 2 | perl -pe 's/(\S+)$/$1\tX/' > data/$t/test.tsv
done
```

## Reference results

Best UPOS result for each Finnish treebank in CoNLL'18
from https://universaldependencies.org/conll18/results-upos.html

```
fi_ftb: 1. HIT-SCIR (Harbin): 96.70
fi_pud: 1. LATTICE (Paris)  : 97.65
fi_tdt: 1. HIT-SCIR (Harbin): 97.30
```

## BERT model comparison for Finnish POS tagging

The scripts run here are specific to a particular Slurm system configuration.
You will need to edit them to match your setup if you want to rerun this.

```
./slurm/run-parameter-selection.sh
python3 slurm/select_params.py logs/*.out | cut -f 1-12 > slurm/selected-params.tsv
./slurm/run-selected-params.sh
python3 slurm/summarize_test.py logs/*.out | cut -f 2,4,11-14 > results.tsv
```

This should give approximately the following results:

```
Model             Corpus Mean
FinBERT cased     FTB    98.39
FinBERT uncased   FTB    98.28
M-BERT  cased     FTB    95.87
M-BERT  uncased   FTB    96.00
FinBERT cased     PUD    98.08
FinBERT uncased   PUD    97.94
M-BERT  cased     PUD    97.58
M-BERT  uncased   PUD    97.48
FinBERT cased     TDT    98.23
FinBERT uncased   TDT    98.12
M-BERT  cased     TDT    96.97
M-BERT  uncased   TDT    96.59
```

## Modifications to the original repo
In `scripts/`
- `venv.sh` to create venv on puhti
In `slurm/`
- `batch-dev-pos.sh` runs more than one set of parameters for each sbatch submission, so that time is not wasted queuing
- `batch-run-parameter-selection.sh` used for submitting jobs for `batch-dev-pos.sh`
- `print.sh` prints a file for all the parameters to be searched. One line per job. Used for `batch-run-parameter-selection.sh`
- function `batch_read_logs` added in `summarize.py` for processing files where all the results have been collected in one file
- `select_params.py` changed to using `batch_read_logs` instead of `read_logs`
- `summarize_test.py` changed to using `batch_read_logs` instead of `read_logs`

## Workflow after the modifications
1. Parameter search on the dev set
- use `print.sh` to print out all the combinations
- use `batch-dev-pos.sh` and `batch-run-parameter-selection.sh` to do the experiments
2. Collecting results
- grab for 'DEV-RESULT' and 'accuracy' in the stdout logging files for the results, collect the results into a tsv file `dev-results.tsv`
3. Use `select_params.py` to select the parameters for the test set
- `python3 slurm/select_params.py slurm/dev-results.tsv | cut -f 1-12 > slurm/selected-params.tsv`
4. Run the selected parameters on the test set
- use `batch-test-pos.sh` and `batch-run-selected-params.sh`
5. Organizing the results
- grab for 'TEST-RESULT': `grep -h 'TEST-RESULT' logs/*.out > delme.test-result`
- `cat test-result.delme| grep biBERT70 > delme.70`
- `python3 slurm/summarize_test.py delme.70`
- `rm delme.*`

## Note to self for running on puhti
batch size 20, 4 epochs out of memory (requires 6GB of memory)

Check for out of memory errors
`less logs/batch-*.err | grep -i 'status: out of'`

Parameter search on the dev set
Batching the jobs according to the following parameters
{16,20}{biBERT70,biBERT80}{[23],4}