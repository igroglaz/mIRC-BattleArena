;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; dungeons.als
;;;; Last updated: 12/12/22
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dungeon.dungeonname { return $readini($dungeonfile($dungeon.dungeonfile), info, name) }
dungeon.currentroom {  return $readini($txtfile(battle2.txt), DungeonInfo, currentRoom) }
dungeon.dungeonfile { return $readini($txtfile(battle2.txt), DungeonInfo, DungeonFile) }
dungeon.bossroomcheck {
  if ($readini($dungeonfile($dungeon.dungeonfile), $dungeon.currentroom, bossroom) = true) { return true }
  else { return false }
}
dungeon.recommendedplayers {
  var %recommended.players $readini($dungeonfile($dungeon.dungeonfile), info, PlayersRecommended)
  if (%recommended.players = $null) { var %recommended.players 2 }
  else { return %recommended.players }
}
dungeon.echo { 
  var %echo.check $readini($dungeonfile($dungeon.dungeonfile), info, Echo)
  if (%echo.check = $null) { return false }
  else { return %echo.check }
}

dungeon.start {
  ; Open the dungeon.
  set %battleis on | set %battleisopen on

  /.timerBattleStart off

  var %time.to.enter $readini(system.dat, system, TimeToEnterDungeon)
  if (%time.to.enter = $null) { var %time.to.enter 120 }
  /.timerBattleBegin 0 %time.to.enter /dungeon.begin

  set %battle.type dungeon

  var %dungeon.players.needed $readini($dungeonfile($3), info, PlayersNeeded)
  if (%dungeon.players.needed = $null) { var %dungeon.players.needed 1 }

  var %dungeon.max.players $readini($dungeonfile($3), Info, PlayersMax)
  if (%dungeon.max.players = $null) { var %dungeon.max.players 0 }

  var %dungeon.players.recommended $readini($dungeonfile($3), Info, PlayersRecommended)
  if (%dungeon.players.recommended = $null) { var %dungeon.players.recommended 2 }

  var %dungeon.level $readini($dungeonfile($3), info, Level)
  if (%dungeon.level = $null) { var %dungeon.level 15 }

  writeini $txtfile(battle2.txt) DungeonInfo DungeonFile $3 
  writeini $txtfile(battle2.txt) DungeonInfo PlayersNeeded %dungeon.players.needed
  writeini $txtfile(battle2.txt) DungeonInfo DungeonLevel %dungeon.level

  writeini $txtfile(battle2.txt) BattleInfo TimeKeyUsed $fulldate

  ; Show the dungeon start message.
  if ($4 != true) { $display.message(02 $+ $get_chr_name($1)  $+ $readini($dungeonfile($3), info, StartBattleDesc), global) }
  if ($4 = true) { $display.message(02 $+ $get_chr_name($1)  $+ $readini($dungeonfile($3), info, StartBattleDesc), global) | writeini $txtfile(battle2.txt) DungeonInfo IgnoreWritingDungeonTime true }

  if (%dungeon.max.players = 0) { $display.message(04This $iif(%portal.bonus = true, portal, dungeon) is level12 %dungeon.level 04and requires12 %dungeon.players.needed $iif(%dungeon.players.needed = 1, player, players) 04to enter (12 $+ %dungeon.players.recommended $+ 04 $iif(%dungeon.players.recommended = 1, player, players) recommended). The $iif(%portal.bonus = true, portal, dungeon) will begin in12 $duration(%time.to.enter) $+ 04. Use !enter if you wish to join the party. , global) }
  else { $display.message(04This $iif(%portal.bonus = true, portal, dungeon) is level12 %dungeon.level 04and will start after12 %dungeon.max.players $iif(%dungeon.max.players = 1, player 04enters, players 04enter) or in12 $duration(%time.to.enter) $+ 04. Use !enter if you wish to join the party. , global) }

}

dungeon.enter {
  $checkchar($1)
  if ((%battleisopen != on) && ($return.systemsetting(AllowLateEntries) != true)) { $set_chr_name($1)
    $display.message($readini(translation.dat, battle, BattleClosed), global)  | halt 
  }

  ; There's a player limit in IRC mode due to the potential for flooding..  There is no limit for DCCchat mode.
  if (($readini(system.dat, system, botType) = IRC) || ($readini(system.dat, system, botType) = TWITCH)) {
    if ($readini($txtfile(battle2.txt), BattleInfo, Players) >= 8) { $display.message($readini(translation.dat, errors, PlayerLimit),private) | halt }
  }

  var %curbat $readini($txtfile(battle2.txt), Battle, List)
  if ($istok(%curbat,$1,46) = $true) { $set_chr_name($1) | $display.message($readini(translation.dat, errors, AlreadyInBattle), private) | halt  }

  ; Is the player too low level to enter?
  if ($get.level($1) < $readini($txtfile(battle2.txt), DungeonInfo, DungeonLevel)) { $display.message($readini(translation.dat, errors, LevelTooLowForDungeon), private) | halt }

  ; For DCCchat mode we need to move the player into the battle room.
  writeini $char($1) DCCchat Room BattleRoom

  ; Add the player to the battle list.
  %curbat = $addtok(%curbat,$1,46)
  writeini $txtfile(battle2.txt) Battle List %curbat
  writeini $txtfile(battle2.txt) Dungeon List %curbat

  if ($readini($char($1), info, flag) = $null) {
    var %battleplayers $readini($txtfile(battle2.txt), BattleInfo, Players)
    inc %battleplayers 1 
    writeini $txtfile(battle2.txt) BattleInfo Players %battleplayers
    writeini $txtfile(battle2.txt) BattleInfo Difficulty 0
    writeini $char($1) info SkippedTurns 0
  }

  ; Restore the player
  $fulls($1)

  ; Add the player to the battle.txt
  write $txtfile(battle.txt) $1

  ; rem a few things
  remini $char($1) skills lockpicking.on
  remini $char($1) info levelsync 
  writeini $char($1) info NeedsFulls yes

  $set_chr_name($1) 
  $display.message($readini(translation.dat, battle, EnteredTheDungeon), global)

  ; Check for max party size
  var %dungeon.max.players $readini($dungeonfile($dungeon.dungeonfile), Info, PlayersMax)
  if (%battleplayers >= %dungeon.max.players) { $dungeon.begin | halt }
}

