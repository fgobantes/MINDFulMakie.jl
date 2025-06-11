let 
ibnfs = loadmultidomaintestibnfs()

ibnfs1ob = Observable(ibnfs[1])

latestintent = Observable(UUID[])
f,_,_ = MINDFM.ibnplot(ibnfs1ob; multidomain=true, intentids=latestintent, showspectrumslots=true, spectrumverticalheight = 0.3)
savefig(f)

MINDF.setlinkstate!(ibnfs1ob[], Edge(8, 20), false)
MINDF.setlinkstate!(ibnfs[1], Edge(8, 20), false)

notify(ibnfs1ob)
savefig(f)

populateibnfs(ibnfs, 100)

notify(ibnfs1ob)
savefig(f)

latestintent[] = [getidagnodeid(last(MINDF.getnetworkoperatoridagnodes(getidag(ibnfs[1]))))]
savefig(f)
end

