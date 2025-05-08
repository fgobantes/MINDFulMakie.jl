# plots the graph with the current slot utilization given by suindexed
function plotgraphwithslotutilization(graph::SimpleDiGraph, suindexed, topology::String, demandpattern::String)

    if size(suindexed, 1) != ne(graph) # check that dimensions of suindexed match with the graph
        println("DIMENSIONS NOT MATCHING!")
        return nothing
    end

    set_theme!() # use default theme
   
    #create figure and set the padding, set aspect to 4:3, and create axis
    fsize = 2200
    figure = Figure(figure_padding = 1, size = (fsize, fsize))#, px_per_unit = 8)
    #colsize!(figure.layout, 1, Aspect(1, 4/3))
    axis = Axis(figure[1, 1], 
                xticksvisible = false, 
                yticksvisible = false, 
                #xticklabelsvisible = false,
                #yticklabelsvisible = false,
                aspect = 1)

    #plot graph into axis
    ilabels = Char.((0:nv(graph)-1).+65)
    plot = graphplot!(axis, 
                      SimpleGraph(graph),
                      ilabels=ilabels,
                      ilabels_fontsize = 0.017*fsize,
                      layout = NetworkLayout.Stress(),
                      node_color=:lightblue,
                      node_size=0.05*fsize,
                      node_strokewidth = 0.0005*fsize,
                      edge_width=[0.001*fsize for i in 1:ne(graph)])

    #Box(figure[1, 1], color = (:red, 0.2), strokewidth = 0)
    
    # find amount of allocations and generate/clip color table
    #Random.seed!(0)
    #colors = Vector()
    #for _ in 1:maxdemands push!(colors, RGBf(rand(3)...)) end

    cmap = Makie.to_colormap(:deep)
    left_border = 0.1 # something between 0 and 0.5, cuts the borders of a heatmap
    right_border = 0.1
    cmap = cmap[trunc(Integer, left_border*length(cmap)):Integer(trunc(Integer, (1-right_border)*length(cmap)))] # cut the boarders

    #get nodes coordinates
    nodecoordinates = get_node_plot(plot).converted[1].val

    #plot parameters
    num_slots = 50              # number of slots @TODO: not hardcode numslots
    distance_axis = 0.03        # distance from base line to axis
    distance_node = 0.15        # distance from slots to nodes
    slot_height = 0.03          # height of a slot rect
    markerwidth = 0.02          # width from first or last slot to the tip of the pointing arrows
    distance_slotnumber = 0.02  # distance from middle edge to slotnumbers 
    slotnumsize = 0.009          # size of slotnumber labels

    # main loop over all edges
    for (i, e) in enumerate(edges(graph))

        #get src and dst nodes coordinates
        x1 = nodecoordinates[src(e)][1]
        y1 = nodecoordinates[src(e)][2]
        x2 = nodecoordinates[dst(e)][1]
        y2 = nodecoordinates[dst(e)][2]

        m, c = calcline(x1, y1, x2, y2) # calc line equation through both nodes
        mlot1, clot1 = calclot(m, c, x1) #calc normal line through x1
        mlot2, clot2 = calclot(m, c, x2) #calc normal line through x2
        xm1, xp1 = pointswithfixdistance(mlot1, distance_axis, x1) #get points with distance distance_axis
        xm2, xp2 = pointswithfixdistance(mlot2, distance_axis, x2)

        #calc offset of line and x's margins
        if x1 < x2
            if m<0
                coff = calcyaxisintersect(m, xp1, mlot1*xp1+clot1)
                _, xbegin = pointswithfixdistance(m, distance_node, xp1) 
                xend, _ = pointswithfixdistance(m, distance_node, xp2)
            elseif m>0
                coff = calcyaxisintersect(m, xm1, mlot1*xm1+clot1)
                _, xbegin = pointswithfixdistance(m, distance_node, xm1)
                xend, _ = pointswithfixdistance(m, distance_node, xm2)
            else
            end
        elseif x2 < x1
            if m<0
                coff = calcyaxisintersect(m, xm2, mlot2*xm2+clot2)
                _, xbegin = pointswithfixdistance(m, distance_node, xm2)
                xend, _ = pointswithfixdistance(m, distance_node, xm1)
            elseif m>0
                coff = calcyaxisintersect(m, xp2, mlot2*xp2+clot2)
                _, xbegin = pointswithfixdistance(m, distance_node, xp2)
                xend, _ = pointswithfixdistance(m, distance_node, xp1)
            else
            end
        else #x1 == x2
        end
        
        # now draw the rects
        step = (xend-xbegin)/num_slots
        for j in 1:num_slots 
            x = xbegin+(j-1)*step
            p1 = Point2f(x, m*x+coff)
            p2 = Point2f(x+step, m*(x+step)+coff)
            mlot, clot1 = calclot(m, coff, x)
            _, clot2 = calclot(m, coff, x+step)

            if x1<x2
                if m<0
                    _, xoff = pointswithfixdistance(mlot1, slot_height, x+step)
                elseif m>0
                    xoff, _ = pointswithfixdistance(mlot1, slot_height, x+step)
                else #m==0
                end
            elseif x2<x1
                if m<0
                    xoff, _ = pointswithfixdistance(mlot1, slot_height, x+step)
                elseif m>0
                    _, xoff = pointswithfixdistance(mlot1, slot_height, x+step)
                else #m==0
                end
            else
            end

            p3 = Point2f(xoff, mlot*xoff+clot2)
            p4 = Point2f(xoff-step, mlot*(xoff-step)+clot1)
            
            # draw direction markers
            if x1 < x2 && j == num_slots
                pm = (p2+p3)/2
                cmark = calcyaxisintersect(m, pm[1], pm[2])
                _, xmark = pointswithfixdistance(m, markerwidth, pm[1])
                ptip = Point2f(xmark, m*xmark + cmark)
                arrowmarker = BezierPath([MoveTo(p2),LineTo(ptip),LineTo(p3),ClosePath()])
                Makie.scatter!(axis, 0, 0, marker = arrowmarker, markersize = 1, markerspace = :data, color = :black)
            elseif x2 < x1 && j == 1
                pm = (p1+p4)/2
                cmark = calcyaxisintersect(m, pm[1], pm[2])
                xmark, _ = pointswithfixdistance(m, markerwidth, pm[1])
                ptip = Point2f(xmark, m*xmark + cmark)
                arrowmarker = BezierPath([MoveTo(p1),LineTo(ptip),LineTo(p4),ClosePath()])
                Makie.scatter!(axis, 0, 0, marker = arrowmarker, markersize = 1, markerspace = :data, color = :black)
            else
            end

            # write index numbers for first and last slot
            pt = (p3+p4)/2
            cslotnumber = calcyaxisintersect(m, pt[1], pt[2])
            mtlot, ctlot = calclot(m, cslotnumber, pt[1])
            if x1<x2
                if m<0
                    if j == 1
                        _, xt = pointswithfixdistance(mtlot, distance_slotnumber, pt[1])
                        text!(axis, Point3f(xt, mtlot*xt + ctlot, 0), fontsize = slotnumsize*fsize, text = "1", align = (:center, :center), rotation = atan(m))
                    elseif j == num_slots
                        _, xt = pointswithfixdistance(mtlot, distance_slotnumber, pt[1])
                        text!(axis, Point3f(xt, mtlot*xt + ctlot, 0), fontsize = slotnumsize*fsize, text = "$num_slots", align = (:center, :center), rotation = atan(m))
                    end
                elseif m>0
                    if j == 1
                        xt, _ = pointswithfixdistance(mtlot, distance_slotnumber, pt[1])
                        text!(axis, Point3f(xt, mtlot*xt + ctlot, 0), fontsize = slotnumsize*fsize, text = "1", align = (:center, :center), rotation = atan(m))
                    elseif j == num_slots
                        xt, _ = pointswithfixdistance(mtlot, distance_slotnumber, pt[1])
                        text!(axis, Point3f(xt, mtlot*xt + ctlot, 0), fontsize = slotnumsize*fsize, text = "$num_slots", align = (:center, :center), rotation = atan(m))
                    end
                end
            elseif x2<x1
                if m<0
                    if j == 1
                        xt, _ = pointswithfixdistance(mtlot, distance_slotnumber, pt[1])
                        text!(axis, Point3f(xt, mtlot*xt + ctlot, 0), fontsize = slotnumsize*fsize, text = "1", align = (:center, :center), rotation = atan(m))
                    elseif j == num_slots
                        xt, _ = pointswithfixdistance(mtlot, distance_slotnumber, pt[1])
                        text!(axis, Point3f(xt, mtlot*xt + ctlot, 0), fontsize = slotnumsize*fsize, text = "$num_slots", align = (:center, :center), rotation = atan(m))
                    end
                elseif m>0
                    if j == 1
                        _, xt = pointswithfixdistance(mtlot, distance_slotnumber, pt[1])
                        text!(axis, Point3f(xt, mtlot*xt + ctlot, 0), fontsize = slotnumsize*fsize, text = "1", align = (:center, :center), rotation = atan(m))
                    elseif j == num_slots
                        _, xt = pointswithfixdistance(mtlot, distance_slotnumber, pt[1])
                        text!(axis, Point3f(xt, mtlot*xt + ctlot, 0), fontsize = slotnumsize*fsize, text = "$num_slots", align = (:center, :center), rotation = atan(m))
                    end
                end
            end
                    

            # draw slot utilization
            slotrect = BezierPath([MoveTo(p1),LineTo(p2),LineTo(p3),LineTo(p4),ClosePath()])  
            
            if suindexed[i, j] == 0
                rectcolor = :white
            else  
                rectcolor = suindexed[i, j] # index that scatter! will use to determine color given a colormap
            end
            # Makie.scatter!(axis, 0, 0, marker = slotrect, markersize = 1, markerspace = :data, color = :black)
            # Makie.scatter!(axis, 0, 0, marker = slotrect, markersize = 1, markerspace = :data, colormap = cmap, color = rectcolor)
        
        end

        xs = xbegin:0.01:xend
        ys = Vector()
        for x in xs
            push!(ys, m*x+coff)
        end
        #lines!(axis, xs, ys, color = :blue)

    end
    
    # add colorbar
    Colorbar(figure, 
            limits = (0.5, maxdemands+0.5), 
            colormap = cgrad(cmap, maxdemands, categorical=true), 
            width = 0.1*fsize, 
            bbox = BBox(0, 3.38*fsize, 0.02*fsize, 0.95*fsize), # borders of colorbar, left, right, bottom, top
            flipaxis = false,
            ticks = 1:maxdemands,
            ticklabelsize = 0.013*fsize)

    text!(figure.scene, Point3f(1.688*fsize, 0.968*fsize, 0), fontsize = 0.023*fsize, text = "Demands", space = :pixel, align = (:center, :center)) # add colorbar caption on top
    text!(figure.scene, Point3f(0.035*fsize, 0.97*fsize, 0), fontsize = 0.03*fsize, text = "Network: $topology", space = :pixel, align = (:left, :center)) # add caption for whole plot
    text!(figure.scene, Point3f(0.035*fsize, 0.93*fsize, 0), fontsize = 0.03*fsize, text = "Demandpattern: $demandpattern", space = :pixel, align = (:left, :center))
    
    if cur_demand != 0
        for i in 1:cur_demand
            translate!(text!(figure.scene, Point3f(1.69*fsize, (0.95-0.02)*fsize/maxdemands*(i-1+0.5) + 0.02*fsize, 0), fontsize = 0.012*fsize, text = "$(ilabels[demands[i].source]) ⇒ $(ilabels[demands[i].target]) ($(demands[i].demandvalue))", markerspace = :data, align = (:center, :center)), 0, 0, 1)
            # text!(figure.scene, Point3f(60, 90, 0), fontsize = 15, text = "size: $(dinfos[cur_demand].val)", space = :pixel)
        end
        text!(figure.scene, Point3f(0.036*fsize, 0.05*fsize, 0), fontsize = 0.03*fsize, text = "t = $(@sprintf "%.5f" demands[cur_demand].tin) s", space = :pixel, align = (:left, :center))
        #text!(figure.scene, Point3f(25, 50, 0), fontsize = 45, text = "$(dinfos[cur_demand].src) ⇒ $(dinfos[cur_demand].dst)", space = :pixel)
        #text!(figure.scene, Point3f(60, 90, 0), fontsize = 15, text = "size: $(dinfos[cur_demand].val)", space = :pixel)
    else
        text!(figure.scene, Point3f(0.036*fsize, 0.05*fsize, 0), fontsize = 0.03*fsize, text = "t = $(@sprintf "%.5f" 0) s", space = :pixel, align = (:left, :center))
    end


    #set limits so graph is not cut off and axis aspect of 1 is kept
    layout = plot[:node_pos][]
    limsx = extrema(first.(layout)) #.+ Float32[-0.09, 10.79]
    limsy = extrema(last.(layout)) #.+ Float32[-0.12, 0.12]
    padding = 0.1
    deltax = abs(limsx[2]-limsx[1])
    deltay = abs(limsy[2]-limsy[1])
    newlimsx = zeros(Float64, 2)
    newlimsy = zeros(Float64, 2)
    if deltax >= deltay
        delta = deltax-deltay
        newlimsx[1] = limsx[1]-padding
        newlimsx[2] = limsx[2]+padding
        newlimsy[1] = limsy[1]-delta/2-padding
        newlimsy[2] = limsy[2]+delta/2+padding
    else 
        delta = deltay-deltax
        newlimsx[1] = limsx[1]-delta/2-padding
        newlimsx[2] = limsx[2]+delta/2+padding
        newlimsy[1] = limsy[1]-padding
        newlimsy[2] = limsy[2]+padding
    end

    xlims!(axis, newlimsx...)
    ylims!(axis, newlimsy...)
    
    # hide the unnecessary stuff
    hidespines!(axis)
    hidedecorations!(axis)

    #colsize!(figure.layout, 1, Aspect(1, 4/3))
    colsize!(figure.layout, 1, Aspect(1, 16/9))
    resize_to_layout!(figure)
    
    return figure
end


function calcline(x1, y1, x2, y2)
    m = (y2-y1)/(x2-x1)
    c = y2 - m*x2
    #println("m: ", m)
    #println("c: ", c)
    return m, c
end


#calc normal line at point x1
function calclot(m, ya, x1)
    # Steigung m, y-Achsenabschnitt ya, Punkt bei x1
    return -1/m, (m+1/m)*x1 + ya
end


#calc the two x values for two points with distance d on a given line from given point
function pointswithfixdistance(m, d, x1)
    # Steigung m, Distanz d, Punkt bei x1
    a = 1+m^2
    b = -2*a*x1
    c = a*x1^2-d^2
    #println("a:", a)
    #println("b:", b)
    #println("c:", c)
    xm = (-b-sqrt(b^2-4*a*c))/(2*a)
    xp = (-b+sqrt(b^2-4*a*c))/(2*a)
    #println("xl:", xl)
    #println("xr:", xr)
    return xm, xp
end


#calc ya (yaxisintersect) given m and a point
function calcyaxisintersect(m, x1, y1)
    return y1-m*x1
end

