------------------------------- MODULE BigBFT -------------------------------
(*********************************************************************************)
(* VERSION 1.0                                                                   *)
(* This module is a specification for BigBFT algorithm.                          *)
(* AUTHORS = " Salem Alqahtani and Murat Demirbas                                *)
(*********************************************************************************)
 
EXTENDS Integers, Sequences, FiniteSets, TLC

CONSTANT MaxSlot, F, MaxBallot, MAXROUND

N == ( 3 * F ) + 1
Leader == 0..N-1

(*********************************************************************************)
(* Ballot and Slot definition                                                    *)
(*********************************************************************************)


Slots  == 0..MaxSlot
Ballot == 0..MaxBallot
rounds == 0..MAXROUND

ASSUME ConstantAssumption == /\ N \in Nat 
                             /\ F \in Nat
                             /\ F > 0
(* 
 --algorithm BigBFT
 { 
   variable Assig={},Propose={},s1=0,Voting={},QC={};

  define{
   Sent2bVoting(s) ==  {m \in Voting: m[2]=s}
   ProposeProof(r) ==  {m \in QC: m[2]=r}
   }

 (*****************************************************************************)
 (* SendAssignment is where a coordinator sends assigned slots to leaders     *)
 (*****************************************************************************)    

  macro SendNewRound(r,sh)
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
    await(\E m \in Assig: m.round=r /\ m.Shards[id] # -1 /\ m.Shards[id]=s);    
   \* Proof 
   if ( Cardinality(ProposeProof(r-1))>= N-F \/ r = 0){
        Propose:=Propose \union {<<id, s, r, v,"2a">>}; \* bcast v type 2a with b for s in r
   };
  }

 (***************************************************************************)
 (* A vote phase                                                            *)
 (***************************************************************************) 
 
  macro Vote(id,s,b,r)
  {
    await (\E m \in Propose: m[2]=s /\ m[3]=r );
    Voting:=Voting \union {<<id, s, r, "2b">>}; \* bcast 2b for s in r
    QC:= QC \union {<<s, r>>};
   \* Commit 
   if ( Cardinality(Sent2bVoting(s))>= N-F ){
        CSlot[s]:= CSlot[s] \union {s};
     };
  }
 
 (***************************************************************************)
 (* The normal case operation for each leader process                       *)
 (***************************************************************************)
\* \* Leader process
   fair process (l \in Leader)
   variable r=0, s=0, b=0,MaxR=0,total_slots=0,v=0,total_leaders=0,
            Shard=[i \in Leader |-> -1],CSlot=[i \in Slots |-> {}];
   {
   \* run until maximum rounds are reached
A:   while (r<MAXROUND){
           total_slots:=0;
           total_leaders := N;
           if(self=r){
AA:          while (s1 \in Slots /\ total_leaders > 0){
               Shard[s1%N]:= s1;
               total_leaders:=total_leaders-1;
               s1:=s1+1;
             };
             SendNewRound(r,Shard);
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
            s:=s+1;
            b:=b+1;
            };
NxC:      r:=r+1;
     };
    }
   }
 *)
\* BEGIN TRANSLATION - the hash of the PCal code: PCal-355d5df2440770301bec267e7bd02c56 (chksum(pcal) = "a81773c0" /\ chksum(tla) = "20754ae") (chksum(pcal) = "a81773c0" /\ chksum(tla) = "20754ae") (chksum(pcal) = "a81773c0" /\ chksum(tla) = "20754ae") (chksum(pcal) = "a81773c0" /\ chksum(tla) = "20754ae") (chksum(pcal) = "489bce38" /\ chksum(tla) = "61424ea8") (chksum(pcal) = "6a918442" /\ chksum(tla) = "5f28c608") (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) = "6a918442" /\ chksum(tla) = "5f28c608") (chksum(pcal) = "6a918442" /\ chksum(tla) = "5f28c608") (chksum(pcal) = "c6c58045" /\ chksum(tla) = "40362121") (chksum(pcal) = "95b1296b" /\ chksum(tla) = "ecbeb89a") (chksum(pcal) = "d3e8d6ce" /\ chksum(tla) = "20e3ef5b") (chksum(pcal) = "5f0ab1d6" /\ chksum(tla) = "951759f7") (chksum(pcal) = "905fc96" /\ chksum(tla) = "2a733b1a") (chksum(pcal) = "e9df0bea" /\ chksum(tla) = "c5c57e43") (chksum(pcal) = "49d89beb" /\ chksum(tla) = "83aa86ef") (chksum(pcal) = "d4d6b626" /\ chksum(tla) = "638d1f8d") (chksum(pcal) = "670c5e37" /\ chksum(tla) = "78b0a582") (chksum(pcal) = "cdd4dde1" /\ chksum(tla) = "257890b8") (chksum(pcal) = "48edc5f2" /\ chksum(tla) = "b5a4bf86") (chksum(pcal) = "e7382914" /\ chksum(tla) = "866c448b") (chksum(pcal) = "910c5478" /\ chksum(tla) = "c912a8d3") (chksum(pcal) = "a82fcfb0" /\ chksum(tla) = "2657dee8") (chksum(pcal) = "f3705a42" /\ chksum(tla) = "fe6f203") (chksum(pcal) = "21872dcb" /\ chksum(tla) = "422d5e86") (chksum(pcal) = "fbb6aa02" /\ chksum(tla) = "bf743ee5") (chksum(pcal) = "df33f37c" /\ chksum(tla) = "a6f336e1") (chksum(pcal) = "df33f37c" /\ chksum(tla) = "a6f336e1") (chksum(pcal) = "1f0d1f14" /\ chksum(tla) = "8a74b6ee") (chksum(pcal) = "8869c46f" /\ chksum(tla) = "62e64f4f") (chksum(pcal) = "58dd2c55" /\ chksum(tla) = "40f85290") (chksum(pcal) = "58d962ef" /\ chksum(tla) = "240d0019") (chksum(pcal) = "df65c127" /\ chksum(tla) = "8bd25674") (chksum(pcal) = "98972c33" /\ chksum(tla) = "c0f6d07a") (chksum(pcal) = "58dd2c55" /\ chksum(tla) = "40f85290") (chksum(pcal) = "df65c127" /\ chksum(tla) = "8bd25674") (chksum(pcal) = "61949323" /\ chksum(tla) = "6b2a72e9") (chksum(pcal) = "98972c33" /\ chksum(tla) = "c0f6d07a") (chksum(pcal) = "fa2832fa" /\ chksum(tla) = "11508a29") (chksum(pcal) = "cef9bc2b" /\ chksum(tla) = "9a107945") (chksum(pcal) = "eccca233" /\ chksum(tla) = "4d2ff92e") (chksum(pcal) = "adb55e9e" /\ chksum(tla) = "12da2ef6") (chksum(pcal) = "debf89e6" /\ chksum(tla) = "8acd606") (chksum(pcal) = "b2a04ef4" /\ chksum(tla) = "b0291ea6") (chksum(pcal) = "7ed038b0" /\ chksum(tla) = "fbe3e78b") (chksum(pcal) = "702ba8b3" /\ chksum(tla) = "2f589c47") (chksum(pcal) = "702ba8b3" /\ chksum(tla) = "2f589c47") (chksum(pcal) = "702ba8b3" /\ chksum(tla) = "2f589c47") (chksum(pcal) = "b4f181eb" /\ chksum(tla) = "4dcddfc") (chksum(pcal) = "7d5203c1" /\ chksum(tla) = "a56acce8") (chksum(pcal) = "378b2ad3" /\ chksum(tla) = "a002b854") (chksum(pcal) = "2cfa9238" /\ chksum(tla) = "36aa2a64") (chksum(pcal) = "27610901" /\ chksum(tla) = "62b0f1bb") (chksum(pcal) = "3f16feee" /\ chksum(tla) = "1f57721c") (chksum(pcal) = "3f16feee" /\ chksum(tla) = "1f57721c") (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING) (chksum(pcal) \in STRING /\ chksum(tla) \in STRING)
VARIABLES Assig, Propose, s1, Voting, QC, pc

