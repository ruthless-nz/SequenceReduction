
function basic_lev_multi(dataframe; sequence_id="sequence_id",sequence_event="sequence_event",sequence_order="sequence_order")

    # The lev_master Array is the key object of this funtion. consider it the spine, or memory
    # the Elements are: The Sequence, Lev matrix, Lev Value, Trace
    lev_master = Array[]
    # Elements are: Lev average, and trace average
    lev_history = Array[]

    # ok so first thing is to create a sub dataframe from the dataframe
    gd = groupby(dataframe, Symbol(sequence_id))    

    # We need to initalise the master sequence
    master_df = sort!(unique(dataframe[:, [Symbol(sequence_event), Symbol(sequence_order)]]), [Symbol(sequence_order)])   
    master_seq=master_df[!,Symbol(sequence_event)]
    # println("Size of master sequence is ",size(master_seq)[1])

    ga=Array[]
    for subdf in gd
        push!(ga,[subdf[!,Symbol(sequence_id)],subdf[!,Symbol(sequence_event)],subdf[!,Symbol(sequence_order)]])
    end
    # println(typeof(ga[1][1]))

    lev_master =  Array{Array}(undef,length(ga),1)
    # lev_master = Matrix{Any}(missing,length(ga),4)
    Threads.@threads  for i in eachindex(ga)
    #     Create the first cut of lev matricies
            lev_matrix = lev_create(master_seq,ga[i][2])
        # Get the lev values
            lev_value = lev_distance(lev_matrix)
        # and do the trace on the lev matrix 
            lev_master[i] = [ga[i][2],lev_matrix,lev_value,lev_trace(lev_matrix)]
    end;


    # println(typeof(lev_master))
    # println(length(lev_master))
# Cool so this creates the initial lev master object
# Now we want to begin the ole iteration

# Pull out the values so we can do sum statz
lev_value = Array{Int64}(undef,length(lev_master))
trace =  Array{Array}(undef,length(lev_master))
master_seq_hist = []
push!(master_seq_hist,copy(master_seq))

for i in eachindex(lev_master);
    lev_value[i] = lev_master[i][3]
    trace[i] = lev_master[i][4]
end

# Get the history of the run and add it to the lev hist Array
push!(lev_history,Array{Union{Array,String,Float64}}([mean(lev_value)+1,mean(vcat(trace...),dims=1),trace]))
push!(lev_history,Array{Union{Array,String,Float64}}([mean(lev_value),mean(vcat(trace...),dims=1),trace]))
positions = findall(x -> x == maximum(lev_history[end][2]), lev_history[end][2])



# ok so now iterate over this thing
while (lev_history[end][1] < lev_history[end-1][1])
    # println(lev_history[end][1],"   ",lev_history[end-1][1],)

    to_remove=positions[end][2]-1
    # take positions and remove the last one from the master sequence
    # println(" removing event ",master_seq[to_remove]," position ",to_remove," --- ","Avg Lev:",lev_history[end][1],
    #     " Master Sequence Length:",size(master_seq)[1])

    deleteat!(master_seq,to_remove)  
    push!(master_seq_hist,copy(master_seq))

    # init these temp arrays
    lev_value = Array{Float64}(undef,length(lev_master))
    trace =  Array{Array}(undef,length(lev_master))
    # update the lev arrays and calculate new lev value
    Threads.@threads for i in eachindex(lev_master);
        lev_master[i][2] = lev_update(lev_master[i][2],lev_master[i][1],master_seq,to_remove)
        lev_master[i][3] = lev_distance(lev_master[i][2])
        lev_master[i][4] = lev_trace(lev_master[i][2])
        # and create the stats
        # println(typeof(lev_master[i][3]))
        lev_value[i] = lev_master[i][3]
        trace[i] = lev_master[i][4]
    end

    # Get the history of the run and add it to the lev hist Array
    push!(lev_history,Array{Union{Array,String,Float64}}([mean(lev_value),mean(vcat(trace...),dims=1),trace]))
    positions = findall(x -> x == maximum(lev_history[end][2]), lev_history[end][2])

end;

if lev_history[end][1] > lev_history[end-1][1]
    # println("Going back one and ending things")
    master_seq = master_seq_hist[end-1]
end

    Lev_return = [master_seq,lev_history,lev_master]

    return Lev_return

end


# basic_lev_multi(sample_data2, sequence_id=:trace_id, sequence_event=:activities);