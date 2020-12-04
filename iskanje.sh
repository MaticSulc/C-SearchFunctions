cd $2
for DIR in `find . -maxdepth 1 -mindepth 1 -type d`
do
    naziv=$(grep --include *.h -R -n -i $1 $DIR) #-R recursive, -i case insenstive, -n za st. vrstice
    linenumber=${naziv#*:}
    linenumber=${linenumber%:*}
    pot=${naziv%:*:*} #regex do : karkoli :
    pot=${pot:1}    #strip prvega
    if [ -z "$naziv" ]; then #ce ne obstaja
        continue
    fi
    
    printf "\nDefinicija funkcije $1 se nahaja v datoteki $2$pot v vrstici $linenumber.\n"
    tip=${naziv#*:*:}
    tip=${tip/%\ */}
    parametri=${naziv#*(}
    parametri=${parametri%)*}
    
    arr=($parametri)
    st_parametrov=${parametri//[^,]/}   #stejemo vejice
    st_parametrov=${#st_parametrov}
    if [ $st_parametrov == 0 ] #ce je 0 vejic ima funkcija 1 parameter
    then
        st_parametrov=1
    else
        st_parametrov=$((st_parametrov+1))
    fi
    
    if [ -z "$parametri" ] #izjema za 0, ce je $parametri prazen jih je 0
    then
        st_parametrov=0
    fi
    
    printf "Funkcija prejme $st_parametrov parameter/a/re/ov, ki je/sta/so tipa "
    st=$((st_parametrov*2))
    for (( c=0; c<$st; c+=2))
    do
        if [ -z "$parametri" ] #ce je $parametri prazen ne navedemo tipov
        then
            continue
        fi
        
        if [ $(( $c + 4 )) -gt "$st" ] #preveri, ce bo se slo enkrat skozi, da postavi prava locila
        then
            printf "${arr[c]}."
        else
            printf "${arr[c]}, "
        fi
        
    done
    if [ -z "$parametri" ] #izjema za 0
    then
        printf "(funkcija nima parametrov)." #izpis, ce nima parametrov
    fi
    printf " Funkcija vrača tip $tip.\n"
    cpp_pot=${pot/include/src} #menjamo include z src
    cpp_pot=${cpp_pot/h/cpp}    #menjava koncnice
    
    prvavrstica=$(awk -v ime="$1" 'BEGIN{IGNORECASE=1} $0~ime {print NR":"$0}' ${cpp_pot:1}) #ignorecase awk, najde vrsto z pravim imenom funkcije in dobi st. vrstice
    zacetnavrsta=${prvavrstica%:*} #iscemo pri : ker sem tako izpisal
    zadnjavrsta=$(awk -v vrsta=$zacetnavrsta 'BEGIN {n=1;i=0;levi=0;desni=0;} {i++;} {while (n<vrsta) {n=n+1;next;}} /{/ {if(n>=vrsta){levi++}} /}/ {if(n>=vrsta){desni++}} {if(levi == desni && n>=vrsta) exit;} END {print i}' ${cpp_pot:1}) #stejemo brackete (z regex matching) dokler se ne ujemajo, vmes testiram ce je vrsta pravilna (smo v pravi funkciji!), counter za st. vrstice,
    
    printf "\nImplementacija funkcije $1 se nahaja v datoteki $2$cpp_pot med vrsticama $zacetnavrsta in $zadnjavrsta.\n"
    awk -v vrsta=$zacetnavrsta 'BEGIN {n=1;i=0;levi=0;desni=0;} {i++;} {while (n<vrsta) {n=n+1;next;}} {print} /{/ {if(n>=vrsta){levi++}} /}/ {if(n>=vrsta){desni++}} {if(levi == desni && n>=vrsta) exit;} END {}' ${cpp_pot:1} #enaka logika kot zgoraj, le da izpise sproti vrstice, ne pa na koncu st. vrste
    
    
done