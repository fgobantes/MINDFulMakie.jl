let 

ibnfs = loadmultidomaintestibnfs()

ibnfs1ob = Observable(ibnfs[1])

f,_,_ = MINDFM.intentplot(ibnfs1ob; intentid=nothing, showstate = true, showintent=true, multidomain=true, subidag=:all)
savefig(f)

populateibnfs(ibnfs, 2; sourceibnf = ibnfs[1])

notify(ibnfs1ob)
savefig(f)


latestintent = getidagnodeid(last(MINDF.getnetworkoperatoridagnodes(getidag(ibnfs[1]))))
MINDF.uninstallintent!(ibnfs[1], latestintent)

notify(ibnfs1ob)
savefig(f)

end