dungeon.begin {
  unset %monster.list
  set %battleisopen off

  /.timerBattleBegin off

  ; Write the time the dungeon begins
  writeini $txtfile(battle2.txt) BattleInfo TimeStarted $fulldate

  ; First, see if there's any players in the battle..
  var %number.of.players $readini($txtfile(battle2.txt), BattleInfo, Players)
  if (%number.of.players = $null) { var %number.of.players 0 }

  if ((%number.of.players = 0) || (%number.of.players < $readini($txtfile(battle2.txt), DungeonInfo, PlayersNeeded))) { $display.message($readini(translation.dat, errors, NotEnoughPartyMembersForDungeon), global) | $clear_battle | halt }

  ; Dungeon was created successfully so let's write the created time to the person who made it
  if (($readini($txtfile(battle2.txt), DungeonInfo, IgnoreWritingDungeonTime) != true) && (%portal.bonus != true)) { 
    var %dungeon.creator $readini($txtfile(battle2.txt), DungeonInfo, DungeonCreator)
    writeini $char(%dungeon.creator) info LastDungeonStartTime $ctime
  }

  ; Levelsync everyone
  $display.message($readini(translation.dat, system, DungeonLevelSync), battle)
  $portal.sync.players($readini($txtfile(battle2.txt), DungeonInfo, DungeonLevel))

  ; move the dungeon to room 0 and show the opening message
  writeini $txtfile(battle2.txt) DungeonInfo CurrentRoom 0

  $display.message(02* $readini($dungeonfile($dungeon.dungeonfile), $dungeon.currentroom, desc) ,battle)

  /.timerDungeonFullyStart 1 3 /dungeon.firstroom
}

dungeon.firstroom {
  ; The dungeon begins here. Everyone has 1 round to prepare.

  ; Get the battlefield
  $dungeon.battlefield

  ; Get a random weather from the battlefield
  $random.weather.pick

  ; Check to see if there's any battlefield limitations
  $battlefield.limitations

  ; Reset the empty rounds counter.
  writeini battlestats.dat battle emptyRounds 0

  ; Set the # of Turns Before Darkness
  set %darkness.turns 30
  set %battle.rage.darkness false
  set %darkness.fivemin.warn false

  $generate_battle_order
  set %who $read -l1 $txtfile(battle.txt) | set %line 1
  set %current.turn 1 | set %true.turn 1

  $battlelist(public)

  ; To keep someone from sitting and doing nothing for hours at a time, there's a timer that will auto-force the next turn.
  var %nextTimer $readini(system.dat, system, TimeForIdle)
  if (%nextTimer = $null) { var %nextTimer 180 }
  /.timerBattleNext 1 %nextTimer /next forcedturn

  $display.message($readini(translation.dat, battle, StepsUpFirst), battle)

  $aicheck(%who)
}

dungeon.dungeonovercheck {
  var %dungeon.finalroom $readini($dungeonfile($dungeon.dungeonfile), info, finalroom) 
  if ($dungeon.currentroom > %dungeon.finalroom) { return true }
  else { return false } 
}

dungeon.battlefield {
  var %dungeon.battlefield $readini($dungeonfile($dungeon.dungeonfile), $dungeon.currentroom, battlefield)
  if (%dungeon.battlefield = $null) { set %current.battlefield $dungeon.dungeonname Room }
  else { set  %current.battlefield %dungeon.battlefield }
}

dungeon.rewardorbs {
  var %dungeon.level $readini($txtfile(battle2.txt), dungeoninfo, dungeonlevel)
  var %boss.room.check $readini($dungeonfile($dungeon.dungeonfile), $dungeon.currentroom, bossroom)

  if (%boss.room.check = true) { var %dungeon.level $calc(%dungeon.level + 5) }
  else { var %dungeon.level $calc(%dungeon.level + 3) }

  if ($1 = dungeonclear) { var %dungeon.clear true | var %dungeon.level $calc(%dungeon.level + 15) }

  if ($1 = failure) {  
    $battle.calculate.redorbs(defeat, %dungeon.level)
    $battle.reward.redorbs(defeat )
    $battle.reward.killcoins
  } 
  else { 
    $battle.calculate.redorbs(victory, %dungeon.level, %dungeon.clear)
    $battle.reward.redorbs(victory, %dungeon.clear )
    $battle.reward.playerstylepoints
    $battle.reward.playerstylexp
    $battle.reward.ignitionGauge.all
    $battle.reward.killcoins
  }

  if (%dungeon.firsttime.clear = true) { 
    $display.message($readini(translation.dat, battle, FirstTimeDungeonReward), battle)
    unset %dungeon.firsttime.clear
  }

  if ($1 = dungeonclear) { $display.message($readini(translation.dat, battle, RewardOrbsDungeonClear), battle) }
  if ($1 = failure) { $display.message($readini(translation.dat, battle, RewardOrbsLoss), battle) }
  if (($1 != dungeonclear) && ($1 != failure)) { $display.message($readini(translation.dat, battle, RewardOrbsWin), battle) }
}


