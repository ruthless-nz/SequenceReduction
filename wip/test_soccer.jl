
using SequenceReduction



soccer_events=CSV.read("C://Users//tbunc//OneDrive//Data//soccer_events//events.csv"; copycols=true)

# describe(soccer_events)

# Ok so for my first cut I will combine side (home or away) with the basic event.

# so keep just a few of the cols. 

soccer_events2 = soccer_events[1:Int(floor(nrow(soccer_events)/100)) ,[:id_odsp, :sort_order, :sequence_event]]



@time basic_lev(soccer_events2, sequence_id=:id_odsp, sequence_order=:sort_order);
@time basic_lev_multi(soccer_events2, sequence_id=:id_odsp, sequence_order=:sort_order);
# Ok so potentially could do some form of outlier removal for master sequence
soccer_events

first_trace = hcat(soccer_lev[2][1][3]...)
soccer_lev[2][1][3]
reduce(hcat,soccer_lev[2][1][3])
# Lets turn this into an array

using RecursiveArrayTools
using Clustering

VA = VectorOfArray(soccer_lev[2][1][3])
arr = convert(Array,VA)
trace_vals_1 = convert(Array{Float64,2},arr[1,:,:])

# R  = kmeans(trace_vals_1, 2);
# counts(R)
# assignments(R)

dbscan(trace_vals_1,.05)
trace_vals_1[1,:]
