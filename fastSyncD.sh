### MODIFICACIONES --- DEVELOPING

function sync() {
#       NDIRECTORIOS=$(echo $2|grep -o "\/"|wc -l)
        case "$1" in
        "download")
#               echo -e "CACA "$2
#               echo -e "LALA "$3
                if [ $4 == "true" ]; then
                        if [ ! -d "$3" ]; then
                                echo -e "Creando directorio... "$3
                                mkdir -p $3
                        fi
                else
            if [ ! -d "$(dirname "$3")" ]; then
                                echo -e "EL DIRECTORIO NO EXISTE"
                                mkdir -p $(dirname "$3")
                        fi
                                $DBU download "$2" "$3"
                                cambiarF "$2" "$3" "$5"
                fi
        ;;
        "upload")

        ;;
        esac
}


function compararFecha() {

    if [ "$3" ]; then
                FECHAFREMOTO="$3"
        else
                FECHAFREMOTO=$(date -d "$($DBU metadata "$1"| sed 's/\",/\n/g'|grep modified|cut -d "\"" -f 4|cut -d "," -f 2)" +"%Y%m%d%H%M%S")
        fi

        if [ -f "$2" ]; then
                echo -e "EL FICHERO EXISTE!!"
                FECHAFLOCAL=$(date -d"$(stat "$2"|grep -y "modify"|awk '{print $2 " " $3}')" +"%Y%m%d%H%M%S")
        else
                echo -e "EL FICHERO LOCAL NO EXISTE"
                FECHAFLOCAL="00000000000000"
#               exit 1
                #$DBU download $1 $DLOCAL$1
#               sync "download" "$1" "$DLOCAL$1" "$4"
#               return 1
        fi

        if [ "$4" == "true" ]; then
                echo -e "ES UN DIRECTORIO"
                sync "download" "$1" "$DLOCAL$1" "$4"
                return 1
        fi

        echo -e "$FECHAFREMOTO"
        echo -e "$FECHAFLOCAL"
#       cambiarF "$2"

        if [ $FECHAFREMOTO -gt $FECHAFLOCAL ]; then
                echo 'El fichero remoto está más actualizado que el local'
                sync "download" "$1" "$DLOCAL$1" "$4" "$FECHAFREMOTO"
        elif [ $FECHAFREMOTO -lt $FECHAFLOCAL ]; then
                echo 'El fichero local está más actualizado que el remoto'
        else
                echo 'El fichero es el mismo tanto en local como en remoto'
        fi

}

#echo "$FECHAFREMOTO - $FECHAFLOCAL"


function crearCursor() {
        echo -e "Creando cursor..."
        if [ $1 ]; then
                echo $1 > $HOME/.latestCursor.txt
        else
                $DBU latest_cursor | sed -ne '3p' | cut -d "\"" -f 4 > $HOME/.latestCursor.txt
        fi
}

while true; do

if [[ -f $HOME/.latestCursor.txt && $(wc -l $HOME/.latestCursor.txt|awk '{print $1}') -eq 1 ]]; then
        LASTCURSOR=$(cat $HOME/.latestCursor.txt)
        echo -e "Cursor encontrado -> "$LASTCURSOR
        REPETIR=1
        CHANGES=$($DBU longpoll_delta $LASTCURSOR | sed -ne '3p' | awk '{print $3}')
        echo $CHANGES

        if [[ "$CHANGES" == "true" ]]; then
                DELTA=$($DBU -x $DREMOTO delta $LASTCURSOR)
                NEWCURSOR=$(echo -e "$DELTA" | grep cursor| cut -d "\"" -f 4)
                MODIFICADOS=$(echo -e "$DELTA"|sed -e "1,5d" -e 's/,//g'|grep -e "path" -e "modified")
                DIR=$(echo -e "$DELTA"|sed -e "1,5d" -e 's/,//g'|grep "is_dir"|cut -d " " -f 2)
                echo -e "$MODIFICADOS"
                ELIMINADOS=$(echo -e "$DELTA"|sed -e "1,5d" -e 's/\,//g' -e 's/\ null/null/g' -e 's/\"//g'|grep -B1 null|grep  -v "^\-\-$")
                if [ $(printf "$MODIFICADOS"|wc -c) -ne 0 ]; then
                        NMODIFICADOS=$(echo -e "$MODIFICADOS"|wc -l)
#                       echo "Nª MOD: $(echo -e "$MODIFICADOS"|wc -m)"
                else
                        NMODIFICADOS=0
                fi

                if [[ $(printf "$ELIMINADOS"|wc -c) -ne 0 ]]; then
                        NELIMINADOS=$(echo -e "$ELIMINADOS"|wc -l)
                else
                        NELIMINADOS=0
                fi
#               echo -e "$ELIMINADOS"
#               echo -e "$NELIMINADOS"
#               echo -e "$MODIFICADOS"
#               echo -e "$NMODIFICADOS"
                I=1
                while [ $NMODIFICADOS -ge $I ]; do
                        DFICHEROU=$(echo -e "$MODIFICADOS"|sed -ne "$I""p"|cut -d "\"" -f 4)
                        echo -e "LINEA: $I ----> $DFICHEROU"
                        ISDIR=$(echo -e "$DIR"|sed -ne "$I""p"|cut -d " " -f 2)
                        I=$((($I+1)))
#                       FECHAFU=$(echo -e "$MODIFICADOS"|sed -ne "$I""p"|cut -d "\"" -f 4|cut -d " " -f 2-99999|sed -e 's/\"//g')
                        FECHAFU=$(echo -e "$MODIFICADOS"|sed -ne "$I""p"|cut -d "\"" -f 4|cut -d " " -f 2-99999)
                        FECHAFFORMATEADAU=$(date -d "$FECHAFU" +"%Y%m%d%H%M%S")
                        echo -e "LINEA: $I ----> $FECHAFFORMATEADAU"
                        echo "ES DIR: "$ISDIR
                        compararFecha "$DFICHEROU" "$DLOCAL$DFICHEROU" "$FECHAFFORMATEADAU" "$ISDIR"
                        I=$((($I+1)))
                done

                I=1

                while [ $NELIMINADOS -ge $I ]; do
                        DFICHEROE=$(echo -e "$ELIMINADOS"|sed -ne "$I""p")
                        DFICHEROE=$($DBU metadata "$DFICHEROE"|grep "path"|cut -d "\"" -f 4)
                        echo -e "ELIMINAR ----> $DLOCAL$DFICHEROE"
                        I=$((($I+2)))
                done
        crearCursor "$NEWCURSOR"
        fi

else
        crearCursor
fi

### FINAL IF PRUEBA
done
