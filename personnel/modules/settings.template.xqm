xquery version "3.0";
(: Local settings module: Copy it to settings.xml and make  
 : changes in your local copy.
 : 
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU Lesser General Public License, version 3 or later
 :)
module namespace settings="http://stsf.net/xquery/settings";

(: admin password for the database :)
declare variable $settings:admin-password := "INSERT_SOMETHING_HERE";

(: authorization key for Invision Power Board :)
declare variable $settings:ipb-auth-key := "INSERT_SOMETHING_HERE";

(: first administrative users :)
declare variable $settings:admin-users := ("Insert", "Names", "Here");

(: admin users' member numbers in the boards :)
declare variable $settings:admin-numbers := (Insert, Numbers, Here);

(: email addresses for first administrative users :)
declare variable $settings:admin-emails := ("Insert", "Email Addresses", "Here");

(: Database base URL. It is safe to leave this as is. :)
declare variable $settings:absolute-url-base := "/exist/apps/personnel";
