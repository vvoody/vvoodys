#!/bin/bash

# Split the big single ape/flac file to mp3 or ogg files.
# Lastly, write the id3(version 2) tag info into the mp3s or oggs.
#
# Ensure that your cue file is *UTF-8* encoding. NO GB* id3!
#
# Required: mac, flac, lame, cuetools, id3v2(or mutagen), shntool, vorbis-tools
#
# Edited from Brian Archive CUE/FLAC Splitter v0.1
# ;-) vvoody <wxj.g.sh{at}gmail.com>
# ogg convert function added at 2008-10-19
#     by Grissiom <chaos.proton{at}gmail.com> 

echo_usage() {
	echo
	echo "usage: $0 [options [encoding options]] <cuefile>"
	echo
	echo "OPTIONS:"
	echo "    mp3: split sndfile into mp3 files."
	echo "    ogg: split sndfile into ogg files."
	echo "    encoding options: options pass to the encoder,"
        echo "                  must enclosed in quotation marks"
	echo
}

case $1 in
	"--help" )
		echo_usage
		exit 0
		;;
	"mp3" )
		ext='mp3'
		encmd='cust ext=mp3 lame -b 192 - %f'
		;;
	"ogg" )
		ext='ogg'
		encmd='cust ext=ogg oggenc - -o %f'
		;;
	* )
		echo_usage
		exit 1
		;;
esac


if [ $# -eq 2 ]; then
	cuefile=$2
elif [ $# -eq 3 ]; then
	enopt=$2
	cuefile=$3
else
	echo_usage
	exit 1
fi

sndfile=`egrep '^FILE' $cuefile | awk -F'"' '{print $2}'`
# According to http://digitalx.org/cuesheetsyntax.php ,
# the file name may not be enclosed  in quotation marks.
if [ -z $sndfile ]; then
	sndfile=`egrep '^FILE' $cuefile | awk -F' ' '{print $2}'`
fi

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
# Default bit rate is 128, you can customize it by using -b option.
# More output format, see `man shntool`
 shntool split -f "$cuefile" -t '%n.%t' -o "$encmd" "$sndfile"

# Remove the pregrap file, or it will make write the id3 incorrectly.
if [ -f "00.pregap."$ext ]; then
	rm -f 00.pregap.$ext
	echo "00.pregap.$ext found! Removed it."
fi


# Write the id3v2 into the output files.
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
