#!/bin/bash

# Función para mostrar texto en verde
function green_text {
    echo -e "\e[32m$1\e[0m"
}

# Función para mostrar el resumen con estilo
function bold_text {
    echo -e "\e[1m$1\e[0m"
}

# Función para mostrar el menú de ayuda
function show_help {
    echo "Uso: $0 [opciones] [archivo_de_hostnames]"
    echo ""
    echo "Este script resuelve nombres de host a direcciones IP y verifica si los puertos 445 (SMB) y 3389 (RDP) están abiertos."
    echo ""
    echo "Opciones:"
    echo "  -h, --help              Muestra este mensaje de ayuda y sale"
    echo "  -o, --outputfile FILE   Exporta los resultados a un archivo de texto"
    echo ""
    echo "Argumentos:"
    echo "  archivo_de_hostnames     Archivo que contiene la lista de nombres de host, uno por línea"
    echo ""
    echo "Ejemplo:"
    echo "  $0 hostnames.txt -o resultados.txt"
    echo ""
    exit 0
}

# Variables de salida
output_file=""

# Procesar argumentos
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            ;;
        -o|--outputfile)
            output_file="$2"
            shift
            ;;
        *)
            if [[ -z "$input_file" ]]; then
                input_file="$1"
            else
                echo "Error: Argumento desconocido: $1"
                exit 1
            fi
            ;;
    esac
    shift
done

# Verificación de archivo de entrada
if [[ -z "$input_file" ]]; then
    echo "Error: No se proporcionó ningún archivo de hostnames."
    echo "Usa $0 -h para ver las opciones disponibles."
    exit 1
fi

# Variables de conteo
resolved_count=0
ipv4_count=0
ipv6_count=0
open_smb_count=0
open_rdp_count=0
hostnames_with_open_ports=()

# Redirigir salida a archivo si se especifica
if [[ -n "$output_file" ]]; then
    exec > >(tee "$output_file") 2>&1
fi

while IFS= read -r hostname; do
    ip=$(getent hosts "$hostname" | awk '{ print $1 }')

    if [ -n "$ip" ]; then
        resolved_count=$((resolved_count + 1))
        echo -n "$hostname -> $ip -> "

        if [[ "$ip" =~ ":" ]]; then
            ipv6_count=$((ipv6_count + 1))
            # Verificar puertos 445 y 3389 en IPv6
            smb_open=false
            rdp_open=false

            if nmap -6 -p 445 "$ip" | grep -q "445/tcp open"; then
                open_smb_count=$((open_smb_count + 1))
                smb_open=true
            fi

            if nmap -6 -p 3389 "$ip" | grep -q "3389/tcp open"; then
                open_rdp_count=$((open_rdp_count + 1))
                rdp_open=true
            fi

            if $smb_open && $rdp_open; then
                hostnames_with_open_ports+=("$hostname -> $ip (SMB y RDP abiertos)")
                green_text "Puertos 445 (SMB) y 3389 (RDP) abiertos"
            elif $smb_open; then
                hostnames_with_open_ports+=("$hostname -> $ip (SMB abierto)")
                green_text "Puerto 445 (SMB) abierto"
            elif $rdp_open; then
                hostnames_with_open_ports+=("$hostname -> $ip (RDP abierto)")
                green_text "Puerto 3389 (RDP) abierto"
            else
                echo "Puertos 445 y 3389 cerrados"
            fi

        else
            ipv4_count=$((ipv4_count + 1))
            # Verificar puertos 445 y 3389 en IPv4
            smb_open=false
            rdp_open=false

            if nmap -p 445 "$ip" | grep -q "445/tcp open"; then
                open_smb_count=$((open_smb_count + 1))
                smb_open=true
            fi

            if nmap -p 3389 "$ip" | grep -q "3389/tcp open"; then
                open_rdp_count=$((open_rdp_count + 1))
                rdp_open=true
            fi

            if $smb_open && $rdp_open; then
                hostnames_with_open_ports+=("$hostname -> $ip (SMB y RDP abiertos)")
                green_text "Puertos 445 (SMB) y 3389 (RDP) abiertos"
            elif $smb_open; then
                hostnames_with_open_ports+=("$hostname -> $ip (SMB abierto)")
                green_text "Puerto 445 (SMB) abierto"
            elif $rdp_open; then
                hostnames_with_open_ports+=("$hostname -> $ip (RDP abierto)")
                green_text "Puerto 3389 (RDP) abierto"
            else
                echo "Puertos 445 y 3389 cerrados"
            fi
        fi
    else
        echo "$hostname -> No se pudo resolver"
    fi
done < "$input_file"

# Resumen con estilo mejorado
echo ""
bold_text "========================================="
bold_text "                 RESUMEN"
bold_text "========================================="
echo ""
bold_text "Hostnames resueltos a direcciones IP: \e[36m$resolved_count\e[0m"
echo ""
bold_text "Direcciones IPv4: \e[36m$ipv4_count\e[0m"
bold_text "Direcciones IPv6: \e[36m$ipv6_count\e[0m"
bold_text "Hostnames con el puerto 445 abierto (SMB): \e[36m$open_smb_count\e[0m"
bold_text "Hostnames con el puerto 3389 abierto (RDP): \e[36m$open_rdp_count\e[0m"
echo ""

if [ "${#hostnames_with_open_ports[@]}" -gt 0 ]; then
    bold_text "======================================="
    bold_text "Hostnames e IPs con puertos abiertos:"
    bold_text "======================================="
    for entry in "${hostnames_with_open_ports[@]}"; do
        green_text "$entry"
    done
fi
echo ""
echo "Verifica las direcciones IP mencionadas anteriormente y evalúa si presentan vulnerabilidades relacionadas con SMB o RDP."
bold_text "========================================="
