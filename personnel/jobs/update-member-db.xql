xquery version "3.0";
(: 
 : automatically update or refresh the board names database
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU LGPL 3 or above
 :)
import module namespace mem="http://stsf.net/xquery/members"
  at "xmldb:exist:///personnel/modules/members.xqm";
import module namespace settings="http://stsf.net/xquery/settings"
  at "xmldb:exist:///personnel/modules/settings.xqm";

declare namespace m="http://stsf.net/personnel/members";  

let $duration := 
  current-dateTime() - 
  xmldb:last-modified($mem:member-collection, $mem:board-db)
return
  if ($duration >= $settings:boardnames-refresh-interval
    or count(doc($mem:board-db-uri)//m:boardname)=0)
  then mem:refresh-board-name-db()
  else if ($duration >= $settings:boardnames-update-interval)
  then mem:update-board-name-db()
  else ()