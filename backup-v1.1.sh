#!/bin/bash -x
# Data atual no formato DD-MM-YYYY
today=$(date +'%d-%m-%Y')

# Data atual no formato MM-YYYY
month_year=$(date +%m-%Y)

# Horário de término dos backups (03h)
end_time=03

pass="senha"

function n1(){
    declare -i contador1=$(cat /home/extend/scripts/contador | cut -d: -f1 | sed "s/ //g")
    echo $[contador1]
}

function n2(){
    declare -i contador2=$(cat /home/extend/scripts/contador | cut -d: -f2 | sed "s/ //g")
    echo $[contador2]
}
cont1=`n1`
cont2=`n2`
function checkBoolean2(){
    chek2=$(cat /home/extend/scripts/contador | cut -d: -f5 | sed "s/ //g")
}
function checkBoolean(){
    check1=$(cat /home/extend/scripts/contador | cut -d: -f4 | sed "s/ //g")
}

function horaAgora(){
    horarioLocal=$(date +%H)
}

function validaClientes(){
    quantClientes=$(find /home/extend/scripts/clientes -maxdepth 1 -type f | wc -l) #verifica a quantidade de clientes
    cliente=$(ls -m /home/extend/scripts/clientes | tr '\n' ' '| cut -d, -f$cont1 | sed "s/ //g") #guarda qual cliente é com basse no numero de clientes retornados acima
    cd '/home/extend/scripts/clientes/'
    lastIpCliente=$(grep -c ".*" ./$cliente) #verifica quantas linhas tem no arquivo do cliente pego pela variavel acima
    cd '/home/extend/scripts/'
    validaUltimoBackup
}
function validaUltimoBackup(){
    cont1=`n1`
    cont2=`n2`
    ultimoCliente=$(cat /home/extend/scripts/contador | cut -d: -f1 | sed "s/ //g")
    ultimoIP=$(cat /home/extend/scripts/contador | cut -d: -f2 | sed "s/ //g")
    isTrue=$(cat /home/extend/scripts/contador | cut -d: -f3 | sed "s/ //g")
    
    if [ $ultimoCliente == $quantClientes ] && [ $ultimoIP == $lastIpCliente ] && [ $isTrue == 1 ];
    then
        echo "1:1:0:true:true" >/home/extend/scripts/contador
        verificacao_nclientes
    else
        echo "$cont1:$cont2:0:true:true" >/home/extend/scripts/contador
        verificacao_nclientes
    fi
}

