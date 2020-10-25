module SequenceReduction

# Dependancies are called below:
using DataFrames
using CSV
using Statistics

# LEV CREATE
# Ok so here we create the Lev Matrix 
# Inputs are two columns that are the two sequences
# Output is the lev Matrix

function lev_create(x,y)
    
    # ok so we need to get the lengths of both arrays
        lenx = size(x)[1]
        leny = size(y)[1]
        
    # Initialise the lev array
        lev_array = zeros(Int, leny + 1, lenx + 1)   
        
    #  and now we populate it with the col starting vals
        lev_array[1,:] = 0:(size(lev_array)[2]-1)
        lev_array[:,1] = 0:(size(lev_array)[1]-1)
        
    # cool so now we do the base lev algo
        
        for i in 2:size(lev_array)[2]
            for j in 2:size(lev_array)[1]
    #             because we start from 2 not 1, we can skip the first lev condition
                if x[i-1] == y[j-1]
                    sub_cost = 0
                    else sub_cost = 1
                end
             
                ins = lev_array[j-1,i]+1
                del = lev_array[j,i-1]+1
                sub = lev_array[j-1,i-1] + sub_cost
     
                lev_array[j,i] = min(ins,del,sub)
                              
            end
        end
        
        return   lev_array 
    end;

# LEV DISTANCE
# This will get the last value of the lev array
# input is a Lev Matrix (or any matrix really) and returns the last value. 
# Simple, but well named

function lev_distance(x)

    lev_distance = x[end,end]
    
        return lev_distance
    
end


# LEV TRACE
# get a list of the elements that are increasing the edit distance
# This takes a lev matrix, the sequences that created it, and returns an array with 
# the edit distance information

# Important to note that this assumes that the master sequence is on the top/x axis
function lev_trace(lev_matrix)
    
    #     ok so init the bad elements Matrix
        bad_elements = zeros(Int8,1,size(lev_matrix)[2])
        
    #     ok so start at the bottom right
        i = size(lev_matrix)[2]
        j = size(lev_matrix)[1]
    #     count = 0
        
         while i > 1 && j > 1
        
            i_old = i
            j_old = j
    
            left = lev_matrix[j,i-1]
            diag = lev_matrix[j-1,i-1]
            up   = lev_matrix[j-1,i]
            
    #         print(left,diag,up)
    #         print(" ")
            
             if up == min(left,diag,up) 
                j = j - 1
    #             print(" up ")
             elseif diag == min(left,diag,up)
                i = i - 1
                j = j - 1
    #             print(" diag ")
            elseif left == min(left,diag,up)
                bad_elements[i]=1
                i = i - 1
    #             print(" left ")
    
            end
    #             print(i,j)
    #             print(" ")
                
    #     count = count + 1
        end
    
    return bad_elements
end

# LEV UPDATE
# This function takes in a lev matrix, slices it at a point and recalculates it from that point
# inputs are: lev matrix, the new sequences, and the positions on the old master sequence were the new sequence changes
# Types are: array, array, array, Int8
function lev_update(matrix,seq,new_master_seq,position)

    #     ok so check how many elements have been removed
        elements_removed = size(matrix)[2] - 1 - size(new_master_seq)[1]
        
        #     trim this number of elements off the end
        lev_array=matrix[1:end, 1:(size(matrix))[2]-elements_removed]
        
            for i in (position+1):size(lev_array)[2]
                for j in 2:size(lev_array)[1]
        
                    if new_master_seq[i-1] == seq[j-1]
                        sub_cost = 0
                        else sub_cost = 1
                    end
             
                    ins = lev_array[j-1,i]+1
                    del = lev_array[j,i-1]+1
                    sub = lev_array[j-1,i-1] + sub_cost
    
                    lev_array[j,i] = min(ins,del,sub)
                end
            end
        
    
        return lev_array
        
    end

# BASIC lEV
# This is the basic lev reduction. It takes a Dataframe with the following collumns(order not needed):
# Sequence Identifier
# Sequence Event
# Sequence Order

# Inputs are:
# dataframe, sequence_id, sequence_event, sequence_order
# Types:
# Dataframe, String, String, String

function basic_lev(dataframe; sequence_id="sequence_id",sequence_event="sequence_event",sequence_order="sequence_order")

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

    for subdf in gd
    #     Create the first cut of lev matricies
            seq = subdf[!,Symbol(sequence_event)]
            lev_matrix = lev_create(master_seq,seq)
        # Get the lev values
            lev_value = lev_distance(lev_matrix)
        # and do the trace on the lev matrix
            trace = lev_trace(lev_matrix)

            push!(lev_master,[seq,lev_matrix,lev_value,trace])
            
    end

    # return lev_master

# Cool so this creates the initial lev master object
# Now we want to begin the ole iteration

# Pull out the values so we can do sum statz
lev_value = Int64[]
trace = Array[]
master_seq_hist = Array[]
push!(master_seq_hist,copy(master_seq))

for i in lev_master;
    push!(lev_value,i[3])
    push!(trace,i[4])
end

# Get the history of the run and add it to the lev hist Array
push!(lev_history,Array{Union{Array,String,Float64}}([mean(lev_value)+1,mean(vcat(trace...),dims=1),trace]))
push!(lev_history,Array{Union{Array,String,Float64}}([mean(lev_value)+1,mean(vcat(trace...),dims=1),trace]))
positions = findall(x -> x == maximum(lev_history[end][2]), lev_history[end][2])

# ok so now iterate over this thing
while (lev_history[end][1] < lev_history[end-1][1])
    # println(lev_history[end][1],"   ",lev_history[end-1][1],)

    to_remove=positions[1][2]-1
    # take positions and remove the last one from the master sequence
    # println(" removing event ",master_seq[to_remove]," position ",to_remove," --- ","Avg Lev:",lev_history[end][1],
    #     " Master Sequence Length:",size(master_seq)[1])

    deleteat!(master_seq,to_remove)  
    push!(master_seq_hist,copy(master_seq))

    # init these temp arrays
    lev_value = Int64[]
    trace = Array[]
    # update the lev arrays and calculate new lev value
    for i in lev_master;
        i[2] = lev_update(i[2],i[1],master_seq,to_remove)
        i[3] = lev_distance(i[2])
        i[4] = lev_trace(i[2])
        # and create the stats
        push!(lev_value,i[3])
        push!(trace,i[4])
    end

    # Get the history of the run and add it to the lev hist Array
    push!(lev_history,Array{Union{Array,String,Float64}}([mean(lev_value)+1,mean(vcat(trace...),dims=1),trace]))
    positions = findall(x -> x == maximum(lev_history[end][2]), lev_history[end][2])

end;

if lev_history[end][1] > lev_history[end-1][1]
    # println("Going back one and ending things")
    master_seq = master_seq_hist[end-1]
end

    Lev_return = [master_seq,lev_history,lev_master]

    return Lev_return

end


end # module
