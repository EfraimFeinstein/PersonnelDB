xquery version "3.0";
(: Return a list of open positions
 :
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU LGPL 3+
 :)
import module namespace ship="http://stsf.net/xquery/ships"
  at "xmldb:exist:///personnel/modules/ships.xqm";
  
declare namespace s="http://stsf.net/personnel/ships";
declare namespace x="http://stsf.net/personnel/extended";

element x:positions {
  for $position-by-all in collection($ship:ship-collection)//s:position[s:status="open"]
  group $position-by-all as $position-by-ship by $position-by-all/ancestor::s:ship/s:name as $ship-name
  return
    element x:ship {
      $ship-name,
      for $position-by-s in $position-by-ship
      group $position-by-s as $position-by-dept by $position-by-s/ancestor::s:department/s:name as $dept
      return 
        element x:department {
          $dept,
          for $position in $position-by-dept
          return
            element x:position {
              $position/s:name,
              $position/s:id
            }
        }
    }
}