function verificacao_nclientes() {
    cont1=`n1`
    cont2=`n2`
    checkBoolean
    while [ $check1 ];
    do
        clientes=$(ls -m /home/extend/scripts/clientes | tr '\n' ' '| cut -d, -f$cont1 | sed "s/ //g")
        echo $clientes
        cd '/home/bkpClientes/'
        if [ ! -d $clientes ]; then
            echo $clientes
            mkdir $clientes
        fi
        verificacao_ip
        echo "verificando se o while continua antes do while2"
        sleep 1
    done
    
}
function verificacao_ip() {
    checkBoolean2
    dir=$(echo /home/extend/scripts/clientes/ | sed "s/ //g")
    echo "aqui esta o dir: $dir"
    cd $dir
    verifica_ip=$(grep -c ".*" ./$clientes)
    cd '/home/extend/scripts/'
    # for ((; a <= $verifica_ip; a++ )); do #while [ $a -le $verifica_ip ]; do
    while [ $chek2 ];
    do
        horario=$(date +%H:%M:%S)
        ip_clientes=$(cat /home/extend/scripts/clientes/$clientes | grep ip$cont2: | cut -d: -f2 | sed "s/ //g")
        ENTER=$(echo /home/bkpClientes/$clientes | sed "s/ //g")
        cd $ENTER
        if [ ! -d $ip_clientes ];
        then
            mkdir $ip_clientes
        fi
        
        
        verifica_conexao
        if [ $? -eq 0 ];
        then
            sshpass -p '$pass' ssh -o StrictHostKeyChecking=no root@$ip_clientes 'rsync --version'
            if [ $? -eq 0 ];
            then
                backup
            else
                install
                backup
            fi
        else
            echo "não foi possivel fazer o backup"
            echo "cliente,$clientes,ip,$ip_clientes,data,$today,hora,$horario" >>/home/extend/scripts/logs/Erros:$clientes-$month_year.txt
            cd "/home/extend/scripts/"
        fi
        
        horaAgora
        cont1=`n1`
        cont2=`n2`
        if [ $cont2 == $verifica_ip ] && [ $cont1 == $quantClientes ];
        then
            echo "$cont1:$cont2:1:true:true" >/home/extend/scripts/contador
            validahorario
        elif [ $cont2 == $verifica_ip ] && [ $horarioLocal > $end_time ];
        then
            cont1=`n1`
            result1=$(expr "$cont1" + "1")
            echo $result1
            echo "$result1:1:0:true:false" >/home/extend/scripts/contador
            checkBoolean2
        elif [ $cont2 -le $verifica_ip ];
        then
            cont1=`n1`
            cont2=`n2`
            result2=$(expr "$cont2" + "1")
            echo "$cont1:$result2:0:true:true" >/home/extend/scripts/contador
            checkBoolean2
        fi
        sleep 6
        validahorario
    done
}
function install(){
    vers=$(sshpass -p '$pass' ssh -o StrictHostKeyChecking=no root@$ip_clientes 'cat /etc/os-release | grep VERSION= | cut -d= -f2')
    if [ $? -eq 0 ]
    then
        pastInst=$(echo /home/extend/scripts/rsync/debian${vers:1:2} | sed "s/ //g")
        cd $pastInst
        sleep 1
        sshpass -p '$pass' scp rsync.deb root@$ip_clientes:/tmp/
        sleep 1
        sshpass -p '$pass' ssh -o StrictHostKeyChecking=no root@$ip_clientes 'dpkg -i /tmp/rsync.deb' 2>>/home/extend/scripts/logs/logsInstall
        if [ $? -eq 0 ]
        then
            echo "instalado com sucesso no cliente: $clientes :servidor $ip_clientes" >>/home/extend/scripts/logs/logsInstall
        else
            echo "$cliente: $ip_clientes: $today"  >>/home/extend/scripts/logs/logsInstall
            cd '/home/extend/scripts/rsync/debian32bt'
            sshpass -p '$pass' scp rsync732.deb root@$ip_clientes:/tmp/
            sshpass -p '$pass' ssh -o StrictHostKeyChecking=no root@$ip_clientes 'dpkg -i /tmp/rsync732.deb' 2>>/home/extend/scripts/logs/logsInstall
        fi
    else
        echo "não foi instalado $ip_clientes" >>/home/extend/scripts/logs/logsInstall
    fi
    cd "/home/extend/scripts"
    
}
function verifica_conexao() {
    echo "verificando a conexão do ip $ip_clientes"
    ping -c 1 $ip_clientes 1>>/home/extend/scripts/logs/Erros:$clientes-$month_year.txt # >/dev/null 2>&1
    ping -c 4 $ip_clientes >/dev/null 2>&1
    return $?
}
function backup() {
    echo "iniciando backup cliente: $clientes IP: $ip_clientes"
    sshpass -p '$pass' rsync -avzPh --progress root@$ip_clientes:/home/bkp*/ /home/bkpClientes/$clientes/$ip_clientes 2>>/home/extend/scripts/logs/Erros:$clientes-$month_year.txt
    if [ $? -eq '0' ]; then
        echo "cliente,$clientes,ip,$ip_clientes,data,$today,hora,$horario" >>/home/extend/scripts/logs/$clientes-$month_year.txt
    fi
}
function validahorario() {
    horaAgora
    cont1=`n1`
    cont2=`n2`
    if [[ $horarioLocal -le $end_time ]]; #-le
    then
        echo "executando o backup"
        validaClientes
    else
        echo "O backup não será executado horario excedeu o limite" >> /home/extend/scripts/logs/log
        echo "$cont1:$cont2:0:false:false" >/home/extend/scripts/contador
        exit
    fi
}
validahorario
