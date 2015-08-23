#!/bin/bash
### FASTSYNC PARA DROPBOX-UPLOADER ###
### VERSIÓN -> 1.1 ###
### CREADO POR TONI VILLENA, tonivj5@gmail.com ###

## DIRECTORIO DE DROPBOX UPLOADER Y EL SCRIPT
DBU="$HOME/Dropbox/dropbox_uploader.sh"
## DIRECTORIO REMOTO EN DROPBOX
#DREMOTO="./PROYECTOS/"
DREMOTO="/PROYECTOS/"
## DIRECTORIO LOCAL EN EL EQUIPO
DLOCAL="$HOME/dlocal/"
## NIVEL DE DIRECTORIO QUE QUEREMOS SUBIR, EJEMPLO ->
        ## DIRECTORIO LOCAL: /home/user/dropbox/test/hello.txt
                ## NIVEL DE /home -> 1
                ## NIVEL DE /user -> 2
                ## NIVEL DE /dropbox -> 3
                ## NIVEL DE /test -> 4
                ## NIVEL DE /hello.txt -> 5
        ## DIRECTORIO REMOTO (DROPBOX): /test/hello.txt
LVLD=5

function cambiarF() {
        if [ "$3" ]; then
                FECHAFREMOTO="$3"
        else
                FECHAFREMOTO=$(date -d "$($DBU metadata "$1"| sed 's/\",/\n/g'|grep modified|cut -d "\"" -f 4|cut -d "," -f 2)" +"%Y%m%d%H%M%S")
        fi

        FECHAFORMATEADA=$(echo ${FECHAFREMOTO:0:12}.${FECHAFREMOTO:${#FECHAFREMOTO}-2:${#FECHAFREMOTO}})
        echo -e "Cambiando fecha del fichero local... "
        STATF="$FECHAFREMOTO"
        touch -t "$FECHAFORMATEADA" "$2"
}

if [[ $1 == "FS" ]]; then

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

REPETIR=1

while [ $REPETIR -eq 1 ]; do

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
exit
fi
###

## FUNCIÓN QUE EJECUTA LAS ÓRDENES QUE SERÁN EFECTUADAS EN DROPBOX
function toDropbox() {
if [[ $1 == "MOVE" && -n "${array[1]}" ]]; then
#       echo ${array[0]}
        DESDE=$(echo $(echo ${array[0]}|cut -d "-" -f 4-99999)|cut -d "/" -f $LVLD"-99999")
        A=$(echo $(echo ${array[1]}|cut -d "-" -f 4-99999)|cut -d "/" -f $LVLD"-99999")
        LASTD=$(echo $DESDE|rev|cut -d "/" -f 2-99999|rev)
        ARCHIVO=$(echo $DESDE|rev|cut -d "/" -f 1|rev)
        if [ $($DBU list "$DREMOTO$LASTD"|grep "$ARCHIVO"|wc -l) -eq 1 ]; then
                DO="MOVE"
                MOVER=1
        else
                DO="CREATE"
                RUTAF=$(echo ${array[1]}|cut -d "-" -f 4-99999)
                FILE=$A
        fi
        unset array[0]
        unset array[1]
#echo $DREMOTO$DESDE
#echo $DREMOTO$A
else
        DO=$(echo $1| cut -d "-" -f 1)
        RUTAF=$(echo $1| cut -d "-" -f 6-99999)
        FILE=$(echo $RUTAF|cut -d "/" -f $LVLD"-99999")
        MOVER=0

#       echo "$RUTAF"
#       echo "$FILE"
#echo $RUTAF
fi
#echo $DO
case "$DO" in
"CREATE"|"MODIFY")
        $DBU upload "$RUTAF" "$DREMOTO$FILE"
        cambiarF "$DREMOTO$FILE" "$RUTAF"
#       echo "MODIFICAR/CREAR $RUTAF - $DREMOTO$FILE"

;;
"MOVE")
        if [ $MOVER -eq 1 ]; then
                $DBU move "$DREMOTO$DESDE" "$DREMOTO$A"
#               echo "DESDE $DREMOTO$DESDE A $DREMOTO$A"
        fi
;;
"DELETE")
        echo -e "$DREMOTO$FILE"
        echo -e "NIVEL $LVLD"
        echo -e "$RUTAF"
#       $DBU delete "$DREMOTO$FILE"

;;
*)
esac;
}