dungeon.clearroom { 
  ; reward orbs for killing monsters
  if ($readini($dungeonfile($dungeon.dungeonfile), $dungeon.currentroom, monsters) != $null) { $dungeon.rewardorbs }

  ; Clear dead monsters
  $multiple_wave_clearmonsters

  ; Increase the room #
  var %current.room $dungeon.currentroom
  inc %current.room 1
  writeini $txtfile(battle2.txt) DungeonInfo CurrentRoom %current.room

  if ($dungeon.dungeonovercheck = true) { $dungeon.end | halt } 

  $display.message(02* $readini($dungeonfile($dungeon.dungeonfile), $dungeon.currentroom, desc) ,battle)

  /.timerDungeonSlowDown2 1 5 /dungeon.nextroom
}

dungeon.reset.lastbattle {
  ; The echo has activated!  Let's reset the last battle.
  $display.message($readini(translation.dat, system, EchoActivated))
  .echo -q $findfile( $char_path , *.char, 0 , 0, clear_all_monsters $1-)


  .remove $txtfile(battle.txt)

  var %monster.list $readini($txtfile(battle2.txt), BattleInfo, MonsterList) 
  var %battle.list $readini($txtfile(battle2.txt), Battle, list)
  var %monster.count 1 |  var %number.of.monsters $numtok(%monster.list,46)

  while (%monster.count <= %number.of.monsters) {
    var %monster.name  $gettok(%monster.list, %monster.count,46)
    remini $txtfile(battle2.txt) BattleInfo %monster.name $+ .lastactionbar
    .remove $char(%monster.name) 
    %battle.list = $remtok(%battle.list,%monster.name,46) 
    inc %monster.count
  }

  var %player.count 1 | var %players.total $numtok(%battle.list, 46)
  while (%player.count <= %players.total) {
    var %player.name  $gettok(%battle.list, %player.count,46)
    write $txtfile(battle.txt) %player.name
    inc %player.count 
  }

  writeini $txtfile(battle2.txt) battle list %battle.list
  .remini $txtfile(battle2.txt) BattleInfo MonsterList
  .remini $txtfile(battle2.txt) BattleInfo monsters 
  .remini $txtfile(battle2.txt) Actionpoints
  .remini $txtfile(battle2.txt) style 

  var %current.room $dungeon.currentroom
  dec %current.room 1
  writeini $txtfile(battle2.txt) DungeonInfo CurrentRoom %current.room

  ; Restore every player and move back to the room that was failed.
  $dungeon.restoreroom
  halt
}

dungeon.end { 

  var %total.battle.duration $battle.calculateBattleDuration

  if (($1 = failure) || ($1 = draw)) { 

    ; Check for the Echo. If echo is true, reset the last battle and try again!  
    if (($dungeon.echo = true) && (%echo.on != true)) {   
      set %echo.on true
      $dungeon.reset.lastbattle 
      halt        
    }

    ; Check for the Echo. If echo is true and has already activated then it's over.
    if (($dungeon.echo = true) && (%echo.on = true)) {   
      $display.message(02 $+ $readini($dungeonfile($dungeon.dungeonfile), info, DungeonFail), global) 
      $dungeon.rewardorbs(failure) 
    }

    ; If the dungeon doesn't have Echo enabled then just end.
    if ($dungeon.echo = false) { 
      $display.message(02 $+ $readini($dungeonfile($dungeon.dungeonfile), info, DungeonFail), global) 
      $dungeon.rewardorbs(failure) 
    }

  }

  else { 
    $display.message(02 $+ $readini($dungeonfile($dungeon.dungeonfile), info, cleardungeondesc), global) 

    if (%portal.bonus = true) { $portal.alliednotes($readini($txtfile(battle2.txt), Battle, PortalItem)) } 

    ; give orb rewards
    $dungeon.rewardorbs(dungeonClear)

    ; give out a reward
    $generate_style_order

    $battle.reward.blackorbs 
    if (%black.orb.winners != $null) { $display.message($readini(translation.dat, battle, BlackOrbWin), battle)   }

    if (%portal.bonus = true) {
      if ($readini($txtfile(battle2.txt), battle, alliednotes) != $null) { $display.message($readini(translation.dat, battle, AlliedNotesGain), battle)  }

      var %battletxt.lines $lines($txtfile(battle.txt)) | var %battletxt.current.line 1 
      while (%battletxt.current.line <= %battletxt.lines) { 
        var %who.battle $read -l $+ %battletxt.current.line $txtfile(battle.txt)
        var %flag $readini($char(%who.battle), info, flag)
        if ((%flag = monster) || (%flag = npc)) { inc %battletxt.current.line 1 }
        else { 

          var %total.portalbattles.won $readini($char(%who.battle), stuff, PortalBattlesWon) 
          if (%total.portalbattles.won = $null) { var %total.portalbattles.won 0 }
          inc %total.portalbattles.won 1 

          writeini $char(%who.battle) stuff PortalBattlesWon %total.portalbattles.won

          $achievement_check(%who.battle, AlliedScrub)
          $achievement_check(%who.battle, AlliedSoldier)
          $achievement_check(%who.battle, AlliedGeneral)

          inc %battletxt.current.line          
        }
      }
    }

    $give_random_reward

    $dungeon.spoils.drop
    $show.random.reward

    $create_treasurechest
  }

  ; then do a $clear_battle
  set %battleis off | unset %portal.bonus | $clear_battle | halt
}

