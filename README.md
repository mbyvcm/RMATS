# RMATS
detection of exon skipping events

### GTF File
The following annotations are used for MET-ex14 & EGFRvIII

MET-ex14:
chr7 55086811 55087058 [exon 2]
chr7 55209979 55221845 [EGFRvIII]
chr7 55223523 55223639 [exon 8]

EGFR-vIII:
chr7 116411552 116411708 [exon 13]
chr7 116411903 116412043 [MET-ex14]
chr7 116414935 116415165 [exon 15]

The above intervals were included within the ref_annot.gtf (minus chr7) file included with STAR-Fusion.

These files will enable the detection of MET-ex14 & EGFR-vIII events. The absence of EGFR-vIII / MET-ex14 does not preclude the presence of other events within these genes / exons. This test is only validated for the events / intervals described above. 
