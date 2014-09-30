#!/usr/bin/env python
import commands
import os
import time
import ftplib

ftp=ftplib.FTP()
HOSTNAME = commands.getoutput('hostname')
SERVICE  = commands.getoutput('ls /opt/ky/logs/%s/' % HOSTNAME)
SERVER_NUM = HOSTNAME.split('-')
SYS_TIME = commands.getoutput('date +%Y-%m-%d')
LOG_FILES = commands.getoutput('cd /opt/ky/logs/%s/%s/ && ls *.log' % (HOSTNAME,SERVICE)).split('\n')
FTP_PATH = './'+SERVICE+'/'+SERVER_NUM[4]

#define export log script
def export_log_files():
	a = os.system('ls /usr/src/log_backup &> /dev/null')
	if a==0:
		print "Start export %s logs to '/usr/src/log_backup' !!" % SYS_TIME
		time.sleep(3)
		exporting()
	else:
		print "'/usr/src/log_backup' folder not found !! \nWill create now !!"
		time.sleep(3)
		b = os.system('mkdir /usr/src/log_backup &> /dev/null')
		if b==0:
			print "Create folder success!! \nStart export %s logs to '/usr/src/log_backup' !!" % SYS_TIME
			exporting()
		else:
			print "Backup folder create fail, please check!!"

#operation of export log files
def exporting():
	for x in LOG_FILES:
		os.system('cd /opt/ky/logs/%s/%s/ && grep "%s" %s >> /usr/src/log_backup/%s-%s' % (HOSTNAME,SERVICE,SYS_TIME,x,SYS_TIME,x))
		print "export %s success" % x
		time.sleep(3)

def backup_dir_remove():
	commands.getoutput('rm -rf /usr/src/log_backup')

#FTP configuration
def ftp_connect():
	ftp.set_debuglevel(2)
	ftp.connect('172.16.1.160','5222')
	ftp.login('kaiyuan','kaiyuan2014')

def ftp_upload(file_name):
	bufsize= 1024
	file_handler = open(file_name)
	ftp.storbinary('STOR %s' % os.path.basename(file_name),file_handler,bufsize)
	file_handler.close()

def log_upload():
	export_log_files()
	ftp_connect()
	ftp.cwd(FTP_PATH)
	ftp.set_debuglevel(0)
	NEW_LOG_FILES = commands.getoutput('cd /usr/src/log_backup && ls *.log').split('\n')
	for f in NEW_LOG_FILES:
		ftp_upload('/usr/src/log_backup/%s' % f)
		print '%s upload success!' % f
	backup_dir_remove()
	ftp.close()

log_upload()
