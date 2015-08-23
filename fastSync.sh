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

export -f cambiarF


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
