#!bin/sh
#########################################################################
#Script to compress and backup files from the folder:
#--Colocar o DIR AQUI--
#
#Author: Davidson de Oliveira Mizael - davidsonmizael@gmail.com
#Start Date: 06/16/2015
#########################################################################
#Exit codes:
# 1, 2 and 3 - Failed in folder creation
# 101 - Folder is empty
# 201 - Failed in file compression with .tar
# 202 - Failed in file compression from .tar to .tar.bz2
# 301 - Failed in mysql dump 
#########################################################################

######  VARIABLES  ######

#Actual date
VAR_ACTUAL_DATE="$(date +'%m_%d_%y')"
VAR_ACTUAL_MONTH="$(date +'%m')"
VAR_ACTUAL_YEAR="$(date +'%Y')"
#Directories path
DIR_PATH="/home/dmizael/Desktop/SPRINT"
DIR_DEST="/home/dmizael/Desktop/BACKUPSPRINT/"
DIR_DEST_WDATE="${DIR_DEST}${VAR_ACTUAL_YEAR}/${VAR_ACTUAL_MONTH}"
#File names
FILE_BKPNAME="dirtest_${VAR_ACTUAL_DATE}"
FILE_BKPLOG=".${FILE_BKPNAME}.log"
DB_BKPNAME="dbckup_${VAR_ACTUAL_DATE}.gz"
#Database info
MYSQL_USER="root"
MYSQL_PSSWD="password"
MYSQL_DBNAME="dbname"

#Creating the log file
touch /home/dmizael/Desktop/$FILE_BKPLOG
###### Functions ######

function checkDestination {
	#Se a pasta do ano ja existe entra no if
	########################################
	if [ -d "${DIR_DEST}${VAR_ACTUAL_YEAR}" ]; then
			#Se a pasta do mês não existe entra no if
			#########################################
			if [ ! -d "${DIR_DEST}${VAR_ACTUAL_YEAR}/${VAR_ACTUAL_MONTH}" ]; then
					echo "Month folder didn't exist yet." >> $FILE_BKPLOG
					#Cria a pasta do mês
					####################
					mkdir "${DIR_DEST_WDATE}"
					if [ $? -eq 0 ]; then 
						echo "${DIR_DEST_WDATE}: successfully created." >> $FILE_BKPLOG
					else
						echo "Failed to create ${DIR_DEST_WDATE}"
						exit 1
					fi
			fi
	#Se a pasta do ano não existe então a pasta do mês tambem não então entra no else e cria as 2
	#############################################################################################
	else
			echo "Year folder didn't exist yet." >> $FILE_BKPLOG
			mkdir "${DIR_DEST}${VAR_ACTUAL_YEAR}"
			if [ $? -eq 0 ]; then 
				echo "${DIR_DEST}${VAR_ACTUAL_YEAR}: successfully created" >> $FILE_BKPLOG
			else
				echo "Failed to create ${DIR_DEST}${VAR_ACTUAL_YEAR}" >> $FILE_BKPLOG
				exit 2
			fi

			mkdir "${DIR_DEST_WDATE}"			
			if [ $? -eq 0 ]; then 
				echo "${DIR_DEST_WDATE}: successfully created" >> $FILE_BKPLOG
			else
				echo "Failed to create ${DIR_DEST_WDATE}" >> $FILE_BKPLOG
				exit 3
			fi			
	fi
}

function checkFiles {
	#Verifica se tem arquivos no diretorio
	######################################
	QTY_FILES_DIR="${ls -a $DIR_PATH | wc -l}"
	if [ $QTY_FILES_DIR -neq 0 ]; then
		echo "${DIR_PATH} is not empty..." >> $FILE_BKPLOG
		echo "Printing the list of files in the folder ${DIR_PATH} and sub folders \n\n" >> $FILE_BKPLOG
		find $DIR_PATH -type d -ls |awk '{print "Last update :" $8 " " $9 " " $10 "\tFile size: " $7 "\t File name:" $11}' >> $FILE_BKPLOG
	else
		echo "${DIR_PATH} is empty. Please verify" >> $FILE_BKPLOG
		exit 101
	fi
}

function compressFiles {
	#Compacta a pasta toda e manda pro destino
	##########################################
	echo "Compressing to tar..." >> $FILE_BKPLOG 
	cd $DIR_PATH && tar czf $DIR_DEST_WDATE/$FILE_BKPNAME.tar .
	if [ "$?" -eq 0 ]; then
			echo "${FILE_BKPNAME}.tar successfully compressed." >> $FILE_BKPLOG 
	else
			echo "Failed to compress files to ${FILE_BKPNAME}.tar" >> $FILE_BKPLOG 
			exit 201
	fi
	 
	echo "Compressing to bzip2..."
	bzip2 $DIR_DEST_WDATE/$FILE_BKPNAME.tar
	if [ "$?" -eq 0 ]; then
			echo "${FILE_BKPNAME}.tar.bz2 successfully compressed." >> $FILE_BKPLOG 
	else
			echo "Failed to compress ${FILE_BKPNAME}.tar to ${FILE_BKPNAME}.tar.bz2" >> $FILE_BKPLOG 
			exit 202
	fi
}

function backupDatabase {
	#Testa conexao com o banco
	##########################
	echo "Mysql dump started at: $(date +'%m/%d/%y %H:%M:%S')" >> $FILE_BKPLOG 
	mysqldump --user=$MYSQL_USER --password=$MYSQL_PSSWD --default-character-set=utf8 $MYSQL_DBNAME | gzip > "${DB_BKPNAME}"
	if [ "$?" -eq 0 ]; then
		echo "Mysql dumped successfully: ${DB_BKPNAME} generated." >> $FILE_BKPLOG
		echo "Mysql dump ended at: $(date +'%m/%d/%y %H:%M:%S')" >> $FILE_BKPLOG
	else
		echo "Failed to dump mysql to file ${DB_BKPNAME}." >> $FILE_BKPLOG
		exit 301		
	fi
}

function sendToServer {
	SERVER=$1
	DIR_SEND_BACKUP=$2
	USERNAME="teste"
	echo "Sending file ${FILE_BKPNAME} to the server ${SERVER})..." >> $FILE_BKPLOG
	scp $DIR_DEST_WDATE/$FILE_BKPNAME $USERNAME@$SERVER:$DIR_SEND_BACKUP
	if [ "$?" -eq 0 ]; then
		echo "File ${FILE_BKPNAME} sent successfully to the server ${SERVER}." >> $FILE_BKPLOG
	else
		echo "Failed sending the file ${FILE_BKPNAME} to the server ${SERVER}" >> $FILE_BKPLOG
		exit 401
	fi
}

###### Main function ######
echo "Script started running at: $(date +'%m/%d/%y %H:%M:%S')" >> $FILE_BKPLOG
echo "Checking folders to backup." >> $FILE_BKPLOG
echo "Checking destination folders." >> $FILE_BKPLOG
checkDestination
echo "Checking if folder is not empty." >> $FILE_BKPLOG
checkFiles
echo "Starting compression..." >> $FILE_BKPLOG
compressFiles
echo "Script finished at: $(date +'%m/%d/%y %H:%M:%S')" >> $FILE_BKPLOG

mv ${DIR_PATH}/${FILE_BKPNAME}.log ${DIR_DEST_WDATE}/.${FILE_BKPNAME}.log