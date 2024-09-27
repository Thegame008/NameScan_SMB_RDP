# NameScan_SMB_RDP
Uso Linux: ./NameScanSMB.sh [archivo_de_hostnames] [opciones]

Este script resuelve nombres de host a direcciones IP y verifica si los puertos 445 (SMB) y 3389 (RDP) están abiertos.

Opciones:
  -h, --help              Muestra este mensaje de ayuda y sale
  -o, --outputfile FILE   Exporta los resultados a un archivo de texto

Argumentos:
  archivo_de_hostnames     Archivo que contiene la lista de nombres de host, uno por línea

Ejemplo:
  ./NameScanSMB.sh hostnames.txt -o resultados.txt