(* define statement *)
Sent2bVoting(s) ==  {m \in Voting: m[2]=s}
ProposeProof(r) ==  {m \in QC: m[2]=r}

VARIABLES r, s, b, MaxR, total_slots, v, total_leaders, Shard, CSlot

vars == << Assig, Propose, s1, Voting, QC, pc, r, s, b, MaxR, total_slots, v, 
           total_leaders, Shard, CSlot >>

ProcSet == (Leader)

Init == (* Global variables *)
        /\ Assig = {}
        /\ Propose = {}
        /\ s1 = 0
        /\ Voting = {}
        /\ QC = {}
        (* Process l *)
        /\ r = [self \in Leader |-> 0]
        /\ s = [self \in Leader |-> 0]
        /\ b = [self \in Leader |-> 0]
        /\ MaxR = [self \in Leader |-> 0]
        /\ total_slots = [self \in Leader |-> 0]
        /\ v = [self \in Leader |-> 0]
        /\ total_leaders = [self \in Leader |-> 0]
        /\ Shard = [self \in Leader |-> [i \in Leader |-> -1]]
        /\ CSlot = [self \in Leader |-> [i \in Slots |-> {}]]
        /\ pc = [self \in ProcSet |-> "A"]

A(self) == /\ pc[self] = "A"
           /\ IF r[self]<MAXROUND
                 THEN /\ total_slots' = [total_slots EXCEPT ![self] = 0]
                      /\ total_leaders' = [total_leaders EXCEPT ![self] = N]
                      /\ IF self=r[self]
                            THEN /\ pc' = [pc EXCEPT ![self] = "AA"]
                            ELSE /\ pc' = [pc EXCEPT ![self] = "DS"]
                 ELSE /\ pc' = [pc EXCEPT ![self] = "Done"]
                      /\ UNCHANGED << total_slots, total_leaders >>
           /\ UNCHANGED << Assig, Propose, s1, Voting, QC, r, s, b, MaxR, v, 
                           Shard, CSlot >>