dungeon.spoils.drop {
  var %most.stylish.player $readini($txtfile(battle2.txt), battle, MostStylish)
  unset %item.drop.rewards

  var %boss.list $readini($txtfile(battle2.txt), BattleInfo, MonsterList)

  if (%boss.list = $null) { return }

  set %battletxt.lines $lines($txtfile(battle.txt)) | var %battletxt.current.line 1 
  while (%battletxt.current.line <= %battletxt.lines) { 
    var %who.battle $read -l $+ %battletxt.current.line $txtfile(battle.txt)
    var %flag $readini($char(%who.battle), info, flag)

    if ((%flag = monster) || (%flag = npc)) { inc %battletxt.current.line 1 }
    else { 

      if (%who.battle != %most.stylish.player) { 

        var %random.boss.monster $gettok(%boss.list,$numtok(%boss.list, 46),46)
        var %reward.list $readini($dbfile(spoils.db), drops, %random.boss.monster)
        if (%reward.list = $null) { return }

        var %drop.reward $gettok(%reward.list,$rand(1,$numtok(%reward.list, 46)),46)
        var %player.amount $readini($char(%who.battle), Item_Amount, %drop.reward)
        if (%player.amount = $null) { var %player.amount 0 }

        var %item.reward.amount 1
        inc %player.amount %item.reward.amount

        writeini $char(%who.battle) item_amount %drop.reward %player.amount
        $set_chr_name(%who.battle) 

        var %drop.counter $readini($char(%who.battle), stuff, dropsrewarded)
        if (%drop.counter = $null) { var %drop.counter 0 }
        inc %drop.counter 1
        writeini $char(%who.battle) stuff DropsRewarded %drop.counter

        %item.drop.rewards = $addtok(%item.drop.rewards, %real.name $+  $+ $chr(91) $+ %drop.reward x $+ %item.reward.amount $+  $+ $chr(93) $+ , 46)

        inc %battletxt.current.line 1 
      }
      else { inc %battletxt.current.line 1 }

    }
  }

}

dungeon.nextroom {
  ; Get the battlefield
  $dungeon.battlefield

  ; Get a random weather from the battlefield
  $random.weather.pick(inbattle)

  ; Check to see if there's any battlefield limitations
  $battlefield.limitations

  ; Reset the empty rounds counter.
  writeini battlestats.dat battle emptyRounds 0

  ; Set the # of Turns Before Darkness
  set %darkness.turns $readini($dungeonfile($dungeon.dungeonfile), $dungeon.currentroom, DarknessTurns)
  if (%darkness.turns = $null) { set %darkness.turns 30 }

  set %battle.rage.darkness false
  set %darkness.fivemin.warn false

  remini $txtfile(battle2.txt) battle bonusitem
  remini $txtfile(battle2.txt) style

  if ($readini($dungeonfile($dungeon.dungeonfile), $dungeon.currentroom, RestoreRoom) = true) { $dungeon.restoreroom }
  if ($readini($dungeonfile($dungeon.dungeonfile), $dungeon.currentroom, StoryRoom) = true) { $dungeon.storyroom }
  if ($readini($dungeonfile($dungeon.dungeonfile), $dungeon.currentroom, RestoreMech) = true) { $dungeon.restoremech }

  else { 
    ; Generate dungeon monsters
    $dungeon.generatemonsters

    ; Generate dungeon npcs
    $dungeon.generatenpcs

    ; Generate dungeon objects
    $dungeon.objects 

    $generate_battle_order(dungeonnewroom)
    set %who $read -l1 $txtfile(battle.txt) | set %line 1
    set %current.turn 1

    $battlelist(public)

    ; To keep someone from sitting and doing nothing for hours at a time, there's a timer that will auto-force the next turn.
    var %nextTimer $readini(system.dat, system, TimeForIdle)
    if (%nextTimer = $null) { var %nextTimer 180 }
    /.timerBattleNext 1 %nextTimer /next forcedturn

    $turn(%who)

    unset %wait.your.turn
  }
}


