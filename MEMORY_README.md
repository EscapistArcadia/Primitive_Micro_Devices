This is a comprehensive yet provisional guide of how to build the load/store modules for OOO CP3, everything is subjective to change

--Reservation Station
    Dispatch is supposed to issue a entry, consisting of valid, 3 bit funct3, rs1 renamed, 32 bit rs1 data / rs1 robid, rs2 renamed, 32 bit rs2 data / rs2 robid, 12 bit imm
    Each entry should listen to the incoming CDB broadcast and resolve rs1 and rs2 dependency accordingly
    Once dependencies are resolved, the entry for a load instruction should send a read request to mm cache, and upon a response it will put the data into CDB
    If the entry is a store instruction, 

