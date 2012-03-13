xquery version "3.0";
(: Log out the current user
 : Method: any
 : 
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU Lesser General Public License, version 3 or later
 :)

session:clear(),
response:set-status-code(204)