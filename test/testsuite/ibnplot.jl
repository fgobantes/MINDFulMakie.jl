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

