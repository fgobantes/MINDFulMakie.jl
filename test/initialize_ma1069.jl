using MINDFulMakie

using MINDFul
using CairoMakie
using Test, TestSetExtensions, ReferenceTests
using Graphs
import AttributeGraphs as AG
using JLD2, UUIDs
using Unitful, UnitfulData
using HTTP

import MINDFul: ReturnCodes

import Random: MersenneTwister

const MINDF = MINDFul
const MINDFM = MINDFulMakie

import MINDFul: ReturnCodes, IBNFramework, getibnfhandlers, GlobalNode, ConnectivityIntent, addintent!, NetworkOperator, compileintent!, KShorestPathFirstFitCompilation, installintent!, uninstallintent!, uncompileintent!, getidag, getrouterview, getoxcview, RouterPortLLI, TransmissionModuleLLI, OXCAddDropBypassSpectrumLLI, canreserve, reserve!, getlinkspectrumavailabilities, getreservations, unreserve!, getibnfid, getidagnodestate, IntentState, getidagnodechildren, getidagnode, OpticalTerminateConstraint, getlogicallliorder, issatisfied, getglobalnode, getibnag, getlocalnode, getspectrumslotsrange, gettransmissionmode, getname, gettransmissionmodule, TransmissionModuleCompatibility, getrate, getspectrumslotsneeded, OpticalInitiateConstraint, getnodeview, getnodeview, getsdncontroller, getrouterview, removeintent!, getlinkstates, getcurrentlinkstate, setlinkstate!, logicalordercontainsedge, logicalordergetpath, edgeify, getintent, RemoteIntent, getisinitiator, getidagnodeid, getibnfhandler, getidagnodes, @passtime, getlinkstates, GBPSf


TESTDIR = @__DIR__
ASSETSDIR = joinpath(@__DIR__, "assets/")
TMPDIR = joinpath(ASSETSDIR, "tmp")
isdir(TMPDIR) && rm(TMPDIR; recursive=true)
mkdir(TMPDIR)
PSNR_THRESHOLD::Int = 30

function savefig(fig)
    counter = length(readdir(TMPDIR))
    save(joinpath(TMPDIR, "test-$(counter+1).png"), fig)
end

function loadmultidomaintestibnfs()
    domains_name_graph = first(JLD2.load(TESTDIR*"/data/itz_IowaStatewideFiberMap-itz_Missouri-itz_UsSignal_addedge_24-23,23-15__(1,9)-(2,3),(1,6)-(2,54),(1,1)-(2,21),(1,16)-(3,18),(1,17)-(3,25),(2,27)-(3,11).jld2"))[2]


    hdlr=Vector{MINDFul.RemoteHTTPHandler}()
    ibnfs = [
        let
            ag = name_graph[2]
            ibnag = MINDF.default_IBNAttributeGraph(ag)
            ibnf = MINDF.IBNFramework(ibnag, Vector{MINDFul.RemoteHTTPHandler}())
        end for name_graph in domains_name_graph
    ]
    

    # add ibnf handlers    
    for i in eachindex(ibnfs)
        port = 8080 + i
        URI = HTTP.URI(; scheme="http", host="127.0.0.1", port=string(port))
        URI_s=string(URI)
        push!(hdlr, MINDF.RemoteHTTPHandler(UUID(i), URI_s))
    end

    for i in eachindex(ibnfs)
        push!(MINDF.getibnfhandlers(ibnfs[i]), hdlr[i])
        for j in eachindex(ibnfs)
            i == j && continue
            push!(MINDF.getibnfhandlers(ibnfs[i]), hdlr[j])
        end
    end

    MINDF.startibnserver!(ibnfs)
    return ibnfs
end

ibnfs = loadmultidomaintestibnfs()

# with border node
conintent_bordernode = MINDF.ConnectivityIntent(MINDF.GlobalNode(UUID(1), 4), MINDF.GlobalNode(UUID(3), 25), u"100.0Gbps")
intentuuid_bordernode = MINDF.addintent!(ibnfs[1], conintent_bordernode, MINDF.NetworkOperator())

MINDF.compileintent!(ibnfs[1], intentuuid_bordernode, MINDF.KShorestPathFirstFitCompilation(5))
 
# install
MINDF.installintent!(ibnfs[1], intentuuid_bordernode; verbose=true)

# to neighboring domain
conintent_neigh = MINDF.ConnectivityIntent(MINDF.GlobalNode(UUID(1), 4), MINDF.GlobalNode(UUID(3), 47), u"100.0Gbps")
intentuuid_neigh = MINDF.addintent!(ibnfs[1], conintent_neigh, MINDF.NetworkOperator())

MINDF.compileintent!(ibnfs[1], intentuuid_neigh, MINDF.KShorestPathFirstFitCompilation(5))

MINDF.installintent!(ibnfs[1], intentuuid_neigh; verbose=true)

function populateibnfs(ibnfs, num; sourceibnf=nothing)
    rng = MersenneTwister(0)

    for counter in 1:num
        srcibnf = isnothing(sourceibnf) ? rand(rng, ibnfs) : sourceibnf
        srcnglobalnode = rand(rng, MINDF.getglobalnode.(MINDF.getproperties.(MINDF.getintranodeviews(getibnag(srcibnf)))) )
        dstibnf = rand(rng, ibnfs)
        dstglobalnode = rand(rng, MINDF.getglobalnode.(MINDF.getproperties.(MINDF.getintranodeviews(getibnag(dstibnf)))) )
        while dstglobalnode == srcnglobalnode
            dstglobalnode = rand(rng, MINDF.getglobalnode.(MINDF.getproperties.(MINDF.getintranodeviews(getibnag(dstibnf)))) )
        end

        rate = GBPSf(rand(rng)*100) 

        conintent = ConnectivityIntent(srcnglobalnode, dstglobalnode, rate)
        conintentid = addintent!(srcibnf, conintent, NetworkOperator())
        compileintent!(srcibnf, conintentid, KShorestPathFirstFitCompilation(10)) == ReturnCodes.SUCCESS
        installintent!(srcibnf, conintentid; verbose=false) == ReturnCodes.SUCCESS
        issatisfied(srcibnf, conintentid)
    end
end


nothing
