; =====================================================================
;  RenCorner mod setup for mIRC  (vmann259)
;  Load once in mIRC:   /load -rs rencorner.mrc
;  (install-rencorner-mirc.ps1 does this for you on a new PC)
;
;  What it does:
;    - Connects to irc.rencorner.co when mIRC starts
;    - Identifies with NickServ (password + mod channel key asked once,
;      stored only in your local mIRC variables - never in this file)
;    - Waits 5s, then joins the mod/admin channels with the channel key
;    - Adds shortcut commands and a right-click nicklist menu
;
;  Shortcut commands (type these in mIRC):
;    /rc.setup               re-enter your NickServ password and channel key
;    /rc.join                join all RenCorner channels now
;    /rcdelreg <name>        !delreg <name> in #rc-aow-admin
;    /rclistreg <name>       !listreg <name> in #rc-aow-admin
;    /rccheck <name>         HW hash + serial hash + IP info for one player
;    /rccompare <a> <b>      run /rccheck on two names (is A the same as B?)
;    /rchelp <command>       !help <command> in #rc-aow-admin
; =====================================================================

; ---------- settings: edit these if anything changes ----------
alias -l rc.nick    return vmann259
alias -l rc.altnick return vmann259_
alias -l rc.server  return irc.rencorner.co
alias -l rc.key     return %rc.chankey
alias -l rc.admin   return #rc-aow-admin
; channels that need the key
alias -l rc.keyed   return #rc-mods,#rc-aow-admin,#rc-comm-admin,#rc-snipe-admin
; open channels (add #rc-kf, #rc-terraria, etc. if you want them)
alias -l rc.open    return #rc-aow,#rc-comm,#rc-snipe

; ---------- first run / password ----------
alias rc.setup {
  var %p = $input(Enter the NickServ password for $rc.nick $+ . Stored locally in mIRC's variables file.,pq,RenCorner setup)
  if (%p != $null) set %rc.pass %p
  var %k = $input(Enter the mod channel key - ask in #rc-mods if you do not have it.,eq,RenCorner setup)
  if (%k != $null) set %rc.chankey %k
  echo -ag 3[RenCorner] Saved. Type /rc.setup any time to change them.
}

; $input can't run directly inside an event, so start it on a timer
on *:START: {
  if ((!%rc.pass) || (!%rc.chankey)) .timerRCsetup 1 1 rc.firstrun
  else rc.connect
}
alias rc.firstrun { rc.setup | rc.connect }

alias rc.connect {
  server $rc.server -i $rc.nick $rc.altnick $rc.nick $rc.nick
}

; ---------- on connect: identify, then join after 5s ----------
on *:CONNECT: {
  if ((*rencorner* iswm $network) || (*rencorner* iswm $server)) {
    if (%rc.pass) .msg NickServ IDENTIFY %rc.pass
    .timerRCjoin 1 5 rc.join
  }
}

alias rc.join {
  ; one copy of the key per keyed channel: key,key,key,key
  var %n = $numtok($rc.keyed,44)
  var %keys = $left($str($rc.key $+ $chr(44),%n),-1)
  join $rc.keyed %keys
  join $rc.open
}

; ---------- mod shortcuts (sent to #rc-aow-admin, spaced to avoid flood) ----------
alias rchelp    { if (!$1) { echo -ag Usage: /rchelp <command> | return } | msg $rc.admin !help $1 }
alias rcdelreg  { if (!$1) { echo -ag Usage: /rcdelreg <name> | return } | msg $rc.admin !delreg $1 }
alias rclistreg { msg $rc.admin !listreg $1 }

alias rccheck {
  if (!$1) { echo -ag Usage: /rccheck <name> | return }
  msg $rc.admin !hwhash $1
  .timer 1 2 msg $rc.admin !serialhash $1
  .timer 1 4 msg $rc.admin !ipinfo $1
}

alias rccompare {
  if (!$2) { echo -ag Usage: /rccompare <name1> <name2> | return }
  echo -ag 3[RenCorner] Comparing $1 and $2 - matching HW hash or serial = very likely the same person. Matching IP alone is weak.
  rccheck $1
  .timer 1 7 rccheck $2
}

; ---------- right-click a nick in the nicklist ----------
menu nicklist {
  RenCorner
  .Check HW/serial/IP:rccheck $1
  .List registration:rclistreg $1
  .Delete registration:rcdelreg $1
  .Seen:msg $rc.admin !seen $1
}
