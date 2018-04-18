#!/bin/bash
decompString(){
    dcmd=""
    if [ $decompress = 1 ]
    then
        case $1 in
        *.tar.bz2 | *.tbz2 )
            dcmd='| tar xj'
            return
            ;;
        *.tar.gz | *.tgz) 
            dcmd='| tar xz'
            return
            ;;  
        *.tar)
            dcmd='| tar x'
            return
            ;;
        *.gz)
            dcmd='| gzip'
            return
            ;;
        *.bz2)
            dcmd='| bzip2 -d'
            return
            ;;
        *.zip)
            dcmd="&& unzip -o' $filename '&& rm $filename"
            return
            ;;
        esac
    fi
    dcmd="-o $filename"
    return
}
decompress=0
if [ $1 = "-d" ]; then
    #decompress mode
    decompress=1
    shift
fi
    mkdir -p $1
    cd $1
    shift
#loop through the urls
while test ${#} -gt 0 ; do
    if [[ $1 == https://drive.google.com/file/d/* ]] 
    then
        url=$1
        echo google drive url is $url
        fileID=${url##*https://drive.google.com/file/d/}
        fileID=${fileID%%/*}
        echo fileID is $fileID
        filename=$(curl -s $url |  grep -o '<title>.* - Google' | head -c -10  | cut -c 8- | tr -d '\n')
        echo filename is $filename
        #get a cookie and check if there is a verification code 
        curl -c ./cookie -r 0-0 -s -L "https://drive.google.com/uc?export=download&id=${fileID}" >& /dev/null
        code=$(cat ./cookie | grep -o 'download_warning.*' | cut -f2)
        if [ -z $code ]; then
            rm ./cookie
            echo No problem with virus check no verification needed
            decompString $filename
            echo "curl  -L 'https://drive.google.com/uc?export=download&id=${fileID}' $dcmd"
            bash -c "curl  -L 'https://drive.google.com/uc?export=download&id=$fileID' $dcmd"
        else
            echo Verification code to bypass virus scan is $code 
            decompString $filename
            echo "curl  -Lb ./cookie 'https://drive.google.com/uc?export=download&confirm=${code}&id=$fileID' $dcmd"
            bash -c "curl -Lb ./cookie 'https://drive.google.com/uc?export=download&confirm=${code}&id=$fileID' $dcmd"
            rm ./cookie
        fi
    else
        echo 'url' $1 'is not from google drive'
        if [ $decompress = 0 ] 
        then
            curl -JLO $1
        else
            case $1 in
            *.tar.bz2 | *.tbz2 ) curl  $1 | tar xj   ;;
            *.tar.gz | *.tgz)    curl  $1 | tar xz   ;;  
            *.tar)               curl  $1 | tar x    ;;
            *.gz)                curl  $1 | gzip     ;;
            *.bz2)               curl  $1 | bzip2 -d ;;
            *.zip)               curl  -o ./temp.zip $1 && unzip -o temp.zip && rm temp.zip   ;;
            *)                   curl -JLO $1            ;;
            esac           
        fi
    fi
    shift
done

