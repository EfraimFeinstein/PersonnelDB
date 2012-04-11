xquery version "3.0";
(: Edit a ship
 : Note: can only be used by administrators or authorized GMs
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
import module namespace ship="http://stsf.net/xquery/ships"
  at "xmldb:exist:///db/personnel/modules/ships.xqm";

declare namespace s="http://stsf.net/personnel/ships";
declare namespace x="http://stsf.net/personnel/extended";
declare namespace error="http://stsf.net/error";

let $data := request:get-data()/s:ship 
let $success := ship:edit-ship(prs:remove-extensions($data))
where $success
return ship:transform-extended($data)