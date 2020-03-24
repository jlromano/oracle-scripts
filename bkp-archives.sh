#!/bin/bash
# Backup banco de dados Oracle - Archives
# Autor: Julio Romano - S2IT
# Data : 29/12/2015

#Definir Data/Log
DATA=`date +"%d%m%y-%H%M"`

# Definicao de variaveis
. /home/oracle/.bash_profile
BKP_DIR=/u01/backup/bkp-archives
BKP_HOME=/u01/backup/scripts
LOG_FILE=${BKP_DIR}/bkp-archives-$1-$DATA.log

export ORACLE_SID=$1
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/dbhome_1

echo -e "Inicio do processo de Backup dos Archives do Banco de Dados $1 `date`" > ${LOG_FILE}

rman target / catalog rman/rman @${BKP_HOME}/bkp-archives.rma >> ${LOG_FILE}

echo -e "\nProcesso de Backup dos Archives Finalizado" >> ${LOG_FILE}

cd ${BKP_DIR}

echo -e "\nInicio do processo de remocao dos backups obsoletos `date`" >> ${LOG_FILE}
find ${BKP_DIR} -name "*.log" -mtime +5 -exec rm -f {} \; >> ${LOG_FILE}
echo -e "\nFim do processo de remocao dos backups obsoletos" >> ${LOG_FILE}

echo -e "\nFinal do processo de backup `date`" >> ${LOG_FILE}