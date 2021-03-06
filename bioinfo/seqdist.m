% Compute the Hamming distance between two sequences. 
% Takes into account only known positions. (Unknowns in one sequence
% do not add to the distance) 
function dist=seqdist(R_seqInd,iseq1,iseq2)
seq1=R_seqInd(iseq1,:);
seq2=R_seqInd(iseq2,:);
seq1(seq1==5)=0;
seq2(seq2==5)=0;
difpos=find(seq1~=seq2);
dist=length(find(seq1(difpos).*seq2(difpos)>0));
