#!/bin/bash

DATADIR="capture/"
FEATUREDIR="feature/"

RAWFILES=`ls -l $DATADIR | egrep '^-' |  awk '{print $9}' ` 
rm -rf capture/*
rm -rf feature/*
rm -f result.res
rm -f ndx.train

capture_wait(){

while [ `ls -1 capture/ | wc -l` -eq 0 ]
do
	
	sleep 5
done
extract_feature
}


extract_feature(){
for WAVFILE in `ls -l $DATADIR | egrep '^-' |  awk '{print $9}' `
do
	#echo ${WAVFILE}	
	sfbcep -F WAVE -p 24 $DATADIR${WAVFILE} ${FEATUREDIR}${WAVFILE}.mfcc
	EnergyDetector --config cfg/EnergyDetector.cfg --inputFeatureFilename  ${WAVFILE} 
	NormFeat --config cfg/NormFeat.cfg --inputFeatureFilename  ${WAVFILE} 
	rm $DATADIR${WAVFILE}
	cp _ndx.train ndx.train
	sed -i "s/%file%/${WAVFILE}/g" ndx.train 
	ComputeTest --config cfg/ComputeTest.cfg	
	detect
		
done
capture_wait
}

detect(){
detected_speaker=""
max_probability=0.3

while read line           
do           
    read -a arr <<< ${line} 
    if [ ${arr[2]} -eq 1 ]	
    then	
	    if [ $(bc <<<"${arr[4]} >= ${max_probability}") -eq 1 ]
		then
		    max_probability=${arr[4]}
		    detected_speaker=${arr[1]}
	    fi
    fi	
done < result.res

echo "detected speaker: ${detected_speaker}"
}

capture_wait
