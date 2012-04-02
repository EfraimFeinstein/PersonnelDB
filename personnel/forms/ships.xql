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
import module namespace ship="http://stsf.net/xquery/ships"
  at "/db/personnel/modules/ships.xqm";
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
declare namespace x="http://stsf.net/personnel/extended";

let $member-number := session:get-attribute("member-number")
let $ship := request:get-parameter("ship", ())
let $new := not($ship) or string($ship) = "new"
let $is-gm := ship:is-game-master($ship)
let $is-admin := prs:is-administrator() 
return
  site:form(
    <xf:model>
      <xf:instance id="ship-instance"
        src="{$settings:absolute-url-base}/queries/get-ship.xql?ship={$ship}">
      </xf:instance>
      <xf:bind nodeset="instance('ship-instance')/s:beginTime" type="xf:time"/>
      <xf:bind nodeset="instance('ship-instance')/s:endTime" type="xf:time"/>
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
      <xf:instance id="approve-instance">
        <x:approve>
          <x:ship>{$ship}</x:ship>
          <x:position/>
        </x:approve>
      </xf:instance>
      <xf:instance id="reject-instance">
        <x:reject>
          <x:ship>{$ship}</x:ship>
          <x:position/>
        </x:reject>
      </xf:instance>
      <xf:instance id="leave-instance">
        <x:leave>
          <x:ship>{$ship}</x:ship>
          <x:position/>
        </x:leave>
      </xf:instance>
      <xf:instance id="unassign-instance">
        <x:unassign>
          <x:ship>{$ship}</x:ship>
          <x:position/>
        </x:unassign>
      </xf:instance>
      <xf:instance id="reassign-instance">
        <x:reassign>
          <x:ship>{$ship}</x:ship>
          <x:department/>
          <x:position/>
          <x:character/>
        </x:reassign>
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
          for $gm in ship:get-game-master-players($ship)
          return <gm>{$gm/(p:name, p:boardName)[1]/string()}</gm>
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
      <xf:submission 
        id="approve-submit"
        method="post"
        resource="{$settings:absolute-url-base}/queries/approve.xql"
        ref="instance('approve-instance')"
        replace="none"
        >
        <xf:action ev:event="xforms-submit-done">
          <xf:message>Posting approved successfully.</xf:message>
        </xf:action>
        <xf:action ev:event="xforms-submit-error">
          <xf:message>Error: 
          <xf:output value="event('response-body')"/></xf:message>
        </xf:action>
      </xf:submission>      
      <xf:submission 
        id="reject-submit"
        method="post"
        resource="{$settings:absolute-url-base}/queries/reject.xql"
        ref="instance('reject-instance')"
        replace="none"
        >
        <xf:action ev:event="xforms-submit-done">
          <xf:message>Posting rejected successfully.</xf:message>
        </xf:action>
        <xf:action ev:event="xforms-submit-error">
          <xf:message>Error: 
          <xf:output value="event('response-body')"/></xf:message>
        </xf:action>
      </xf:submission>
      <xf:submission 
        id="unassign-submit"
        method="post"
        resource="{$settings:absolute-url-base}/queries/unassign.xql"
        ref="instance('unassign-instance')"
        replace="none"
        >
        <xf:action ev:event="xforms-submit-done">
          <xf:message>Posting unassigned successfully.</xf:message>
        </xf:action>
        <xf:action ev:event="xforms-submit-error">
          <xf:message>Error: 
          <xf:output value="event('response-body')"/></xf:message>
        </xf:action>
      </xf:submission>
      <xf:submission 
        id="leave-submit"
        method="post"
        resource="{$settings:absolute-url-base}/queries/leave.xql"
        ref="instance('leave-instance')"
        replace="none"
        >
        <xf:action ev:event="xforms-submit-done">
          <xf:message>Extended leave granted successfully.</xf:message>
        </xf:action>
        <xf:action ev:event="xforms-submit-error">
          <xf:message>Error: 
          <xf:output value="event('response-body')"/></xf:message>
        </xf:action>
      </xf:submission>
      <xf:submission 
        id="reassign-submit"
        method="post"
        resource="{$settings:absolute-url-base}/queries/reassign.xql"
        ref="instance('reassign-instance')"
        replace="none"
        >
        <xf:action ev:event="xforms-submit-done">
          <xf:message>Character reassigned successfully.</xf:message>
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
      <xf:group class="meeting-time">
        <xf:select1 ref="s:day">
          <xf:label>Meeting day: </xf:label>
          {
            for $day in ("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")
            return
              <xf:item>
                <xf:label>{$day}</xf:label>
                <xf:value>{$day}</xf:value>
              </xf:item>
          }
        </xf:select1>
        <xf:input ref="s:beginTime">
          <xf:label>Starts at: </xf:label>
        </xf:input>
        <xf:input ref="s:endTime">
          <xf:label>Ends at: </xf:label>
        </xf:input>
      </xf:group>
      <xf:textarea ref="s:description">
        <xf:label>Short description:</xf:label>
      </xf:textarea>
      <xf:group class="roster-editor" ref="s:roster">
        <xf:repeat nodeset="s:unassigned/">
          <xf:label>Unassigned players</xf:label>
          <xf:repeat id="unassigned" nodeset="s:heldBy">
            <xf:output ref="@x:boardName">
              <xf:label>Player: </xf:label>
            </xf:output>
            <xf:trigger>
              <xf:label>Reassign</xf:label>
              <xf:action ev:event="DOMActivate">
                <xf:setvalue ref="instance('reassign-instance')/x:character" value="context()"/>
                <xf:show dialog="reassign-dialog"/>
              </xf:action>
            </xf:trigger>
            <xf:dialog id="reassign-dialog">
              <xf:select1 ref="instance('reassign-instance')/x:department" appearance="compact">
                <xf:label>Select department:</xf:label>
                <xf:itemset nodeset="instance('ship-instance')//s:department">
                  <xf:label ref="s:name"/>
                  <xf:value ref="s:name"/>
                </xf:itemset>
              </xf:select1>
              <xf:select1 ref="instance('reassign-instance')/x:position" appearance="compact">
                <xf:label>Select position:</xf:label>
                <xf:itemset nodeset="instance('ship-instance')//s:department[s:name=instance('reassign-instance')/x:department]/s:position[s:status='open' or s:status='reserved']">
                  <xf:label ref="s:name"/>
                  <xf:value ref="s:id"/>
                </xf:itemset>
              </xf:select1>
              <xf:trigger ref="instance('reassign-instance')/x:position[.]">
                <xf:label>Reassign</xf:label>
                <xf:action ev:event="DOMActivate">
                  <xf:hide dialog="reassign-dialog"/>
                  <xf:send submission="reassign-submit"/>
                </xf:action>
              </xf:trigger>
              <xf:trigger>
                <xf:label>Cancel</xf:label>
                <xf:action ev:event="DOMActivate">
                  <xf:hide dialog="reassign-dialog"/>
                </xf:action>
              </xf:trigger>
            </xf:dialog>
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
            <xf:select1 ref="s:status[not(.='pending' or .='filled')]">
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
            <xf:output ref="s:status[.='pending' or .='filled']">
              <xf:label>Status:</xf:label>
            </xf:output>
            <xf:output ref="s:heldBy/@x:boardName">
              <xf:label>Held by: </xf:label>
            </xf:output>
            <xf:trigger ref="s:status[.='pending']">
              <xf:label>Approve</xf:label>
              <xf:action ev:event="DOMActivate">
                <xf:setvalue ref="instance('approve-instance')/x:position" value="context()/../s:id"/>
                <xf:send submission="approve-submit"/>
              </xf:action>
            </xf:trigger>
            <xf:trigger ref="s:status[.='pending']">
              <xf:label>Reject</xf:label>
              <xf:action ev:event="DOMActivate">
                <xf:setvalue ref="instance('reject-instance')/x:position" value="context()/../s:id"/>
                <xf:send submission="reject-submit"/>
              </xf:action>
            </xf:trigger>
            <xf:trigger ref="s:status[.='filled']">
              <xf:label>Put on XLOA</xf:label>
              <xf:action ev:event="DOMActivate">
                <xf:setvalue ref="instance('leave-instance')/x:position" value="context()/../s:id"/>
                <xf:send submission="leave-submit"/>
              </xf:action>
            </xf:trigger>
            <xf:trigger ref="s:status[.='filled']">
              <xf:label>Unassign</xf:label>
              <xf:action ev:event="DOMActivate">
                <xf:setvalue ref="instance('unassign-instance')/x:position" value="context()/../s:id"/>
                <xf:send submission="unassign-submit"/>
              </xf:action>
            </xf:trigger>
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