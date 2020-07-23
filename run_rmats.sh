#!/bin/bash

#PBS -l walltime=48:00:00
PBS_O_WORKDIR=(`echo $PBS_O_WORKDIR | sed "s/^\/state\/partition1//"`)
cd $PBS_O_WORKDIR

source ~/miniconda3/bin/activate rmats

# source variables
. RMATS.config
OUTPUT_DIR=/data/results/$seqId/$panel/$sampleId/

# rmats output here
if [ -d "$OUTPUT_DIR"/RMATS ]; then
  rm -r "$OUTPUT_DIR"/RMATS
fi

mkdir -p "$OUTPUT_DIR"/RMATS

# create text file with query sample bam location - required by RMATS
echo /data/results/"$seqId"/"$panel"/"$sampleId"/"$sampleId"_Aligned_sorted.bam > "$OUTPUT_DIR"/RMATS/query_sample.txt

# rmats calling
rmats.py \
      --b1 "$OUTPUT_DIR"/RMATS/query_sample.txt \
      --b2 $RMATS_REF_SAMPLES \
      -t paired \
      --gtf $GTF_PATH \
      --variable-read-length \
      --od "$OUTPUT_DIR"/RMATS \
      --tmp "$OUTPUT_DIR"/RMATS \
      --readLength $READ_LENGTH \
      --nthread $THREADS \
      --tstat $THREADS

###################
# GENERATE REPORT #
###################

# ENSEMBL GENE ID
# GENE SYMBOL
# CHROMOSOME
# START OF EVENT
# END OF EVENT
# IJC_SAMPLE = NUMBER OF JUNCTION READS SUPPORTING EXON (I)NCLUSION IN SAMPLE
# SJC_SAMPLE = NUMBER OF JUNCTION READS SUPPORTING EXON (S)KIPPING  IN SAMPLE
# IJC_REF = NUMBER OF JUNCTION READS SUPPORTING EXON (I)NCLUSION IN POOLED REF
# SJC_REF = NUMBER OF JUNCTION READS SUPPORTING EXON (S)KIPPING  IN POOLED REF
# FDR = P-Value (FALSE DISCOVERY RATE)
# INC_LEVEL_SAMPLE = PROPORTION OF READS SUPPORTING EXON INCLUSION IN SAMPLE (X)
# INC_LEV_REF = PROPORTION OF READS SUPPORTING EXON INCLUSION IN REF (Y)
# INC_LEV_DIFF = mean(X) - mean(Y)"


# remove legacy report file
if [ -f "$OUTPUT_DIR"/"$seqId"_"$sampleId"_RMATS_Report.tsv ]; then
  rm  "$OUTPUT_DIR"/"$seqId"_"$sampleId"_RMATS_Report.tsv
fi


if [ -f "$OUTPUT_DIR"/RMATS/SE.MATS.JC.txt ]; then

  # if no fusion are called assume error with RMATS
  n_fusions=$(wc -l "$OUTPUT_DIR"/RMATS/SE.MATS.JC.txt)
  if [[ $n_fusions < 3 ]]; then
    exit 1
  fi

  # read RMATS exon skipping report, extract MET and EGFR events
  while read ln; do

    if [[ $ln == ID* ]]; then

      header=$(echo $ln | cut -f 2-4,6-7,13-16,20-23)
      echo $header "Sample1_Perc_SJC" | sed -e 's/ /\t/g' > "$OUTPUT_DIR"/"$seqId"_"$sampleId"_RMATS_Report.tsv 

    elif [[ $ln =~ "chr7	+	116411902	116412043" ]] || [[ $ln =~ "chr7	+	55209978	55221845" ]]; then

      main=$(echo $ln | cut -f 2-4,6-7,13-16,20-23)

      IJC=$(echo $ln | cut -d " " -f 13)
      SJC=$(echo $ln | cut -d " " -f 14)
      
      # calculate proportion metric (as requested by HR)
      PROP=$(awk "BEGIN {print "$SJC"/("$IJC"+"$SJC")*100}")

      echo -e $main $PROP | sed -e 's/ /\t/g' >> "$OUTPUT_DIR"/"$seqId"_"$sampleId"_RMATS_Report.tsv
    fi

  done < "$OUTPUT_DIR"/RMATS/SE.MATS.JC.txt

fi

source ~/miniconda3/bin/deactivate
