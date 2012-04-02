xquery version "3.0";
(: Edit the selected player's XML records
 : Note: cannot be used by non-administrators 
 :    to add characters or applications
 : Method: POST
 : Return:
 :  200 OK
 :  400 Error
 :
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU Lesser General Public License, version 3 or later
 :)

import module namespace prs="http://stsf.net/xquery/personnel"
  at "xmldb:exist:///db/personnel/modules/personnel.xqm";
import module namespace pl="http://stsf.net/xquery/players"
  at "xmldb:exist:///db/personnel/modules/players.xqm";

declare namespace p="http://stsf.net/personnel/players";
declare namespace error="http://stsf.net/error";

let $data := request:get-data()/p:player 
let $success := pl:edit-player(prs:remove-extensions($data))
return $data