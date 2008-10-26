#!/bin/bash

# Split the big single ape/flac file to mp3 or ogg files.
# Lastly, write the id3(version 2) tag info into the mp3s or oggs.
#
# Ensure that your cue file is *UTF-8* encoding. NO GB* id3!
#
# Required: mac, flac, lame, cuetools, id3v2, shntool, vorbis-tools
#
# Edited from Brian Archive CUE/FLAC Splitter v0.1
# ;-) vvoody <wxj.g.sh{at}gmail.com>
#     grissiom <chaos.proton{at}gmail.com>

echo_usage() {
	echo
	echo "usage: $0 [encoding_type [encoding_options]] <cuefile>"
	echo 
	echo "encoding_type:"
	echo "    mp3: split sndfile into mp3 files.(default)"
	echo "    ogg: split sndfile into ogg files."
	echo
	echo "encoding_options: options pass to the encoder,"
        echo "                  must enclosed in quotation marks"
	echo
	echo "If you want to specify the encoding options, you must specify the encoding type."
	echo "We use lame for mp3 encoding and oggenc(provided by vorbis-tools) for ogg ones."
	echo
}

######################################################
# parameter parse begin
######################################################

if [ $1 = "--help" ]; then
	echo_usage
	exit 0
fi

# -V2 is the recommended option for lame.(you can see it by typing lame --help)
case $# in
1 )
	cuefile=$1
	ext="mp3"
	enopt="-V2"
	;;
2 )
	ext=$1
	if [ $ext = "mp3" ]; then
		enopt="-V2"
	fi
	cuefile=$2
	;;
3 )
	ext=$1
	enopt=$2
	cuefile=$3
	;;
* )
	echo_usage
	exit 1
	;;
esac

case $ext in
	"mp3" )
		encmd="cust ext=mp3 lame $enopt - %f"
		;;
	"ogg" )
		encmd="cust ext=ogg oggenc $enopt - -o %f"
		;;
esac

sndfile=`egrep '^FILE' $cuefile | awk -F'"' '{print $2}'`

# According to http://digitalx.org/cuesheetsyntax.php ,
# the file name may not be enclosed  in quotation marks.
if [ -z $sndfile ]; then
	sndfile=`egrep '^FILE' $cuefile | awk -F' ' '{print $2}'`
fi

######################################################
# parameter parse finished, we can begin the work now ;)
######################################################

tracks=$(cueprint -d '%N' "$cuefile")
genre=$(cueprint -d '%G' "$cuefile")

# Store the idv3 info. We will write them to the mp3s later.
id3count=1
echo "Disk Genre: "$genre
echo $tracks "tracks altogether."
echo
while [ $id3count -le $tracks ]; do
	artist[$id3count]=$(cueprint -n$id3count -t '%p' "$cuefile")
	album[$id3count]=$(cueprint -n$id3count -t '%T' "$cuefile")
	tracknum[$id3count]=$(cueprint -n$id3count -t '%02n' "$cuefile")
	title[$id3count]=$(cueprint -n$id3count -t '%t' "$cuefile")
	echo "Artist      - ${artist[$id3count]}"
	echo "Album       - ${album[$id3count]}"
	echo "Track No.   - ${tracknum[$id3count]}"
	echo "Track Title - ${title[$id3count]}"
	echo
	id3count=$[$id3count + 1]
done

echo "=================================================="

# Split and convert the single ape/flac file.
# Each mp3 name is like: "07.Yesterday Once More.mp3"
# More output format, see `man shntool`
 shntool split -f "$cuefile" -t '%n.%t' -o "$encmd" "$sndfile"

# Remove the pregrap file, or it will make write the id3 incorrectly.
if [ -f "00.pregap."$ext ]; then
	rm -f 00.pregap.$ext
	echo "00.pregap.$ext found! Removed it."
fi

# Write the id3v2 into the output files.
# Either mid3v2 or id3tag will corrupt ogg files...
# And it seems that ogg files have a different type of tagging.
acount=1
for outfile in *.$ext; do
	if [ $ext = 'mp3' ]; then
# 		mid3v2 --artist="${artist[$acount]}" \
# 		--album="${album[acount]}" \
# 		--track="${tracknum[acount]}" \
# 		--song="${title[acount]}" \
# 		"$outfile"
		id3tag \
		--artist="${artist[$acount]}" \
		--album="${album[acount]}" \
		--track="${tracknum[acount]}" \
		--song="${title[acount]}" \
		--total="${tracks}" \
		--genre="${genre}" \
		"$outfile"
	elif [ $ext = 'ogg' ]; then
		vorbiscomment -aR \
		-t "Artist=${artist[$acount]}" \
		-t "Album=${album[acount]}" \
		-t "Title=${title[acount]}" \
		-t "Genre=${genre}" \
		-t "totaltracks=${tracks}" \
		-t "tracknumber=${tracknum[acount]}" \
		"$outfile"
	fi
	acount=$[$acount + 1]
done

# End of script.
