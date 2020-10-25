# ok so get some data and import these packages


using BenchmarkTools
using Profile

sample_data=CSV.read("C://Users//tbunc//OneDrive//Data//sample_sequence_data.csv"; copycols=true)


sample_data[:sequence_order] = [1:size(sample_data,1);]
gd = groupby(sample_data, :trace_id)
for subdf in gd
    subdf[:sequence_order,] = [1:size(subdf,1);]
       end 

sample_data2 = DataFrame(gd)

Profile.clear()

@btime lev = basic_lev(sample_data2, sequence_id=:trace_id, sequence_event=:activities);
# Before explicit Array declaration:    10.100 ms (79181 allocations: 10.45 MiB)
# After explicit Array declaration:     2.282 ms (12253 allocations: 1.97 MiB)

@btime lev = basic_lev_multi(sample_data2, sequence_id=:trace_id, sequence_event=:activities);
# 15.965 ms (147784 allocations: 14.02 MiB)
x[1]

Profile.print()

# open("C://Users//tbunc//OneDrive//Data//profile.txt", "w") do s
#     Profile.print(IOContext(s, :displaysize => (24, 5000)))
# end



