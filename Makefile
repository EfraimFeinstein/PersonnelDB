INSTALL_JAR = setup/eXist-setup-2.0-tech-preview.jar
INSTALL_DIR = /usr/local/personnel
PASSWORD = StarTrekSimulationForum
EXISTBACKUP ?= java -Dexist.home=$(INSTALL_DIR) -jar $(INSTALL_DIR)/start.jar org.exist.backup.Main 

install:
	java -jar $(INSTALL_JAR) -p $(INSTALL_DIR)
	echo "xmldb:change-user('admin', '$(PASSWORD)', (), ())" | $(INSTALL_DIR)/bin/client.sh -u "admin" -qls -x  
	setup/makedb.py -x setup/exclude -h $(INSTALL_DIR) .
	$(EXISTBACKUP) -r ./__contents__.xml -u admin -P "$(PASSWORD)" -p "$(PASSWORD)" -ouri=xmldb:exist:// 
	echo "import module namespace prs='http://stsf.net/xquery/personnel' at 'xmldb:exist:///db/personnel/modules/personnel.xqm'; prs:setup()" | $(INSTALL_DIR)/bin/client.sh -u "admin" -P "$(PASSWORD)" -qls -x  

uninstall:
	rm -fr $(INSTALL_DIR)

