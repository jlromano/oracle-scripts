#!/bin/bash
# Oracle Datapump Backup
# Created by: Julio Romano
# Contact: julio@infolayer.com.br

# Load Script Variables
. ~/.bash_profile
BKP_DIR=/backup_ora/export
STAMP=$(date "+%d_%m_%Y_%Hh%M")

# Load Oracle Variables
ORACLE_SID=${1}
ORACLE_BASE=/u01/app/oracle
ORACLE_HOME=${ORACLE_BASE}/product/12.2.0.1/dbhome_1
TNS_ADMIN=${ORACLE_HOME}/network/admin
PATH=$PATH:$ORACLE_HOME/bin

export ORACLE_SID ORACLE_BASE ORACLE_HOME

# Load Datapump Variables
DIR=IFLBKP
DMP=backup_${ORACLE_SID}_${STAMP}.dmp
LOG=backup_${ORACLE_SID}_${STAMP}.log

# Backup process
echo "\n\n${STAMP} :: ${ORACLE_SID} :: Backup process STARTING" >> ${BKP_DIR}/scripts/backup_general.log
expdp \"/ as sysdba\" parfile=${BKP_DIR}/scripts/parfile.par full=y logfile=${LOG} dumpfile=${DMP} directory=${DIR}
echo "${STAMP} :: ${ORACLE_SID} :: Backup process FINISHED" >> ${BKP_DIR}/scripts/backup_general.log
echo "${STAMP} :: ${ORACLE_SID} :: Detailed log: ${BKP_DIR}/${ORACLE_SID}/${LOG}" >> ${BKP_DIR}/scripts/backup_general.log

# Compress process
echo "${STAMP} :: ${ORACLE_SID} :: Compress process STARTING" >> ${BKP_DIR}/scripts/backup_general.log
cd ${BKP_DIR}
tar --remove-files -czvf ${BKP_DIR}/${ORACLE_SID}/${DMP}.tar.gz \
${BKP_DIR}/${ORACLE_SID}/${DMP} >> ${BKP_DIR}/scripts/backup_general.log
echo "${STAMP} :: ${ORACLE_SID} :: Compress process FINISHED" >> ${BKP_DIR}/scripts/backup_general.log

# Maintenance process
echo "${STAMP} :: ${ORACLE_SID} :: Maintenance process STARTING" >> ${BKP_DIR}/scripts/backup_general.log
find ${BKP_DIR}/${ORACLE_SID} -name "*.tar.gz" -mtime +3 -exec rm -f {} \; >> ${BKP_DIR}/scripts/backup_general.log
find ${BKP_DIR}/${ORACLE_SID} -name "*.log" -mtime +3 -exec rm -f {} \; >> ${BKP_DIR}/scripts/backup_general.log
echo "${STAMP} :: ${ORACLE_SID} :: Maintenance process FINISHIED" >> ${BKP_DIR}/scripts/backup_general.log
echo "${STAMP} :: ${ORACLE_SID} :: Backup process COMPLETED!!!" >> ${BKP_DIR}/scripts/backup_general.log