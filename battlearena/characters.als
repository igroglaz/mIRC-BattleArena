;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; characters.als
;;;; Last updated: 03/15/22
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Starting character checks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
starting_character_checks {
  set %file $nopath($1-) 
  set %name $remove(%file,.char)

  if (%name = $null) { return }
  if (%name = new_chr) { return }
  if ($readini($char(%name), info, flag) = npc) { return }
  if ($readini($char(%name), info, flag) = monster) { return }

  if ($readini(system.dat, system, EnableDNSCheck) = true) { 
    var %last.ip $readini($char(%name), info, lastIP) 
    if (%last.ip = %ip.to.check) {  inc %duplicate.ips 1 }
  }

  var %temp.shoplevel $readini($char(%name), Stuff, ShopLevel)
  if (%temp.shoplevel = $null) { var %temp.shoplevel 1 }
  inc %current.shoplevel %temp.shoplevel

  inc %totalplayers 1

  unset %name | unset %file | unset %ip.address. [ $+ [ $1 ] ]
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Allows chars to add/remove
; access to his/her characters
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
character.access {
  if ($2 = add) { 
    $checkchar($3)
    var %player.access.list $readini($char($1), access, list)
    if (%player.access.list = $null) { writeini $char($1) access list $nick | var %player.access.list $nick }
    if ($istok(%player.access.list,$3,46) = $true) {  $display.private.message2($1, $readini(translation.dat, errors, AccessCommandAlreadyHasAccess)) | halt }
    var %player.access.list $addtok(%player.access.list, $3,46) | writeini $char($1) access list %player.access.list | $display.private.message2($1, $readini(translation.dat, system, AccessCommandAdd)) | halt 
  }

  if ($2 = remove) { 
    var %player.access.list $readini($char($1), access, list)
    if (%player.access.list = $null) { writeini $char($1) access list $nick | var %player.access.list $nick }
    if ($istok(%player.access.list,$3,46) = $true) {   
      if ($3 != $1) { var %player.access.list $remtok(%player.access.list, $3,46) | writeini $char($1) access list %player.access.list | $display.private.message2($1, $readini(translation.dat, system, AccessCommandRemove)) | halt }
      if ($3 = $1) { $display.private.message2($1, $readini(translation.dat, errors, AccessCommandCan'tRemoveSelf)) }
    }
  }

  if ($2 = list) {
    var %player.access.list $readini($char($1), access, list)
    if (%player.access.list = $null) { writeini $char($1) access list $nick | var %player.access.list $nick }
    set %replacechar $chr(044) $chr(032)
    %player.access.list = $replace(%player.access.list, $chr(046), %replacechar)  
    unset %replacechar
    $display.private.message2($1, $readini(translation.dat, system, AccessCommandList)) 
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Get the character's real
; name
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
set_chr_name {
  set %real.name $readini($char($1), BaseStats, Name)
  if (%real.name = $null) { set %real.name $1 | return }
  else { return }
}

get_chr_name {
  var %tmp.real.name $readini($char($1), BaseStats, Name)
  if (%tmp.real.name = $null) { return $1 }
  else { return %tmp.real.name }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Returns the character's
; current potion effect
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return.potioneffect {
  var %potion.effect $readini($char($1), status, potioneffect)
  if (%potion.effect = $null) { return none }
  else { return %potion.effect }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Get the character's current
; player style
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return.playerstyle {
  return $readini($char($1), styles, equipped)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Get the character's shop
; level
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return.shoplevel {
  ; $1 = the short name of the character to check.
  ; $2 = if set to true, the minimum shop level will not be checked.

  var %char.shoplevel $readini($char($1), stuff, shoplevel) 
  var %min.shoplevel $return.minshoplevel($1)

  if (!$2 && %char.shoplevel < %min.shoplevel) { writeini $char($1) stuff shoplevel %min.shoplevel | var %char.shoplevel %min.shoplevel }

  return %char.shoplevel
}

return.minshoplevel {
  if ($get.level.basestats($1) <= 100) { var %min.shoplevel 1.0 }
  var %min.shoplevel $round($calc($log($get.level.basestats($1)) - 2.6),1)
  if (%min.shoplevel > 5) { var %min.shoplevel 5.0 }
  return %min.shoplevel
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Returns red orb amount
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_redorbs {
  ; $1 = the person you're checking

  var %tmp.redorbs $readini($char($1), stuff, redorbs)
  if (%tmp.redorbs = $null) { return 0 }
  else { return %tmp.redorbs }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Returns orbs on hand + spent
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return.totalorbs {
  var %orbs.onhand $readini($char($1), stuff, redorbs)
  var %orbs.spent $readini($char($1), stuff, RedOrbsSpent)
  var %total.orbs $calc(%orbs.onhand + %orbs.spent)
  if (%total.orbs = $null) { return 0 }
  else { return %total.orbs }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Returns gender of char
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
gender { return $readini($char($1), Info, Gender) }
gender2 {
  if ($gender($1) = her) { return her }
  if ($gender($1) = its) { return it }
  else { return him }
}
gender3 {
  if ($gender($1) = her) { return she }
  if ($gender($1) = its) { return it }
  else { return he }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a target's HP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
character.hp.check { 
  ; $1 = the person we're checking
  ; $2 = public or private

  if ($readini($char($1), info, flag) != $null) {
    if ($2 = public) { $display.message($readini(translation.dat, errors, Can'tUseCommandOnMonsters), private) } 
    if ($2 = private) { $display.private.message($readini(translation.dat, errors, Can'tUseCommandOnMonsters)) } 
    halt
  }

  $set_chr_name($1) | $hp_status_hpcommand($1) 
  if ($person_in_mech(1) = true) { 
    var %mech.name $readini($char($1), mech, name) | $hp_mech_hpcommand($1) 
    if ($2 = public) { $display.message($readini(translation.dat, system, ViewMyMechHP), private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewMyMechHP)) }
  }
  else { 
    if ($2 = public) { $display.message($readini(translation.dat, system, ViewMyHP), private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewMyHP)) }
  }

  unset %real.name | unset %hstats 
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a target's TP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
character.tp.check { 
  ; $1 = the person we're checking
  ; $2 = public or private

  if ($readini($char($1), info, flag) != $null) {
    if ($2 = public) { $display.message($readini(translation.dat, errors, Can'tUseCommandOnMonsters), private) } 
    if ($2 = private) { $display.private.message($readini(translation.dat, errors, Can'tUseCommandOnMonsters)) } 
    halt
  }

  $set_chr_name($1) 
  if ($2 = public) { $display.message($readini(translation.dat, system, ViewMyTP), private) }
  if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewMyTP)) }

  unset %real.name 
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a target's TP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
character.ig.check { 
  ; $1 = the person we're checking
  ; $2 = public or private

  if ($readini($char($1), info, flag) != $null) {
    if ($2 = public) { $display.message($readini(translation.dat, errors, Can'tUseCommandOnMonsters), private) } 
    if ($2 = private) { $display.private.message($readini(translation.dat, errors, Can'tUseCommandOnMonsters)) } 
    halt
  }

  $set_chr_name($1) 
  if ($2 = public) { $display.message($readini(translation.dat, system, ViewMyIG), private) }
  if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewMyIG)) }

  unset %real.name 
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Returns current stats
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
current.hp { return $readini($char($1), battle, hp) }
current.str { return $readini($char($1), battle, str) }
current.def { return $readini($char($1), battle, def) }
current.int { return $readini($char($1), battle, int) }
current.spd { return $readini($char($1), battle, spd) }

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Calculates the bonus stats
; This is from armor/weapons/food
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
armor.stat {
  ; $1 = the person we're checking
  ; $2 = the stat we're checking

  ; when a player is level synced the armor bonus is added into their stats
  ; thus we do not need to count it again.
  if ($readini($char($1), info, levelsync) = yes) { return 0 }

  var %armor.stat 0

  ; Check for each armor part
  if (($return.equipped($1, head) != nothing) && ($return.equipped($1, head) != none)) { inc %armor.stat $readini($dbfile(equipment.db), $return.equipped($1, head), $2) }
  if (($return.equipped($1, body) != nothing) && ($return.equipped($1, body) != none)) { inc %armor.stat $readini($dbfile(equipment.db), $return.equipped($1, body), $2) }
  if (($return.equipped($1, legs) != nothing) && ($return.equipped($1, legs) != none)) { inc %armor.stat $readini($dbfile(equipment.db), $return.equipped($1, legs), $2) }
  if (($return.equipped($1, feet) != nothing) && ($return.equipped($1, feet) != none)) { inc %armor.stat $readini($dbfile(equipment.db), $return.equipped($1, feet), $2) }
  if (($return.equipped($1, hands) != nothing) && ($return.equipped($1, hands) != none)) { inc %armor.stat $readini($dbfile(equipment.db), $return.equipped($1, hands), $2) }

  return %armor.stat
}


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Calculates the protection value
; This is from armor/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
armor.protection {
  ; $1 = the person we're checking

  var %armor.protection 0

  ; Check for each armor part
  if (($return.equipped($1, head) != nothing) && ($return.equipped($1, head) != none)) { inc %armor.protection $readini($dbfile(equipment.db), $return.equipped($1, head), Protection) }
  if (($return.equipped($1, body) != nothing) && ($return.equipped($1, body) != none)) { inc %armor.protection $readini($dbfile(equipment.db), $return.equipped($1, body), Protection) }
  if (($return.equipped($1, legs) != nothing) && ($return.equipped($1, legs) != none)) { inc %armor.protection $readini($dbfile(equipment.db), $return.equipped($1, legs), Protection) }
  if (($return.equipped($1, feet) != nothing) && ($return.equipped($1, feet) != none)) { inc %armor.protection $readini($dbfile(equipment.db), $return.equipped($1, feet), Protection) }
  if (($return.equipped($1, hands) != nothing) && ($return.equipped($1, hands) != none)) { inc %armor.protection $readini($dbfile(equipment.db), $return.equipped($1, hands), Protection) }

  if ($readini($char($1), skills, sentinel.on) = on) { writeini $char($1) skills sentinel.on off | inc %armor.protection 10 }

  if (%armor.protection = $null) { return 0 }
  else { return %armor.protection }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Returns enmity name
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
character.enmity.getname {
  ; $1 = highest or lowest

  if ($1 = highest) { 
    ; Look through the enmity list and find who has the largest enmity value
    var %current.enmity.amount 0 
    var %current.enmity.counter 1 |  var %number.of.enmity.targets $numtok($return_peopleinbattle, 46)
    var %highest.enmity no one

    while (%current.enmity.counter <= %number.of.enmity.targets) { 
      var %current.enmity.name $gettok($return_peopleinbattle, %current.enmity.counter, 46)

      ; Is this person dead? if so, remove from the enmity list. 
      if ($readini($char(%current.enmity.name), Battle, Status) = dead) { remini $txtfile(battle2.txt) enmity %current.enmity.name }

      ; Has the person fled? If so, remove from the enmity list
      if ($readini($char(%current.enmity.name), Battle, Status) = runaway) { remini $txtfile(battle2.txt) enmity %current.enmity.name }

      ; Is this person a monster? If so, remove from enmity list.
      if ($readini($char(%current.enmity.name), Info, Flag) = monster) { remini $txtfile(battle2.txt) enmity %current.enmity.name }

      ; Grab the current enmity amount of the person.  If it's more than the current amount, this is our new target.
      var %temp.enmity.amount $enmity(%current.enmity.name, return)
      if (%temp.enmity.amount != $null) { 
        if (%temp.enmity.amount > %current.enmity.amount) { var %highest.enmity %current.enmity.name | var %current.enmity.amount %temp.enmity.amount } 
      } 
      inc %current.enmity.counter
    }

    return %highest.enmity
  }

  if ($1 = lowest) { 
    ; Look through the enmity list and find who has the lowest enmity value
    var %highest.name $ai.enmity.getname
    var %current.enmity.amount $readini($txtfile(battle2.txt), enmity, %highest.name)

    if (%current.enmity.amount = $null) { var %current.enmity.amount 1 } 
    var %current.enmity.counter 1 |  var %number.of.enmity.targets $numtok($return_peopleinbattle, 46)
    var %lowest.enmity no one

    while (%current.enmity.counter <= %number.of.enmity.targets) { 
      var %current.enmity.name $gettok($return_peopleinbattle, %current.enmity.counter, 46)

      ; Is this person dead? if so, remove from the enmity list. 
      if ($readini($char(%current.enmity.name), Battle, Status) = dead) { remini $txtfile(battle2.txt) enmity %current.enmity.name | var %ignore.person true }

      ; Has the person fled? If so, remove from the enmity list
      if ($readini($char(%current.enmity.name), Battle, Status) = runaway) { remini $txtfile(battle2.txt) enmity %current.enmity.name | var %ignore.person true }

      ; Is this person a monster? If so, remove from enmity list.
      if ($readini($char(%current.enmity.name), Info, Flag) = monster) { remini $txtfile(battle2.txt) enmity %current.enmity.name | var %ignore.person true }

      ; Grab the current enmity amount of the person.  If it's more than the current amount, this is our new target.
      var %temp.enmity.amount $enmity(%current.enmity.name, return)

      if ((%temp.enmity.amount != $null) && (%ignore.person != true)) { 
        if (%temp.enmity.amount < %current.enmity.amount) { var %lowest.enmity %current.enmity.name | var %current.enmity.amount %temp.enmity.amount } 
      } 
      inc %current.enmity.counter
    }

    return %lowest.enmity
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Returns TNL of char
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get.level.tnl { 
  var %current.level $get.level.basestats($1)
  var %next.level $calc(%current.level + 1)

  var %str $readini($char($1), BaseStats, str)
  var %def $readini($char($1), basestats, def)
  var %int $readini($char($1), basestats, int)
  var %spd $readini($char($1), basestats, spd)

  var %current.stats.now %str
  inc %current.stats.now %def
  inc %current.stats.now %int
  inc %current.stats.now %spd

  if (%current.level <= 100) {
    var %total.stats.needed $calc(20  * %next.level)
    var %tnl $calc(%total.stats.needed - %current.stats.now)
    return %tnl
  }

  var %tnl to be fixed later
  return %tnl
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Returns level of char
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get.level {
  var %str $readini($char($1),battle, str)
  var %def $readini($char($1), battle, def)
  var %int $readini($char($1), battle, int)
  var %spd $readini($char($1), battle, spd)

  var %level %str
  inc %level %def
  inc %level %int
  inc %level %spd

  var %temporary.level $round($calc(%level / 20), 1)
  var %weight $get.level.statweight($1, %temporary.level)

  if ($readini($char($1), info, flag) = monster) {  var %level $floor($calc(%level * %weight)) }
  if ($readini($char($1), info, flag) != monster) { 

    if (%level > 2000) {
      dec %level 2000
      var %level $calc(%level * $get.level.statweight($1, %temporary.level))
      var %level $floor(%level)
      inc %level 2000
    }
  }

  var %level $floor($calc(%level / 20))
  return $round(%level,0)
}
get.full.level {
  var %str $readini($char($1),battle, str)
  var %def $readini($char($1), battle, def)
  var %int $readini($char($1), battle, int)
  var %spd $readini($char($1), battle, spd)
  inc %str $armor.stat($1, str)
  inc %def $armor.stat($1, def)
  inc %int $armor.stat($1, int)
  inc %spd $armor.stat($1, spd)

  var %level %str
  inc %level %def
  inc %level %int
  inc %level %spd

  var %temporary.level $round($calc(%level / 20), 1)
  var %weight $get.level.statweight($1, %temporary.level)

  if ($readini($char($1), info, flag) = monster) { 
    var %level $floor($calc(%level * %weight))
  }
  if ($readini($char($1), info, flag) != monster) { 

    if (%level > 2000) {
      dec %level 2000
      var %level $calc(%level * %weight)
      var %level $floor(%level)
      inc %level 2000
    }
  }

  var %level $floor($calc(%level / 20))
  return $round(%level,0)
}
get.level.basestats {
  var %str $readini($char($1), BaseStats, str)
  var %def $readini($char($1), basestats, def)
  var %int $readini($char($1), basestats, int)
  var %spd $readini($char($1), basestats, spd)

  var %level %str
  inc %level %def
  inc %level %int
  inc %level %spd

  var %temporary.level $round($calc(%level / 20), 1)
  var %weight $get.level.statweight($1, %temporary.level)

  if ($readini($char($1), info, flag) = monster) { 
    var %level $floor($calc(%level * %weight))
  }
  if ($readini($char($1), info, flag) != monster) { 

    if (%level > 2000) {
      dec %level 2000
      var %level $calc(%level * %weight)
      var %level $floor(%level)
      inc %level 2000
    }
  }

  var %level $floor($calc(%level / 20))
  return $round(%level,0)
}
get.level.old {
  var %str $readini($char($1),battle, str)
  var %def $readini($char($1), battle, def)
  var %int $readini($char($1), battle, int)
  var %spd $readini($char($1), battle, spd)

  var %level %str
  inc %level %def
  inc %level %int
  inc %level %spd

  var %level $round($calc(%level / 20), 1)

  return %level
}

get.level.statweight {
  var %weight 1

  if ($readini($char($1), info, flag) = monster) { 
    if (%battle.type = defendoutpost) { return %weight }
    if (%battle.type = MonsterFair) { return %weight }
    if (%battle.type = Torment) { return %weight }
    if (%battle.type = Cosmic) { return %weight }
    if (%battle.type = mimic) { return %weight }
    if (%battle.type = dungeon) { 
      ; to do: check to see if the monsters/boss in the dungeon room needs a different weight
      return %weight

    } 
    if (%besieged = on) { return %weight }
    if (%supplyrun = on) { return %weight }

    if (%portal.bonus = true) { 
      var %portal.item $readini($txtfile(battle2.txt), battleinfo, PortalItem)
      var %statweight $readini($dbfile(items.db), %portal.item, StatWeight)

      if (%statweight = $null) { return %weight }
      else { return %statweight }
    }

    var %current.streak $return_winningstreak

    if (%current.streak <= 100) { return %weight }
    if ((%current.streak > 100) && (%current.streak <= 500)) { var %weight .98 }
    if ((%current.strek >= 500) && (%current.streak <= 1000)) { var %weight .96 }
    if ((%current.streak > 1000) && (%current.streak <= 5000)) { var %weight .95 }
    if (%current.streak > 5000) { var %weight .92 }
  }
  else {
    if ($2 < 100) { return 1 }
    if (($2 >= 101) && ($2 <= 500)) { var %weight .95 }
    if (($2 > 500) && ($2 <= 1000)) { var %weight .90 }
    if (($2 > 1000) && ($2 <= 5000)) { var %weight .85 }
    if (($2 > 5000) && ($2 <= 10000)) { var %weight .80 }
    if (($2 > 10000) && ($2 <= 20000)) { var %weight .75 }
    if ($2 > 20000) { var %weight .70 }
  }

  return %weight
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Returns level of armor
; based on armor's stats
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ilevel {

  var %str $armor.stat($1, str)
  var %def $armor.stat($1, def)
  var %int  $armor.stat($1, int)
  var %spd  $armor.stat($1, spd)

  var %level %str
  inc %level %def
  inc %level %int
  inc %level %spd

  var %level $round($calc(%level / 20), 0)

  return %level

}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Returns what is equipped in the slot
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return.equipped {
  ; $1 = person
  ; $2 = what we're checking (head, body, accessory1, accessory2, etc)

  return $readini($char($1), equipment, $2)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Checks & Clears a player's
; portal usage if enough time
; has passed
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
portal.clearusagecheck {
  ; $1 = person to check

  set %current.day $gettok($adate, 2, 47)
  set %current.month $gettok($adate, 1, 47)

  set %last.portal.used.month $gettok($readini($char($1), info, LastPortalDate), 1, 47)
  set %last.portal.used.day $gettok($readini($char($1), info, LastPortalDate), 2, 47)

  var %reset.usage false

  if ((%current.month = $null) || (%last.portal.used.day = $null)) { var %reset.usage true }

  if (%last.portal.used.month = %current.month) { 
    if (%last.portal.used.day != %current.day) { var %reset.usage true }
  }
  if (%current.month != %last.portal.used.month) { var %reset.usage true }

  if (%reset.usage = true) { writeini $char($1) info PortalsUsedTotal 0 }

  unset %current.day | unset %current.month | unset %last.portal.used.day | unset %last.portal.used.month
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Returns the max # of times
; a portal can be used daily
; (base amount)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
portal.dailymaxlimit {
  return 10
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; See if the user $1 has
; the skill $2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
skillhave.check {
  if ($readini($char($1), skills, $2) > 0) { return true }
  else { return false }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays which active
; skills are equipped
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
skill.equipped.list {
  ; $1 = the person we're checking

  $checkchar($1)
  var %player.equipped.skills $readini($char($1), skills, equipped)
  if (%player.equipped.skills = $null) { 
    if ($2 = private) { $display.private.message($readini(translation.dat, system, HasNoEquippedSkills)) | halt }
    else { $display.message($readini(translation.dat, system, HasNoEquippedSkills),private) | halt }
  }
  else {

    if ($chr(046) isin %player.equipped.skills) { var %replacechar $chr(044) $chr(032) |  var %player.equipped.skills.display $replace(%player.equipped.skills, $chr(046), %replacechar)  }
    else { var %player.equipped.skills.display %player.equipped.skills }

    if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewEquippedSkills)) | halt }
    else { $display.message($readini(translation.dat, system, ViewEquippedSkills), private) }
  }

}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Equip an active skill
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
skill.equip {
  ; $1 = the player
  ; $2 = the skill
  ; $3 = private/null

  $check_for_battle($1)

  var %player.equipped.skills $readini($char($1), skills, equipped)

  ; First things first, does the player own this skill?
  if ($skillhave.check($1, $2) = false) { 

    ; If the skill was left on the equipped list and the player no longer has the skill (such as selling it)
    ; remove the skill from the equipped list.
    if ($istok(%player.equipped.skills,$2,46) = $true) { 
      var %skill.tok.to.remove $findtok(%player.equipped.skills, $2, 46)
      var %player.equipped.skills = $deltok(%player.equipped.skills, %skill.tok.to.remove, 46)
      if (%player.equipped.skills = $null) { remini $char($1) skills equipped } 
      else {  writeini $char($1) skills Equipped %player.equipped.skills }
    }

    ; Display the error message
    $display.private.message($readini(translation.dat, errors, PlayerDoesNotOwnSkill)) 
    halt 
  }

  ; Does this skill need to be equipped?
  if ($skill.needtoequip($2) != true) { 
    if ($3 = private) { $display.private.message($readini(translation.dat, errors, ThisSkillDoesn'tNeedToBeEquipped)) }
    else { $display.message($readini(translation.dat, errors, ThisSkillDoesn'tNeedToBeEquipped), private) }
    halt 
  }

  ; Is it already equipped?
  if ($istok(%player.equipped.skills,$2,46) = $true) {  
    $display.private.message($readini(translation.dat, errors, ThisSkillIsAlreadyEquipped))
    halt 
  }

  ; Does the player already have max skills equipped?
  if ($numtok(%player.equipped.skills, 46) = $return.skill.slots($1)) { 
    $display.private.message($readini(translation.dat, errors, MaxSkillsEquipped))
    halt 
  }

  ; Go ahead and equip it.
  %player.equipped.skills = $addtok(%player.equipped.skills,$2,46) 
  writeini $char($1) skills Equipped %player.equipped.skills

  if ($3 = private) { $display.private.message($readini(translation.dat, errors, SkillHasBeenEquipped)) }
  else { $display.message($readini(translation.dat, errors, SkillHasBeenEquipped), private) }

  unset %player.equipped.skills

  ; if the battle is on..
  if (%battleis = on) {  $check_for_double_turn($1)   }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Unequip an active skill
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
skill.unequip {
  ;  $1 = the player
  ; $2 = the skill
  ; $3 = private/null

  var %player.equipped.skills $readini($char($1), skills, equipped)

  ; Is it equipped?
  if ($istok(%player.equipped.skills,$2,46) = $false) {  
    $display.private.message($readini(translation.dat, errors, SkillNotEquipped))
    halt 
  }


  ; Go ahead and unequip it.
  if ($istok(%player.equipped.skills,$2,46) = $true) { 
    var %skill.tok.to.remove $findtok(%player.equipped.skills, $2, 46)
    var %player.equipped.skills = $deltok(%player.equipped.skills, %skill.tok.to.remove, 46)
    if (%player.equipped.skills = $null) { remini $char($1) skills equipped } 
    else {  writeini $char($1) skills Equipped %player.equipped.skills }
  }

  if ($3 = private) { $display.private.message($readini(translation.dat, errors, SkillHasBeenUnEquipped)) }
  else { $display.message($readini(translation.dat, errors, SkillHasBeenUnEquipped), private) }

  unset %player.equipped.skills


}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Check for the treasurehunter
; skill.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
treasurehunter.check {
  unset %battle.list | set %lines $lines($txtfile(battle.txt)) | set %l 1 | set %treasure.hunter.percent 0
  while (%l <= %lines) { 
    set %who.battle $read -l [ $+ [ %l ] ] $txtfile(battle.txt) | set %status.battle $readini($char(%who.battle), Battle, Status)
    if (%status.battle = dead) { inc %l 1 }
    else { 
      var %treasurehunter.skill $readini($char(%who.battle), skills, treasurehunter) 
      if (%treasurehunter.skill > 0) { inc %treasure.hunter.percent %treasurehunter.skill }
      if ($augment.check($1, EnhanceTreasureHunter) = true) { inc %treasure.hunter.percent %augment.strength }

      if ($accessory.check(%who.battle, IncreaseTreasureOdds) = true) {
        inc %treasure.hunter.percent %accessory.amount
        unset %accessory.amount
      }

      inc %l 1 
    } 
  }
  unset %lines | unset %l | unset %current.accessory | unset %current.accessory.type

  return %treasure.hunter.percent
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Check for the backguard
; skill.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
backguard.check {
  unset %battle.list | set %lines $lines($txtfile(battle.txt)) | set %l 1
  while (%l <= %lines) { 
    set %who.battle $read -l [ $+ [ %l ] ] $txtfile(battle.txt)
    if ($readini($char($1), info, flag) != $null) { inc %l 1 }
    else { 
      var %backguard.skill $readini($char(%who.battle), skills,backguard) 
      if (%backguard.skill > 0) { dec %surpriseattack.chance %backguard.skill }
      inc %l 1 
    } 
  }
  unset %lines | unset %l 
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Check for the divine blessing
; skill.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
divineblessing.check {
  unset %battle.list | set %lines $lines($txtfile(battle.txt)) | set %l 1
  while (%l <= %lines) { 
    set %who.battle $read -l [ $+ [ %l ] ] $txtfile(battle.txt)
    if ($readini($char($1), info, flag) != $null) { inc %l 1 }
    else { 
      var %divineblessing.skill $readini($char(%who.battle), skills,divineblessing) 
      if (%divineblessing.skill > 0) { inc %curse.chance %divineblessing.skill }
      inc %l 1 
    } 
  }
  unset %lines | unset %l 
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Returns a person's item amount
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
item.amount { 
  ; $1 = person
  ; $2 = item name
  var %temp.item.amount $readini($char($1), item_amount, $2)
  if (%temp.item.amount = $null) { return 0 }
  else { return %temp.item.amount } 
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Refills a char's natural armor
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
fullNaturalArmor {
  if ($readini($char($1), info, flag) = $null) { return }
  var %naturalArmorMax $readini($char($1), NaturalArmor, Max)
  if (%naturalArmorMax != $null) { writeini $char($1) NaturalArmor Current %naturalArmorMax }
  return
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; "looks" at a player
; Displays armor and weapon
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
lookat {
  $weapon_equipped($1) | $set_chr_name($1)
  var %equipped.accessory $readini($char($1), equipment, accessory) 
  if (%equipped.accessory = $null) { var %equipped.accessory nothing }
  var %equipped.armor.head $readini($char($1), equipment, head) 
  if (%equipped.armor.head = $null) { var %equipped.armor.head nothing }
  var %equipped.armor.body $readini($char($1), equipment, body) 
  if (%equipped.armor.body = $null) { var %equipped.armor.body nothing }
  var %equipped.armor.legs $readini($char($1), equipment, legs) 
  if (%equipped.armor.legs = $null) { var %equipped.armor.legs nothing }
  var %equipped.armor.feet $readini($char($1), equipment, feet) 
  if (%equipped.armor.feet = $null) { var %equipped.armor.feet nothing }
  var %equipped.armor.hands $readini($char($1), equipment, hands) 
  if (%equipped.armor.hands = $null) { var %equipped.armor.hands nothing }

  var %equipped.accessory $equipment.color(%equipped.accessory) $+  $+ %equipped.accessory $+ 03

  if ($readini($char($1), equipment, accessory2) != $null) { 
    var %equipped.accessory2 $equipment.color($readini($char($1), equipment, accessory2)) $+ $readini($char($1), equipment, accessory2)
    var %equipped.accessory %equipped.accessory 03and %equipped.accessory2 $+ 03
  }

  var %equipped.armor.head $equipment.color(%equipped.armor.head) $+ %equipped.armor.head $+ 03
  var %equipped.armor.body $equipment.color(%equipped.armor.body) $+ %equipped.armor.body $+ 03
  var %equipped.armor.legs $equipment.color(%equipped.armor.legs) $+ %equipped.armor.legs $+ 03
  var %equipped.armor.feet $equipment.color(%equipped.armor.feet) $+ %equipped.armor.feet $+ 03 
  var %equipped.armor.hands $equipment.color(%equipped.armor.hands) $+ %equipped.armor.hands $+ 03

  var %weapon.equipped $equipment.color(%weapon.equipped) $+ %weapon.equipped

  if ($readini($char($1), info, CustomTitle) != $null) { var %custom.title " $+ $readini($char($1), info, CustomTitle) $+ " }

  if ($readini(system.dat, system, botType) = IRC) { 
    if ($2 = channel) {  $display.message(03 $+ %real.name %custom.title is wearing %equipped.armor.head on $gender($1) head; %equipped.armor.body on $gender($1) body; %equipped.armor.legs on $gender($1) legs; %equipped.armor.feet on $gender($1) feet; %equipped.armor.hands on $gender($1) hands. %real.name also has %equipped.accessory equipped $iif(%equipped.accessory2 = $null, as an accessory, as accessories) and is currently using the %weapon.equipped $iif(%weapon.equipped.left != $null, 03and $equipment.color(%weapon.equipped.left) $+ %weapon.equipped.left 03weapons, 03weapon),private) }
    if ($2 != channel) { $display.private.message(03 $+ %real.name %custom.title is wearing %equipped.armor.head on $gender($1) head; %equipped.armor.body on $gender($1) body; %equipped.armor.legs on $gender($1) legs; %equipped.armor.feet on $gender($1) feet; %equipped.armor.hands on $gender($1) hands. %real.name also has %equipped.accessory $iif(%equipped.accessory2 = $null, as an accessory, as accessories) and is currently using the %weapon.equipped $iif(%weapon.equipped.left != $null, 03and $equipment.color(%weapon.equipped.left) $+ %weapon.equipped.left 03weapons, 03weapon)) }
  }
  if ($readini(system.dat, system, botType) = DCCchat) {
    var %look.message 03 $+ %real.name is wearing %equipped.armor.head on $gender($1) head, %equipped.armor.body on $gender($1) body, %equipped.armor.legs on $gender($1) legs, %equipped.armor.feet on $gender($1) feet, %equipped.armor.hands on $gender($1) hands. %real.name also has %equipped.accessory  $+ $iif(%equipped.accessory2 = $null, as an accessory, as accessories) and is currently using the the %weapon.equipped $iif(%weapon.equipped.left != $null, 03and $equipment.color(%weapon.equipped.left) $+ %weapon.equipped.left 03weapons, 03weapon)
  $dcc.private.message($nick, %look.message) }
} 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; The rest command
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
rest.cmd {
  $no.turn.check($1)
  $check_for_battle($1)

  var %rest.message $readini($char($1), Descriptions, Restmessage)
  if (%rest.message = $null) { var %rest.message $readini(translation.dat, Battle,RestMessage) }
  $display.message(12 $+ %rest.message, battle)  

  if ($readini($char($1), n, Info, AfterRest) != $null) { $readini($char($1), p, Info, AfterRest) }

  $next | halt
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Returns a person's allied
; notes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
check.allied.notes {
  var %allied.notes $readini($char($1), stuff, alliednotes) 
  if (%allied.notes = $null) { var %allied.notes no }
  $set_chr_name($1) 
  if ($readini(system.dat, system, botType) = IRC) {
    if ($2 = channel) {  $display.message($readini(translation.dat, system, ViewAlliedNotes),private) } 
    else { $display.private.message($readini(translation.dat, system, ViewAlliedNotes)) }
  }
  if ($readini(system.dat, system, botType) = DCCchat) { $dcc.private.message($nick, $readini(translation.dat, system, ViewAlliedNotes)) }

  unset %real.name | unset %hstats 
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Returns a person's
; double dollar amount
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
check.doubledollars {
  var %doubledollars $readini($char($1), stuff, doubledollars) 
  if (%doubledollars = $null) { writeini $char($1) stuff doubledollars 100 | var %doubledollars 100 }
  var %currency.symbol $readini(system.dat, system, BetCurrency)
  if (%currency.symbol = $null) { var %currency.symbol $chr(36) $+ $chr(36) }
  $set_chr_name($1) 
  if ($readini(system.dat, system, botType) = IRC) {
    if ($2 = channel) {  $display.message($readini(translation.dat, system, ViewDoubleDollars),private) } 
    else { $display.private.message($readini(translation.dat, system, ViewDoubleDollars)) }
  }
  if ($readini(system.dat, system, botType) = DCCchat) { $dcc.private.message($nick, $readini(translation.dat, system, ViewDoubleDollars)) }

  unset %real.name | unset %hstats 
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Checks a person's Kill Coins
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
check.kill.coins {
  var %kill.coins $readini($char($1), stuff, killcoins) 
  if (%kill.coins = $null) { var %kill.coins 0 | writeini $char($1) stuff killcoins 0 }
  $set_chr_name($1) 
  if ($readini(system.dat, system, botType) = IRC) {
    if ($2 = channel) {  $display.message($readini(translation.dat, system, ViewKillCoins),private) } 
    else { $display.private.message($readini(translation.dat, system, ViewKillCoins)) }
  }
  if ($readini(system.dat, system, botType) = DCCchat) { $dcc.private.message($nick, $readini(translation.dat, system, ViewKillCoins)) }

  unset %real.name | unset %hstats 
}

return.killcoin.count {
  var %kill.coins $readini($char($1), stuff, killcoins) 
  if (%kill.coins = $null) { var %kill.coins 0 | writeini $char($1) stuff killcoins 0 }
  return %kill.coins
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Checks a person's max
; skill slots
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return.skill.slots {
  ; $1 = the person we're checking

  var %skill.slots $return.systemsetting(StartingSkillSlots)
  if (%skill.slots = null) { var %skill.slots 5 }

  var %skill.slot.enhancements $readini($char($1), enhancements, SkillSlots)

  if (%skill.slot.enhancements != $null) { inc %skill.slots %skill.slot.enhancements }

  return %skill.slots
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Builds a list of all active
; statuses
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
player.status { unset %all_status | unset %all_skills | $set_chr_name($1) 

  if ($readini($char($1), Battle, Status) = dead) { set %all_status dead | return } 
  else { 

    var %value 1 | var %status.lines $lines($lstfile(statuseffects.lst))

    while (%value <= %status.lines) {
      var %current.status $read -l $+ %value $lstfile(statuseffects.lst)
      if (($readini($char($1), Status, %current.status) = yes) || ($readini($char($1), Status, %current.status) = on)) { 
        if ((%current.status = poison) && ($readini($char($1), status, heavypoison) = yes)) { $status_message_check($readini(translation.dat, statuses, HeavyPoison)) }
        else { $status_message_check($readini(translation.dat, statuses, %current.status)) }
      } 
      inc %value 1 
    }

    $bar_check($1)
    unset %resists

    var %enspell $readini($char($1), status, en-spell)
    if ((%enspell != $null) && (%enspell != none)) { $status_message_check(12en- $+ %enspell) }

    $player.skills.list($1)

    if (%all_status = $null) { %all_status = 03Normal }
    if (%all_skills = $null) { %all_skills = 03None }
    return
  }
  unset %real.name | unset %status 
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Builds a list of all active
; skills
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
player.skills.list {
  unset %all_skills
  if ($readini($char($1), status, conservetp.on) = on) { $skills_message_check(02conserving TP) }
  if ($readini($char($1), status, conservetp) = yes) { $skills_message_check(02conserving TP) }
  if ($readini($char($1), skills, utsusemi.on) = on) { $skills_message_check(02Utsusemi[ $+ $readini($char($1), skills, utsusemi.shadows) $+ ]) }
  if ($readini($char($1), skills, sentinel.on) = on) { $skills_message_check(02Sentinel) }
  if ($readini($char($1), skills, royalguard.on) = on) { $skills_message_check(02Royal Guard) }
  if ($readini($char($1), skills, manawall.on) = on) { $skills_message_check(02Mana Wall) }
  if ($readini($char($1), skills, mightystrike.on) = on) { $skills_message_check(02Mighty Strike) }
  if ($readini($char($1), skills, truestrike.on) = on) { $skills_message_check(02True Strike) }
  if ($readini($char($1), skills, elementalseal.on) = on) { $skills_message_check(02Elemental Seal) }
  if ($readini($char($1), skills, thirdeye.on) = on) { $skills_message_check(02Third Eye) }
  if ($readini($char($1), skills, retaliation.on) = on) { $skills_message_check(02Retaliation) }
  if ($readini($char($1), skills, konzen-ittai.on) = on) { $skills_message_check(02Konzen-Ittai) }
  if ($readini($char($1), skills, defender.on) = on) { $skills_message_check(02Defender) }
  if ($readini($char($1), skills, aggressor.on) = on) { $skills_message_check(02Aggressor) }
  if ($readini($char($1), skills, perfectcounter.on) = on) { $skills_message_check(02Will Perform a Perfect Counter) }
  if ($readini($char($1), skills, FormlessStrike.on) = on) { $skills_message_check(Formless Strikes) }
  if ($readini($char($1), skills, PerfectDefense.on) = on) { $skills_message_check(Perfect Defense) }
  if ($readini($char($1), skills, drainsamba.on) = on) { $skills_message_check(02Drain Samba) }
  if ($readini($char($1), skills, bloodboost.on) = on) { $skills_message_check(02Blood Boost) }
  if ($readini($char($1), skills, bloodspirit.on) = on) { $skills_message_check(02Blood Spirit) }
  if ($readini($char($1), skills, speed.on) = on) { $skills_message_check(02Speed Boost) }
  if ($readini($char($1), skills, criticalfocus.on) = on) { $skills_message_check(02Critical Focus) }
  if ($readini($char($1), skills, shieldfocus.on) = on) { $skills_message_check(02Shield Focus) }
  if ($readini($char($1), skills, barrage.on) = on) { $skills_message_check(02Barrage) }
  if ($readini($char($1), skills, doublecast.on) = on) { $skills_message_check(02DoubleCast) }
  if ($readini($char($1), skills, duality.on) = on) { $skills_message_check(02Duality) }
  if ($readini($char($1), skills, thinair.on) = on) { $skills_message_check(02Thin Air) }
  if ($readini($char($1), skills, quickpockets.on) = on) { $skills_message_check(02Quick Pockets) }
  if ($readini($char($1), skills, overcharge.on) = on) { $skills_message_check(02Overcharge) }
  if ($readini($char($1), skills, ricochet.on) = on) { $skills_message_check(02Ricochet) }

  set %cover.target $readini($char($1), skills, CoverTarget)
  if ((%cover.target != $null) && (%cover.target != none)) { $skills_message_check(02Covered by %cover.target) }

  unset %cover.target
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sees if the char is charmed
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
is_charmed {
  if ($readini($char($1), status, charmed) = yes) { return true }
  else { return false }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sees if the char is confused
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
is_confused {
  if ($readini($char($1), status, confuse) = yes) { return true }
  else { return false }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sees if the char is mini
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
is_mini {
  if ($readini($char($1), status, mini) = yes) { return true }
  else { return false }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sees if the char has amnesia
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
amnesia.check {
  var %amnesia.check $readini($char($1), status, amnesia)
  if (%amnesia.check = no) { return }
  else { 
    $set_chr_name($1) 
    $display.message($readini(translation.dat, status, CurrentlyAmnesia),battle) 

    halt 
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a char's weapon list
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
display_weapon_lists {  $set_chr_name($1) 

  set %replacechar $chr(044) $chr(032) 
  %weapon.list1 = $replace(%weapon.list1, $chr(046), %replacechar)

  if ($2 = channel) { 
    $display.message($readini(translation.dat, system, ViewWeaponList),private)

    var %weapon.counter 2
    while ($weapons.returnlist(%weapon.counter) != $null) {
      set %display.weaponlist $weapons.returnlist(%weapon.counter)
      %display.weaponlist = $replace(%display.weaponlist, $chr(046), %replacechar)

      $display.message(03 $+ %display.weaponlist)
      $weapons.unsetlist(%weapon.counter) | unset %display.weaponlist
      inc %weapon.counter
      if (%weapon.counter > 100) { echo -a breaking to prevent a flood | break }
    }
  }
  if ($2 = private) {
    $display.private.message2($3,$readini(translation.dat, system, ViewWeaponList))

    var %weapon.counter 2
    while ($weapons.returnlist(%weapon.counter) != $null) {
      set %display.weaponlist $weapons.returnlist(%weapon.counter)
      %display.weaponlist = $replace(%display.weaponlist, $chr(046), %replacechar)

      $display.private.message2($3,03 $+ %display.weaponlist)
      $weapons.unsetlist(%weapon.counter) | unset %display.weaponlist
      inc %weapon.counter
      if (%weapon.counter > 100) { echo -a breaking to prevent a flood | break }
    }
  }
  if ($2 = dcc) { 
    $dcc.private.message($3, $readini(translation.dat, system, ViewWeaponList))

    var %weapon.counter 2
    while ($weapons.returnlist(%weapon.counter) != $null) {
      set %display.weaponlist $weapons.returnlist(%weapon.counter)
      %display.weaponlist = $replace(%display.weaponlist, $chr(046), %replacechar)

      $dcc.private.message($3,03 $+ %display.weaponlist)
      $weapons.unsetlist(%weapon.counter) | unset %display.weaponlist
      inc %weapon.counter
      if (%weapon.counter > 100) { echo -a breaking to prevent a flood | break }
    }
  }
  unset %wpn.lst.target | unset %base.weapon.list | unset %weapons
  unset %weapon.list1 | unset %weapon.counter | unset %replacechar
  unset %weaponlist.counter | unset %mech.weapon.list | unset %mech.weapon.list2
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a char's shield list
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
display_shield_lists {  $set_chr_name($1) 
  set %replacechar $chr(044) $chr(032) 
  %shield.list1 = $replace(%shield.list1, $chr(046), %replacechar)

  if ($2 = channel) { 
    $display.message($readini(translation.dat, system, ViewshieldList),private)

    var %shield.counter 2
    while ($shields.returnlist(%shield.counter) != $null) {
      set %display.shieldlist $shields.returnlist(%shield.counter)
      %display.shieldlist = $replace(%display.shieldlist, $chr(046), %replacechar)

      $display.message(03 $+ %display.shieldlist,private)
      $shields.unsetlist(%shield.counter) | unset %display.shieldlist
      inc %shield.counter
      if (%shield.counter > 100) { echo -a breaking to prevent a flood | break }
    }
  }
  if ($2 = private) {
    $display.private.message2($3,$readini(translation.dat, system, ViewshieldList))

    var %shield.counter 2
    while ($shields.returnlist(%shield.counter) != $null) {
      set %display.shieldlist $shields.returnlist(%shield.counter)
      %display.shieldlist = $replace(%display.shieldlist, $chr(046), %replacechar)

      $display.private.message2($3,03 $+ %display.shieldlist)
      $shields.unsetlist(%shield.counter) | unset %display.shieldlist
      inc %shield.counter
      if (%shield.counter > 100) { echo -a breaking to prevent a flood | break }
    }
  }
  if ($2 = dcc) { 
    $dcc.private.message($3, $readini(translation.dat, system, ViewshieldList))

    var %shield.counter 2
    while ($shields.returnlist(%shield.counter) != $null) {
      set %display.shieldlist $shields.returnlist(%shield.counter)
      %display.shieldlist = $replace(%display.shieldlist, $chr(046), %replacechar)

      $dcc.private.message($3,03 $+ %display.shieldlist)
      $shields.unsetlist(%shield.counter) | unset %display.shieldlist
      inc %shield.counter
      if (%shield.counter > 100) { echo -a breaking to prevent a flood | break }
    }
  }
  unset %shld.lst.target | unset %base.shield.list | unset %shields
  unset %shield.list1 | unset %shield.counter | unset %replacechar
  unset %shieldlist.counter
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Returns a player's limit break %
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
limitbreak.percent {
  var %limit.percent $readini($char($1), Battle, LimitBreakPercent)
  if (%limit.percent = $null) { return 0 }
  else { return %limit.percent }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a char's style xp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
show.stylexp {
  ; Get and show the list
  set %current.playerstyle $readini($char($1), styles, equipped)
  set %current.playerstyle.xp $readini($char($1), styles, %current.playerstyle $+ XP)
  set %current.playerstyle.level $readini($char($1), styles, %current.playerstyle)
  var %current.playerstyle.xptolevel $calc(500 * %current.playerstyle.level)
  $set_chr_name($1) 
  if (%current.playerstyle.level >= 10) {   
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewCurrentStyleMaxed),private) }
    if ($2 = private) {  $display.private.message($readini(translation.dat, system, ViewCurrentStyleMaxed)) }
    if ($2 = dcc) {  $dcc.private.message($nick, $readini(translation.dat, system, ViewCurrentStyleMaxed)) }
  }
  if (%current.playerstyle.level < 10) {   
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewCurrentStyle),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewCurrentStyle)) }
    if ($2 = dcc) {  $dcc.private.message($nick, $readini(translation.dat, system, ViewCurrentStyle)) }
  }
  unset %styles.list | unset %current.playerstyle.* | unset %styles | unset %style.name | unset %style_level | unset %current.playerstyle
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a char's skils
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readskills {
  $checkchar($1) | $skills.list($1) | $set_chr_name($1) 

  if (%passive.skills.list != $null) { 
    if ($2 = channel) { 
      $display.message($readini(translation.dat, system, ViewPassiveSkills),private)
      if (%passive.skills.list2 != $null) { $display.message(03 $+ %passive.skills.list2,private) }
    }
    if ($2 = private) {
      $display.private.message($readini(translation.dat, system, ViewPassiveSkills))
      if (%passive.skills.list2 != $null) { $display.private.message(03 $+ %passive.skills.list2) }
    }
    if ($2 = dcc) {
      $dcc.private.message($nick, $readini(translation.dat, system, ViewPassiveSkills))
      if (%passive.skills.list2 != $null) { $dcc.private.message($nick, 03 $+ %passive.skills.list2) }
    }

  }
  if (%active.skills.list != $null) { 
    if ($2 = channel) { 
      $display.message($readini(translation.dat, system, ViewActiveSkills),private)
      if (%active.skills.list2 != $null) { $display.message(03 $+ %active.skills.list2,private) }
    }
    if ($2 = private) {
      $display.private.message($readini(translation.dat, system, ViewActiveSkills))
      if (%active.skills.list2 != $null) { $display.private.message(03 $+ %active.skills.list2) }
    }
    if ($2 = dcc) {
      $dcc.private.message($nick, $readini(translation.dat, system, ViewActiveSkills))
      if (%active.skills.list2 != $null) { $dcc.private.message($nick, 03 $+ %active.skills.list2) }
    }
  }

  if (%resists.skills.list != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewResistanceSkills),private)  }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewResistanceSkills))  }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, ViewResistanceSkills))  }
  }

  if (%killer.skills.list != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewKillerTraitSkills),private)  }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewKillerTraitSkills))  }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, ViewKillerTraitSkills))  }
  }

  if ((((%passive.skills.list = $null) && (%active.skills.list = $null) && (%killer.skills.list = $null) && (%resists.skills.list = $null)))) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, HasNoSkills),private)   }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, HasNoSkills))   }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, HasNoSkills)) }
  }
  unset %passive.skills.list | unset %active.skills.list | unset %active.skills.list2 | unset %resists.skills.list | unset %killer.skills.list
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a char's ammo
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readammo {
  if (%ammo.items.list != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewammoItems)) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewammoItems)) }
    if ($2 = dcc) {  $dcc.private.message($nick, $readini(translation.dat, system, ViewammoItems)) }
  } 

  if (%ammo.items.list = $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, HasNoammo),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, HasNoammo)) }
    if ($2 = dcc) {  $dcc.private.message($nick, $readini(translation.dat, system, HasNoammo)) }
  }    

  unset %ammo.items.list
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a char's keys
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readkeys {
  if (%keys.items.list != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewKeysItems)) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewKeysItems)) }
    if ($2 = dcc) {  $dcc.private.message($nick, $readini(translation.dat, system, ViewKeysItems)) }
  } 
  if (%dungeon.keys.items.list != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewDungeonKeysItems)) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewDungeonKeysItems)) }
    if ($2 = dcc) {  $dcc.private.message($nick, $readini(translation.dat, system, ViewDungeonKeysItems)) }
  } 

  if ((%keys.items.list = $null) && (%dungeon.keys.items.list = $null)) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, HasNoKeys),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, HasNoKeys)) }
    if ($2 = dcc) {  $dcc.private.message($nick, $readini(translation.dat, system, HasNoKeys)) }
  }    

  unset %dungeon.keys.items.list | unset %keys.items.list
}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a char's gems
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readgems {
  if (%gems.items.list != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewGemItems),private) }
    if ($2 = private) {  $display.private.message($readini(translation.dat, system, ViewGemItems)) }
    if ($2 = dcc) {  $dcc.private.message($nick, $readini(translation.dat, system, ViewGemItems)) }
  } 
  else { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, HasNoGems),private) }
    if ($2 = private) {  $display.private.message($readini(translation.dat, system, HasNoGems)) }
    if ($2 = dcc) {  $dcc.private.message($nick, $readini(translation.dat, system, HasNoGems)) }
  }    
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a char's seals
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readseals {
  if (%seals.items.list != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewSealItems),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewSealItems)) }
    if ($2 = dcc) {  $dcc.private.message($nick, $readini(translation.dat, system, ViewSealItems)) }
  } 
  else { 
    if ($2 = channel) {  $display.message($readini(translation.dat, system, HasNoSeals),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, HasNoSeals)) }
    if ($2 = dcc) {  $dcc.private.message($nick, $readini(translation.dat, system, HasNoSeals)) }
  }    

  unset %seals.items.list
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a char's instruments
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readinstruments {
  if (%instruments.items.list != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewInstruments),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewInstruments)) }
    if ($2 = dcc) {  $dcc.private.message($nick, $readini(translation.dat, system, ViewInstruments)) }
  } 
  else { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, HasNoinstruments),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, HasNoinstruments)) }
    if ($2 = dcc) {  $dcc.private.message($nick, $readini(translation.dat, system, HasNoinstruments)) }
  }    

  unset %instruments.items.list
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a char's trusts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readtrusts {
  if (%trust.items.list != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewTrustItems),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewTrustItems)) }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, ViewTrustItems)) }
  } 
  else { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, HasNoTrusts),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, HasNoTrusts)) }
    if ($2 = dcc) {  $dcc.private.message($nick, $readini(translation.dat, system, HasNoTrusts)) }
  }    

  unset %trust.items.list
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a char's potion ingredients
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readingredients {
  if (%Ingredients.items.list != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewIngredientItems),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewIngredientItems)) }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, ViewIngredientItems)) }
  } 
  else { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, HasNoingredients),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, HasNoingredients)) }
    if ($2 = dcc) {  $dcc.private.message($nick, $readini(translation.dat, system, HasNoingredients)) }
  }    

  unset %ingredients.items.list
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a char's portals
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readportals {
  if (%portals.items.list != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewPortalItems),private) | if (%portals.items.list2 != $null) { $display.message( $+ %portals.items.list2,private) }  |  if (%portals.items.list3 != $null) { $display.message( $+ %portals.items.list3,private) } } 
    if ($2 = private) {  $display.private.message($readini(translation.dat, system, ViewPortalItems)) |  if (%portals.items.list2 != $null) { $display.private.message( $+ %portals.items.list2) } |  if (%portals.items.list3 != $null) { $display.private.message( $+ %portals.items.list3) }  } 
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, ViewPortalItems)) | if (%portals.items.list2 != $null) { $dcc.private.message($nick,  $+ %portals.items.list2) } | if (%portals.items.list3 != $null) { $dcc.private.message($nick,  $+ %portals.items.list3) } }
  }

  if (%portals.items.list = $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, HasNoportals),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, HasNoportals)) }
    if ($2 = dcc) {  $dcc.private.message($nick, $readini(translation.dat, system, HasNoportals)) }
  }    

  unset %portals.items.*
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a char's misc items
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readmiscitems {
  if (%misc.items.list != $null) {
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewMiscItems),private) | if (%misc.items.list2 != $null) { $display.message( $+ %misc.items.list2,private) } |  if (%misc.items.list3 != $null) { $display.message( $+ %misc.items.list3,private) } | if (%misc.items.list4 != $null) { $display.message( $+ %misc.items.list4,private) } | if (%misc.items.list5 != $null) { $display.message( $+ %misc.items.list5,private) } | if (%misc.items.list6 != $null) { $display.message( $+ %misc.items.list6,private) } }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewMiscItems)) | if (%misc.items.list2 != $null) { $display.private.message(05 $+ %misc.items.list2) } | if (%misc.items.list3 != $null) { $display.private.message( $+ %misc.items.list3) } | if (%misc.items.list4 != $null) { $display.private.message( $+ %misc.items.list4) } | if (%misc.items.list5 != $null) { $display.private.message( $+ %misc.items.list5) } | if (%misc.items.list6 != $null) { $display.private.message( $+ %misc.items.list6) } }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, ViewMiscItems)) | if (%misc.items.list2 != $null) {  $dcc.private.message($nick,  $+ %misc.items.list2) } | if (%misc.items.list3 != $null) { $dcc.private.message($nick,  $+ %misc.items.list3) } | if (%misc.items.list4 != $null) { $dcc.private.message($nick,  $+ %misc.items.list4) } |  if (%misc.items.list5 != $null) { $dcc.private.message($nick,  $+ %misc.items.list5) } |  if (%misc.items.list6 != $null) { $dcc.private.message($nick,  $+ %misc.items.list6) } }
  }

  if (%misc.items.list = $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, HasNoMiscItems),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, HasNoMiscItems)) }
    if ($2 = dcc) {  $dcc.private.message($nick, $readini(translation.dat, system, HasNoMiscItems)) }
  }    

  unset %miscitems.items.*
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a char's trading cards
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readtradingcards {
  if (%tradingcards.items.list != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewTradingCards),private) | if (%tradingcards.items.list2 != $null) { $display.message( $+ %tradingcards.items.list2,private) }  |  if (%tradingcards.items.list3 != $null) { $display.message( $+ %tradingcards.items.list3,private) } } 
    if ($2 = private) {  $display.private.message($readini(translation.dat, system, ViewTradingCards)) |  if (%tradingcards.items.list2 != $null) { $display.private.message( $+ %tradingcards.items.list2) } |  if (%tradingcards.items.list3 != $null) { $display.private.message( $+ %tradingcards.items.list3) }  } 
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, ViewTradingCards)) | if (%tradingcards.items.list2 != $null) { $dcc.private.message($nick,  $+ %tradingcards.items.list2) } | if (%tradingcards.items.list3 != $null) { $dcc.private.message($nick,  $+ %tradingcards.items.list3) } }
  }

  if (%tradingcards.items.list = $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, HasNotradingcards),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, HasNotradingcards)) }
    if ($2 = dcc) {  $dcc.private.message($nick, $readini(translation.dat, system, HasNotradingcards)) }
  }    

  unset %tradingcards.items.*
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a char's items
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readitems { 
  if (%items.list != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewItems),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewItems)) }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, ViewItems)) }
  }
  if (%items.list2 != $null) { 
    if ($2 = channel) { $display.message( $+ %items.list2,private) }
    if ($2 = private) { $display.private.message( $+ %items.list2) }
    if ($2 = dcc) { $dcc.private.message($nick,  $+ %items.list2) }
  }
  if (%statplus.items.list != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewStatPlusItems),private) }
    if ($2 = private) {  $display.private.message($readini(translation.dat, system, ViewStatPlusItems)) }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, ViewStatPlusItems)) }
  }
  if (%summons.items.list != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewSummonItems),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewSummonItems)) }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, ViewSummonItems)) }
  }
  if (%summons.items.list2 != $null) { 
    if ($2 = channel) { $display.message( $+ %summons.items.list2,private) }
    if ($2 = private) {  $display.private.message( $+ %summons.items.list2) }
    if ($2 = dcc) { $dcc.private.message($nick,  $+ %summons.items.list2) }
  }
  if (%summons.items.list3 != $null) { 
    if ($2 = channel) { $display.message( $+ %summons.items.list3,private) }
    if ($2 = private) {  $display.private.message( $+ %summons.items.list3) }
    if ($2 = dcc) { $dcc.private.message($nick,  $+ %summons.items.list3) }
  }
  if (%reset.items.list != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewShopResetItems),private) }
    if ($2 = private) {  $display.private.message($readini(translation.dat, system, ViewShopResetItems)) }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, ViewShopResetItems)) }
  }
  if (%special.items.list != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewShopSpecialItems),private) | if (%special.items.list2 != $null) { $display.message( $+ %special.items.list2) }   }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewShopSpecialItems)) | if (%special.items.list2 != $null) { $display.private.message( $+ %special.items.list2) } } 
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, ViewShopSpecialItems)) | if (%special.items.list2 != $null) { $dcc.private.message($nick,  $+ %special.items.list2) } }
  }

  if (((((((((((%items.list = $null) && (%statplus.items.list = $null) && (%summons.items.list = $null) && (%reset.items.list = $null) && (%gems.items.list = $null) && (%portals.items.list = $null) && (%mech.items.list = $null) && (%special.items.list = $null) && (%trust.items.list = $null) && (%potioningredient.items.list = $null) && (%misc.items.list = $null))))))))))) { 
    var %items.empty true 

    if ($2 = channel) { $display.message($readini(translation.dat, system, HasNoItems),private) }
    if ($2 = private) {  $display.private.message($readini(translation.dat, system, HasNoItems)) }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, HasNoItems)) }
  }    


  ; Display commands for other inventory items
  if (%items.empty != true) { 
    if ($2 = channel) { $display.message(03Other item commands:05 !misc items03 $+ $chr(44) 03!seals03 $+ $chr(44) 15!portals03 $+ $chr(44) 07!gems03 $+ $chr(44) 06!instruments03 $+ $chr(44) 14!keys03 $+ $chr(44) 06!trusts03 $+ $chr(44) 05!trading cards03 $+ $chr(44) 03!mech items  $+ $chr(44) 05!ingredients $+ $chr(44) 07!runes  $+ $chr(44) 10!ammo,private) }
    if ($2 = private) {  $display.private.message(03Other item commands:05 !misc items03 $+ $chr(44) 03!seals03 $+ $chr(44) 15!portals03 $+ $chr(44) 07!gems03 $+ $chr(44) 06!instruments03 $+ $chr(44) 14!keys03 $+ $chr(44) 06!trusts03 $+ $chr(44) 05!trading cards03 $+ $chr(44) 03!mech items $+ $chr(44) 05!ingredients $+ $chr(44) 07!runes $+ $chr(44) 10!ammo) }
    if ($2 = dcc) { $dcc.private.message($nick, 03Other item commands:05 !misc items03 $+ $chr(44) 03!seals03 $+ $chr(44) 15!portals03 $+ $chr(44) 07!gems03 $+ $chr(44) 06!instruments03 $+ $chr(44) 14!keys03 $+ $chr(44) 06!trusts03 $+ $chr(44) 05!trading cards03 $+ $chr(44) 03!mech items $+ $chr(44) 05!ingredients $+ $chr(44) 07!runes $+ $chr(44) 10!ammo) }
  }

  unset %*.items.lis* | unset %items.lis*
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a char's accessories
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readaccessories {
  ; Display the list of accessories the player has
  if (%accessories.list != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewAccessories),private) }
    if ($2 = private) {  $display.private.message($readini(translation.dat, system, ViewAccessories)) }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, ViewAccessories)) }

    if (%accessories.list2 != $null) { 
      if ($2 = channel) {  $display.message(03 $+ %accessories.list2,private) }
      if ($2 = private) { $display.private.message(03 $+ %accessories.list2) }
      if ($2 = dcc) { $dcc.private.message($nick, 03 $+ %accessories.list2) }
    }

    if (%accessories.list3 != $null) { 
      if ($2 = channel) {  $display.message(03 $+ %accessories.list3,private) }
      if ($2 = private) { $display.private.message(03 $+ %accessories.list3) }
      if ($2 = dcc) { $dcc.private.message($nick, 03 $+ %accessories.list3) }
    }
  }
  else { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, HasNoAccessories),private) }
    if ($2 = private) {  $display.private.message($readini(translation.dat, system, HasNoAccessories)) }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, HasNoAccessories)) } 
  }

  ; Display which accessories (if any) are equipped

  if ($readini($char($1), enhancements, Accessory2) != true) { 
    var %equipped.accessory $readini($char($1), equipment, accessory)
    if ((%equipped.accessory = $null) || (%equipped.accessory = none)) { 
      if ($2 = channel) {  $display.message($readini(translation.dat, system, HasNoEquippedAccessory),private) }
      if ($2 = private) {  $display.private.message($readini(translation.dat, system, HasNoEquippedAccessory)) }
      if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, HasNoEquippedAccessory)) }
    }
    if ((%equipped.accessory != $null) && (%equipped.accessory != none)) {
      if ($2 = channel) { $display.message($readini(translation.dat, system, ViewEquippedAccessory),private) }
      if ($2 = private) {  $display.private.message($readini(translation.dat, system, ViewEquippedAccessory)) }
      if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, ViewEquippedAccessory)) }
    }
    unset %accessories.list | unset %accessories.list2 | unset %accessories.list3
  }

  if ($readini($char($1), enhancements, accessory2) = true) { 
    var %equipped.accessory $readini($char($1), equipment, accessory)
    var %equipped.accessory2 $readini($char($1), equipment, accessory2)

    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewEquippedAccessories),private) }
    if ($2 = private) {  $display.private.message($readini(translation.dat, system, ViewEquippedAccessories)) }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, ViewEquippedAccessories)) }
  }

  unset %accessories.* | unset %accessory*

}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a char's songs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readsongs {
  if (%songs.list != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, Viewsongs),private) }
    if ($2 = private) {  $display.private.message($readini(translation.dat, system, Viewsongs)) }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, Viewsongs)) }

    if (%songs.list2 != $null) { 
      if ($2 = channel) {  $display.message(03 $+ %songs.list2,private) }
      if ($2 = private) {  $display.private.message(03 $+ %songs.list2) }
      if ($2 = dcc) { $dcc.private.message($nick, 03 $+ %songs.list2) }
    }
  }
  else { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, HasNosongs),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, HasNosongs)) }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, HasNosongs)) } 
  }
  unset %songs.list 
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a char's armor
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readarmor {
  if (%armor.head != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewArmorHead),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewArmorHead)) }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, ViewArmorHead)) }
  }
  if (%armor.head2 != $null) { 
    if ($2 = channel) { $display.message(03 $+ %armor.head2,private) }
    if ($2 = private) { $display.private.message(03 $+ %armor.head2) }
    if ($2 = dcc) { $dcc.private.message($nick, 03 $+ %armor.head2) }
  }
  if (%armor.head3 != $null) { 
    if ($2 = channel) { $display.message(03 $+ %armor.head3,private) }
    if ($2 = private) { $display.private.message(03 $+ %armor.head3) }
    if ($2 = dcc) { $dcc.private.message($nick, 03 $+ %armor.head3) }
  }
  if (%armor.head4 != $null) { 
    if ($2 = channel) { $display.message(03 $+ %armor.head4,private) }
    if ($2 = private) { $display.private.message(03 $+ %armor.head4) }
    if ($2 = dcc) { $dcc.private.message($nick, 03 $+ %armor.head4) }
  }

  if (%armor.body != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewArmorBody),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewArmorBody)) }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, ViewArmorBody)) }
  }
  if (%armor.body2 != $null) { 
    if ($2 = channel) { $display.message(03 $+ %armor.body2,private) }
    if ($2 = private) { $display.private.message(03 $+ %armor.body2) }
    if ($2 = dcc) { $dcc.private.message($nick, 03 $+ %armor.body2) }
  }
  if (%armor.body3 != $null) { 
    if ($2 = channel) { $display.message(03 $+ %armor.body3,private) }
    if ($2 = private) {  $display.private.message(03 $+ %armor.body3) }
    if ($2 = dcc) { $dcc.private.message($nick, 03 $+ %armor.body3) }
  }
  if (%armor.body4 != $null) { 
    if ($2 = channel) { $display.message(03 $+ %armor.body4,private) }
    if ($2 = private) {  $display.private.message(03 $+ %armor.body4) }
    if ($2 = dcc) { $dcc.private.message($nick, 03 $+ %armor.body4) }
  }

  if (%armor.legs != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewArmorLegs),private) }
    if ($2 = private) {  $display.private.message($readini(translation.dat, system, ViewArmorLegs)) }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, ViewArmorLegs)) }
  }
  if (%armor.legs2 != $null) { 
    if ($2 = channel) { $display.message(03 $+ %armor.legs2,private) }
    if ($2 = private) {  $display.private.message(03 $+ %armor.legs2) }
    if ($2 = dcc) { $dcc.private.message($nick, 03 $+ %armor.legs2) }
  }
  if (%armor.legs3 != $null) { 
    if ($2 = channel) { $display.message(03 $+ %armor.legs3,private) }
    if ($2 = private) { $display.private.message(03 $+ %armor.legs3) }
    if ($2 = dcc) { $dcc.private.message($nick, 03 $+ %armor.legs3) }
  }
  if (%armor.legs4 != $null) { 
    if ($2 = channel) { $display.message(03 $+ %armor.legs4,private) }
    if ($2 = private) { $display.private.message(03 $+ %armor.legs4) }
    if ($2 = dcc) { $dcc.private.message($nick, 03 $+ %armor.legs4) }
  }

  if (%armor.feet != $null) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, ViewArmorFeet),private) }
    if ($2 = private) {  $display.private.message($readini(translation.dat, system, ViewArmorFeet)) }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, ViewArmorFeet)) }
  }
  if (%armor.feet2 != $null) { 
    if ($2 = channel) { $display.message(03 $+ %armor.feet2,private) }
    if ($2 = private) {  $display.private.message(03 $+ %armor.feet2) }
    if ($2 = dcc) { $dcc.private.message($nick, 03 $+ %armor.feet2) }
  }
  if (%armor.feet3 != $null) { 
    if ($2 = channel) { $display.message(03 $+ %armor.feet3,private) }
    if ($2 = private) {  $display.private.message(03 $+ %armor.feet3) }
    if ($2 = dcc) { $dcc.private.message($nick, 03 $+ %armor.feet3) }
  }
  if (%armor.feet4 != $null) { 
    if ($2 = channel) { $display.message(03 $+ %armor.feet4,private) }
    if ($2 = private) {  $display.private.message(03 $+ %armor.feet4) }
    if ($2 = dcc) { $dcc.private.message($nick, 03 $+ %armor.feet4) }
  }

  if (%armor.hands != $null) {
    if ($2 = channel) {  $display.message($readini(translation.dat, system, ViewArmorHands),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, ViewArmorHands)) }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, ViewArmorHands)) }
  }
  if (%armor.hands2 != $null) { 
    if ($2 = channel) { $display.message(03 $+ %armor.hands2,private) }
    if ($2 = private) { $display.private.message(03 $+ %armor.hands2) }
    if ($2 = dcc) { $dcc.private.message($nick, 03 $+ %armor.hands2) }
  }
  if (%armor.hands3 != $null) { 
    if ($2 = channel) { $display.message(03 $+ %armor.hands3,private) }
    if ($2 = private) { $display.private.message(03 $+ %armor.hands3) }
    if ($2 = dcc) { $dcc.private.message($nick, 03 $+ %armor.hands3) }
  }
  if (%armor.hands4 != $null) { 
    if ($2 = channel) { $display.message(03 $+ %armor.hands4,private) }
    if ($2 = private) { $display.private.message(03 $+ %armor.hands4) }
    if ($2 = dcc) { $dcc.private.message($nick, 03 $+ %armor.hands4) }
  }

  if (((((%armor.head = $null) && (%armor.body = $null) && (%armor.legs = $null) && (%armor.feet = $null) && (%armor.hands = $null))))) { 
    if ($2 = channel) { $display.message($readini(translation.dat, system, HasNoArmor),private) }
    if ($2 = private) { $display.private.message($readini(translation.dat, system, HasNoArmor)) }
    if ($2 = dcc) { $dcc.private.message($nick, $readini(translation.dat, system, HasNoArmor)) }
  }    

  unset %armor.head | unset %armor.body | unset %armor.legs | unset %armor.feet | unset %armor.hands | unset %armor.head2 | unset %armor.body2 | unset %armor.legs2 | unset %armor.feet2 | unset %armor.hands2
  unset %armor.head3 | unset %armor.body3 | unset %armor.legs3 | unset %armor.feet3 | unset %armor.hands3
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Equips a weapon
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
wield_weapon {
  if ($2 = right) { writeini $char($1) weapons equipped $3 }
  if ($2 = left) { writeini $char($1) weapons equippedLeft $3 }
  if ($2 = both) { writeini $char($1) weapons equipped $3 | remini $char($1) weapons equippedLeft }

  $set_chr_name($1) | $display.message($readini(translation.dat, system, EquipWeaponPlayer),private)

  $shadowclone.changeweapon($1, $2, $3)

  unset %weapon.equipped.right | unset %weapon.equipped.left | unset %weapon.equipped
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Shadow Clone equips a wepon
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
shadowclone.changeweapon {
  var %cloneowner $readini($char($1 $+ _clone), info, cloneowner)

  if (%cloneowner = $null) { return }

  if ($readini($char($1 $+ _clone), battle, hp) = 0) { return }

  $set_chr_name($1 $+ _clone)
  if ($is_charmed($1 $+ _clone) = true) {  $display.message($readini(translation.dat, status, CurrentlyCharmed), battle) | halt }
  if ($is_confused($ $+ _clone) = true) { $display.message($readini(translation.dat, status, CurrentlyConfused), battle) | halt }
  if ($readini($char($1 $+ _clone), status, weapon.lock) != $null) { $display.message($readini(translation.dat, status, CurrentlyWeaponLocked), battle) | halt }

  if ($2 = both) {  writeini $char($1 $+ _clone) weapons equipped $3 | remini $char($1 $+ _clone) weapons equippedLeft }
  if ($2 = left) { writeini $char($1 $+ _clone) weapons equippedLeft $3 }
  if ($2 = right) { writeini $char($1 $+ _clone) weapons equipped $3 }

  $display.message($readini(translation.dat, system, EquipWeaponPlayer), battle) | halt 
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Giving an item to a target
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
gives.command {
  ; $1 = person giving item
  ; $2 = person receiving item
  ; $3 = amount being given
  ; $4 = item being given

  $set_chr_name($1)
  $check_for_battle($1) 
  $checkchar($2)

  if ($2 = $1) { $display.message($readini(translation.dat, errors, CannotGiveToYourself), private) | halt }


  if (((($4 = redorbs) || ($4 = currency) || ($4 = orb) || ($4 = orbs)))) { 
    $set_chr_name($1)
    ; If the target isn't an npc, we can't give orbs
    if ($readini($char($2), info, flag) != npc) { $display.message($readini(translation.dat, errors, CannotGiveOrbsToPlayers), private) | halt }

    ; If the target's AI isn't "PayToAttack" you can't give orbs to that npc.
    if ($readini($char($2), info, ai_type) != paytoattack) { $display.message($readini(translation.dat, errors, can'tGiveOrbsToThatChar), private) | halt }

    ; Does the player have enough orbs to give?
    var %player.orbs $readini($char($1), stuff, RedOrbs)
    if ((%player.orbs <= 0) || (%player.orbs = $null)) { $display.message($readini(translation.dat, errors, DoesNotHaveEnoughOrbsToTrade), private) | halt }
    if ($3 > %player.orbs) { $display.message($readini(translation.dat, errors, DoesNotHaveEnoughOrbsToTrade), private) | halt }

    ; check for the cap
    var %npc.orbs $readini($char($2), stuff, redorbs)
    if (($3 > 1000) || (%npc.orbs >= 1000)) {  $display.message($readini(translation.dat, errors, Can'tGiveMoreOrbsToNPC), private) | halt }

    ; give orbs to npcs
    if (%npc.orbs = $null) { var %npc.orbs 0 }
    inc %npc.orbs $3
    writeini $char($2) stuff redorbs %npc.orbs

    ; decrease player orbs
    dec %player.orbs $3
    writeini $char($1) stuff redorbs %player.orbs

    $display.message($readini(translation.dat, system, GiveOrbsToTarget), battle)
  }
  else { 
    var %flag $readini($char($2), Info, Flag)
    if (%flag != $null) { $display.message($readini(translation.dat, errors, Can'tGiveToNonChar), private) | halt }

    var %check.item.give $readini($char($1), Item_Amount, $4) 

    if ((%check.item.give <= 0) || (%check.item.give = $null)) { $set_chr_name($1) | $display.message($readini(translation.dat, errors, DoesNotHaveThatItem), private) | halt }
    if ((. isin $3) || ($3 <= 0)) { $display.message($readini(translation.dat, errors, Can'tGiveNegativeItem), private) | halt }
    if ($3 > %check.item.give) { $display.message($readini(translation.dat, errors, CannotGiveThatMuchofItem), private) | halt }

    var %equipped.accessory $readini($char($1), equipment, accessory)
    if (%equipped.accessory = $4) {
      if (%check.item.give <= $3) { $display.message($readini(translation.dat, errors, StillWearingAccessory), private) | halt }
    }

    ; Check to see if it's a piece of armor that's equipped
    var %armor.equip.slot $readini($dbfile(equipment.db), $4, EquipLocation)

    var %equipped.armor $readini($char($1), equipment, %armor.equip.slot)
    if (%equipped.armor = $4) {
      if (%check.item.give = 1) { $display.private.message($readini(translation.dat, errors, StillWearingArmor)) | halt }
    }


    var %give.item.type $readini($dbfile(items.db), $4, type)
    if (%give.item.type != $null) { var %dbfile items.db }
    if (%give.item.type = $null) { var %dbfile equipment.db }

    var %exclusive.test $readini($dbfile(%dbfile), $4, exclusive)
    if (%exclusive.test = $null) { var %exclusive.test no }
    if (%exclusive.test = yes) { $display.message($readini(translation.dat, errors, CannotGiveItem), private) | halt }

    ; If so, decrease the amount
    dec %check.item.give $3
    writeini $char($1) item_amount $4 %check.item.give

    var %target.items $readini($char($2), item_amount, $4)
    inc %target.items $3 
    writeini $char($2) item_amount $4 %target.items

    var %item.to.give.correct $4
    if (($right($4, 1) = y) && ($3 > 1)) {  var %item.to.give.correct $replace(%item.to.give.correct, $right($4,1), ie)  } 

    $display.message($readini(translation.dat, system, GiveItemToTarget), global)

    var %number.of.items.given $readini($char($1), stuff, ItemsGiven)
    if (%number.of.items.given = $null) { var %number.of.items.given 0 }
    inc %number.of.items.given $3
    writeini $char($1) stuff ItemsGiven %number.of.items.given
    $achievement_check($1, Santa'sLittleHelper)
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Adds a random augment
; to a weapon
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
reforge.weapon {
  ; $1 = user
  ; $2 = weapon

  $set_chr_name($1)
  ; Is it a battle?

  if ((%battleis = on) && ($istok($readini($txtfile(battle2.txt), Battle, List),$1,46) = $true))  { $display.message($readini(translation.dat, errors, Can'tReforgepInBattle), private) | halt }

  ; does the player own that weapon?
  var %player.weapon.check $readini($char($1), weapons, $2)

  if ((%player.weapon.check < 1) || (%player.weapon.check = $null)) {  $set_chr_name($1) | $display.message($readini(translation.dat, errors, DoNotHaveWeapon), private) | halt }

  ; does the player have enough black orbs to reforge it?
  var %reforge.cost $round($calc(2 * ($readini($dbfile(weapons.db), $2, cost))),0)
  if (%reforge.cost > 20) { var %reforge.cost 20 }
  var %player.blackorbs $readini($char($1), stuff, BlackOrbs)
  if (%player.blackorbs < %reforge.cost) { $display.message($readini(translation.dat, errors, NotEnoughBlackOrbs), private) | halt }

  ; Can we actually reforge this weapon?
  if ((%reforge.cost <= 0) || ($2 = fists)) { $display.message($readini(translation.dat, errors, Can'tReforgeThatWeapon), private) | halt }

  ; Does the player have enough RepairHammers?
  set %check.item $readini($char($1), Item_Amount, RepairHammer) 
  if ((%check.item <= 0) || (%check.item = $null)) { $set_chr_name($1) | $display.message($readini(translation.dat, errors, DoesNotHaveEnoughHammers), private) | halt }

  ; Augment the weapon
  set %total.augments $lines($lstfile(augments.lst))
  set %random.augment $rand(1, %total.augments)
  set %augment.name $read -l $+ %random.augment $lstfile(augments.lst)
  writeini $char($1) augments $2 %augment.name

  $set_chr_name($1)

  if (%battleis != on) { $display.message($readini(translation.dat, system, WeaponReforged), global) }
  if (%battleis = on) { $display.private.message($readini(translation.dat, system, WeaponReforged)) }

  var %number.of.augments $readini($char($1), stuff, WeaponsReforged)
  if (%number.of.augments = $null) { var %number.of.augments 0 }
  inc %number.of.augments 1
  writeini $char($1) stuff WeaponsReforged %number.of.augments
  $achievement_check($1, HiHoHiHo)

  unset %augment.name | unset %total.augments | unset %random.augment

  ; Decrease the number of black orbs
  dec %player.blackorbs %reforge.cost
  writeini $char($1) stuff blackorbs %player.blackorbs
  $inc.blackorbsspent($1, %reforge.cost)

  ; Decrease the number of RepairHammers.
  $decrease_item($1, RepairHammer) 
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a char's augments
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
augments.list {
  ; Check for augments
  unset %weapon.list | unset %augment.list |  unset %augment.list2 | unset %augment.list3 | unset %augment.list4
  $weapon.list($1)

  var %number.of.augments 0 | var %weapon.counter 1
  while ($weapons.returnlist(%weapon.counter) != $null) {
    set %display.weaponlist $weapons.returnlist(%weapon.counter)
    var %number.of.weapons $numtok(%display.weaponlist,46)
    var %value 1
    while (%value <= %number.of.weapons) {
      set %weapon.name $gettok(%display.weaponlist, %value, 46)
      set %weapon.name $gettok(%weapon.name,1, 40)
      set %weapon_augment $readini($char($1), augments, $strip(%weapon.name))

      if (%weapon_augment != $null) { 
        inc %number.of.augments 1
        var %weapon_to_add  %weapon.name $+ $chr(040) $+ %weapon_augment $+ $chr(041) $+ 

        if (%number.of.augments <= 10) {  %weapon.list = $addtok(%weapon.list,%weapon_to_add,46) }
        if ((%number.of.augments > 10) && (%number.of.augments <= 20)) { %augment.list2 = $addtok(%augment.list2, %weapon_to_add, 46) }
        if ((%number.of.augments > 20) && (%number.of.augments <= 30)) { %augment.list3 = $addtok(%augment.list3, %weapon_to_add, 46) }
        if ((%number.of.augments > 30) && (%number.of.augments <= 40)) { %augment.list4 = $addtok(%augment.list4, %weapon_to_add, 46) }
        if ((%number.of.augments > 40) && (%number.of.augments <= 50)) {  %augment.list5 = $addtok(%augment.list5, %weapon_to_add, 46) }
        if ((%number.of.augments > 40) && (%number.of.augments <= 50)) {  %augment.list5 = $addtok(%augment.list5, %weapon_to_add, 46) }
        if ((%number.of.augments > 50) && (%number.of.augments <= 60)) {  %augment.list6 = $addtok(%augment.list6, %weapon_to_add, 46) }
        if (%number.of.augments > 60) { %augment.list7 = $addtok(%augment.list7, %weapon_to_add, 46) }

      }
      inc %value 1 
    }
    unset %value | unset %weapon.name | unset %weapon_level | unset %number.of.weapons

    $weapons.unsetlist(%weapon.counter) | unset %display.weaponlist
    inc %weapon.counter
    if (%weapon.counter > 100) { echo -a breaking to prevent a flood | break }
  }

  if (%weapon.list = $null) {
    if (($2 = $null) || ($2 = channel)) { $set_chr_name($1) | $display.message($readini(translation.dat, errors, NoAugments), private) } 
    if ($2 = private) {  $set_chr_name($1) | $display.private.message($readini(translation.dat, errors, NoAugments)) } 
    halt 
  }

  if ($chr(046) isin %weapon.list) { set %replacechar $chr(044) $chr(032)
    %weapon.list = $replace(%weapon.list, $chr(046), %replacechar)
    %augment.list2 = $replace(%augment.list2, $chr(046), %replacechar)
    %augment.list3 = $replace(%augment.list3, $chr(046), %replacechar)
    %augment.list4 = $replace(%augment.list4, $chr(046), %replacechar)
    %augment.list5 = $replace(%augment.list5, $chr(046), %replacechar)
    %augment.list6 = $replace(%augment.list6, $chr(046), %replacechar)
    %augment.list7 = $replace(%augment.list7, $chr(046), %replacechar)
  }
  $set_chr_name($1) 

  if (($2 = $null) || ($2 = channel)) {
    $display.message($readini(translation.dat, system, ListOfAugments), private)
    if (%augment.list2 != $null) { $display.message(03 $+ %augment.list2, private) }
    if (%augment.list3 != $null) { $display.message(03 $+ %augment.list3, private) }
    if (%augment.list4 != $null) { $display.message(03 $+ %augment.list4, private) }
    if (%augment.list5 != $null) { $display.message(03 $+ %augment.list5, private) }
    if (%augment.list6 != $null) { $display.message(03 $+ %augment.list6, private) }
    if (%augment.list7 != $null) { $display.message(03 $+ %augment.list7, private) }
  }

  if ($2 = private) {  
    $display.private.message($readini(translation.dat, system, ListOfAugments))
    if (%augment.list2 != $null) { $display.private.message(03 $+ %augment.list2) }
    if (%augment.list3 != $null) { $display.private.message(03 $+ %augment.list3) }
    if (%augment.list4 != $null) { $display.private.message(03 $+ %augment.list4) }
    if (%augment.list5 != $null) { $display.private.message(03 $+ %augment.list5) } 
    if (%augment.list6 != $null) { $display.private.message(03 $+ %augment.list6) }
    if (%augment.list7 != $null) { $display.private.message(03 $+ %augment.list7) }
  }
  unset %augment.list*
  unset %weapon.list | unset %base.weapon.list  | unset %weapons
  unset %weapon_augment | unset %mech.weapon.list | unset %mech.weaponlist2 | unset %replacechar
  unset %weaponlist.counter | unset %mech.weapon.list2
}

augments.strength {
  ; CHECKING AUGMENTS
  unset %augment.list* | unset %weapon.list | unset %base.weapon.list  | unset %weapons | unset %number.of.augments

  var %value 1 | var %augments.lines $lines($lstfile(augments.lst))
  if ((%augments.lines = $null) || (%augments.lines = 0)) { return }

  while (%value <= %augments.lines) {

    var %augment.name $read -l $+ %value $lstfile(augments.lst)

    if ($augment.check($1, %augment.name) = true) {

      inc %number.of.augments 1

      if (%number.of.augments <= 10) {  %augment.list = $addtok(%augment.list,%augment.name $+ [ $+ %augment.strength $+ ],46) }
      if ((%number.of.augments > 10) && (%number.of.augments <= 20)) { %augment.list.2 = $addtok(%augment.list.2, %augment.name $+ [ $+ %augment.strength $+ ], 46) }
      if ((%number.of.augments > 20) && (%number.of.augments <= 30)) { %augment.list.3 = $addtok(%augment.list.3, %augment.name $+ [ $+ %augment.strength $+ ], 46) }
      if ((%number.of.augments > 30) && (%number.of.augments <= 40)) { %augment.list.4 = $addtok(%augment.list.4, %augment.name $+ [ $+ %augment.strength $+ ], 46) }
      if ((%number.of.augments > 40) && (%number.of.augments <= 50)) { %augment.list.5 = $addtok(%augment.list.5, %augment.name $+ [ $+ %augment.strength $+ ], 46) }
      if ((%number.of.augments > 50) && (%number.of.augments <= 60)) { %augment.list.6 = $addtok(%augment.list.6, %augment.name $+ [ $+ %augment.strength $+ ], 46) }
      if ((%number.of.augments > 60) && (%number.of.augments <= 70)) { %augment.list.7 = $addtok(%augment.list.7, %augment.name $+ [ $+ %augment.strength $+ ], 46) }
      if ((%number.of.augments > 70) && (%number.of.augments <= 80)) { %augment.list.8 = $addtok(%augment.list.8, %augment.name $+ [ $+ %augment.strength $+ ], 46) }
      if (%number.of.augments > 80) { %augment.list.9 = $addtok(%augment.list.9, %augment.name $+ [ $+ %augment.strength $+ ], 46) }

    }

    unset %augment.strength
    inc %value 1 
  }

  ; CLEAN UP THE LIST
  if ($chr(046) isin %augment.list ) { set %replacechar $chr(044) $chr(032)
    %augment.list = $replace(%augment.list, $chr(046), %replacechar)
  }
  if ($chr(046) isin %augment.list.2 ) { set %replacechar $chr(044) $chr(032)
    %augment.list.2 = $replace(%augment.list.2, $chr(046), %replacechar)
  }
  if ($chr(046) isin %augment.list.3 ) { set %replacechar $chr(044) $chr(032)
    %augment.list.3 = $replace(%augment.list.3, $chr(046), %replacechar)
  }
  if ($chr(046) isin %augment.list.4 ) { set %replacechar $chr(044) $chr(032)
    %augment.list.4 = $replace(%augment.list.4, $chr(046), %replacechar)
  }
  if ($chr(046) isin %augment.list.5 ) { set %replacechar $chr(044) $chr(032)
    %augment.list.5 = $replace(%augment.list.5, $chr(046), %replacechar)
  }
  if ($chr(046) isin %augment.list.6 ) { set %replacechar $chr(044) $chr(032)
    %augment.list.6 = $replace(%augment.list.6, $chr(046), %replacechar)
  }
  if ($chr(046) isin %augment.list.7 ) { set %replacechar $chr(044) $chr(032)
    %augment.list.7 = $replace(%augment.list.7, $chr(046), %replacechar)
  }
  if ($chr(046) isin %augment.list.8 ) { set %replacechar $chr(044) $chr(032)
    %augment.list.8 = $replace(%augment.list.8, $chr(046), %replacechar)
  }
  if ($chr(046) isin %augment.list.9 ) { set %replacechar $chr(044) $chr(032)
    %augment.list.9 = $replace(%augment.list.9, $chr(046), %replacechar)
  }

  if (%augment.list != $null) { $set_chr_name($1) | $display.message($readini(translation.dat, system, augmentList), private)
    if (%augment.list.2 != $null) { $display.message(03 $+ %augment.list.2, private) }
    if (%augment.list.3 != $null) { $display.message(03 $+ %augment.list.3, private) }
    if (%augment.list.4 != $null) { $display.message(03 $+ %augment.list.4, private) }
    if (%augment.list.5 != $null) { $display.message(03 $+ %augment.list.5, private) }
    if (%augment.list.6 != $null) { $display.message(03 $+ %augment.list.6, private) }
    if (%augment.list.7 != $null) { $display.message(03 $+ %augment.list.7, private) }
    if (%augment.list.8 != $null) { $display.message(03 $+ %augment.list.8, private) }
    if (%augment.list.9 != $null) { $display.message(03 $+ %augment.list.9, private) }
  }
  if (%augment.list = $null) { $set_chr_name($1) | $display.message($readini(translation.dat, system, Noaugments), private) }
  unset %augment.list*
  unset %weapon.list | unset %base.weapon.list  | unset %weapons
  unset %weapon_augment | unset %mech.weapon.list | unset %mech.weaponlist2 | unset %replacechar
  unset %weaponlist.counter | unset %mech.weapon.list2
  unset %number.of.augments 
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Dragon Hunt command
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
character.dragonhunt {
  ; $1 = person doing the hunting

  if ($readini(battlestats.dat, dragonballs, ShenronWish) = on) { $display.message($readini(translation.dat, errors, NoHuntsDuringShenron), private) | halt }

  ; can't do this while a chest exists
  if ($readini($txtfile(treasurechest.txt), ChestInfo, Color) != $null) { $display.message($readini(translation.dat, errors, Can'tDoActionWhileChest), private) | halt }

  ; Has enough time elapsed?
  var %player.lastHunt $readini($char($1), info, LastDragonHuntTime)
  var %time.difference $calc($ctime - %player.lastHunt)
  var %dragonhunt.time.setting 3600
  if ((%time.difference = $null) || (%time.difference < %dragonhunt.time.setting)) { 
    $display.message($readini(translation.dat, errors, DragonHunt.Can'tHunt), private)
    halt 
  }

  ; Are there any dragons to hunt?
  var %dragonhunt.numberofdragons $ini($dbfile(dragonhunt.db),0)
  if (%dragonhunt.numberofdragons = 0) { 
    $display.message($readini(translation.dat, errors, DragonHunt.NoDragons), private) 
    halt
  }

  ; Write the time the user has hunted for a lair
  writeini $char($1) info LastDragonHuntTime $ctime

  ; Check for a dragon's lair
  var %dragonhunt.chance 4

  ; Increase the chance by the global chance
  var %global.dragonchance $readini(battlestats.dat, AlliedForces, DragonHuntChance)
  if (%global.dragonchance = $null) { var %global.dragonchance 0 }
  inc %dragonhunt.chance %global.dragonchance

  ; If there's more than 4 dragons let's increase the odds of finding one
  if (%dragonhunt.numberofdragons > 4) { inc %dragonhunt.chance %dragonhunt.numberofdragons } 

  ; If the combined dragon age is over 800 improve the odds of finding one
  if ($dragonhunt.dragonage.combined > 800) { inc %dragonhunt.chance 8 }

  ; Check for accessories and augments to improve chances
  if ($augment.check($1, EnhanceDragonHunt) = true) { inc %dragonhunt.chance $calc(5 * %augment.strength) }

  if ($accessory.check($1, EnhanceDragonHunt) = true) {
    inc %dragonhunt.chance %accessory.amount
    unset %accessory.amount
  }

  ; Check for DragonHunter skill
  var %dragonhunter.skill $readini($char($1), skills, DragonHunter)
  if (%dragonhunter.skill != $null) { inc %dragonhunt.chance %dragonhunter.skill }

  var %dragonhunt.randomnum $rand(1,100)

  if (%dragonhunt.randomnum > %dragonhunt.chance) { 
    $display.message($readini(translation.dat, errors, DragonHunt.NoLairFound), private) 
    inc %global.dragonchance 10 
    writeini battlestats.dat AlliedForces DragonHuntChance %global.dragonchance
    halt
  }

  else {
    var %dragonhunts.total $readini(battlestats.dat, Battle, TotalDragonHunts)
    if (%dragonhunts.total = $null) { var %dragonhunts.total 0 }
    inc %dragonhunts.total 1
    writeini battlestats.dat Battle TotalDragonHunts %dragonhunts.total

    ; Get the dragon's name that we'll be facing
    var %dragonhunt.numberofdragons $ini($dbfile(dragonhunt.db),0)
    var %random.dragon $rand(1,%dragonhunt.numberofdragons)
    set %dragonhunt.file.name $ini($dbfile(dragonhunt.db), %random.dragon)
    set %dragonhunt.name $readini($dbfile(dragonhunt.db), %dragonhunt.file.name, name)

    var %global.dragonchance 0 
    writeini battlestats.dat AlliedForces DragonHuntChance %global.dragonchance

    $startnormal(DragonHunt, $1)
    halt
  }  
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Returns the average damage
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
character.averagedmg {
  ; $1 = person
  ; $2 = melee or tech

  var %average.damage $readini($char($1), stuff, TotalDmg. $+ $2)
  if (%average.damage = $null) { writeini $char($1) stuff TotalDmg. $+ $2 0 | return 0 }

  var %number.of.hits $readini($char($1), stuff, $2 $+ Hits)
  var %average.damage $round($calc(%average.damage / %number.of.hits),2)

  return %average.damage
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Returns the resting bonus
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
character.resting.bonus.orbs { 
  ; Calculate a "resting" bonus.  This is a bonus to orbs for people who have been out of battle for a while.
  var %last.battle $readini($char($1), Info, LastBattleTime)
  if (%last.battle = $null) { 

    ; Try to calculate the time it's been since they last logged in
    var %last.battle $ctime($readini($char($1), info, LastSeen))

    ; Check again, as a last ditch effort
    if (%last.battle = $null) { var %last.battle $ctime }
  }

  var %rest.time.difference $calc($ctime - %last.battle)
  var %rest.time $calc(%rest.time.difference /60/60)
  var %resting.bonus $round($calc(%rest.time * 150),0)

  if (%resting.bonus < 1) { var %resting.bonus 0 }

  return %resting.bonus
}
character.resting.bonus.killcoins {
  ; Calculate a "resting" bonus.  This is a bonus to coins for people who have been out of battle for a while.
  var %last.battle $readini($char($1), Info, LastBattleTime)
  if (%last.battle = $null) { 

    ; Try to calculate the time it's been since they last logged in
    var %last.battle $ctime($readini($char($1), info, LastSeen))

    ; Check again, as a last ditch effort
    if (%last.battle = $null) { var %last.battle $ctime }
  }

  var %rest.time.difference $calc($ctime - %last.battle)
  var %rest.time $calc(%rest.time.difference /60/60)
  var %resting.bonus $round($calc(%rest.time * 2),0)

  if (%resting.bonus < 1) { var %resting.bonus 0 }

  return %resting.bonus
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Checks to see if a char's
; stat levels up.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
character.stat.levelup.check {
  ; $1 = the person
  ; $2 = the stat

  if ($readini($char($1), info, flag) != $null) { return }

  var %stat.xp $readini($char($1), StatXP, $2)

  ; if this is the first time a player is receiving stat xp then let's see if they've already got
  ; some stuff that we can convert into stat xp.
  if (%stat.xp = $null) { 
    var %stat.xp 0
    writeini $char($1) StatXP $2 0

    if ($2 = str) { 
      var %basexp $readini($char($1), Stuff, MeleeHIts) 
      if (%basexp = $null) { var %basexp 0 }
      var %basexp $round($calc(%basexp / 10),0)
      var %basestat $readini($char($1), BaseStats, $2)
      inc %basestat %basexp
      writeini $char($1) BaseStats $2 %basestat
    }
    if ($2 = int) { 
      var %basexp $readini($char($1), Stuff, techHits) 
      if (%basexp = $null) { var %basexp 0 }
      var %basexp $round($calc(%basexp / 10),0)
      var %basestat $readini($char($1), BaseStats, $2)
      inc %basestat %basexp
      writeini $char($1) BaseStats $2 %basestat 
    }
    if ($2 = def) { 
      var %basexp $readini($char($1), Stuff, TotalDeaths ) 
      if (%basexp = $null) { var %basexp 0 }
      var %basexp $round($calc(%basexp / 10),0)
      var %basestat $readini($char($1), BaseStats, $2)
      inc %basestat %basexp
      writeini $char($1) BaseStats $2 %basestat 
    }
  }

  ; increase the stat xp by 1
  inc %stat.xp 1

  if (%stat.xp = 10) { 
    ; level up the stat and reset the xp 
    var %stat.xp 0
    var %basestat $readini($char($1), BaseStats, $2)
    inc %basestat 1
    writeini $char($1) BaseStats $2 %basestat 
  }

  writeini $char($1) StatXP $2 %stat.xp 
}
