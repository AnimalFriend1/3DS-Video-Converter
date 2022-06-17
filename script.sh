if ! command -v ffmpeg &> /dev/null
then
    echo "FFmpeg isn't installed"
    if command -v apt-get &> /dev/null
    then
        echo Install it now?
        select yn in "Yes" "No"; do
            case $yn in
                Yes ) sudo apt-get install ffmpeg; break;;
                No ) exit;;
            esac
        done
    else
        exit
    fi
fi
echo Select source.
select SOURCE_OPTION in "Youtube" "File"; do
    case $SOURCE_OPTION in
    Youtube ) 
    echo Enter video URL
    read YTURL
    break;;
    File ) 
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
        break;;
    esac
done
echo Select an aspect ratio.
select ASPECT_OPTION in "4:3" "16:9" "5:3"; do
    case $ASPECT_OPTION in
    4:3 )
    ASPECT_RES=320x240
    break;;
    16:9 )
    ASPECT_RES=426x240
    break;;
    5:3 )
    ASPECT_RES=400x240
    break;;
    esac
done
echo Select 3DS type.
select DS_TYPE in "new" "old"; do
    case $DS_TYPE in
    old )
    QUALITY=15
    break;;
    new )
    QUALITY=1
    break;;
    esac
done
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
if [[ $(ls -l /media/$USER/ | grep -c ^d) = 1 ]]; then
    echo Save to storage device at /media/$USER/$(ls /media/$USER/)?
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) mv "$OTHERFILENAME" "/media/cato/$(ls /media/$USER/)"; break;;
            No ) echo File saved in "$PWD"; break;;
        esac
    done
fi
echo "Finished, press the enter key to exit"
read
