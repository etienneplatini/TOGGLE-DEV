/usr/local/samtools-0.1.18/samtools-0.1.18/samtools sort -n ../tophat/accepted_hits.bam ../tophat/accepted_hits.SAMTOOLSSORT
/usr/local/bin/htseq-count -r name -s no -t mRNA -m union -i ID -f bam ../tophat/accepted_hits.SAMTOOLSSORT.bam ../referenceRNASeq.gff3 > ../tophat/accepted_hits.HTSEQCOUNT.txt