DS(self) == /\ pc[self] = "DS"
            /\ IF s[self] \in Slots /\ total_slots[self] < N
                  THEN /\ total_slots' = [total_slots EXCEPT ![self] = total_slots[self]+1]
                       /\ IF self=s[self]%N
                             THEN /\ v' = [v EXCEPT ![self] = self+10]
                                  /\ (\E m \in Assig: m.round=r[self] /\ m.Shards[(s[self]%N)] # -1 /\ m.Shards[(s[self]%N)]=s[self])
                                  /\ IF Cardinality(ProposeProof(r[self]-1))>= N-F \/ r[self] = 0
                                        THEN /\ Propose' = (Propose \union {<<(s[self]%N), s[self], r[self], v'[self],"2a">>})
                                        ELSE /\ TRUE
                                             /\ UNCHANGED Propose
                             ELSE /\ TRUE
                                  /\ UNCHANGED << Propose, v >>
                       /\ (\E m \in Propose': m[2]=s[self] /\ m[3]=r[self] )
                       /\ Voting' = (Voting \union {<<self, s[self], r[self], "2b">>})
                       /\ QC' = (QC \union {<<s[self], r[self]>>})
                       /\ IF Cardinality(Sent2bVoting(s[self]))>= N-F
                             THEN /\ CSlot' = [CSlot EXCEPT ![self][s[self]] = CSlot[self][s[self]] \union {s[self]}]
                             ELSE /\ TRUE
                                  /\ CSlot' = CSlot
                       /\ s' = [s EXCEPT ![self] = s[self]+1]
                       /\ b' = [b EXCEPT ![self] = b[self]+1]
                       /\ pc' = [pc EXCEPT ![self] = "DS"]
                  ELSE /\ pc' = [pc EXCEPT ![self] = "NxC"]
                       /\ UNCHANGED << Propose, Voting, QC, s, b, total_slots, 
                                       v, CSlot >>
            /\ UNCHANGED << Assig, s1, r, MaxR, total_leaders, Shard >>

NxC(self) == /\ pc[self] = "NxC"
             /\ r' = [r EXCEPT ![self] = r[self]+1]
             /\ pc' = [pc EXCEPT ![self] = "A"]
             /\ UNCHANGED << Assig, Propose, s1, Voting, QC, s, b, MaxR, 
                             total_slots, v, total_leaders, Shard, CSlot >>

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
            /\ UNCHANGED << Propose, Voting, QC, r, s, b, total_slots, v, 
                            CSlot >>

l(self) == A(self) \/ DS(self) \/ NxC(self) \/ AA(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Leader: l(self))
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in Leader : WF_vars(l(self))

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION - the hash of the generated TLA code (remove to silence divergence warnings): TLA-c62ee608d0a0181a7a69077a4ed3066a

\* If 2 correct leaders decide, they decide the same thing.  
Agreement == (\A a \in Leader: 
          \A bb \in 0..MaxSlot: Cardinality(CSlot[a][bb]) <= 1) 

\* At round r, before every leader propose a new value, 
\* leaders check if r-1 round collected N-F votes for previous proposal value.  
Safety ==  (\A rr \in 0..MAXROUND-1: (
                                     \/ (Cardinality(ProposeProof(0)) >= 0) \* inital state when rr-1 = 0
                                     \/ (2* Cardinality(ProposeProof(rr-1)) >= N-F) \* checking a round r-1 when proposing in round r 
                                    ))
          
Safety1 == \A a \in Leader: s[a]<9
\*Safety == \A a \in Leader: s[a]<7 
=============================================================================
\* Modification History
\* Last modified Sun Feb 21 19:43:51 EST 2021 by salemalqahtani
\* Created Fri Jan 15 17:43:11 EST 2021 by salemalqahtani
