"Plots the `idx`st intent of `ibn`"
@recipe(IntentPlot, ibn, idx) do scene
    Attributes(
               interdomain = false,
               show_state = true,
    )
end

function Makie.plot!(intplot::IntentPlot)
    ibn = intplot[:ibn]
    idx = intplot[:idx]

    dag = ibn[].intents[idx[]]
    if intplot.show_state[] == false
        labs = [dagtext(dag[MGN.label_for(dag,v)].intent) for v in  vertices(dag)]
    else 
        labs = [let dagnode=dag[MGN.label_for(dag,v)]; dagtext(dagnode.intent)*"\nstate=$(dagnode.state)"; end for v in  vertices(dag)]
    end
    labsalign = [length(outneighbors(dag, v)) == 0 ? (:center, :top) : (:center, :bottom)  for v in vertices(dag)]
    GraphMakie.graphplot!(intplot, dag, layout=NetworkLayout.Buchheim(), nlabels=labs, nlabels_align=labsalign)

    return intplot
end