# author Jens Georg
# selects candidates for copraRNA based on a phylogenetic tree of the input sRNAs
# selects a pre-defined set of organisms around the ooi, the pre-selected organisms and the organsims selected based uon the tree by the script

#call: R --slave -f  GLASSgo2CopraRNA_all_neighbours.r --args wildcard=NC_000913,NC_003197 exclude=NC_020260 max_number=5 outfile_prefix=sRNA ooi=NC_000913 sim=3

args <- commandArgs(trailingOnly = TRUE)

ooi<-"NC_000913"
wildcard<-c("NC_000913","NC_000911","NC_003197","NC_016810","NC_000964","NC_002516","NC_003210","NC_007795","NC_003047")
max_number<-5
outfile_prefix<-"sRNA"
exclude<-c("NZ_CP009781.1","NZ_LN681227.1")
sim<-3

for(i in 1:length(args)){
	temp<-strsplit(args[i],"=")
	temp<-temp[[1]]
	temp1<-temp[1]
	temp2<-temp[2]
	assign(as.character(temp1),temp2)
 }

wil<-grep(",",wildcard)
if(length(wil)>0){
	wildcard<-strsplit(wildcard,",")[[1]]
} 
 
max_number<-as.numeric(max_number)
sim<-as.numeric(sim)
require(ape)
load("refined_GLASSgo_table.Rdata")


temp<-coor2
if(length(exclude)>0){
	temp_ex<-c()
	for(i in 1:length(exclude)){
		temp_ex1<-grep(exclude[i], coor2[,"fin"])
		if(length(temp_ex1)>0){
			temp_ex<-c(temp_ex,temp_ex1)
		}
	}
	if(length(temp_ex)>0){
	
	temp<-temp[-temp_ex,]
	}
}
coor2<-temp



# clustal omega call with kimura distance matrix for tree generation
clustalo3<-function(coor, positions){
	fasta<-c()
	for(i in 1:length(positions)){
		fasta<-c(fasta, paste(">",coor[positions[i],"fin"],sep=""))
		fasta<-c(fasta, as.character(coor[positions[i],"sequence"]))
	}
	write.table(fasta, file="temp_fasta", row.names=F, col.names=F, quote=F)
	wd<-getwd()
	command<-paste("clustalo -i ", "temp_fasta", " --distmat-out=distmatout.txt --full --output-order=input-order --use-kimura --force --max-hmm-iterations=-1", sep="")
	system(command)
	na<-grep(">", fasta)
	na<-gsub(">","",fasta[na])
	temp<-read.delim("distmatout.txt",sep="",header=F, , skip=1)
	unlink("distmatout.txt")
	unlink("temp_fasta")
	temp<-temp[,2:ncol(temp)]
	colnames(temp)<-na
	rownames(temp)<-na
	temp
}

# clustal omega call with percent identity matrix 
clustalo4<-function(coor, positions){
	wd<-getwd()
	fasta<-c()
	for(i in 1:length(positions)){
		fasta<-c(fasta, paste(">",coor[positions[i],"fin"],sep=""))
		fasta<-c(fasta, as.character(coor[positions[i],"sequence"]))
	}
	write.table(fasta, file="temp_fasta", row.names=F, col.names=F, quote=F)
	command<-paste("clustalo -i ", "temp_fasta", " --distmat-out=distmatout.txt --full --percent-id --output-order=input-order --force --max-hmm-iterations=-1", sep="")
	system(command)
	na<-grep(">", fasta)
	na<-gsub(">","",fasta[na])
	temp<-read.delim("distmatout.txt",sep="",header=F, , skip=1)
	unlink("distmatout.txt")
	temp<-temp[,2:ncol(temp)]
	colnames(temp)<-na
	rownames(temp)<-na
	temp
}

if(nrow(coor2)<max_number){
	ooi_pos<-grep(ooi, coor2[,"fin"])
	fasta<-c()
	if(length(ooi_pos)>0){
		fasta<-c(paste(">",as.character(coor2[ooi_pos,"fin"],sep="")),as.character(coor2[ooi_pos,"sequence"]))
		coor2<-coor2[-ooi_pos,]
	}
	
	for(i in 1:nrow(coor2)){
		fasta<-c(fasta, paste(">",coor2[i,"fin"],sep=""))
		fasta<-c(fasta, as.character(coor2[i,"sequence"]))
	}
	nam<-paste(outfile_prefix,"CopraRNA_input_balanced.fasta", sep="_" )
	write.table(fasta, file=nam, row.names=F, col.names=F, quote=F)
}

