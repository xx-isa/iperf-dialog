#!/bin/bash

# mode=""
# port=""
# interval=0
# host=""
# version=3
# transmission_window=""
# other_options=""
# file_name=""
transmission_time=0
udp=false
reverse_transmission=false

iperf_cmd() {
    [[ $version -eq 3 ]] && echo -n "iperf3" || echo -n "iperf"

    case $mode in
    "cliente")
        $udp && echo -n " -u"
        echo -n " -c $host"

        if [[ $version -eq 3 ]]; then
            [[ $transmission_time -gt 0 ]] && echo -n " -t $transmission_time"
            $reverse_transmission && echo -n " -R"
        fi
        ;;
    "servidor")
        [[ $version -eq 2 ]] && $udp && echo -n " -u"
        echo -n " -s"
        ;;
    esac

    [[ -n $transmission_window ]] && { [[ $mode = "cliente" ]] || [[ $version -eq 2 ]]; } &&
        echo -n " -w $transmission_window"
    [[ $version -eq 3 ]] && [[ -n $file_name ]] && echo -n " -F $file_name"
    [[ -n $port ]] && echo -n " -p $port"
    [[ $interval -gt 0 ]] && echo -n " -i $interval"
    echo -n " $other_options"
}

descricao() {
    echo "modo: $mode"
    [[ $mode = "cliente" ]] && echo "servidor: $host"
    echo "porta: ${port:-"(Padrão) 5001"}"
    echo "intervalo entre reports: $interval segundos"
    echo "protocolo de transporte: $($udp && echo "UDP" || echo "TCP")"
    echo "inverter transmissão: $($reverse_transmission && echo "Sim" || echo "Não")"
    echo "tempo de transmissão: $([[ $transmission_time -eq 0 ]] &&
        echo "(Padrão) 10 segundos" || echo "$transmission_time segundos")"
    [[ $transmission_window ]] && echo "janela de transmissão: $transmission_window"
    [[ -n $file_name ]] && echo "arquivo a ser transmitido: $file_name"
    [[ $other_options ]] && echo "argumentos extras: $other_options"
    echo "versão do iperf: $version"
}

versao() {
    dialog --stdout --title "iPerf" --menu "Escolha uma versão do iPerf" 0 0 0 \
        2 "iPerf2 (iperf)" \
        3 "iPerf3 (iperf3)"    
}

modo() {
    dialog --stdout --title "Iperf" --backtitle "$(iperf_cmd)" \
        --menu "Escolha uma opção" \
        0 0 0 \
        cliente "Configuração de cliente" \
        servidor "Configuração de servidor"
}

inputbox() {
    dialog --stdout --title "$1" --backtitle "$(iperf_cmd)" \
        --inputbox "$2" 0 0 "$3"
}

yesno() {
    dialog --title "$1" --backtitle "$(iperf_cmd)" \
        --yesno "$2" 0 0 && echo true || echo false
}

opcoes_menu() {
    # shellcheck disable=SC2046
    eval dialog --stdout --title \"Parâmetros\" --backtitle \"$(iperf_cmd)\" \
        --menu \"Escolha um parâmetro para configurar\" 0 0 0 \
        $(  if [[ $mode = "cliente" ]]; then
                echo \
                    host \"alterar o servidor escolhido\" \
                    window \"definir o tamanho da janela\" \
                    udp \"ativar ou desativar transporte por UDP\"
                if [[ $version -eq 3 ]]; then
                    echo \
                        reverse \"inverte a direcao 'do' tráfego\" \
                        time \"definir tempo de transmissao\" \
                        file \"definir arquivo para a transmissão\"
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
        version \"alterar versão 'do' iperf\" \
        voltar \"voltar para a tela anterior\"
}

opcoes_case() {
    case "$(opcoes_menu)" in
    "host")
        host=$(inputbox "Cliente" "Insira o endereço do servidor" "$host")
        ;;
    "udp")
        udp=$(yesno "UDP" "transmitir via UDP?")
        ;;
    "reverse")
        reverse_transmission=$(
            yesno "inversão de transmissão" "inverter a direção da transmissão?"
        )
        ;;
    "time")
        transmission_time=$(
            inputbox "Tempo de Transmissão" \
                "Insira o tempo de transmissão, em segundos" \
                "$transmission_time"
        )
        ;;
    "window")
        transmission_window=$(
            inputbox "Janela de Transmissão" \
                "Insira"
        )
        ;;
    "file")
        file_name=$(
            dialog --stdout --title "escolha um arquivo" --backtitle "$(iperf_cmd)" \
            --fselect "." 0 80
        )
        ;;
    "port")
        port=$(
            inputbox "Porta" "Digite no numero da porta do servidor" \
                "$([[ $version -eq 3 ]] && echo "5201" || echo "5001")"
        )
        ;;
    "modo")
        mode=$(modo)
        if [[ $mode = "cliente" ]]; then
            host=$(
                inputbox "Cliente" "Insira o endereço do servidor" "$host"
            )
        fi
        ;;
    "interval")
        interval=$(
            inputbox "Intervalo de reports" \
                "Insira o intervalo de tempo, em segundos" \
                "0"
        )
        ;;
    "other")
        other_options=$(
            inputbox "Opções Extras" \
                "Insira as opções de linha de comando" \
                "$other_options"
        )
        ;;
    "version")
        version=$(versao)
        ;;
    *) ;;
    esac
}


version=$(versao)
mode=$(modo)
if [[ $mode = "cliente" ]]; then
    host=$(
        inputbox "Cliente" "Insira o endereço do servidor" "$host"
    )
fi

while :; do
    opt=$(
        dialog --stdout --title "Opções" --backtitle "$(iperf_cmd)" \
            --menu "$(iperf_cmd)" \
            0 0 0 \
            1 "executar comando" \
            2 "descrever comando" \
            3 "configurar opções"
    )
    case $opt in
    "1")
        clear
        eval "$(iperf_cmd)"
        ;;
    "2")
        dialog --title "descrição" --backtitle "$(iperf_cmd)" \
            --msgbox "$(descricao)" 0 0
        ;;
    "3")
        opcoes_case
        ;;
    *)
        break
        ;;
    esac
done