dungeon.generatemonsters {
  ; Clear the old spoil list
  remini $txtfile(battle2.txt) BattleInfo MonsterList

  ; Get the list of monsters from the room
  var %monster.list $readini($dungeonfile($dungeon.dungeonfile), $dungeon.currentroom, monsters)
  var %dungeon.level $readini($txtfile(battle2.txt), DungeonInfo, DungeonLevel)

  if ($readini($dungeonfile($dungeon.dungeonfile), $dungeon.currentroom, BossRoom) = true) { var %monster.level $readini($dungeonfile($dungeon.dungeonfile), Info, BossLevel) }
  else { var %monster.level $readini($dungeonfile($dungeon.dungeonfile), Info, MonsterLevel) }
  if (%monster.level = $null) { var %monster.level %dungeon.level }

  if (($dungeon.echo = true) && (%echo.on = true)) { 
    dec %monster.level 10 
    if (%monster.level <= 0) { var %monster.level 5 }
  }

  if (%monster.list = dungeon.evilclone) { 
    var %clone.list $readini($txtfile(battle2.txt), battle, list)
    var %number.of.items $numtok(%clone.list, 46)
    var %clone.person.number $rand(1,%number.of.items)
    var %clone $gettok(%clone.list, %clone.person.number, 46)
    $dungeon.evilclone(%clone) 
  }
  else { 

    ; Cycle through and summon each
    var %value 1 | var %multiple.monster.counter 2 | set %number.of.monsters $numtok(%monster.list,46)
    while (%value <= %number.of.monsters) { 
      unset %multiple.monster.found
      set %current.monster.to.spawn $gettok(%monster.list,%value,46)

      var %isboss $isfile($boss(%current.monster.to.spawn))
      var %ismonster $isfile($mon(%current.monster.to.spawn))

      if ((%isboss != $true) && (%ismonster != $true)) { inc %value }
      else { 
        set %found.monster true 
        var %current.monster.to.spawn.name %current.monster.to.spawn

        while ($isfile($char(%current.monster.to.spawn.name)) = $true) { 
          var %current.monster.to.spawn.name %current.monster.to.spawn $+ %multiple.monster.counter 
          inc %multiple.monster.counter 1 | var %multiple.monster.found true
        }
      }

      if ($isfile($boss(%current.monster.to.spawn)) = $true) { .copy -o $boss(%current.monster.to.spawn) $char(%current.monster.to.spawn.name)  }
      if ($isfile($mon(%current.monster.to.spawn)) = $true) {  .copy -o $mon(%current.monster.to.spawn) $char(%current.monster.to.spawn.name)  }

      if (%multiple.monster.found = true) {  
        var %real.name.spawn $readini($char(%current.monster.to.spawn), basestats, name) $calc(%multiple.monster.counter - 1)
        writeini $char(%current.monster.to.spawn.name) basestats name %real.name.spawn
      }

      ; increase the total # of monsters
      set %battlelist.toadd $readini($txtfile(battle2.txt), Battle, List) | %battlelist.toadd = $addtok(%battlelist.toadd,%current.monster.to.spawn.name,46) | writeini $txtfile(battle2.txt) Battle List %battlelist.toadd | unset %battlelist.toadd
      write $txtfile(battle.txt) %current.monster.to.spawn.name
      var %battlemonsters $readini($txtfile(battle2.txt), BattleInfo, Monsters) | inc %battlemonsters 1 | writeini $txtfile(battle2.txt) BattleInfo Monsters %battlemonsters

      if (($readini(system.dat, system, botType) = IRC) || ($readini(system.dat, system, botType) = TWITCH)) { 
        var %timer.delay $calc(%value - 1)

        if (%number.of.monsters > 2) { 
          dec %timer.delay 2
          if (%timer.delay <= 0) { var %timer.delay 0 }
        } 

        $set_chr_name(%current.monster.to.spawn.name) 
        $display.message($readini(translation.dat, battle, EnteredTheBattle), battle)

        ; display the description of the spawned monster if it's a boss room
        if ($dungeon.bossroomcheck = true) { 
          $display.message(12 $+ %real.name  $+ $readini($char(%current.monster.to.spawn.name), descriptions, char), battle)  
          if ($readini($char(%current.monster.to.spawn.name), descriptions, BossQuote) != $null) { $display.message(02 $+ %real.name looks at the heroes and says " $+ $readini($char(%current.monster.to.spawn.name), descriptions, BossQuote) $+ ", battle) }

        }
      }

      if ($readini(system.dat, system, botType) = DCCchat) {
        $display.message($readini(translation.dat, battle, EnteredTheBattle), battle)
        $display.message(12 $+ %real.name  $+ $readini($char(%current.monster.to.spawn.name), descriptions, char), battle)
        if (%bossquote != $null) {   $display.message(02 $+ %real.name looks at the heroes and says " $+ $readini($char(%current.monster.to.spawn.name), descriptions, BossQuote) $+ ", battle) }
      }

      ; Boost the monster
      $levelsync(%current.monster.to.spawn.name, %monster.level)
      writeini $char(%current.monster.to.spawn.name) basestats str $readini($char(%current.monster.to.spawn.name), battle, str)
      writeini $char(%current.monster.to.spawn.name) basestats def $readini($char(%current.monster.to.spawn.name), battle, def)
      writeini $char(%current.monster.to.spawn.name) basestats int $readini($char(%current.monster.to.spawn.name), battle, int)
      writeini $char(%current.monster.to.spawn.name) basestats spd $readini($char(%current.monster.to.spawn.name), battle, spd)

      $boost_monster_hp(%current.monster.to.spawn.name, dungeon, $get.level(%current.monster.to.spawn.name))

      $fulls(%current.monster.to.spawn.name, yes)

      var %spoil.monster.list $readini($txtfile(battle2.txt), BattleInfo, MonsterList)
      var %spoil.monster.list $addtok(%spoil.monster.list, %current.monster.to.spawn.name, 46)
      writeini $txtfile(battle2.txt) BattleInfo MonsterList %spoil.monster.list

      set %multiple.wave.bonus yes
      set %first.round.protection yes
      unset %darkness.fivemin.warn
      unset %battle.rage.darkness

      ; Get the boss item.
      $check_drops(%current.monster.to.spawn.name)

      inc %value

    }
  }

  unset %found.monster
}


