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

(: email address that mail comes from :)
declare variable $settings:from-email-address := "personnel@forum.com";

(: SMTP server :)
declare variable $settings:smtp-server := "localhost";

(: update interval for full board name refresh
 : full refresh will hit stsf.net a lot!
 : default: 7 days
 : Format: P[days]DT[hours]H[minutes]M[seconds]S
 :)
declare variable $settings:boardnames-refresh-interval :=
   xs:dayTimeDuration("P7DT0H0M0S");

(: update interval for partial board name refresh
 : to get new members
 : default: 1 day
 : Format: P[days]DT[hours]H[minutes]M[seconds]S
 :)
declare variable $settings:boardnames-update-interval :=
   xs:dayTimeDuration("P1DT0H0M0S");

(: Database base URL. It is safe to leave this as is. :)
declare variable $settings:absolute-url-base := "/exist/apps/personnel";
