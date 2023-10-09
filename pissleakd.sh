#!/bin/bash

# config

debug=0
sname="pissleakd.baseduser.eu.org"
sid="9RD"

#### Boilerplate

cleanup() { # kill everything
  for pid in $( jobs -p ); do
    kill $pid 2>/dev/null;
  done;
  rm /tmp/$$_0 /tmp/$$_1 /tmp/$$_2;
}

secho() {
    local yellow=$(echo -ne "\e[33;1m")
    local yellowN=$(echo -ne "\e[37;22m")
    if [[ $debug == 0 ]]; then
      echo $@ > /tmp/$$_0
    fi
    echo "${yellow}$@${yellowN}"
}

hello() {
    if [[ $debug == 1 ]]; then
      echo "PASS :<redacted>"
    else
      echo "PASS :$(<pass.txt)"
    fi
    echo "PROTOCTL EAUTH=${sname} SID=${sid}"
    echo "PROTOCTL NOQUIT NICKv2 SJOIN SJ3 CLK TKLEXT TKLEXT2 NICKIP ESVID MLOCK EXTSWHOIS"
    echo "SERVER ${sname} 1 :Central Command"
    echo "NETINFO 1 $(date +%s) 6100 * 0 0 0 :pissnet"
    echo ":${sname} EOS"
}

scase()
{ # scase(inp, pos, cmd)
    #local stdin=$(cat)
    local tok=$(echo $line | cut -d " " -f "$2")
    if [[ "$1" == $tok ]]; then
        #echo "\"$tok\" == \"$1\" passed! running cmd..."
        #echo "$1: echo \"$line\" | $3"
        echo "$line" | $3
        return $?
    fi
    return 0
}

#### Command Parsers

nothingf() { # ignore command
    return 0;
}

nothingt() { # ignore command
    return 1;
}

pass() { # link-local PASS, throw it out as it's sensinfo
    local pw=$(cat | cut -d " " -f 2 | cut -d $(echo -ne "\r") -f 1)
    local tgtpw=":$(<pass.txt)"
    if [[ "$pw" != "$tgtpw" ]]; then
        secho "ERROR :Closing Link (Link denied (Authentication failed))"
        return 1;
    fi
    return 1;
}

pong1() { # link-local PINGs
    secho "PONG $(cat | cut -d " " -f 2)"
    return 1;
}

pong2() { # remote PINGs, usually
    local stdin=$(cat)
    local src=$(echo -n $stdin | cut -d " " -f 1 | cut -d ":" -f 2)
    # note: respond to invalid (not facing us directly) pings anyway - god forbid you make this server an INBETWEEN link
    secho ":$sname PONG $src :$sname"
    return 1;
}

version() {
    local stdin=$(cat)
    local src=$(echo -n $stdin | cut -d " " -f 1 | cut -d ":" -f 2)
    local dst=$(echo -n $stdin | cut -d " " -f 3)
    if [[ $dst == $sname || $dst == $sid ]]; then
      secho ":${sname} 351 $src pissleakd-1.0.0. ${sname} :[$(uname -a)]"
      secho ":${sname} 105 $src NOTHING :is supported by this server"
    fi
    return 1;
}

#### The MEAT

parser() {
    line="$1"
    #scase "EOS" 2 nothingt; if [[ $? != 0 ]]; then return 1; fi # TODO speedup synch parsing
    # level 1 (cmd) commands
    scase "PASS" 1 pass; if [[ $? != 0 ]]; then return 1; fi
    scase "PING" 1 pong1; if [[ $? != 0 ]]; then return 1; fi
    # level 2 (:src cmd :payload) commands
    scase "NOTICE" 2 nothingt; if [[ $? != 0 ]]; then return 1; fi
    scase "PING" 2 pong2; if [[ $? != 0 ]]; then return 1; fi
    scase "PONG" 2 nothingt; if [[ $? != 0 ]]; then return 1; fi
    scase "PRIVMSG" 2 nothingt; if [[ $? != 0 ]]; then return 1; fi
    scase "VERSION" 2 version; if [[ $? != 0 ]]; then return 1; fi
    return 0
}

test() { # put your tests here
  #echo ":baseduser.eu.org PING ${sname} :baseduser.eu.org" | scase "PING" 2 null # garbage, ghhhhh
  #line=":baseduser.eu.org PING ${sname} :baseduser.eu.org"
  #scase "PING" 2 pong

  line="PASS :foo"
  parser "$line"
  echo $?
}

#uncomment if debug=1
#test
#exit

mkfifo /tmp/$$_0 /tmp/$$_1 /tmp/$$_2

interr() {
  cleanup
  echo -e "\nSIGINT caught"
  exit
}

trap interr SIGINT

runner() {
  ((sleep 0.5s; hello; cat /tmp/$$_0) & cat) | openssl s_client -connect [225:2bee:df65:4647:eade:ebfb:7472:c159]:6900 | while read line; do
    out=$(parser "$line")
    handled=$?
    prefix=""
    suffix=""
    if [[ $handled == 1 ]]; then
      prefix=$(echo -ne "\e[32m") # green
      suffix=$(echo -ne "\e[37m")
    else
      prefix=$(echo -ne "\e[31m") # red
      suffix=$(echo -ne "\e[37m")
    fi
    echo "${prefix}${line}${suffix}";
    if [[ $out != "" ]]; then
      echo "$out";
    fi
  done
}

#### Services

sleep 3652425d > /tmp/$$_0 & # for some wild fucking reason this has to be done for the pipe to not die?? have fun for the next 10000y

(sleep 40s; secho "PING :9RD") & # sanity check our connection

runner
