#!/bin/bash -xv
dataHoje=$(date +'%d-%m-%Y')
dataMes=$(date +%m-%Y)
verifica_clientes=$(find /home/extend/scripts/clientes -maxdepth 1 -type f | wc -l)
HORARIOLOCAL=$(date +%H)
HORARIOFIM="03"
logs=/home/extend/scripts/logs

validate() {
    if [ $HORARIOLOCAL ] <$HORARIOFIM; then #-a
        echo "executando o backup"
        verificacao_nclientes
    else
        echo "O backup não será executado horario excedeu o limite"
    fi
}

verificacao_nclientes() {
    # for ((i = 1; i <= $verifica_clientes; i++)); do
    i=$(cat /opt/scripts/contador | cut -d: -f1)
    CLIENTES=$(ls -m /home/extend/scripts/clientes | cut -d, -f$i | sed "s/ //g")
    echo $CLIENTES
    cd '/home/bkpComunix/'
    if [ ! -d $CLIENTES ]; then
        echo $CLIENTES
        mkdir $CLIENTES
    fi
    verificacao_ip
    # done
}
echo $CLIENTES

verificacao_ip() {
    a=$(cat /opt/scripts/contador | cut -d: -f2) #alterar o caminho
    cd '/home/extend/scripts/clientes/'
    verifica_ip=$(grep -c ".*" ./$CLIENTES)
    echo $verifica_ip
    # for ((a = 1; a <= $verifica_ip; a++)); do
    # echo $a
    # echo 'aquié abaixo do a'
    horario=$(date +%H:%M:%S)
    ip_clientes=$(cat $CLIENTES | grep ip$a, | cut -d, -f2 | sed "s/ //g")
    # echo $ip_clientes
    ENTER=$(echo /home/bkpComunix/$CLIENTES | sed "s/ //g")
    cd $ENTER
    if [ ! -d $ip_clientes ]; then
        mkdir $ip_clientes
    fi
    # ((a++))
    verifica_conexao
    if [ $? -eq '0' ]; then
        # echo $?

        backup
    else
        error
    fi
    echo $a
    ((a+=1))
    echo $a
    echo "$i:$a:$dataMes" >/opt/scripts/contador # aqui deu certo mas falta uma validação para o tamanho maximo do ip do cliente
    verificacao_nclientes
    # done
}

verifica_conexao() {
    ping -c 4 $ip_clientes >/dev/null 2>&1
    return $?
}

backup() {
    echo "iniciando backup cliente: $CLIENTES IP: $ip_clientes"
    sshpass -p "pwserver" rsync -avzPh --progress --backup --backup-dir=/tmp root@$ip_clientes:/opt/scripts/ /home/bkpComunix/$CLIENTES/$ip_clientes 2>>/home/extend/scripts/logs/Erros:$CLIENTES-$dataMes.txt
    if [ $? -eq '0' ]; then
        echo "cliente,$CLIENTES,ip,$ip_clientes,data,$dataHoje,hora,$horario,status,$?" >>/home/extend/scripts/logs/$CLIENTES-$dataMes.txt
    else
        error
    fi
    cd "/home/extend/scripts/clientes/"
}
error() {
    echo "não foi possivel fazer o backup"
    echo "cliente,$CLIENTES,ip,$ip_clientes,data,$dataHoje,hora,$horario,status,$?" >>/home/extend/scripts/logs/Erros:$CLIENTES-$dataMes.txt
    cd "/home/extend/scripts/clientes/"

}
validate
