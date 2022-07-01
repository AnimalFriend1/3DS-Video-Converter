if ! command -v zenity &> /dev/null
then
    echo "Zenity isn't installed"
    if command -v apt-get &> /dev/null
    then
        echo Install it now?
        select yn in "Yes" "No"; do
            case $yn in
                Yes ) sudo apt-get install zenity; break;;
                No ) exit;;
            esac
        done
    else
        exit
    fi
fi
if ! command -v ffmpeg &> /dev/null
then
    zenity --error --text="FFmpeg isn't installed"
    if command -v apt-get &> /dev/null
    then
        if zenity --question --text="Install FFmpeg now?"
        then
        sudo apt-get install ffmpeg;
        else
        exit
        fi
    else
        exit
    fi
fi
SOURCE_OPTION=$(zenity --list --title="Select source" --text="Select source" --column="source" --hide-header YouTube \File)
if [ -z "$SOURCE_OPTION" ]; then
exit
fi
case $SOURCE_OPTION in
YouTube ) 
YTURL=$(zenity --entry --title="YouTube URL" --text="Enter the URL of the YouTube video")
OTHERFILENAME=$(zenity --file-selection --save --title="Save the file as..." --file-filter="*.mp4")
if [[ $OTHERFILENAME != *.mp4 ]]; then
    OTHERFILENAME="$OTHERFILENAME.mp4"
fi
if [ -z "$OTHERFILENAME" ]; then
exit
fi
;;
File ) 
FILENAME=$(zenity --file-selection --title="Select a video file")
if [ -z "$FILENAME" ]; then
exit
fi
OTHERFILENAME=$(zenity --file-selection --save --title="Save the file as..." --file-filter="*.mp4")
if [ -z "$OTHERFILENAME" ]; then
exit
fi
if [[ $OTHERFILENAME != *.mp4 ]]; then
    OTHERFILENAME="$OTHERFILENAME.mp4"
fi
;;
esac
ASPECT_OPTION=$(zenity --list --title="Select aspect ratio" --text="Select aspect ratio" --column="Aspect Ratio" --column="Resolution" 16:9 426x240 \4:3 320x240 \5:3 400x240)
if [ -z "$ASPECT_OPTION" ]; then
exit
fi
case $ASPECT_OPTION in
4:3 )
ASPECT_RES=320x240
;;
16:9 )
ASPECT_RES=426x240
;;
5:3 )
ASPECT_RES=400x240
;;
esac
DS_TYPE=$(zenity --list --title="Select 3DS type" --text="Select 3DS type" --column="type" --hide-header New \Old)
if [ -z "$DS_TYPE" ]; then
exit
fi
case $DS_TYPE in
Old )
QUALITY=15
;;
New )
QUALITY=1
;;
esac
if [ $SOURCE_OPTION = YouTube ]; then
    if [ ! -f yt-dlp ]; then
    echo Downloading yt-dlp
    wget --progress=bar:force https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp 2>&1 | zenity --title="Downloading yt-dlp" --text="Downloading yt-dlp" --progress --auto-close --auto-kill
    chmod a+rx yt-dlp
    fi
    echo Downloading video
    if [ $DS_TYPE = old ]; then
        ./yt-dlp -o "%(id)s.%(ext)s" $YTURL --progress --newline -f 'bestvideo[height<=240]+bestaudio/best[height<=240]'
    else
        ./yt-dlp -o "%(id)s.%(ext)s" $YTURL
    fi
    FILENAME=$(./yt-dlp --get-filename -o "%(id)s.%(ext)s" $YTURL)
fi
echo Getting frame rate...
FRAME_RATE=$(ffmpeg -i "$FILENAME" 2>&1 | sed -n "s/.*, \(.*\) fp.*/\1/p")
if [ $DS_TYPE = Old ]; then
    if [[ FRAME_RATE > 30 ]]; then
        echo "Framerate will be 30"
        FRAME_RATE=30
    fi
fi
echo Converting...
ffmpeg -i "$FILENAME" -acodec aac -vcodec mpeg1video -s $ASPECT_RES -r $FRAME_RATE -q:v $QUALITY "$OTHERFILENAME"
if [ $SOURCE_OPTION = YouTube ]; then
    rm "$FILENAME"
fi
if command -v notify-send &> /dev/null
then
        notify-send "Finished converting video"
fi 