dungeon.generatenpcs {
  ; Get the list of npcs from the room
  var %npc.list $readini($dungeonfile($dungeon.dungeonfile), $dungeon.currentroom, npcs)
  var %dungeon.level $readini($txtfile(battle2.txt), DungeonInfo, DungeonLevel)

  if (%npc.list = $null) { return }

  ; Cycle through and summon each
  var %value 1 | var %multiple.npc.counter 2 | set %number.of.npcs $numtok(%npc.list,46)
  while (%value <= %number.of.npcs) { 
    unset %multiple.npc.found
    set %current.npc.to.spawn $gettok(%npc.list,%value,46)

    var %isnpc $isfile($npc(%current.npc.to.spawn))

    if ((%isnpc != $true) && (%isnpc != $true)) { inc %value }
    else { 
      set %found.npc true 
      var %current.npc.to.spawn.name %current.npc.to.spawn

      while ($isfile($char(%current.npc.to.spawn.name)) = $true) { 
        var %current.npc.to.spawn.name %current.npc.to.spawn $+ %multiple.npc.counter 
        inc %multiple.npc.counter 1 | var %multiple.npc.found true
      }
    }

    if ($isfile($npc(%current.npc.to.spawn)) = $true) {  .copy -o $npc(%current.npc.to.spawn) $char(%current.npc.to.spawn.name)  }

    if (%multiple.npc.found = true) {  
      var %real.name.spawn $readini($char(%current.npc.to.spawn), basestats, name) $calc(%multiple.npc.counter - 1)
      writeini $char(%current.npc.to.spawn.name) basestats name %real.name.spawn
    }

    ; increase the total # of npcs
    set %battlelist.toadd $readini($txtfile(battle2.txt), Battle, List) | %battlelist.toadd = $addtok(%battlelist.toadd,%current.npc.to.spawn.name,46) | writeini $txtfile(battle2.txt) Battle List %battlelist.toadd | unset %battlelist.toadd
    write $txtfile(battle.txt) %current.npc.to.spawn.name
    var %battlenpcs $readini($txtfile(battle2.txt), BattleInfo, npcs) | inc %battlenpcs 1 | writeini $txtfile(battle2.txt) BattleInfo npcs %battlenpcs

    var %npc.level $readini($char(%current.npc.to.spawn.name), info, npclevel)

    if (%npc.level = $null) { var %npc.level 15 }
    if (%npc.level < %dungeon.level) { var %npc.level %dungeon.level }
    ;   if (%npc.level > $calc(%dungeon.level + 10)) { var %npc.level $calc(%dungeon.level + 10) }

    ; display the description of the spawned npc
    $set_chr_name(%current.npc.to.spawn.name) 

    if (($readini(system.dat, system, botType) = IRC) || ($readini(system.dat, system, botType) = TWITCH)) { 
      var %timer.delay $calc(%value - 1)

      if (%number.of.npcs > 2) { 
        dec %timer.delay 2
        if (%timer.delay <= 0) { var %timer.delay 0 }
      } 
      $display.message(12 $+ %real.name has entered the battle to help the forces of good!,battle)

      var %npcquote $readini($char(%current.npc.to.spawn.name), descriptions, npcquote)
      if (%npcquote != $null) { 
        var %npcquote 02 $+ %real.name looks at the heroes and says " $+ $readini($char(%current.npc.to.spawn), descriptions, npcQuote) $+ "
        $display.message(%npcquote, battle) 
      }
    }

    if ($readini(system.dat, system, botType) = DCCchat) {
      $display.message($readini(translation.dat, battle, EnteredTheBattle), battle)
      $display.message(12 $+ %real.name  $+ $readini($char(%current.npc.to.spawn.name), descriptions, char), battle)
      if (%npcquote != $null) {   $display.message(02 $+ %real.name looks at the heroes and says " $+ $readini($char(%current.npc.to.spawn.name), descriptions, npcQuote) $+ ", battle) }
    }

    ; Boost the npc
    $levelsync(%current.npc.to.spawn.name, %npc.level)
    writeini $char(%current.npc.to.spawn.name) basestats str $readini($char(%current.npc.to.spawn.name), battle, str)
    writeini $char(%current.npc.to.spawn.name) basestats def $readini($char(%current.npc.to.spawn.name), battle, def)
    writeini $char(%current.npc.to.spawn.name) basestats int $readini($char(%current.npc.to.spawn.name), battle, int)
    writeini $char(%current.npc.to.spawn.name) basestats spd $readini($char(%current.npc.to.spawn.name), battle, spd)

    $boost_monster_hp(%current.npc.to.spawn.name, dungeon, $get.level(%current.npc.to.spawn.name))

    $fulls(%current.npc.to.spawn.name, yes)

    inc %value

  }
  unset %found.npc
}

