#!/bin/bash
# +---------------------------------------------------------------------------+
# | Daily Checklist S2IT                                                      |
# | Automacao do Checklist Diario                                             |
# | Autor: S2IT - Julio Romano                                                |
# | Ultima Modificacao: 17/11/2015                                            |
# +---------------------------------------------------------------------------+

# Variaveis de ambiente
[ -f ~/.profile ]      && . ~/.profile
[ -f ~/.bash_profile ] && . ~/.bash_profile

# Variaveis do Script
WORK_DIR="/tmp"
LOGFILE="${WORK_DIR}/logcheck.log"
export ORACLE_SID="$1"

# Configuracoes de Email
REMT="julio.romano@s2it.com.br"        
DEST="julio.romano@s2it.com.br"       
SMTPSRV="mail.servicesupport.com.br"  
SMTPUSER=""                           
SMTPPASS=""                           

#######################################
# Coleta Informacoes Gerais do Ambiente
# Globals:
#   None
# Arguments:
#   $1 - SID
# Returns:
#   None
#######################################
coletar_info() {
  echo -e "::::::::::::::::::::::::::"                              >  ${LOGFILE}
  echo -e ":: DAILY CHECKLIST S2IT ::"                             >>  ${LOGFILE}
  echo -e "::::::::::::::::::::::::::"                             >>  ${LOGFILE}
                   
  echo -e "\nServidor       : $(hostname)"                         >>  ${LOGFILE}
  echo -e "Banco de Dados : ${ORACLE_SID}"                         >>  ${LOGFILE}
  echo -e "Data           : $(date)"                               >>  ${LOGFILE}
  echo -e "Uptime         :$(uptime)"                              >>  ${LOGFILE}
}

#######################################
# Verifica Espaco em Disco Linux|AIX
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
verificar_disco() {
  # Verifica Espaco em Disco
  # Linux
  echo -e "\nEspaço em disco:"                                     >>  ${LOGFILE}
  if [ -d /etc/init.d ]; then 
    df -h                                                          >>  ${LOGFILE}
  else 
  # AIX
    echo -e "\nEspaço em disco:"                                   >>  ${LOGFILE}
    df -Pkg                                                        >>  ${LOGFILE}
  fi
}

#######################################
# Verificacoes Bkp Fisico BKPon - S2IT
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
verificar_bkpf() {
  if [ -d /etc/init.d ]; then 
    # Linux
    DATI=$(date --date="1 day ago" +"%y%m%d")
  else
    # AIX
    TZ=IST+24
    DATI=$(date +"%y%m%d")
  fi
  
  ls ${BKP_HOME}/log/ | egrep "${DATI}" >> cat.log
  
  for i in $(cat cat.log | egrep "FULL.log" | egrep "${1%?}" | tail -1); do
    echo -e "\nBackup Fisico: ${BKP_HOME}/log/$i"                   >> ${LOGFILE}
    if [ $(cat ${BKP_HOME}/log/$i \
      | egrep "RMAN-" \
      | tail -1) ] || [ $(cat ${BKP_HOME}/log/$i \
      | egrep "RMAN-" | tail -1) ]; then
      echo "$(cat ${BKP_HOME}/log/$i | egrep "RMAN-" | tail -1)"    >> ${LOGFILE}
      echo "$(cat ${BKP_HOME}/log/$i | egrep "ORA-" | tail -1)"     >> ${LOGFILE}
    else
      echo "Backup Fisico Executado com Sucesso"                    >> ${LOGFILE}
    fi
  done
]

#######################################
# Verificacoes Bkp Logico BKPon - S2IT
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################  
verificar_bkpl() {
  ls $BKP_HOME/log/ |egrep "${DATI}" >> cat2.log
  for i in $(cat cat.log \
    | egrep "EXPF.log" \
    | egrep "${1%?}" \
    | tail -2 \
    | egrep -v 'log.t'); do
    echo -e "\nBackup Logico: ${BKP_HOME}/log/$i"                   >> ${LOGFILE}
    echo "$(cat ${BKP_HOME}/log/$i | tail -1)"                      >> ${LOGFILE}
  done
}

#######################################
# Verificar BKP via Query
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
verificar_bkpq() {
  sqlplus -s "/ as sysdba" <<! > /dev/null
  spool rman_jobs REPLACE
  select start_time, 
         end_time,
         TO_CHAR(TRUNC(ELAPSED_SECONDS/3600),'FM9900') || ':' ||
         TO_CHAR(TRUNC(MOD(ELAPSED_SECONDS,3600)/60),'FM00') || ':' ||
         TO_CHAR(MOD(ELAPSED_SECONDS,60),'FM00') ELAPSED_TIME,
         status 
  from V\$RMAN_BACKUP_JOB_DETAILS 
  where input_type='DB FULL'
  and trunc(start_time) > trunc(sysdate)-1;
  spool off
  quit
!
  echo -e "\nBackup Fisico: $(cat ${WORK_DIR}/rman_jobs.lst)" >>     ${LOGFILE}
}

#######################################
# Exibe o path do Scanner - S2IT
# Globals:
#   None
# Arguments:
#   $1 - SID
# Returns:
#   None
#######################################
verificar_spath() {
  sqlplus "/ as sysdba" <<! > /dev/null
  set feedback off head off
  spool spool2 REPLACE
  select value 
  from v\$parameter 
  where name='background_dump_dest';
  spool off
  quit
!
  echo -e "\nAlert Log: $(cat ${WORK_DIR}/spool2.lst \
    | sed 's/ //g' \
    | tail -2 \
    | egrep -v "spool")/alert_${ORACLE_SID}.log"                  >> ${LOGFILE}
}

#######################################
# Verifica os Jobs - S2IT
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
verificar_jobs() {
  sqlplus "/ as sysdba" <<! > /dev/null
  SET pages 999 lines 1000 feedback OFF trimspool ON 
  spool jobss2it REPLACE 
  col what FOR a55
  SELECT job,
         what,
         failures,
         broken,
         last_date,
         next_date
  FROM dba_jobs
  WHERE schema_user IN ('S2IT','DBAS2IT')
  ORDER BY 1;
  spool OFF
  quit
!
  echo -e "\nJobs: $(cat ${WORK_DIR}/jobss2it.lst \
    | sed '1 d;2 d;3 d;4 d;5 d;6 d;7 d;8 d;9 d;10 d' \
    | egrep -v "spool")"                                            >> ${LOGFILE}
}

#######################################
# Limpar Arquivos Temporarios - S2IT
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
limpar_arquivos() {
  rm -f cat.log cat2.log jobss2it.lst spool2.lst
}

#######################################
# Gera E-mail de Monitoramento - S2IT
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
enviar_email() {
  sendEmail -f ${REMT} -t ${DEST} -u "Checklist Diario :: $(hostname) :: $1" -o\
  message-file=${LOGFILE} -s ${SMTPSRV} -xu ${SMTPUSER} -xp ${SMTPPASS}
}

# MAIN
coletar_info
verificar_disco
verificar_bkpl
verificar_bkpq
verificar_spath
verificar_jobs
limpar_arquivos