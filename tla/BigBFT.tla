------------------------------- MODULE BigBFT -------------------------------
(* A specification of BigBFT. *)
EXTENDS Integers, Sequences, FiniteSets, TLC, Naturals
(* MaxSlot is the set of slots. *)  
(* F is the number of failure nodes. *)
(* MAXROUND is the maximum number of rounds. *)
CONSTANT MaxSlot, F, MAXROUND
(* definitions *)
Slots     == 0..MaxSlot
Rounds    == 0..MAXROUND
N         == ( 3 * F ) + 1 \* all processes
Leaders   == 0..N-1

ASSUME N \in Nat /\ F \in Nat /\ F >= 1
(* All possible protocol messages *)
Messages ==
[type:{"A"}, round:Rounds, slot:Slots, leader:Leaders, Coordinator:Leaders]
\cup [type:{"P"}, round:Rounds, slot:Slots, leader:Leaders, Coordinator:Leaders]
\cup [type:{"C"}, round:Rounds, slot:Slots, leader:Leaders, voter:Leaders, proposer:Leaders]
  
(* 
 --algorithm BigBFT
 { 
   variable 
            msgsAssign={},    \* assign messages broadcast to the system
            msgsPropose={},   \* propose messages broadcast to the system
            msgsVote={},      \* vote messages broadcast to the system
            log=[i \in Rounds |-> [l \in Leaders |-> [v |-> <<>>, commit |-> FALSE]]];
            
  define{
   \* rnd is the round number
   Commit_Round(rnd)      ==  {m1 \in msgsVote: m1.round = rnd}
   Increse_slot(slt,rnd)  ==  {m2 \in msgsVote: m2.slot= slt /\ m2.round = rnd}
   Increse_round(rnd)     ==  {m2 \in msgsVote: m2.round = rnd}
  }
 (* Start is where a coordinator sends assigned slots to leaders *)
  macro Start(round,slot,self)
 {  
    when ~ \E m \in msgsAssign : m.round = round /\ m.slot = slot;
    msgsAssign := msgsAssign \union {[type |-> "A", 
                                     round |-> round,
                                     slot  |-> slot,
                                     leader|-> slot,
                                Coordinator|-> self]
                                    };
 }
 (* Proposing phase *)
  macro Propose(slot,value,self)
 {      
     with(m \in msgsAssign){
      when self = m.leader /\ slot = m.slot;
      when log[m.round][m.slot].v = <<>>;
      log[m.round][self].v := <<value>>; 
      msgsPropose := msgsPropose \union {[  type |-> "P",
                                           round |-> m.round, 
                                            slot |-> slot, 
                                          leader |-> self,
                                      Coordinator|-> m.Coordinator]
                                        };
    };
 }
 (* Voting and Commiting phase *)
  macro Vote(round,self,slot)
 {
      with(m \in msgsPropose){       
       when ~ \E m1 \in msgsVote : m1.round = round 
                                  /\ m1.voter=self 
                                  /\ m1.proposer = m.leader;
       when m.slot=slot /\ m.round=round;
       msgsVote := msgsVote \union {[  type |-> "C", 
                                      round |-> round, 
                                       slot |-> slot, 
                                      voter |-> self,
                                   proposer |-> m.leader]
                                   };
      };
      
      (* commit a previous round or the maximum round*)
      if( /\  round = MAXROUND
          /\  log[MAXROUND][self].v # <<>> 
          /\  Cardinality(Commit_Round(MAXROUND)) >= (N-F)*N )
      {
        log[MAXROUND][self].commit := TRUE;
      }else{
          if( /\ round > 0
              /\ (Cardinality(Commit_Round(round-1)) >= (N-F)*N ) 
              /\ log[round-1][self].v # <<>>)
          {
            log[round-1][self].commit := TRUE;
          };
      };
 }
  
  macro IncSlot(slot,round)
 {
    if(Cardinality(Increse_slot(slot,round)) >= N-F ){
      slot:=slot+1;
    };
 }
 
  macro IncRound(round)
 {
    if(Cardinality(Increse_round(round)) >= (N)*(N) ){
      round:=round+1;
    };
 }
 (* The normal case operation for each leader process *)
\* \* Leader process
   fair process (l \in Leaders)
   variable round=0,slot=0,value=self;
   { 
P1:   while(round \in Rounds){
       slot:=0;
P2:    while(slot \in Slots){
        either{ 
            if(self=round){
              Start(round,slot,self);
            };
        };
        or  Propose(slot,value,self);
        or  Vote(round,self,slot);
P3:     IncSlot(slot,round);
       };
       \* waiting for r to get enough votes
P4:    IncRound(round); 
      };
   }
}
 *)
\* BEGIN TRANSLATION - the hash of the PCal code:   (chksum(pcal) = "b1186e6d" /\ chksum(tla) = "5f636618") (chksum(pcal) = "f6ead070" /\ chksum(tla) = "9eb5898a") (chksum(pcal) = "f6ead070" /\ chksum(tla) = "9eb5898a") (chksum(pcal) = "f6ead070" /\ chksum(tla) = "9eb5898a") (chksum(pcal) = "c796ea64" /\ chksum(tla) = "b844b5b8") (chksum(pcal) = "5996c819" /\ chksum(tla) = "1df020d6") (chksum(pcal) = "5996c819" /\ chksum(tla) = "1df020d6") (chksum(pcal) = "c796ea64" /\ chksum(tla) = "b844b5b8") (chksum(pcal) = "3b06bddb" /\ chksum(tla) = "714e5f46") (chksum(pcal) = "e1e69152" /\ chksum(tla) = "d8b14bbf") (chksum(pcal) = "5996c819" /\ chksum(tla) = "1df020d6") (chksum(pcal) = "19bb677a" /\ chksum(tla) = "fce5c1bc") (chksum(pcal) = "656a4abc" /\ chksum(tla) = "5f3184b7") (chksum(pcal) = "1a701940" /\ chksum(tla) = "6a5a3070") (chksum(pcal) = "1a701940" /\ chksum(tla) = "6a5a3070") (chksum(pcal) = "1df012bd" /\ chksum(tla) = "60c2451e") (chksum(pcal) = "1df012bd" /\ chksum(tla) = "60c2451e") (chksum(pcal) = "4e5a5157" /\ chksum(tla) = "67739efe") (chksum(pcal) = "4e5a5157" /\ chksum(tla) = "67739efe") (chksum(pcal) = "4e5a5157" /\ chksum(tla) = "67739efe") (chksum(pcal) = "3c0398c6" /\ chksum(tla) = "95a71ddd") (chksum(pcal) = "b5750246" /\ chksum(tla) = "f7e0847f") (chksum(pcal) = "4d278c11" /\ chksum(tla) = "4d58b366") (chksum(pcal) = "4d278c11" /\ chksum(tla) = "4d58b366") (chksum(pcal) = "75751df7" /\ chksum(tla) = "368f7639") (chksum(pcal) = "b8c65972" /\ chksum(tla) = "63198f3e") (chksum(pcal) = "b8c65972" /\ chksum(tla) = "63198f3e") (chksum(pcal) = "292cb7ec" /\ chksum(tla) = "89f3c02d") (chksum(pcal) = "73fe3dd7" /\ chksum(tla) = "503be3d3") (chksum(pcal) = "436f3611" /\ chksum(tla) = "3c8fabb7") (chksum(pcal) = "3a8a294c" /\ chksum(tla) = "bfafa1f") (chksum(pcal) = "436f3611" /\ chksum(tla) = "3c8fabb7") (chksum(pcal) = "436f3611" /\ chksum(tla) = "3c8fabb7") (chksum(pcal) = "7cfaced6" /\ chksum(tla) = "e7dc0f50") (chksum(pcal) = "2b1b70b0" /\ chksum(tla) = "f75f9140") (chksum(pcal) = "a0fbcd7e" /\ chksum(tla) = "2e3652c2") (chksum(pcal) = "c688cda0" /\ chksum(tla) = "e8029c49") (chksum(pcal) = "8e525216" /\ chksum(tla) = "a0885da7") (chksum(pcal) = "3d3eb9a1" /\ chksum(tla) = "a60663b0") (chksum(pcal) = "2cab2e59" /\ chksum(tla) = "cf54f19d") (chksum(pcal) = "a1dcb327" /\ chksum(tla) = "e1c707b8") (chksum(pcal) = "567e40d1" /\ chksum(tla) = "f2b54698") (chksum(pcal) = "567e40d1" /\ chksum(tla) = "bdf8924a") (chksum(pcal) = "567e40d1" /\ chksum(tla) = "7ad05697") (chksum(pcal) = "567e40d1" /\ chksum(tla) = "12c6768e") (chksum(pcal) = "83680eb3" /\ chksum(tla) = "ed0496c7") (chksum(pcal) = "83680eb3" /\ chksum(tla) = "ed0496c7") (chksum(pcal) = "cc215d99" /\ chksum(tla) = "4475f03f") (chksum(pcal) = "cc215d99" /\ chksum(tla) = "4475f03f") (chksum(pcal) = "6486f21" /\ chksum(tla) = "585cd0bb") (chksum(pcal) = "6486f21" /\ chksum(tla) = "585cd0bb") (chksum(pcal) = "4a56fd6e" /\ chksum(tla) = "790fdbb4") (chksum(pcal) = "f338d13c" /\ chksum(tla) = "4713850f") (chksum(pcal) = "ab9c6328" /\ chksum(tla) = "44773249") (chksum(pcal) = "8aea9859" /\ chksum(tla) = "9371a7d2") (chksum(pcal) = "86cbf82a" /\ chksum(tla) = "2d43518f") (chksum(pcal) = "1474b04" /\ chksum(tla) = "4acef09a") (chksum(pcal) = "93931f45" /\ chksum(tla) = "3285fc3b") (chksum(pcal) = "96df8d27" /\ chksum(tla) = "8659e02f") (chksum(pcal) = "f3272b6b" /\ chksum(tla) = "38e07d66") (chksum(pcal) = "96acc87f" /\ chksum(tla) = "82d5fc60") (chksum(pcal) = "96acc87f" /\ chksum(tla) = "82d5fc60") (chksum(pcal) = "8724deae" /\ chksum(tla) = "8811989c") (chksum(pcal) = "10c638ff" /\ chksum(tla) = "b3710657") (chksum(pcal) = "10c638ff" /\ chksum(tla) = "b3710657") (chksum(pcal) = "10c638ff" /\ chksum(tla) = "b3710657") (chksum(pcal) = "10c638ff" /\ chksum(tla) = "b3710657") (chksum(pcal) = "10c638ff" /\ chksum(tla) = "b3710657") (chksum(pcal) = "10c638ff" /\ chksum(tla) = "b3710657") (chksum(pcal) = "23a912f3" /\ chksum(tla) = "addcaa5d") (chksum(pcal) = "23a912f3" /\ chksum(tla) = "addcaa5d") (chksum(pcal) = "a4a641b5" /\ chksum(tla) = "ee7a7c79") (chksum(pcal) = "a4a641b5" /\ chksum(tla) = "ee7a7c79") (chksum(pcal) = "881f9309" /\ chksum(tla) = "9cc4a17e") (chksum(pcal) = "c4ec1411" /\ chksum(tla) = "a817313b") (chksum(pcal) = "c4ec1411" /\ chksum(tla) = "a817313b") (chksum(pcal) = "cdbfe25c" /\ chksum(tla) = "dc274099") (chksum(pcal) = "cdbfe25c" /\ chksum(tla) = "dc274099") (chksum(pcal) = "881f9309" /\ chksum(tla) = "9cc4a17e") (chksum(pcal) = "4c287b69" /\ chksum(tla) = "3d3c08e0") (chksum(pcal) = "37a1ea0a" /\ chksum(tla) = "584dc9dd") (chksum(pcal) = "a203b06c" /\ chksum(tla) = "81cc6755") (chksum(pcal) = "de0164b" /\ chksum(tla) = "bf6e6000") (chksum(pcal) = "de0164b" /\ chksum(tla) = "bf6e6000") (chksum(pcal) = "ba562600" /\ chksum(tla) = "ad087f55") (chksum(pcal) = "ca0abe6d" /\ chksum(tla) = "81ed2d19") (chksum(pcal) = "28e04886" /\ chksum(tla) = "9314e2ce") (chksum(pcal) = "eb740437" /\ chksum(tla) = "9d790c2a") (chksum(pcal) = "bd60f949" /\ chksum(tla) = "ec0a3d03") (chksum(pcal) = "9c73c10e" /\ chksum(tla) = "6026b314") (chksum(pcal) = "163068b1" /\ chksum(tla) = "6844e5c2") (chksum(pcal) = "f3dbb131" /\ chksum(tla) = "db92f1a2") (chksum(pcal) = "163068b1" /\ chksum(tla) = "6844e5c2") (chksum(pcal) = "bed0d739" /\ chksum(tla) = "12f7e8b") (chksum(pcal) = "e8ccd265" /\ chksum(tla) = "2df55904") (chksum(pcal) = "e8ccd265" /\ chksum(tla) = "2df55904") (chksum(pcal) = "bed0d739" /\ chksum(tla) = "12f7e8b") (chksum(pcal) = "3221c631" /\ chksum(tla) = "ebff137e") (chksum(pcal) = "d5e5cb88" /\ chksum(tla) = "86684622") (chksum(pcal) = "76707a74" /\ chksum(tla) = "ca66ada7") (chksum(pcal) = "20a455a3" /\ chksum(tla) = "b196a5e") (chksum(pcal) = "bd1c1212" /\ chksum(tla) = "4e48e4e8") (chksum(pcal) = "eb4f3bdc" /\ chksum(tla) = "fe24aa86") (chksum(pcal) = "eb4f3bdc" /\ chksum(tla) = "fe24aa86") (chksum(pcal) = "eb4f3bdc" /\ chksum(tla) = "fe24aa86") (chksum(pcal) = "bd1c1212" /\ chksum(tla) = "4e48e4e8") (chksum(pcal) = "446ff9f8" /\ chksum(tla) = "f64f6b35") (chksum(pcal) = "abd2c31a" /\ chksum(tla) = "432427c4") (chksum(pcal) = "5ecb1ce0" /\ chksum(tla) = "591cbefc") (chksum(pcal) = "ebadb7aa" /\ chksum(tla) = "1da92f9c") (chksum(pcal) = "ebadb7aa" /\ chksum(tla) = "1da92f9c") (chksum(pcal) = "ebadb7aa" /\ chksum(tla) = "1da92f9c") (chksum(pcal) = "ebadb7aa" /\ chksum(tla) = "1da92f9c") (chksum(pcal) = "ebadb7aa" /\ chksum(tla) = "1da92f9c") (chksum(pcal) = "6981f821" /\ chksum(tla) = "ec3108b9") (chksum(pcal) = "6981f821" /\ chksum(tla) = "ec3108b9") (chksum(pcal) = "9f270685" /\ chksum(tla) = "bfb70407") (chksum(pcal) = "6440fadf" /\ chksum(tla) = "17a47189") (chksum(pcal) = "977d60c5" /\ chksum(tla) = "dc921135") (chksum(pcal) = "c12c6ad3" /\ chksum(tla) = "8234916f") (chksum(pcal) = "64df4962" /\ chksum(tla) = "c4712b45") (chksum(pcal) = "3d68837" /\ chksum(tla) = "201840f3") (chksum(pcal) = "c12c6ad3" /\ chksum(tla) = "8234916f") (chksum(pcal) = "c12c6ad3" /\ chksum(tla) = "8234916f") (chksum(pcal) = "c12c6ad3" /\ chksum(tla) = "8234916f")
VARIABLES msgsAssign, msgsPropose, msgsVote, log, pc

(* define statement *)
Commit_Round(rnd)      ==  {m1 \in msgsVote: m1.round = rnd}
Increse_slot(slt,rnd)  ==  {m2 \in msgsVote: m2.slot= slt /\ m2.round = rnd}
Increse_round(rnd)     ==  {m2 \in msgsVote: m2.round = rnd}

VARIABLES round, slot, value

vars == << msgsAssign, msgsPropose, msgsVote, log, pc, round, slot, value >>

ProcSet == (Leaders)

Init == (* Global variables *)
        /\ msgsAssign = {}
        /\ msgsPropose = {}
        /\ msgsVote = {}
        /\ log = [i \in Rounds |-> [l \in Leaders |-> [v |-> <<>>, commit |-> FALSE]]]
        (* Process l *)
        /\ round = [self \in Leaders |-> 0]
        /\ slot = [self \in Leaders |-> 0]
        /\ value = [self \in Leaders |-> self]
        /\ pc = [self \in ProcSet |-> "P1"]

P1(self) == /\ pc[self] = "P1"
            /\ IF round[self] \in Rounds
                  THEN /\ slot' = [slot EXCEPT ![self] = 0]
                       /\ pc' = [pc EXCEPT ![self] = "P2"]
                  ELSE /\ pc' = [pc EXCEPT ![self] = "Done"]
                       /\ slot' = slot
            /\ UNCHANGED << msgsAssign, msgsPropose, msgsVote, log, round, 
                            value >>

P2(self) == /\ pc[self] = "P2"
            /\ IF slot[self] \in Slots
                  THEN /\ \/ /\ IF self=round[self]
                                   THEN /\ ~ \E m \in msgsAssign : m.round = round[self] /\ m.slot = slot[self]
                                        /\ msgsAssign' = (msgsAssign \union {[type |-> "A",
                                                                             round |-> round[self],
                                                                             slot  |-> slot[self],
                                                                             leader|-> slot[self],
                                                                        Coordinator|-> self]
                                                                            })
                                   ELSE /\ TRUE
                                        /\ UNCHANGED msgsAssign
                             /\ UNCHANGED <<msgsPropose, msgsVote, log>>
                          \/ /\ \E m \in msgsAssign:
                                  /\ self = m.leader /\ slot[self] = m.slot
                                  /\ log[m.round][m.slot].v = <<>>
                                  /\ log' = [log EXCEPT ![m.round][self].v = <<value[self]>>]
                                  /\ msgsPropose' = (msgsPropose \union {[  type |-> "P",
                                                                           round |-> m.round,
                                                                            slot |-> slot[self],
                                                                          leader |-> self,
                                                                      Coordinator|-> m.Coordinator]
                                                                        })
                             /\ UNCHANGED <<msgsAssign, msgsVote>>
                          \/ /\ \E m \in msgsPropose:
                                  /\ ~ \E m1 \in msgsVote : m1.round = round[self]
                                                           /\ m1.voter=self
                                                           /\ m1.proposer = m.leader
                                  /\ m.slot=slot[self] /\ m.round=round[self]
                                  /\ msgsVote' = (msgsVote \union {[  type |-> "C",
                                                                     round |-> round[self],
                                                                      slot |-> slot[self],
                                                                     voter |-> self,
                                                                  proposer |-> m.leader]
                                                                  })
                             /\ IF /\  round[self] = MAXROUND
                                   /\  log[MAXROUND][self].v # <<>>
                                   /\  Cardinality(Commit_Round(MAXROUND)) >= (N-F)*N
                                   THEN /\ log' = [log EXCEPT ![MAXROUND][self].commit = TRUE]
                                   ELSE /\ IF /\ round[self] > 0
                                              /\ (Cardinality(Commit_Round(round[self]-1)) >= (N-F)*N )
                                              /\ log[round[self]-1][self].v # <<>>
                                              THEN /\ log' = [log EXCEPT ![round[self]-1][self].commit = TRUE]
                                              ELSE /\ TRUE
                                                   /\ log' = log
                             /\ UNCHANGED <<msgsAssign, msgsPropose>>
                       /\ pc' = [pc EXCEPT ![self] = "P3"]
                  ELSE /\ pc' = [pc EXCEPT ![self] = "P4"]
                       /\ UNCHANGED << msgsAssign, msgsPropose, msgsVote, log >>
            /\ UNCHANGED << round, slot, value >>

