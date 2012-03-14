INSTALL_JAR = setup/eXist-setup-2.0-tech-preview.jar
INSTALL_DIR = /usr/local/personnel
PASSWORD = StarTrekSimulationForum
EXISTBACKUP ?= java -Dexist.home=$(INSTALL_DIR) -jar $(INSTALL_DIR)/start.jar org.exist.backup.Main 
XSLTOPTIONS ?= -ext:on 
SAXONJAR ?= $(INSTALL_DIR)/lib/endorsed/saxonhe-9.2.1.5.jar
JCLASSPATH ?= "$(SAXONJAR):$(RESOLVERPATH):$(COMMONDIR)"
SAXONCLASS ?= net.sf.saxon.Transform
XSLT ?= java $(JAVAOPTIONS) -cp "$(JCLASSPATH)" $(SAXONCLASS)  $(XSLTOPTIONS) 

install:
	java -jar $(INSTALL_JAR) -p $(INSTALL_DIR)
	$(XSLT) -s $(INSTALL_DIR)/conf.xml -o $(INSTALL_DIR)/conf.xml setup/setup-conf-xml.xsl2 
	echo "xmldb:change-user('admin', '$(PASSWORD)', (), ())" | $(INSTALL_DIR)/bin/client.sh -u "admin" -qls -x  
	setup/makedb.py -x setup/exclude -h $(INSTALL_DIR) .
	$(EXISTBACKUP) -r ./__contents__.xml -u admin -P "$(PASSWORD)" -p "$(PASSWORD)" -ouri=xmldb:exist:// 
	echo "import module namespace prs='http://stsf.net/xquery/personnel' at 'xmldb:exist:///db/personnel/modules/personnel.xqm'; prs:setup()" | $(INSTALL_DIR)/bin/client.sh -u "admin" -P "$(PASSWORD)" -qls -x  

uninstall:
	rm -fr $(INSTALL_DIR)

