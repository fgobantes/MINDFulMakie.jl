f,_,_ = MINDFM.ibnplot(ibnfs[1]; multidomain=false)
savefig(f)

f,_,_ = MINDFM.ibnplot(ibnfs[1]; multidomain=false, shownodelabels = :local)
savefig(f)

f,_,_ = MINDFM.ibnplot(ibnfs[1]; multidomain=false, shownodelabels = :global)
savefig(f)

f,_,_ = MINDFM.ibnplot(ibnfs[1]; multidomain=true)
savefig(f)

f,_,_ = MINDFM.ibnplot(ibnfs[1]; multidomain=false, intentuuid=intentuuid_bordernode) 
savefig(f)

f,_,_ = MINDFM.ibnplot(ibnfs[1]; multidomain=false, intentuuid=intentuuid_neigh) 
savefig(f)

f,_,_ = MINDFM.ibnplot(ibnfs[1]; multidomain=true, intentuuid=intentuuid_bordernode)
savefig(f)

f,_,_ = MINDFM.ibnplot(ibnfs[1]; multidomain=false, showspectrumslots=true)
savefig(f)

f,_,_ = MINDFM.ibnplot(ibnfs[1]; multidomain=true, showspectrumslots=true)
savefig(f)

f,_,_ = MINDFM.ibnplot(ibnfs[1]; multidomain=true, showspectrumslots=true, intentuuid=intentuuid_neigh)
savefig(f)

# break some links
MINDF.setlinkstate!(ibnfs[1], Edge(8, 20), false)
MINDF.setlinkstate!(ibnfs[2], Edge(36, 35), false)
MINDF.setlinkstate!(ibnfs[2], Edge(35, 36), false)

f,_,_ = MINDFM.ibnplot(ibnfs[1]; multidomain=true)
savefig(f)

# bring back to same state
MINDF.setlinkstate!(ibnfs[1], Edge(8, 20), true)
MINDF.setlinkstate!(ibnfs[2], Edge(36, 35), true)
MINDF.setlinkstate!(ibnfs[2], Edge(35, 36), true)
