#!/bin/bash

mode=""
udp=false
port=""
interval=0
host=""
version=3
transmission_time=0
transmission_window=""
reverse_transmission=false
other_options=""
file_name=""

build_command() {
    cmd="iperf"

    case $mode in
    "cliente")
        if $udp; then
            cmd+=" -u"
        fi

        cmd+=" -c $host"

        if [[ $version -eq 3 ]]; then
            if [[ $transmission_time -gt 0 ]];then
                cmd+=" -t $transmission_time"
            fi
             
            if $reverse_transmission; then
                cmd+=" -R"
            fi
        fi
        ;;
    "servidor")
        if [[ $version -eq 2 ]] && $udp; then
                cmd+=" -u"
        fi
        cmd+=" -s"
        ;;
    esac


    if [[ $transmission_window ]]; then
        if [[ $mode = "cliente" ]] || [[ $version -eq 2 ]]; then
            cmd+=" -w $transmission_window"
        fi
    fi

    if [[ $version -eq 3 ]] && [[ $file_name ]]; then
        cmd+=" -F $file_name"
    fi

    if [[ $port ]]; then
        cmd+=" -p $port"
    fi
    if [[ $interval -gt 0 ]]; then
        cmd+=" -i $interval"
    fi

    cmd+=" $other_options"

    echo "$cmd"
}

descreve() {

    msg="modo: $mode\n"

    if [[ $mode = "cliente" ]]; then
        msg+="servidor: $host\n"
    fi

    msg+="porta: $(if $port; then echo "$port"; else echo "(Padrão) 5001"; fi)\n"

    msg+="intervalo entre reports: $interval segundos\n"

    msg+="protocolo de transporte: $(if $udp; then echo UDP; else echo TCP; fi)\n"

    msg+="inverter transmissão: $(if $reverse_transmission; then echo Sim; else echo Não; fi)\n"

    msg+="tempo de transmissão: $(if [[ $transmission_time -eq 0 ]]; then echo "(Padrão) 10 segundos"; else echo "$transmission_time segundos"; fi)\n"

    msg+="janela de transmissão: $transmission_window\n"

    if [[ -n $file_name ]]; then
        msg+="arquivo a ser transmitido: $file_name\n"
    fi

    msg+="argumentos extras: $other_options\n"

    msg+="versão do iperf: $version\n"

    echo "$msg"
}

init() {
    mode=$(
        dialog --stdout --title "Iperf" --backtitle "$(build_command)" \
        --menu "Escolha uma opção" \
        0 0 0 \
        cliente "Configuração de cliente" \
        servidor "Configuração de servidor"
        )
}

cliente() {
    host=$(
        dialog --stdout --title "Cliente" --backtitle "$(build_command)" \
            --inputbox "Digite o endereço do servidor" \
            10 50 "$host"
    )
}

menu_geral() {
    dialog --stdout --title "Opções" --backtitle "$(build_command)" \
        --menu "$(build_command)" \
        0 0 0 \
        1 "executar comando" \
        2 "descrever comando" \
        3 "configurar opções"
}

opcoes_menu() {
    # shellcheck disable=SC2046
    eval dialog --stdout --title \"opcoes 'do' iperf\" --backtitle \"$(build_command)\" \
        --menu \"\" 0 0 0 \
        $(
            if [[ $mode = "cliente" ]]; then
                echo \
                host \"alterar o servidor escolhido\" \
                window \"definir o tamanho da janela\" \
                udp \"ativar ou desativar transporte por UDP\"
                if [[ $version -eq 3 ]]; then
                echo \
                reverse \"inverte a direcao 'do' tráfego\" \
                time \"definir tempo de transmissao\"
                fi
            elif [[ $version -eq 2 ]]; then
                echo \
                udp \"ativar ou desativar transporte por UDP\" \
                window \"definir o tamanho da janela\"
            else
                echo \
                file \"definir arquivo para a transmissão\"
            fi
        ) \
        port \"escolher porta 'do' servidor\" \
        modo \"alterar modo de funcionamento\" \
        interval \"alterar intervalo entre reports\" \
        other \"passar argumentos customizados\" \
        voltar \"voltar para a tela anterior\"
}

opcoes_case() {
    case "$(opcoes_menu)" in
    "host")
        cliente
        ;;
    "udp")
        udp=$(
            dialog --stdout --title "configuração de UDP" --backtitle "$(build_command)" \
                --yesno 'transmitir via UDP?' 0 0
            if [[ $? -eq 0 ]]; then echo true; else echo false; fi
        )
        ;;
    "reverse")
        reverse_transmission=$(
            dialog --stdout --title "inversão de transmissão" --backtitle "$(build_command)" \
                --yesno 'inverter a direção da transmissão?' 0 0
            if [[ $? -eq 0 ]]; then echo true; else echo false; fi
        )
        ;;
    "time")
        transmission_time=$(
            dialog --stdout --backtitle "$(build_command)" \
                --inputbox "insira o tempo de transmissão, em segundos" \
                0 0 
        )
        ;;
    "window")
        janela
        ;;
    "file")
        arquivo
        ;;
    "port")
        port=$(
            dialog --stdout --backtitle "$(build_command)" \
                --inputbox "digite o numero da porta do servidor" \
                0 0 \
                "$(
                    if [[ $version -eq 3 ]]; then
                        echo "5201"
                    else
                        echo "5001"
                    fi
                )"
        )
        ;;
    "modo")
        init
        ;;
    "interval")
        interval=$(
            dialog --stdout --backtitle "$(build_command)" \
                --inputbox "digite o numero da porta do servidor" \
                0 0 "0"
        )
        ;;
    "other")
        other_options=$(
            dialog --stdout --backtitle "$(build_command)" \
                --inputbox "insira as opções extras a serem utilizadas" \
                0 0 
        )
        ;;
    *)
    ;;
    esac
}

init
if [[ $mode = "cliente" ]]; then
    cliente
fi

while :; do
    case "$(menu_geral)" in
    "1")
        break
        ;;
    "2")
        dialog --title "descrição" --backtitle "$(build_command)" --cr-wrap \
            --msgbox "$(descreve)" 15 50
        ;;
    "3")
        opcoes_case
        ;;
    *)
        break
        ;;
    esac
done

# clear
build_command