dungeon.restoreroom {
  ; Restores players to full health, tp, and clears their skill timers.

  $display.message(07* The party feels their health $+ $chr(44)  tp $+ $chr(44)  and power being restored!)

  var %battletxt.lines $lines($txtfile(battle.txt)) | var %battletxt.current.line 1 
  while (%battletxt.current.line <= %battletxt.lines) { 
    var %who.battle $read -l $+ %battletxt.current.line $txtfile(battle.txt)
    var %flag $readini($char(%who.battle), info, flag)

    if (%flag != monster) { $fulls(%who.battle, dungeon) |  $clear_skill_timers(%who.battle) |  writeini $char(%who.battle) info NeedsFulls yes }

    inc %battletxt.current.line
  }

  ; Resync everyone
  $portal.sync.players($readini($txtfile(battle2.txt), DungeonInfo, DungeonLevel))

  ; Move to the next room.
  var %current.room $dungeon.currentroom
  inc %current.room 1
  writeini $txtfile(battle2.txt) DungeonInfo CurrentRoom %current.room

  if ($dungeon.dungeonovercheck = true) { $dungeon.end | halt } 

  $display.message(02* $readini($dungeonfile($dungeon.dungeonfile), $dungeon.currentroom, desc) ,battle)

  /.timerDungeonSlowDown2 1 5 /dungeon.nextroom
  halt
}

dungeon.restoremech {
  $display.message(07* The party feels their mech hp $+ $chr(44)  and energy restored in this room)

  var %battletxt.lines $lines($txtfile(battle.txt)) | var %battletxt.current.line 1 
  while (%battletxt.current.line <= %battletxt.lines) { 
    var %who.battle $read -l $+ %battletxt.current.line $txtfile(battle.txt)
    var %flag $readini($char(%who.battle), info, flag)

    if (%flag != monster) { 
      var %mech.hpmax $readini($char(%who.battle), mech, HpMax) 
      var %mech.energymax $readini($char(%who.battle), mech, EnergyMax) 

      if (%mech.hpmax != $null) { writeini $char(%who.battle) mech HpCurrent %mech.hpmax }
      if (%mech.energymax != $null) { writeini $char(%who.battle) mech EnergyCurrent %mech.energymax }
    }

    inc %battletxt.current.line
  }

  ; Move to the next room.
  var %current.room $dungeon.currentroom
  inc %current.room 1
  writeini $txtfile(battle2.txt) DungeonInfo CurrentRoom %current.room

  if ($dungeon.dungeonovercheck = true) { $dungeon.end | halt } 

  $display.message(02* $readini($dungeonfile($dungeon.dungeonfile), $dungeon.currentroom, desc) ,battle)

  /.timerDungeonSlowDown2 1 5 /dungeon.nextroom
  halt
}

dungeon.storyroom {
  ; This room is only there to display text.  It doesn't heal anyone like a restore room.

  var %current.room $dungeon.currentroom
  inc %current.room 1
  writeini $txtfile(battle2.txt) DungeonInfo CurrentRoom %current.room

  if ($dungeon.dungeonovercheck = true) { $dungeon.end | halt } 

  $display.message(02* $readini($dungeonfile($dungeon.dungeonfile), $dungeon.currentroom, desc) ,battle)

  /.timerDungeonSlowDown2 1 5 /dungeon.nextroom
  halt
}


dungeon.objects {  
  var %breakable.objects $readini($dungeonfile($dungeon.dungeonfile), $dungeon.currentroom, objects)
  if (%breakable.objects = $null) { return }

  var %number.of.objects $numtok(%breakable.objects,46)
  var %current.object 1
  while (%current.object <= %number.of.objects) {
    var %object.chosen $gettok(%breakable.objects, %current.object, 46)

    .copy -o $char(new_chr) $char(%object.chosen)
    writeini $char(%object.chosen) info flag monster 
    writeini $char(%object.chosen) Basestats name %object.chosen
    writeini $char(%object.chosen) info password .8V%N)W1T;W5C:'1H:7,`1__.1134
    writeini $char(%object.chosen) info gender its
    writeini $char(%object.chosen) info gender2 its
    writeini $char(%object.chosen) info bosslevel 1
    writeini $char(%object.chosen) info CanTaunt false
    writeini $char(%object.chosen) basestats HP 1
    writeini $char(%object.chosen) battle HP 1
    writeini $char(%object.chosen) descriptions DeathMessage crumbles into pieces all over the ground
    writeini $char(%object.chosen) descriptions char is a breakable object
    writeini $char(%object.chosen) info ai_type defender
    writeini $char(%object.chosen) monster type object

    set %curbat $readini($txtfile(battle2.txt), Battle, List) |  %curbat = $addtok(%curbat,%object.chosen,46) |  writeini $txtfile(battle2.txt) Battle List %curbat | write $txtfile(battle.txt) %object.chosen

    inc %current.object
  }

}


;================================
; Aliases below this line are for special
; dungeons
;================================
dungeon.haukke.lampcount {
  var %haukke.lamps.lit 0
  if ($readini($char(Haukke_Lamp1), battle, hp) > 0) { inc %haukke.lamps.lit 1 }
  if ($readini($char(Haukke_Lamp2), battle, hp) > 0) { inc %haukke.lamps.lit 1 }
  if ($readini($char(Haukke_Lamp3), battle, hp) > 0) { inc %haukke.lamps.lit 1 }
  if ($readini($char(Haukke_Lamp4), battle, hp) > 0) { inc %haukke.lamps.lit 1 }
  return %haukke.lamps.lit
}


