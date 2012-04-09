xquery version "3.0";
(: Return a list of open positions
 :
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU LGPL 3+
 :)
import module namespace ship="http://stsf.net/xquery/ships"
  at "xmldb:exist:///personnel/modules/ships.xqm";
import module namespace prs="http://stsf.net/xquery/personnel"
  at "xmldb:exist:///personnel/modules/personnel.xqm";
  
declare namespace s="http://stsf.net/personnel/ships";
declare namespace x="http://stsf.net/personnel/extended";

element x:positions {
  for $position-by-all in collection($ship:ship-collection)//s:position[s:status=("open","reserved")]
  group $position-by-all as $position-by-ship by $position-by-all/ancestor::s:ship/s:name as $ship-name
  return
    element x:ship {
      $ship-name,
      for $position-by-s in $position-by-ship
      group $position-by-s as $position-by-dept by $position-by-s/ancestor::s:department/s:name as $dept
      return 
        element x:department {
          $dept,
          (: each identical position should only have one entry :)
          for $position in $position-by-dept
          where $position/s:status=("open", "reserved"[prs:is-administrator() or ship:is-game-master($ship-name)])
          group $position as $position-by-name by $position/s:name as $name 
          return
            element x:position {
              $name,
              $position-by-name/s:id
            }
        }
    }
}