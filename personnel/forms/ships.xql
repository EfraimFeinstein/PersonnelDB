xquery version "3.0";
(: ships form
 : 
 : Only GMs and administrators can use this form effectively
 : Calling it with ?ship=name is required
 :
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU Lesser General Public License
 :)
import module namespace prs="http://stsf.net/xquery/personnel"
  at "/db/personnel/modules/personnel.xqm";
import module namespace pl="http://stsf.net/xquery/players"
  at "/db/personnel/modules/players.xqm";
import module namespace mem="http://stsf.net/xquery/members"
  at "/db/personnel/modules/members.xqm";
import module namespace site="http://stsf.net/xquery/site"
  at "/db/personnel/modules/site.xqm";
import module namespace settings="http://stsf.net/xquery/settings"
  at "/db/personnel/modules/settings.xqm";

declare default element namespace "http://www.w3.org/1999/xhtml";
declare namespace ev="http://www.w3.org/2001/xml-events";
declare namespace xf="http://www.w3.org/2002/xforms";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace p="http://stsf.net/personnel/players";
declare namespace s="http://stsf.net/personnel/ships";

let $member-number := session:get-attribute("member-number")
let $ship := request:get-parameter("ship", ())
let $new := not($ship) or string($ship) = "new"
let $is-gm := prs:is-game-master()
let $is-admin := prs:is-administrator() 
return
  site:form(
    <xf:model>
      <xf:instance id="ship-instance"
        src="{$settings:absolute-url-base}/queries/get-ship.xql?ship={$ship}">
      </xf:instance>
      <xf:instance id="new-department-instance">
        <s:department>
          <s:name/>
        </s:department>
      </xf:instance>
      <xf:instance id="new-position-instance">
        <s:position>
          <s:id/>
          <s:name/>
          <s:status>open</s:status>
          <s:heldBy/>
        </s:position>
      </xf:instance>
      <xf:instance id="new-department-options">
        <new-dept xmlns="">
          <n-chiefs>1</n-chiefs>
          <n-assts>3</n-assts>
          <counter/>
        </new-dept>
      </xf:instance>
      <xf:instance id="game-masters">
        <gms xmlns="">{
          for $gm in sm:get-group-members(concat($ship, " GM"))
          return <gm>{mem:board-name-by-member-name($gm)}</gm>
        }</gms>
      </xf:instance>
      <xf:submission 
        id="edit-ship-submit"
        method="post"
        ref="instance('ship-instance')"
        replace="instance"
        instance="ship-instance"
        >
        <xf:resource value="concat('{$settings:absolute-url-base}/queries/edit-ship.xql?ship=', instance('ship-instance')/s:name)"/>
        <xf:action ev:event="xforms-submit-done">
          <xf:message>Ship {
            if ($new)
            then "added"
            else "edited"
          } successfully.</xf:message>
          {
            if ($new)
            then
              <xf:load>
                <xf:resource value="concat('{$settings:absolute-url-base}/forms/ships?ship=', instance('ship-instance')/s:name)"/>
              </xf:load>
            else ()
          }
        </xf:action>
        <xf:action ev:event="xforms-submit-error">
          <xf:message>Error: 
          <xf:output value="event('response-body')"/></xf:message>
        </xf:action>
      </xf:submission>      
    </xf:model>,
    <title>{
      if ($new)
      then "Add new ship"
      else "Edit ship"
    }</title>,
    (
    <xf:group class="ship-editor" ref="instance('ship-instance')">
      <xf:input ref="s:name">
        <xf:label>Ship name: </xf:label>
      </xf:input>
      <xf:group class="ship-game-masters">{
        if ($ship != "new")
        then
          <xf:repeat nodeset="instance('game-masters')/gm">
            <xf:output ref=".">
              <xf:label>GM: </xf:label>
            </xf:output>
          </xf:repeat>
        else (),
        if ($is-admin)
        then <span class="no-gms">Game masters can be assigned in the <a href="{$settings:absolute-url-base}/forms/players">player console</a>.</span>
        else () 
      }</xf:group>
      <xf:group class="roster-editor" ref="s:roster">
        <xf:repeat nodeset="s:unassigned/">
          <xf:label>Unassigned players</xf:label>
          <xf:repeat nodeset="s:heldBy">
            <xf:output ref=".">
              <xf:label>Player: </xf:label>
            </xf:output>
          </xf:repeat>
        </xf:repeat>
        <xf:repeat nodeset="s:department">
          <xf:input ref="s:name">
            <xf:label>Name:</xf:label>
          </xf:input>
          <xf:trigger>
            <xf:label>Remove department</xf:label>
            <xf:action ev:event="DOMActivate">
              <xf:action if="not(s:position/s:heldBy='')">
                <xf:message>Removing the department. Any players not also assigned elsewhere will be place into the "unassigned" category</xf:message>             
              </xf:action>
              <xf:insert 
                origin="s:position/s:heldBy[not(//s:unassigned/s:heldBy=.)][count(//s:position/s:heldBy[.=current()])=1]"
                context="//s:unassigned"
                />
              <xf:delete nodeset="."/>
            </xf:action>
          </xf:trigger>
          <xf:repeat nodeset="s:position">
            <!-- this is here for debugging -->
            <xf:output ref="s:id">
              <xf:label>Position Id: </xf:label>
            </xf:output>
            <xf:input ref="s:name">
              <xf:label>Position: </xf:label>
            </xf:input>
            <xf:select1 ref="s:status">
              <xf:label>Status:</xf:label>
              <xf:item>
                <xf:label>Open</xf:label>
                <xf:value>open</xf:value>
              </xf:item>
              <xf:item>
                <xf:label>Reserved</xf:label>
                <xf:value>reserved</xf:value>
              </xf:item>
            </xf:select1>
            <xf:output ref="s:heldBy">
              <xf:label>Held by: </xf:label>
            </xf:output>
            <xf:trigger>
              <xf:label>Duplicate position</xf:label>
              <xf:action ev:event="DOMActivate">
                <xf:insert 
                  origin="instance('new-position-instance')"
                  nodeset="." 
                  position="after"/>
                <xf:setvalue ref="following-sibling::s:position[1]/s:id" 
                  value="//s:id[not(//s:id &gt; .)] + 1"/>
                <xf:setvalue ref="following-sibling::s:position[1]/s:name"
                  value="context()/s:name"/>
              </xf:action>
            </xf:trigger>
            <xf:trigger>
              <xf:label>Remove position</xf:label>
              <xf:action ev:event="DOMActivate">
                <xf:message if="not(s:heldBy='')">If not already assigned to another position, the player will be placed in the "unassigned" category</xf:message>             
                <xf:insert 
                  origin="s:heldBy[not(//s:unassigned/s:heldBy=.)][count(//s:heldBy[.=current()])=1]"
                  context="//s:unassigned"
                  />
                <xf:delete nodeset="."/>
              </xf:action>
            </xf:trigger>
          </xf:repeat>
        </xf:repeat>
        <xf:group class="new-department" ref="instance('new-department-instance')">
          <xf:input ref="s:name">
            <xf:label>Department name: </xf:label>
          </xf:input>
          <xf:input ref="instance('new-department-options')/n-chiefs">
            <xf:label>Number of chiefs (reserved spots): </xf:label>
          </xf:input>
          <xf:input ref="instance('new-department-options')/n-assts">
            <xf:label>Number of assistants (open spots): </xf:label>
          </xf:input>
          <xf:trigger ref="instance('new-department-options')">
            <xf:label>Add new department</xf:label>
            <xf:action ev:event="DOMActivate">
              <!-- copy the department template -->
              <xf:insert 
                nodeset="instance('ship-instance')/s:roster/s:department" 
                origin="instance('new-department-instance')" 
                at="last()"
                position="after"/>
              <!-- set chief positions -->
              <xf:setvalue ref="instance('new-department-options')/counter" value="1"/>
              <xf:action while="instance('new-department-options')/counter &lt;= instance('new-department-options')/n-chiefs">
                <xf:insert 
                  origin="instance('new-position-instance')"
                  nodeset="instance('ship-instance')/s:roster/s:department[last()]/*"
                  at="last()"
                  position="after"
                  />
                <xf:setvalue 
                  ref="instance('ship-instance')/s:roster/s:department[last()]/s:position[last()]/s:id"
                  value="instance('ship-instance')//s:id[not(//s:id &gt; .)] + 1"/>
                <xf:setvalue 
                  ref="instance('ship-instance')/s:roster/s:department[last()]/s:position[last()]/s:name"
                  value="'Chief'"/>
                <xf:setvalue 
                  ref="instance('ship-instance')/s:roster/s:department[last()]/s:position[last()]/s:status"
                  value="'reserved'"/>
                <xf:setvalue ref="instance('new-department-options')/counter" value="instance('new-department-options')/counter + 1"/>
              </xf:action>
              <!-- set up assistant positions -->
              <xf:setvalue ref="instance('new-department-options')/counter" value="1"/>
              <xf:action while="instance('new-department-options')/counter &lt;= instance('new-department-options')/n-assts">
                <xf:insert 
                  origin="instance('new-position-instance')"
                  nodeset="instance('ship-instance')/s:roster/s:department[last()]/*"
                  at="last()"
                  position="after"
                  />
                <xf:setvalue 
                  ref="instance('ship-instance')/s:roster/s:department[last()]/s:position[last()]/s:id"
                  value="instance('ship-instance')//s:id[not(//s:id &gt; .)] + 1"/>
                <xf:setvalue 
                  ref="instance('ship-instance')/s:roster/s:department[last()]/s:position[last()]/s:name"
                  value="'Assistant'"/>
                <xf:setvalue ref="instance('new-department-options')/counter" value="instance('new-department-options')/counter + 1"/>
              </xf:action>
              <!-- done, clear -->
              <xf:setvalue ref="instance('new-department-instance')/s:name" value="''"/>
              <xf:setvalue ref="instance('new-department-options')/n-chiefs" value="1"/>
              <xf:setvalue ref="instance('new-department-options')/n-assts" value="3"/>
            </xf:action>
            
          </xf:trigger>
        </xf:group>
      </xf:group>
      <xf:trigger>
        <xf:label>{
          if ($new)
          then "Add ship"
          else "Edit ship"
        }</xf:label>
        <xf:send ev:event="DOMActivate" submission="edit-ship-submit"/>
      </xf:trigger>
    </xf:group>
    )
  )