if(nrow(coor2)>max_number){
	
	
	wildcard<-c(ooi,wildcard)
	pos_wild<-c()
	pos_ooi<-grep(ooi,coor2[,"fin"])[1]
	for(i in 1:length(wildcard)){
		pos_wild<-c(pos_wild,grep(wildcard[i],coor2[,"fin"])[1])
	}
	pos_wild<-unique(na.omit(pos_wild))
	
	
	
	max_number2<-max_number-length(pos_wild)+1
	pos<-seq(1,nrow(coor2))
	if(length(pos_wild)>0){
		pos<-pos[-pos_wild]
	}
	pos<-unique(c(pos_ooi,pos))
	dis<-clustalo3(coor2, pos)
	dis2<-clustalo4(coor2, pos)
	dis<-as.dist(dis)
	clus<-(hclust(dis,method="average"))
	plot(clus)
	knum<-min(max_number2,length(clus$labels)-1)
	if(knum<2){
		knum<-2
	}
	clus2<-rect.hclust(clus,k=knum)
	
	out<-c()
	for(i in 1:length(clus2)){
		temp<-clus2[[i]]
		temp_ooi<-grep(ooi,names(temp))
		if(length(temp_ooi)==0){
			temp2<-sample(length(temp),1)
			out<-c(out, names(temp)[temp2])
		}
	}
	out_old<-out
	out<-c(coor2[pos_wild,"fin"],out)
	
	
	dis<-clustalo3(coor2, seq(1,nrow(coor2)))
	dis<-as.dist(dis)
	clus<-(hclust(dis,method="average"))
	dis2<-clustalo4(coor2, seq(1,nrow(coor2)))
	
	
	
	sel2<-c()
	for(i in 1:length(out)){
		sel<-c()
		ooil<-sort(dis2[grep(out[i], colnames(dis2)),], decreasing=T)
		ident<-which(ooil==100)
		if(length(ident)>0){
			ooil<-ooil[-ident]
		}
		close_orgs<-c()
		iii<-0
		while(length(close_orgs)<sim){
		knum2<-min(max_number2,length(clus$labels)-1)-iii
		if(knum2<2){
		break
		}
		clus3<-rect.hclust(clus,k=knum2)
		ooi1<-grep(out[i], names(unlist(clus3)))
		len<-as.numeric(summary(clus3)[,1])
		su<-0
		ii<-1
		while(su<ooi1){
			su<-su+len[ii]
			ii<-ii+1
		}
		ii<-ii-1
		close_orgs<-sort(ooil[intersect(names(clus3[[ii]]),names(ooil))],decreasing=T)

			
		iii<-iii+1
		}


		if(length(close_orgs)>sim){
			n<-length(close_orgs)%/%sim
			n<-seq(1,n*sim,by=n)
			n<-names(close_orgs)[n]
			sel<-unique(c(sel,n))
		}


		if(length(close_orgs)<=sim){
		sel<-unique(c(sel,names(close_orgs)))

		}
		sel2<-c(sel2,sel)
	}
	sel2<-unique(sel2)
	
	
	
	

	
	out<-c(coor2[pos_wild,"fin"],sel2,out)
	out<-match(out,coor2[,"fin"])
	fasta<-c()
	for(i in 1:length(out)){
		fasta<-c(fasta, paste(">",coor2[out[i],"fin"],sep=""))
		fasta<-c(fasta, as.character(coor2[out[i],"sequence"]))
	}
	nam<-paste(outfile_prefix,"CopraRNA_input_neighbourhood.fasta", sep="_" )
	fasta<-gsub("\\..*","",fasta)
	write.table(fasta, file=nam, row.names=F, col.names=F, quote=F)
	dis<-clustalo3(coor2, seq(1,nrow(coor2)))
	dis<-as.dist(dis)
	clus<-(hclust(dis,method="average"))
	clus<-as.phylo(clus)
	lab<-clus$tip.label

	nam_selected<-match(out_old,lab)
	nam_wildcard<-match(coor2[pos_wild,"fin"],lab)
	nam_neighbourhood<-match(sel2,lab)
	nam_ooi<-grep(ooi,lab)

	lab<-match(lab,coor2[,"fin"])
	lab<-coor2[lab,"nam2"]
	clus$tip.label<-lab
	nam<-paste(outfile_prefix,"tree_coprarna_candidates_neighbourhood.pdf", sep="_" )
	pdf(nam)
	colo<-rep("1",length(lab))
	colo[nam_neighbourhood]<-"orangered"
	colo[nam_selected]<-"dodgerblue1"
	colo[nam_wildcard]<-"olivedrab2"
	colo[nam_ooi]<-"purple1"
	par(mar=c(3, 1, 1, 1), xpd=TRUE)
	plot(clus,tip.color=colo, cex=0.5 )

	legend("bottom",  inset=c(-0.05),bty="n", legend=c("organism of interst (ooi)","pre-selected organisms","selected organisms","close to initial organisms"), text.col=c("purple1","olivedrab2","dodgerblue1","orangered"),cex=0.6)
	par(xpd=FALSE)
	dev.off()
	
}

unlink("Rplots.pdf")