P3(self) == /\ pc[self] = "P3"
            /\ IF Cardinality(Increse_slot(slot[self],round[self])) >= N-F
                  THEN /\ slot' = [slot EXCEPT ![self] = slot[self]+1]
                  ELSE /\ TRUE
                       /\ slot' = slot
            /\ pc' = [pc EXCEPT ![self] = "P2"]
            /\ UNCHANGED << msgsAssign, msgsPropose, msgsVote, log, round, 
                            value >>

P4(self) == /\ pc[self] = "P4"
            /\ IF Cardinality(Increse_round(round[self])) >= (N)*(N)
                  THEN /\ round' = [round EXCEPT ![self] = round[self]+1]
                  ELSE /\ TRUE
                       /\ round' = round
            /\ pc' = [pc EXCEPT ![self] = "P1"]
            /\ UNCHANGED << msgsAssign, msgsPropose, msgsVote, log, slot, 
                            value >>

l(self) == P1(self) \/ P2(self) \/ P3(self) \/ P4(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Leaders: l(self))
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in Leaders : WF_vars(l(self))

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION - the hash of the generated TLA code 
\*(remove to silence divergence warnings): 
\*TLA-c62ee608d0a0181a7a69077a4ed3066a
(* The invariants*)
(* No two correct processes decide differently. *)
Agreement == ( \A rounds \in Rounds, i,j \in ProcSet: 
                                        /\ log[rounds][i].commit = TRUE
                                        /\ log[rounds][j].commit = TRUE
                                        => (log[rounds][i].commit = log[rounds][j].commit))
(* If every processes votes and no process is suspected or crashes. *)    
AllVote  == (Cardinality(msgsVote) <= 32)
(* <> is not working *)
Progress  == (\A i \in Leaders: slot[i] < 5 ) 
=============================================================================
\* Modification History
\* Last modified Tue Mar 23 19:22:11 EDT 2021 by salemalqahtani
\* Created Fri Jan 15 17:43:11 EST 2021 by salemalqahtani
