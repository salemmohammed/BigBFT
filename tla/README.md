-BigBFT in TLA+

A PlusCal specification of BigBFT consensus protocol.

Variables:

- Assig: A set the assignment phase messages
- Propose: A set of the propose phase messages
- Voting: A set of the voting phase messages
- QC: Quorum certificate
- s1: Slots counter
- N denotes the number of Leaders
- F denotes the maximum number of nodes that may fail
- MAXROUND: number of rounds

