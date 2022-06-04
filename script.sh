echo Select source. Available options:
echo "yt (Youtube)"
echo "file"
read SOURCE_OPTION
if [ $SOURCE_OPTION = yt ]; then
    echo Enter video URL
    read YTURL
elif [ $SOURCE_OPTION = file ]; then
    echo Enter filename
    read FILENAME
    if [ ! -f $FILENAME ]; then
        echo File does not exist
        exit
    fi
    echo "Enter output filename (should end in .mp4)"
    read OTHERFILENAME
    if [[ $OTHERFILENAME != *.mp4 ]]; then
        OTHERFILENAME="$OTHERFILENAME.mp4"
        echo Output filename will be $OTHERFILENAME
    fi
else
    echo Invalid option
    exit
fi
echo Select an aspect ratio. Available options:
echo 4:3
echo 16:9
echo 5:3
read ASPECT_OPTION
if [ $ASPECT_OPTION = 4:3 ]; then
    ASPECT_RES=320x240
elif [ $ASPECT_OPTION = 16:9 ]; then
    ASPECT_RES=426x240
elif [ $ASPECT_OPTION = 5:3 ]; then
    ASPECT_RES=400x240
else
    echo Invalid option
    exit
fi
echo Select 3DS type. Available options:
echo new
echo old
read DS_TYPE
if [ $DS_TYPE = old ]; then
    QUALITY=15
elif [ $DS_TYPE = new ]; then
    QUALITY=1
else
    echo Invalid option
    exit
fi
if [ $SOURCE_OPTION = yt ]; then
    if [ ! -f yt-dlp ]; then
    echo Downloading yt-dlp
    wget -q https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp
    chmod a+rx yt-dlp
    fi
    echo Downloading video
    if [ $DS_TYPE = old ]; then
        ./yt-dlp -o "%(id)s.%(ext)s" $YTURL -f 'bestvideo[height<=240]+bestaudio/best[height<=240]'
    else
        ./yt-dlp -o "%(id)s.%(ext)s" $YTURL
    fi
    FILENAME=$(./yt-dlp --get-filename -o "%(id)s.%(ext)s" $YTURL)
    OTHERFILENAME=$(./yt-dlp --get-filename -o "%(title)s.mp4" $YTURL)
fi
echo Getting frame rate...
FRAME_RATE=$(ffmpeg -i $FILENAME 2>&1 | sed -n "s/.*, \(.*\) fp.*/\1/p")
# untested ↓
if [ $DS_TYPE = old ]; then
    if [ FRAME_RATE -gt 30 ]; then
        echo "Framerate will be 30"
        FRAME_RATE=30
    fi
fi
echo Converting...
ffmpeg -i $FILENAME -acodec aac -vcodec mpeg1video -s $ASPECT_RES -r $FRAME_RATE -q:v $QUALITY "$OTHERFILENAME"
if [ $SOURCE_OPTION = yt ]; then
    rm $FILENAME
fi
echo "Finished, press the enter key to exit"
read
