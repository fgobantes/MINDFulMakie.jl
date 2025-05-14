f,_,_ = MINDFM.intentplot(ibnfs[1], intentid = intentuuid_bordernode; multidomain=false)
savefig(f)

f,_,_ = MINDFM.intentplot(ibnfs[1], intentid = intentuuid_bordernode; multidomain=true)
savefig(f)

f,_,_ = MINDFM.intentplot(ibnfs[1], intentid = intentuuid_neigh; multidomain=false)
savefig(f)

f,_,_ = MINDFM.intentplot(ibnfs[1], intentid = intentuuid_neigh; multidomain=true)
savefig(f)

f,_,_ = MINDFM.intentplot(ibnfs[1], intentid = intentuuid_neigh; multidomain=true, showstate = true, showintent = true)
savefig(f)

f,_,_ = MINDFM.intentplot(ibnfs[1], subidag = :all)
savefig(f)

f,_,_ = MINDFM.intentplot(ibnfs[1], subidag = :all)
savefig(f)

f,_,_ = MINDFM.intentplot(ibnfs[1], subidag = :all, multidomain=true)
savefig(f)
