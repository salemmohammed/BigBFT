------------------------------- MODULE BigBFT -------------------------------
(*********************************************************************************)
(* This is a specification of BigBFT algorithm.                                  *)
(*********************************************************************************)

EXTENDS Integers, Sequences, FiniteSets, TLC

CONSTANT MaxSlot, F, MaxBallot, MAXROUND

N == ( 3 * F ) + 1
Leader == 0..N-1

(*********************************************************************************)
(* Ballot and Slot definition                                                    *)
(*********************************************************************************)

Slots == 0..MaxSlot
Ballot == 0..MaxBallot
rounds == 0..MAXROUND

ASSUME ConstantAssumption == /\ N \in Nat 
                             /\ F \in Nat
                             /\ F > 0
(* 
 --algorithm BigBFT
 { 
   variable Assig={},Propose={},s1=0,Voting={}, 
            Msgs=[n \in Leader |-> {[chain|-> <<0>>, round |-> 0, sender|->0],
                                    [chain|-> <<0>>, round |-> 0, sender|->1]}];
            
  define{
   VotingMsg(t,s)    == {m \in Voting: (m.type=t) /\ (m.slot=s)}
   ExtractMsg(r,s) == CHOOSE m \in Msgs[s]: m.round=r
   FindMaxChain(s) == CHOOSE z \in {m.chain: m \in Msgs[s]}:
             ~(\E x \in {m.chain: m \in Msgs[s]}: Len(x)>Len(z))
   }   
 (*****************************************************************************)
 (* SendAssignment is where a coordinator sends assigned slots to leaders     *)
 (*****************************************************************************)    

  macro SendAssignment(r,sh)
 {
    await(r>=MaxR);
    MaxR:=r;
    Assig := Assig \union {[type  |-> "1a", round |-> r, Shards |-> sh]};
 }
 
 (***************************************************************************)
 (* A propose phase                                                         *)
 (***************************************************************************)  

  macro SendPhase1Msg(id,b,r,s,v)
  {
  await(\E m \in Assig: m.round=r /\ m.Shards[id]#-1 /\ m.Shards[id]=s);
   Propose:=Propose \union {[type |->"2a", slot|->s, leader |-> id, Value |-> v, bal|->b ]};
  }

 (***************************************************************************)
 (* A vote phase                                                            *)
 (***************************************************************************) 
 
  macro Vote(id,s,b,r)
  {
  await((\E m \in Propose: m.slot=s /\ m.bal=b));
   Voting:=Voting \union {[type |->"2b", FromLdr|->id, slot|->s]};
  }
 
 (***************************************************************************)
 (* Commit                                                                  *)
 (***************************************************************************) 
   macro Commit(s,id,r) 
   { 
     if (Cardinality(VotingMsg("2b",s)) * 2 >= Cardinality(Leader)){
        
        with (m \in VotingMsg("2b",s)){
          CSlot[m.slot]:= CSlot[m.slot] \union {s};
        }; 
     }
   }
   
   macro FindLastCommit(r) {
   if (2*Cardinality ({m\in Msgs[self]: m.round=r /\ m.chain=FindMaxChain(self)}) >= N)
     nChain:= FindMaxChain(self);
   else 
     nChain:= Tail(FindMaxChain(self)); 
   }
   
 (***************************************************************************)
 (* Normal case operation for non-byzantine behaviour                       *)
 (***************************************************************************)
\* \* Leader process
   fair process (l \in Leader)
   variable r=0, s=0, b=0,MaxR=0,total_slots=0,v=0,total_leaders=0,Q={},
            Shard=[i \in Leader |-> -1],CSlot=[i \in Slots |-> {}],nChain= <<>>;
   {
   \* run until maximum rounds are reached
A:   while (r<MAXROUND){
           total_slots:=0;
           total_leaders := N;
           if(self=r){
           
           FindLastCommit(r-1);
           
           Q:=Leader;
Ch:        while (Q #{}){
            with (p \in Q){
             Msgs[p]:= Msgs[p] \union {[chain|-> <<r>> \o nChain, round |-> r, sender|->self]};
             Q:=Q\{p};
             }
            };
             \*Shard:=[i \in Leader |-> -1];
AA:          while (s1 \in Slots /\ total_leaders > 0){
               Shard[s1%N]:= s1;
               total_leaders:=total_leaders-1;
               s1:=s1+1;
             };
             SendAssignment(r,Shard);
            };        
DS:         while (s \in Slots /\ total_slots < N){
             total_slots:=total_slots+1;
\* phase one propose the value
            if(self=s%N){
               v:=self+10;
               SendPhase1Msg(s%N,b,r,s,v);
              };
\* phase two vote on the value.
            Vote(self,s,b,r);
            \*Msgs[self]:= Msgs[self] \union {[chain|->ExtractMsg(r,self).chain, round|->r, sender|->self]};
\* Commit the value.
            Commit(s,self,r);
            s:=s+1;
            b:=b+1;
            };
NxC:      r:=r+1;
     };
    }
   }
 *)
\* BEGIN TRANSLATION - the hash of the PCal code: PCal-64886943a1bac6483708ed417cb5d194
VARIABLES Assig, Propose, s1, Voting, Msgs, pc

(* define statement *)
VotingMsg(t,s)    == {m \in Voting: (m.type=t) /\ (m.slot=s)}
ExtractMsg(r,s) == CHOOSE m \in Msgs[s]: m.round=r
FindMaxChain(s) == CHOOSE z \in {m.chain: m \in Msgs[s]}:
          ~(\E x \in {m.chain: m \in Msgs[s]}: Len(x)>Len(z))

VARIABLES r, s, b, MaxR, total_slots, v, total_leaders, Q, Shard, CSlot, 
          nChain

vars == << Assig, Propose, s1, Voting, Msgs, pc, r, s, b, MaxR, total_slots, 
           v, total_leaders, Q, Shard, CSlot, nChain >>

ProcSet == (Leader)

Init == (* Global variables *)
        /\ Assig = {}
        /\ Propose = {}
        /\ s1 = 0
        /\ Voting = {}
        /\ Msgs = [n \in Leader |-> {[chain|-> <<0>>, round |-> 0, sender|->0],
                                     [chain|-> <<0>>, round |-> 0, sender|->1]}]
        (* Process l *)
        /\ r = [self \in Leader |-> 0]
        /\ s = [self \in Leader |-> 0]
        /\ b = [self \in Leader |-> 0]
        /\ MaxR = [self \in Leader |-> 0]
        /\ total_slots = [self \in Leader |-> 0]
        /\ v = [self \in Leader |-> 0]
        /\ total_leaders = [self \in Leader |-> 0]
        /\ Q = [self \in Leader |-> {}]
        /\ Shard = [self \in Leader |-> [i \in Leader |-> -1]]
        /\ CSlot = [self \in Leader |-> [i \in Slots |-> {}]]
        /\ nChain = [self \in Leader |-> <<>>]
        /\ pc = [self \in ProcSet |-> "A"]

A(self) == /\ pc[self] = "A"
           /\ IF r[self]<MAXROUND
                 THEN /\ total_slots' = [total_slots EXCEPT ![self] = 0]
                      /\ total_leaders' = [total_leaders EXCEPT ![self] = N]
                      /\ IF self=r[self]
                            THEN /\ IF 2*Cardinality ({m\in Msgs[self]: m.round=(r[self]-1) /\ m.chain=FindMaxChain(self)}) >= N
                                       THEN /\ nChain' = [nChain EXCEPT ![self] = FindMaxChain(self)]
                                       ELSE /\ nChain' = [nChain EXCEPT ![self] = Tail(FindMaxChain(self))]
                                 /\ Q' = [Q EXCEPT ![self] = Leader]
                                 /\ pc' = [pc EXCEPT ![self] = "Ch"]
                            ELSE /\ pc' = [pc EXCEPT ![self] = "DS"]
                                 /\ UNCHANGED << Q, nChain >>
                 ELSE /\ pc' = [pc EXCEPT ![self] = "Done"]
                      /\ UNCHANGED << total_slots, total_leaders, Q, nChain >>
           /\ UNCHANGED << Assig, Propose, s1, Voting, Msgs, r, s, b, MaxR, v, 
                           Shard, CSlot >>

DS(self) == /\ pc[self] = "DS"
            /\ IF s[self] \in Slots /\ total_slots[self] < N
                  THEN /\ total_slots' = [total_slots EXCEPT ![self] = total_slots[self]+1]
                       /\ IF self=s[self]%N
                             THEN /\ v' = [v EXCEPT ![self] = self+10]
                                  /\ (\E m \in Assig: m.round=r[self] /\ m.Shards[(s[self]%N)]#-1 /\ m.Shards[(s[self]%N)]=s[self])
                                  /\ Propose' = (Propose \union {[type |->"2a", slot|->s[self], leader |-> (s[self]%N), Value |-> v'[self], bal|->b[self] ]})
                             ELSE /\ TRUE
                                  /\ UNCHANGED << Propose, v >>
                       /\ ((\E m \in Propose': m.slot=s[self] /\ m.bal=b[self]))
                       /\ Voting' = (Voting \union {[type |->"2b", FromLdr|->self, slot|->s[self]]})
                       /\ IF Cardinality(VotingMsg("2b",s[self])) * 2 >= Cardinality(Leader)
                             THEN /\ \E m \in VotingMsg("2b",s[self]):
                                       CSlot' = [CSlot EXCEPT ![self][m.slot] = CSlot[self][m.slot] \union {s[self]}]
                             ELSE /\ TRUE
                                  /\ CSlot' = CSlot
                       /\ s' = [s EXCEPT ![self] = s[self]+1]
                       /\ b' = [b EXCEPT ![self] = b[self]+1]
                       /\ pc' = [pc EXCEPT ![self] = "DS"]
                  ELSE /\ pc' = [pc EXCEPT ![self] = "NxC"]
                       /\ UNCHANGED << Propose, Voting, s, b, total_slots, v, 
                                       CSlot >>
            /\ UNCHANGED << Assig, s1, Msgs, r, MaxR, total_leaders, Q, Shard, 
                            nChain >>

NxC(self) == /\ pc[self] = "NxC"
             /\ r' = [r EXCEPT ![self] = r[self]+1]
             /\ pc' = [pc EXCEPT ![self] = "A"]
             /\ UNCHANGED << Assig, Propose, s1, Voting, Msgs, s, b, MaxR, 
                             total_slots, v, total_leaders, Q, Shard, CSlot, 
                             nChain >>

Ch(self) == /\ pc[self] = "Ch"
            /\ IF Q[self] #{}
                  THEN /\ \E p \in Q[self]:
                            /\ Msgs' = [Msgs EXCEPT ![p] = Msgs[p] \union {[chain|-> <<r[self]>> \o nChain[self], round |-> r[self], sender|->self]}]
                            /\ Q' = [Q EXCEPT ![self] = Q[self]\{p}]
                       /\ pc' = [pc EXCEPT ![self] = "Ch"]
                  ELSE /\ pc' = [pc EXCEPT ![self] = "AA"]
                       /\ UNCHANGED << Msgs, Q >>
            /\ UNCHANGED << Assig, Propose, s1, Voting, r, s, b, MaxR, 
                            total_slots, v, total_leaders, Shard, CSlot, 
                            nChain >>

AA(self) == /\ pc[self] = "AA"
            /\ IF s1 \in Slots /\ total_leaders[self] > 0
                  THEN /\ Shard' = [Shard EXCEPT ![self][s1%N] = s1]
                       /\ total_leaders' = [total_leaders EXCEPT ![self] = total_leaders[self]-1]
                       /\ s1' = s1+1
                       /\ pc' = [pc EXCEPT ![self] = "AA"]
                       /\ UNCHANGED << Assig, MaxR >>
                  ELSE /\ (r[self]>=MaxR[self])
                       /\ MaxR' = [MaxR EXCEPT ![self] = r[self]]
                       /\ Assig' = (Assig \union {[type  |-> "1a", round |-> r[self], Shards |-> Shard[self]]})
                       /\ pc' = [pc EXCEPT ![self] = "DS"]
                       /\ UNCHANGED << s1, total_leaders, Shard >>
            /\ UNCHANGED << Propose, Voting, Msgs, r, s, b, total_slots, v, Q, 
                            CSlot, nChain >>

l(self) == A(self) \/ DS(self) \/ NxC(self) \/ Ch(self) \/ AA(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Leader: l(self))
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in Leader : WF_vars(l(self))

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION - the hash of the generated TLA code (remove to silence divergence warnings): TLA-531a98c5daa4687ae509fbda8db3bb17
Safety == (\A a \in Leader: 
          \A bb \in 0..MaxSlot: Cardinality(CSlot[a][bb]) <= 1) 

Safety1 == \A a \in Leader: s[a]<9
\*Safety == \A a \in Leader: s[a]<7 
=============================================================================
\* Modification History
\* Last modified Sun Feb 07 19:56:43 EST 2021 by salemalqahtani
\* Created Fri Jan 15 17:43:11 EST 2021 by salemalqahtani