## FICHEROS SIN ESPACIOS
#inotifywait -mr --format '%w %f %e' -e create,close_write,delete_self,delete,move /home/usuario/general/angularjs/inmobiliaria/| while read DIR FILE EVENT; do
## FICHEROS CON ESPACIOS
inotifywait -mr -c -e create,close_write,delete,move "$DLOCAL"| while read AEVENT; do

        DOBLE=$(echo $AEVENT|grep "\""|wc -l)

#echo $AEVENT
#echo $DOBLE
        if [ $DOBLE -eq 1 ]; then
                DIR=$(echo $AEVENT|cut -d "," -f 1)
                FILE=$(echo $AEVENT|cut -d "," -f 4)
                EVENT=$(echo $AEVENT|cut -d "\"" -f 2)
        else
                DIR=$(echo $AEVENT|cut -d "," -f 1)
                FILE=$(echo $AEVENT|cut -d "," -f 3)
                EVENT=$(echo $AEVENT|cut -d "," -f 2)
        fi;

#echo $DIR
#echo $FILE
#echo "$DIR$FILE"
#echo $EVENT
#       echo -e "PRIMERO $AEVENT"
#       echo -e "SEGUNDO $AEVENTA"
        STATF=$(date -d "$(stat "$DIR$FILE" 2> /dev/null|grep "Modify"|cut -d " " -f 2-9)" +"%Y%m%d%H%M%S" 2> /dev/null)

        if [[ "$AEVENTA" == "$AEVENT" && "$STATFA" == "$STATF" ]]; then
                EVENT="NINGUNO"
        fi
        echo -e "EVENTO -> $EVENT"
        case "$EVENT" in
        "CREATE"|"CREATE,ISDIR"|"CLOSE_WRITE,CLOSE")
                if [[ "$EVENT" == "CREATE" || "$EVENT" == "CREATE,ISDIR" ]]; then
                        EVENT="CREATE"
                        toDropbox "$EVENT-----$DIR$FILE"; #>> aFicheros.txt
                else
                        EVENT="MODIFY"
                        toDropbox "$EVENT-----$DIR$FILE"; #>> aFicheros.txt
                fi;
        ;;
        "DELETE"|"DELETE,ISDIR")
                EVENT="DELETE"
                toDropbox "$EVENT-----$DIR$FILE" #>> eFicheros.txt
        ;;
        "NINGUNO")
                echo "NATA de NATA"
        ;;
        "MOVED_TO"|"MOVED_FROM"|"MOVED_TO,ISDIR"|"MOVED_FROM,ISDIR")
                if [[ "$EVENT" == "MOVED_FROM" || "$EVENT" == "MOVED_FROM,ISDIR" ]]; then
                        NUMEROA=$(($RANDOM))
                        EVENT="MOVED_FROM"
                        array[0]="$EVENT-$NUMEROA-D-$DIR$FILE" #>> mDesde.txt
                        MOVIDO=1
                elif [[ $MOVIDO -eq 1 ]]; then
                        EVENT="MOVED_TO"
                        array[1]="$EVENT-$NUMEROA-A-$DIR$FILE" #>> mA.txt
                else
                        EVENT="CREATE"
                        toDropbox "$EVENT-----$DIR$FILE"; #>> aFicheros.txt
                fi;
                toDropbox "MOVE"
        ;;
        *)
                echo "NO FUNKA"
        esac;

        AEVENTA="$AEVENT"
        STATFA="$STATF"
done