dungeon.pirate.bubblecount {
  ; $1 = red or blue

  var %bubble.count 0

  if ($1 = blue) { 
    if ($readini($char(Blue_Bubble), battle, hp) > 0) { inc %bubble.count 1 }
    if ($readini($char(Blue_Bubble1), battle, hp) > 0) { inc %bubble.count 1 }
    if ($readini($char(Blue_Bubble2), battle, hp) > 0) { inc %bubble.count 1 }
    if ($readini($char(Blue_Bubble3), battle, hp) > 0) { inc %bubble.count 1 }
    if ($readini($char(Blue_Bubble4), battle, hp) > 0) { inc %bubble.count 1 }
    if ($readini($char(Blue_Bubble5), battle, hp) > 0) { inc %bubble.count 1 }
    if ($readini($char(Blue_Bubble6), battle, hp) > 0) { inc %bubble.count 1 }
    if ($readini($char(Blue_Bubble7), battle, hp) > 0) { inc %bubble.count 1 }
    if ($readini($char(Blue_Bubble8), battle, hp) > 0) { inc %bubble.count 1 }
    if ($readini($char(Blue_Bubble9), battle, hp) > 0) { inc %bubble.count 1 }
    if ($readini($char(Blue_Bubble10), battle, hp) > 0) { inc %bubble.count 1 }
  }

  if ($1 = red) { 
    if ($readini($char(Red_Bubble), battle, hp) > 0) { inc %bubble.count 1 }
    if ($readini($char(Red_Bubble1), battle, hp) > 0) { inc %bubble.count 1 }
    if ($readini($char(Red_Bubble2), battle, hp) > 0) { inc %bubble.count 1 }
    if ($readini($char(Red_Bubble3), battle, hp) > 0) { inc %bubble.count 1 }
    if ($readini($char(Red_Bubble4), battle, hp) > 0) { inc %bubble.count 1 }
    if ($readini($char(Red_Bubble5), battle, hp) > 0) { inc %bubble.count 1 }
    if ($readini($char(Red_Bubble6), battle, hp) > 0) { inc %bubble.count 1 }
    if ($readini($char(Red_Bubble7), battle, hp) > 0) { inc %bubble.count 1 }
    if ($readini($char(Red_Bubble8), battle, hp) > 0) { inc %bubble.count 1 }
    if ($readini($char(Red_Bubble9), battle, hp) > 0) { inc %bubble.count 1 }
    if ($readini($char(Red_Bubble10), battle, hp) > 0) { inc %bubble.count 1 }
  }

  return %bubble.count
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This function generates a 
; single evil doppelganger
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dungeon.evilclone {
  var %clone.name Evil_ $+ $1
  .copy $char($1) $char(%clone.name)
  var %dungeon.level $readini($txtfile(battle2.txt), DungeonInfo, DungeonLevel)

  ; Copy the battle stats over to basestats to account for level sync
  writeini $char(%clone.name) basestats str $readini($char($1), battle, str)
  writeini $char(%clone.name) basestats def $readini($char($1), battle, def)
  writeini $char(%clone.name) basestats int $readini($char($1), battle, int)
  writeini $char(%clone.name) basestats spd $readini($char($1), battle, spd)

  $levelsync(%clone.name, %dungeon.level)
  writeini $char(%clone.name) basestats str $readini($char(evil_ $+ $1), battle, str)
  writeini $char(%clone.name) basestats def $readini($char(evil_ $+ $1), battle, def)
  writeini $char(%clone.name) basestats int $readini($char(evil_ $+ $1), battle, int)
  writeini $char(%clone.name) basestats spd $readini($char(evil_ $+ $1), battle, spd)

  writeini $char(%clone.name) info flag monster 
  writeini $char(%clone.name) info clone yes
  writeini $char(%clone.name) info Doppelganger yes
  writeini $char(%clone.name) Basestats name Evil Doppelganger of $1
  writeini $char(%clone.name) info password .8V%N)W1T;W5C:'1H:7,`1__.154
  $boost_monster_stats(%clone.name, doppelganger)
  set %curbat $readini($txtfile(battle2.txt), Battle, List) |  %curbat = $addtok(%curbat,%clone.name,46) |  writeini $txtfile(battle2.txt) Battle List %curbat | write $txtfile(battle.txt) %clone.name
  $set_chr_name(%clone.name) 

  var %style.chance $rand(1,3)
  if (%style.chance = 1) { writeini $char(%clone.name) styles equipped trickster }
  if (%style.chance = 2) { writeini $char(%clone.name) styles equipped guardian }
  if (%style.chance = 3) { writeini $char(%clone.name) styles equipped weaponmaster }

  writeini $char(%clone.name) status resist-fire no | writeini $char(%clone.name) status resist-lightning no | writeini $char(%clone.name) status resist-ice no
  writeini $char(%clone.name) status resist-earth no | writeini $char(%clone.name) status resist-wind no | writeini $char(%clone.name) status resist-water no
  writeini $char(%clone.name) status resist-light no | writeini $char(%clone.name) status resist-dark no
  writeini $char(%clone.name) status revive no

  $display.message($readini(translation.dat, battle, EnteredTheBattle),battle)

  var %battlemonsters $readini($txtfile(battle2.txt), BattleInfo, Monsters) | inc %battlemonsters 1 | writeini $txtfile(battle2.txt) BattleInfo Monsters %battlemonsters
  inc %battletxt.current.line 1 

  $fulls(%clone.name, yes) 

  var %boss.item $readini($dungeonfile($dungeon.dungeonfile), Info, Reward)
  writeini $txtfile(battle2.txt) battle bonusitem %boss.item | unset %boss.item

  set %multiple.wave.bonus yes
  set %first.round.protection yes
  set %darkness.turns 51
  unset %darkness.fivemin.warn
  unset %battle.rage.darkness
}
